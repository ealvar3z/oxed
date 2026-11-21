type t = {
  term : LTerm.t;
  mode : LTerm.mode;
  mutable closed : bool;
}

let open_ () : t Lwt.t =
  let open Lwt.Syntax in
  let* term = Lazy.force LTerm.stdout in
  let* mode = LTerm.enter_raw_mode term in
  Lwt.return { term; mode; closed = false }

let close t =
  if t.closed then Lwt.return_unit
  else
    let open Lwt.Syntax in
    let* () = LTerm.leave_raw_mode t.term t.mode in
    t.closed <- true;
    Lwt.return_unit

let read_event t =
  LTerm.read_event t.term
