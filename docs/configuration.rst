.. _configuration:

=============
Configuration
=============

.. contents::
   :depth: 2
   :local:

Bookweald uses a JSON configuration file to store user-specific paths,
behavior flags, database settings, logging preferences, and the blacklist file location.

.. note:: The tilde character in file path examples means the user home directory and should be replaced by the real value. Bookweald does not expand tildes in file names.

Top-level fields
----------------

- ``library_dir`` (string)
  
  Directory containing incoming FB2 files (zips or raw). This field is required.

- ``target_dir`` (string)
  
  Destination directory for organized books (see :ref:`group_cmd`). This field is required.

- ``dry_run`` (boolean, optional)
  
  If ``true``, simulate all operations without modifying the filesystem or database. Default is ``false``.

- ``max_component_len`` (int, optional)
  
  Maximum allowed length of a single filename component.
  ``0`` means no limit (default).

  This value is used in the :ref:`group_cmd` to limit potentially long file names based on book titles and author names.

- ``jobs`` (int, optional)
  
  Number of parallel jobs. Set to ``1`` to disable parallelism. Default is to use all available CPU threads.

- ``log_file`` (string, optional)
  
  Path to the log file. If ``None``, logs go to stdout.

- ``blacklist`` (string, optional)
  
  Path to the blacklist file for invalid or illegal FB2 files.
  If ``None`` (default), blacklisting is disabled.

- ``drop_existing_log_file_on_start`` (boolean, optional)
  
  If ``true`` and ``log_file`` is set: truncate the log on startup (otherwise append). Default is ``false``.

- ``log_level`` (string, optional)
  
  Override the default "info" logging level ("quiet", "error", "warning", "info", "debug", "app").

- ``alias_file`` (string, optional)
  
  Path to the author alias JSON file. Default is ``None`` (aliasing feature disabled).

.. _db-configuration:

Database Configuration
----------------------

- ``database`` (JSON object)
  
  PostgreSQL connection settings (all optional with reasonable defaults):

  - ``host`` (string, optional)
      
    Hostname or IP address of the PostgreSQL server.
    Default: ``localhost``

  - ``port`` (int, optional)
    
    TCP port the PostgreSQL server listens on.
    Default: ``5432``

  - ``user`` (string, optional)
    
    Username for normal (read/write) operations on the book database.
    Default: ``books``

  - ``passwd`` (string, optional)
    
    Password for the normal user.
    Default: ``books``

  - ``name`` (string, optional)
    
    Name of the database containing the book metadata.
    Default: ``books``

  - ``admin`` (string, optional)
    
    Username with administrative privileges (used for schema creation and migrations).
    Default: ``admin``

  - ``admin_passwd`` (string, optional)
    
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

1. The value passed with the ``--config`` option
2. ``~/.config/bookweald/config.json``

Default Configuration File Creation
-----------------------------------

Use the ``init`` command::

   bookweald init

Or with a custom path::

   bookweald init --config /path/to/config.json

This creates a minimal configuration file.

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