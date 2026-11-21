open Core

let header =
  Str.regexp "^[a-z0-9][a-z0-9.+-]* ([^() ]+) [^;]+; urgency=[a-z]+$"
;;

let trailer =
  Str.regexp
    "^ -- .+ <[^<> ]+>  [A-Z][a-z][a-z], [0-9][0-9]? [A-Z][a-z][a-z] \
     [0-9][0-9][0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] \
     [+-][0-9][0-9][0-9][0-9]$"
;;

let matches re s = Str.string_match re s 0

let check text =
  let lines = String.split text ~on:'\n' |> Array.of_list in
  let n = Array.length lines in
  let fail i msg = Error (i + 1, msg) in
  let rec skip i =
    if i < n && String.is_empty (String.strip lines.(i))
    then skip (i + 1)
    else i
  in
  let rec body i changed =
    let line = lines.(i) in
    if String.is_prefix line ~prefix:" -- "
    then
      if not (matches trailer line)
      then fail i "invalid trailer"
      else if not changed
      then fail i "empty changes"
      else Ok (i + 1)
    else if String.is_empty (String.strip line)
    then body (i + 1) changed
    else if String.is_prefix line ~prefix:"  *"
            && not (String.is_prefix line ~prefix:"  * ")
    then fail i "invalid bullet spacing"
    else if String.is_prefix line ~prefix:"  "
    then body (i + 1) true
    else fail i "invalid change indentation"
  in
  let rec stanzas i count =
    let i = skip i in
    if i = n
    then if count > 0 then Ok count else fail 0 "empty changelog"
    else if not (matches header lines.(i))
    then fail i "invalid header"
    else (
      match body (i + 1) false with
      | Ok next -> stanzas next (count + 1)
      | Error _ as err -> err)
  in
  stanzas 0 0
;;

let add text message =
  let message = String.strip message in
  if String.is_empty message
     || String.contains message '\n'
     || String.contains message '\r'
  then Error "invalid change description"
  else (
    match check text with
    | Error (line, msg) -> Error (Printf.sprintf "line %d: %s" line msg)
    | Ok _ ->
      (match String.split text ~on:'\n' with
       | header :: "" :: rest
         when String.is_substring header ~substring:" UNRELEASED; " ->
         let result =
           String.concat
             ~sep:"\n"
             (header :: "" :: ("  * " ^ message) :: rest)
         in
         (match check result with
          | Ok _ -> Ok result
          | Error (line, msg) ->
            Error (Printf.sprintf "line %d: %s" line msg))
       | _ -> Error "newest stanza must be UNRELEASED"))
;;
