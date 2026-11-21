open Lwt.Syntax

let run () =
  let* workspace = Workspace.open_files [] in
  let editor = Editor.create workspace in
  let* language = Language.start editor in
  Language.stop language
;;

let () =
  Lwt_main.run (run ());
  print_endline "PASS: Language"
;;
