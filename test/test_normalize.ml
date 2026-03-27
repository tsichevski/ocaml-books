open Alcotest
open Ocaml_books.Normalize

let read_whole_binary_file (path : string) : string =
  In_channel.with_open_bin path In_channel.input_all

let test_normalize () =
  check string
    "Simple" (normalize_name "1щёпкина ") "Щепкина";
  check string "Compound" (normalize_name "Щепкина-Куперник") "Щепкина-Куперник"

let tests = [
  test_case "name normalization" `Quick test_normalize;
]

