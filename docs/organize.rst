=================================
Organize Command
=================================

.. contents::
   :depth: 2
   :local:


Purpose
-------

The ``organize`` subcommand parses all FB2 files in the configured ``library_dir``,
extracts author and title metadata, groups books by author, and moves them into
subdirectories under ``target_dir`` named after each author.

Current behavior (as implemented):

- Scans only the top level of ``library_dir`` (no recursion yet)
- Processes only files ending with ``.fb2``
- Uses ``fb2_parse.parse_book_info`` for metadata extraction
- Groups by author name (case-insensitive, first author only)
- Sanitizes filenames and directory names
- Moves files to ``target_dir/author_name/author_name - title.fb2``
- Respects ``--dry-run`` (prints actions instead of moving)
- Respects ``--verbose`` (shows detailed progress and errors)

This is the core feature for making books accessible by author via subdirectories.


Usage
-----

Basic::

   ocaml-books organize

With options::

   ocaml-books organize --verbose
   ocaml-books organize --dry-run
   ocaml-books organize --config ./custom-config.json


Behavior details
----------------

1. Loads configuration (library_dir, target_dir, dry_run, verbose)

2. Lists all regular files in ``library_dir`` that end with ``.fb2``

3. For each file:
   - Parses author and title
   - On success: adds to in-memory grouping (Hashtbl by lowercase author)
   - On failure: prints error (does not stop processing)

4. For each author group:
   - Creates subdirectory ``target_dir / sanitized_author``
   - For each book:
     - Builds filename ``sanitized_author - sanitized_title.fb2``
     - In dry-run: prints what would be moved
     - Otherwise: moves the file using ``Sys.rename``

5. Prints summary (number of books processed, failures)


Known limitations (current version)
-----------------------------------

- No recursive scan of subdirectories in ``library_dir``
- Only the first ``<author>`` block is used (no support for multiple authors yet)
- Filename collisions (same author + title) overwrite without warning
- No copy mode (always move)
- No progress bar or detailed statistics
- No undo / backup of moved files


Example output (with --verbose)
-------------------------------

   Scanning directory: /home/user/books/incoming
   Found 12 candidate FB2 files
   Parsed: Лев Толстой → Война и мир
   Parsed: Антон Чехов → Вишнёвый сад
   Parse failed: broken.fb2: missing <title-info>
   Created directory: /home/user/books/organized/лев толстой
   Moved /home/user/books/incoming/war_and_peace.fb2 → /home/user/books/organized/лев толстой/лев толстой - война и мир.fb2
   Organized 11 books


Future improvements (planned)
-----------------------------

- Recursive directory scanning
- Support multiple authors per book (join with ", " or separate entries)
- Filename collision handling (add counter: "Title (2).fb2")
- Copy mode (--copy flag)
- Progress reporting or summary table
- Undo log / backup of original files


See also
--------

- Configuration Management — how to set library_dir and target_dir
- Command-line Interface — full list of options and subcommands