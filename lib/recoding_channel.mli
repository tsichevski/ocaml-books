(**
   Streaming decoder for legacy single-byte encodings to UTF-8 on-the-fly.

   Supported encodings:
   - Windows-1251 (CP1251) – Russian Cyrillic (Windows)
   - KOI8-R – Russian Cyrillic (Unix legacy)
   - Windows-1252 – Western European with smart quotes and €
   - ISO-8859-1 (Latin-1) – Classic Western European
   - ISO-8859-5 (Latin/Cyrillic) – Official Cyrillic
   - Windows-1255 (CP1255) – Hebrew with Niqqud support

   This module converts high bytes (0x80–0xFF) to proper UTF-8 sequences
   while passing ASCII (0x00–0x7F) unchanged.
*)

(** Opaque decoder state. *)
type t

(** {2 Creation functions} *)

(** [create_cp1251 ic] creates a decoder that converts Windows-1251 to UTF-8. *)
val create_cp1251 : char Seq.t -> t

(** [create_koi8r ic] creates a decoder that converts KOI8-R to UTF-8. *)
val create_koi8r : char Seq.t -> t

(** [create_cp1252 ic] creates a decoder that converts Windows-1252 to UTF-8. *)
val create_cp1252 : char Seq.t -> t

(** [create_iso8859_1 ic] creates a decoder that converts ISO-8859-1 (Latin-1) to UTF-8. *)
val create_iso8859_1 : char Seq.t -> t

(** [create_iso8859_5 ic] creates a decoder that converts ISO-8859-5 to UTF-8. *)
val create_iso8859_5 : char Seq.t -> t

(** [create_cp1255 ic] creates a decoder that converts Windows-1255 to UTF-8. *)
val create_cp1255 : char Seq.t -> t

(** {2 Input functions} *)

val to_seq : t -> char Seq.t
