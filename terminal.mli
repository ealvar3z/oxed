type t

val open_ : unit -> t Lwt.t
val close : t -> unit Lwt.t
