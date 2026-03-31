=============
Illegal Files
=============

.. index:: illegal files, broken files, duplicates, registry
.. contents::
   :depth: 2
   :local:

Introduction
------------

This document describes the format and handling of the ``illegal_files.txt`` registry used by bookweald to permanently exclude certain files from indexing.

Purpose
-------

The registry records files that must never be processed or stored in the main ``books`` table. This includes pure duplicates, broken FB2/XML files, files without titles, and other problematic cases.

Key Rules
---------

- **Rule**: Only the human-editable text file ``illegal_files.txt`` is used. No PostgreSQL table stores this information.
- **Rule**: On application startup the file is loaded into an in-memory ``Hashtbl.t`` for fast lookup by relative path.
- **Rule**: The main PostgreSQL ``books`` table contains **only** successfully processed valid books.
- **Rule**: Relative file paths are stored (absolute paths are unreliable because files can be imported from any directory).

File Format
~~~~~~~~~~~

Location: ``~/.config/bookweald/illegal_files.txt``

One entry per line with fields separated by ``|``:

::

   PATH|ERROR_TYPE|COMMENT

Fields:

- ``PATH`` — relative file path (or basename for simple cases)
- ``ERROR_TYPE`` — one of: ``DUPLICATE``, ``BROKEN_XML``, ``NO_TITLE``, ``OTHER``
- ``COMMENT`` — optional free-text note (``|`` characters inside comment must be escaped as ``\|``)

Lines beginning with ``#`` are treated as comments and ignored.

Example
~~~~~~~

::

   # Manually decided duplicates (keep the better version)
   Book Title.fb2|DUPLICATE|keep the later version with better format
   broken.fb2|BROKEN_XML|xml parsing failed at line 42
   NoTitle.fb2|NO_TITLE
   some/file/with/path.fb2|OTHER|custom reason here

Implementation Notes
~~~~~~~~~~~~~~~~~~~~

- Loaded in ``lib/config.ml`` into ``Hashtbl.t string (string * string option)``
- During import in the main pipeline:
  - Check if the file’s relative path exists in the illegal registry.
  - If present → silently skip the file.
  - If a newly discovered file has no title after parsing → add it to the registry with ``NO_TITLE`` and skip.