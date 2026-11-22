type range =
  { start : int
  ; stop : int
  }

type t = 
  { editor : Editor.t
  ; mutable dot : range
  }

type address =
  | All 
  | Dot
  | Eof
  | Line of int
  | Between of address * address

type command =
  | Print
  | Number

type expression =
  { address : address
  ; command : command
  }

let create editor = 
  { editor
  ; dot = { start = 0; stop = 0 }
  }
;;

let lines text =
  if text = "" then []
  else
    let lines = String.split_on_char '\n' text in 
    match List.rev lines with
    | "" :: rest -> List.rev rest
    | _ -> lines
;;

let index_lines content =
  let total = Zed_string.length (Zed_string.of_utf8 content) in 
  let offset = ref 0 in 

  lines content
  |> List.mapi (fun i text ->
      let start = !offset in 
      let length = Zed_string.length (Zed_string.of_utf8 text) in 
      let stop = min total (start + length + 1) in 

      offset := stop;
      i + 1, { start; stop }, text)
;;

let parse_address source =
  let atom = function
    | "" | "." -> Some Dot
    | "$" -> Some Eof
    | text ->
        Option.map (fun n -> Line n) (int_of_string_opt text)
  in

  match String.split_on_char ',' source with 
  | [""; "" ] -> Some All 
  | [ first; last ] ->
      (match atom first, atom last with 
      | Some first, Some last ->
          Some (Between (first, last))
      | _ -> None)
  | [ address ] -> atom address 
  | _ -> None
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

        (match parse_address prefix with
        | Some address -> Ok (Some { address; command })
        | None -> Error "? invalid address"))
;;

let execute ed source =
  match parse source with
  | Error message -> Error message
  | Ok None -> Ok ""
  | Ok (Some { address; command }) ->
    let content = Editor.text ed.editor in 
    let text = Zed_string.of_utf8 content in
    let total = Zed_string.length text in
    let indexed = index_lines content in 

    let rec resolve = function
      | All -> Ok { start = 0; stop = total }
      | Dot -> Ok ed.dot
      | Eof -> Ok { start = total; stop = total }
      | Line n ->
          (match List.find_opt (fun (i, _, _) -> i = n) indexed with 
            | Some (_, range, _) -> Ok range
            | None -> Error "? address out of range")
      | Between (first, last) ->
          (match resolve first, resolve last with 
          | Ok a, Ok b when a.start <= b.stop ->
              Ok { start = a.start; stop = b.stop }
          | Ok _, Ok _ -> Error "? reversed range"
          | Error message, _ | _, Error message -> Error message)
    in

    match resolve address with 
    | Error message -> Error message
    | Ok range -> 
        Printf.eprintf "command=%S dot=[%d,%d) range=[%d,%d)\n%!" source
        ed.dot.start ed.dot.stop range.start range.stop;
        ed.dot <- range;

      (match command with 
      | Print ->
          let output =
            Zed_string.sub
              ~pos:range.start 
              ~len:(range.stop - range.start)
              text
            |> Zed_string.to_utf8
          in 
          let length = String.length output in 
          if length > 0 && output.[length - 1] = '\n' then 
            Ok (String.sub output 0 (length - 1))
          else Ok output
      | Number ->
          let output = 
            indexed
            |> List.filter (fun (_, line, _) ->
                line.start < range.stop && range.start < line.stop)
            |> List.map (fun (i, _, text) ->
                Printf.sprintf "%d  %s" i text)
            |> String.concat "\n"
          in 
          Ok output)
