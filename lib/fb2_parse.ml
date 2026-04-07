(** FB2 parser for extracting book metadata.

    This module provides streaming XML parsing of FictionBook 2.1 files using [Xmlm].
    It handles character recoding (UTF-8, CP1251, KOI8-R), extracts <title-info>
    and <document-info> metadata, builds [Book.book] records, and supports author
    aliasing.

    Parsing is path-based and event-driven: the parser walks the XML tree and
    collects data when specific element paths are matched.

    Raises [Fb2_parse_error] or [Failure] on malformed or incomplete FB2 files.
*)

open Xmlm
open Book
open Person

exception Fb2_parse_error of string

module Log = (val Logs.src_log (Logs.Src.create "fb2_parse" ~doc:"Parsing FB2 document") : Logs.LOG)

(** [parse input handle path] is the core recursive streaming parser.

    It consumes XML signals from [input] and calls [handle] for every element start,
    end, or data chunk. [path] is the current element stack (reversed).

    The [handle] function receives [Some trimmed_data] for text nodes or [None] for
    element starts, and the current path. It should return [true] to stop early.

    Example usage: see [locate] and [parse_book_info].
*)
let rec parse input handle path =
  let signal = Xmlm.input input in
  match signal with
  | `Dtd _ ->
      parse input handle path
  | `El_start ((_, tag), _) ->
      let path' = tag :: path in
      handle None path' || parse input handle path'
  | `El_end ->
      (match path with
       | [_] -> false  (* root element closed → exit *)
       | hd :: tl -> parse input handle tl
       | [] -> failwith "Invalid XML: element END tag without START")
  | `Data txt ->
      let trimmed = String.trim txt in
      (not (String.equal trimmed "") && handle (Some trimmed) path)
      || parse input handle path

(** [locate input path] parses document until the exact element path exists in the document.
    returns [true] if the element path was found, otherwise returns false 
*)
let locate input path = parse input (fun _txt path' -> List.equal String.equal path path') []

(** [parse_visit path h] opens the file, detects encoding from XML declaration,
    sets up a recoding channel, and runs the handler [h] on the [Xmlm] input.

    Supported encodings: utf-8, windows-1251/cp1251, koi8-r.
    Raises [Failure] for unsupported encodings.
*)
let parse_visit path h =
  In_channel.with_open_bin path
    (fun ic ->
      let encoding, _ = Xml_declaration.read_declaration ic in
      let src = Utils.ic_to_seq ic in
      let seq =
        if encoding = "utf-8" then
          src
        else
          let create = 
            match encoding with
            | "windows-1251" | "cp1251" -> Recoding_channel.create_cp1251
            | "windows-1252" | "cp1252" -> Recoding_channel.create_cp1252
            | "windows-1255" | "cp1255"  -> Recoding_channel.create_cp1255
            | "iso-8859-1" -> Recoding_channel.create_iso8859_1
            | "iso-8859-5" -> Recoding_channel.create_iso8859_5
            | "koi8-r" -> Recoding_channel.create_koi8r
            | _ -> failwith (Printf.sprintf "Unsupported encoding in %s: %s" path encoding)    
          in
          create src |> Recoding_channel.to_seq
      in
      let fn () =
        match Seq.uncons seq with
        | None -> raise End_of_file
        | Some (c, _) -> Char.code c
      in
      let input = Xmlm.make_input (`Fun fn) in
      h input encoding
    )

(** [validate path] performs a minimal parse to check that the FB2 file is well-formed XML
    and contains at least a root element. Does not extract metadata.
*)
let validate path =
  parse_visit path (fun input _ -> ignore (parse input (fun _ _ -> false) []))

(** [parse_book_info path aliases] extracts full book metadata from an FB2 file.

    It collects:
    - title, authors (with deduplication), language, genre from <title-info>
    - id and version from <document-info>

    [aliases] is an optional hashtable for author name normalization (e.g. pseudonyms).

    Raises:
    - [Fb2_parse_error] if no <book-title> is found or the <description> section is missing.
*)
let parse_book_info path aliases =
  parse_visit path
    (fun input encoding ->
      if locate input ["description"; "FictionBook"] then
        let authors = ref [] in
        let current_first_name = ref None in
        let current_middle_name = ref None in
        let current_last_name = ref None in
        let id = ref None in
        let title = ref None in
        let lang = ref None in
        let genre = ref None in
        let version = ref None in

        (** Append the currently collected author (if valid) and clear the buffers.
            Skips duplicates based on normalized id. Applies aliases if provided. *)
        let append_current_author_unique () =
          match !current_last_name, !current_first_name, !current_middle_name with
          | None, _, None ->
              current_middle_name := None
          | last_name, first_name, middle_name ->
              match normalize last_name first_name middle_name with
              | None ->
                  Log.warn (fun m -> m "Ignoring author with name that normalized to empty in %s" path)
              | Some _id ->
                  let candidate = person_create_exn last_name first_name middle_name in
                  let candidate =
                    match aliases with
                    | None -> candidate
                    | Some table ->
                        match Hashtbl.find_opt table candidate.id with
                        | None -> candidate
                        | Some e ->
                            Log.debug (fun m -> m "Alias %s replaced by %s in %s" candidate.id e.id path);
                            e
                  in
                  if not (List.exists (fun y -> y.id = candidate.id) !authors) then
                    authors := candidate :: !authors;

                  current_first_name := None;
                  current_middle_name := None;
                  current_last_name := None
        in

        ignore (parse input (fun txt path ->
          match txt with
          | None -> (* Element start *)
              (match path with
               | ["author"; ("title-info" | "document-info"); "description"] ->
                   append_current_author_unique ()
               | _ -> ());
              false
          | Some v ->
              let value = Some (String.trim v) in
              (match path with
               | ["first-name"; "author"; ("title-info" | "document-info"); "description"] ->
                   current_first_name := value
               | ["middle-name"; "author"; ("title-info" | "document-info"); "description"] ->
                   current_middle_name := value
               | ["last-name"; "author"; ("title-info" | "document-info"); "description"] ->
                   current_last_name := value
               | ["id"; "document-info"; "description"] ->
                   id := value
               | ["version"; "document-info"; "description"] ->
                   version := value
               | ["book-title"; "title-info"; "description"] ->
                   title := value
               | ["lang"; "title-info"; "description"] ->
                   lang := value
               | ["genre"; "title-info"; "description"] ->
                   genre := value
               | _ -> ());
              false
        ) ["description"]);

        append_current_author_unique ();

        let filename = Filename.basename path |> Filename.chop_extension in
        let title_str =
          match !title with
          | None -> raise (Fb2_parse_error (Printf.sprintf "Book has no title in file: %s" path))
          | Some t -> t
        in
        let authors_list = List.rev !authors in

        book_create_exn
          title_str
          authors_list
          !id
          !version
          !lang
          !genre
          filename
          encoding
      else
        raise (Fb2_parse_error (Printf.sprintf "%s: no 'description' XML element found" path))
    )