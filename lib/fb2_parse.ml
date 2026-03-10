(*
  Simplified FB2 parser using xmlm's built-in encoding detection.
*)

open Base
open Core
open Xmlm
(* open Ocaml_books.Recoding_channel *)

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
     | [_] -> false (* Closing the root element, exiting *)
     | hd :: tl ->
       parse input handle tl
     | _ ->
       failwith "Invalid XML: END without start")
  | `Data txt ->
    let trimmed = String.strip txt in
    (not (String.is_empty trimmed) && handle (Some trimmed) path) || parse input handle path

let locate input path = parse input (fun txt path' -> List.equal String.equal path path') []

type title_info = {
  title: string option;
  first_name: string option;
  middle_name: string option;
  last_name: string option;
  lang: string option;
  genre: string option;
}

(** Parse the title-info element contents *)
let collect_title_info input =
  let title = ref None
  and first_name = ref None
  and middle_name = ref None
  and last_name = ref None
  and lang = ref None
  and genre = ref None in
  ignore (parse input (fun txt path ->
      (match txt with
       | None -> ()
       | Some v ->
         match path with
         | ["first-name"; "author"; "title-info"] -> first_name := txt
         | ["last-name"; "author"; "title-info"] -> last_name := txt
         | ["middle-name";"author"; "title-info"] -> middle_name := txt
         | ["book-title"; "title-info"]  -> title := txt
         | ["lang"; "title-info"]  -> lang := txt
         | ["genre"; "title-info"]  -> genre := txt
         | _ -> ()
      );
      false)
      ["title-info"]);
  { title = !title;
    first_name = !first_name;
    middle_name = !middle_name;
    last_name = !last_name;
    lang = !lang;
    genre = !genre;
  }


(* let () = *)
(*   In_channel.with_file "/tmp/books/incoming/701300.fb2" ~binary:true ~f: *)
(*     (fun ic -> *)
(*        let input = Xmlm.make_input (`Channel ic) in *)
(*        if locate input ["title-info"; "description"; "FictionBook"] then *)
(*          begin *)
(*            let p = collect_title_info input in *)
(*            printf "title = %s;\nfirst = %s;\nmiddle = %s;\nlast = %s;\ngenre = %s;\nlang = %s\n" *)
(*              (Option.value ~default:"-" p.title) *)
(*              (Option.value ~default:"-" p.first_name) *)
(*              (Option.value ~default:"-" p.middle_name) *)
(*              (Option.value ~default:"-" p.last_name) *)
(*              (Option.value ~default:"-" p.genre) *)
(*              (Option.value ~default:"-" p.lang) *)
(*          end          *)
(*        else *)
(*          failwith "No title-info found" *)

(*     ) *)

(** [parse_title_author path] reads an FB2 file with automatic encoding detection.

    Uses xmlm which automatically:
    - Detects encoding from <?xml encoding="..."?>
    - Converts to UTF-8 internally
    - Provides streaming (SAX-style) event parsing

    Returns (author_name, title) tuple.
*)
let parse_title_author path =
  In_channel.with_file path ~binary:true ~f:
    (fun ic ->
       let enc, _ = Xml_declaration.read_declaration ic in
       let rindex = match enc with
         | "utf-8" -> Recoding_channel.create_norecode ic
         | "windows-1251" | "cp1251" -> Recoding_channel.create_cp1251 ic
         | "koi8-r" -> Recoding_channel.create_koi8r ic
         | _ -> failwith ("Unsupported encoding: " ^ enc)
       in
       let fn () =
         match Recoding_channel.input_byte rindex with
         | None -> -1
         | Some c -> c
       in  
       let input = Xmlm.make_input (`Fun fn) in
       if locate input ["title-info"; "description"; "FictionBook"] then
         let p = collect_title_info input in
         let author_parts = List.filter_map ~f:Fn.id ( [p.first_name; p.middle_name; p.last_name] )
         in
         let author = match author_parts with
           | [] -> None
           | parts -> Some (String.concat ~sep:" " parts)
         in
         (author, p.title)
       else
         raise (Fb2_parse_error (sprintf "%s: no 'title-info' XML element found" path))
    );
