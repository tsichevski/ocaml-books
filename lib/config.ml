(** Configuration loading and management for BookWeald.

    This module defines the main configuration type [t] and provides functions
    to load it from JSON files with fallback to sensible defaults.

    Config files are searched in this order (first match wins):

    1. ``./config.json`` (local override, useful for development)
    2. ``~/.config/bookweald/config.json`` (user-wide, XDG-style)

    The configuration is serialized/deserialized using ``yojson`` and
    ``ppx_deriving_yojson`` for type safety.

    All optional fields default to [None] or sensible values when missing.
*)

(** Main configuration record.

    Fields control library paths, behavior flags, parallelism, logging,
    author aliases, and PostgreSQL connection settings.

    Example JSON snippet:

    {[
      {
        "library_dir": "/home/user/books/incoming",
        "target_dir": "/home/user/books/organized",
        "dry_run": false,
        "jobs": 4,
        "db_host": "localhost"
        ...
      }
    ]}
*)
type t = {
  (** Directory containing incoming FB2 files. *)
  library_dir : string;

  (** Destination directory for organized books (author-based structure). *)
  target_dir : string;

  (** Directory for files that failed validation or parsing. *)
  invalid_dir : string;

  (** If [true], simulate all operations without modifying the filesystem or database. *)
  dry_run : bool;

  (** Maximum allowed length of a single filename component (directory or file name).
      [0] means no limit (default). *)
  max_component_len : int;

  (** Number of parallel jobs (domain pool). Set to [1] to disable parallelism. *)
  jobs : int;

  (** Optional path to a log file. If [None], logs go to stdout. *)
  log_file : string option;

  (** Optional logging level override.
      Supported values: "quiet", "error", "warning", "info", "debug", "app".
      If [None], the default level (INFO) is used. *)
  log_level : string option;

  (** Optional path to author alias JSON file (see {!Alias.load_aliases}). *)
  alias_file : string option;

  (* PostgreSQL connection settings *)

  (** Database hostname. *)
  db_host : string;

  (** Database port (default: 5432). *)
  db_port : int;

  (** Database username for normal operations. *)
  db_user : string;

  (** Password for the normal database user. *)
  db_passwd : string;

  (** Database name. *)
  db_name : string;

  (** Admin username (used for schema initialization). *)
  db_admin : string;

  (** Admin password (used for schema initialization). *)
  db_admin_passwd : string;
} [@@deriving yojson { strict = false }]

(** [default ()] returns the hardcoded default configuration.

    Paths are based on ``$HOME/books/...``. Most optional fields are [None].
    Useful as a fallback when no config file is found or when creating a new one.

    Example:

    {[
      let cfg = Config.default () in
      cfg.library_dir = "/home/user/books/incoming"
    ]}
*)
let default () : t =
  let home = Sys.getenv "HOME" in
  {
    library_dir      = Filename.concat home "books/incoming";
    target_dir       = Filename.concat home "books/organized";
    invalid_dir      = Filename.concat home "books/invalid";
    alias_file       = None;
    dry_run          = false;
    max_component_len = 0;
    jobs             = 1;
    log_file         = None;
    log_level        = None;

    (* PostgreSQL defaults *)
    db_host          = "localhost";
    db_port          = 5432;
    db_user          = "books";
    db_passwd        = "books";
    db_name          = "books";
    db_admin         = "admin";
    db_admin_passwd  = "admin"
  }

(** [load path] loads and parses a configuration from the given JSON file.

    Uses strict=false deriver so unknown fields are ignored.
    Raises [Failure] with a descriptive message if the JSON is invalid or
    cannot be converted to type [t].

    Example:

    {[
      let cfg = Config.load "./config.json" in
      Printf.printf "Library dir: %s\n" cfg.library_dir
    ]}
*)
let load path : t =
  try
    match of_yojson (Yojson.Safe.from_file path) with
    | Ok cfg -> cfg
    | Error e ->
        failwith (Printf.sprintf "Invalid configuration in %s: %s" path e)
  with e ->
    Printf.eprintf "Cannot read configuration file %s: %s\n" path (Printexc.to_string e);
    raise e

(** [create_default path] writes a default configuration to [path] in pretty-printed JSON.

    - Creates parent directories if they do not exist (using {!Fs.mkdir_p}).
    - Overwrites the file if it already exists.

    Raises:
    - [Sys_error] on file I/O failures.
    - [Failure] propagated from {!Fs.mkdir_p} if directory creation fails.

    Example:

    {[
      Config.create_default "~/.config/bookweald/config.json"
      (* creates the file with default values and prints confirmation *)
    ]}
*)
let create_default (path : string) : unit =
  let cfg = default () in
  let json = to_yojson cfg in
  let pretty = Yojson.Safe.pretty_to_string ~std:true json in

  let dir = Filename.dirname path in
  if not (Sys.file_exists dir) then
    Fs.mkdir_p dir ~perm:0o755;

  let oc = open_out path in
  Fun.protect ~finally:(fun () -> close_out_noerr oc)
    (fun () ->
      output_string oc (pretty ^ "\n");
      flush oc)
