
(* tangled from ~/org/technology/data/data.org *)
(* adapted from /media/users/balp/tests/data/interchange/json/test_random_event/test_yojson_read.ml *)

(* open Core.Std *)

let read_json_file (filename:string) : Yojson.Basic.json =

  Printf.printf "In_channel read file %s...\n" filename;
  (* Read JSON file into an OCaml string *)
  let buf = Core.Std.In_channel.read_all filename in           
  (* Use the string JSON constructor *)
  let json1 = Yojson.Basic.from_string buf in
  json1
  (* Use the file JSON constructor *)
  (* let json2 = Yojson.Basic.from_file filename in *)
  (* Test that the two values are the same *)
  (* print_endline (if json1 = json2 then "OK" else "FAIL") *)

let parse_json_file (content:string) : unit =

  Printf.printf "atdgen parsed json file is :\n";
  (* Use the atdgen JSON parser *)
  let file : Callgraph_t.file = Callgraph_j.file_of_string content in
  print_endline (Callgraph_j.string_of_file file)

let parse_json_dir (content:string) (dirfullpath:string): unit =

  Printf.printf "atdgen parsed json directory is :\n";
  (* Use the atdgen JSON parser *)
  let dir : Callgraph_t.dir = Callgraph_j.dir_of_string content in
  print_endline (Callgraph_j.string_of_dir dir);

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
	  let json : Yojson.Basic.json = read_json_file jsoname_file in
	  let content : string = Yojson.Basic.to_string json in
	  Printf.printf "Read %s content is:\n %s: \n" f content;
	  parse_json_file content
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
	let json : Yojson.Basic.json = read_json_file jsoname_dir in
	let content : string = Yojson.Basic.to_string json in
	Printf.printf "Read directory content is:\n %s: \n" content;
	parse_json_dir content dirfullpath
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package yojson -tag thread callgraph_from_json.native" *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread callgraph_from_json.native" *)
(* End: *)
