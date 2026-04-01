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
        "database": {
          "host": "localhost",
          "port": 5432,
          "user": "books",
          "passwd": "books",
          "name": "books",
          "admin": "admin",
          "admin_passwd": "admin"
        }
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
  dry_run : bool [@default false];

  (** Maximum allowed length of a single filename component (directory or file name).
      [0] means no limit (default). *)
  max_component_len : int [@default 0];

  (** Number of parallel jobs (domain pool). Set to [1] to disable parallelism. *)
  jobs : int [@default 1];

  (** Optional path to a log file. If [None], logs go to stdout. *)
  log_file : string option [@default None];

  (** Optional path to the file black list.
      If omitted in JSON or set to null → None.
      If [None], illegal files will not be managed. *)
  blacklist : string option [@default None];

  (** If [true] and [log_file] is set: truncate the log file on startup
      (drop existing content). Otherwise append (default).
      Has no effect when [log_file = None]. *)
  drop_existing_log_file_on_start : bool [@default false];

  (** Optional logging level override.
      Supported values: "quiet", "error", "warning", "info", "debug", "app".
      If [None], the default level (INFO) is used. *)
  log_level : string option [@default None];

  (** Optional path to author alias JSON file (see {!Alias.load_aliases}). *)
  alias_file : string option [@default None];

  (** Grouped PostgreSQL connection settings (preferred). *)
  database : database_config;
} [@@deriving yojson]

and database_config = {
  (** Database hostname. *)
  host : string   [@default "localhost"];

  (** Database port (default: 5432). *)
  port : int [@default 5432];

  (** Database username for normal operations. *)
  user : string [@default "books"];

  (** Password for the normal database user. *)
  passwd : string [@default "books"];

  (** Database name. *)
  name : string [@default "books"];

  (** Admin username (used for schema initialization). *)
  admin : string [@default "admin"];

  (** Admin password (used for schema initialization). *)
  admin_passwd : string [@default "admin"];
} [@@deriving yojson]

(** [default_database] returns sensible defaults for the database section. *)
let default_database () : database_config =
  {
    host         = "localhost";
    port         = 5432;
    user         = "books";
    passwd       = "books";
    name         = "books";
    admin        = "admin";
    admin_passwd = "admin"
  }

(** [default ()] returns the hardcoded default configuration.

    Paths are based on ``$HOME/books/...``. Most optional fields are [None].
    Useful as a fallback when no config file is found or when creating a new one.
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
    drop_existing_log_file_on_start = false;
    blacklist = None;
    
    (* PostgreSQL defaults – grouped *)
    database         = default_database ()
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

  Out_channel.with_open_gen [Open_wronly; Open_creat] 0o644 path
    (fun oc -> output_string oc (pretty ^ "\n"))