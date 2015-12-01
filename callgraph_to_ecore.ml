(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   KTD SCIS 2014-2015                                                       *)
(*   Use Case Legacy TOSA                                                     *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)
(* forked from callers_to_dot.ml *)

exception NOT_FOUND_LOCAL_FUNCTION
exception UNSUPPORTED_RECURSIVE_FUNCTION

type fcg_vertex = { sign:string; vertex:Graph_func.function_decl };;

(* Dot function callgraph *)
class function_callgraph_to_dot (callgraph_jsonfile:string)
				(other:string list option)
  = object(self)

  inherit Function_callgraph.function_callgraph callgraph_jsonfile other

  val mutable fcg_dot_graph : Graph_func.G.t = Graph_func.G.empty

  val mutable fcg_dot_nodes : fcg_vertex list = []

  method output_dot_fcg (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file fcg_dot_graph

  method rootdir_to_dot () = 
    
    (match json_rootdir with
    | None -> ()
    | Some rootdir -> self#dir_to_dot rootdir ""
    )

  method dir_to_dot (dir:Callgraph_t.dir) (path:string) =
    
    Printf.printf "callgraph_to_dot.ml::INFO::callgraph_dir_to_dot: dir=\"%s\"...\n" dir.name;

    let dirpath = Printf.sprintf "%s/%s" path dir.name in

    (* Parse files located in dir *)
    (match dir.files with
     | None -> ()
     | Some files -> 
	List.iter
	  ( 
	    fun (file:Callgraph_t.file) ->  self#file_to_dot file dirpath
	  )
	  files
    );

    (* Parse children directories *)
    (match dir.children with
     | None -> ()
     | Some children -> 
	List.iter
	  ( 
	    fun (child:Callgraph_t.dir) ->  self#dir_to_dot child dirpath
	  )
	  children
    )

  method file_get_function (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction option =

    let search_fct_def = self#file_get_defined_function file fct_sign in

    (match search_fct_def with
     | None -> self#file_get_declared_function file fct_sign
     | Some _ -> search_fct_def
    )

  method file_get_declared_function (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction option =

    (* Parse functions declared in file *)
    (match file.declared with
     | None -> None
     | Some declared -> 
	try
	  let found_fct : Callgraph_t.fonction =
	    List.find
	      ( 
		fun (fct_decl:Callgraph_t.fonction) -> (String.compare fct_sign fct_decl.sign == 0)
	      )
	      declared
	  in
	  Printf.printf "class function_callgraph_to_dot::file_get_declared_function::FOUND_DECL_FCT:: declaration found for function \"%s\" in file \"%s\" !\n" fct_sign file.name;
	  Some found_fct
	with
	  Not_found -> 
	  (
	    Printf.printf "class function_callgraph_to_dot::file_get_declared_function::NOT_FOUND_DECL_FCT:: no declaration found for function \"%s\" in file \"%s\" !\n" fct_sign file.name;
	    None
	  )
    )

  method file_get_defined_function (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction option =

    (* Parse functions defined in file *)
    (match file.defined with
     | None -> None
     | Some defined -> 
	try
	  let found_fct : Callgraph_t.fonction =
	    List.find
	      ( 
		fun (fct_decl:Callgraph_t.fonction) -> (String.compare fct_sign fct_decl.sign == 0)
	      )
	      defined
	  in
	  Printf.printf "class function_callgraph_to_dot::file_get_defined_function::FOUND_DEF_FCT:: definition found for function \"%s\" in file \"%s\" !\n" fct_sign file.name;
	  Some found_fct
	with
	  Not_found -> 
	  (
	    Printf.printf "class function_callgraph_to_dot::file_get_defined_function::NOT_FOUND_DEF_FCT:: no definition found for function \"%s\" in file \"%s\" !\n" fct_sign file.name;
	    None
	  )
    )

  method file_to_dot (file:Callgraph_t.file) (path:string) = 

    Printf.printf "callgraph_to_dot.ml::INFO::callgraph_file_to_dot: name=\"%s\"...\n" file.name;

    let filepath = Printf.sprintf "%s/%s" path file.name in

    (* Parse functions declared in file *)
    (match file.declared with
     | None -> ()
     | Some declared -> 
	List.iter
	  ( 
	    fun (fct_decl:Callgraph_t.fonction) ->  self#function_to_dot fct_decl filepath
	  )
	  declared
    );

    (* Parse functions defined in file *)
    (match file.defined with
     | None -> ()
     | Some defined -> 
	List.iter
	  ( 
	    fun (fct_decl:Callgraph_t.fonction) ->  self#function_to_dot fct_decl filepath
	  )
	  defined
    )

  method function_to_dot (fonction:Callgraph_t.fonction) (filepath:string) = 

    Printf.printf "class function_callgraph_to_dot::function_to_dot::INFO: sign=\"%s\"...\n" fonction.sign;

    let vfct = self#function_create_dot_vertex fonction.sign filepath in

    (* Parse local function calls *)
    (match fonction.locallees with
     | None -> ()
     | Some locallees ->
    	List.iter
    	  (
    	    fun (locallee:string) ->
	    (
	      (* let (callee:Callgraph_t.fonction) = *)
	      (* 	(match self#file_get_function file locallee with *)
	      (* 	   | None ->  *)
	      (* 	      ( *)
	      (* 		Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n"; *)
	      (* 		Printf.printf "callgraph_to_dot.ml:ERROR: Not found local called function \"%s\" in file \"%s\"" locallee file.name; *)
	      (* 		Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n"; *)
	      (* 		raise NOT_FOUND_LOCAL_FUNCTION *)
	      (* 	      ) *)
	      (* 	   | Some fct -> fct *)
	      (* 	) *)
	      (* in *)
	      (* let vcal = self#function_get_dot_vertex callee.sign in *)
	      let vcal = self#function_get_dot_vertex locallee in
              let vcallee : Graph_func.function_decl = 
		(match vcal with
		 | None -> 
		    ( 
		      self#function_create_dot_vertex locallee filepath
		    )
		 | Some vcal -> vcal)
	      in
	      self#locallee_to_dot vfct vcallee
	    )
    	  )
    	  locallees
    );

    (* Parse external function calls *)
    (match fonction.extcallees with
     | None -> ()
     | Some extcallees ->
    	List.iter
    	  (
    	    fun (extcallee:string) ->
	    (
	      let vcal = self#function_get_dot_vertex extcallee in
              let vcallee : Graph_func.function_decl = 
		(match vcal with
		 | None -> 
		    ( 
		      self#function_create_dot_vertex extcallee filepath
		    )
		 | Some vcal -> vcal)
	      in
	      self#extcallee_to_dot vfct vcallee
	    )
    	  )
    	  extcallees
    )

  method function_get_dot_vertex (fct_sign:string) : Graph_func.function_decl option =

    try
      (
	let vertex : fcg_vertex =
	  List.find
	    ( 
	      fun (vertex:fcg_vertex) -> 
	      (String.compare fct_sign vertex.sign == 0)
	    )
	    fcg_dot_nodes
	in
	(* let vfct : Graph_func.function_decl = Graph_func.G.find_vertex fcg_dot_graph fct_sign in *)
	Printf.printf "function_get_dot_vertex::FOUND_VERTEX:: a vertex does already exist for function \"%s\", so use it directly !\n" fct_sign;
	Some vertex.vertex
      )
    with
      Not_found -> 
      (
	Printf.printf "function_get_dot_vertex::NOT_FOUND_VERTEX:: no vertex found for function \"%s\"!\n" fct_sign;
	None
      )

  (* adapted from class function_callers_json_parser::dump_fct defined in file function_callgraph.ml *)
  method function_create_dot_vertex (fct_sign:string) (fct_file:string) : Graph_func.function_decl =

    (* Replace all / by _ in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\/") "_" fct_file in

    (* Replace all '.' by '_' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\.") "_" fpath in

    (* Replace all '-' by '_' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\-") "_" fpath in

    (* Replace all '+' by 'p' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\+") "p" fpath in

    let filename : string = Filename.basename fct_file in

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
    let vfct : Graph_func.function_decl =
      {
	id = Printf.sprintf "\"%s\"" fct_sign;
	name = Printf.sprintf "\"%s\"" fct_sign;
	file_path = fct_file;
	line = "unknownFunctionLine";
	bodyfile = fct_file;
	bodystart = "unknownBodyStart";
	bodyend = "unknownBodyEnd";
	return_type = "unknownFunctionReturnType";
	argsstring = "unknownFunctionArgs";
	params = [];
	callers = [];
	callees = [];
	file = file
      }
    in

    if Graph_func.G.mem_vertex fcg_dot_graph vfct then
      (
	Printf.printf "function_to_dot::EXISTING_VERTEX:: a vertex does already exist for function \"%s\", so do not duplicate it !\n" fct_sign
      )
    else
      (
	Printf.printf "function_to_dot::CREATE_VERTEX:: function node \"%s\" does not yet exist, so we add it !\n" fct_sign;
	let (rfct:fcg_vertex) = { sign=fct_sign; vertex=vfct } in
	(match fcg_dot_nodes with
	| [] -> rfct::[]
	| l -> rfct::l
	);
	fcg_dot_graph <- Graph_func.G.add_vertex fcg_dot_graph vfct
      );
    vfct
      
  method locallee_to_dot (vcaller:Graph_func.function_decl) (vcallee:Graph_func.function_decl) : unit =

    (* raise an xception in case of a recursive function call *)
    if String.compare vcaller.name vcallee.name == 0 then
      (
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	Printf.printf "callgraph_to_dot.ml:ERROR: unsupported recursive function call %s->%s\n" vcaller.name vcallee.name;
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	raise UNSUPPORTED_RECURSIVE_FUNCTION
      );
    
    if Graph_func.G.mem_edge fcg_dot_graph vcaller vcallee then
      (
	Printf.printf "locallee_to_dot::EXISTING_EDGE:: an edge does already exist for local call %s->%s, so do not duplicate it !\n" 
		      vcaller.name vcallee.name
      )
    else
      (
	Printf.printf "locallee_to_dot::CREATE_EDGE:: local call %s->%s does not yet exist, so we add it !\n" 
		      vcaller.name vcallee.name;
	fcg_dot_graph <- Graph_func.G.add_edge_e fcg_dot_graph (Graph_func.G.E.create vcaller "internal" vcallee)
      )

  (* copy/paste + modifs from method "locallee_to_dot" *)
  method extcallee_to_dot (vcaller:Graph_func.function_decl) (vcallee:Graph_func.function_decl) : unit =

    (* raise an xception in case of a recursive function call *)
    if String.compare vcaller.name vcallee.name == 0 then
      (
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	Printf.printf "callgraph_to_dot.ml:ERROR: unsupported recursive function call %s->%s\n" vcaller.name vcallee.name;
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	raise UNSUPPORTED_RECURSIVE_FUNCTION
      );
    
    if Graph_func.G.mem_edge fcg_dot_graph vcaller vcallee then
      (
	Printf.printf "extcallee_to_dot::EXISTING_EDGE:: an edge does already exist for external call %s->%s, so do not duplicate it !\n" 
		      vcaller.name vcallee.name
      )
    else
      (
	Printf.printf "extcallee_to_dot::CREATE_EDGE:: external call %s->%s does not yet exist, so we add it !\n" 
		      vcaller.name vcallee.name;
	fcg_dot_graph <- Graph_func.G.add_edge_e fcg_dot_graph (Graph_func.G.E.create vcaller "external" vcallee)
      )

end
;;

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("callgraph_jsonfilepath" %: string)
  +> anon (maybe(sequence("other" %: string)))

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Dot backend for callgraph's json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun callgraph_jsonfilepath other () -> 
      
      let dot_filename : String.t  = Printf.sprintf "%s.dot" callgraph_jsonfilepath in

      let dot_fcg : function_callgraph_to_dot = new function_callgraph_to_dot callgraph_jsonfilepath other in

      dot_fcg#parse_jsonfile();

      dot_fcg#rootdir_to_dot();

      dot_fcg#output_dot_fcg dot_filename
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package ocamlgraph -tag thread callgraph_to_dot.native" *)
(* End: *)
