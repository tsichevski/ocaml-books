open Alcotest
module Recoding_channel = Bookweald.Recoding_channel
module Fs = Bookweald.Fs
module Utils = Bookweald.Utils
open Recoding_channel

let recode create input =
  let rc = create (Utils.ic_to_seq input) in
  String.of_seq (to_seq rc)

let test_cp1251 () =
  let input = In_channel.open_bin "../../../test/fixtures/cp1251_cp1251.txt" in
  let recoded =  recode create_cp1251 input in
  let expected = Fs.read_file_binary "../../../test/fixtures/cp1251_utf8.txt" in
  check string
    "cp1251" 
    expected
    recoded

let test_koi8 () =
  let input = In_channel.open_bin "../../../test/fixtures/128-255.txt" in
  let recoded =  recode create_koi8r input in
  Stdlib.Printf.printf "%s\n" recoded;  
  let expected = Fs.read_file_binary "../../../test/fixtures/128-255_koi8_utf8.txt" in
  Stdlib.Printf.printf "%s\n" expected;  
  check string "koi8"
    expected
    recoded

let tests = [
  test_case "cp1251 recoding" `Quick test_cp1251;
  test_case "koi8 all recoding" `Quick test_koi8;
]

