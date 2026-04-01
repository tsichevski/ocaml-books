========================
Configuration Management
========================

.. contents::
   :depth: 2
   :local:

Purpose
-------

The tool uses a JSON configuration file to store user-specific paths,
behavior flags, database settings, logging preferences and blacklist location.
This avoids hard-coding values and makes the tool flexible for different users and machines.

Configuration Type
------------------

The main configuration is defined by the record ``Config.t`` in ``lib/config.ml``.

.. note::
   All optional fields default to ``None`` or sensible values when missing in JSON.
   Unknown fields are ignored (``strict=false``).

Notes
-----

The tilda character in file path examples means user home directory and should be replaced by the real value. Bookweald does not expands tildas in file names.

Top-level fields
~~~~~~~~~~~~~~~~

- ``library_dir`` (string)  
  Directory containing incoming FB2 files (zips or raw).
  
  .. note:: unzipping zipped files on-the-fly is not yet implemented.

- ``target_dir`` (string)  
  Destination directory for organized books (author-based structure).

- ``invalid_dir`` (string)  
  Directory for files that failed validation or parsing.

  .. note:: this directory is currently user in the ``group`` command only. In the future, moving broken files to some other directory feature will be removed, so will be this configuration item.

- ``dry_run`` (boolean)  
  If ``true``, simulate all operations without modifying filesystem or database.

- ``max_component_len`` (int)  
  Maximum allowed length of a single filename component.  
  ``0`` means no limit (default).

  This value is used in the ``group`` command to limit the potentially long file names based on book titles and author names.

- ``jobs`` (int)  
  Number of parallel jobs (domain pool). Set to ``1`` to disable parallelism.

- ``log_file`` (string, optional)  
  Path to log file. If ``None``, logs go to stdout.

- ``blacklist`` (string, optional)  
  Path to the blacklist file for invalid/illegal FB2 files
  If ``None``, blacklisting is disabled.

- ``drop_existing_log_file_on_start`` (boolean)  
  If ``true`` and ``log_file`` is set: truncate the log on startup (otherwise append).

- ``log_level`` (string, optional)  
  Override the default "info" logging level ("quiet", "error", "warning", "info", "debug", "app").

- ``alias_file`` (string, optional)  
  Path to author alias JSON file.

- ``database`` (object)  
  PostgreSQL connection settings:

    - ``host`` (string)  
      Hostname or IP address of the PostgreSQL server.  
      Default: ``localhost``

    - ``port`` (int)  
      TCP port the PostgreSQL server listens on.  
      Default: ``5432``

    - ``user`` (string)  
      Username for normal (read/write) operations on the book database.  
      Default: ``books``

    - ``passwd`` (string)  
      Password for the normal user.  
      Default: ``books``

    - ``name`` (string)  
      Name of the database containing the book metadata.  
      Default: ``books``

    - ``admin`` (string)  
      Username with administrative privileges (used for schema creation and migrations).  
      Default: ``admin``

    - ``admin_passwd`` (string)  
      Password for the admin user.  
      Default: ``admin``

Default Values
--------------

When no config file is found, these defaults are used::

   library_dir      = ~/books/incoming
   target_dir       = ~/books/organized
   invalid_dir      = ~/books/invalid
   dry_run          = false
   max_component_len = 0
   jobs             = 1
   log_file         = None
   blacklist        = None
   drop_existing_log_file_on_start = false
   log_level        = None
   alias_file       = None

   database:
     host         = localhost
     port         = 5432
     user         = books
     passwd       = books
     name         = books
     admin        = admin
     admin_passwd = admin

Configuration File Locations
----------------------------

The tool searches for ``config.json`` in this order (first match wins):

1. ``./config.json`` (current directory — useful for overrides)
2. ``~/.config/bookweald/config.json`` (XDG-style user config)

Default Configuration Creation
------------------------------

Use the ``init`` subcommand::

   bookweald init

Or with a custom path::

   bookweald init --config /path/to/config.json

Example Config File
-------------------

::

   {
     "library_dir": "/home/user/books/incoming",
     "target_dir": "/home/user/books/organized",
     "invalid_dir": "/home/user/books/invalid",
     "dry_run": false,
     "jobs": 4,
     "max_component_len": 0,
     "blacklist": "/home/user/.config/bookweald/blacklist.txt",
     "database": {
       "host": "localhost",
       "port": 5432,
       "user": "books",
       "passwd": "books",
       "name": "books",
       "admin": "admin",
       "admin_passwd": "admin"
     }
   }

Notes
-----

- JSON is pretty-printed when created by ``init``.
- The configuration is loaded with ``yojson`` and ``ppx_deriving_yojson``.
- See ``lib/config.ml`` for the full ``Config.t`` and ``database_config`` types.
- Blacklist support is fully integrated (see ``docs/blacklist.rst``).

See also
--------

- :doc:`blacklist`
- :doc:`indexing`
- Command-line interface (``bookweald init``, etc.)