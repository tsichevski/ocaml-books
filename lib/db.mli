(** Database interface for persistent book indexing.

    Uses PostgreSQL via the ``ocaml-postgresql`` library.
    Stores book metadata (keyed by digest) and normalized author information
    with a many-to-many link table.

    All text is expected to be UTF-8. Optional fields are stored as real SQL NULL.
*)

open Book
open Person

(** {1 Types} *)

type connection
(** Abstract type representing an open PostgreSQL connection. *)

type book_id = string
(** Internal database primary key for a book (as string). *)

type person_id = string
(** Internal database primary key for a person (as string). *)

(** {1 Connection management} *)

val connect :
  ?host:string ->
  ?port:int ->
  ?user:string ->
  ?password:string ->
  ?dbname:string ->
  unit -> connection
(** [connect ?host ?port ?user ?password ?dbname ()] establishes a connection
    to the PostgreSQL server using the given parameters (or defaults).

    @raise Failure if the connection cannot be established.
*)

val close : connection -> unit
(** [close conn] closes the database connection.

    Safe to call multiple times (idempotent).
*)

(** {1 Schema management} *)

val init_schema : connection -> unit
(** [init_schema conn] creates the required tables ([books], [persons], [book_authors])
    and indexes if they do not exist.

    The operation is idempotent and includes primary keys, unique constraints,
    and foreign keys with ON DELETE CASCADE.

    Example:

    {[
      let conn = Db.connect () in
      Db.init_schema conn
    ]}
*)

val drop_schema : connection -> unit
(** [drop_schema conn] drops all library tables (books, persons, book_authors).

    Use with extreme caution — this is irreversible and intended only for testing/reset.
*)

(** {1 Person (author) operations} *)

val find_or_insert_person : connection -> person -> person_id
(** [find_or_insert_person conn p] looks up the person by its normalized name;
    inserts a new record using UPSERT if not found.

    Guarantees exactly-once semantics even under concurrent access.

    @return internal database ID of the person (as string)
    @raise Failure on database errors or integrity violations
*)

(** {1 Book operations} *)

val find_or_insert_book : connection -> book -> book_id
(** [find_or_insert_book conn b] ensures the book exists (keyed by its digest)
    and links all its authors.

    - If the book does not exist → inserts it and links all authors.
    - If the book exists → links any missing authors only.

    @return internal database ID of the book (as string)
    @raise Failure on database errors or integrity violations
*)

val delete_book : connection -> book -> book_id
(** [delete_book conn b] deletes the book identified by its digest and title.

    @return the internal ID of the deleted book
    @raise Failure if no matching book was found
*)

(** {1 Low-level helpers (for advanced use)} *)

val insert_book : connection -> book -> book_id
val insert_person : connection -> string -> person -> person_id
val find_person_opt : connection -> string -> person_id option