type t

val start : Editor.t -> t Lwt.t
val stop : t -> unit Lwt.t
