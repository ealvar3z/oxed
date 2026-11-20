type event = unit

type t = {
    terminal : Terminal.t;
    editor : Editor.t;
    commands : Ed.t;
    syntax : Syntax.t;
    languages : Language.t;
    mutable running : bool
}

let create ~terminal ~editor ~commands ~syntax ~languages =
    { terminal; editor; commands; syntax; languages; running = true }

let next_event (_app : t) : event Lwt.t =
    failwith "TODO: App.next_event"

let dispatch (_app : t) (_event : event) : unit Lwt.t =
    failwith "TODO: App.dispatch"

let render (_app : t) : unit Lwt.t =
    failwith "TODO: App.render"

let running (app : t) : bool =
    app.running

