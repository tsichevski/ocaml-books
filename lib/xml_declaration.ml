open Utils

let extract_encoding (declaration : string) : string =
  let start_encoding = "encoding=\"" in
  match substring_index declaration start_encoding with
  | None -> "utf-8"
  | Some pos ->
    let start_pos = pos + String.length start_encoding in
    if start_pos >= String.length declaration then
      "utf-8"
    else
      (match String.index_from_opt declaration start_pos '"' with
       | None -> "utf-8"
       | Some end_pos ->
         String.sub declaration start_pos (end_pos - start_pos)
         |> String.lowercase_ascii)

(** [read_until_marker_exn ic buf] continues reading from channel until "?>" is found.

    Assumes "<?xml" was seen already .
    Returns (encoding, declaration_string).

    Throws error if EOF reached prematurely
*)
let rec read_until_marker_exn (ic : In_channel.t) (buf : Buffer.t) : string * string =
  match In_channel.input_char ic with
  | None -> 
    (* EOF without ?>: incomplete declaration *)
    failwith "XML declaration Incomplete"
  | Some '?' ->
    Buffer.add_char buf '?';
    (match In_channel.input_char ic with
     | Some '>' ->
       Buffer.add_char buf '>';
       let decl = Buffer.contents buf in
       let enc = extract_encoding decl in
       (enc, decl)
     | Some c ->
       Buffer.add_char buf c;
       read_until_marker_exn ic buf
     | None ->
       failwith "XML declaration Incomplete")
  | Some c ->
    Buffer.add_char buf c;
    read_until_marker_exn ic buf

let read_declaration ic : string * string =
  let init_pos = In_channel.pos ic in
  let buf = Buffer.create 256 in

  (* Check if file starts with <?xml *)
  let magic = Bytes.create 5 in
  let bytes_read = In_channel.input ic magic 0 5 in
  if bytes_read < 5 || not (String.equal (Bytes.to_string magic) "<?xml") then
    begin
      (* Does not start with <?xml *)
      (* Rewind the pos back to initial*)
      In_channel.seek ic init_pos;
      ("utf-8", "")
    end    
  else
    begin
      Buffer.add_bytes buf magic;
      read_until_marker_exn ic buf
    end

