(* Misc utility functions missing in stdlib *)

(** [substring_index_from haystack needle start] searches for the first occurrence
    of substring [needle] in [haystack], starting the search at byte position [start]
    (inclusive, 0-based).

    Returns [Some pos] where [pos] is the starting byte index of the first match,
    or [None] if no match is found.

    @param haystack the string to search in
    @param needle   the substring to find (may be empty)
    @param start    starting search position (0 ≤ start ≤ String.length haystack)
    @return [Some pos] or [None]

    Performance note: O(n·m) worst-case (linear scan with substring comparison).
    Suitable for typical metadata/filename lengths in this project.

    Special case: if [needle] is empty string, returns [Some start] (standard convention).

    Raises nothing. *)
let substring_index_from haystack needle start =
  let n_len = String.length needle in
  if n_len = 0 then Some start
  else
    let rec loop pos =
      (* Check if remaining suffix is long enough to contain needle *)
      if pos + n_len > String.length haystack then None
      (* Compare substring starting at pos *)
      else if String.sub haystack pos n_len = needle then Some pos
      else loop (pos + 1)
    in loop start

(** [substring_index haystack needle] searches for the first occurrence
    of substring [needle] in [haystack], starting from position 0.

    Equivalent to [substring_index_from haystack needle 0].

    @param haystack the string to search in
    @param needle   the substring to find
    @return [Some pos] or [None] *)
let substring_index haystack needle =
  substring_index_from haystack needle 0

(** [trim_opt s] removes leading and trailing whitespace from the string [s].

    If the resulting string is empty (i.e. [s] contained only whitespace),
    it returns [None]. Otherwise it returns [Some trimmed_string].

    This is useful when you want to treat a whitespace-only string
    the same as an absent value.

    {b Example:}

    {[
      trim_opt "  hello world  " = Some "hello world"
      trim_opt "   " = None
      trim_opt "" = None
    ]}
*)
let trim_opt s =
  match String.trim s with
  | "" -> None
  | s  -> Some s
  
(** [filter_map_concat_list l ch f] applies the function [f] to each l item,
    filters out [None] values, and if any non-[None] results remain, concatenates
    them back using [ch] as separator, trims the final string, and returns [Some result].
    Returns [None] if the final result would be empty or if no
    parts survived the mapping/filtering.
*)
let filter_map_concat_list l ch f =
  match
    List.map f l |> List.filter_map Fun.id
  with
  | [] -> None
  | l ->
    String.concat (String.make 1 ch) l |> trim_opt

(** [filter_map_concat s ch f] splits the string [s] on character [ch],
    and passes the result to [filter_map_concat_list]
*)
let filter_map_concat s sep f =
  filter_map_concat_list (String.split_on_char sep s) sep f

let ic_to_seq ic =
  let rec make () =
    match In_channel.input_byte ic with
    | Some b ->
      Seq.Cons ((Char.chr b), make)
    | None -> Seq.Nil
  in
  make

