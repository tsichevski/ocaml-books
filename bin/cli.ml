(* Command-line interface for the OCaml Books tool.
Uses Cmdliner (2.1.0) for subcommands, flags, automatic help/man-page generation.

Supported subcommands:
- init       create default configuration file
- extract    extract FB2 files from ZIP archive(s)
- group      parse FB2 files and move them into author-named subdirectories
- validate   fully parse all FB2 files as XML
- index      add files to index

Common flags:
--config / -c FILE      custom config file
--dry-run               simulate actions (no file changes)
--max-component-len / -m N   max length of filename/dir components (bytes; 0 = no limit)
--jobs / -j N           max number of domains/threads for parallel work (1 = disable)

Dependencies: cmdliner, bookweald (project library), Moiu *)
open Cmdliner

module Db = Bookweald.Db
module Fs = Bookweald.Fs
module Config = Bookweald.Config
module Logging = Bookweald.Logging
module Unzip = Bookweald.Unzip
module Fb2_parse = Bookweald.Fb2_parse
module Alias = Bookweald.Alias
module Blacklist = Bookweald.Blacklist

module Log = (val Logs.src_log (Logs.Src.create "bookweald" ~doc:"Tool commands") : Logs.LOG)

(** Global config file term *)
let config_term : string option Term.t =
  let doc = "Path to the configuration file. \
  If omitted, defaults to ~/.config/bookweald/config.json." in
  Arg.(value & opt (some string) None &
       info ["c"; "config"] ~docv:"FILE" ~doc)

(** Helper to create a full Cmd.t with global config *)
let make_cmd name doc man action_term =
  let info = Cmd.info name ~doc ~man in
  let full_term =
    Term.(const (fun config action -> (config, action))
          $ config_term
          $ action_term)
  in
  Cmd.v info full_term

let parallel_execute jobs action on_failure files =
  Miou.run ~domains:jobs
    (fun () ->
      let tasks =
        List.map
          (fun path ->
            Miou.call
              (fun () ->
                try
                  action path
                with e ->
                  on_failure e path
              )
          )
          files
      in

      Miou.await_all tasks)

(** Recursively find all regular files with .fb2 extension in a directory
This function is used in several commands. *)
let find_fb2_files dir =
  let rec aux d accu =
    if Fs.is_regular_file d then
      if Filename.check_suffix d ".fb2" then
        d::accu
      else
        accu
    else
      Sys.readdir d
    |> Array.to_list
    |> List.fold_left
      (fun ac p ->
        let path = Filename.concat d p in
        let dir_contents = aux path [] in
        List.append dir_contents ac
      )
      accu in
        
  aux dir []

let connect (cfg : Config.t) as_admin =
  let db = cfg.database in
  let user,password = if as_admin then (db.admin, db.admin_passwd) else (db.user, db.passwd) in
  Db.connect ~host:db.host ~user:user ~password:password ~port:db.port ~dbname:db.name ()

let dry_run =
  let doc = "Do not actually change anything, just show what would happen." in
  Arg.(value & flag & info ["n"; "dry-run"] ~doc)

let source_dir =
  let doc = "Path to the source directory, default is configured library_dir" in
  Arg.(value & opt (some string) None & info ["path"] ~docv:"PATH" ~doc)

let overwrite =
  let doc = "Overwrite existing files without asking." in
  Arg.(value & flag & info ["f"; "force"] ~doc)

let reverse_blacklisted =
  let doc = "Reverse black list: process blacklisted files only." in
  Arg.(value & flag & info ["r"; "reverse"] ~doc)

(** Maximum allowed byte length of any single filename or directory component.
0 = no artificial limit (use OS/filesystem limit) *)
let max_component_len =
  let doc = "Maximum allowed length of any filename or directory component (in bytes). \
  0 = no limit (default: no limit)." in
  Arg.(value & opt int 0 & info ["m"; "max-component-len"] ~docv:"N" ~doc)

(** Maximum number of domains (threads) to use for parallel operations.
Default: recommended count from Domain.recommended_domain_count () *)
let jobs =
  let doc = "Maximum number of domains/threads to use for parallel work. \
  Use 1 to disable parallelism. Default → use recommended count." in
  Arg.(value & opt int (Stdlib.Domain.recommended_domain_count ()) & info ["j"; "jobs"] ~docv:"N" ~doc)

