(* Unzip file support *)
(*
  utop:
  #require "zipc";;
  #require "unix";;
 *)
open Zipc
open Unix

exception Zipc_error of string

let read_file_binary path =
  try
    let ic = open_in_bin path in
    Fun.protect ~finally:(fun () -> close_in_noerr ic)
      (fun () -> Ok (really_input_string ic (in_channel_length ic)))
  with Sys_error msg ->
    Error msg

let extract_fb2_files zip_path target_dir : (string list, string) result =
  let size = (Unix.stat zip_path).Unix.st_size in

  if Int.to_float size > 4_500_000_000.0 then begin
      (* Large archive → fallback to external 7z *)
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
                      name e;
                    acc
                    else
                      acc
          ) zip []
        |> List.rev
      in

      Ok fb2_paths_rev
    end
