open Lwt.Syntax

let run () =
  let* terminal = Terminal.open_ () in
  Lwt.finalize
    (fun () ->
      let* () =
        Terminal.render terminal (fun ctx ->
          LTerm_draw.draw_string ctx 0 0 (Zed_string.of_utf8 "oxed");
          LTerm_draw.draw_string
            ctx
            2
            0
            (Zed_string.of_utf8 "Press any key to exit"))
      in
      let* _ = Terminal.read_event terminal in
      Lwt.return_unit)
    (fun () -> Terminal.close terminal)
;;

let () = Lwt_main.run (run ())
