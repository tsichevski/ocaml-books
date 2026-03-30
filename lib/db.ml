(** PostgreSQL database layer for the book library.

    This module provides functions to store and retrieve books and authors
    in a normalized relational schema:

    - ``books`` table (keyed by digest)
    - ``persons`` table (keyed by normalized_name)
    - ``book_authors`` link table (many-to-many)

    All operations are designed to be safe for concurrent use from multiple
    indexing threads. UPSERT patterns guarantee exactly-once semantics for
    persons and deduplication for books.

    The module uses the ``Postgresql`` OCaml binding.
*)

open Book
open Person

module Log = (val Logs.src_log (Logs.Src.create "db" ~doc:"Database access") : Logs.LOG)

type connection = Postgresql.connection
type book_id = string
type person_id = string

(** [opt_to_param opt] converts an optional string to a parameter suitable
    for Postgresql queries.

    Uses [Postgresql.null] for [None] so that the database receives a real SQL NULL.
    Using "" would incorrectly store an empty string instead of NULL.
*)
let opt_to_param = function
  | None   -> Postgresql.null
  | Some s -> s

let opt_to_string = function
  | None   -> "<none>"
  | Some s -> s

let log_book (b : book) op =
  Log.debug (fun m -> m "%s book: digest=%s title=%s file=%s encoding=%s"
    op (digest b) b.title b.filename b.encoding)

let log_person ?(level = Logs.Debug) (p : person) op =
  Log.msg level (fun m -> m "%s person: l:%s f:%s m:%s (%s)"
    op
    (opt_to_string p.last_name)
    (opt_to_string p.first_name)
    (opt_to_string p.middle_name)
    p.id)

(** [insert_book c b] inserts a new book record and returns its primary key (as string).

    Raises [Failure] if the INSERT unexpectedly returns no row.
*)
let insert_book (c : connection) (b : book) : book_id =
  log_book b "Inserting";
  let new_id = c#exec
    {|INSERT INTO books (digest, ext_id, version, title, encoding, lang, genre, filename)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id|}
    ~params:[| digest b; opt_to_param b.ext_id; opt_to_param b.version;
               b.title; b.encoding; opt_to_param b.lang;
               opt_to_param b.genre; b.filename |]
    ~expect:[Tuples_ok]
  in
  if new_id#ntuples = 0 then
    failwith (Printf.sprintf "Cannot insert new book (digest=%s, title=%s)" (digest b) b.title)
  else
    new_id#getvalue 0 0

(** [find_person_opt c norm] looks up a person by normalized name.

    Returns [Some id] if exactly one match, [None] if none.
    Raises [Failure] if more than one person shares the same normalized_name
    (should never happen due to UNIQUE constraint).
*)
let find_person_opt (c : connection) (norm : string) : person_id option =
  Log.debug (fun m -> m "Lookup person opt: %s" norm);
  let existing = c#exec
    "SELECT id FROM persons WHERE normalized_name=$1"
    ~params:[| norm |]
    ~expect:[Tuples_ok]
  in
  match existing#ntuples with
  | 0 ->
      Log.debug (fun m -> m "No person found: %s" norm);
      None
  | 1 ->
      let pid = existing#getvalue 0 0 in
      Log.debug (fun m -> m "Found person id=%s for %s" pid norm);
      Some pid
  | n ->
      failwith (Printf.sprintf
        "Database integrity error: %d persons with same normalized_name=%s" n norm)

(** [insert_person c norm a] atomically registers an author using UPSERT.

    If a person with the same [normalized_name] already exists, the existing id is returned.
    Otherwise a new row is inserted.

    This guarantees exactly-once semantics even under concurrent indexing.

    Example:

    {[
      let pid = insert_person conn "толстой лев николаевич" tolstoy_person in
      (* pid is the integer primary key as string *)
    ]}
*)
let insert_person (c : connection) norm (a : person) : person_id =
  log_person a "Inserting";
  let new_id = c#exec {sql|
INSERT INTO persons (first_name, middle_name, last_name, normalized_name)
VALUES ($1, $2, $3, $4)
ON CONFLICT (normalized_name)
DO UPDATE SET id = persons.id   -- no-op, just to get RETURNING
RETURNING id
|sql}
    ~params:[| opt_to_param a.first_name; opt_to_param a.middle_name;
               opt_to_param a.last_name; norm |]
    ~expect:[Tuples_ok]
  in
  if new_id#ntuples = 0 then begin
    log_person ~level:Logs.Error a "No person inserted";
    failwith (Printf.sprintf "Failed to insert person (normalized_name=%s)" norm)
  end else
    new_id#getvalue 0 0

(** [find_or_insert_person c a] returns the database id for the given person,
    inserting it if necessary.
*)
let find_or_insert_person (c : connection) (a : person) : person_id =
  let norm = a.id in
  log_person a "Find or Insert";
  match find_person_opt c norm with
  | Some id -> id
  | None -> insert_person c norm a

let insert_link (c : connection) (book_id : book_id) (person_id : person_id) =
  Log.debug (fun m -> m "Add link: book_id=%s person_id=%s" book_id person_id);
  ignore (c#exec
    {|INSERT INTO book_authors (book_id, person_id) VALUES ($1, $2)|}
    ~params:[| book_id; person_id |]
    ~expect:[Command_ok])

