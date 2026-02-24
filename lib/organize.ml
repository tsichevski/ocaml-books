module AuthorTbl = Hashtbl.Make(String)

type book = {
  author : string;
  title  : string;
  path   : string;
}

let group_by_author books =
  let tbl = AuthorTbl.create 16 in
  List.iter (fun b ->
    let key = String.lowercase_ascii b.author in
    let existing = AuthorTbl.find_opt tbl key |> Option.value ~default:[] in
    AuthorTbl.replace tbl key (b :: existing)
  ) books;
  tbl
