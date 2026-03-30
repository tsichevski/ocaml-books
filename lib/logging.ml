(** Logging setup for BookWeald.

    This module configures the [Logs] library to output structured messages
    with level, source, and thread identifier.

    When a log file is provided, messages are appended to that file.
    Otherwise, the default reporter (usually stderr) is left unchanged.

    Output format for file logging:

    [LEVEL][SOURCE][THREAD] message

    Example line:

    [INFO][fb2_parse][main] Parsed book: Война и мир

    Thread ID is "main" for the main domain or the domain index for parallel workers.
*)

open Logs

(** [setup path] configures the Logs reporter to write to the given file.

    - Opens the file in append mode (creates it if it does not exist).
    - Uses a custom reporter that prefixes every message with:
      - Log level (e.g. INFO, DEBUG, ERROR)
      - Source name (e.g. "fb2_parse", "db")
      - Thread identifier ("main" or domain index)
    - The original reporter is replaced for the whole program.

    If the file cannot be opened, raises [Failure] with a descriptive message
    including the path and the underlying error.

    This function is usually called once at program startup from the CLI
    (see {!Config.t.log_file}).

    Example:

    {[
      (* In CLI setup *)
      match cfg.log_file with
      | Some p -> Logging.setup p
      | None   -> ()
    ]}

    Example output when logging to file:

    {[
      [DEBUG][normalize][main] normalize_name: "Лев Николаевич Толстой" -> "Лев Николаевич Толстой"
      [ERROR][db][3] Database integrity error: 2 books with same digest=...
    ]}
*)
let setup path =
  try
    let oc = open_out_gen [Open_wronly; Open_append; Open_creat] 0o644 path in
    Fun.protect ~finally:(fun () -> close_out_noerr oc)
      (fun () ->
        let f = Format.formatter_of_out_channel oc in

        let report src level ~over k msgf =
          let k _ = over (); k () in
          let pp_header ppf () =
            let level_str = level_to_string (Some level) in
            let thread_id =
              if Domain.is_main_domain () then
                "main"
              else
                Domain.self_index () |> string_of_int
            in
            Format.fprintf ppf "[%s][%s][%s] " level_str (Src.name src) thread_id
          in
          msgf @@ fun ?header ?tags fmt ->
            Format.kfprintf k f ("%a" ^^ fmt ^^ "@.") pp_header ()
        in

        let reporter = { report } in
        Logs.set_reporter reporter;

        Logs.info (fun m -> m "Logging initialized to file: %s" path)
      )
  with e ->
    failwith (Printf.sprintf
      "Cannot setup logging to file %s: %s" path (Printexc.to_string e))