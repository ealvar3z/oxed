type t

val open_ : unit -> t Lwt.t
val close : t -> unit Lwt.t
val read_event : t -> LTerm_event.t Lwt.t
val render
  :  t
  -> ?cursor_col:int
  -> (LTerm_draw.context -> unit)
  -> unit Lwt.t
