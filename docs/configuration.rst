=====================
Program Configuration
=====================

.. contents::
   :depth: 2
   :local:


Goals for configuration
-----------------------

The tool needs a persistent place to store:

- path to incoming ZIP archives / raw FB2 files (`library_dir`)
- destination directory where books will be organized (`target_dir`)
- optional settings (default encoding, dry-run mode, log level, etc.)

Location
--------

Configuration file will be placed in the standard XDG location:

``~/.config/ocaml-books/config.json``

This is the most conventional choice on Linux/macOS and is respected by many tools.


Chosen format
-------------

**JSON** — simple, human-readable, easy to edit, widely supported.

Library: **yojson** + **ppx_deriving_yojson**

::

   opam install yojson ppx_deriving_yojson


Why yojson + ppx_deriving_yojson
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- minimal dependencies
- type-safe (de)serialization
- good error messages
- easy to extend later (add new fields without breaking old configs)


Configuration type
------------------

::

   type t = {
     library_dir     : string;
     target_dir      : string;
     default_encoding: string option;   (* future use *)
     dry_run         : bool;
     verbose         : bool;
   }
   [@@deriving yojson { strict = false }]


Loading logic – priorities
--------------------------

1. Explicit path via command line argument (future)
2. ``./config.json`` (current directory – useful for project-specific overrides)
3. ``~/.config/ocaml-books/config.json`` (user-global default)
4. Hardcoded safe defaults

::

   let default_config () : t =
     {
       library_dir      = Filename.concat (Sys.getenv "HOME") "books/incoming";
       target_dir       = Filename.concat (Sys.getenv "HOME") "books/organized";
       default_encoding = Some "utf-8";
       dry_run          = false;
       verbose          = true;
     }


   let config_file_locations () : string list =
     [
       "config.json";
       Filename.concat (Sys.getenv "HOME") ".config/ocaml-books/config.json";
     ]


   let load () : t =
     let rec try_load = function
       | [] -> default_config ()
       | path :: rest ->
           if Sys.file_exists path then
             try
               let json = Yojson.Safe.from_file path in
               match t_of_yojson json with
               | Ok cfg -> cfg
               | Error e ->
                   Printf.eprintf "Invalid config %s: %s\n" path e;
                   try_load rest
             with e ->
               Printf.eprintf "Cannot read config %s: %s\n" path (Printexc.to_string e);
               try_load rest
           else
             try_load rest
     in
     try_load (config_file_locations ())


Usage example
-------------

::

   let cfg = Config.load () in

   Printf.printf "Organizing books from:\n  %s\n  → %s\n"
     cfg.library_dir cfg.target_dir;

   if cfg.dry_run then
     Printf.printf "Dry run mode – no files will be moved\n";


Creating default config (optional command)
------------------------------------------

::

   let create_default path =
     let cfg = default_config () in
     let json = t_to_yojson cfg in
     let pretty = Yojson.Safe.pretty_to_string ~std:true json in
     let oc = open_out path in
     output_string oc (pretty ^ "\n");
     close_out oc;
     Printf.printf "Created default config: %s\n" path


Directory setup
---------------

Add to ``lib/dune``:

.. code-block:: lisp

   (library
    (name ocaml_books)
    (libraries unix zip xml-light yojson ppx_deriving_yojson.runtime))


Add new file ``lib/config.ml`` with the code above.

Next steps suggestions
----------------------

- Add ``--config PATH`` command-line argument (using Arg or cmdliner)
- Add simple ``init`` subcommand to create default config
- Validate that ``library_dir`` and ``target_dir`` exist and are directories
- Decide whether to support environment variables override (XDG_CONFIG_HOME, etc.)