(** Command "init" — creates default configuration file *)
let init_cmd =
  let doc = "Initialize default configuration file" in
  let man = [
    `S Manpage.s_description;
    `P "Creates ~/.config/bookweald/config.json with default values."
  ] in
  let action_term =
    Term.(const (fun dry -> `Init dry) $ dry_run)
  in
  make_cmd "init" doc man action_term

(** Command "schema-init" - (re)initializes DB schema *)
let schema_init_cmd =
  let doc = "Drop DB contents and initialize DB schema" in
  let man = [
    `S Manpage.s_description;
    `P "Initializes DB schema.";
  ] in
  let action_term =
    Term.(const (fun dry -> `SchemaInit dry) $ dry_run)
  in
  make_cmd "schema-init" doc man action_term

(** Extract command *)
let extract_cmd =
  let doc = "Extract from a ZIP archive containing FB2 books." in
  let man = [
    `S Manpage.s_description;
    `P "Extracts all .fb2 files from given ZIP."
  ] in
  let zip_file = Arg.(required & pos 0 (some string) None & info [] ~docv:"ZIPFILE") in

  let action_term =
    Term.(const (fun zip dry overwrite -> `Extract (zip, dry, overwrite))
          $ zip_file
          $ dry_run
          $ overwrite)
  in
  make_cmd "extract" doc man action_term

let group_cmd =
  let doc = "Group books by author (create author sub-directories)." in
  let man = [
    `S Manpage.s_description;
    `P "Scans directory for FB2 files,";
    `P "parses author/title, and moves files to target_dir/author_name/.";
    `P "Uses sanitized filenames: author - title.fb2";
  ] in
  let action_term =
    Term.(const (fun source_dir dry overwrite max_component_len jobs -> `Group (source_dir, dry, overwrite, max_component_len, jobs))
          $ source_dir
          $ dry_run
          $ overwrite
          $ max_component_len
          $ jobs)
  in
  make_cmd "group" doc man action_term

(** Command "validate" — fully parses all FB2 files and register invalid ones to blacklist file *)
let validate_cmd =
  let doc = "Validate all FB2 files in the specified directory for XML conformance" in
  let man = [
    `S Manpage.s_description;
    `P "Fully parses each .fb2 file.";
    `P "Invalid files are appended to invalid_files.";
    `P "Respects --reverse (validate blacklisted files only).";
    `P "Respects --dry-run (only prints actions).";
  ] in
  let action_term =
    Term.(const (fun source_dir dry reverse jobs -> `Validate (source_dir, dry, reverse, jobs))
          $ source_dir
          $ dry_run
          $ reverse_blacklisted
          $ jobs)
  in
  make_cmd "validate" doc man action_term

(** Command "index" — parses all FB2 files and adds them to index *)
let index_cmd =
  let doc = "Parse all FB2 files in the specified directory and add them to index" in
  let man = [
    `S Manpage.s_description;
    `P "Index each .fb2 file.";
    `P "Respects --dry-run (only logs actions).";
  ] in
  let action_term =
    Term.(const (fun source_dir dry overwrite jobs -> `Index (source_dir, dry, overwrite, jobs))
          $ source_dir
          $ dry_run
          $ overwrite
          $ jobs)
  in
  make_cmd "index" doc man action_term

