open Lwt.Syntax
exception Injected

let run fail =
  let* terminal = Terminal.open_ () in
  Lwt.finalize
    (fun () ->
      let* () = Lwt_unix.sleep 1.0 in
      if fail then Lwt.fail Injected
      else Lwt.return_unit)
    (fun () ->
      let* () = Terminal.close terminal in
      Terminal.close terminal)

  let () =
    let fail = Array.length Sys.argv > 1 in
    try
      Lwt_main.run (run fail);
      print_endline "Normal termination"
    with
    | Injected ->
        print_endline "Exception handled"
