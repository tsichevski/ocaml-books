open Alcotest
open Base
open Ocaml_books.Recoding_channel

let chars_to_string chars = String.concat ~sep:"" (List.map chars ~f:(fun c -> String.make 1 c))

let recode_cp1251_stream ic =
  let rc = Ocaml_books.Recoding_channel.create ic in
  let rec loop accu =
    match Ocaml_books.Recoding_channel.input_char rc with
    | None -> accu
    | Some ch ->
      (* Stdlib.Printf.printf "%c\n" ch; *)
      loop (ch::accu)
  in
  chars_to_string (List.rev (loop []))
    
let test_cp1251 () =
  let input = In_channel.open_bin "../../../test/fixtures/cp1251_cp1251.txt" in
  let recoded =  (recode_cp1251_stream input) in
  (* Stdlib.Printf.printf "%s\n" recoded; *)
  check string "dummy" "ЂЃ‚ѓ„…†‡€‰Љ‹ЊЌЋЏђ‘’“”•–—™љ›њќћџ ЎўЈ¤Ґ¦§Ё©Є«¬­®Ї°±Ііґµ¶·ё№є»јЅѕїАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя" recoded

let tests = [
  test_case "simple cp1251 recoding" `Quick test_cp1251;
]

