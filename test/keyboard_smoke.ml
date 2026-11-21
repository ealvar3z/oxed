open Lwt.Syntax

let rec read_key terminal =
  let* event = Terminal.read_event terminal in
  match event with
  | LTerm_event.Key key -> Lwt.return key
  | _ -> read_key terminal
;;

let run () =
  let* terminal = Terminal.open_ () in
  Lwt.finalize
    (fun () -> read_key terminal)
    (fun () -> Terminal.close terminal)
;;

let () =
  let key = Lwt_main.run (run ()) in
  Printf.printf "Key: %s\n" (LTerm_key.to_string_compact key)
;;
