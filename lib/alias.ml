(** Author alias handling for book metadata normalization.

    This module provides utilities to load and apply author aliases from a JSON file.
    Aliases allow mapping variant spellings, pseudonyms, or different transliterations
    of the same person to a single canonical [Person.person] record.

    The resulting hash table is used during FB2 parsing (in [Fb2_parse]) to replace
    alias names with their canonical form, ensuring correct grouping of books by author.
*)

open Person

(** [person_from_string_exn s] parses a string into a {!Person.person} record.

    Expected format: space-separated parts in the order
    last_name first_name middle_name.

    - At least the last name must be present.
    - First name and middle name are optional.
    - Extra spaces around parts are trimmed automatically.

    Raises [Failure] with a descriptive message if the string cannot be parsed
    according to the rules (wrong number of parts after splitting, or empty name).

    Example (successful):

    {[
      person_from_string_exn "Толстой Лев Николаевич"
      (* returns person with id = "толстой лев николаевич" *)
    ]}

    Example (failure):

    {[
      person_from_string_exn ""
      (* raises Failure with message containing the empty string *)
    ]}
*)
let person_from_string_exn s : person =
  let parts = String.split_on_char ' ' s
    |> List.map String.trim
    |> List.filter (fun p -> p <> "") in
  match parts with
  | [last_name; first_name; middle_name] ->
      person_create_exn (Some last_name) (Some first_name) (Some middle_name)
  | [last_name; first_name] ->
      person_create_exn (Some last_name) (Some first_name) None
  | [last_name] ->
      person_create_exn (Some last_name) None None
  | _ ->
      failwith (Printf.sprintf
        "Cannot parse string to person: [%s]\n\
         Expected format: \"Last First Middle\" (middle name optional)" s)

(** [load_aliases path] loads an author alias table from a JSON file at [path].

    Expected JSON structure:

    {[
      {
        "Canonical Last First Middle": ["alias1", "alias2", ...],
        "Another Author Last First": ["nick1", "nick2"]
      }
    ]}

    * Each key is a canonical person string (passed to [person_from_string_exn]).
    * Each value is a JSON array of alias strings.

    All strings (keys and aliases) are automatically trimmed.
    Duplicate aliases are allowed (later ones overwrite earlier ones in the table).

    Returns a hash table where:
    - key   = trimmed alias string
    - value = canonical {!Person.person} record

    Raises:
    - [Failure] if the root JSON value is not an object.
    - Failures from [person_from_string_exn] if a canonical string is malformed.
    - Malformed entries inside the object (non-string aliases or non-list values)
      are silently ignored.

    Example usage in configuration:

    The table is typically loaded once at startup and passed to [Fb2_parse.parse_book_info].

    Example JSON snippet for aliases:

    {[
      {
        "Толстой Лев Николаевич": ["Толстой Л.Н.", "Leo Tolstoy", "Толстой Л Н"]
      }
    ]}
*)
let load_aliases path : (string, person) Hashtbl.t =
  let json = Yojson.Safe.from_file path in
  let table = Hashtbl.create 512 in
  begin match json with
  | `Assoc obj ->
      List.iter (fun (canonical, aliases_json) ->
        match aliases_json with
        | `List alias_list ->
            List.iter (function
              | `String alias ->
                  let trimmed_alias = String.trim alias in
                  let canonical_person = person_from_string_exn (String.trim canonical) in
                  Hashtbl.add table trimmed_alias canonical_person
              | _ -> ()
            ) alias_list
        | _ -> ()
      ) obj
  | _ ->
      failwith (Printf.sprintf
        "aliases.json must be a JSON object (got wrong root type).\n\
         File: %s" path)
  end;
  table