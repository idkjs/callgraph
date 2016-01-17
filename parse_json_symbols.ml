(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

(* let parse_json_file (content:string) : unit = *)

(*   Printf.printf "atdgen parsed json file is :\n"; *)
(*   (\* Use the atdgen JSON parser *\) *)
(*   let file : Callers_t.file = Callers_j.file_of_string content in *)
(*   print_endline (Callers_j.string_of_file file) *)

(* let parse_json_dir (content:string) (dirfullpath:string): unit = *)

(*   Printf.printf "atdgen parsed json directory is :\n"; *)
(*   (\* Use the atdgen JSON parser *\) *)
(*   let dir : Callers_t.dir = Callers_j.dir_of_string content in *)
(*   print_endline (Callers_j.string_of_dir dir); *)

(*   (\* Parse the json files contained in the current directory *\) *)
(*   (match dir.files with *)
(*    | None -> () *)
(*    | Some files ->  *)
(*       List.iter *)
(* 	( fun f ->  *)
(*      *)
(* 	  (\* let jsoname_file = String.concat "" [ f; ".file.callers.json" ] in *\) *)
(* 	  let dirpath : string = Filename.basename dirfullpath in *)
(* 	  let jsoname_file =  *)
(* 	    if String.compare dirpath dirfullpath == 0 *)
(* 	    then f *)
(* 	    else String.concat "" [ dirpath; "/"; f ] *)
(* 	  in *)
(* 	  let json : Yojson.Basic.json = read_json_file jsoname_file in *)
(* 	  let content : string = Yojson.Basic.to_string json in *)
(* 	  (\* Printf.printf "Read %s content is:\n %s: \n" f content; *\) *)
(* 	  parse_json_file content *)
(* 	) *)
(* 	files *)
(*   ) *)

(* let parse_json_symbols (content:string) (dirfullpath:string): unit = *)

(*   Printf.printf "atdgen parsed json directory is :\n"; *)
(*   (\* Use the atdgen JSON parser *\) *)
(*   let dir : Callers_t.dir = Callers_j.dir_of_string content in *)
(*   print_endline (Callers_j.string_of_dir dir); *)

(*   (\* Parse the json files contained in the current directory *\) *)
(*   (match dir.files with *)
(*    | None -> () *)
(*    | Some files ->  *)
(*       List.iter *)
(* 	( fun f ->  *)
(* *)
(* 	  (\* let jsoname_file = String.concat "" [ f; ".file.callers.json" ] in *\) *)
(* 	  let dirpath : string = Filename.basename dirfullpath in *)
(* 	  let jsoname_file =  *)
(* 	    if String.compare dirpath dirfullpath == 0 *)
(* 	    then f *)
(* 	    else String.concat "" [ dirpath; "/"; f ] *)
(* 	  in *)
(* 	  let json : Yojson.Basic.json = read_json_file jsoname_file in *)
(* 	  let content : string = Yojson.Basic.to_string json in *)
(* 	  (\* Printf.printf "Read %s content is:\n %s: \n" f content; *\) *)
(* 	  parse_json_file content *)
(* 	) *)
(* 	files *)
(*   ) *)

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("allsymbols_jsonfilepath" %: string)

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Parses the global list of defined symbols"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun allsymbols_jsonfilepath () ->

	let content = Common.read_json_file allsymbols_jsonfilepath in
        (match content with
        | None -> ()
        | Some content ->
           (
	     Printf.printf "Read defined symbols content is:\n %s: \n" content
	   (* parse_json_symbols content dirfullpath *)
           )
        )
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package yojson -tag thread parse_json_symbols.native" *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread parse_json_symbols.native" *)
(* End: *)
