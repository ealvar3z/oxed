type t = Disabled

let start (_editor : Editor.t) : t Lwt.t = Lwt.return Disabled

let stop : t -> unit Lwt.t = function
  | Disabled -> Lwt.return_unit
;;
