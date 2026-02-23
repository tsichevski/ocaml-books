====================================
Home Book Library Management Project
====================================

.. contents::
   :depth: 2
   :local:


Overview
--------

A lightweight OCaml tool for organizing a personal collection of FB2 e-books.

Current scope (narrowed minimal viable implementation):

- Import books from ZIP archives containing FB2 files
- Extract individual FB2 files to a working directory
- Parse basic metadata from FB2: book title and author name(s)
- Group books by author (in-memory for now)
- Organize files by moving them into subdirectories named after authors

Future / optional directions (not yet implemented):

- Persistent index (using `index` library or SQLite)
- Navigation tool / CLI to browse by author
- Handling legacy Russian encodings (currently assumes UTF-8)
- Zipping processed originals
- Better filename sanitization & collision handling
- Support for multiple authors per book, series info, etc.


Programming Language
--------------------

OCaml 5.x


Location
--------

https://github.com/tsichevski/ocaml-books


Current Libraries Used
----------------------

Only minimal, lightweight dependencies are used:

+--------------------+----------------------------------------+----------------------------------------------------+
| Package            | Purpose                                | Why chosen                                         |
+====================+========================================+====================================================+
| camlzip / zip      | Read/extract ZIP archives              | Standard, reliable, small footprint                |
+--------------------+----------------------------------------+----------------------------------------------------+
| xml-light          | Parse FB2 XML for title & author       | Extremely lightweight, no extra deps, sufficient   |
+--------------------+----------------------------------------+----------------------------------------------------+
| unix (stdlib)      | File system operations (mkdir, rename) | No extra dependency needed                         |
+--------------------+----------------------------------------+----------------------------------------------------+

No heavy dependencies (camomile, yojson, cmdliner, index, etc.) are used yet.

Dune build system is used for project structure.


Project Structure (current)
---------------------------

::

  ocaml-books/
  ├── bin/
  │   ├── dune
  │   └── main.ml               # entry point (currently minimal/test)
  ├── lib/
  │   ├── dune
  │   ├── fs.ml                 # mkdir_p helper
  │   ├── unzip.ml              # ZIP extraction utilities
  │   └── fb2_parse.ml          # FB2 title/author extraction
  ├── dune-project              # (may be missing – add later)
  ├── .gitignore
  └── README.rst                # this file


How to Build & Run (current)
----------------------------

::

   # In project root
   dune build bin/main.exe

   # Run (example – adjust paths)
   ./_build/default/bin/main.exe


Current Limitations & Next Steps
--------------------------------

- Assumes all FB2 files are valid UTF-8 (no legacy encoding conversion yet)
- Author name is taken from the first <author> block only
- Files are extracted but not yet moved/grouped by author
- No command-line interface (only hardcoded test calls in main.ml)
- No persistent index or navigation tool

Planned next steps (in rough priority order):

1. Implement basic grouping by author (Hashtbl or Map)
2. Add file moving to author-named subdirectories
3. Add simple CLI (using Arg or cmdliner)
4. Add configuration (JSON or simple file)
5. Re-evaluate need for camomile (encoding) and index (persistent storage)

Contributions & feedback welcome!


License
-------

MIT