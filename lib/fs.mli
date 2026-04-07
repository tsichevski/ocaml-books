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
val mkdir_p : ?perm:int -> string -> unit

(** [is_regular_file path] returns true if [path] exists and is a regular file
    (not directory, symlink, device, etc.). Returns false on non-existent paths or errors.
*)
val is_regular_file : string -> bool

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
val sanitize_filename : string -> int -> string

(** [read_file_binary path] read the file contents as a string *)
val read_file_binary : string -> string
