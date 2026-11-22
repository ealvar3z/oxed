let transcript ed commands =
  List.iter
    (fun source ->
      Printf.printf "λ %s\n" source;
      match Ed.execute ed source with
      | Ok "" -> print_endline "(empty)"
      | Ok output -> print_endline output
      | Error message -> print_endline message)
    commands
;;

let%expect_test "whole-buffer, numbered, dot, and EOF addresses" =
  Fixture.with_file "λ café\n" (fun path ->
    let workspace = Lwt_main.run (Workspace.open_files [ path ]) in
    let ed = Ed.create (Editor.create workspace) in
    transcript
      ed
      [ ",p"; ",n"; "1n"; "1,1p"; "1p"; ".p"; ".n"; "$p"; ".p"; "2p"; "xyz" ]);
  [%expect
    {|
    λ ,p
    λ café
    λ ,n
    1  λ café
    λ 1n
    1  λ café
    λ 1,1p
    λ café
    λ 1p
    λ café
    λ .p
    λ café
    λ .n
    1  λ café
    λ $p
    (empty)
    λ .p
    (empty)
    λ 2p
    ? address out of range
    λ xyz
    ? unknown command
    |}]
;;

let%expect_test "relative addresses and failed-command atomicity" =
  let ed = Ed.create (Fixture.ascii_editor "alpha\nbeta\ncharlie\n") in
  transcript ed [ "1p"; "+p"; "-p"; ".+2n"; "$-p"; "+p"; ".p" ];
  [%expect
    {|
    λ 1p
    alpha
    λ +p
    beta
    λ -p
    alpha
    λ .+2n
    3  charlie
    λ $-p
    charlie
    λ +p
    ? address out of range
    λ .p
    charlie
    |}]
;;
