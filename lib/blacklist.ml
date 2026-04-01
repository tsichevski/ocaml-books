module Log = (val Logs.src_log (Logs.Src.create "invalid-files" ~doc:"Manage invalid file list") : Logs.LOG)

(** Minimal helper for appending entries to blacklist file. Follows blacklist.rst format. *)
let append file path comment =
  Fs.mkdir_p (Filename.dirname file) ~perm:0o755;
  Out_channel.with_open_gen [Open_wronly; Open_append; Open_creat] 0o644 file
    (fun oc -> Printf.fprintf oc "%s|%s\n%!" (Filename.basename path) comment)

let load path =
  let table = Hashtbl.create 512 in
  if Sys.file_exists path then
    In_channel.with_open_text path
      (fun ic ->
        try
          let rec loop () =
            let line = input_line ic in
            if String.starts_with ~prefix:"#" line then
              loop ()
            else
              match String.split_on_char '|' line with
              | file::msg::[] ->
                Hashtbl.add table file msg;
                loop ()
              | _ -> failwith ("Invalid blacklist file line: " ^ line)
          in
          loop ()
        with | End_of_file -> table
      )
  else
    begin
      Log.info (fun m -> m "Blacklist file does not exist, will be created on-demand: %s" path);
      table
    end
