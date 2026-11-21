type t =
  { engine : unit Zed_edit.t
  ; cursor : Zed_cursor.t
  ; path : string option
  }

let create workspace =
  let source = Workspace.active workspace in
  let engine : unit Zed_edit.t = Zed_edit.create () in
  let cursor = Zed_edit.new_cursor engine in
  let context = Zed_edit.context engine cursor in
  let rope = source.text |> Zed_string.of_utf8 |> Zed_rope.of_string in
  Zed_edit.insert context rope;
  Zed_cursor.goto cursor 0;
  { engine; cursor; path = source.path }
;;

let text editor =
  Zed_edit.text editor.engine |> Zed_rope.to_string |> Zed_string.to_utf8
;;

let path editor = editor.path
let position editor = Zed_cursor.get_position editor.cursor
