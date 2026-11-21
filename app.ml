type t =
  { terminal : Terminal.t
  ; editor : Editor.t
  ; commands : Ed.t
  ; syntax : Syntax.t
  ; languages : Language.t
  ; mutable running : bool
  }

type event =
  | Key of LTerm_key.t
  | Mouse of LTerm_mouse.t
  | Resize of LTerm_geom.size
  | Sequence of string

let create ~terminal ~editor ~commands ~syntax ~languages =
  { terminal; editor; commands; syntax; languages; running = true }
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
  | _ -> Lwt.return_unit
;;

let render (app : t) : unit Lwt.t =
  Terminal.render app.terminal (fun ctx ->
    let rows = (LTerm_draw.size ctx).rows in
    LTerm_draw.draw_string ctx 0 0 (Zed_string.of_utf8 "oxed");
    if rows > 1
    then
      LTerm_draw.draw_string
        ctx
        (rows - 1)
        0
        (Zed_string.of_utf8 "Ctrl-Q quit"))
;;

let running (app : t) : bool = app.running
