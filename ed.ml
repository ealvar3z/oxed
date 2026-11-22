type t = Editor.t
type address =
  | All 
  | Line of int
  | Range of int * int

type command =
  | Print
  | Number

type expression =
  { address : address
  ; command : command
  }

let create editor = editor
let lines text =
  if text = "" then []
  else
    let lines = String.split_on_char '\n' text in 
    match List.rev lines with
    | "" :: rest -> List.rev rest
    | _ -> lines
;;

let parse source =
  let source = String.trim source in 
  if source = "" then Ok None
  else (
    let last = String.length source - 1 in 
    let command =
      match source.[last] with
      | 'p' -> Some Print
      | 'n' -> Some Number
      | _ -> None
    in 
    match command with
    | None -> Error "? unknown command"
    | Some command ->
        let prefix = String.sub source 0 last in 
        let address =
          match String.split_on_char ',' prefix with
          | [""; ""] -> Some All
          | [ line ] ->
              Option.map (fun n -> Line n) (int_of_string_opt line)
          | [ first; last ] ->
              (match int_of_string_opt first, int_of_string_opt last with
              | Some first, Some last -> Some (Range (first, last))
              | _ -> None)
          | _ -> None
        in 
        (match address with
        | Some address -> Ok (Some { address; command })
        | None -> Error "? invalid address"))
;;

let execute editor source =
  match parse source with
  | Error message -> Error message
  | Ok None -> Ok ""
  | Ok (Some { address; command }) ->
    let content = lines (Editor.text editor) in 
    let count = List.length content in 
    let first, last =
      match address with
      | All -> 1, count
      | Line n -> n, n
      | Range (a, b) -> a, b
    in 
    if count = 0 && address = All then Ok ""
    else if first < 1 || last > count || first > last then
      Error "? address out of range"
    else (
      let selected =
        content
        |> List.mapi (fun i line -> i + 1, line)
        |> List.filter (fun (i, _) -> i >= first && i <= last)
      in 
      let output =
        List.map
        (fun (i, line) ->
          match command with
          | Print -> line
          | Number -> Printf.sprintf "%d  %s" i line)
        selected
      in 
      Ok (String.concat "\n" output))
;;
