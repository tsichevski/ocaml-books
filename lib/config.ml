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

let default_config () : t = {
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
    | [] -> default_config ()
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
