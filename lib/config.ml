(* Configuration loading and saving for the OCaml Books tool.
   Handles JSON-based config files with fallback to defaults.
   Uses yojson for parsing/serialization and ppx_deriving_yojson for type-safe conversions.

   Dependencies: yojson, ppx_deriving_yojson, sys, filename, printf (standard library).
   No external non-OPAM dependencies.

   Config locations checked in order:
   1. ./config.json (local, for project-specific overrides)
   2. ~/.config/ocaml-books/config.json (user-global, standard XDG location)

   All functions are pure except for I/O side-effects in load/create_default. *)

(** Configuration type with all settings used by the tool. *)
type t = {
  library_dir     : string;             (* Source directory with ZIPs or raw FB2 files *)
  target_dir      : string;             (* Destination directory for organized books *)
  dry_run         : bool;               (* If true: simulate actions without changes *)
  verbose         : bool;               (* If true: print detailed progress info *)
} [@@deriving yojson { strict = false }]

(** [default ()] returns the hardcoded default configuration values. *)
let default () : t = {
  library_dir      = Filename.concat (Sys.getenv "HOME") "books/incoming";
  target_dir       = Filename.concat (Sys.getenv "HOME") "books/organized";
  dry_run          = false;
  verbose          = true;
}

(** [config_file_locations ()] returns the list of standard config file paths to check. *)
let config_file_locations () : string list =
  [
    "config.json";
    Filename.concat (Sys.getenv "HOME") ".config/ocaml-books/config.json";
  ]

(** [load ()] attempts to load configuration from standard locations.
    Prints errors to stderr on failure (invalid JSON, read errors) and continues to next location.
    Returns default configuration if all locations fail or no files exist. *)
let load () : t =
  let rec try_load = function
    | [] -> default ()
    | path :: rest ->
       if Sys.file_exists path then
         try
           let json = Yojson.Safe.from_file path in
           match of_yojson json with
           | Ok cfg -> cfg
           | Error e ->
              Printf.eprintf "Invalid config %s: %s\n" path e;
              try_load rest
         with e ->
           Printf.eprintf "Cannot read config %s: %s\n" path (Printexc.to_string e);
           try_load rest
       else
         try_load rest
  in
  try_load (config_file_locations ())

(** [create_default path] writes a default configuration to [path] in pretty-printed JSON.
    Creates parent directories if needed using Fs.mkdir_p.
    Overwrites the file if it already exists.
    Prints success message to stdout.

    @raise Sys_error on file creation/write failure
    @raise Failure from Fs.mkdir_p if directory creation fails *)
let create_default (path : string) : unit =
  let cfg = default () in
  let json = to_yojson cfg in
  let pretty = Yojson.Safe.pretty_to_string ~std:true json in

  let dir = Filename.dirname path in
  if not (Sys.file_exists dir) then begin
      Fs.mkdir_p dir ~perm:0o755  (* assuming Fs.mkdir_p takes optional ~perm *)
    end;

  let oc = open_out path in
  Fun.protect ~finally:(fun () -> close_out_noerr oc)
    (fun () ->
      output_string oc (pretty ^ "\n");
      flush oc);

  Printf.printf "Default configuration written to %s\n" path