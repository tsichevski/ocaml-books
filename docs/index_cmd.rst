===============
 Index Command
===============

The ``index`` command reads all valid FB2 files and adds their details (title, authors, language, genre, etc.) into the database.

- Skips any files listed in the blacklist.
- Can process multiple books in parallel (controlled by the ``jobs`` setting).
- Shows a final summary with the total number of successfully indexed files.

Example::

  bookweald index

