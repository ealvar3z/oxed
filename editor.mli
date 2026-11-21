type t

val create : Workspace.t -> t
val text : t -> string
val path : t -> string option
val position : t -> int
val insert_char : t -> Uchar.t -> unit
val move_left : t -> unit
val move_right : t -> unit
val backspace : t -> unit
val delete_forward : t -> unit
