(* #require "cmdliner";; *)
(* bin/cli.ml *)

open Cmdliner
open Ocaml_books

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
      Config.default ()
  | Some p ->
      if verbose then Printf.printf "Loading config from: %s\n" p;
      Config.load ()  (* add ~path support later if needed *)
  | None ->
      if verbose then Printf.printf "Loading config from default locations\n";
      Config.load ()


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
      ~exits:Cmd.Exit.defaults          (* ← modern replacement *)
  in
  Cmd.v info Term.(const (fun (v, c, d) ->
    if d then begin
      Printf.printf "[dry-run] Would create default config\n";
      0
    end else
      let path = Filename.concat (Sys.getenv "HOME") ".config/ocaml-books/config.json" in
      try
        Config.create_default path;
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
        let extracted = Unzip.extract_fb2_files path cfg.library_dir in
        if v then Printf.printf "Extracted %d FB2 files\n" (List.length extracted);
        0
      with e ->
        Printf.eprintf "Extraction failed: %s\n" (Printexc.to_string e);
        1
  ) $ common_opts $ zip_path_arg)


(* ────────────────────────────────────────────── *)
(* organize command – placeholder *)

let organize_cmd =
  let doc = "Parse books and organize them into author directories" in
  let info =
    Cmd.info "organize"
      ~doc
      ~exits:Cmd.Exit.defaults
  in
  Cmd.v info Term.(const (fun (v, c, d) ->
    let cfg = load_config v c in
    Printf.printf "Organize (dry-run=%b, verbose=%b) from %s to %s\n"
      d v cfg.library_dir cfg.target_dir;
    (* TODO: real logic – scan, parse, group, move *)
    0
  ) $ common_opts)


(* ────────────────────────────────────────────── *)
(* Main program *)

let () =
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
  let cmd = Cmd.group main_info [init_cmd; import_cmd; organize_cmd] in
  exit (Cmd.eval cmd)
