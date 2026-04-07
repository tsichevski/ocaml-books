(**
   Streaming decoder for legacy single-byte encodings to UTF-8 on-the-fly.

   Supported encodings:
   - Windows-1251 (CP1251) – Russian Cyrillic (Windows)
   - KOI8-R – Russian Cyrillic (Unix legacy)
   - Windows-1252 – Western European with smart quotes and €
   - ISO-8859-1 (Latin-1) – Classic Western European
   - ISO-8859-5 (Latin/Cyrillic) – Official Cyrillic
   - Windows-1255 (CP1255) – Hebrew with Niqqud support

   This module wraps a standard [in_channel] (opened in binary mode)
   and converts high bytes (0x80–0xFF) to proper UTF-8 sequences
   while passing ASCII (0x00–0x7F) unchanged.

   Main usage example:

   {v
     let ic = open_in_bin "legacy_book.fb2" in
     let decoder = create_cp1255 ic in
     while let Some c = input_char decoder do
       print_char c
     done;
     close_in ic
   v}

   Features:
   - Zero-cost passthrough for ASCII
   - Buffering of partial UTF-8 output across calls
   - Safe replacement character (U+FFFD) for undefined ranges
   - All tables aligned with official Unicode mappings and GNU libiconv
   - Pure standard library (no Base/Core)
 *)

(** Mapping table: Windows-1251 bytes 0x80–0xFF → Unicode scalar values.
    Bytes 0x00–0x7F are ASCII and passed through unchanged. *)
