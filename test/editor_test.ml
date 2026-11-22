let%test_unit "empty unnamed buffer" =
  let editor = Fixture.empty_editor () in
  Fixture.check (Editor.text editor = "") "empty buffer";
  Fixture.check (Editor.path editor = None) "unnamed buffer";
  Fixture.check (Editor.position editor = 0) "initial cursor"
;;

let%test_unit "Unicode insert, move, and delete" =
  let editor = Fixture.empty_editor () in
  Editor.insert_char editor (Uchar.of_int 0x03BB);
  Fixture.check (Editor.text editor = "λ") "lambda insertion";
  Fixture.check (Editor.position editor = 1) "cursor after lambda";
  Editor.insert_char editor (Uchar.of_int 0x00E9);
  Fixture.check (Editor.text editor = "λé") "accented insertion";
  Fixture.check (Editor.position editor = 2) "cursor after accent";
  Editor.move_left editor;
  Fixture.check (Editor.position editor = 1) "move left";
  Editor.delete_forward editor;
  Fixture.check (Editor.text editor = "λ") "forward deletion";
  Editor.move_left editor;
  Fixture.check (Editor.position editor = 0) "move to beginning";
  Editor.move_right editor;
  Fixture.check (Editor.position editor = 1) "move right";
  Editor.backspace editor;
  Fixture.check (Editor.text editor = "") "backspace";
  Fixture.check (Editor.position editor = 0) "cursor after deletion"
;;

let%test_unit "UTF-8 file loads without moving cursor" =
  Fixture.with_file "λ café\n" (fun path ->
    let workspace = Lwt_main.run (Workspace.open_files [ path ]) in
    let editor = Editor.create workspace in
    Fixture.check (Editor.text editor = "λ café\n") "UTF-8 round trip";
    Fixture.check (Editor.path editor = Some path) "file path";
    Fixture.check (Editor.position editor = 0) "cursor reset")
;;
