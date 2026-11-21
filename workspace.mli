type source =
  { path : string option
  ; text : string
  }

type t

val open_files : string list -> t Lwt.t
val active : t -> source
