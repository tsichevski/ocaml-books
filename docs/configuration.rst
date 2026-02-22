=================================
Configuration Management Proposal
=================================

.. contents::
   :depth: 2
   :local:


Overview
--------

The tool needs a simple, user-editable configuration file to store:

- path to the source book repository (ZIP archives or unpacked FB2 files)
- target directory where books will be organized (by-author subfolders or index location)
- default encoding guess for legacy Russian FB2 files
- optional: index storage path, log level, ignored patterns, etc.

Goal: minimal dependencies, human-readable format, easy to create/edit, safe defaults.


Recommended Approach
--------------------

**Format**          JSON  
**Main library**    yojson  
**Deriving**        ppx_deriving_yojson  
**Minimal fallback** ezjsonm (if stricter minimalism needed)

**Why JSON?**

- Widely understood and editable in any text editor
- Good tooling support (VS Code, jq, etc.)
- Easy to extend in the future
- Reasonable error messages via yojson
- ppx_deriving_yojson gives clean type-safe (de)serialization

**Alternative formats** (if JSON is not desired)

- TOML via otoml ─ modern, clean, good errors
- OCaml syntax via ez_config ─ very OCaml-native, no parsing overhead
- INI via config-file ─ very simple, but limited expressiveness

JSON + yojson is currently the best balance for this project.


Default Config Location
-----------------------

Two possible strategies (both common in CLI tools):

1. Project-local: ``config.json`` or ``.ocaml-books.json`` in the current working directory
2. User-global: ``~/.config/ocaml-books/config.json`` or ``~/.ocaml-books/config.json``

**Recommended hybrid**:

- Look first in current directory → ``./config.json``
- Then fallback to user home → ``~/.config/ocaml-books/config.json``
- If nothing found → use hardcoded safe defaults


Example Config File
-------------------

::

   {
     "library_dir":      "/home/user/books/incoming",
     "target_dir":       "/home/user/books/organized",
     "default_encoding": "windows-1251",
     "index_backend":    "pack",
     "index_path":       "library_index",
     "move_files":       true,
     "dry_run":          false,
     "log_level":        "info"
   }


Configuration Type & (De)serialization
--------------------------------------

::

   type config = {
     library_dir     : string;
     target_dir      : string;
     default_encoding: string option;
     index_backend   : string option;   (* "pack", "layered", "sqlite", … *)
     index_path      : string option;
     move_files      : bool;
     dry_run         : bool;
     log_level       : string option;
   } [@@deriving yojson { strict = false }]


Loading with fallback & merging
-------------------------------

::

   let default_config () =
     {
       library_dir      = Filename.concat (Sys.getenv "HOME") "books/incoming";
       target_dir       = Filename.concat (Sys.getenv "HOME") "books/organized";
       default_encoding = Some "windows-1251";
       index_backend    = Some "pack";
       index_path       = Some (Filename.concat (Sys.getenv "HOME") ".ocaml-books/library_index");
       move_files       = true;
       dry_run          = false;
       log_level        = Some "info";
     }

   let load () : config =
     let paths = [
       "config.json";
       Filename.concat (Sys.getenv "HOME") ".config/ocaml-books/config.json";
       Filename.concat (Sys.getenv "HOME") ".ocaml-books/config.json";
     ] in

     let rec try_load = function
       | [] -> default_config ()
       | p :: ps ->
           try
             let json = Yojson.Safe.from_file p in
             match config_of_yojson json with
             | Ok c -> c
             | Error _ -> try_load ps
           with _ -> try_load ps
     in

     let user_cfg = try_load paths in
     (* Merge: user values override defaults *)
     {
       library_dir      = user_cfg.library_dir;
       target_dir       = user_cfg.target_dir;
       default_encoding = user_cfg.default_encoding;
       index_backend    = user_cfg.index_backend;
       index_path       = user_cfg.index_path;
       move_files       = user_cfg.move_files;
       dry_run          = user_cfg.dry_run;
       log_level        = user_cfg.log_level;
     }


Saving config (optional – for “init” or “config set” command)
--------------------------------------------------------------

::

   let save path cfg =
     let json = config_to_yojson cfg in
     let pretty = Yojson.Safe.pretty_to_string ~std:true json in
     let oc = open_out path in
     output_string oc (pretty ^ "\n");
     close_out oc


.. note::
   - Add command-line flags (--config PATH) to override location
   - Consider adding a small “ocaml-books config init” command that creates default config.json
   - Validate paths exist & are directories when loading (raise friendly error)
   - For production, add basic schema validation or at least required-field checks


Dependencies to add to dune / opam
----------------------------------

::

   (libraries
    …
    yojson
    ppx_deriving_yojson.runtime)

::

   opam install yojson ppx_deriving_yojson

