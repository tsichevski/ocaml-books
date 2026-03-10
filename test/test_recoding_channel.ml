open Alcotest
open Base
open Ocaml_books.Recoding_channel

let bytes_to_string bytes = String.concat ~sep:""
    (List.map bytes
       ~f:(fun c ->
           match Char.of_int c with
           | None -> failwith "Cannot convert int to char"
           | Some c -> String.make 1 c))

let recode_stream rc =
  let rec loop accu =
    match Ocaml_books.Recoding_channel.input_byte rc with
    | None -> accu
    | Some ch ->
      loop (ch::accu)
  in
  bytes_to_string (List.rev (loop []))
    
let read_whole_binary_file (path : string) : string =
  Core.In_channel.with_file ~binary:true path ~f:In_channel.input_all

let test_cp1251 () =
  let input = In_channel.open_bin "../../../test/fixtures/cp1251_cp1251.txt" in
  let rc = Ocaml_books.Recoding_channel.create_cp1251 input in
  let recoded =  recode_stream rc in
  let expected = read_whole_binary_file "../../../test/fixtures/cp1251_utf8.txt" in
  check string
    "cp1251" 
    expected
    recoded

let test_koi8 () =
  let input = In_channel.open_bin "../../../test/fixtures/128-255.txt" in
  let rc = Ocaml_books.Recoding_channel.create_koi8r input in
  let recoded =  recode_stream rc in
  Stdlib.Printf.printf "%s\n" recoded;  
  let expected = read_whole_binary_file "../../../test/fixtures/128-255_koi8_utf8.txt" in
  Stdlib.Printf.printf "%s\n" expected;  
  check string "koi8"
    expected
    recoded

let tests = [
  test_case "cp1251 recoding" `Quick test_cp1251;
  test_case "koi8 all recoding" `Quick test_koi8;
]