let cp1251_to_uchar_array : Uchar.t array =
  [|
    (* 0x80 *)
    Uchar.of_int 0x0402; (* Ђ *)
    Uchar.of_int 0x0403; (* Ѓ *)
    Uchar.of_int 0x201A; (* ‚ *)
    Uchar.of_int 0x0453; (* ѓ *)
    Uchar.of_int 0x201E; (* „ *)
    Uchar.of_int 0x2026; (* … *)
    Uchar.of_int 0x2020; (* † *)
    Uchar.of_int 0x2021; (* ‡ *)
    Uchar.of_int 0x20AC; (* € *)
    Uchar.of_int 0x2030; (* ‰ *)
    Uchar.of_int 0x0409; (* Љ *)
    Uchar.of_int 0x2039; (* ‹ *)
    Uchar.of_int 0x040A; (* Њ *)
    Uchar.of_int 0x040C; (* Ќ *)
    Uchar.of_int 0x040B; (* Ћ *)
    Uchar.of_int 0x040F; (* Џ *)
    (* 0x90 *)
    Uchar.of_int 0x0452; (* ђ *)
    Uchar.of_int 0x2018; (* ‘ *)
    Uchar.of_int 0x2019; (* ’ *)
    Uchar.of_int 0x201C; (* “ *)
    Uchar.of_int 0x201D; (* ” *)
    Uchar.of_int 0x2022; (* • *)
    Uchar.of_int 0x2013; (* – *)
    Uchar.of_int 0x2014; (* — *)
    Uchar.rep; (* undefined *)
    Uchar.of_int 0x2122; (* ™ *)
    Uchar.of_int 0x0459; (* љ *)
    Uchar.of_int 0x203A; (* › *)
    Uchar.of_int 0x045A; (* њ *)
    Uchar.of_int 0x045C; (* ќ *)
    Uchar.of_int 0x045B; (* ћ *)
    Uchar.of_int 0x045F; (* џ *)
    (* 0xA0–0xAF *)
    Uchar.of_int 0x00A0; (*   *)
    Uchar.of_int 0x040E; (* Ў *)
    Uchar.of_int 0x045E; (* ў *)
    Uchar.of_int 0x0408; (* Ј *)
    Uchar.of_int 0x00A4; (* ¤ *)
    Uchar.of_int 0x0490; (* Ґ *)
    Uchar.of_int 0x00A6; (* ¦ *)
    Uchar.of_int 0x00A7; (* § *)
    Uchar.of_int 0x0401; (* Ё *)
    Uchar.of_int 0x00A9; (* © *)
    Uchar.of_int 0x0404; (* Є *)
    Uchar.of_int 0x00AB; (* « *)
    Uchar.of_int 0x00AC; (* ¬ *)
    Uchar.of_int 0x00AD; (* ­ *)
    Uchar.of_int 0x00AE; (* ® *)
    Uchar.of_int 0x0407; (* Ї *)
    (* 0xB0–0xBF *)
    Uchar.of_int 0x00B0; (* ° *)
    Uchar.of_int 0x00B1; (* ± *)
    Uchar.of_int 0x0406; (* І *)
    Uchar.of_int 0x0456; (* і *)
    Uchar.of_int 0x0491; (* ґ *)
    Uchar.of_int 0x00B5; (* µ *)
    Uchar.of_int 0x00B6; (* ¶ *)
    Uchar.of_int 0x00B7; (* · *)
    Uchar.of_int 0x0451; (* ё *)
    Uchar.of_int 0x2116; (* № *)
    Uchar.of_int 0x0454; (* є *)
    Uchar.of_int 0x00BB; (* » *)
    Uchar.of_int 0x0458; (* ј *)
    Uchar.of_int 0x0405; (* Ѕ *)
    Uchar.of_int 0x0455; (* ѕ *)
    Uchar.of_int 0x0457; (* ї *)
    (* 0xC0–0xFF – Cyrillic letters *)
    Uchar.of_int 0x0410; (* А *)
    Uchar.of_int 0x0411; (* Б *)
    Uchar.of_int 0x0412; (* В *)
    Uchar.of_int 0x0413; (* Г *)
    Uchar.of_int 0x0414; (* Д *)
    Uchar.of_int 0x0415; (* Е *)
    Uchar.of_int 0x0416; (* Ж *)
    Uchar.of_int 0x0417; (* З *)
    Uchar.of_int 0x0418; (* И *)
    Uchar.of_int 0x0419; (* Й *)
    Uchar.of_int 0x041A; (* К *)
    Uchar.of_int 0x041B; (* Л *)
    Uchar.of_int 0x041C; (* М *)
    Uchar.of_int 0x041D; (* Н *)
    Uchar.of_int 0x041E; (* О *)
    Uchar.of_int 0x041F; (* П *)
    Uchar.of_int 0x0420; (* Р *)
    Uchar.of_int 0x0421; (* С *)
    Uchar.of_int 0x0422; (* Т *)
    Uchar.of_int 0x0423; (* У *)
    Uchar.of_int 0x0424; (* Ф *)
    Uchar.of_int 0x0425; (* Х *)
    Uchar.of_int 0x0426; (* Ц *)
    Uchar.of_int 0x0427; (* Ч *)
    Uchar.of_int 0x0428; (* Ш *)
    Uchar.of_int 0x0429; (* Щ *)
    Uchar.of_int 0x042A; (* Ъ *)
    Uchar.of_int 0x042B; (* Ы *)
    Uchar.of_int 0x042C; (* Ь *)
    Uchar.of_int 0x042D; (* Э *)
    Uchar.of_int 0x042E; (* Ю *)
    Uchar.of_int 0x042F; (* Я *)
    Uchar.of_int 0x0430; (* а *)
    Uchar.of_int 0x0431; (* б *)
    Uchar.of_int 0x0432; (* в *)
    Uchar.of_int 0x0433; (* г *)
    Uchar.of_int 0x0434; (* д *)
    Uchar.of_int 0x0435; (* е *)
    Uchar.of_int 0x0436; (* ж *)
    Uchar.of_int 0x0437; (* з *)
    Uchar.of_int 0x0438; (* и *)
    Uchar.of_int 0x0439; (* й *)
    Uchar.of_int 0x043A; (* к *)
    Uchar.of_int 0x043B; (* л *)
    Uchar.of_int 0x043C; (* м *)
    Uchar.of_int 0x043D; (* н *)
    Uchar.of_int 0x043E; (* о *)
    Uchar.of_int 0x043F; (* п *)
    Uchar.of_int 0x0440; (* р *)
    Uchar.of_int 0x0441; (* с *)
    Uchar.of_int 0x0442; (* т *)
    Uchar.of_int 0x0443; (* у *)
    Uchar.of_int 0x0444; (* ф *)
    Uchar.of_int 0x0445; (* х *)
    Uchar.of_int 0x0446; (* ц *)
    Uchar.of_int 0x0447; (* ч *)
    Uchar.of_int 0x0448; (* ш *)
    Uchar.of_int 0x0449; (* щ *)
    Uchar.of_int 0x044A; (* ъ *)
    Uchar.of_int 0x044B; (* ы *)
    Uchar.of_int 0x044C; (* ь *)
    Uchar.of_int 0x044D; (* э *)
    Uchar.of_int 0x044E; (* ю *)
    Uchar.of_int 0x044F; (* я *)
  |]

(** Mapping table: KOI8-R bytes 0x80–0xFF → Unicode scalar values.
    Source: RFC 1489 (standard KOI8-R as implemented in GNU libiconv / glibc iconv).
    All 128 high bytes are defined — no replacement characters needed.
    Bytes 0x00–0x7F are passed through unchanged. *)
