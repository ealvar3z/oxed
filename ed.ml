type t = Editor.t

let create editor = editor
let lines text =
  if text = "" then []
  else
    let lines = String.split_on_char '\n' text in 
    match List.rev lines with
    | "" :: rest -> List.rev rest
    | _ -> lines
;;

let execute editor command =
  let content = lines (Editor.text editor) in 
  match String.trim command with
  | ",p" -> Ok (String.concat "\n" content)
  | ",n" ->
      let numbered =
        List.mapi
        (fun i line -> Printf.sprintf "%d  %s" (i + 1) line)
        content
      in 
      Ok (String.concat "\n" numbered)
  | "" -> Ok ""
  | _ -> Error "? unknown command"
;;
