(lang dune 3.21)

(name ocaml-books)

(wrapped_executables false)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Vladimir Tsichevski <tsichevski@gmail.com>")

(maintainers "Vladimir Tsichevski <tsichevski@gmail.com>")

(license MIT)

(documentation https://url/to/documentation)

(package
 (name ocaml-books)
 (synopsis "Home Book Library Management Project")
 (description "Manage Personal Book Repository in FB2 Format")
 (depends
  (ocaml (>= 5.0.0))
  camlzip
  (cmdliner (>= 1.2.0))
  (miou (>= 0.5.4))
 )

 (tags
  ("ocaml" "books")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
