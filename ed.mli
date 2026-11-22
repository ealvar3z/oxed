type t

val create : Editor.t -> t
val execute : t -> string -> (string, string) result
