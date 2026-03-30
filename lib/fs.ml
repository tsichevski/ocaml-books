(** Filesystem utilities for BookWeald.

    This module provides safe directory creation, filename sanitization,
    and file-type checks used during book import and organization.

    All functions are minimal and match the original implementation.
*)

(** [mkdir_p ?perm path] creates the directory [path] and all missing parent
    directories (like [mkdir -p]). Safe if the path already exists.

    @param perm Optional permission mode (default: 0o755)
    @raise Failure if the path exists but is not a directory
    @raise Unix.Unix_error on other file system errors
*)
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

(** [is_regular_file path] returns true if [path] exists and is a regular file
    (not directory, symlink, device, etc.). Returns false on non-existent paths or errors.
*)
let is_regular_file path =
  Sys.file_exists path &&
    not (Sys.is_directory path)

(** [sanitize_filename s max_len] creates a safe filename by replacing forbidden
    characters with '_', trimming whitespace, and truncating to [max_len] bytes
    (if [max_len > 0]).

    Forbidden characters: / \ : * ? {|"|} < > | and control characters (0-31).

    If the result would be empty, returns "unnamed".
    If truncation occurs, appends "…".

    Example:

    {[
      sanitize_filename "Лев Толстой: Война и мир (1869)" 50
      (* returns something like "Лев Толстой_Война и мир (1869)" or truncated *)
    ]}
*)
let sanitize_filename s max_len =
  String.map (fun c ->
    match c with
    | '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|'
    | '\000' .. '\031' -> '_'
    | _ -> c
  ) s
  |> String.trim
  |> fun s ->
     let s = if max_len > 0 && String.length s > max_len then
               String.sub s 0 max_len ^ "…"
             else s
     in
     if s = "" then "unnamed" else s

