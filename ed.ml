type range =
  { start : int
  ; stop : int
  }

type t =
  { editor : Editor.t
  ; mutable dot : range
  }

type direction =
  | Forward
  | Backward

type address =
  | All
  | Dot
  | Eof
  | Line of int
  | Relative of address * direction * int
  | Between of address * address

type command =
  | Print
  | Number

type expression =
  { address : address
  ; command : command
  }

let create editor = { editor; dot = { start = 0; stop = 0 } }

let lines text =
  if text = ""
  then []
  else (
    let lines = String.split_on_char '\n' text in
    match List.rev lines with
    | "" :: rest -> List.rev rest
    | _ -> lines)
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

let parse_simple = function
  | "" | "." -> Some Dot
  | "$" -> Some Eof
  | text ->
    (match int_of_string_opt text with
     | Some n when n > 0 -> Some (Line n)
     | _ -> None)
;;

let find_sign source =
  let rec loop i =
    if i >= String.length source
    then None
    else (
      match source.[i] with
      | '+' -> Some (i, Forward)
      | '-' -> Some (i, Backward)
      | _ -> loop (i + 1))
  in
  loop 0
;;

let parse_distance = function
  | "" -> Some 1
  | text ->
    (match int_of_string_opt text with
     | Some n when n > 0 -> Some n
     | _ -> None)
;;

let parse_atom source =
  match find_sign source with
  | None -> parse_simple source
  | Some (i, direction) ->
    let base = String.sub source 0 i in
    let suffix = String.sub source (i + 1) (String.length source - i - 1) in
    (match parse_simple base, parse_distance suffix with
     | Some base, Some distance ->
       Some (Relative (base, direction, distance))
     | _ -> None)
;;

let parse_address source =
  match String.split_on_char ',' source with
  | [ ""; "" ] -> Some All
  | [ first; last ] ->
    (match parse_atom first, parse_atom last with
     | Some first, Some last -> Some (Between (first, last))
     | _ -> None)
  | [ address ] -> parse_atom address
  | _ -> None
;;

let parse source =
  let source = String.trim source in
  if source = ""
  then Ok None
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

let resolve_line indexed n =
  match List.find_opt (fun (i, _, _) -> i = n) indexed with
  | Some (_, range, _) -> Ok range
  | None -> Error "? address out of range"
;;

let resolve_relative indexed base direction distance =
  let candidates =
    match direction with
    | Forward ->
      List.filter (fun (_, line, _) -> line.start >= base.stop) indexed
    | Backward ->
      List.rev indexed
      |> List.filter (fun (_, line, _) -> line.stop <= base.start)
  in
  match List.nth_opt candidates (distance - 1) with
  | Some (_, range, _) -> Ok range
  | None -> Error "? address out of range"
;;

let ( let* ) = Result.bind

let rec resolve_address ed indexed total = function
  | All -> Ok { start = 0; stop = total }
  | Dot -> Ok ed.dot
  | Eof -> Ok { start = total; stop = total }
  | Line n -> resolve_line indexed n
  | Relative (base, direction, distance) ->
    let* base = resolve_address ed indexed total base in
    resolve_relative indexed base direction distance
  | Between (first, last) ->
    let* a = resolve_address ed indexed total first in
    let* b = resolve_address ed indexed total last in
    if a.start <= b.stop
    then Ok { start = a.start; stop = b.stop }
    else Error "? reversed range"
;;

let print_range text range =
  let output =
    Zed_string.sub ~pos:range.start ~len:(range.stop - range.start) text
    |> Zed_string.to_utf8
  in
  let length = String.length output in
  if length > 0 && output.[length - 1] = '\n'
  then String.sub output 0 (length - 1)
  else output
;;

let number_range indexed range =
  indexed
  |> List.filter (fun (_, line, _) ->
    line.start < range.stop && range.start < line.stop)
  |> List.map (fun (i, _, text) -> Printf.sprintf "%d  %s" i text)
  |> String.concat "\n"
;;

let format_command text indexed range = function
  | Print -> print_range text range
  | Number -> number_range indexed range
;;

let execute ed source =
  let* expression = parse source in
  match expression with
  | None -> Ok ""
  | Some { address; command } ->
    let content = Editor.text ed.editor in
    let text = Zed_string.of_utf8 content in
    let indexed = index_lines content in
    let* range =
      resolve_address ed indexed (Zed_string.length text) address
    in
    let output = format_command text indexed range command in
    ed.dot <- range;
    Ok output
;;