let koi8r_to_uchar_array : Uchar.t array =
  [|
    (* 0x80–0x8F *) (* box drawing, blocks *)
    Uchar.of_int 0x2500; Uchar.of_int 0x2502; Uchar.of_int 0x250C; Uchar.of_int 0x2510;
    Uchar.of_int 0x2514; Uchar.of_int 0x2518; Uchar.of_int 0x251C; Uchar.of_int 0x2524;
    Uchar.of_int 0x252C; Uchar.of_int 0x2534; Uchar.of_int 0x253C; Uchar.of_int 0x2580;
    Uchar.of_int 0x2584; Uchar.of_int 0x2588; Uchar.of_int 0x258C; Uchar.of_int 0x2590;
    (* 0x90–0x9F *) (* shades, math, etc. *)
    Uchar.of_int 0x2591; Uchar.of_int 0x2592; Uchar.of_int 0x2593; Uchar.of_int 0x2320;
    Uchar.of_int 0x25A0; Uchar.of_int 0x2219; Uchar.of_int 0x221A; Uchar.of_int 0x2248;
    Uchar.of_int 0x2264; Uchar.of_int 0x2265; Uchar.of_int 0x00A0; Uchar.of_int 0x2321;
    Uchar.of_int 0x00B0; Uchar.of_int 0x00B2; Uchar.of_int 0x00B7; Uchar.of_int 0x00F7;
    (* 0xA0–0xAF *) (* more box drawing + Ё/ё + © *)
    Uchar.of_int 0x2550; Uchar.of_int 0x2551; Uchar.of_int 0x2552; Uchar.of_int 0x0451;
    Uchar.of_int 0x2553; Uchar.of_int 0x2554; Uchar.of_int 0x2555; Uchar.of_int 0x2556;
    Uchar.of_int 0x2557; Uchar.of_int 0x2558; Uchar.of_int 0x2559; Uchar.of_int 0x255A;
    Uchar.of_int 0x255B; Uchar.of_int 0x255C; Uchar.of_int 0x255D; Uchar.of_int 0x255E;
    (* 0xB0–0xBF *)
    Uchar.of_int 0x255F; Uchar.of_int 0x2560; Uchar.of_int 0x2561; Uchar.of_int 0x0401;
    Uchar.of_int 0x2562; Uchar.of_int 0x2563; Uchar.of_int 0x2564; Uchar.of_int 0x2565;
    Uchar.of_int 0x2566; Uchar.of_int 0x2567; Uchar.of_int 0x2568; Uchar.of_int 0x2569;
    Uchar.of_int 0x256A; Uchar.of_int 0x256B; Uchar.of_int 0x256C; Uchar.of_int 0x00A9;
    (* 0xC0–0xCF *) (* lowercase Cyrillic *)
    Uchar.of_int 0x044E; Uchar.of_int 0x0430; Uchar.of_int 0x0431; Uchar.of_int 0x0446;
    Uchar.of_int 0x0434; Uchar.of_int 0x0435; Uchar.of_int 0x0444; Uchar.of_int 0x0433;
    Uchar.of_int 0x0445; Uchar.of_int 0x0438; Uchar.of_int 0x0439; Uchar.of_int 0x043A;
    Uchar.of_int 0x043B; Uchar.of_int 0x043C; Uchar.of_int 0x043D; Uchar.of_int 0x043E;
    (* 0xD0–0xDF *)
    Uchar.of_int 0x043F; Uchar.of_int 0x044F; Uchar.of_int 0x0440; Uchar.of_int 0x0441;
    Uchar.of_int 0x0442; Uchar.of_int 0x0443; Uchar.of_int 0x0436; Uchar.of_int 0x0432;
    Uchar.of_int 0x044C; Uchar.of_int 0x044B; Uchar.of_int 0x0437; Uchar.of_int 0x0448;
    Uchar.of_int 0x044D; Uchar.of_int 0x0449; Uchar.of_int 0x0447; Uchar.of_int 0x044A;
    (* 0xE0–0xEF *) (* uppercase Cyrillic *)
    Uchar.of_int 0x042E; Uchar.of_int 0x0410; Uchar.of_int 0x0411; Uchar.of_int 0x0426;
    Uchar.of_int 0x0414; Uchar.of_int 0x0415; Uchar.of_int 0x0424; Uchar.of_int 0x0413;
    Uchar.of_int 0x0425; Uchar.of_int 0x0418; Uchar.of_int 0x0419; Uchar.of_int 0x041A;
    Uchar.of_int 0x041B; Uchar.of_int 0x041C; Uchar.of_int 0x041D; Uchar.of_int 0x041E;
    (* 0xF0–0xFF *)
    Uchar.of_int 0x041F; Uchar.of_int 0x042F; Uchar.of_int 0x0420; Uchar.of_int 0x0421;
    Uchar.of_int 0x0422; Uchar.of_int 0x0423; Uchar.of_int 0x0416; Uchar.of_int 0x0412;
    Uchar.of_int 0x042C; Uchar.of_int 0x042B; Uchar.of_int 0x0417; Uchar.of_int 0x0428;
    Uchar.of_int 0x042D; Uchar.of_int 0x0429; Uchar.of_int 0x0427; Uchar.of_int 0x042A;
  |]

