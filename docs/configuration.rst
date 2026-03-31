========================
Configuration Management
========================

.. contents::
   :depth: 2
   :local:

Purpose
-------

The tool uses a JSON configuration file to store user-specific paths and preferences.

This avoids hard-coding values and makes the tool more flexible for different users and machines.

Configuration type
------------------

The configuration is represented by a record with the following fields:

- library_dir (string)  
  Directory containing ZIP archives or raw FB2 files to process.

- target_dir (string)  
  Directory where organized books will be placed (author subdirectories).

- dry_run (boolean)  
  If true: simulate actions without modifying the file system.

- drop_existing_log_file_on_start (boolean)  
  If true and a ``log_file`` is configured: truncate (drop) the existing log file  
  on program startup.  
  Default: false (append mode).

- invalid_list_file (string, optional)  
  Path to the file where invalid FB2 files will be recorded (one per line).  
  If ``None``, illegal files are not managed (see ``docs/illegal-files.rst``).


Default values
--------------

When no valid config file is found, the tool uses these defaults::

   library_dir      = ~/books/incoming
   target_dir       = ~/books/organized
   dry_run          = false
   drop_existing_log_file_on_start = false
   invalid_list_file = None
   
Configuration file locations
----------------------------

The tool searches for the configuration file in this order:

1. ./config.json  
   (current working directory — useful for project-specific or per-session overrides)

2. ~/.config/bookweald/config.json  
   (standard user configuration directory on Linux/macOS)

If no valid file is found or parsing fails, the tool falls back to the defaults above.


Loading behavior
----------------

- The tool tries each location in order.
- If a file is found, it is parsed as JSON.
- Invalid JSON or unknown fields trigger a warning on stderr; the tool continues with defaults.
- Missing fields are filled with defaults.
- Read or permission errors are printed to stderr and fallback occurs.


Creating default configuration
------------------------------

Use the ``init`` subcommand::

   bookweald init

This creates ~/.config/bookweald/config.json with default values.

Alternatively, specify a custom path::

   bookweald init --config ./my-config.json

This writes to the given path instead.


Example config file
-------------------

::
   {
     "library_dir": "/home/user/my-fb2-collection/zips",
     "target_dir":  "/home/user/my-fb2-collection/organized",
     "dry_run":     false,
     "drop_existing_log_file_on_start": false,
     "invalid_list_file": "/home/user/.config/bookweald/illegal_files.txt",
   }

The file is created in pretty-printed JSON format for readability.


Notes
-----

- The tool does not currently support environment variable overrides or multiple config profiles.
- All paths are expanded using standard shell conventions (~ → home directory).
- JSON is pretty-printed when created.
- Future extensions may include:
  - Support for legacy encoding conversion
  - Command-line overrides for individual fields
  - Validation of paths (existence, writability)

See also
--------

- Command-line interface — how to use ``init`` and other commands
- Project structure — where config is used