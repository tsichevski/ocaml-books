open Zipc
open Unix

let extract_fb2_files ?(overwrite:bool = true) zip_path target_dir : (string list, string) result =
  let size = (Unix.stat zip_path).Unix.st_size in

  if size > 4_500_000_000 then begin
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

    let content = Fs.read_file_binary zip_path in
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

let unzip_fb2_file contents =
  let zip =
    match Zipc.of_binary_string contents with
    | Ok z -> z
    | Error e -> failwith (Printf.sprintf "Failed to parse ZIP: %s" e)
  in

  match Zipc.fold
    (fun member acc ->
      match Zipc.Member.kind member with
      | Zipc.Member.Dir -> acc
      | Zipc.Member.File file ->
        let name = Zipc.Member.path member in
        if (Filename.check_suffix name ".fb2") then
          match acc with
          | Some data -> failwith "More than one .fb2 entry in an archive"
          | None -> 
            match Zipc.File.to_binary_string file with
            | Ok data ->
              Some data
            | Error e ->
              failwith (Printf.sprintf "Failed to decompress %s: %s\n" name e)
        else acc
    )
    zip None
  with
  | None -> failwith "No matching .fb2 file in archive"
  | Some d -> d