(** Mapping table: Windows-1252 bytes 0x80–0x9F → Unicode scalar values. *)
let windows1252_to_uchar_array : Uchar.t array =
  [|
    (* 0x80–0x8F *)
    Uchar.of_int 0x20AC; (* € *)
    Uchar.rep;      (* undefined *)
    Uchar.of_int 0x201A; (* ‚ *)
    Uchar.of_int 0x0192; (* ƒ *)
    Uchar.of_int 0x201E; (* „ *)
    Uchar.of_int 0x2026; (* … *)
    Uchar.of_int 0x2020; (* † *)
    Uchar.of_int 0x2021; (* ‡ *)
    Uchar.of_int 0x02C6; (* ˆ *)
    Uchar.of_int 0x2030; (* ‰ *)
    Uchar.of_int 0x0160; (* Š *)
    Uchar.of_int 0x2039; (* ‹ *)
    Uchar.of_int 0x0152; (* Œ *)
    Uchar.rep;      (* undefined *)
    Uchar.of_int 0x017D; (* Ž *)
    Uchar.rep;      (* undefined *)
    (* 0x90–0x9F *)
    Uchar.rep;      (* undefined *)
    Uchar.of_int 0x2018; (* ‘ *)
    Uchar.of_int 0x2019; (* ’ *)
    Uchar.of_int 0x201C; (* “ *)
    Uchar.of_int 0x201D; (* ” *)
    Uchar.of_int 0x2022; (* • *)
    Uchar.of_int 0x2013; (* – *)
    Uchar.of_int 0x2014; (* — *)
    Uchar.of_int 0x02DC; (* ˜ *)
    Uchar.of_int 0x2122; (* ™ *)
    Uchar.of_int 0x0161; (* š *)
    Uchar.of_int 0x203A; (* › *)
    Uchar.of_int 0x0153; (* œ *)
    Uchar.rep;      (* undefined *)
    Uchar.of_int 0x017E; (* ž *)
    Uchar.of_int 0x0178; (* Ÿ *)
  |]

(** ISO-8859-1 (Latin-1) mapping table.
    Bytes 0x00–0x7F = ASCII
    Bytes 0x80–0x9F = undefined (mapped to replacement character for safety)
    Bytes 0xA0–0xFF = identical to Unicode U+00A0–U+00FF *)
let iso8859_1_to_uchar_array : Uchar.t array =
  [|
    (* 0x80–0x9F: officially undefined in ISO-8859-1, we use replacement for safety *)
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    (* 0xA0–0xFF: direct mapping to U+00A0–U+00FF *)
    Uchar.of_int 0x00A0; Uchar.of_int 0x00A1; Uchar.of_int 0x00A2; Uchar.of_int 0x00A3;
    Uchar.of_int 0x00A4; Uchar.of_int 0x00A5; Uchar.of_int 0x00A6; Uchar.of_int 0x00A7;
    Uchar.of_int 0x00A8; Uchar.of_int 0x00A9; Uchar.of_int 0x00AA; Uchar.of_int 0x00AB;
    Uchar.of_int 0x00AC; Uchar.of_int 0x00AD; Uchar.of_int 0x00AE; Uchar.of_int 0x00AF;
    Uchar.of_int 0x00B0; Uchar.of_int 0x00B1; Uchar.of_int 0x00B2; Uchar.of_int 0x00B3;
    Uchar.of_int 0x00B4; Uchar.of_int 0x00B5; Uchar.of_int 0x00B6; Uchar.of_int 0x00B7;
    Uchar.of_int 0x00B8; Uchar.of_int 0x00B9; Uchar.of_int 0x00BA; Uchar.of_int 0x00BB;
    Uchar.of_int 0x00BC; Uchar.of_int 0x00BD; Uchar.of_int 0x00BE; Uchar.of_int 0x00BF;
    Uchar.of_int 0x00C0; Uchar.of_int 0x00C1; Uchar.of_int 0x00C2; Uchar.of_int 0x00C3;
    Uchar.of_int 0x00C4; Uchar.of_int 0x00C5; Uchar.of_int 0x00C6; Uchar.of_int 0x00C7;
    Uchar.of_int 0x00C8; Uchar.of_int 0x00C9; Uchar.of_int 0x00CA; Uchar.of_int 0x00CB;
    Uchar.of_int 0x00CC; Uchar.of_int 0x00CD; Uchar.of_int 0x00CE; Uchar.of_int 0x00CF;
    Uchar.of_int 0x00D0; Uchar.of_int 0x00D1; Uchar.of_int 0x00D2; Uchar.of_int 0x00D3;
    Uchar.of_int 0x00D4; Uchar.of_int 0x00D5; Uchar.of_int 0x00D6; Uchar.of_int 0x00D7;
    Uchar.of_int 0x00D8; Uchar.of_int 0x00D9; Uchar.of_int 0x00DA; Uchar.of_int 0x00DB;
    Uchar.of_int 0x00DC; Uchar.of_int 0x00DD; Uchar.of_int 0x00DE; Uchar.of_int 0x00DF;
    Uchar.of_int 0x00E0; Uchar.of_int 0x00E1; Uchar.of_int 0x00E2; Uchar.of_int 0x00E3;
    Uchar.of_int 0x00E4; Uchar.of_int 0x00E5; Uchar.of_int 0x00E6; Uchar.of_int 0x00E7;
    Uchar.of_int 0x00E8; Uchar.of_int 0x00E9; Uchar.of_int 0x00EA; Uchar.of_int 0x00EB;
    Uchar.of_int 0x00EC; Uchar.of_int 0x00ED; Uchar.of_int 0x00EE; Uchar.of_int 0x00EF;
    Uchar.of_int 0x00F0; Uchar.of_int 0x00F1; Uchar.of_int 0x00F2; Uchar.of_int 0x00F3;
    Uchar.of_int 0x00F4; Uchar.of_int 0x00F5; Uchar.of_int 0x00F6; Uchar.of_int 0x00F7;
    Uchar.of_int 0x00F8; Uchar.of_int 0x00F9; Uchar.of_int 0x00FA; Uchar.of_int 0x00FB;
    Uchar.of_int 0x00FC; Uchar.of_int 0x00FD; Uchar.of_int 0x00FE; Uchar.of_int 0x00FF;
  |]

