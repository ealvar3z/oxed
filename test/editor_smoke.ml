open Lwt.Syntax

let expect condition message = if not condition then failwith message

let run path =
  let* workspace = Workspace.open_files [] in
  let editor = Editor.create workspace in

  expect (Editor.text editor = "") "empty buffer";
  expect (Editor.path editor = None) "unnamed buffer";
  expect (Editor.position editor = 0) "initial cursor";

  Editor.insert_char editor (Uchar.of_int 0x03BB);
  expect (Editor.text editor = "λ") "Greek lambda insertion";
  expect (Editor.position editor = 1) "cursor after lambda";

  Editor.insert_char editor (Uchar.of_int 0x00E9);
  expect (Editor.text editor = "λé") "accented insertion";
  expect (Editor.position editor = 2) "cursor after accent";

  Editor.move_left editor;
  expect (Editor.position editor = 1) "move left";

  Editor.delete_forward editor;
  expect (Editor.text editor = "λ") "forward deletion";

  Editor.move_left editor;
  expect (Editor.position editor = 0) "move to beginning";

  Editor.move_right editor;
  expect (Editor.position editor = 1) "move right";

  Editor.backspace editor;
  expect (Editor.text editor = "") "backspace";
  expect (Editor.position editor = 0) "cursor after deletion";

  let* workspace = Workspace.open_files [ path ] in
  let editor = Editor.create workspace in

  expect (Editor.text editor = "λ café\n") "UTF-8 round trip";
  expect (Editor.path editor = Some path) "file path";
  expect (Editor.position editor = 0) "cursor reset";

  Lwt.return_unit
;;

let () =
  match Array.to_list Sys.argv with
  | [ _; path ] ->
    Lwt_main.run (run path);
    print_endline "PASS: Editor"
  | _ ->
    prerr_endline "usage: editor_smoke FILE";
    exit 2
;;
