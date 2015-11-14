(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   KTD SCIS 2014-2015                                                       *)
(*   Use Case Legacy TOSA                                                     *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)
(* tangled from ~/org/technology/data/data.org *)
(* adapted from /media/users/balp/tests/data/interchange/json/test_random_event/test_yojson_read.ml *)

(* exception Internal_Error *)
exception Internal_Error_1
exception Internal_Error_2
exception Internal_Error_3
exception Internal_Error_4
exception Internal_Error_5
exception Internal_Error_6
exception Internal_Error_7

exception Unexpected_Error_1
exception Unexpected_Error_2
exception Unexpected_Error_3

exception File_Not_Found
exception Usage_Error
(* exception TBC *)

module Callers = Map.Make(String);;
module Callees = Map.Make(String);;
module Calls = Map.Make(String);;

class function_callers_json_parser 
	(callee_id:string) 
	(callee_json_filepath:string)
	(other:string list option)
	(* (root_directory:string)  *)
  = object(self)

  val callee_id : string = callee_id

  val callee_file_path : string = callee_json_filepath

  val show_files : bool = 

    (match other with
    | None -> false
    | Some args -> 
      
      let show_files : string =
	try
	  List.find
	    (
	      fun arg -> 
		(match arg with
		| "files" -> true
		| _ -> false
		)
	    )
	    args
	with
	  Not_found -> "none"
      in
      (match show_files with
      | "files" -> true
      | "none"
      | _ -> false
      )
    )

  (* Function callers graph *)
  val mutable gfct_callers : Graph_func.G.t = Graph_func.G.empty

  (* Function callees graph *)
  val mutable gfct_callees : Graph_func.G.t = Graph_func.G.empty

  (* Function caller to callee graph *)
  val mutable gfct_c2b : Graph_func.G.t = Graph_func.G.empty

  val mutable callees_table = Callees.empty
  val mutable callers_table = Callees.empty

  val mutable callees_calls_table = Calls.empty
  val mutable callers_calls_table = Calls.empty

  method read_json_file (filename:string) : Yojson.Basic.json =
    try
      Printf.printf "In_channel read file %s...\n" filename;
    (* Read JSON file into an OCaml string *)
      let buf = Core.Std.In_channel.read_all filename in           
    (* Use the string JSON constructor *)
      let json1 = Yojson.Basic.from_string buf in
      json1
    with
    | Sys_error msg -> 
      (
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	Printf.printf "funcion_callers_to_dot::ERROR::File_Not_Found::%s\n" filename;
	Printf.printf "Sys_error msg: %s\n" msg;
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	raise File_Not_Found
      )

  method dump_fct (fct_sign:string) (json_file:string) : Graph_func.function_decl =

    (* Replace all / by _ in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\/") "_" json_file in

    (* Replace all '.' by '_' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\.") "_" fpath in

    (* Replace all '-' by '_' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\-") "_" fpath in

    (* Replace all '+' by 'p' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\+") "p" fpath in

    let filename : string = Filename.basename json_file in

    let file : Graph.Graphviz.DotAttributes.subgraph option = 
      if show_files then
	Some
    	  {
    	    sg_name = fpath;
    	    sg_attributes = [ `Label filename ];
    	    (* sg_parent = Some class_memberdef_factory.file.sg_name; *)
    	    sg_parent = None;
    	  }
      else
	None
    in
    let v : Graph_func.function_decl =
      {
	id = Printf.sprintf "\"%s\"" fct_sign;
	name = Printf.sprintf "\"%s\"" fct_sign;
	file_path = json_file;
	line = "unkownFunctionLine";
	bodyfile = json_file;
	bodystart = "unkownBodyStart";
	bodyend = "unkownBodyEnd";
	return_type = "unkownFunctionReturnType";
	argsstring = "unkownFunctionArgs";
	params = [];
	callers = [];
	callees = [];
	file = file
      }
    in
    v

  method parse_fct_in_file (record_fullname:string) (json_filepath:string) : Callgraph_t.record option =

    let dirpath : string = Common.read_before_last '/' json_filepath in
    let filename : string = Common.read_after_last '/' 1 json_filepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
    let json : Yojson.Basic.json = self#read_json_file jsoname_file in
    let content : string = Yojson.Basic.to_string json in
    (* Printf.printf "Read %s content is:\n %s: \n" filename content; *)
    (* Printf.printf "atdgen parsed json file is :\n"; *)
    (* Use the atdgen JSON parser *)
    let file : Callgraph_t.file = Callgraph_j.file_of_string content in
    (* print_endline (Callgraph_j.string_of_file file); *)
    
    (* Parse the json functions contained in the current file *)
    (match file.records with
     | None -> None
     | Some records ->

	(* Look for the function "record_fullname" among all the functions defined in file *)
	try
	  (
  	    Some (
	      List.find
  	      (
  		fun (r:Callgraph_t.record) -> String.compare record_fullname r.fullname == 0
	      )
	      records)
	  )
	with
	  Not_found -> None
    )

  method callees_register_function_call (call:string) : unit =
    
    callees_calls_table <- Calls.add call true callees_calls_table

  method callees_registered_as_function_call (call:string) : bool =

    try
      Calls.find call callees_calls_table
    with
      Not_found -> false

  method callers_register_function_call (call:string) : unit =
    
    callers_calls_table <- Calls.add call true callers_calls_table

  method callers_registered_as_function_call (call:string) : bool =

    try
      Calls.find call callers_calls_table
    with
      Not_found -> false

  method register_function_callee (fct_sign:string) : unit =
    
    callees_table <- Callees.add fct_sign true callees_table

  method registered_as_function_callee (fct_sign:string) : bool =

    try
      Callees.find fct_sign callees_table
    with
      Not_found -> false

  method register_function_caller (fct_sign:string) : unit =
    
    callers_table <- Callers.add fct_sign true callers_table

  method registered_as_function_caller (fct_sign:string) : bool =

    try
      Callers.find fct_sign callers_table
    with
      Not_found -> false

  method parse_function_and_callees (fct_sign:string) (json_file:string) 
				    (gcaller_sign:string) (gcaller_v:Graph_func.function_decl option) 
	 : Graph_func.function_decl option =

    (* Printf.printf "DEBUG: parse_function_and_callees \"%s\" \"%s\" \"%s\"\n" fct_sign json_file gcaller_sign; *)

    (* Parse current record *)
    let record = self#parse_fct_in_file fct_sign json_file in
    
    (match record with
     | None -> 
	Printf.printf "WARNING: no function found in file \"%s\" with signature=\"%s\" !\n" 
		      json_file fct_sign;
	None

     | Some record -> 
	(
	  let vcaller : Graph_func.function_decl = self#dump_fct record.fullname json_file in
	  gfct_callees <- Graph_func.G.add_vertex gfct_callees vcaller;

	  let call : string = String.concat "" [ gcaller_sign; " -> "; fct_sign ]
	  in

	  if (self#registered_as_function_callee fct_sign)
	     && (self#callees_registered_as_function_call call) then
	    (
	      Printf.printf "WARNING: callee cycle detected including function \"%s\"\n" fct_sign;
	      (match gcaller_v with
	      | None -> raise Internal_Error_1
	      | Some gcaller -> 
		 gfct_callees <- Graph_func.G.add_edge_e gfct_callees (Graph_func.G.E.create gcaller "cycle" vcaller)
	      );
	      None
	    )
	  else
	    (
	      if not(self#callees_registered_as_function_call call) then
		self#callees_register_function_call call;

	      if not(self#registered_as_function_callee fct_sign) then
		(
		  self#register_function_callee fct_sign;
		  
		  (* Parse child classes *)
		  (match record.inherited with
		   | None -> ()
		   | Some inherited ->
		      Printf.printf "Parse inherited classes of class \"%s\"\n" record.fullname;
		      List.iter
			( fun (i:Callgraph_t.inheritance) -> 

			  (match i.record with
			  | "unknownClassDef" -> 
			    (
			      Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
			      Printf.printf "WARNING: Unable to visit unknown base class: %s\n" i.record;
			      Printf.printf "class name is: %s\n" record.fullname;
			      Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
			      let loc : string list = Str.split_delim (Str.regexp ":") i.decl in
			      let file = 
				(match loc with
				| [ file; _ ] ->  file
				| _ -> raise Internal_Error_2
				)
			      in
			      let vcallee : Graph_func.function_decl = self#dump_fct i.record file in
			      gfct_callees <- Graph_func.G.add_edge_e gfct_callees (Graph_func.G.E.create vcaller "external" vcallee)
			    )
			  | _ ->
			    (
			      let loc : string list = Str.split_delim (Str.regexp ":") i.decl in
			      let file = 
				(match loc with
				| [ file; _ ] ->  file
				| _ -> raise Internal_Error_2
				)
			      in
			      let vcallee = self#parse_function_and_callees (i.record) (file) (fct_sign) (Some vcaller) in
			      (match vcallee with
			      (* | None -> raise Internal_Error *)
			      | None -> () (* cycle probably detected *)
			      | Some vcallee ->
				gfct_callees <- Graph_func.G.add_edge_e gfct_callees (Graph_func.G.E.create vcaller "external" vcallee)
			      )
			    )
			  )
			)
			inherited
		  )
		);
	      Some vcaller
	    )
	)
    )

  method parse_function_and_callers (record_fullname:string) (json_file:string) 
				    (gcallee_sign:string) (gcallee_v:Graph_func.function_decl option) 
	 : Graph_func.function_decl option =

    (* Printf.printf "DEBUG: parse_function_and_callers \"%s\" \"%s\" \"%s\"\n" record_fullname json_file gcallee_sign; *)

    (* Parse current function *)
    let record = self#parse_fct_in_file record_fullname json_file in
    
    (match record with
     | None -> 
	Printf.printf "WARNING: no function found in file \"%s\" with signature=\"%s\" !\n" 
		      json_file record_fullname;
	None

     | Some record -> 
	(
	  let vcallee : Graph_func.function_decl = self#dump_fct record.fullname json_file in
	  gfct_callers <- Graph_func.G.add_vertex gfct_callers vcallee;

	  let call : string = String.concat "" [ record_fullname; " -> "; gcallee_sign ]
	  in

	  if (self#registered_as_function_caller record_fullname)
	     && (self#callers_registered_as_function_call call) then
	    (
	      Printf.printf "WARNING: caller cycle detected including function \"%s\"\n" record_fullname;
	      (match gcallee_v with
	       | None -> raise Internal_Error_3
	       | Some gcallee -> 
		  gfct_callers <- Graph_func.G.add_edge_e gfct_callers (Graph_func.G.E.create vcallee "cycle" gcallee)
	      );
	      None
	    )
	  else
	    (
	      if not(self#callers_registered_as_function_call call) then
		self#callers_register_function_call call;

	      if not(self#registered_as_function_caller record_fullname) then
		(
		  self#register_function_caller record_fullname;

		  if self#registered_as_function_callee record_fullname then
		    (
		      gfct_c2b <- Graph_func.G.add_vertex gfct_c2b vcallee;
		    );

		  (* Parse base classes *)
		  (match record.inherits with
		  | None -> ()
		  | Some inherits ->
		      Printf.printf "Parse base classes...\n";
		      List.iter
			( fun (i:Callgraph_t.inheritance) -> 

			  (match i.decl with
			  | "unlinkedExtCaller" -> 
			      (
				Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
				Printf.printf "Unable to visit unlinked extcaller: %s\n" i.record;
				Printf.printf "Current caller is: %s\n" record.fullname;
				Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
			      )
			  | _ ->
			    (
			      let file = 
				let loc : string list = Str.split_delim (Str.regexp ":") i.decl in
				(match loc with
				| [ file; _ ] ->  file
				| _ -> 
				  (
				    Printf.printf "HBDBG: i.def: %s" i.decl;
				    raise Internal_Error_5
				  )
				)
			      in
			      let vcaller = self#parse_function_and_callers i.record file record_fullname (Some vcallee) in
			      (match vcaller with
			      | None -> raise Internal_Error_6 (* cycle probably detected *)
			      | Some vcaller ->
				(
				  gfct_callers <- Graph_func.G.add_edge_e gfct_callers (Graph_func.G.E.create vcaller "external" vcallee);
				  
				  if (self#registered_as_function_callee record_fullname) &&
				    (self#registered_as_function_callee i.record)
				  then
				    (
				      gfct_c2b <- Graph_func.G.add_edge_e gfct_c2b (Graph_func.G.E.create vcaller "external" vcallee);
				    )
				)
			      )
			    )
			  )
			)
			inherits
		  )
		);
	      Some vcallee
	    )
	)
    )
	
  (* method parse_json_dir (rootdir:string) : unit = *)

  (*   let jsoname_dir = String.concat "" [ rootdir; ".dir.callers.json" ] in *)
  (*   (\* let jsoname_dir = String.concat "" [ rootdir; ".dir.callers.json" ] in *\) *)
  (*   let json : Yojson.Basic.json = self#read_json_file jsoname_dir in *)
  (*   let content : string = Yojson.Basic.to_string json in *)
  (*   Printf.printf "Read directory content is:\n %s: \n" content; *)

  (*   Printf.printf "atdgen parsed json directory is :\n"; *)
  (*   (\* Use the atdgen JSON parser *\) *)
  (*   let dir : Callgraph_t.dir = Callgraph_j.dir_of_string content in *)
  (*   print_endline (Callgraph_j.string_of_dir dir); *)

  (*   (\* Parse the json files contained in the current directory *\) *)
  (*   (match dir.files with *)
  (*    | None -> () *)
  (*    | Some files -> List.iter ( fun f -> self#parse_json_file f ) files *)
  (*   ) *)

  method output_function_callers (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file gfct_callers

  method output_function_callees (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file gfct_callees

  method output_function_c2b (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file gfct_c2b

end

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("direction" %: string)
  +> anon ("record1_json" %: string)
  +> anon ("record1_name" %: string)
  +> anon (maybe(sequence("other" %: string)))

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Parses base and/or child classes from callers's generated json files (direction=base|child|c2b)"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun direction record1_json record1_name other () -> 
      
      let parser = new function_callers_json_parser record1_name record1_json other in

      try
      (
	match direction with

	 | "base" -> 
	    (
	      let _ = parser#parse_function_and_callers (record1_name) (record1_json) "callers" None in
	      parser#output_function_callers (Printf.sprintf "%s.base.classes.gen.dot" record1_name)
	    )

	 | "child" -> 
	    (
	      let _ = parser#parse_function_and_callees (record1_name) (record1_json) "callees" None in
	      parser#output_function_callees (Printf.sprintf "%s.child.classes.gen.dot" record1_name)
	    )

	 | "c2b" -> 
	    (match other with
	     | Some [record2_json; record2_name; "files"]
	     | Some [record2_json; record2_name ] ->
		(
		  Printf.printf "1) First retrieve all the callees of the caller function \"%s\ defined in file \"%s\"\n" record1_name record1_json;
		  let _ = parser#parse_function_and_callees (record1_name) (record1_json) "callees" None in
		  Printf.printf "2) Then retrieve all the callers of the callee function \"%s\ defined in file \"%s\"\n" record2_name record2_json;
		  let _ = parser#parse_function_and_callers (record2_name) (record2_json) "callers" None in 
		  parser#output_function_callees (Printf.sprintf "%s.child.classes.gen.dot" record1_name);
		  parser#output_function_callers (Printf.sprintf "%s.base.classes.gen.dot" record2_name);
		  Printf.printf "3) Now we can retrieve all the paths between caller function \"%s\" and callee function \"%s\"\n" record1_name record2_name;
		  parser#output_function_c2b (Printf.sprintf "%s.%s.c2b.classes.gen.dot" record1_name record2_name)
		)
	     | None
	     | _ -> 
		(
		  Printf.printf "ERROR: \"c2b\" direction requires \"id\", \"sign\" and \"json\" file path of both caller record1 and callee record2 !\n";
		  raise Usage_Error
		)
	    )
	 | _ -> 
	    (
	      Printf.printf "ERROR: unsupported direction \"%s\"" direction;
	      raise Internal_Error_7
	    )
      )
      with
	File_Not_Found -> raise Unexpected_Error_3
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package yojson -tag thread classes_to_dot.native" *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package ocamlgraph -tag thread classes_to_dot.native" *)
(* End: *)
