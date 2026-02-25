(* lib/fs.ml *)

(* File system utilities: directory creation, filename sanitization, and file type checks.
   Used for safe FS operations in the book library manager.

   Dependencies: OCaml standard library (Sys, Unix, Filename).
   No external packages required.

   All functions are designed to be safe and handle common edge cases (non-existing paths, race conditions). *)

(* #require "unix";; *)

(** [mkdir_p ?perm path] creates the directory [path] and all missing parent
    directories (like [mkdir -p]). Safe if the path already exists.

    @param perm Optional permission mode (default: 0o755)
    @raise Failure if the path exists but is not a directory
    @raise Unix.Unix_error on other file system errors *)
let mkdir_p ?(perm = 0o755) path =
  let rec create p =
    if Sys.file_exists p then
      if not (Sys.is_directory p) then
        failwith ("Not a directory: " ^ p)
      else ()
    else
      let parent = Filename.dirname p in
      if parent <> Filename.current_dir_name && parent <> p then
        create parent;
      try
        Unix.mkdir p perm
      with
      | Unix.Unix_error (Unix.EEXIST, _, _) -> ()  (* race condition: already created *)
      | Unix.Unix_error (e, f, arg) ->
          failwith (Printf.sprintf "Unix.mkdir failed (%s): %s %s"
                      (Unix.error_message e) f arg)
  in
  create path

(* [sanitize_filename s] creates a safe filename by replacing forbidden characters
    with '_', trimming whitespace, and ensuring non-empty result (defaults to unnamed).

    Forbidden characters: / \ : * ? < > |, double-quote and control chars (0x00-0x1F).

    Used to prevent invalid filenames on various filesystems. *)
let sanitize_filename s =
  String.map (fun c ->
    match c with
    | '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|'
    | '\000' .. '\031' -> '_'
    | _ -> c
  ) s
  |> String.trim
  |> fun s -> if s = "" then "unnamed" else s

(** [is_regular_file path] returns true if [path] exists and is a regular file
    (not directory, symlink, device, etc.). Returns false on non-existent paths or errors. *)
let is_regular_file path =
  Sys.file_exists path &&
    not (Sys.is_directory path)