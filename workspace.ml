type source =
  { path : string option
  ; text : string
  }

type t =
  { active : source
  ; others : source list
  }

let active workspace = workspace.active

let open_files paths =
  let open Lwt.Syntax in
  let read path =
    let* text = Lwt_io.with_file ~mode:Lwt_io.Input path Lwt_io.read in
    Lwt.return { path = Some path; text }
  in
  match paths with
  | [] -> Lwt.return { active = { path = None; text = "" }; others = [] }
  | path :: rest ->
    let* active = read path in
    let* others = Lwt_list.map_s read rest in
    Lwt.return { active; others }
;;
