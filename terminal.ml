type t =
  { term : LTerm.t
  ; mode : LTerm.mode
  ; mutable closed : bool
  }

let open_ () : t Lwt.t =
  let open Lwt.Syntax in
  let* term = Lazy.force LTerm.stdout in
  let* mode = LTerm.enter_raw_mode term in
  Lwt.return { term; mode; closed = false }
;;

let close t =
  if t.closed
  then Lwt.return_unit
  else
    let open Lwt.Syntax in
    let* () = LTerm.leave_raw_mode t.term t.mode in
    t.closed <- true;
    Lwt.return_unit
;;

let read_event t = LTerm.read_event t.term

let render t ?cursor_col draw =
  let open Lwt.Syntax in
  let size = LTerm.size t.term in
  let matrix = LTerm_draw.make_matrix size in
  let ctx = LTerm_draw.context matrix size in
  let style =
    { LTerm_style.none with
      foreground = Some LTerm_style.white
    ; background = Some LTerm_style.black
    }
  in
  LTerm_draw.fill_style ctx style;
  draw ctx;
  let* () = LTerm.render t.term matrix in
  match cursor_col with
  | Some col when size.rows > 0 && size.cols > 0 ->
    let col = max 0 (min (size.cols - 1) col) in
    LTerm.goto t.term { LTerm_geom.row = size.rows - 1; col }
  | _ -> Lwt.return_unit
;;
