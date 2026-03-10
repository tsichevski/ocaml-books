(**
   CP1251 (Windows-1251) to UTF-8 on-the-fly decoder for streaming input.

   This module provides a thin wrapper around [In_channel.t] that reads legacy
   Windows-1251 encoded data and delivers it as UTF-8 bytes character by character.

   Main usage pattern:
   {[
     let decoder = create stdin in
     while let Some c = input_char decoder in
       Stdlib.print_char c
     done
   ]}

   Features:
   - transparent conversion of single-byte CP1251 → multi-byte UTF-8
   - correct handling of ASCII range (0x00–0x7F) with zero overhead
   - undefined CP1251 bytes mapped to Unicode replacement character U+FFFD
   - buffering of partial UTF-8 sequences across calls

   Limitations:
   - Does not perform validation of malformed UTF-8 output
   - Does not support seeking or position reporting
   - Designed for sequential forward reading only
 *)

open Base

(** Complete mapping: CP1251 bytes 0x80–0xFF → Unicode scalar values.
    Bytes 0x00–0x7F are treated as ASCII and passed through unchanged. *)
let cp1251_to_uchar_array : Uchar.t array =
  [|
    (* 0x80 *)
    Uchar.of_scalar_exn 0x0402; (* Ђ *)
    Uchar.of_scalar_exn 0x0403; (* Ѓ *)
    Uchar.of_scalar_exn 0x201A; (* ‚ *)
    Uchar.of_scalar_exn 0x0453; (* ѓ *)
    Uchar.of_scalar_exn 0x201E; (* „ *)
    Uchar.of_scalar_exn 0x2026; (* … *)
    Uchar.of_scalar_exn 0x2020; (* † *)
    Uchar.of_scalar_exn 0x2021; (* ‡ *)
    Uchar.of_scalar_exn 0x20AC; (* € *)
    Uchar.of_scalar_exn 0x2030; (* ‰ *)
    Uchar.of_scalar_exn 0x0409; (* Љ *)
    Uchar.of_scalar_exn 0x2039; (* ‹ *)
    Uchar.of_scalar_exn 0x040A; (* Њ *)
    Uchar.of_scalar_exn 0x040C; (* Ќ *)
    Uchar.of_scalar_exn 0x040B; (* Ћ *)
    Uchar.of_scalar_exn 0x040F; (* Џ *)
    (* 0x90 *)
    Uchar.of_scalar_exn 0x0452; (* ђ *)
    Uchar.of_scalar_exn 0x2018; (* ‘ *)
    Uchar.of_scalar_exn 0x2019; (* ’ *)
    Uchar.of_scalar_exn 0x201C; (* “ *)
    Uchar.of_scalar_exn 0x201D; (* ” *)
    Uchar.of_scalar_exn 0x2022; (* • *)
    Uchar.of_scalar_exn 0x2013; (* – *)
    Uchar.of_scalar_exn 0x2014; (* — *)
    Uchar.replacement_char; (* undefined *)
    Uchar.of_scalar_exn 0x2122; (* ™ *)
    Uchar.of_scalar_exn 0x0459; (* љ *)
    Uchar.of_scalar_exn 0x203A; (* › *)
    Uchar.of_scalar_exn 0x045A; (* њ *)
    Uchar.of_scalar_exn 0x045C; (* ќ *)
    Uchar.of_scalar_exn 0x045B; (* ћ *)
    Uchar.of_scalar_exn 0x045F; (* џ *)
    (* 0xA0–0xAF *)
    Uchar.of_scalar_exn 0x00A0; (*   *)
    Uchar.of_scalar_exn 0x040E; (* Ў *)
    Uchar.of_scalar_exn 0x045E; (* ў *)
    Uchar.of_scalar_exn 0x0408; (* Ј *)
    Uchar.of_scalar_exn 0x00A4; (* ¤ *)
    Uchar.of_scalar_exn 0x0490; (* Ґ *)
    Uchar.of_scalar_exn 0x00A6; (* ¦ *)
    Uchar.of_scalar_exn 0x00A7; (* § *)
    Uchar.of_scalar_exn 0x0401; (* Ё *)
    Uchar.of_scalar_exn 0x00A9; (* © *)
    Uchar.of_scalar_exn 0x0404; (* Є *)
    Uchar.of_scalar_exn 0x00AB; (* « *)
    Uchar.of_scalar_exn 0x00AC; (* ¬ *)
    Uchar.of_scalar_exn 0x00AD; (* ­ *)
    Uchar.of_scalar_exn 0x00AE; (* ® *)
    Uchar.of_scalar_exn 0x0407; (* Ї *)
    (* 0xB0–0xBF *)
    Uchar.of_scalar_exn 0x00B0; (* ° *)
    Uchar.of_scalar_exn 0x00B1; (* ± *)
    Uchar.of_scalar_exn 0x0406; (* І *)
    Uchar.of_scalar_exn 0x0456; (* і *)
    Uchar.of_scalar_exn 0x0491; (* ґ *)
    Uchar.of_scalar_exn 0x00B5; (* µ *)
    Uchar.of_scalar_exn 0x00B6; (* ¶ *)
    Uchar.of_scalar_exn 0x00B7; (* · *)
    Uchar.of_scalar_exn 0x0451; (* ё *)
    Uchar.of_scalar_exn 0x2116; (* № *)
    Uchar.of_scalar_exn 0x0454; (* є *)
    Uchar.of_scalar_exn 0x00BB; (* » *)
    Uchar.of_scalar_exn 0x0458; (* ј *)
    Uchar.of_scalar_exn 0x0405; (* Ѕ *)
    Uchar.of_scalar_exn 0x0455; (* ѕ *)
    Uchar.of_scalar_exn 0x0457; (* ї *)
    (* 0xC0–0xFF – Cyrillic letters *)
    Uchar.of_scalar_exn 0x0410; (* А *)
    Uchar.of_scalar_exn 0x0411; (* Б *)
    Uchar.of_scalar_exn 0x0412; (* В *)
    Uchar.of_scalar_exn 0x0413; (* Г *)
    Uchar.of_scalar_exn 0x0414; (* Д *)
    Uchar.of_scalar_exn 0x0415; (* Е *)
    Uchar.of_scalar_exn 0x0416; (* Ж *)
    Uchar.of_scalar_exn 0x0417; (* З *)
    Uchar.of_scalar_exn 0x0418; (* И *)
    Uchar.of_scalar_exn 0x0419; (* Й *)
    Uchar.of_scalar_exn 0x041A; (* К *)
    Uchar.of_scalar_exn 0x041B; (* Л *)
    Uchar.of_scalar_exn 0x041C; (* М *)
    Uchar.of_scalar_exn 0x041D; (* Н *)
    Uchar.of_scalar_exn 0x041E; (* О *)
    Uchar.of_scalar_exn 0x041F; (* П *)
    Uchar.of_scalar_exn 0x0420; (* Р *)
    Uchar.of_scalar_exn 0x0421; (* С *)
    Uchar.of_scalar_exn 0x0422; (* Т *)
    Uchar.of_scalar_exn 0x0423; (* У *)
    Uchar.of_scalar_exn 0x0424; (* Ф *)
    Uchar.of_scalar_exn 0x0425; (* Х *)
    Uchar.of_scalar_exn 0x0426; (* Ц *)
    Uchar.of_scalar_exn 0x0427; (* Ч *)
    Uchar.of_scalar_exn 0x0428; (* Ш *)
    Uchar.of_scalar_exn 0x0429; (* Щ *)
    Uchar.of_scalar_exn 0x042A; (* Ъ *)
    Uchar.of_scalar_exn 0x042B; (* Ы *)
    Uchar.of_scalar_exn 0x042C; (* Ь *)
    Uchar.of_scalar_exn 0x042D; (* Э *)
    Uchar.of_scalar_exn 0x042E; (* Ю *)
    Uchar.of_scalar_exn 0x042F; (* Я *)
    Uchar.of_scalar_exn 0x0430; (* а *)
    Uchar.of_scalar_exn 0x0431; (* б *)
    Uchar.of_scalar_exn 0x0432; (* в *)
    Uchar.of_scalar_exn 0x0433; (* г *)
    Uchar.of_scalar_exn 0x0434; (* д *)
    Uchar.of_scalar_exn 0x0435; (* е *)
    Uchar.of_scalar_exn 0x0436; (* ж *)
    Uchar.of_scalar_exn 0x0437; (* з *)
    Uchar.of_scalar_exn 0x0438; (* и *)
    Uchar.of_scalar_exn 0x0439; (* й *)
    Uchar.of_scalar_exn 0x043A; (* к *)
    Uchar.of_scalar_exn 0x043B; (* л *)
    Uchar.of_scalar_exn 0x043C; (* м *)
    Uchar.of_scalar_exn 0x043D; (* н *)
    Uchar.of_scalar_exn 0x043E; (* о *)
    Uchar.of_scalar_exn 0x043F; (* п *)
    Uchar.of_scalar_exn 0x0440; (* р *)
    Uchar.of_scalar_exn 0x0441; (* с *)
    Uchar.of_scalar_exn 0x0442; (* т *)
    Uchar.of_scalar_exn 0x0443; (* у *)
    Uchar.of_scalar_exn 0x0444; (* ф *)
    Uchar.of_scalar_exn 0x0445; (* х *)
    Uchar.of_scalar_exn 0x0446; (* ц *)
    Uchar.of_scalar_exn 0x0447; (* ч *)
    Uchar.of_scalar_exn 0x0448; (* ш *)
    Uchar.of_scalar_exn 0x0449; (* щ *)
    Uchar.of_scalar_exn 0x044A; (* ъ *)
    Uchar.of_scalar_exn 0x044B; (* ы *)
    Uchar.of_scalar_exn 0x044C; (* ь *)
    Uchar.of_scalar_exn 0x044D; (* э *)
    Uchar.of_scalar_exn 0x044E; (* ю *)
    Uchar.of_scalar_exn 0x044F; (* я *)
  |]

(** Decoder state: wraps an input channel and holds pending UTF-8 bytes. *)
type t = { input: In_channel.t; mutable last : char list }

(** [create input] wraps an existing input channel with CP1251→UTF-8 decoding. *)
let create input = { input; last = [] }

(** [input_char t] reads the next UTF-8 byte from the decoded stream.

    - Returns [Some c] if a byte is available
    - Returns [None] on end of file
    - May perform multiple underlying reads when crossing a character boundary
*)
let input_char t : char option =
  let rec loop () =
    match t.last with
    | c::tl ->
      t.last <- tl;
      Some c
    | [] ->
      match In_channel.input_byte t.input with
      | None -> None
      | Some sc ->
        if sc < 128 then
          Char.of_int sc
        else
          begin
            let uchar = cp1251_to_uchar_array.(sc - 0x80) in
            let s = Uchar.Utf8.to_string uchar in
            t.last <- String.to_list s;
            loop ()
          end
  in
  loop ()