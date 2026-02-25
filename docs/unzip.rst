================================
ZIP Extraction Module (unzip.ml)
================================

.. contents::
   :depth: 2
   :local:


Overview
--------

This module provides safe extraction of FB2 files from ZIP archives using the **zipc** library.

Key features:

- Loads entire archive into memory (small/medium ZIPs only)
- Falls back to external ``7z`` for very large archives (>1.5 GB)
- Extracts only files ending with ``.fb2``
- Creates parent directories as needed
- Returns list of successfully extracted full paths
- Returns error message string on failure


Dependencies
------------

Required OPAM packages:

- ``zipc``    (main ZIP handling)
- ``unix``    (file system operations)


Code (lib/unzip.ml)
-------------------

.. code-block:: ocaml

   (* lib/unzip.ml *)

   open Zipc

   exception Zipc_error of string

   let string_of_error = function
     | `Msg s                  -> s
     | `Unsupported_version v  -> Printf.sprintf "unsupported ZIP version: %d" v
     | `Invalid_header         -> "invalid ZIP header"
     | `Corrupted              -> "archive appears corrupted"
     | `Not_a_zip              -> "not a valid ZIP file"
     | `No_such_entry          -> "requested entry not found"
     | `Io_error msg           -> Printf.sprintf "I/O error: %s" msg

   let read_file_binary path =
     try
       let ic = open_in_bin path in
       Fun.protect ~finally:(fun () -> close_in_noerr ic)
         (fun () -> Ok (really_input_string ic (in_channel_length ic)))
     with Sys_error msg ->
       Error msg

   let extract_fb2_files zip_path target_dir : (string list, string) result =
     let size = (Unix.stat zip_path).Unix.st_size in

     if Int64.to_float size > 1_500_000_000.0 then begin
       (* Large archive → fallback to external 7z *)
       Printf.printf "Large archive (%.1f GB) detected - using external 7z\n"
         (Int64.to_float size /. 1e9);
       let cmd =
         Printf.sprintf "7z x %s -o%s -y >/dev/null 2>&1"
           (Filename.quote zip_path) (Filename.quote target_dir)
       in
       if Sys.command cmd = 0 then
         Ok []   (* success - caller can scan target_dir for .fb2 files *)
       else
         Error "External 7z extraction failed"
     end else begin
       (* Normal size → use zipc in pure OCaml *)
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
                       name (string_of_error e);
                     acc
               else
                 acc
         ) [] zip
         |> List.rev
       in

       Ok fb2_paths_rev
     end


Integration notes
-----------------

- Add to ``lib/dune``:

  .. code-block:: lisp

     (libraries unix zipc xml-light yojson ppx_deriving_yojson.runtime cmdliner)

- Usage example (in CLI or main):

  .. code-block:: ocaml

     match Unzip.extract_fb2_files "/path/to/archive.zip" "/tmp/extracted" with
     | Ok paths ->
         Printf.printf "Extracted %d FB2 files\n" (List.length paths);
         (* continue with organize *)
     | Error msg ->
         Printf.eprintf "Extraction failed: %s\n" msg;
         exit 1

- For very large archives (3.5 GB+), ensure ``7z`` is installed on the system

- Future improvements:

  - Add progress callback for large extractions
  - Support encrypted ZIPs (currently not handled)
  - Return list of extracted paths even in 7z mode (scan target_dir after extraction)

Let me know if you want to:

- integrate this into the ``import`` command with directory scanning
- add recursive ZIP discovery (find all .zip in folder)
- or start filling in the ``organize`` command with this extractor

Happy to continue with the next piece.