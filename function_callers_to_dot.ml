(* tangled from ~/org/technology/data/data.org *)
(* adapted from /media/users/balp/tests/data/interchange/json/test_random_event/test_yojson_read.ml *)

(* open Core.Std *)

exception Internal_Error
exception Unexpected_Case
exception Usage_Error
(* exception TBC *)

module Callers = Map.Make(String);;
module Callees = Map.Make(String);;
module Calls = Map.Make(String);;

class function_callers_json_parser 
	(callee_id:string) 
	(callee_signature:string)
	(callee_json_filepath:string)
	(other:string list option)
	(* (root_directory:string)  *)
  = object(self)

  val callee_id : string = callee_id

  val callee_sign : string = callee_signature

  val callee_file_path : string = callee_json_filepath

  val show_files : bool = 

    (match other with
    | None -> false
    | Some args -> 
       (match args with
	| ["files"]
	| ["files"; _] ->
	   (
	     true
	   )
	| _  -> false
       )
    )

  (* Function callers graph *)
  val mutable gfct_callers : Graph_func.G.t = Graph_func.G.empty

  (* Function callees graph *)
  val mutable gfct_callees : Graph_func.G.t = Graph_func.G.empty

  (* Function caller to callee  graph *)
  val mutable gfct_c2c : Graph_func.G.t = Graph_func.G.empty

  val mutable callees_table = Callees.empty
  val mutable callers_table = Callees.empty

  val mutable callees_calls_table = Calls.empty
  val mutable callers_calls_table = Calls.empty

  method read_json_file (filename:string) : Yojson.Basic.json =

    Printf.printf "In_channel read file %s...\n" filename;
    (* Read JSON file into an OCaml string *)
    let buf = Core.Std.In_channel.read_all filename in           
    (* Use the string JSON constructor *)
    let json1 = Yojson.Basic.from_string buf in
    json1

  method dump_fct (fct:Callgraph_t.fct) (json_file:string) : Graph_func.function_decl =

    (* Replace all / by _ in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\/") "_" json_file in

    (* Replace all '.' by '_' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\.") "_" fpath in

    let file : Graph.Graphviz.DotAttributes.subgraph option = 

      if show_files then
	Some
    	  {
    	    sg_name = fpath;
    	    sg_attributes = [ `Label json_file ];
    	    (* sg_parent = Some class_memberdef_factory.file.sg_name; *)
    	    sg_parent = None;
    	  }
      else
	None
    in
    let v : Graph_func.function_decl =
      {
	id = Printf.sprintf "\"%s\"" fct.sign;
	name = Printf.sprintf "\"%s\"" fct.sign;
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

  method parse_fct_in_file (fct_sign:string) (json_filepath:string) : Callgraph_t.fct option =

    let dirpath : string = Common.read_before_last '/' json_filepath in
    let filename : string = Common.read_after_last '/' 1 json_filepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
    let json : Yojson.Basic.json = self#read_json_file jsoname_file in
    let content : string = Yojson.Basic.to_string json in
    Printf.printf "Read %s content is:\n %s: \n" filename content;
    Printf.printf "atdgen parsed json file is :\n";
    (* Use the atdgen JSON parser *)
    let file : Callgraph_t.file = Callgraph_j.file_of_string content in
    print_endline (Callgraph_j.string_of_file file);
    
    (* Parse the json functions contained in the current file *)
    (match file.defined with
     | None -> None
     | Some fcts ->

	(* Look for the function "fct_sign" among all the functions defined in file *)
	try
	  (
  	    Some (
	      List.find
  	      (
  		fun (f:Callgraph_t.fct) -> String.compare fct_sign f.sign == 0
	      )
	      fcts )
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

    (* Parse current function *)
    let fct = self#parse_fct_in_file fct_sign json_file in
    
    (match fct with
     | None -> 
	Printf.printf "WARNING: no function found in file \"%s\" with signature=\"%s\" !\n" 
		      json_file fct_sign;
	None

     | Some fct -> 
	(
	  let vcaller : Graph_func.function_decl = self#dump_fct fct json_file in
	  gfct_callees <- Graph_func.G.add_vertex gfct_callees vcaller;

	  let call : string = String.concat "" [ gcaller_sign; " -> "; fct_sign ]
	  in

	  if (self#registered_as_function_callee fct_sign)
	     && (self#callees_registered_as_function_call call) then
	    (
	      Printf.printf "WARNING: callee cycle detected including function \"%s\"\n" fct_sign;
	      (match gcaller_v with
	      | None -> raise Internal_Error
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

		  (* Parse local callees *)
		  (match fct.locallees with
		   | None -> ()
		   | Some locallees ->
		      Printf.printf "Parse local callees...\n";
		      List.iter
			( fun (f:string) -> 
			  let vcallee = self#parse_function_and_callees f json_file fct_sign (Some vcaller) in
			  (match vcallee with
			   | None -> () (* cycle probably detected *)
			   | Some vcallee ->
			      gfct_callees <- Graph_func.G.add_edge_e gfct_callees (Graph_func.G.E.create vcaller "internal" vcallee)
			  )
			)
			locallees
		  );

		  (* Parse remote callees *)
		  (match fct.extcallees with
		   | None -> ()
		   | Some extcallees ->
		      Printf.printf "Parse remote callees...\n";
		      List.iter
			( fun (f:Callgraph_t.extfct) -> 
			  let loc : string list = Str.split_delim (Str.regexp ":") f.def in
			  let file = 
			    (match loc with
			    | [ file; _ ] ->  file
			    | _ -> raise Unexpected_Case)
			  in
			  let vcallee = self#parse_function_and_callees f.sign file fct_sign (Some vcaller) in
			  (match vcallee with
			   (* | None -> raise Internal_Error *)
			   | None -> () (* cycle probably detected *)
			   | Some vcallee ->
			      gfct_callees <- Graph_func.G.add_edge_e gfct_callees (Graph_func.G.E.create vcaller "external" vcallee)
			  )
			)
			extcallees
		  )
		);
	      Some vcaller
	    )
	)
    )

  method parse_function_and_callers (fct_sign:string) (json_file:string) 
				    (gcallee_sign:string) (gcallee_v:Graph_func.function_decl option) 
	 : Graph_func.function_decl option =

    (* Parse current function *)
    let fct = self#parse_fct_in_file fct_sign json_file in
    
    (match fct with
     | None -> 
	Printf.printf "WARNING: no function found in file \"%s\" with signature=\"%s\" !\n" 
		      json_file fct_sign;
	None

     | Some fct -> 
	(
	  let vcallee : Graph_func.function_decl = self#dump_fct fct json_file in
	  gfct_callers <- Graph_func.G.add_vertex gfct_callers vcallee;

	  let call : string = String.concat "" [ fct_sign; " -> "; gcallee_sign ]
	  in

	  if (self#registered_as_function_caller fct_sign)
	     && (self#callers_registered_as_function_call call) then
	    (
	      Printf.printf "WARNING: caller cycle detected including function \"%s\"\n" fct_sign;
	      (match gcallee_v with
	       | None -> raise Internal_Error
	       | Some gcallee -> 
		  gfct_callers <- Graph_func.G.add_edge_e gfct_callers (Graph_func.G.E.create vcallee "cycle" gcallee)
	      );
	      None
	    )
	  else
	    (
	      if not(self#callers_registered_as_function_call call) then
		self#callers_register_function_call call;

	      if not(self#registered_as_function_caller fct_sign) then
		(
		  self#register_function_caller fct_sign;

		  if self#registered_as_function_callee fct_sign then
		    (
		      gfct_c2c <- Graph_func.G.add_vertex gfct_c2c vcallee;
		    );
		  
		  (* Parse local callers *)
		  (match fct.locallers with
		   | None -> ()
		   | Some locallers ->
		      Printf.printf "Parse local callers...\n";
		      List.iter
			( fun (f:string) -> 
			  let vcaller = self#parse_function_and_callers f json_file fct_sign (Some vcallee) in
			  (match vcaller with
			   | None -> raise Internal_Error
			   (* | None -> () (\* cycle probably detected *\) *)
			   | Some vcaller ->
			      (
				gfct_callers <- Graph_func.G.add_edge_e gfct_callers (Graph_func.G.E.create vcaller "internal" vcallee);

				if (self#registered_as_function_callee fct_sign) &&
				     (self#registered_as_function_callee f)	 
				then
				  (
				    gfct_c2c <- Graph_func.G.add_edge_e gfct_c2c (Graph_func.G.E.create vcaller "internal" vcallee);
				  )
			      )
			  )
			)
			locallers
		  );

		  (* Parse remote callers *)
		  (match fct.extcallers with
		   | None -> ()
		   | Some extcallers ->
		      Printf.printf "Parse remote callers...\n";
		      List.iter
			( fun (f:Callgraph_t.extfct) -> 
			  let file = 
			    let loc : string list = Str.split_delim (Str.regexp ":") f.def in
			    (match loc with
			    | [ file; _ ] ->  file
			    | _ -> raise Unexpected_Case)
			  in
			  let vcaller = self#parse_function_and_callers f.sign file fct_sign (Some vcallee) in
			  (match vcaller with
			   | None -> raise Internal_Error
			   (* | None -> () (\* cycle probably detected *\) *)
			   | Some vcaller ->
			      (
				gfct_callers <- Graph_func.G.add_edge_e gfct_callers (Graph_func.G.E.create vcaller "external" vcallee);
				
				if (self#registered_as_function_callee fct_sign) &&
				     (self#registered_as_function_callee f.sign)
				then
				  (
				    gfct_c2c <- Graph_func.G.add_edge_e gfct_c2c (Graph_func.G.E.create vcaller "external" vcallee);
				  )
			      )
			  )
			)
			extcallers
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

  method output_function_c2c (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file gfct_c2c

end

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("direction" %: string)
  +> anon ("fct1_id" %: string)
  +> anon ("fct1_sign" %: string)
  +> anon ("fct1_json" %: string)
  +> anon (maybe(sequence("other" %: string)))

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Parses function's callers and/or callees from callers's generated json files (direction=callers|callees|c2c)"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun direction fct1_id fct1_sign fct1_json other () -> 
      
      let parser = new function_callers_json_parser fct1_id fct1_sign fct1_json other in

      (match direction with

	 | "callers" -> 
	    (
	      let _ = parser#parse_function_and_callers fct1_sign fct1_json "callers" None in
	      parser#output_function_callers (Printf.sprintf "%s.fct.callers.gen.dot" fct1_id)
	    )

	 | "callees" -> 
	    (
	      let _ = parser#parse_function_and_callees fct1_sign fct1_json "callees" None in
	      parser#output_function_callees (Printf.sprintf "%s.fct.callees.gen.dot" fct1_id)
	    )

	 | "c2c" -> 
	    (match other with
	     | Some ["files"; fct2_id; fct2_sign; fct2_json]
	     | Some [fct2_id; fct2_sign; fct2_json] ->
		(
		  let _ = parser#parse_function_and_callees fct1_sign fct1_json "callees" None in
		  let _ = parser#parse_function_and_callers fct2_sign fct2_json "callers" None in 
		  parser#output_function_callees (Printf.sprintf "%s.fct.callees.gen.dot" fct1_id);
		  parser#output_function_callers (Printf.sprintf "%s.fct.callers.gen.dot" fct2_id);
		  parser#output_function_c2c (Printf.sprintf "%s.%s.c2c.gen.dot" fct1_id fct2_id)
		)
	     | None
	     | _ -> 
		(
		  Printf.printf "ERROR: \"c2c\" direction requires \"id\", \"sign\" and \"json\" file path of both caller fct1 and callee fct2 !\n";
		  raise Usage_Error
		)
	    )
	 | _ -> 
	    (
	      Printf.printf "ERROR: unsupported direction \"%s\"" direction;
	      raise Internal_Error
	    )
      )
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package yojson -tag thread function_callers_to_dot.native" *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package ocamlgraph -tag thread function_callers_to_dot.native" *)
(* End: *)
