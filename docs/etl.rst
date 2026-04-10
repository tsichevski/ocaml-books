===============================================
Incomplete Author Name Resolution (Future Plan)
===============================================

.. contents::
   :depth: 2
   :local:

Introduction
------------

The ``bookweald`` FB2 parser (in ``lib/fb2_parse.ml``) extracts author names and titles from ZIP archives, after converting legacy Russian encodings to Unicode. These author strings are often incomplete or abbreviated, leading to poor grouping in author sub-directories or index files. 

This feature adds automatic or semi-automatic resolution of full canonical author names using the extracted title and partial author, via public Internet book databases.

Key Requirements
----------------

- Input: Book title and partial author (post-Unicode normalization).
- Output: Full original author name for grouping.
- Modes: automatic (best-match heuristic) or semi-automatic (CLI prompt with candidates).
- Offline fallback: retain raw parsed name if lookup fails or is disabled.
- No impact on core import flow unless explicitly enabled.

Recommended APIs
~~~~~~~~~~~~~~~~

- Primary: Open Library Search API (free, no key required, JSON output). Books in English.
- Alternative: Google Books API (richer data, requires key).

Query example::

  https://openlibrary.org/search.json?q=title:BookTitle+author:PartialAuthor

OCaml Implementation
--------------------

Dependencies
~~~~~~~~~~~~

Add via OPAM and declare in ``dune-project``:

- ``cohttp-lwt-unix`` for asynchronous HTTP.
- ``yojson`` for JSON parsing.
- ``lwt`` for concurrency (already implied by cohttp).

New Module
~~~~~~~~~~

Create ``lib/author_resolver.ml``::

  open Cohttp_lwt_unix
  open Yojson.Basic.Util

  let resolve title partial_author =
    let query = Printf.sprintf "%s %s" title partial_author in
    let uri = Uri.of_string ("https://openlibrary.org/search.json?q=" ^ query) in
    Client.get uri >>= fun (resp, body) ->
    (* parse JSON, extract best author match, return Lwt.t string option *)

Integration
~~~~~~~~~~~

- Call after FB2 parsing in the import pipeline.
- Update author grouping and directory/index logic to prefer resolved names.
- Store resolved names persistently in the planned index format (to avoid repeated lookups).
- Add CLI flag ``--resolve-authors`` for opt-in.

Challenges Addressed
~~~~~~~~~~~~~~~~~~~~

- Unicode: Build on existing conversion; all API strings use UTF-8.
- Index format: Resolved names feed directly into author sub-directories or navigable index tool.
- Rate limits / errors: Simple cache and exponential back-off.

Next Steps on GitHub
--------------------

- Add the new module and dependencies.
- Extend ``fb2_parse.ml`` and main import flow.
- Update README.rst with usage example.
- Test with sample ZIP archives containing partial Russian author names.
  
