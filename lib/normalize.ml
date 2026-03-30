(** String normalization utilities for book metadata and filenames.

    This module provides functions to clean and normalize names and titles extracted
    from FB2 files (especially Russian-language books). It:

    - Keeps only alphabetic Unicode characters (discards punctuation, digits, symbols).
    - Replaces both Ё and ё with е (standard practice in Russian book indexing).
    - Applies title-case.
    - Returns [None] for strings that become blank after cleaning.

    These functions are used when building stable [Person.id] and [Book.id] values,
    as well as for creating filesystem-safe directory names.
*)

(** [normalize_chunk s] processes a single "word" chunk.

    It:
    - Filters out anything that is not an alphabetic character (using [Uucp.Alpha.is_alphabetic]).
    - Replaces Ё (U+0401) and ё (U+0451) with е (U+0435).
    - Title-cases the result.
    - Returns [None] if the result is empty after trimming.

    Example:

    {[
      normalize_chunk "Лев Николаевич" = Some "Левниколаевич"   (* note: no space inside chunk *)
      normalize_chunk "!!! ТОЛСТОЙ !!!" = Some "Толстой"
      normalize_chunk "  " = None
    ]}
*)
let normalize_chunk s =
  let b = Buffer.create (String.length s) in
  Uutf.String.fold_utf_8
    (fun _ _ u ->
      match u with
      | `Uchar u ->
        if Uucp.Alpha.is_alphabetic u then
          begin
            let cp = Uchar.to_int u in
            let u =
              if cp = 0x0401 || cp = 0x0451 then  (* Ё or ё *)
                Uchar.of_int 0x0435                 (* е *)
              else
                u
            in
            let func =
              if Buffer.length b = 0 then
                Uucp.Case.Map.to_upper
              else
                Uucp.Case.Map.to_lower
            in
            match func u with
            | `Self -> Uutf.Buffer.add_utf_8 b u
            | `Uchars l -> List.iter (fun u -> Uutf.Buffer.add_utf_8 b u) l
          end
      | `Malformed e ->
          failwith (Printf.sprintf
            "Malformed UTF-8 character in normalize_chunk.\n\
             Input snippet: [%s]\n\
             Error: %s" (String.sub s 0 (min 30 (String.length s))) e)
    )
    () s;
  Buffer.contents b |> Utils.trim_opt

(** [normalize_name s] normalizes a full name or title.

    It:
    - Splits [s] on the hyphen character '-',
    - Applies [normalize_chunk] to each part,
    - Filters out empty results,
    - Joins surviving parts back with a single space,
    - Trims the final string.

    Returns [None] if the entire result would be empty (e.g. only punctuation or whitespace).

    Example:

    {[
      normalize_name "Лев Николаевич Толстой" = Some "Лев Николаевич Толстой"
      normalize_name "Толстой, Л. Н."         = Some "Толстой Л Н"
      normalize_name "!!!   "                 = None
      normalize_name "War and Peace"          = Some "War And Peace"
    ]}
*)
let normalize_name s : string option =
  Utils.filter_map_concat s '-' normalize_chunk