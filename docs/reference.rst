======================
Command-Line Reference
======================

BookWeald is a command-line tool for managing your FictionBook (FB2) library.  
It helps you organize, validate, index, and store information about your books.

Run any command with ``--help`` to see detailed options and usage.

Available Commands
------------------

.. toctree::
   :maxdepth: 2

   init_cmd
   extract_cmd
   validate_cmd
   schema_init_cmd
   index_cmd
   group_cmd

Common Options
--------------

- ``--config <file>`` or ``-c <file>`` — use a specific configuration file.
- ``--dry-run`` — simulate the operation and show what would happen without making any real changes (very useful before grouping).
- ``--jobs <number>`` or ``-j <number>`` — how many books to process at the same time.
- ``--verbose`` / ``-v`` — show more detailed messages.
- ``--quiet`` — show fewer messages.
