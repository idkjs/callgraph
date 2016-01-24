(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

type fcg_vertex = { sign:string; vertex:Graph_func.function_decl };;

(* Dot function callgraph *)
class function_callgraph_to_dot (other:string list option)
  = object(self)

  inherit Function_callgraph.function_callgraph

  val mutable fcg_dot_graph : Graph_func.G.t = Graph_func.G.empty

  val mutable fcg_dot_nodes : fcg_vertex list = []

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

  method get_fcg_dot_nodes_number : int =

    let nb_dot_vertices : int = List.length fcg_dot_nodes in
    Printf.printf "c2d.get_fcg_dot_nodes_number:DEBUG: current number of dot vertices is %d\n" nb_dot_vertices;
    nb_dot_vertices

  method output_dot_fcg (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file fcg_dot_graph

  method rootdir_to_dot () =

    (match json_rootdir with
    | None -> ()
    | Some rootdir ->
       (* Parse directories *)
       (match rootdir.dir with
        | None -> ()
        | Some dirs ->
	   List.iter
	     (
	       fun (dir:Callgraph_t.dir) -> self#dir_to_dot dir dir.path
	     )
	     dirs
       )
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
     | Some children -> ()
	(* List.iter *)
	(*   ( *)
	(*     fun (child:Callgraph_t.dir) ->  self#dir_to_dot child dirpath *)
	(*   ) *)
	(*   children *)
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
	    fun (fct_decl:Callgraph_t.fonction_decl) ->  self#function_decl_to_dot fct_decl filepath
	  )
	  declared
    );

    (* Parse functions defined in file *)
    (match file.defined with
     | None -> ()
     | Some defined ->
	List.iter
	  (
	    fun (fct_decl:Callgraph_t.fonction_def) ->  self#function_def_to_dot fct_decl filepath
	  )
	  defined
    )

  method function_decl_to_dot (fonction:Callgraph_t.fonction_decl) (filepath:string) : unit =

    Printf.printf "c2d.function_decl_to_dot:BEGIN: fct_sign=\"%s\", file=%s\n" fonction.sign filepath;

    let fct_virtuality =
      (match fonction.virtuality with
       | None -> "no"
       | Some v -> v
      )
    in
    let vfct = self#function_create_dot_vertex fonction.sign fct_virtuality filepath in

    (* Parse local function callers *)
    (match fonction.locallers with
     | None -> ()
     | Some locallers ->
    	List.iter
    	  (
    	    fun (localler:Callgraph_t.fct_ref) ->
	    (
	      let vcal = self#function_get_dot_vertex localler.sign in
              let vcaller : Graph_func.function_decl =
		(match vcal with
		 | None ->
		    (
		      self#function_create_dot_vertex localler.sign localler.virtuality filepath
		    )
		 | Some vcal -> vcal)
	      in
	      self#local_call_to_dot vcaller vfct
	    )
    	  )
    	  locallers
    );

    (* Parse external function callers *)
    (match fonction.extcallers with
     | None -> ()
     | Some extcallers ->
    	List.iter
    	  (
    	    fun (extcaller:Callgraph_t.extfct_ref) ->
	    (
	      let vcal = self#function_get_dot_vertex extcaller.sign in
              let vcaller : Graph_func.function_decl =
		(match vcal with
		 | None ->
		    (
		      self#function_create_dot_vertex extcaller.sign extcaller.virtuality extcaller.file
		    )
		 | Some vcal -> vcal)
	      in
	      self#external_call_to_dot vcaller vfct
	    )
    	  )
    	  extcallers
    );

     (* Parse virtual function redeclarations *)
    (match fonction.virtdecls with
     | None -> ()
     | Some virtdecls ->
    	List.iter
    	  (
    	    fun (virtdecl:Callgraph_t.fonction_decl) ->
	    (
	      let vredecl = self#function_get_dot_vertex virtdecl.sign in
              let vdef : Graph_func.function_decl =
		(match vredecl with
		 | None ->
		    (
                      let virtuality = Callers.fct_virtuality_option_to_string virtdecl.virtuality in
		      self#function_create_dot_vertex virtdecl.sign virtuality "c2d.function_decl_to_dot.virtdecls.file.TBC"
		    )
		 | Some vcal -> vcal)
	      in
	      self#virtual_call_to_dot vfct vdef
	    )
    	  )
    	  virtdecls
    );

     (* Parse virtual function callers *)
    (match fonction.virtcallers with
     | None -> ()
     | Some virtcallers ->
    	List.iter
    	  (
    	    fun (virtcaller:Callgraph_t.extfct_ref) ->
	    (
	      let vcal = self#function_get_dot_vertex virtcaller.sign in
              let vcaller : Graph_func.function_decl =
		(match vcal with
		 | None ->
		    (
		      self#function_create_dot_vertex virtcaller.sign virtcaller.virtuality virtcaller.file
		    )
		 | Some vcal -> vcal)
	      in
	      self#virtual_call_to_dot vcaller vfct
	    )
    	  )
    	  virtcallers
    )
 
  method function_def_to_dot (fonction:Callgraph_t.fonction_def) (filepath:string) : unit =

    Printf.printf "c2d.function_def_to_dot:BEGIN: fct_sign=\"%s\", file=%s\n" fonction.sign filepath;

    let fct_virtuality =
      (match fonction.virtuality with
       | None -> "no"
       | Some v -> v
      )
    in
    let vfct = self#function_create_dot_vertex fonction.sign fct_virtuality filepath in

    (* Parse local function callees *)
    (match fonction.locallees with
     | None -> ()
     | Some locallees ->
    	List.iter
    	  (
    	    fun (locallee:Callgraph_t.fct_ref) ->
	    (
	      let vcal = self#function_get_dot_vertex locallee.sign in
              let vcallee : Graph_func.function_decl =
		(match vcal with
		 | None ->
		    (
		      self#function_create_dot_vertex locallee.sign locallee.virtuality filepath
		    )
		 | Some vcal -> vcal)
	      in
	      self#local_call_to_dot vfct vcallee
	    )
    	  )
    	  locallees
    );

    (* Parse external function callees *)
    (match fonction.extcallees with
     | None -> ()
     | Some extcallees ->
    	List.iter
    	  (
    	    fun (extcallee:Callgraph_t.extfct_ref) ->
	    (
	      let vcal = self#function_get_dot_vertex extcallee.sign in
              let vcallee : Graph_func.function_decl =
		(match vcal with
		 | None ->
		    (
		      self#function_create_dot_vertex extcallee.sign extcallee.virtuality extcallee.file
		    )
		 | Some vcal -> vcal)
	      in
	      self#external_call_to_dot vfct vcallee
	    )
    	  )
    	  extcallees
    );

    (* Parse virtual function callees *)
    (match fonction.virtcallees with
     | None -> ()
     | Some virtcallees ->
    	List.iter
    	  (
    	    fun (virtcallee:Callgraph_t.extfct_ref) ->
	    (
	      let vcal = self#function_get_dot_vertex virtcallee.sign in
              let vcallee : Graph_func.function_decl =
		(match vcal with
		 | None ->
		    (
		      self#function_create_dot_vertex virtcallee.sign virtcallee.virtuality virtcallee.file
		    )
		 | Some vcal -> vcal)
	      in
	      self#virtual_call_to_dot vfct vcallee
	    )
    	  )
    	  virtcallees
    );

    Printf.printf "c2d.function_to_dot:END: fct_sign=\"%s\", file=%s\n" fonction.sign filepath

  method function_get_dot_vertex (fct_sign:string) : Graph_func.function_decl option =

    let nb_vtx = self#get_fcg_dot_nodes_number in
    if nb_vtx == 0 then
      (
	Printf.printf "c2d.function_get_dot_vertex::NOT_FOUND_VERTEX:: no vertex has yet been created, so no vertex found for fct=%s \n" fct_sign;
        None
      )
    else
      (
        try
          (
	    let vertex : fcg_vertex =
	      List.find
	        (
	          fun (vertex:fcg_vertex) ->
	          (
                    Printf.printf "c2d.function_get_dot_vertex:DEBUG: (fct_sign==%s) =?= (vertex.sign==%s)\n" fct_sign vertex.sign;
                    String.compare fct_sign vertex.sign == 0
                  )
	        )
	        fcg_dot_nodes
	    in
	    (* let vfct : Graph_func.function_decl = Graph_func.G.find_vertex fcg_dot_graph fct_sign in *)
	    Printf.printf "c2d.function_get_dot_vertex::FOUND_VERTEX:: a vertex does already exist for function \"%s\", so use it directly !\n" fct_sign;
	    Some vertex.vertex
          )
        with
          Not_found ->
          (
	    Printf.printf "c2d.function_get_dot_vertex::NOT_FOUND_VERTEX:: no vertex found for function \"%s\"!\n" fct_sign;
	    None
          )
      )

  (* adapted from class function_callers_json_parser::dump_fct defined in file function_callgraph.ml *)
  method function_create_dot_vertex (fct_sign:string) (fct_virtuality:string) (fct_file:string) : Graph_func.function_decl =

    Printf.printf "c2d.function_create_dot_vertex:BEGIN: fct_sign=\"%s\", fct_file=\"%s\"\n" fct_sign fct_file;

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
	id = fct_sign;
	name = fct_sign;
        virtuality = fct_virtuality;
	(* file_path = fct_file; *)
	(* line = "unknownFunctionLine"; *)
	(* bodyfile = fct_file; *)
	(* bodystart = "unknownBodyStart"; *)
	(* bodyend = "unknownBodyEnd"; *)
	(* return_type = "unknownFunctionReturnType"; *)
	(* argsstring = "unknownFunctionArgs"; *)
	(* params = []; *)
	(* callers = []; *)
	(* callees = []; *)
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

        let nb_vtx_before = self#get_fcg_dot_nodes_number in

	let (rfct:fcg_vertex) = { sign=fct_sign; vertex=vfct } in

	fcg_dot_nodes <-(match fcg_dot_nodes with
	                 | [] -> rfct::[]
	                 | l -> rfct::l
	                );

        let nb_vtx_after = self#get_fcg_dot_nodes_number in

        if ( nb_vtx_after == nb_vtx_before + 1) then
          Printf.printf "c2d.function_create_dot_vertex:DEBUG: nb vertices incremented correctly\n"
        else
          (
            Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
            Printf.printf "c2d.function_create_dot_vertex:ERROR: nb vertices not incremented correctly ! before=%d, after=%d\n" nb_vtx_before nb_vtx_after;
            Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
            raise Common.Internal_Error
          );

	fcg_dot_graph <- Graph_func.G.add_vertex fcg_dot_graph vfct
      );

    Printf.printf "c2d.function_create_dot_vertex:END: fct_sign=\"%s\", fct_file=\"%s\"\n" fct_sign fct_file;
    vfct

  method local_call_to_dot (vcaller:Graph_func.function_decl) (vcallee:Graph_func.function_decl) : unit =

    Printf.printf "c2d.local_call_to_dot:BEGIN: vcaller=%s, vacllee=%s\n" vcaller.name vcallee.name;

    (* raise an xception in case of a recursive function call *)
    if String.compare vcaller.name vcallee.name == 0 then
      (
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	Printf.printf "callgraph_to_dot.ml:ERROR: unsupported recursive function call %s->%s\n" vcaller.name vcallee.name;
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	raise Common.Unsupported_Recursive_Function
      );

    if Graph_func.G.mem_edge fcg_dot_graph vcaller vcallee then
      (
	Printf.printf "local_call_to_dot:EXISTING_EDGE:: an edge does already exist for local call %s->%s, so do not duplicate it !\n"
		      vcaller.name vcallee.name
      )
    else
      (
	Printf.printf "local_call_to_dot:CREATE_EDGE:: local call %s->%s does not yet exist, so we add it !\n"
		      vcaller.name vcallee.name;
	fcg_dot_graph <- Graph_func.G.add_edge_e fcg_dot_graph (Graph_func.G.E.create vcaller "internal" vcallee)
      );

    Printf.printf "c2d.local_call_to_dot:END: vcaller=%s, vacllee=%s\n" vcaller.name vcallee.name

  method external_call_to_dot (vcaller:Graph_func.function_decl) (vcallee:Graph_func.function_decl) : unit =

    Printf.printf "c2d.external_call_to_dot:BEGIN: vcaller=%s, vacllee=%s\n" vcaller.name vcallee.name;

    (* raise an xception in case of a recursive function call *)
    if String.compare vcaller.name vcallee.name == 0 then
      (
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	Printf.printf "callgraph_to_dot.ml:ERROR: unsupported recursive function call %s->%s\n" vcaller.name vcallee.name;
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	raise Common.Unsupported_Recursive_Function
      );

    if Graph_func.G.mem_edge fcg_dot_graph vcaller vcallee then
      (
	Printf.printf "c2d.external_call_to_dot:EXISTING_EDGE:: an edge does already exist for external call %s->%s, so do not duplicate it !\n"
		      vcaller.name vcallee.name
      )
    else
      (
	Printf.printf "c2d.external_call_to_dot:CREATE_EDGE:: external call %s->%s does not yet exist, so we add it !\n"
		      vcaller.name vcallee.name;
	fcg_dot_graph <- Graph_func.G.add_edge_e fcg_dot_graph (Graph_func.G.E.create vcaller "external" vcallee)
      );

    Printf.printf "c2d.external_call_to_dot:END: vcaller=%s, vacllee=%s\n" vcaller.name vcallee.name

  method virtual_call_to_dot (vcaller:Graph_func.function_decl) (vcallee:Graph_func.function_decl) : unit =

    Printf.printf "c2d.virtual_call_to_dot:BEGIN: vcaller=%s, vacllee=%s\n" vcaller.name vcallee.name;

    (* raise an xception in case of a recursive function call *)
    if String.compare vcaller.name vcallee.name == 0 then
      (
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	Printf.printf "callgraph_to_dot.ml:ERROR: unsupported recursive function call %s->%s\n" vcaller.name vcallee.name;
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	raise Common.Unsupported_Recursive_Function
      );

    if Graph_func.G.mem_edge fcg_dot_graph vcaller vcallee then
      (
	Printf.printf "virtual_call_to_dot:EXISTING_EDGE:: an edge does already exist for virtual call %s->%s, so do not duplicate it !\n"
		      vcaller.name vcallee.name
      )
    else
      (
	Printf.printf "virtual_call_to_dot:CREATE_EDGE:: virtual call %s->%s does not yet exist, so we add it !\n"
		      vcaller.name vcallee.name;
	fcg_dot_graph <- Graph_func.G.add_edge_e fcg_dot_graph (Graph_func.G.E.create vcaller "virtual" vcallee)
      );

    Printf.printf "c2d.virtual_call_to_dot:END: vcaller=%s, vacllee=%s\n" vcaller.name vcallee.name

end
;;

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("callgraph_jsonfilepath" %: string)
  +> anon ("callgraph_dotfilepath" %: string)
  +> anon (maybe(sequence("other" %: string)))

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Dot backend for callgraph's json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun callgraph_jsonfilepath callgraph_dotfilepath other () ->

      let dot_fcg : function_callgraph_to_dot = new function_callgraph_to_dot other in

      dot_fcg#parse_jsonfile callgraph_jsonfilepath;

      dot_fcg#rootdir_to_dot();

      dot_fcg#output_dot_fcg callgraph_dotfilepath
    )

(* Running Basic Commands *)
let () = Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -package base64 -tag thread callgraph_to_dot.native" *)
(* End: *)