(** Main entry point *)
let main () =
  let lock = Mutex.create () in
  let lock () = Mutex.lock lock and unlock () = Mutex.unlock lock in
  Logs.set_reporter_mutex ~lock ~unlock;
  
  let info =
    Cmd.info "books"
      ~version:"0.1.0"
      ~doc:"Home Book Library manager written in OCaml"
      ~man:[
        `S Manpage.s_common_options;
        `P "The only common option is --config / -c.";
      ]
  in

  (* Default term when no sub-command is given *)
  let default_term =
    Term.(const (fun config -> (config, `Help)) $ config_term)
  in

  let subcommands = [
    init_cmd;
    schema_init_cmd;
    extract_cmd;
    validate_cmd;
    group_cmd;
    index_cmd;
  ] in

  let tool = Cmd.group ~default:default_term info subcommands in

  match Cmd.eval_value tool with
  | Ok (`Ok (config_file, action)) ->
    (* Global setup *)
    let config_path = match config_file with
    | Some p -> p
    | None ->
      let home = Sys.getenv "HOME" in
      Filename.concat (Filename.concat home ".config") "bookweald/config.json"
    in    
    Log.debug (fun m -> m "Loading configuration from %s" config_path);
    let cfg =
      if Sys.file_exists config_path then
        Config.load config_path
      else
        Config.default () in
        
    ignore(match cfg.log_file with
    | None -> Logs.set_reporter (Logs.format_reporter ())
    | Some p -> Logging.setup cfg.drop_existing_log_file_on_start p);
    
    Logs.set_level (match cfg.log_level with
    | None -> (Some Logs.Info)
    | Some name -> 
      match Logs.level_of_string name with
      | Ok l -> l
      | Error (`Msg msg) -> failwith msg);

    (* Dispatch action *)
    begin
      match action with
      | `Extract (zip, dry_run, overwrite) ->
        let dry_run = dry_run || cfg.dry_run in
        if dry_run then
          Log.info (fun m -> m "[dry-run] Would extract from %s to %s" zip cfg.library_dir)
        else begin
          Log.info (fun m -> m "Extract %s (dry-run=%b, overwrite=%b)" zip dry_run overwrite);
          match Unzip.extract_fb2_files ~overwrite zip cfg.library_dir with
          | Ok extracted ->
            Log.info (fun m -> m "Extracted %d FB2 files" (List.length extracted));
            exit 0
          | Error msg ->
            Log.err (fun m -> m "Extraction failed: %s" msg);
            exit 1
        end
      
      | `Init dry_run ->
        begin
          let dry_run = dry_run || cfg.dry_run in
          if dry_run then begin
            Log.info (fun m -> m "[dry-run] Would create default config");
            exit 0
          end else
            let path = Filename.concat (Sys.getenv "HOME") ".config/bookweald/config.json" in
            try
              Config.create_default path;
              Log.info (fun m -> m "Created config: %s" path);
              exit 0
            with e ->
              Log.err (fun m -> m "Failed to create config: %s" (Printexc.to_string e));
              exit 1
        end
        
      | `Group (source_dir, dry_run, overwrite, max_component_len, jobs) ->
        let dry_run = dry_run || cfg.dry_run in
        let source_dir = match source_dir with Some p -> p | None -> cfg.library_dir in

        let aliases = match cfg.alias_file with
        | None -> None
        | Some path -> Some (Alias.load_aliases path)
        in
        
        let max_component_len = if max_component_len = 0 then cfg.max_component_len else max_component_len in
        Log.info (fun m -> m "Grouping books by author ...\nSource %s\nOrganize mode (max component length = %d bytes)\n Source: %s\n Target: %s"
          source_dir
          max_component_len
          source_dir
          cfg.target_dir);
        if dry_run then Log.info (fun m -> m " [dry-run] No files will be moved");

        let fb2_files = find_fb2_files source_dir in
        let total = List.length fb2_files in
        Log.info (fun m -> m "Found %d candidate FB2 files" total);

        let failures = ref 0 in
        ignore(parallel_execute jobs
          (fun path ->
            let book = Fb2_parse.parse_book_info path aliases in
            let author =
              match book.authors with
              | [] -> "UnknownAuthor"
              | { first_name; middle_name; last_name; _} :: _ ->
                match List.filter_map Fun.id [first_name; middle_name; last_name] with
                | [] -> "UnknownAuthor"
                | parts -> String.concat " " parts
            in
            let title = book.title in
            let author_dir = Filename.concat cfg.target_dir (Fs.sanitize_filename author max_component_len) in
            let dest_name = Printf.sprintf "%s.fb2" (Fs.sanitize_filename title max_component_len) in
            let dest_path = Filename.concat author_dir dest_name in

            if not (path = dest_path) then
              if dry_run then
                Log.debug (fun m -> m "[dry-run] Would move %s → %s" path dest_path)
              else begin
                Log.debug (fun m -> m "Moving %s → %s" path dest_path);
                Fs.mkdir_p author_dir;
                Sys.rename path dest_path
              end;
          )
          (fun e path ->
            incr failures;
            let reason = Printexc.to_string e in
            Log.warn (fun m -> m "%s → FAILED: %s" (Filename.basename path) reason);
        
            if not dry_run then begin
              let dest_name = Filename.basename path in
              let dest_path = Filename.concat cfg.invalid_dir dest_name in
              Fs.mkdir_p cfg.invalid_dir;
              Sys.rename path dest_path;
              Log.debug (fun m -> m " → Moved %s to %s" path dest_path);
            end;
          )
          fb2_files);

        if !failures > 0 then
          Log.info (fun m -> m "Organization complete: %d/%d files failed" !failures total)
        else
          Log.info (fun m -> m  "All %d files groupd successfully" total);
        exit 0

      | `SchemaInit dry_run ->
        let dry_run = dry_run || cfg.dry_run in
        if not dry_run then
          begin
            try
              Log.info (fun m -> m "Initialize DB schema");
              let admconn = connect cfg true in
              Db.drop_schema admconn;
              Db.init_schema admconn;
              Db.close admconn;
            with e ->
              let msg =
                match e with
                | Postgresql.Error pe -> Postgresql.string_of_error pe
                | _ -> Printexc.to_string e in
              Log.err (fun m -> m "Schema init failed with: %s" msg);
              exit 0
          end
        
      | `Validate (source_dir, dry_run, reverse, jobs) ->
        begin
          let dry_run = dry_run || cfg.dry_run
          and source_dir = match source_dir with Some p -> p | None -> cfg.library_dir
          and blacklist = cfg.blacklist in
        
          Log.info (fun m -> m "Validate mode\n Scanning: %s\n jobs: %d" source_dir jobs);

          let in_blacklist =
            match blacklist with
            | None ->
              Log.info (fun m -> m "No black list file will be used");
              (fun _ -> true)
              
            | Some path ->
              Log.info (fun m -> m "Black list file: %s, reverse action: %b" path reverse);
              let table = Blacklist.load path in
              let length = Hashtbl.length table in
              if length > 0 then
                Log.info (fun m -> m "Blacklist table has %d unique filenames" length);
              
              (fun path -> (Hashtbl.mem table (Filename.basename path)))
          in
        
          let fb2_files = find_fb2_files source_dir in
          
          let black, not_black = List.partition in_blacklist fb2_files in
    
          let blacklisted_length = List.length black in
          let to_process = if reverse then black else not_black in
          Log.info (fun m -> m "fb2 files found: %d total, %d blacklisted, %d to process."
            (List.length fb2_files)            
            blacklisted_length
            (List.length to_process));
    
          let failures = ref 0 in
          ignore(parallel_execute jobs
            (fun path ->
              Fb2_parse.validate path;
              Log.debug (fun m -> m "%s → OK" (Filename.basename path));
            )
            (fun e path ->
              incr failures;
              let reason = Printexc.to_string e in
              let basename = Filename.basename path in
              Log.warn (fun m -> m "%s → FAILED: %s" basename reason);
              if not dry_run then
                match blacklist with
                | None -> ()
                | Some file ->
                  if not (in_blacklist basename) then
                    begin
                      Log.info (fun m -> m "Adding to blacklist %s" basename);
                      Blacklist.append file path reason
                    end
            )
            to_process);
      
          if !failures > 0 then
            Log.warn (fun m -> m "Validation complete: %d/%d files failed" !failures blacklisted_length)
          else
            Log.info (fun m -> m "All %d files validated successfully" blacklisted_length);
          
          exit 0
        end
        
      | `Index (source_dir, dry_run, overwrite, jobs) ->
        let dry_run = dry_run || cfg.dry_run in
        let source_dir = match source_dir with Some p -> p | None -> cfg.library_dir in
        Log.info (fun m -> m "Index mode\n Scanning: %s\n Requested jobs: %d"
          source_dir
          jobs);
        if dry_run then Log.info (fun m -> m " [dry-run] No files will be indexed");

        let fb2_files = find_fb2_files source_dir in
    
        let total = List.length fb2_files in
        Log.info (fun m -> m "Found %d .fb2 files" total);
    
        let failures = ref 0 in
        let c = connect cfg false in

        let aliases = match cfg.alias_file with
        | None -> None
        | Some path -> Some (Alias.load_aliases path)
        in

        let result = parallel_execute jobs
          (fun path ->
            let book = Fb2_parse.parse_book_info path aliases in
            let id = Db.find_or_insert_book c book in
            Log.debug (fun m -> m "%s → OK" (Filename.basename path));
            id
          )
          (fun e path ->
            incr failures;
            let reason =
              match e with
              | Postgresql.Error pe -> Postgresql.string_of_error pe
              | _ -> Printexc.to_string e in

            Log.warn (fun m -> m "%s → FAILED: %s" (Filename.basename path) reason);
            raise e
          )
          fb2_files
        in
        List.iter (function
          | Ok id ->
            Log.debug (fun m -> m "Ok: %s" id)
          | Error _ -> ())
          result
        ;
        if !failures > 0 then
          Log.info (fun m -> m "Indexing complete: %d/%d files failed" !failures total)
        else
          Log.info (fun m -> m "All %d files indexed successfully" total);
        exit 0

      | `Help       -> ()
    end

  | Ok (`Version | `Help) -> exit 0
  | Error _ -> exit 1

let () = main ()