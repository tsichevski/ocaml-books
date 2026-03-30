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

open Zipc
open Unix

exception Zipc_error of string
(** Raised for ZIP-specific errors (e.g. corrupted archive, unsupported format, 7z failure). *)

(** [read_file_binary path] reads the entire content of a binary file into a string.

    Returns [Ok content] on success or [Error msg] on I/O failure.

    Example:

    {[
      match read_file_binary "archive.zip" with
      | Ok data -> Printf.printf "Read %d bytes\n" (String.length data)
      | Error e -> Printf.eprintf "Failed: %s\n" e
    ]}
*)
let read_file_binary path : (string, string) result =
  try
    In_channel.with_open_bin path
      (fun ic -> Ok (really_input_string ic (in_channel_length ic)))
  with Sys_error msg ->
    Error msg

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
let extract_fb2_files ?(overwrite:bool = true) zip_path target_dir : (string list, string) result =
  let size = (Unix.stat zip_path).Unix.st_size in

  if Int.to_float size > 4_500_000_000.0 then begin
    (* Large archive fallback to avoid memory exhaustion with zipc *)
    Printf.printf "Large archive (%.1f GB) detected — using external 7z\n"
      (Int.to_float size /. 1e9);

    let cmd =
      Printf.sprintf "7z x %s -o%s -y >/dev/null 2>&1"
        (Filename.quote zip_path) (Filename.quote target_dir)
    in
    if Sys.command cmd = 0 then
      Ok []   (* caller should scan target_dir for .fb2 files *)
    else
      Error "External 7z extraction failed"
  end else begin
    (* Normal size — use pure OCaml zipc *)
    let ( let* ) = Result.bind in

    let* content = read_file_binary zip_path in
    let* zip =
      match Zipc.of_binary_string content with
      | Ok z -> Ok z
      | Error e -> Error (Printf.sprintf "Failed to parse ZIP: %s" e)
    in

    let fb2_paths_rev =
      Zipc.fold (fun member acc ->
          match Zipc.Member.kind member with
          | Zipc.Member.Dir -> acc
          | Zipc.Member.File file ->
              let name = Zipc.Member.path member in
              if Filename.check_suffix name ".fb2" then
                match Zipc.File.to_binary_string file with
                | Ok data ->
                    let basename = Filename.basename name in
                    let out_path = Filename.concat target_dir basename in

                    if not overwrite && Sys.file_exists out_path then begin
                      Printf.printf "Skipping existing file (overwrite=false): %s\n" out_path;
                      acc
                    end else begin
                      let dir = Filename.dirname out_path in
                      if not (Sys.file_exists dir) then
                        Fs.mkdir_p dir;

                      let oc = open_out_bin out_path in
                      Fun.protect ~finally:(fun () -> close_out_noerr oc)
                        (fun () -> output_string oc data);

                      Printf.printf "Extracted: %s\n" basename;
                      out_path :: acc
                    end

                | Error e ->
                    Printf.eprintf "Failed to extract %s: %s\n" name e;
                    acc
              else
                acc
        ) zip []
      |> List.rev
    in

    Ok fb2_paths_rev
  end