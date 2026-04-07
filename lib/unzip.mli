(** ZIP archive extraction utilities for FB2 files.

    This module provides functions to extract .fb2 files from ZIP archives.
    It supports two extraction backends:

    - Pure OCaml using the ``zipc`` library (fast for archives < ~4.5 GB).
    - External ``7z`` tool as a fallback for very large archives (to avoid memory exhaustion).

    Only files ending with ``.fb2`` (case-sensitive) are extracted.
    Directories inside the archive are ignored.
    Extracted files are placed flat into the target directory (no sub-directory preservation).

    Dependencies: ``zipc``, ``unix``, ``fs`` (for ``mkdir_p``).
*)

(** [extract_fb2_files ?overwrite zip_path target_dir] extracts all .fb2 files
    from the ZIP archive at [zip_path] into [target_dir].

    Behaviour:
    - If the archive is larger than 4.5 GB, falls back to the external ``7z`` command
      (requires ``7z`` to be installed in PATH). In this case the returned list is empty
      and the caller is expected to scan [target_dir] for extracted files.
    - For smaller archives, uses pure OCaml ``zipc`` extraction.
    - Creates necessary parent directories using {!Fs.mkdir_p}.
    - Prints progress ("Extracted: filename.fb2") to stdout for user feedback.
    - Continues extraction even if individual files fail (only logs the error).

    @param overwrite If [false] and a file with the same name already exists in
           [target_dir], the existing file is skipped (default: [true]).

    @return [Ok paths] — list of full paths to successfully extracted .fb2 files
            (in reverse order of appearance in the archive).
    @return [Error msg] — if the archive could not be opened or the fallback failed.

    Example:

    {[
      match extract_fb2_files "library.zip" "/tmp/extracted" with
      | Ok paths ->
          Printf.printf "Extracted %d FB2 files\n" (List.length paths)
      | Error e ->
          Printf.eprintf "Extraction failed: %s\n" e
    ]}
*)
val extract_fb2_files :
  ?overwrite:bool -> string -> string -> (string list, string) result

(** [unzip_fb2_file contents] treats the argument as a ZIP archive contents, and extract the first zip entry with name ending with .fb2 to a string *)
val unzip_fb2_file : string -> string