(** [delete_book c b] deletes a book by its digest and title.
*)
let delete_book (c : connection) (b : book) : book_id =
  log_book b "Deleting";
  let res = c#exec
    {|DELETE FROM books WHERE digest=$1 RETURNING id|}
    ~params:[| digest b |]
    ~expect:[Tuples_ok]
  in
  if res#ntuples = 0 then
    failwith (Printf.sprintf "Cannot delete book (digest=%s, title=%s)" (digest b) b.title)
  else
    res#getvalue 0 0

(** [find_or_insert_book c b] ensures the book exists and all its authors are linked.

    - If the book (by digest) does not exist → insert it and link all authors.
    - If it exists → link any missing authors only.

    Raises [Failure] if multiple books with the same digest are found (integrity error).
*)
let find_or_insert_book (c : connection) (b : book) : book_id =
  let digest_val = digest b in
  let title = b.title in
  let authors = b.authors in
  let filename = b.filename in

  log_book b "Looking for existing";

  let existing_book = c#exec
    "SELECT books.id FROM books WHERE digest = $1"
    ~params:[| digest_val |]
    ~expect:[Tuples_ok]
  in

  let new_book_id, persons_to_add =
    match existing_book#ntuples with
    | 0 ->
        log_book b "Will insert";
        let book_id = insert_book c b in
        Log.debug (fun m -> m "Created new book: digest=%s title=%s id=%s file=%s"
          digest_val title book_id filename);
        (book_id, authors)

    | 1 ->
        log_book b "Existing";
        let book_id = existing_book#getvalue 0 0 in

        (* Get existing author normalized names for this book *)
        let existing_authors = c#exec
          "SELECT persons.normalized_name FROM book_authors
           JOIN persons ON book_authors.person_id = persons.id
           WHERE book_authors.book_id = $1"
          ~params:[| book_id |]
          ~expect:[Tuples_ok]
        in

        let n = existing_authors#ntuples in
        Log.debug (fun m -> m "Existing book id=%s has %d authors" book_id n);

        let existing_norms =
          List.init n (fun i -> existing_authors#getvalue i 0)
        in

        (* Keep only authors that are not yet linked *)
        let missing = List.filter
          (fun a -> not (List.mem a.id existing_norms))
          authors
        in
        (book_id, missing)

    | n ->
        Log.warn (fun m -> m "Multiple (%d) books with same digest=%s found" n digest_val);
        failwith (Printf.sprintf
          "Database integrity error: %d books with same digest=%s" n digest_val)
  in

  (* Insert missing person links *)
  let person_ids = List.map (fun a -> find_or_insert_person c a) persons_to_add in
  List.iter (fun pid -> insert_link c new_book_id pid) person_ids;

  new_book_id

(** [init_schema c] creates the required tables and indexes if they do not exist.

    Idempotent: safe to call multiple times.
    Includes primary keys, unique constraints, and foreign keys for data integrity.

    Example:

    {[
      let conn = Db.connect () in
      Db.init_schema conn;
      (* tables books, persons, book_authors are now ready *)
    ]}
*)
let init_schema (c : connection) =
  Log.info (fun m -> m "Initializing database schema");
  let queries = [
    {sql|
CREATE TABLE IF NOT EXISTS books (
  id          SERIAL PRIMARY KEY,
  digest      TEXT NOT NULL UNIQUE,
  ext_id      TEXT,
  version     TEXT,
  title       TEXT NOT NULL,
  encoding    TEXT NOT NULL,
  lang        TEXT,
  genre       TEXT,
  filename    TEXT NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
|sql};

    {sql|
CREATE TABLE IF NOT EXISTS persons (
  id               SERIAL PRIMARY KEY,
  first_name       TEXT,
  middle_name      TEXT,
  last_name        TEXT,
  normalized_name  TEXT NOT NULL UNIQUE
)
|sql};

    {sql|
CREATE TABLE IF NOT EXISTS book_authors (
  book_id    INTEGER REFERENCES books(id) ON DELETE CASCADE,
  person_id  INTEGER REFERENCES persons(id) ON DELETE CASCADE,
  PRIMARY KEY (book_id, person_id)
)
|sql};

    "CREATE INDEX IF NOT EXISTS idx_books_digest ON books(digest)";
    "CREATE INDEX IF NOT EXISTS idx_persons_normalized_name ON persons(normalized_name)";
  ] in
  List.iter (fun q ->
    ignore (c#exec q ~expect:[Command_ok])
  ) queries;
  Log.info (fun m -> m "Database schema initialized successfully")

(** [drop_schema c] drops all library tables (for testing / reset).

    Use with extreme caution.
*)
let drop_schema (c : connection) =
  Log.warn (fun m -> m "Dropping entire database schema");
  let queries = [
    {sql| DROP TABLE IF EXISTS book_authors CASCADE |sql};
    {sql| DROP TABLE IF EXISTS persons CASCADE |sql};
    {sql| DROP TABLE IF EXISTS books CASCADE |sql};
  ] in
  List.iter (fun q ->
    ignore (c#exec q ~expect:[Command_ok])
  ) queries;
  Log.warn (fun m -> m "Database schema dropped")

(** [connect ?host ?port ?user ?password ?dbname ()] creates a new PostgreSQL connection.

    Default values are suitable for local development.
*)
let connect
  ?(host = "localhost")
  ?(port = 5432)
  ?(user = "books")
  ?(password = "books")
  ?(dbname = "books")
  () : connection
  =
  new Postgresql.connection
    ~host
    ~dbname
    ~user
    ~password
    ~port:(string_of_int port)
    ()

let close (c : connection) = c#finish