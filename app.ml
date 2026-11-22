type t =
  { terminal : Terminal.t
  ; editor : Editor.t
  ; commands : Ed.t
  ; syntax : Syntax.t
  ; languages : Language.t
  ; mutable command : string
  ; mutable feedback : string
  ; mutable running : bool
  }

type event =
  | Key of LTerm_key.t
  | Mouse of LTerm_mouse.t
  | Resize of LTerm_geom.size
  | Sequence of string

let create ~terminal ~editor ~commands ~syntax ~languages =
  { terminal
  ; editor
  ; commands
  ; syntax
  ; languages
  ; command = ""
  ; feedback = ""
  ; running = true
  }
;;

let append_char text ch =
  let buffer = Buffer.create 4 in
  Buffer.add_utf_8_uchar buffer ch;
  text ^ Buffer.contents buffer
;;

let remove_last text =
  let text = Zed_string.of_utf8 text in
  let len = Zed_string.length text in
  if len = 0
  then ""
  else Zed_string.sub ~pos:0 ~len:(len - 1) text |> Zed_string.to_utf8
;;

let next_event (app : t) : event Lwt.t =
  let open Lwt.Syntax in
  let* event = Terminal.read_event app.terminal in
  Lwt.return
    (match event with
     | LTerm_event.Key key -> Key key
     | LTerm_event.Mouse mouse -> Mouse mouse
     | LTerm_event.Resize size -> Resize size
     | LTerm_event.Sequence s -> Sequence s)
;;

let dispatch app = function
  | Key key
    when key.control
         && (not key.meta)
         &&
         match key.code with
         | LTerm_key.Char ch -> Uchar.to_int ch = Char.code 'q'
         | _ -> false ->
    app.running <- false;
    Lwt.return_unit
  | Key key when (not key.control) && not key.meta ->
    (match key.code with
     | LTerm_key.Char ch -> app.command <- append_char app.command ch
     | LTerm_key.Backspace -> app.command <- remove_last app.command
     | LTerm_key.Enter ->
       app.feedback <- 
         (match Ed.execute app.commands app.command with
         | Ok output -> output
         | Error message -> message);
       app.command <- ""
     | LTerm_key.Escape -> app.command <- ""
     | _ -> ());
    Lwt.return_unit
  | _ -> Lwt.return_unit
;;

let render (app : t) : unit Lwt.t =
  let prompt = "λ " ^ app.command in
  let cursor_col =
    Zed_string.of_utf8 prompt |> Zed_string.width |> Zed_string.aval_width
  in
  Terminal.render app.terminal ~cursor_col (fun ctx ->
    let rows = (LTerm_draw.size ctx).rows in

    LTerm_draw.draw_string ctx 0 0 (Zed_string.of_utf8 "oxed");

    if rows > 2
    then LTerm_draw.draw_string ctx 1 0 (Zed_string.of_utf8 app.feedback);

    if rows > 1
    then LTerm_draw.draw_string ctx (rows - 1) 0 (Zed_string.of_utf8 prompt))
;;

let running (app : t) : bool = app.running
