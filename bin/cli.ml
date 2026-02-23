open Ocaml_books

let usage_msg = "ocaml-books [command] [options]\n\
                 Commands:\n\
                 \  --init          Create default configuration file\n\
                 \  --import <path> Process ZIP file or directory\n\
                 \  --organize      Parse and organize extracted books\n\
                 \n\
                 Use --help for more information.\n"

let cfg = Config.load
let anon_fun _ = failwith "Unexpected anonymous argument"

let config_path = ref None
let target_dir  = ref None
let dry_run     = ref false

let speclist = Arg.align [
  "--config", Arg.String (fun s -> config_path := Some s),
    "PATH      Use custom config file instead of default locations";
  "--dry-run", Arg.Set dry_run,
    "           Simulate actions without moving files";
  "--target", Arg.String (fun s -> target_dir := Some s),
    "DIR        Override target directory from config";
]

let () =
  if Array.length Sys.argv < 2 then begin
    Arg.usage speclist usage_msg;
    exit 1
  end;

  let cmd = Sys.argv.(1) in
  match cmd with
  | "--import" ->
      if Array.length Sys.argv < 3 then begin
        Printf.eprintf "Error: import requires a ZIP file or directory path\n";
        exit 1
      end;
      let zip_path = Some Sys.argv.(2) in
      Arg.parse speclist anon_fun usage_msg;
      (* TODO: call import logic *)
      Printf.printf "Import from: %s (dry-run: %b)\n" (Option.value zip_path ~default:"(none)") !dry_run
  (* | "--organize" -> *)
  (*     Arg.parse speclist anon_fun usage_msg; *)
  (*     let cfg = Config.load () in *)
  (*     Printf.printf "Organizing from %s to %s (dry-run: %b)\n" *)
  (*       cfg.library_dir cfg.target_dir !dry_run; *)
  (*     (\* TODO: scan library_dir, extract, parse, move *\) *)
  (*     () *)
  | "--help" | "-h" ->
      Arg.usage speclist usage_msg;
      exit 0
  | _ ->
      Printf.eprintf "Unknown command: %s\n" cmd;
      Arg.usage speclist usage_msg;
      exit 1

