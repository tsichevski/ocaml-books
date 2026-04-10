=========
Blacklist
=========

.. index:: blacklist, illegal files, broken files, duplicates, registry
.. contents::
   :depth: 2
   :local:

Introduction
------------

This document describes the format and handling of the ``blacklist.txt`` registry used by bookweald to permanently exclude certain files from indexing and other processing.
This includes pure duplicates, broken FB2/XML files, files without titles, and other problematic cases.

Command supporting blacklisting
-------------------------------

Currently only ``validate`` command supports blacklisting.

Rules
---------

- **Rule**: ``blacklist.txt`` is human-editable text file. It intended both by manual and programmatic editing.
- **Rule**: On application startup the file is loaded into an in-memory table.
- **Rule**: File base names are stored (absolute paths are unreliable because files can be imported from any directory).

File Format
~~~~~~~~~~~

Location: set by the config ``blacklist`` optional item, no default. If not set, black listing is disabled.

One entry per line with fields separated by ``|``::

   PATH|COMMENT

Fields:

- ``PATH`` — file base name
- ``COMMENT`` — optional free-text note, usually the error message caused the blacklisting, ignored by bookweald

Lines beginning with ``#`` are treated as comments and ignored.

Example
~~~~~~~

::

   # Comment line
   Book Title.fb2|keep the later version with better format
   broken.fb2|xml parsing failed at line 42
   NoTitle.fb2|No title
