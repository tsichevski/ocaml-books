(*
  XML declaration parser.

  Extracts encoding information from <?xml ... encoding="..."?> declaration.
  Works for files of any size - no fixed buffer limits.

  Safe for any encoding because the declaration syntax itself is ASCII-compatible.
 *)

(** [extract_encoding declaration] parses encoding from XML declaration string.

    Example: extract_encoding "<?xml version=\"1.0\" encoding=\"windows-1251\"?>"
    Returns: "windows-1251"

    Returns "utf-8" if no encoding attribute found (per XML 1.0 spec).

    Uses simple substring matching which is safe because the entire
    declaration is ASCII, even if the file content uses a different encoding.
*)
val extract_encoding : string -> string

(** [read_declaration ic] reads and parses the XML declaration from the start of a file.

    Reads byte-by-byte until "?>" marker is found. Works for any file encoding
    because the declaration syntax (<?xml version="..." encoding="..."?>) is ASCII-safe.

    Returns (encoding, declaration_string) where:
    - encoding: detected encoding name (lowercase), defaults to "utf-8"
    - declaration_string: the raw <?xml...?> text (for debugging)

    If no declaration found (file doesn't start with <?xml), returns ("utf-8", "").
    If file ends before declaration is complete, returns ("utf-8", partial_declaration).
*)
val read_declaration : in_channel -> string * string
