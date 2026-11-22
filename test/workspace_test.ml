let%test_unit "empty unnamed workspace" =
  let workspace = Lwt_main.run (Workspace.open_files []) in
  let source = Workspace.active workspace in
  Fixture.check (source.path = None) "unnamed buffer";
  Fixture.check (source.text = "") "empty buffer"
;;

let%test_unit "workspace opens existing file" =
  Fixture.with_file "oxed\n" (fun path ->
    let workspace = Lwt_main.run (Workspace.open_files [ path ]) in
    let source = Workspace.active workspace in
    Fixture.check (source.path = Some path) "file path";
    Fixture.check (source.text = "oxed\n") "file contents")
;;
