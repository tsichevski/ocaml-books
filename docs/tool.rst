======================
Command-Line Interface
======================

.. contents::
   :depth: 2
   :local:


Goals for CLI
-------------

Provide simple, usable command-line interface with the following subcommands:

- ``init``          — create default configuration file
- ``import``        — process one ZIP file or directory with ZIPs
- ``organize``      — parse + group + move files to author subdirectories
- ``help`` / ``--help`` — show usage

Minimal dependencies → use only standard library module ``Arg`` (no cmdliner yet).

This keeps the project lightweight while still providing basic usability.

Project structure update
------------------------

Add new file:

::

  bin/cli.ml               # main entry point with command-line parsing

Update ``bin/dune``:

::

   (executable
    (name cli)
    (public_name ocaml-books)   ; ← binary name when installed
    (libraries ocaml_books unix))

Basic CLI implementation (bin/cli.ml)
-------------------------------------

::

   open Ocaml_books

   let usage_msg = "ocaml-books [command] [options]\n\
                    Commands:\n\
                    \  init          Create default configuration file\n\
                    \  import <path> Process ZIP file or directory\n\
                    \  organize      Parse and organize extracted books\n\
                    \n\
                    Use --help for more information.\n"

   let anon_fun _ = failwith "Unexpected anonymous argument"

   let config_path = ref None
   let zip_path    = ref None
   let target_dir  = ref None
   let dry_run     = ref false

   let speclist = Arg.align [
     "--config", Arg.String (fun s -> config_path := Some s),
       "PATH      Use custom config file instead of default locations";
     "--dry-run", Arg.Set dry_run,
       "           Simulate actions without moving files";
     "--target", Arg.String (fun s -> target_dir := Some s),
       "DIR        Override target directory from config";
   ]

   let parse_command () =
     if Array.length Sys.argv < 2 then begin
       Arg.usage speclist usage_msg;
       exit 1
     end;

     let cmd = Sys.argv.(1) in

     match cmd with
     | "init" ->
         let path = Filename.concat (Sys.getenv "HOME") ".config/ocaml-books/config.json" in
         (try Config.create_default path
          with e -> Printf.eprintf "Failed to create config: %s\n" (Printexc.to_string e))
     | "import" ->
         if Array.length Sys.argv < 3 then begin
           Printf.eprintf "Error: import requires a ZIP file or directory path\n";
           exit 1
         end;
         zip_path := Some Sys.argv.(2);
         Arg.parse speclist anon_fun usage_msg;
         (* TODO: call import logic *)
         Printf.printf "Import from: %s (dry-run: %b)\n"
           (Option.value !zip_path ~default:"(none)") !dry_run
     | "organize" ->
         Arg.parse speclist anon_fun usage_msg;
         let cfg = Config.load () in
         Printf.printf "Organizing from %s to %s (dry-run: %b)\n"
           cfg.library_dir cfg.target_dir !dry_run;
         (* TODO: scan library_dir, extract, parse, move *)
         ()
     | "--help" | "-h" ->
         Arg.usage speclist usage_msg;
         exit 0
     | unknown ->
         Printf.eprintf "Unknown command: %s\n" unknown;
         Arg.usage speclist usage_msg;
         exit 1


   let () =
     try parse_command ()
     with
     | Arg.Bad msg ->
         Printf.eprintf "Error: %s\n" msg;
         Arg.usage speclist usage_msg;
         exit 1
     | Arg.Help msg ->
         print_string msg;
         exit 0
     | e ->
         Printf.eprintf "Unexpected error: %s\n" (Printexc.to_string e);
         exit 1


Next implementation steps (recommended order)
---------------------------------------------

1. **Add real import logic**  
   Scan path (file or directory), call ``Unzip.extract_fb2_files`` for each ZIP

2. **Implement organize subcommand**  
   - Scan ``library_dir`` for extracted .fb2 files (or freshly extracted ones)  
   - Parse each with ``Fb2_parse.parse_book_info``  
   - Group by author (Hashtbl or Map)  
   - Move/copy to ``target_dir/author_name/``

3. **Add --verbose / --quiet flags**  
   Control printing level

4. **Consider switching to cmdliner** later  
   When we need subcommands with proper help, positional arguments, etc.

Minimal working version (current + import stub)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   (* inside "import" branch *)
   match !zip_path with
   | None ->
       Printf.eprintf "Error: no path provided for import\n";
       exit 1
   | Some p ->
       let cfg = Config.load () in
       if Sys.is_directory p then
         Printf.printf "Would scan directory %s for ZIPs (not implemented yet)\n" p
       else
         let extracted = Unzip.extract_fb2_files p cfg.library_dir in
         Printf.printf "Extracted %d FB2 files from %s\n" (List.length extracted) p


Would you like to:

- implement full ``import`` command (single ZIP + directory scanning)?
- start the ``organize`` command (group + move)?
- add validation for directories in config loading?
- or something else?

