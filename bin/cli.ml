(* Command-line interface for the OCaml Books tool.
   Uses Cmdliner (2.1.0) for subcommands, flags, automatic help/man-page generation.

   Supported subcommands:
   - init       create default configuration file
   - import     extract FB2 files from ZIP archive(s)
   - organize   parse FB2 files and move them into author-named subdirectories
   - validate   fully parse all FB2 files and move invalid ones to invalid_dir

   Common flags:
   --verbose / -v          increase verbosity
   --config / -c FILE      custom config file
   --dry-run               simulate actions (no file changes)
   --max-component-len / -m N   max length of filename/dir components (bytes; 0 = no limit)
   --jobs / -j N           max number of domains/threads for parallel work (1 = disable)

   Dependencies: cmdliner, ocaml_books (project library), Moiu *)

open Cmdliner
open Miou
open Ocaml_books.Config
open Ocaml_books.Unzip
open Ocaml_books.Book
open Ocaml_books.Fs

(* ────────────────────────────────────────────── *)
(* Common options ───────────────────────────────── *)

(** Flag to increase verbosity (show more progress and debug messages) *)
let verbose =
  let doc = "Increase verbosity (show more details during operations)" in
  Arg.(value & flag & info ["v"; "verbose"] ~doc)

(** Optional path to custom configuration file *)
let config_opt =
  let doc = "Path to configuration file (default: ~/.config/ocaml-books/config.json)" in
  Arg.(value & opt (some string) None & info ["c"; "config"] ~docv:"FILE" ~doc)

(** Flag to simulate actions without modifying the file system *)
let dry_run =
  let doc = "Do not perform any real file operations (simulation mode)" in
  Arg.(value & flag & info ["dry-run"] ~doc)

(** Maximum allowed byte length of any single filename or directory component.
    0 = no artificial limit (use OS/filesystem limit) *)
let max_component_len =
  let doc = "Maximum allowed length of any filename or directory component (in bytes). \
             0 = no limit (default, use OS limit)." in
  Arg.(value & opt int 0 & info ["m"; "max-component-len"] ~docv:"N" ~doc)

(** Maximum number of domains (threads) to use for parallel operations.
    Default: recommended count from Domain.recommended_domain_count () *)
let jobs =
  let doc = "Maximum number of domains/threads to use for parallel work. \
             Use 1 to disable parallelism. Default → use recommended count." in
  Arg.(value & opt int (Stdlib.Domain.recommended_domain_count ()) & info ["j"; "jobs"] ~docv:"N" ~doc)

(** Combination of common options passed to every command *)
let common_opts =
  Term.(const (fun v c d m j -> (v, c, d, m, j))
        $ verbose $ config_opt $ dry_run $ max_component_len $ jobs)


(* ────────────────────────────────────────────── *)
(* Helper: load config with fallback & verbose log *)

let load_config verbose custom_path =
  match custom_path with
  | Some p when not (Sys.file_exists p) ->
      if verbose then Printf.eprintf "Custom config %s not found, using defaults\n%!" p;
      Ocaml_books.Config.default ()
  | Some p ->
      if verbose then Printf.printf "Loading config from: %s\n%!" p;
      Ocaml_books.Config.load () (* TODO: add ~path support later if needed *)
  | None ->
      if verbose then Printf.printf "Loading config from default locations\n%!";
      Ocaml_books.Config.load ()


(* ────────────────────────────────────────────── *)
(* init command *)

(** Command "init" — creates default configuration file *)
let init_cmd =
  let doc = "Initialize default configuration file" in
  let man = [
    `S Manpage.s_description;
    `P "Creates ~/.config/ocaml-books/config.json with default values."
  ] in
  let info =
    Cmd.info "init"
      ~doc
      ~man
      ~exits:Cmd.Exit.defaults
  in
  Cmd.v info Term.(const (fun (v, c, d, m, j) ->
    if d then begin
      Printf.printf "[dry-run] Would create default config\n%!";
      0
    end else
      let cfg = load_config v c in
      let verbose = v || cfg.verbose in
      let path = Filename.concat (Sys.getenv "HOME") ".config/ocaml-books/config.json" in
      try
        Ocaml_books.Config.create_default path;
        if verbose then Printf.printf "Created config: %s\n%!" path;
        0
      with e ->
        Printf.eprintf "Failed to create config: %s\n%!" (Printexc.to_string e);
        1
  ) $ common_opts)


