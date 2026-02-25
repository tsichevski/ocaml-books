(* lib/unzip.ml *)

(* ZIP archive extraction utilities.
   Extracts .fb2 files from ZIP archives using zipc library.
   Handles large archives via fallback to external 7z tool.

   Dependencies: zipc, unix, sys, filename (standard library).

   Assumes archives contain only .fb2 files for extraction.
   No recursive scanning — only direct entries. *)

open Zipc
open Unix

exception Zipc_error of string

(** [read_file_binary path] reads the entire binary content of [path] into a string.
    Returns [Ok content] on success or [Error msg] on failure (e.g., permission denied, file not found). *)
let read_file_binary path =
  try
    let ic = open_in_bin path in
    Fun.protect ~finally:(fun () -> close_in_noerr ic)
      (fun () -> Ok (really_input_string ic (in_channel_length ic)))
  with Sys_error msg ->
    Error msg

(** [extract_fb2_files zip_path target_dir] extracts all .fb2 files from the ZIP at [zip_path]
    into [target_dir].

    - For archives >4.5 GB, falls back to external 7z tool (requires 7z installed).
    - For smaller archives, uses zipc in pure OCaml.
    - Creates parent directories in [target_dir] as needed.
    - Prints extraction progress to stdout.
    - Logs errors for individual files but continues with others.

    @return [Ok paths] — list of full paths to successfully extracted .fb2 files (in reverse order of extraction)
    @return [Error msg] — error message if archive could not be processed or fallback failed *)
let extract_fb2_files zip_path target_dir : (string list, string) result =
  let size = (Unix.stat zip_path).Unix.st_size in

  if Int.to_float size > 4_500_000_000.0 then begin
      (* Large archive fallback to avoid memory exhaustion with zipc *)
      Printf.printf "Large archive (%.1f GB) detected - using external 7z\n"
        (Int.to_float size /. 1e9);
      let cmd =
        Printf.sprintf "7z x %s -o%s -y >/dev/null 2>&1"
          (Filename.quote zip_path) (Filename.quote target_dir)
      in
      if Sys.command cmd = 0 then
        Ok []   (* success - caller can scan target_dir for .fb2 files *)
      else
        Error "External 7z extraction failed"
    end else begin
      (* Normal size - use zipc in pure OCaml *)
      let ( let* ) = Result.bind in

      let* content = read_file_binary zip_path in
      let* zip = Zipc.of_binary_string content in

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

                    let dir = Filename.dirname out_path in
                    if not (Sys.file_exists dir) then Fs.mkdir_p dir;

                    let oc = open_out_bin out_path in
                    output_string oc data;
                    close_out oc;

                    Printf.printf "Extracted: %s\n" basename;
                    out_path :: acc

                 | Error e ->
                    Printf.eprintf "Failed to extract %s: %s\n"
                      name e;
                    acc
                    else
                      acc
          ) zip []
        |> List.rev
      in

      Ok fb2_paths_rev
    end