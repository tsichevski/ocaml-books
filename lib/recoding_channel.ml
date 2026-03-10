open Base

(** Mapping table: Windows-1251 bytes 0x80–0xFF → Unicode scalar values.
    Bytes 0x00–0x7F are passed through unchanged (ASCII identity). *)
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

(** Mapping table: KOI8-R bytes 0x80–0xFF → Unicode scalar values.
    Source: RFC 1489 (standard KOI8-R as implemented in GNU libiconv / glibc iconv).
    All 128 high bytes are defined — no replacement characters needed.
    Bytes 0x00–0x7F are passed through unchanged. *)
let koi8r_to_uchar_array_rfc1489 : Uchar.t array =
  [|
    (* 0x80–0x8F *) (* box drawing, blocks *)
    Uchar.of_scalar_exn 0x2500; Uchar.of_scalar_exn 0x2502; Uchar.of_scalar_exn 0x250C; Uchar.of_scalar_exn 0x2510;
    Uchar.of_scalar_exn 0x2514; Uchar.of_scalar_exn 0x2518; Uchar.of_scalar_exn 0x251C; Uchar.of_scalar_exn 0x2524;
    Uchar.of_scalar_exn 0x252C; Uchar.of_scalar_exn 0x2534; Uchar.of_scalar_exn 0x253C; Uchar.of_scalar_exn 0x2580;
    Uchar.of_scalar_exn 0x2584; Uchar.of_scalar_exn 0x2588; Uchar.of_scalar_exn 0x258C; Uchar.of_scalar_exn 0x2590;
    (* 0x90–0x9F *) (* shades, math, etc. *)
    Uchar.of_scalar_exn 0x2591; Uchar.of_scalar_exn 0x2592; Uchar.of_scalar_exn 0x2593; Uchar.of_scalar_exn 0x2320;
    Uchar.of_scalar_exn 0x25A0; Uchar.of_scalar_exn 0x2219; Uchar.of_scalar_exn 0x221A; Uchar.of_scalar_exn 0x2248;
    Uchar.of_scalar_exn 0x2264; Uchar.of_scalar_exn 0x2265; Uchar.of_scalar_exn 0x00A0; Uchar.of_scalar_exn 0x2321;
    Uchar.of_scalar_exn 0x00B0; Uchar.of_scalar_exn 0x00B2; Uchar.of_scalar_exn 0x00B7; Uchar.of_scalar_exn 0x00F7;
    (* 0xA0–0xAF *) (* more box drawing + Ё/ё + © *)
    Uchar.of_scalar_exn 0x2550; Uchar.of_scalar_exn 0x2551; Uchar.of_scalar_exn 0x2552; Uchar.of_scalar_exn 0x0451;
    Uchar.of_scalar_exn 0x2553; Uchar.of_scalar_exn 0x2554; Uchar.of_scalar_exn 0x2555; Uchar.of_scalar_exn 0x2556;
    Uchar.of_scalar_exn 0x2557; Uchar.of_scalar_exn 0x2558; Uchar.of_scalar_exn 0x2559; Uchar.of_scalar_exn 0x255A;
    Uchar.of_scalar_exn 0x255B; Uchar.of_scalar_exn 0x255C; Uchar.of_scalar_exn 0x255D; Uchar.of_scalar_exn 0x255E;
    (* 0xB0–0xBF *)
    Uchar.of_scalar_exn 0x255F; Uchar.of_scalar_exn 0x2560; Uchar.of_scalar_exn 0x2561; Uchar.of_scalar_exn 0x0401;
    Uchar.of_scalar_exn 0x2562; Uchar.of_scalar_exn 0x2563; Uchar.of_scalar_exn 0x2564; Uchar.of_scalar_exn 0x2565;
    Uchar.of_scalar_exn 0x2566; Uchar.of_scalar_exn 0x2567; Uchar.of_scalar_exn 0x2568; Uchar.of_scalar_exn 0x2569;
    Uchar.of_scalar_exn 0x256A; Uchar.of_scalar_exn 0x256B; Uchar.of_scalar_exn 0x256C; Uchar.of_scalar_exn 0x00A9;
    (* 0xC0–0xCF *) (* lowercase Cyrillic *)
    Uchar.of_scalar_exn 0x044E; Uchar.of_scalar_exn 0x0430; Uchar.of_scalar_exn 0x0431; Uchar.of_scalar_exn 0x0446;
    Uchar.of_scalar_exn 0x0434; Uchar.of_scalar_exn 0x0435; Uchar.of_scalar_exn 0x0444; Uchar.of_scalar_exn 0x0433;
    Uchar.of_scalar_exn 0x0445; Uchar.of_scalar_exn 0x0438; Uchar.of_scalar_exn 0x0439; Uchar.of_scalar_exn 0x043A;
    Uchar.of_scalar_exn 0x043B; Uchar.of_scalar_exn 0x043C; Uchar.of_scalar_exn 0x043D; Uchar.of_scalar_exn 0x043E;
    (* 0xD0–0xDF *)
    Uchar.of_scalar_exn 0x043F; Uchar.of_scalar_exn 0x044F; Uchar.of_scalar_exn 0x0440; Uchar.of_scalar_exn 0x0441;
    Uchar.of_scalar_exn 0x0442; Uchar.of_scalar_exn 0x0443; Uchar.of_scalar_exn 0x0436; Uchar.of_scalar_exn 0x0432;
    Uchar.of_scalar_exn 0x044C; Uchar.of_scalar_exn 0x044B; Uchar.of_scalar_exn 0x0437; Uchar.of_scalar_exn 0x0448;
    Uchar.of_scalar_exn 0x044D; Uchar.of_scalar_exn 0x0449; Uchar.of_scalar_exn 0x0447; Uchar.of_scalar_exn 0x044A;
    (* 0xE0–0xEF *) (* uppercase Cyrillic *)
    Uchar.of_scalar_exn 0x042E; Uchar.of_scalar_exn 0x0410; Uchar.of_scalar_exn 0x0411; Uchar.of_scalar_exn 0x0426;
    Uchar.of_scalar_exn 0x0414; Uchar.of_scalar_exn 0x0415; Uchar.of_scalar_exn 0x0424; Uchar.of_scalar_exn 0x0413;
    Uchar.of_scalar_exn 0x0425; Uchar.of_scalar_exn 0x0418; Uchar.of_scalar_exn 0x0419; Uchar.of_scalar_exn 0x041A;
    Uchar.of_scalar_exn 0x041B; Uchar.of_scalar_exn 0x041C; Uchar.of_scalar_exn 0x041D; Uchar.of_scalar_exn 0x041E;
    (* 0xF0–0xFF *)
    Uchar.of_scalar_exn 0x041F; Uchar.of_scalar_exn 0x042F; Uchar.of_scalar_exn 0x0420; Uchar.of_scalar_exn 0x0421;
    Uchar.of_scalar_exn 0x0422; Uchar.of_scalar_exn 0x0423; Uchar.of_scalar_exn 0x0416; Uchar.of_scalar_exn 0x0412;
    Uchar.of_scalar_exn 0x042C; Uchar.of_scalar_exn 0x042B; Uchar.of_scalar_exn 0x0417; Uchar.of_scalar_exn 0x0428;
    Uchar.of_scalar_exn 0x042D; Uchar.of_scalar_exn 0x0429; Uchar.of_scalar_exn 0x0427; Uchar.of_scalar_exn 0x042A;
  |]

type t = { table: Uchar.t array option; input: In_channel.t; mutable last : int list }

let create table input = { input; table; last = [] }

let create_cp1251 = create (Some cp1251_to_uchar_array)

let create_koi8r = create (Some koi8r_to_uchar_array_rfc1489)

let create_norecode = create None

let input_byte t : int option =
  match t.table with
  | None -> In_channel.input_byte t.input
  | Some table ->
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
            Some sc
          else
            begin
              let uchar = table.(sc - 0x80) in
              let s = Uchar.Utf8.to_string uchar in
              t.last <- String.to_list s |> List.map ~f:Char.to_int;
              loop ()
            end
    in
    loop ()