(* ────────────────────────────────────────────── *)
(* import command *)

(** Positional argument for import: path to ZIP file or directory *)
let zip_path_arg =
  let doc = "Path to ZIP file or directory containing ZIP archives" in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"PATH" ~doc)

(** Command "import" — extracts FB2 files from ZIP archive(s) *)
let import_cmd =
  let doc = "Extract FB2 files from ZIP archive(s)" in
  let man = [
    `S Manpage.s_description;
    `P "Extracts all .fb2 files from given ZIP or scans directory for ZIPs."
  ] in
  let info =
    Cmd.info "import"
      ~doc
      ~man
      ~exits:Cmd.Exit.defaults
  in
  Cmd.v info Term.(const (fun (v, c, d, m, j) path ->
    let cfg = load_config v c in
    let verbose = v || cfg.verbose in

    if d then begin
      Printf.printf "[dry-run] Would extract from %s to %s\n%!" path cfg.library_dir;
      0
    end else
      match Ocaml_books.Unzip.extract_fb2_files path cfg.library_dir with
      | Ok extracted ->
         if verbose then
           Printf.printf "Extracted %d FB2 files\n%!" (List.length extracted);
         0
      | Error msg ->
         Printf.eprintf "Extraction failed: %s\n%!" msg;
         1
  ) $ common_opts $ zip_path_arg)


(* ────────────────────────────────────────────── *)
(* organize command *)

(** Command "organize" — parses and moves FB2 files into author-named subdirectories *)
let organize_cmd =
  let doc = "Parse FB2 files and move them into author-named subdirectories" in
  let man = [
    `S Manpage.s_description;
    `P "Scans library_dir for FB2 files,";
    `P "parses author/title, and moves files to target_dir/author_name/.";
    `P "Uses sanitized filenames: author - title.fb2";
  ] in
  let info =
    Cmd.info "organize"
      ~doc
      ~man
      ~exits:Cmd.Exit.defaults
  in
  Cmd.v info Term.(const (fun (v, custom_path, dry, max_component_len, jobs) ->
    let cfg = load_config v custom_path in
    let verbose = v || cfg.verbose in
    let max_component_len = if max_component_len = 0 then cfg.max_component_len else max_component_len in
    if verbose then begin
      Printf.printf "Organize mode (max component length = %d bytes)\n%!" max_component_len;
      Printf.printf " Source: %s\n" cfg.library_dir;
      Printf.printf " Target: %s\n%!" cfg.target_dir;
      if dry then Printf.printf " [dry-run] No files will be moved\n%!";
    end;

    try
      if not (Sys.is_directory cfg.library_dir) then
        failwith (Printf.sprintf "Not a directory: %s" cfg.library_dir);

      let files =
        Sys.readdir cfg.library_dir
        |> Array.to_list
        |> List.map (Filename.concat cfg.library_dir)
        |> List.filter (fun p ->
             Ocaml_books.Fs.is_regular_file p &&
             Filename.check_suffix p ".fb2" (* basic filter – improve later *)
          )
      in

      if verbose then
        Printf.printf "Found %d candidate FB2 files\n%!" (List.length files);

      List.iter
        (fun path ->
          if verbose then Printf.printf "Parsing: %s\n%!" path;
          let book = Ocaml_books.Fb2_parse.parse_book_info path in
          let author =
            match book.authors with
            | [] -> "UnknownAuthor"
            | { first_name; middle_name; last_name; _} :: _ ->
              match List.filter_map Fun.id [first_name; middle_name; last_name] with
              | [] -> "UnknownAuthor"
              | parts -> String.concat " " parts
          in
          let title = Option.value ~default:"UnknownTitle" book.title in
          let author_dir = Filename.concat cfg.target_dir (Ocaml_books.Fs.sanitize_filename author max_component_len) in
          let dest_name = Printf.sprintf "%s.fb2" (Ocaml_books.Fs.sanitize_filename title max_component_len) in
          let dest_path = Filename.concat author_dir dest_name in

          if dry then
            Printf.printf "[dry-run] Would move %s → %s\n%!" path dest_path
          else begin
            if verbose then Printf.printf "Moving %s → %s\n%!" path dest_path;
            Ocaml_books.Fs.mkdir_p author_dir;
            Sys.rename path dest_path
          end
        ) files;

      Printf.printf "Organized %d books\n%!" (List.length files);
      0

    with e ->
      Printf.eprintf "Organize failed: %s\n%!" (Printexc.to_string e);
      1
  ) $ common_opts)

