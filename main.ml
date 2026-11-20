open Core
open Lwt.Syntax

let rec loop app =
    let* event = App.next_event app in
    let* () = App.dispatch app event in
    let* () = App.render app in
    if App.running app then loop app
    else Lwt.return_unit

let run files =
    let* terminal = Terminal.open_ () in
    Lwt.finalize
        (fun () ->
            let* workspace = Workspace.open_files file in
            let editor = Editor.create workspace in
            let commands = Ed.create editor in
            let syntax = Syntax.create editor in
            let* languages = Language.start editor in
            Lwt.finalize
                (fun () ->
                    let app =
                        App.create
                            ~terminal
                            ~editor
                            ~commands
                            ~syntax
                            ~languages
                    in
                    let* () = App.render app in
                    loop app)
                (fun () -> Terminal.close terminal))

let () =
    let files =
        Sys.get_argv ()
        |> Array.to_list
        |> List.tl_exn
    in
    Lwt_main.run (run files)
        

