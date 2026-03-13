open Xmlm
open Book

exception Fb2_parse_error of string

let rec parse input handle path =
  let signal = Xmlm.input input in
  match signal with
  | `Dtd None -> 
    parse input handle path
  | `Dtd (Some dtd) ->
    parse input handle path
  | `El_start ((_, tag), _) ->
    let path' = tag::path in
    handle None path' || parse input handle path'
  | `El_end ->
    (match path with
     | [_] -> false (* We are closing the root element, exit *)
     | hd :: tl ->
       parse input handle tl
     | _ ->
       failwith "Invalid XML: element END tag without START")
  | `Data txt ->
    let trimmed = String.trim txt in
    (not (String.(empty = trimmed)) && handle (Some trimmed) path) || parse input handle path

let locate input path = parse input (fun txt path' -> List.equal String.equal path path') []

(** Parse the title-info element contents *)
let collect_title_info input =
  let authors = ref [] in
  let current_first_name = ref None in
  let current_middle_name = ref None in
  let current_last_name = ref None in
  let title = ref None in
  let lang = ref None in
  let genre = ref None in

  let append_current_author () =
    match !current_first_name, !current_middle_name, !current_last_name with
    | None, None, None -> ()
    | f, m, l ->
      authors := { first_name = f; middle_name = m; last_name = l } :: !authors;
      current_first_name := None;
      current_middle_name := None;
      current_last_name := None
  in

  ignore (parse input (fun txt path ->
    match txt with
    | None -> (* Element start *)
      (match path with
       | ["author"; ("title-info" | "document-info"); "description"] ->
         append_current_author ()
       | _ -> ());
      false
    | Some v ->
      (match path with
       | ["first-name"; "author"; ("title-info" | "document-info"); "description"] ->
         current_first_name := Some v
       | ["middle-name"; "author"; ("title-info" | "document-info"); "description"] ->
         current_middle_name := Some v
       | ["last-name"; "author"; ("title-info" | "document-info"); "description"] ->
         current_last_name := Some v
       | ["book-title"; "title-info"; "description"] ->
         title := Some v
       | ["lang"; "title-info"; "description"] ->
         lang := Some v
       | ["genre"; "title-info"; "description"] ->
         genre := Some v
       | _ -> ());
      false
  ) ["description"]);

  append_current_author (); (* Append the last author if any *)

  { title = !title;
    authors = List.rev !authors;
    lang = !lang;
    genre = !genre;
  }

let parse_title_author path =
  In_channel.with_open_bin path 
    (fun ic ->
       let enc, _ = Xml_declaration.read_declaration ic in
       let rindex = match enc with
         | "utf-8" -> Recoding_channel.create_direct ic
         | "windows-1251" | "cp1251" -> Recoding_channel.create_cp1251 ic
         | "koi8-r" -> Recoding_channel.create_koi8r ic
         | _ -> failwith ("Unsupported encoding: " ^ enc)
       in
       let fn () =
         match Recoding_channel.input_byte rindex with
         | None -> raise End_of_file
         | Some c -> c
       in  
       let input = Xmlm.make_input (`Fun fn) in
       if locate input ["description"; "FictionBook"] then
         collect_title_info input
       else
         raise (Fb2_parse_error (Printf.sprintf "%s: no 'description' XML element found" path))
    );