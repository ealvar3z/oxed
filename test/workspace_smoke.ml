open Lwt.Syntax

let run path =
  let* workspace = Workspace.open_files [] in
  let source = Workspace.active workspace in
  assert (source.path = None);
  assert (source.text = "");
  let* workspace = Workspace.open_files [ path ] in
  let source = Workspace.active workspace in
  assert (source.path = Some path);
  assert (source.text = "oxed\n");
  Lwt.return_unit
;;

let () =
  match Array.to_list Sys.argv with
  | [ _; path ] ->
    Lwt_main.run (run path);
    print_endline "PASS: Workspace"
  | _ ->
    prerr_endline "usage: workspace_smoke FILE";
    exit 2
;;
