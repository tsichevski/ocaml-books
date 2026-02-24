(* #require "cmdliner";; *)

open Cmdliner
open Ocaml_books.Config
open Ocaml_books.Organize

(* ────────────────────────────────────────────── *)
(* Common options ───────────────────────────────── *)

let verbose =
  let doc = "Increase verbosity (show more details during operations)" in
  Arg.(value & flag & info ["v"; "verbose"] ~doc)

let config_opt =
  let doc = "Path to configuration file (default: ~/.config/ocaml-books/config.json)" in
  Arg.(value & opt (some string) None & info ["c"; "config"] ~docv:"FILE" ~doc)

let dry_run =
  let doc = "Do not perform any real file operations (simulation mode)" in
  Arg.(value & flag & info ["dry-run"] ~doc)

let common_opts =
  Term.(const (fun v c d -> (v, c, d))
        $ verbose $ config_opt $ dry_run)


(* ────────────────────────────────────────────── *)
(* Helper: load config with fallback & verbose log *)

let load_config verbose custom_path =
  match custom_path with
  | Some p when not (Sys.file_exists p) ->
      if verbose then Printf.eprintf "Custom config %s not found, using defaults\n" p;
      Ocaml_books.Config.default ()
  | Some p ->
      if verbose then Printf.printf "Loading config from: %s\n" p;
      Ocaml_books.Config.load ()  (* add ~path support later if needed *)
  | None ->
      if verbose then Printf.printf "Loading config from default locations\n";
      Ocaml_books.Config.load ()


(* ────────────────────────────────────────────── *)
(* init command *)

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
  Cmd.make info Term.(const (fun (v, c, d) ->
    if d then begin
      Printf.printf "[dry-run] Would create default config\n";
      0
    end else
      let path = Filename.concat (Sys.getenv "HOME") ".config/ocaml-books/config.json" in
      try
        Ocaml_books.Config.create_default path;
        if v then Printf.printf "Created config: %s\n" path;
        0
      with e ->
        Printf.eprintf "Failed to create config: %s\n" (Printexc.to_string e);
        1
  ) $ common_opts)


(* ────────────────────────────────────────────── *)
(* import command *)

let zip_path_arg =
  let doc = "Path to ZIP file or directory containing ZIP archives" in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"PATH" ~doc)

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
  Cmd.v info Term.(const (fun (v, c, d) path ->
    let cfg = load_config v c in
    if d then begin
      Printf.printf "[dry-run] Would extract from %s to %s\n" path cfg.library_dir;
      0
    end else
      try
        if v then Printf.printf "Extracting from %s to %s\n" path cfg.library_dir;
        let extracted = Ocaml_books.Unzip.extract_fb2_files path cfg.library_dir in
        if v then Printf.printf "Extracted %d FB2 files\n" (List.length extracted);
        0
      with e ->
        Printf.eprintf "Extraction failed: %s\n" (Printexc.to_string e);
        1
  ) $ common_opts $ zip_path_arg)


(* ────────────────────────────────────────────── *)
(* organize command *)

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
  Cmd.v info Term.(const (fun (verbose, custom_path, dry) ->
    let cfg = load_config verbose custom_path in

    if verbose then begin
      Printf.printf "Organize mode\n";
      Printf.printf "  Source: %s\n" cfg.library_dir;
      Printf.printf "  Target: %s\n" cfg.target_dir;
      if dry then Printf.printf "  [dry-run] No files will be moved\n";
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
             Filename.check_suffix p ".fb2"  (* basic filter – improve later *)
          )
      in

      if verbose then
        Printf.printf "Found %d candidate FB2 files\n" (List.length files);

      let books = ref [] in
      let parse_failures = ref 0 in

      List.iter (fun path ->
        try
          let author, title, _ = Ocaml_books.Fb2_parse.parse_title_author path in
          books := { author; title; path } :: !books;
          if verbose then
            Printf.printf "Parsed: %s → %s\n" author title
        with e ->
          incr parse_failures;
          if verbose then
            Printf.eprintf "Parse failed: %s → %s\n" path (Printexc.to_string e)
      ) files;

      if !parse_failures > 0 then
        Printf.eprintf "Warning: %d files failed to parse\n" !parse_failures;

      let tbl = Ocaml_books.Organize.group_by_author !books in

      AuthorTbl.iter (fun _key books ->
        List.iter (fun b ->
          let author_dir = Filename.concat cfg.target_dir (Ocaml_books.Fs.sanitize_filename b.author) in
          let dest_name = Printf.sprintf "%s - %s.fb2"
                            (Ocaml_books.Fs.sanitize_filename b.author)
                            (Ocaml_books.Fs.sanitize_filename b.title) in
          let dest_path = Filename.concat author_dir dest_name in

          if dry then
            Printf.printf "[dry-run] Would move %s → %s\n" b.path dest_path
          else begin
            if verbose then Printf.printf "Moving %s → %s\n" b.path dest_path;
            Ocaml_books.Fs.mkdir_p author_dir;
            Sys.rename b.path dest_path
          end
        ) books
      ) tbl;

      Printf.printf "Organized %d books\n" (List.length !books);
      0

    with e ->
      Printf.eprintf "Organize failed: %s\n" (Printexc.to_string e);
      1
  ) $ common_opts)

(* ────────────────────────────────────────────── *)
(* Main program *)

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
  ] in
  let main_info =
    Cmd.info "ocaml-books"
      ~version:"0.1.0"
      ~doc
      ~sdocs
      ~man
      ~exits:Cmd.Exit.defaults
  in
  let cmd = Cmd.group main_info @@ [init_cmd; import_cmd; organize_cmd] in
  Cmd.eval' cmd

let () = if !Sys.interactive then () else exit (main ())