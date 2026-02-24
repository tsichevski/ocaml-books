### Goals for `organize` in this iteration

- Read configuration (`library_dir` and `target_dir`)
- Find all regular files in `library_dir` (for now — no recursion, no ZIPs)
- Treat them as FB2 files
- Parse each with `Fb2_parse.parse_title_author`
- Group books by author (simple `Hashtbl.t`)
- For each book:
  - Create subdirectory `target_dir / sanitized_author`
  - Move (or copy in dry-run) the file to `target_dir / author / author - title.fb2`
  - Sanitize filenames (replace forbidden characters)
- Respect `--dry-run` (print actions instead of moving)
- Respect `--verbose` (show more details)
- Print summary at the end

### Required additions

1. Add helper in `lib/fs.ml` (or `lib/utils.ml`) for filename sanitization

```ocaml
(* lib/fs.ml – add this function *)

let sanitize_filename s =
  String.map (fun c ->
    match c with
    | '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|'
    | '\000' .. '\031' -> '_'
    | _ -> c
  ) s
  |> String.trim
  |> fun s -> if s = "" then "unnamed" else s
```

2. Add simple grouping in `lib/organize.ml` (new file)

```ocaml
(* lib/organize.ml *)

open Ocaml_books

module AuthorTbl = Hashtbl.Make(String)

type book = {
  author : string;
  title  : string;
  path   : string;
}

let group_by_author books =
  let tbl = AuthorTbl.create 16 in
  List.iter (fun b ->
    let key = String.lowercase_ascii b.author in
    let existing = AuthorTbl.find_opt tbl key |> Option.value ~default:[] in
    AuthorTbl.replace tbl key (b :: existing)
  ) books;
  tbl
```

3. Update `bin/cli.ml` – replace the placeholder `organize_cmd`

```ocaml
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
             Sys.is_file p &&
             Filename.check_suffix p ".fb2"  (* basic filter – improve later *)
          )
      in

      if verbose then
        Printf.printf "Found %d candidate FB2 files\n" (List.length files);

      let books = ref [] in
      let parse_failures = ref 0 in

      List.iter (fun path ->
        try
          let author, title, _ = Fb2_parse.parse_title_author path in
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

      let tbl = Organize.group_by_author !books in

      AuthorTbl.iter (fun _key books ->
        List.iter (fun b ->
          let author_dir = Filename.concat cfg.target_dir (Fs.sanitize_filename b.author) in
          let dest_name = Printf.sprintf "%s - %s.fb2"
                            (Fs.sanitize_filename b.author)
                            (Fs.sanitize_filename b.title) in
          let dest_path = Filename.concat author_dir dest_name in

          if dry then
            Printf.printf "[dry-run] Would move %s → %s\n" b.path dest_path
          else begin
            if verbose then Printf.printf "Moving %s → %s\n" b.path dest_path;
            Fs.mkdir_p author_dir;
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
```

### Dune update

Add new library file:

```lisp
;; lib/dune
(library
 (name ocaml_books)
 (libraries unix zip xml-light yojson ppx_deriving_yojson.runtime cmdliner)
 (preprocess (pps ppx_deriving_yojson)))
```

### Test after commit & build

```bash
dune build bin/cli.exe
./_build/default/bin/cli.exe organize --verbose
./_build/default/bin/cli.exe organize --dry-run
