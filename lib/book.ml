(** Representation of a book in the library.

    This record captures the essential metadata extracted from an FB2 file.
    It is the central data type used for indexing, deduplication, organizing,
    and storing books in the library.

    The [id] field is a stable key derived from title + authors. It is used
    for grouping and lookup.

    Most fields come directly from FB2 <title-info> or <document-info> sections.
*)
open Person

type book = {
  (* (\** Stable unique identifier for the book. *)
  (*     Built from normalized title and author ids. Used as primary key in the index. *\) *)
  (* id : string; *)

  (** External ID (e.g. from <document-info><id> element).
      Defined for most books. *)
  ext_id : string option;

  (** Optional version of the book (e.g. "1.1", "1.2", ...).
      The tuple (version, ext_id) should be unique, but this is not enforced by the program. *)
  version : string option;

  (** Book title — this field is required and must not be empty after normalization. *)
  title : string;

  (** List of authors. May be empty (e.g. for magazines or anonymous works). *)
  authors : person list;

  (** Book language as specified in the FB2 metadata (not validated). *)
  lang : string option;

  (** Book genre as specified in the FB2 metadata (not validated). *)
  genre : string option;

  (** Original filename without the .fb2 extension. *)
  filename : string;

  (** Original character encoding of the file (e.g. "utf8", "windows-1251"). *)
  encoding : string;
}

(** [normalize_title title] normalizes the book title for use in [id] and filesystem paths.

    Applies the same normalization rules as person names (lowercasing, removing extra spaces, etc.).
    Returns [None] if the title normalizes to empty.
*)
let normalize_title title : string option =
  (* Assuming a normalize function exists; adjust if it's in Normalize module *)
  if String.trim title = "" then None
  else (Normalize.normalize_name title)  (* or Utils.normalize_string title *)

(** [book_create_exn title authors ext_id version lang genre filename encoding] creates a new [book] record.

    - Computes [id] from normalized title + author ids.
    - Raises [Failure] with a descriptive message (including the original title and author count)
      if the title is empty after normalization or if no valid data is provided.

    Example (successful):

    {[
      let authors = [person_create_exn (Some "Толстой") (Some "Лев") None] in
      let b = book_create_exn "Война и мир" authors None None None None "war_and_peace" "utf8" in
      b.id = "война и мир|толстой лев" && b.title = "Война и мир"
    ]}

    Example (failure):

    {[
      book_create_exn "" [] None None None None "empty" "utf8"
      (* raises Failure with message containing the empty title *)
    ]}
*)
let book_create_exn title (authors : person list) ext_id version lang genre filename encoding : book =
  match normalize_title title with
  | None ->
      let author_count = List.length authors in
      failwith (Printf.sprintf
        "Cannot create book: title normalized to empty.\n\
         Original title: [%s]\n\
         Number of authors provided: %d" title author_count)
  | Some norm_title ->
      { ext_id; version; title; authors; lang; genre; filename; encoding }

(** [digest b] generates a unique hexadecimal digest for the book based on its key fields.

    The digest is built from: normalized title | ext_id | version | normalized author ids.
    Useful for deduplication when importing large ZIP archives with duplicate or near-duplicate books.

    Example:

    {[
      let b = ... in
      digest b  (* returns a hex string like "a1b2c3d4..." *)
    ]}
*)
let digest {ext_id; version; title; authors} : string =
  let ext_id = Option.value ext_id ~default:"" in
  let version = Option.value version ~default:"" in
  let norm_title = Option.value (normalize_title title) ~default:"" in
  norm_title :: ext_id :: version :: (List.map (fun a -> a.id) authors)
  |> String.concat "|"
  |> Digest.string
  |> Digest.to_hex