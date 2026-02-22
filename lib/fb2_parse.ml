(*
  utop:
#require "xml-light";;
 *)

open Xml

exception Fb2_parse_error of string

(** [find_child tag_name node] returns the first child element of [node]
    whose tag name is exactly [tag_name].

    @param tag_name The expected tag name (case-sensitive)
    @param node The parent XML node to search in
    @return The matching child element
    @raise Not_found if no child with the given tag name exists

      Example:
      {[
      let title_info =
        try
          let description = find_child "description" xml in
          find_child "title-info" description
        with Not_found ->
          raise (Fb2_parse_error "Missing required FB2 structure")
      ]}
 *)
let find_child (tag_name : string) (node : Xml.xml) : Xml.xml =
  List.find (fun child ->
      match child with
      | Xml.Element (name, _, _) -> name = tag_name
      | _ -> false
    ) (Xml.children node)

let get_text tag_name parent : string =
  try
    match find_child tag_name parent with
    | Xml.Element (_, _, [Xml.PCData txt]) -> String.trim txt
    | Xml.Element (_, _, [])               -> ""
    | _ ->
        raise (Fb2_parse_error (
          Printf.sprintf "<%s> is not a simple text element" tag_name
        ))
  with Not_found ->
    ""

(** [parse_title_author path] reads an FB2 file (assumed to be valid UTF-8 XML)
    and extracts:

    - book title (from <book-title>)
    - author name (joins <first-name> <middle-name> <last-name> from the first <author> element)

    Returns (author_name, title, path) triple.

    Raises [Fb2_parse_error] on missing required tags or malformed structure.
    Raises [Sys_error] / [Xml.Error] on file/XML parsing issues.
 *)
let parse_title_author (path : string) : string * string * string =
  let ic = open_in path in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;

  let xml =
    try parse_string content
    with Xml.Error (msg, pos) ->
      let pos_str =
        Printf.sprintf "line %d (bytes %d–%d)"
          pos.eline pos.emin pos.emax
      in
      raise (Fb2_parse_error (
        Printf.sprintf "Invalid FB2 XML in %s at %s: %s"
          path pos_str (Xml.error_msg msg)
      ))
  in

  (* Validate root tag *)
  (match xml with
   | Xml.Element ("FictionBook", _, _) -> ()
   | Xml.Element (tag, _, _) ->
      raise (Fb2_parse_error (
                 Printf.sprintf "%s: root element is <%s>, expected <FictionBook>" path tag
        ))
   | Xml.PCData _ ->
      (* This can never happen! *)
      raise (Fb2_parse_error (
                 Printf.sprintf "%s: root level text content (not valid FB2)" path
  )));
  (* rest of parsing: title_info, title, author … *)
  let title_info =
    try
      let description = find_child "description" xml in
      find_child "title-info" description
    with Not_found ->
      raise (Fb2_parse_error (Printf.sprintf "%s: cannot deduce <title-info>" path))
  in
  let title  = get_text "book-title"  title_info in
  let author =
    try
      let author_tag = find_child "author" title_info in
      let parts = [
          get_text "first-name"  author_tag;
          get_text "middle-name" author_tag;
          get_text "last-name"   author_tag] in
      let name = String.concat " " parts |> String.trim in
      if name = "" then "Unknown Author" else name
    with Not_found ->
      "Unknown Author"
  in

  (author, title, path)

