=============
Group Command
=============

.. contents::
   :depth: 2
   :local:

Purpose
-------

The ``group`` command organizes your digital book library by author. It scans the library directory for FB2 book files, extracts metadata, sanitizes names, and moves each book into an author-named subdirectory under the target directory.

The resulting structure is always: ``target_dir/Author Name/Title.fb2``

Filename Devising Algorithm
~~~~~~~~~~~~~~~~~~~~~~~~~~~

1. **Author handling**:
   
   - Only the **first** ``<author>`` block in the FB2 metadata is used.
   - All other authors (if any) are completely ignored for directory.
   - Parts ``<last-name>``, ``<first-name>``, ``<middle-name>`` are taken in order, skipping empty ones after normalization.
   - Joined with single spaces, then passed through the global sanitization function (restricts the maximum file name length).
   - If the result is empty, falls back to ``"UnknownAuthor"``.

2. **Title handling**:
   
   - The ``<book-title>`` text is taken (the library parsing layer **guarantees** that a parsed book always has a non-empty title)
   - The title is passed through the global sanitization function (removes illegal characters, collapses whitespace, trims, restricts the maximum file name length).

3. **Basename creation**:
   
   - The sanitized title is used as initial basename (without extension).
   - The original file extension is preserved (usually ``.fb2``, or kept as ``.fb2.zip`` if the source was a zipped FB2).

4. **Uniqueness handling in the author directory**:
   
   - The tool first computes the ideal target path (author directory + sanitized title + extension).
   - It then checks whether a file with that exact basename was seen already in the current program run.
   - If a conflict is detected, it automatically appends a numeric suffix to the **title**:
     
     - First conflict → ``Title(1).fb2``
     - Second conflict → ``Title(2).fb2``
     - And so on, incrementing the number until a free name is found.
   - The suffix is added before the extension.

5. **Length limiting**:
   
   - The configured ``max-component-len`` is applied to both the author directory name and the full basename.
   - Truncation happens intelligently if needed, while always preserving the extension.

Key Features
------------

- Recursively scans for ``.fb2`` and ``.fb2.zip`` files
- Robust metadata parsing with strict title guarantee
- Consistent global sanitization for safe cross-platform filenames
- Automatic conflict resolution via numeric suffixes on the title only
- Dry-run mode to preview every planned move/rename
- Force mode to overwrite existing files
- Parallel processing support
- Per-file error reporting (does not stop on single-file failures)

Usage
-----

Basic usage::

   bookweald group

Common options:

- ``--dry-run`` / ``-n``: Preview without moving anything
- ``--force`` / ``-f``: Overwrite without prompting
- ``--path PATH``: Custom source directory
- ``--max-component-len N``: Limit path component length
- ``--jobs N`` / ``-j N``: Parallel jobs (1 disables parallelism)

Example::

   bookweald group --dry-run --path ./books

Notes
-----

- Only the first author determines the destination directory, other authors in the metadata are ignored for grouping and naming
- Because the library ensures every parsed book has a title, the basename is always well-formed
- Author directories are reused; no duplicate folders are created
- The process respects any configured blacklist