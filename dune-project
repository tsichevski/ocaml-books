(lang dune 3.21)
(name bookweald)
(wrapped_executables false)
(generate_opam_files true)
(source (github tsichevski/bookweald))
(authors "Vladimir Tsichevski <tsichevski@gmail.com>")
(maintainers "Vladimir Tsichevski <tsichevski@gmail.com>")
(bug_reports https://github.com/tsichevski/bookweald/issues)
(documentation https://github.com/tsichevski/bookweald/wiki)

(license MIT)


(package
 (name bookweald)
 (synopsis "Home Book Library Management Project")
 (description "Manage Personal Book Repository in FB2 Format")
 (depends
  (ocaml (>= 5.3.0))
  zipc
  (cmdliner (>= 1.2.0))
  (miou (>= 0.5.4))
  postgresql
 )

 (tags
  ("ocaml" "book" "library")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
