(** Streaming FB2 2.1 parser.

    This module provides functions to parse FictionBook (.fb2) files using a
    streaming XML parser ([Xmlm]). It extracts metadata into a {!Book.book}
    record, handles character recoding for legacy Russian encodings, and
    supports author alias substitution.

    Parsing is path-based and event-driven. The module also includes a minimal
    validation function for quick sanity checks.
*)

open Book
open Person

(** {1 Exceptions} *)

exception Fb2_parse_error of string
(** Raised when the FB2 structure is invalid or required sections are missing.
    The string contains a descriptive message including the file path when possible.
*)

(** {1 Main parsing functions} *)

val parse_book_info :
  string -> (string, person) Hashtbl.t option -> book
(** [parse_book_info path aliases] parses a single FB2 file at [path] and
    returns a fully populated {!Book.book} record.

    @param path Path to the .fb2 file (can be inside a ZIP, but the file must
           be extracted first).
    @param aliases Optional hash table of author aliases (see {!Alias.load_aliases}).
           If provided, matching author names are replaced by their canonical form.

    @return A {!Book.book} with:
            - normalized title and authors
            - extracted language, genre, ext_id, version
            - original filename and detected encoding

    @raise Fb2_parse_error if the <description> section is missing or malformed.
    @raise Failure if the book has no title (via {!Book.book_create_exn}).
    @raise Failure for unsupported encodings (via recoding layer).
*)

val validate : string -> unit
(** [validate path] performs a minimal parse to verify that the file is a
    well-formed FB2 document with at least a root <FictionBook> element.

    Does not extract metadata. Useful for quick filtering of corrupt or
    non-FB2 files before full parsing.

    @raise Fb2_parse_error or Failure on malformed XML or missing root element.
*)

(** {1 Low-level helpers (exposed for testing / advanced use)} *)

val locate : Xmlm.input -> string list -> bool
(** [locate input path] returns [true] if the exact element path exists
    anywhere in the document.

    The path is given as a reversed list of tag names (e.g. ["book-title"; "title-info"; "description"]).
    Used internally by the parser.
*)

val parse_visit :
  string ->
  (Xmlm.input -> string -> unit) -> unit
(** [parse_visit path handler] opens the file, detects its XML encoding,
    sets up the appropriate recoding channel (UTF-8, CP1251, KOI8-R),
    and passes the [Xmlm.input] to the provided [handler].

    The handler receives the input and the detected encoding string.

    This is the common entry point used by both [validate] and [parse_book_info].
*)

(** {1 Notes} *)

(* Supported encodings (detected from XML declaration):
   - "utf-8"
   - "windows-1251" / "cp1251"
   - "koi8-r"

   Any other encoding raises Failure with a descriptive message.
*)