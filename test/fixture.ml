let check condition message = if not condition then failwith message

let empty_editor () =
  Workspace.open_files [] |> Lwt_main.run |> Editor.create
;;

let ascii_editor text =
  let editor = empty_editor () in
  String.iter
    (fun ch -> Editor.insert_char editor (Uchar.of_int (Char.code ch)))
    text;
  editor
;;

let with_file contents f =
  let path = Filename.temp_file "oxed-test-" ".txt" in
  Fun.protect
    ~finally:(fun () -> Sys.remove path)
    (fun () ->
      let channel = open_out_bin path in
      Fun.protect
        ~finally:(fun () -> close_out channel)
        (fun () -> output_string channel contents);
      f path)
;;
