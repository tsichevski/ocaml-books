==============
Author Aliases
==============

.. index:: author aliases, canonical authors, aliases, fb2 authors
           
.. contents::
   :depth: 2
   :local:

Introduction
------------

This document specifies the handling of author name aliases in the bookweald library manager.

The same real author may appear under slightly different name strings in FB2 ``<author>`` blocks. An alias mechanism maps each variant to a single canonical author record.

Key Features
------------

- **Rule**: Provide an alias table that maps every variant name to one canonical author.
- **Rule**: Canonical author data is used for grouping books by author and for naming author sub-directories on disk.
- **Rule**: Books without any author are grouped under a special directory (configurable via ``no_author_dir`` in ``config.json``).
- **Rule**: The alias mapping is maintained **only** in a human-readable JSON file intended for manual editing by the user. The tool does not currently provide automated alias management and does **not** store aliases in the PostgreSQL database.

Aliases File
~~~~~~~~~~~~

The aliases mapping is contained in a JSON file. Its location is defined in the tool configuration under the key ``alias_file``::

   {
       ...
       "alias_file": "/some_path_to/aliases.json",
       ...
   }

There is no default for alias file location, if the file is not configured, author aliases are no used.

File Format
~~~~~~~~~~~

The file is a JSON object where each key is a canonical author name and the value is an array of all known alias strings that should map to it.

Example::

   {
     "Иванов Иван Иванович": [
       "Иванов И. И.",
       "Иванов Иван",
       "Ivanov I.I.",
       "И.И. Иванов"
     ],
     "Петров Сергей Петрович": [
       "Петров С.",
       "Petrov S."
     ],
     "_No_Author_": []   // optional sentinel for books without author
   }

Configuration Reference
~~~~~~~~~~~~~~~~~~~~~~~

See ``config.json`` for the full set of settings, including:

- ``alias_file`` — optional path to the aliases JSON file (no default)

Where alias are used in the program
-----------------------------------

- ``index`` command: authors are mapped to aliases before the data is stored in DB
