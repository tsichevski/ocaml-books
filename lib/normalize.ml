(** Filter out anything but letters, replace 'ё' by 'ё', return the result title-cased *)
let normalize_chunk s =
  let b = Buffer.create (String.length s) in
  Uutf.String.fold_utf_8
    (fun _ _ u ->
      match u with
      | `Uchar u ->
        if Uucp.Alpha.is_alphabetic u then
          begin
            let cp = Uchar.to_int u in
            let u =
              if cp = 0x0401 || cp = 0x0451 then  (* Ё or ё *)
                Uchar.of_int 0x0435                 (* е *)
              else
                u in
            let func = if Buffer.length b = 0 then
              Uucp.Case.Map.to_upper
            else
              Uucp.Case.Map.to_lower in
            match func u with
            | `Self -> Uutf.Buffer.add_utf_8 b u
            | `Uchars l -> List.iter (fun u -> Uutf.Buffer.add_utf_8 b u) l
          end
          
      | `Malformed e -> failwith ("Mailformed char: " ^ e)
    )
    () s;
  Buffer.contents b

(** Filter out anything but letters, replace 'ё' by 'ё', return the result title-cased *)
let normalize_name s =
  String.split_on_char '-' s |> List.map normalize_chunk |> String.concat "-"