====================================
Home Book Library Management Project
====================================

.. contents::
   :depth: 2
   :local:

Programming Language
--------------------

OCaml

Location
--------

https://github.com/tsichevski/ocaml-books.git

Goals
-----

- Import ZIPed library archives
- Partially parse books in FB2 format: extract title and author information. Convert legacy Russian character code sets to unicode
- Group books by author
- Make books accessible by author, either:
  
  - Put files into the sub-directories named by authors
  - Create an index file and a tool, which navigates library by author

Challenges and Solutions
------------------------

Dealing with Unicode in OCaml
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OCaml's standard library has limited Unicode support. The most commonly used library for proper Unicode handling (including UTF-8 strings and conversion from legacy encodings) is **Camomile**.

Alternative modern choices include:

- **Uutf** + **Uucp** + **Uunf** (for UTF decoding/encoding, character properties and normalization)
- **uucd** / **uuseg** ecosystem packages

For converting legacy Russian encodings (CP1251 / windows-1251, KOI8-R, ISO-8859-5, etc.) to Unicode/UTF-8, **Camomile** provides the most straightforward recoding facilities.

Finding an Appropriate Index Format
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Recommended options (persistent / on-disk indices):

1. **index** library (opam package: index)
   
   - Designed exactly for persistent key-value indices in OCaml
   - Supports different backends (pack, layered, etc.)
   - Good performance for this kind of use-case

2. **irmin** (very powerful, git-like versioned store)
   
   - Overkill for simple author → books mapping, but excellent if you later want versioning, branching, or replication

3. **sqlite3** + **caqti** / **sqlite3-ocaml**
   
   - Very simple and widely understood
   - Easy to query with SQL

4. Plain text / JSON / S-expressions + in-memory cache
   
   - Simplest, but scales poorly and requires re-parsing on every start

For most book library use-cases **index** or **sqlite3** are the best balance of simplicity and performance.

Implementation Overview
-----------------------

No Jane libraries for now
~~~~~~~~~~~~~~~~~~~~~~~~~

After some experiments I decided against using Jane libraries Base/Core despinte the excellent book ``Real World Ocaml`` is based in using these libs.
The reasons:

#. The library modules "shadows" the standard library modules, which leads to confusion:

   #. I need to specify some base modules explicitly in the code
   #. Many 3-rd party libraries are based on stdlib modules
   #. By some reasons ocamldebug does not see Base/Core modules

Probably, I'll return to using Base in the future if I see it is really worth it.

Required Libraries (OPAM packages)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- zipc     — reading ZIP archives
- xmlm     — lightweight SAX-style XML parsing for FB2
- cmdliner — for command-line interface

