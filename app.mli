type t
type event

val create :
    terminal:Terminal.t ->
    editor:Editor.t ->
    commands:Ed.t ->
    syntax:Syntax.t ->
    languages:Language.t ->
    t

val next_event : t -> event Lwt.t
val dispatch : t -> event -> unit Lwt.t
val render : t -> unit Lwt.t
val running : t -> bool
