let%test_unit "language service starts and stops" =
  let editor = Fixture.empty_editor () in
  let open Lwt.Syntax in
  let operation =
    let* language = Language.start editor in
    Language.stop language
  in
  Lwt_main.run operation
;;
