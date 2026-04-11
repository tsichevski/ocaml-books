====================================
Home Book Library Management Project
====================================

.. contents::
   :depth: 2
   :local:


Introduction
------------

Bookweald is a command-line tool and OCaml library for managing, indexing, and processing FictionBook (FB2) digital libraries.

It provides fast parsing, normalization, recoding, searching, and database-backed organization of FB2 files, with support for compression, character encoding detection/conversion, and metadata handling.

Key Features
~~~~~~~~~~~~

- FB2 2.1 parsing and validation support
- Character encoding support (UTF-8, CP1251, KOI8-R, etc.)
- Streaming decompression for zipped archives
- Efficient indexing
- Blacklist and author alias management

Location
--------

https://github.com/tsichevski/bookweald

Quickstart
----------

See ``docs/quickstart.rst`` for installation and basic usage.

.. note::
   Detailed configuration options are documented in ``docs/configuration.rst``.

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

  bookweald/
  ├── bin/
  │   ├── dune
  │   └── tool.ml               # entry point (currently minimal/test)
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
   dune build bin/tool.exe

   # Run (example – adjust paths)
   ./_build/default/bin/tool.exe


Current Limitations & Next Steps
--------------------------------

- Assumes all FB2 files are valid UTF-8 (no legacy encoding conversion yet)
- Author name is taken from the first <author> block only
- Files are extracted but not yet moved/grouped by author
- No command-line interface (only hardcoded test calls in tool.ml)
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