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
  let commands = Ed.create editor in
  expect (Ed.execute commands ",p" = Ok "λ café") "whole-buffer print";
  expect (Ed.execute commands ",n" = Ok "1  λ café") "numbered output";
  expect (Ed.execute commands "1n" = Ok "1  λ café") "numbered line";
  expect (Ed.execute commands "1,1p" = Ok "λ café") "line range";
  expect (Ed.execute commands "1p" = Ok "λ café") "select first line";
  expect (Ed.execute commands ".p" = Ok "λ café") "print dot";
  expect (Ed.execute commands ".n" = Ok "1  λ café") "number dot";
  expect (Ed.execute commands "$p" = Ok "") "end-of-file empty selection";
  expect (Ed.execute commands ".p" = Ok "") "dot follows end-of-file";
  expect
    (Ed.execute commands "2p" = Error "? address out of range")
    "invalid line";
  expect
    (Ed.execute commands "xyz" = Error "? unknown command")
    "unknown command";
  let* workspace = Workspace.open_files [] in
  let editor = Editor.create workspace in
  String.iter
    (fun ch -> Editor.insert_char editor (Uchar.of_int (Char.code ch)))
    "alpha\nbeta\ncharlie\n";
  let commands = Ed.create editor in
  expect (Ed.execute commands "1p" = Ok "alpha") "first line";
  expect (Ed.execute commands "+p" = Ok "beta") "next line";
  expect (Ed.execute commands "-p" = Ok "alpha") "previous line";
  expect
    (Ed.execute commands ".+2n" = Ok "3  charlie")
    "relative numbered address";
  expect (Ed.execute commands "$-p" = Ok "charlie") "last line from EOF";
  expect
    (Ed.execute commands "+p" = Error "? address out of range")
    "next line beyond EOF";
  expect
    (Ed.execute commands ".p" = Ok "charlie")
    "invalid address preserves dot";
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