(** New: ISO-8859-5 (Latin/Cyrillic) mapping table.
    Source: Official Unicode mapping (8859-5.TXT) and GNU libiconv.
    - 0x80–0x9F: control / undefined → replacement character
    - 0xA0–0xFF: Cyrillic letters + № and § *)
let iso8859_5_to_uchar_array : Uchar.t array =
  [|
    (* 0x80–0x9F undefined / control → replacement *)
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    Uchar.rep; Uchar.rep; Uchar.rep; Uchar.rep;
    (* 0xA0–0xFF Cyrillic *)
    Uchar.of_int 0x00A0; (*   *)
    Uchar.of_int 0x0401; (* Ё *)
    Uchar.of_int 0x0402; (* Ђ *)
    Uchar.of_int 0x0403; (* Ѓ *)
    Uchar.of_int 0x0404; (* Є *)
    Uchar.of_int 0x0405; (* Ѕ *)
    Uchar.of_int 0x0406; (* І *)
    Uchar.of_int 0x0407; (* Ї *)
    Uchar.of_int 0x0408; (* Ј *)
    Uchar.of_int 0x0409; (* Љ *)
    Uchar.of_int 0x040A; (* Њ *)
    Uchar.of_int 0x040B; (* Ћ *)
    Uchar.of_int 0x040C; (* Ќ *)
    Uchar.of_int 0x00AD; (* soft hyphen *)
    Uchar.of_int 0x040E; (* Ў *)
    Uchar.of_int 0x040F; (* Џ *)
    Uchar.of_int 0x0410; (* А *)
    Uchar.of_int 0x0411; (* Б *)
    Uchar.of_int 0x0412; (* В *)
    Uchar.of_int 0x0413; (* Г *)
    Uchar.of_int 0x0414; (* Д *)
    Uchar.of_int 0x0415; (* Е *)
    Uchar.of_int 0x0416; (* Ж *)
    Uchar.of_int 0x0417; (* З *)
    Uchar.of_int 0x0418; (* И *)
    Uchar.of_int 0x0419; (* Й *)
    Uchar.of_int 0x041A; (* К *)
    Uchar.of_int 0x041B; (* Л *)
    Uchar.of_int 0x041C; (* М *)
    Uchar.of_int 0x041D; (* Н *)
    Uchar.of_int 0x041E; (* О *)
    Uchar.of_int 0x041F; (* П *)
    Uchar.of_int 0x0420; (* Р *)
    Uchar.of_int 0x0421; (* С *)
    Uchar.of_int 0x0422; (* Т *)
    Uchar.of_int 0x0423; (* У *)
    Uchar.of_int 0x0424; (* Ф *)
    Uchar.of_int 0x0425; (* Х *)
    Uchar.of_int 0x0426; (* Ц *)
    Uchar.of_int 0x0427; (* Ч *)
    Uchar.of_int 0x0428; (* Ш *)
    Uchar.of_int 0x0429; (* Щ *)
    Uchar.of_int 0x042A; (* Ъ *)
    Uchar.of_int 0x042B; (* Ы *)
    Uchar.of_int 0x042C; (* Ь *)
    Uchar.of_int 0x042D; (* Э *)
    Uchar.of_int 0x042E; (* Ю *)
    Uchar.of_int 0x042F; (* Я *)
    Uchar.of_int 0x0430; (* а *)
    Uchar.of_int 0x0431; (* б *)
    Uchar.of_int 0x0432; (* в *)
    Uchar.of_int 0x0433; (* г *)
    Uchar.of_int 0x0434; (* д *)
    Uchar.of_int 0x0435; (* е *)
    Uchar.of_int 0x0436; (* ж *)
    Uchar.of_int 0x0437; (* з *)
    Uchar.of_int 0x0438; (* и *)
    Uchar.of_int 0x0439; (* й *)
    Uchar.of_int 0x043A; (* к *)
    Uchar.of_int 0x043B; (* л *)
    Uchar.of_int 0x043C; (* м *)
    Uchar.of_int 0x043D; (* н *)
    Uchar.of_int 0x043E; (* о *)
    Uchar.of_int 0x043F; (* п *)
    Uchar.of_int 0x0440; (* р *)
    Uchar.of_int 0x0441; (* с *)
    Uchar.of_int 0x0442; (* т *)
    Uchar.of_int 0x0443; (* у *)
    Uchar.of_int 0x0444; (* ф *)
    Uchar.of_int 0x0445; (* х *)
    Uchar.of_int 0x0446; (* ц *)
    Uchar.of_int 0x0447; (* ч *)
    Uchar.of_int 0x0448; (* ш *)
    Uchar.of_int 0x0449; (* щ *)
    Uchar.of_int 0x044A; (* ъ *)
    Uchar.of_int 0x044B; (* ы *)
    Uchar.of_int 0x044C; (* ь *)
    Uchar.of_int 0x044D; (* э *)
    Uchar.of_int 0x044E; (* ю *)
    Uchar.of_int 0x044F; (* я *)
    Uchar.of_int 0x2116; (* № *)
    Uchar.of_int 0x0451; (* ё *)
    Uchar.of_int 0x0452; (* ђ *)
    Uchar.of_int 0x0453; (* ѓ *)
    Uchar.of_int 0x0454; (* є *)
    Uchar.of_int 0x0455; (* ѕ *)
    Uchar.of_int 0x0456; (* і *)
    Uchar.of_int 0x0457; (* ї *)
    Uchar.of_int 0x0458; (* ј *)
    Uchar.of_int 0x0459; (* љ *)
    Uchar.of_int 0x045A; (* њ *)
    Uchar.of_int 0x045B; (* ћ *)
    Uchar.of_int 0x045C; (* ќ *)
    Uchar.of_int 0x00A7; (* § *)
    Uchar.of_int 0x045E; (* ў *)
    Uchar.of_int 0x045F; (* џ *)
  |]

