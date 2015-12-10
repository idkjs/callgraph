(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

let parse_json_file (content:string) : unit =

  Printf.printf "atdgen parsed json file is :\n";
  (* Use the atdgen JSON parser *)
  let file : Callers_t.file = Callers_j.file_of_string content in
  print_endline (Callers_j.string_of_file file)

let parse_json_dir (content:string) (dirfullpath:string): unit =

  Printf.printf "atdgen parsed json directory is :\n";
  (* Use the atdgen JSON parser *)
  let dir : Callers_t.dir = Callers_j.dir_of_string content in
  print_endline (Callers_j.string_of_dir dir);

  (* Parse the json files contained in the current directory *)
  (match dir.files with
   | None -> ()
   | Some files ->
      List.iter
	( fun f ->

	  (* let jsoname_file = String.concat "" [ f; ".file.callers.json" ] in *)
	  let dirpath : string = Filename.basename dirfullpath in
	  let jsoname_file =
	    if String.compare dirpath dirfullpath == 0
	    then f
	    else String.concat "" [ dirpath; "/"; f ]
	  in
	  let content = Common.read_json_file jsoname_file in
          (match content with
           | None -> ()
           | Some content ->
              (
	        (* Printf.printf "Read %s content is:\n %s: \n" f content; *)
	        parse_json_file content
              )
	  )
        )
	files
  )

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("dirname" %: string)
  +> anon (maybe("jsondirext" %: string))

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Parses a callers's json directory with the atdgen library"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun dirfullpath jsondirext () ->

	let jsoname_dir : string =
	  (match jsondirext with
	  | None -> Printf.sprintf "%s" dirfullpath
	  | Some dirext -> Printf.sprintf "%s.%s" dirfullpath dirext
	  )
	in
	let content = Common.read_json_file jsoname_dir in
        (match content with
         | None -> ()
         | Some content ->
	    (* Printf.printf "Read directory content is:\n %s: \n" content; *)
	    parse_json_dir content dirfullpath
        )
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package yojson -tag thread parse_json_dir.native" *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread parse_json_dir.native" *)
(* End: *)
