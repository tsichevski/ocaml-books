let () =
  Alcotest.run "ocaml_books" [
    "xml_declaration", Test_xml_declaration.tests;
  ]