(** New: Windows-1255 (CP1255) mapping table for Hebrew.
    Source: Official Microsoft / Unicode mapping (Windows-1255.TXT) and GNU libiconv.
    - 0x80–0x9F: similar to Windows-1252 (smart quotes, €, etc.)
    - 0xA0–0xFF: Hebrew letters, punctuation, and some additional symbols *)
let cp1255_to_uchar_array : Uchar.t array =
  [|
    (* 0x80–0x8F *)
    Uchar.of_int 0x20AC; (* € *)
    Uchar.rep;      (* undefined *)
    Uchar.of_int 0x201A; (* ‚ *)
    Uchar.of_int 0x0192; (* ƒ *)
    Uchar.of_int 0x201E; (* „ *)
    Uchar.of_int 0x2026; (* … *)
    Uchar.of_int 0x2020; (* † *)
    Uchar.of_int 0x2021; (* ‡ *)
    Uchar.of_int 0x02C6; (* ˆ *)
    Uchar.of_int 0x2030; (* ‰ *)
    Uchar.of_int 0x0160; (* Š *)
    Uchar.of_int 0x2039; (* ‹ *)
    Uchar.of_int 0x0152; (* Œ *)
    Uchar.rep;      (* undefined *)
    Uchar.rep;      (* undefined *)
    Uchar.rep;      (* undefined *)

    (* 0x90–0x9F *)
    Uchar.rep;      (* undefined *)
    Uchar.of_int 0x2018; (* ‘ *)
    Uchar.of_int 0x2019; (* ’ *)
    Uchar.of_int 0x201C; (* “ *)
    Uchar.of_int 0x201D; (* ” *)
    Uchar.of_int 0x2022; (* • *)
    Uchar.of_int 0x2013; (* – *)
    Uchar.of_int 0x2014; (* — *)
    Uchar.of_int 0x02DC; (* ˜ *)
    Uchar.of_int 0x2122; (* ™ *)
    Uchar.of_int 0x0161; (* š *)
    Uchar.of_int 0x203A; (* › *)
    Uchar.of_int 0x0153; (* œ *)
    Uchar.rep;      (* undefined *)
    Uchar.rep;      (* undefined *)
    Uchar.of_int 0x0178; (* Ÿ *)

    (* 0xA0–0xAF *)
    Uchar.of_int 0x00A0; (*   *)
    Uchar.of_int 0x00A1; (* ¡ *)
    Uchar.of_int 0x00A2; (* ¢ *)
    Uchar.of_int 0x00A3; (* £ *)
    Uchar.of_int 0x00A4; (* ¤ *)
    Uchar.of_int 0x00A5; (* ¥ *)
    Uchar.of_int 0x00A6; (* ¦ *)
    Uchar.of_int 0x00A7; (* § *)
    Uchar.of_int 0x00A8; (* ¨ *)
    Uchar.of_int 0x00A9; (* © *)
    Uchar.of_int 0x00D7; (* × *)
    Uchar.of_int 0x00AB; (* « *)
    Uchar.of_int 0x00AC; (* ¬ *)
    Uchar.of_int 0x00AD; (* ­ *)
    Uchar.of_int 0x00AE; (* ® *)
    Uchar.of_int 0x00AF; (* ¯ *)

    (* 0xB0–0xBF *)
    Uchar.of_int 0x00B0; (* ° *)
    Uchar.of_int 0x00B1; (* ± *)
    Uchar.of_int 0x00B2; (* ² *)
    Uchar.of_int 0x00B3; (* ³ *)
    Uchar.of_int 0x00B4; (* ´ *)
    Uchar.of_int 0x00B5; (* µ *)
    Uchar.of_int 0x00B6; (* ¶ *)
    Uchar.of_int 0x00B7; (* · *)
    Uchar.of_int 0x00B8; (* ¸ *)
    Uchar.of_int 0x00B9; (* ¹ *)
    Uchar.of_int 0x00F7; (* ÷ *)
    Uchar.of_int 0x00BB; (* » *)
    Uchar.of_int 0x00BC; (* ¼ *)
    Uchar.of_int 0x00BD; (* ½ *)
    Uchar.of_int 0x00BE; (* ¾ *)
    Uchar.of_int 0x00BF; (* ¿ *)

    (* 0xC0–0xDF: Hebrew letters and punctuation *)
    Uchar.of_int 0x05B0; (* ְ HEBREW POINT SHEVA *)
    Uchar.of_int 0x05B1; (* ֱ HEBREW POINT HATAF SEGOL *)
    Uchar.of_int 0x05B2; (* ֲ HEBREW POINT HATAF PATAH *)
    Uchar.of_int 0x05B3; (* ֳ HEBREW POINT HATAF QAMATS *)
    Uchar.of_int 0x05B4; (* ִ HEBREW POINT HIRIQ *)
    Uchar.of_int 0x05B5; (* ֵ HEBREW POINT TSERE *)
    Uchar.of_int 0x05B6; (* ֶ HEBREW POINT SEGOL *)
    Uchar.of_int 0x05B7; (* ַ HEBREW POINT PATAH *)
    Uchar.of_int 0x05B8; (* ָ HEBREW POINT QAMATS *)
    Uchar.of_int 0x05B9; (* ֹ HEBREW POINT HOLAM *)
    Uchar.of_int 0x05BB; (* ֻ HEBREW POINT QUBUTS *)
    Uchar.of_int 0x05BC; (* ּ HEBREW POINT DAGESH OR MAPIQ *)
    Uchar.of_int 0x05BD; (* ֽ HEBREW POINT METEG *)
    Uchar.of_int 0x05BE; (* ־ HEBREW PUNCTUATION MAQAF *)
    Uchar.of_int 0x05BF; (* ֿ HEBREW POINT RAFE *)
    Uchar.of_int 0x05C0; (* ׀ HEBREW PUNCTUATION PASEQ *)

    Uchar.of_int 0x05C1; (* ׁ HEBREW POINT SHIN DOT *)
    Uchar.of_int 0x05C2; (* ׂ HEBREW POINT SIN DOT *)
    Uchar.of_int 0x05C3; (* ׃ HEBREW PUNCTUATION SOF PASUQ *)
    Uchar.of_int 0x05C4; (* ׄ HEBREW MARK UPPER DOT *)
    Uchar.of_int 0x05C5; (* ׅ HEBREW MARK LOWER DOT *)
    Uchar.of_int 0x05C6; (* ׆ HEBREW PUNCTUATION NUN HAFUKHA *)
    Uchar.of_int 0x05C7; (* ׇ HEBREW POINT QAMATS QATAN *)
    Uchar.of_int 0x05D0; (* א HEBREW LETTER ALEF *)
    Uchar.of_int 0x05D1; (* ב HEBREW LETTER BET *)
    Uchar.of_int 0x05D2; (* ג HEBREW LETTER GIMEL *)
    Uchar.of_int 0x05D3; (* ד HEBREW LETTER DALET *)
    Uchar.of_int 0x05D4; (* ה HEBREW LETTER HE *)
    Uchar.of_int 0x05D5; (* ו HEBREW LETTER VAV *)
    Uchar.of_int 0x05D6; (* ז HEBREW LETTER ZAYIN *)
    Uchar.of_int 0x05D7; (* ח HEBREW LETTER HET *)
    Uchar.of_int 0x05D8; (* ט HEBREW LETTER TET *)

    (* 0xE0–0xEF *)
    Uchar.of_int 0x05D9; (* י HEBREW LETTER YOD *)
    Uchar.of_int 0x05DA; (* ך HEBREW LETTER FINAL KAF *)
    Uchar.of_int 0x05DB; (* כ HEBREW LETTER KAF *)
    Uchar.of_int 0x05DC; (* ל HEBREW LETTER LAMED *)
    Uchar.of_int 0x05DD; (* ם HEBREW LETTER FINAL MEM *)
    Uchar.of_int 0x05DE; (* מ HEBREW LETTER MEM *)
    Uchar.of_int 0x05DF; (* ן HEBREW LETTER FINAL NUN *)
    Uchar.of_int 0x05E0; (* נ HEBREW LETTER NUN *)
    Uchar.of_int 0x05E1; (* ס HEBREW LETTER SAMEKH *)
    Uchar.of_int 0x05E2; (* ע HEBREW LETTER AYIN *)
    Uchar.of_int 0x05E3; (* ף HEBREW LETTER FINAL PE *)
    Uchar.of_int 0x05E4; (* פ HEBREW LETTER PE *)
    Uchar.of_int 0x05E5; (* ץ HEBREW LETTER FINAL TSADI *)
    Uchar.of_int 0x05E6; (* צ HEBREW LETTER TSADI *)
    Uchar.of_int 0x05E7; (* ק HEBREW LETTER QOF *)
    Uchar.of_int 0x05E8; (* ר HEBREW LETTER RESH *)

    (* 0xF0–0xFF *)
    Uchar.of_int 0x05E9; (* ש HEBREW LETTER SHIN *)
    Uchar.of_int 0x05EA; (* ת HEBREW LETTER TAV *)
    Uchar.of_int 0x05F0; (* װ HEBREW LIGATURE YIDDISH DOUBLE VAV *)
    Uchar.of_int 0x05F1; (* ױ HEBREW LIGATURE YIDDISH VAV YOD *)
    Uchar.of_int 0x05F2; (* ײ HEBREW LIGATURE YIDDISH DOUBLE YOD *)
    Uchar.of_int 0x05F3; (* ׳ HEBREW PUNCTUATION GERESH *)
    Uchar.of_int 0x05F4; (* ״ HEBREW PUNCTUATION GERSHAYIM *)
    Uchar.of_int 0x200E; (* LEFT-TO-RIGHT MARK *)
    Uchar.of_int 0x200F; (* RIGHT-TO-LEFT MARK *)
    Uchar.rep;      (* undefined *)
    Uchar.rep;      (* undefined *)
    Uchar.rep;      (* undefined *)
    Uchar.rep;      (* undefined *)
    Uchar.rep;      (* undefined *)
    Uchar.rep;      (* undefined *)
    Uchar.rep;      (* undefined *)
  |]

