(* #require "unix";; *)
(** [mkdir_p ?perm path] creates the directory [path] and all missing parent
    directories (like [mkdir -p]). Safe if the path already exists. *)
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

let sanitize_filename s =
  String.map (fun c ->
    match c with
    | '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|'
    | '\000' .. '\031' -> '_'
    | _ -> c
  ) s
  |> String.trim
  |> fun s -> if s = "" then "unnamed" else s

let is_regular_file path =
  Sys.file_exists path &&
    not (Sys.is_directory path)
