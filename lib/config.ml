(*
  utop:
#require "yojson";;
 *)
open Yojson

type t = {
    library_dir     : string;
    target_dir      : string;
    dry_run         : bool;
    verbose         : bool;
  } [@@deriving yojson { strict = false }]

let default () : t = {
    library_dir      = Filename.concat (Sys.getenv "HOME") "books/incoming";
    target_dir       = Filename.concat (Sys.getenv "HOME") "books/organized";
    dry_run          = false;
    verbose          = true;
  }

let config_file_locations () : string list =
  [
    "config.json";
    Filename.concat (Sys.getenv "HOME") ".config/ocaml-books/config.json";
  ]

let load () : t =
  let rec try_load = function
    | [] -> default ()
    | path :: rest ->
       if Sys.file_exists path then
         try
           let json = Yojson.Safe.from_file path in
           match of_yojson json with
           | Ok cfg -> cfg
           | Error e ->
              Printf.eprintf "Invalid config %s: %s\n" path e;
              try_load rest
         with e ->
           Printf.eprintf "Cannot read config %s: %s\n" path (Printexc.to_string e);
           try_load rest
       else
         try_load rest
  in
  try_load (config_file_locations ())

(** [create_default path] writes a default configuration to [path] in JSON format.
    Overwrites the file if it already exists. *)
let create_default (path : string) : unit =
  let cfg = default () in
  let json = to_yojson cfg in
  let pretty = Yojson.Safe.pretty_to_string ~std:true json in

  let dir = Filename.dirname path in
  if not (Sys.file_exists dir) then begin
      Fs.mkdir_p dir ~perm:0o755  (* assuming you have Unix.mkdir_p or Fs.mkdir_p *)
    end;

  let oc = open_out path in
  Fun.protect ~finally:(fun () -> close_out_noerr oc)
    (fun () ->
      output_string oc (pretty ^ "\n");
      flush oc);

  Printf.printf "Default configuration written to %s\n" path