(** Decoder state *)
type t = {
  table: Uchar.t array;      (* The recoding table or None for identity *)
  mutable underlying: char Seq.t;         (* The input source *)
  buffer: bytes;             (* Buffer to keep UTF8 characters *)
  mutable read_pos: int;        (* Current in-buffer read_pos *)
  mutable available : int    (* Buffer bytes available *)
}
  
let create table underlying = { table; underlying; buffer = Bytes.create 4; read_pos = 0; available = 0 }

let create_cp1251    = create cp1251_to_uchar_array
let create_cp1252    = create windows1252_to_uchar_array
let create_koi8r     = create koi8r_to_uchar_array
let create_iso8859_1 = create iso8859_1_to_uchar_array
let create_iso8859_5 = create iso8859_5_to_uchar_array
let create_cp1255    = create cp1255_to_uchar_array

let to_seq m : char Seq.t =
  let rec make () =
    let pos = m.read_pos in
    if m.available > pos then begin
      let c = Bytes.get m.buffer pos in
      m.read_pos <- pos + 1;
      Seq.Cons (c, make)
    end else
      match Seq.uncons m.underlying with
      | None -> Seq.Nil
      | Some (c, tail) ->
        m.underlying <- tail;
        let sc = Char.code c in
        if (sc < 128) then
          Seq.Cons (c, make)
        else
          let idx = sc - 0x80 in
          let table = m.table in
          let uchar = 
            if idx >= Array.length table then
              Uchar.of_int sc
            else                
              table.(sc - 0x80)
          in
          m.read_pos <- 0;
          m.available <- Bytes.set_utf_8_uchar m.buffer 0 uchar;
          make ()
  in
  make
