open Alcotest
open Ocaml_books.Xml_declaration

let test_extract_encoding () =
  let enc = Ocaml_books.Xml_declaration.extract_encoding 
    {|<?xml version="1.0" encoding="windows-1251"?>|}
  in
  check string "detects cp1251" "windows-1251" enc

let test_extract_encoding_default () =
  let enc = Ocaml_books.Xml_declaration.extract_encoding {|<?xml version="1.0"?>|}
  in
  check string "defaults to utf-8" "utf-8" enc

let test_extract_encoding_malformed () =
  let enc = Ocaml_books.Xml_declaration.extract_encoding {|garbage|}
  in
  check string "malformed returns utf-8" "utf-8" enc

let tests = [
  test_case "extract encoding (cp1251)" `Quick test_extract_encoding;
  test_case "extract encoding (no encoding attr)" `Quick test_extract_encoding_default;
  test_case "extract encoding (malformed)" `Quick test_extract_encoding_malformed;
]