type t

val create : Workspace.t -> t
val text : t -> string
val path : t -> string option
val position : t -> int
val insert_char : t -> Uchar.t -> unit
