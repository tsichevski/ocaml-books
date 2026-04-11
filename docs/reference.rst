================================
BookWeald Command-Line Reference
================================

BookWeald is a command-line tool for managing your FictionBook (FB2) library.  
It helps you organize, validate, index, and store information about your books.

Run any command with ``--help`` to see detailed options and usage.

Available Commands
------------------

.. toctree::
   :maxdepth: 2

   init_cmd
   validate_cmd
   group_cmd

**extract** ``<zipfile>``
~~~~~~~~~~~~~~~~~~~~~~~~~

Extracts FB2 books from a ZIP archive into your incoming library folder (``library_dir``).

- Works with regular ZIP files and very large archives (larger than 4.5 GB).
- For large archives it automatically uses the external ``7z`` tool and prints a notice.
- Creates any needed folders automatically.

**schema-init**
~~~~~~~~~~~~~~~

Sets up the PostgreSQL database tables needed to store book information.

- Creates the tables for books, authors, and the links between them.
- Adds indexes and constraints.
- Uses the admin credentials from your configuration.

**index**
~~~~~~~~~

Reads all valid FB2 files and adds their details (title, authors, language, genre, etc.) into the database.

- Skips any files listed in the blacklist.
- Can process multiple books in parallel (controlled by the ``jobs`` setting).
- Shows a final summary with the total number of successfully indexed files.

Common Options
--------------

- ``--config <file>`` or ``-c <file>`` — use a specific configuration file.
- ``--dry-run`` — simulate the operation and show what would happen without making any real changes (very useful before grouping).
- ``--jobs <number>`` or ``-j <number>`` — how many books to process at the same time.
- ``--verbose`` / ``-v`` — show more detailed messages.
- ``--quiet`` — show fewer messages.

Examples
--------

Create initial configuration::

  bookweald init

Extract books from an archive::

  bookweald extract my_books.zip

Check your files for problems::

  bookweald validate

Set up the database::

  bookweald schema-init

Index all your books::

  bookweald index

Organize everything nicely::

  bookweald group

.. note::
   Run commands from the folder where you want the blacklist and logs to appear, or always specify the config file with ``--config``.
