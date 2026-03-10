let () =
  Alcotest.run "ocaml_books" [
    "xml_declaration", Test_xml_declaration.tests;
    "recoding_channel", Test_recoding_channel.tests;
  ]