module Input_channel = Bookweald.Input_channel
open Printf

let () = 
  let src = String.to_seq  "Hello, world!" in
  let ic = Input_channel.create src in
  let seq = Input_channel.to_seq ic in
  let hello = Seq.take 5 seq |> String.of_seq in
  printf "Hello: %s\n" hello;
  Input_channel.mark ic;
  let world = Seq.take 5 seq |> String.of_seq in
  printf "World: %s\n" world;
  Input_channel.reset ic;
  let world = Seq.take 5 seq |> String.of_seq in
  printf "Again: %s\n" world;
  let world = Seq.take 5 seq |> String.of_seq in
  printf "Again: %s\n" world;
  let world = Seq.take 5 seq |> String.of_seq in
  printf "Again: %s\n" world
