open Core

let replace_file file text =
  let tmp, output =
    Stdlib.Filename.open_temp_file
      ~temp_dir:(Stdlib.Filename.dirname file)
      "oxch-"
      ".tmp"
  in
  try
    Stdlib.output_string output text;
    Stdlib.close_out output;
    Core_unix.chmod tmp ~perm:(Core_unix.stat file).st_perm;
    Stdlib.Sys.rename tmp file
  with
  | exn ->
    Stdlib.close_out_noerr output;
    (try Stdlib.Sys.remove tmp with
     | _ -> ());
    raise exn
;;

let check file =
  match Changelog.check (In_channel.read_all file) with
  | Ok count -> printf "PASS: %d stanzas\n" count
  | Error (line, msg) ->
    eprintf "%s:%d: %s\n" file line msg;
    exit 1
;;

let add file message =
  let original = In_channel.read_all file in
  match Changelog.add original message with
  | Ok updated ->
    replace_file file updated;
    printf "Updated %s\n" file
  | Error msg ->
    eprintf "oxch: %s\n" msg;
    exit 1
;;

let () =
  match Array.to_list (Sys.get_argv ()) with
  | [ _; "check" ] -> check "CHANGELOG"
  | [ _; "check"; file ] -> check file
  | [ _; "add"; message ] -> add "CHANGELOG" message
  | [ _; "add"; message; file ] -> add file message
  | _ ->
    eprintf "usage: oxch check [file]\n";
    exit 2
;;
