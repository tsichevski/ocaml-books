(lang dune 3.21)

(name ocaml-books)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Vladimir Tsichevski <tsichevski@gmail.com>")

(maintainers "Vladimir Tsichevski <tsichevski@gmail.com>")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name ocaml-books)
 (synopsis "Home Book Library Management Project")
 (description "Manage Personal Book Repository in FB2 Format")
 (depends ocaml)
 (tags
  ("ocaml" "books")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
