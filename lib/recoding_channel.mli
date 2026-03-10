(**
   Streaming decoder for legacy single-byte Russian encodings (CP1251 / KOI8-R)
   to UTF-8 on-the-fly.

   This module provides a thin wrapper around [In_channel.t] that reads data
   in legacy Windows-1251 or KOI8-R encoding and delivers it as UTF-8 encoded
   bytes, character by character.

   Main usage patterns:

   {v
     (* CP1251 example *)
     let decoder = create_cp1251 stdin in
     while let Some c = input_byte decoder do
       Stdlib.print_char c
     done;

     (* KOI8-R example *)
     let decoder = create_koi8r (In_channel.create ~binary:true "book.fb2") in
     ...
   v}

   Features:
   - Zero-cost passthrough for ASCII bytes (0x00–0x7F)
   - Transparent conversion of high bytes (0x80–0xFF) to UTF-8 sequences
   - Buffering of partial UTF-8 multi-byte sequences across calls
   - CP1251: undefined code points mapped to U+FFFD (replacement character)
   - KOI8-R: all code points defined (no replacement needed)

   Limitations:
   - Sequential forward reading only (no seeking, no position reporting)
   - No error recovery for invalid input beyond replacement character
   - Designed for metadata extraction (title/author), not full document parsing
 *)

(* open Base *)

(** Decoder state: holds the chosen encoding table, underlying input channel
    and a small buffer of pending UTF-8 bytes from the last converted character. *)
type t

(** [create_norecode] creates a no-recoding decoder to handle UTF-8. *)
val create_norecode : In_channel.t -> t

(** [create_cp1251 input] creates a Windows-1251 → UTF-8 decoder. *)
val create_cp1251 : In_channel.t -> t

(** [create_koi8r input] creates a KOI8-R → UTF-8 decoder
    (using the standard RFC 1489 mapping). *)
val create_koi8r : In_channel.t -> t

(** [input_byte t] reads and returns the next byte of the UTF-8 encoded stream.

    @return [Some c] — next UTF-8 byte
    @return [None] — end of input reached
*)
val input_byte: t -> int option