(* ────────────────────────────────────────────── *)
(* validate command *)

(** Command "validate" — fully parses all FB2 files and moves invalid ones to invalid_dir *)
let validate_cmd =
  let doc = "Validate all FB2 files in library_dir for XML and basic FB2 conformance" in
  let man = [
    `S Manpage.s_description;
    `P "Fully parses each .fb2 file.";
    `P "Files that fail validation are moved to invalid_dir.";
    `P "Respects --dry-run (only prints actions).";
  ] in
  let info = Cmd.info "validate" ~doc ~man ~exits:Cmd.Exit.defaults in

  Cmd.v info Term.(const (fun (v, custom_path, dry, max_component_len, jobs) ->
    let cfg = load_config v custom_path in
    let verbose = v || cfg.verbose in
    (* jobs is kept for compatibility, but Miou ignores explicit count in most cases *)
    if verbose then begin
      Printf.printf "Validate mode (using Miou concurrency)\n";
      Printf.printf " Scanning: %s\n" cfg.library_dir;
      Printf.printf " Failed files go to: %s\n" cfg.invalid_dir;
      Printf.printf " Requested jobs: %d (Miou manages scheduling)\n%!" jobs;
      if dry then Printf.printf " [dry-run] No files will be moved\n%!";
    end;

    try
      let fb2_files = ref [] in
      let rec scan dir =
        let entries = Sys.readdir dir in
        Array.iter (fun name ->
          let path = Filename.concat dir name in
          if Sys.is_directory path then
            scan path
          else if Ocaml_books.Fs.is_regular_file path && Filename.check_suffix path ".fb2" then
            fb2_files := path :: !fb2_files
        ) entries
      in
      scan cfg.library_dir;

      let total = List.length !fb2_files in
      if verbose then begin
        Printf.printf "Found %d .fb2 files\n%!" total;
      end;

  Miou.run
    ~domains:jobs
    (fun () ->
      let failures = ref 0 in

        (* Create one lightweight fiber per file *)
        let tasks =
          List.map (fun path ->
            call (fun () ->
              try
                Ocaml_books.Fb2_parse.validate path;
                if verbose then begin
                  Printf.printf "%s → OK\n%!" (Filename.basename path);
                end;
                `Ok
              with e ->
                incr failures;
                let reason = Printexc.to_string e in
                Printf.eprintf "%s → FAILED: %s\n%!" (Filename.basename path) reason;
              
                if not dry then begin
                  let dest_name = Filename.basename path in
                  let dest_path = Filename.concat cfg.invalid_dir dest_name in
                  Ocaml_books.Fs.mkdir_p cfg.invalid_dir;
                  Sys.rename path dest_path;
                  if verbose then begin
                    Printf.printf " → Moved %s to %s\n%!" path dest_path;
                  end
                end;
                `Failed reason
            )
          ) !fb2_files
        in

        (* Wait for all validations to complete *)
        ignore (await_all tasks);

        if !failures > 0 then
          Printf.printf "Validation complete: %d/%d files failed\n%!" !failures total
        else
          Printf.printf "All %d files validated successfully\n%!" total;
    
        0
    )
    with e ->
      Printf.eprintf "Validation failed: %s\n%!" (Printexc.to_string e);
      1
  ) $ common_opts)

(* ────────────────────────────────────────────── *)
(* Main program *)

(** Entry point of the CLI application.
    Builds the command group and evaluates it using Cmdliner. *)
let main () =
  let doc = "Tool for managing and organizing personal FB2 book collection" in
  let sdocs = Manpage.s_common_options in
  let man = [
    `S Manpage.s_description;
    `P "Extracts, parses and organizes FB2 books from ZIP archives by author.";
    `S Manpage.s_examples;
    `P "ocaml-books init";
    `P "ocaml-books import library.zip --verbose --dry-run";
    `P "ocaml-books organize";
    `P "ocaml-books validate";
  ] in
  let main_info =
    Cmd.info "ocaml-books"
      ~version:"0.1.0"
      ~doc
      ~sdocs
      ~man
      ~exits:Cmd.Exit.defaults
  in
  let cmd = Cmd.group main_info @@ [init_cmd; import_cmd; organize_cmd; validate_cmd] in
  Cmd.eval' cmd

let () = if !Sys.interactive then () else exit (main ())