type t = {
  mutable underlying : char Seq.t;   (* source of bytes *)
  buffer : Buffer.t;                 (* recorded bytes since the mark *)
  mutable read_pos : int;            (* In-buffer reading position *)
  mutable recording : bool;          (* are we currently recording? *)
}

let create s = {
  underlying = s;
  buffer = Buffer.create 256;        (* initial capacity, grows as needed *)
  read_pos = 0;
  recording = false;
}

(** Start recording *)
let mark m =
  m.recording <- true

(** Revert to mark *)
let reset m =
  m.recording <- false

(** Commit transaction *)
let drop_mark m =
  Buffer.clear m.buffer;
  m.read_pos <- 0;
  m.recording <- false
  
;;
(* Returns the current view as a char Seq.t *)
let to_seq m =
  let rec make () =
    if m.recording then
      match Seq.uncons m.underlying with
      | None -> Seq.Nil
      | Some (c, tail) ->
          m.underlying <- tail;
          Buffer.add_char m.buffer c;
          Seq.Cons (c, make)
    else
      (** No recording, fetch from buffer *)  
      if Buffer.length m.buffer > m.read_pos then begin
        (** Some chars in buffer available *)
        let c = Buffer.nth m.buffer m.read_pos in
        m.read_pos <- m.read_pos + 1;
        Seq.Cons (c, make)
      end else
        (** No recording and no chars in buffer available: work unbufferred *)
        match Seq.uncons m.underlying with
        | None -> Seq.Nil
        | Some (c, tail) ->
          m.underlying <- tail;
          Seq.Cons (c, make)
  in
  make

(* The rest functions are old and not sequence-oriented *)
let input_line ic =
  let buf = Buffer.create 512 in
  let rec loop () =    
    match ic () with
    | Some c ->
      begin
        match c with
        | 13 -> loop ()
        | 10 -> Some (Buffer.contents buf)
        | c -> Buffer.add_uint8 buf c; loop ()
      end
    | None -> None in
  loop ()
      
let input ic buf ofs len =
  let rec loop i =
    if i = len then
      len
    else
      match ic () with
      | Some c -> Bytes.set buf (ofs + i) (Char.chr c);
      loop (i + 1)
      | None -> i in
  loop 0

