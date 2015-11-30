(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   KTD SCIS 2014-2015                                                       *)
(*   Use Case Legacy TOSA                                                     *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)
(* forked from callers_to_json.org *)

(* Dot function callgraph *)
class function_callgraph_to_dot (callgraph_jsonfile:string)
				(other:string list option)
  = object(self)

  inherit Function_callgraph.function_callgraph callgraph_jsonfile other

  val mutable dot_fcg : Graph_func.G.t = Graph_func.G.empty

  method output_dot_fcg (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file dot_fcg

  method rootdir_to_dot () = 
    
    (match json_rootdir with
    | None -> ()
    | Some rootdir -> self#dir_to_dot rootdir
    )

  method dir_to_dot (dir:Callgraph_t.dir) =
    
    Printf.printf "callgraph_to_dot.ml::INFO::callgraph_dir_to_dot: dir=\"%s\"...\n" dir.name;

    (* Parse files located in dir *)
    (match dir.files with
     | None -> ()
     | Some files -> 
	List.iter
	  ( 
	    fun (file:Callgraph_t.file) ->  self#file_to_dot file
	  )
	  files
    );

    (* Parse children directories *)
    (match dir.children with
     | None -> ()
     | Some children -> 
	List.iter
	  ( 
	    fun (child:Callgraph_t.dir) ->  self#dir_to_dot child
	  )
	  children
    )

  method file_to_dot (file:Callgraph_t.file) = 

    Printf.printf "callgraph_to_dot.ml::INFO::callgraph_file_to_dot: name=\"%s\"...\n" file.name;

    let filepath : string = self#get_file_path file in

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
    );

    ()

  method function_to_dot (fonction:Callgraph_t.fonction) (filepath:string) = 
    
    Printf.printf "callgraph_to_dot.ml::INFO::callgraph_function_to_dot: sign=\"%s\"...\n" fonction.sign;

    let vfct : Graph_func.function_decl = self#function_create_dot_vertex fonction.sign filepath in

    if Graph_func.G.mem_vertex dot_fcg vfct then
      (
	Printf.printf "function_to_dot::WARNING:: a vertex does already exist for function \"%s\", so do not duplicate it !\n" fonction.sign
      )
    else
      (
	Printf.printf "function_to_dot::CREATE_VERTEX:: function node \"%s\" does not yet exist, so we add it !\n" fonction.sign;
	dot_fcg <- Graph_func.G.add_vertex dot_fcg vfct
      )

    (* (\* Parse functions defined in file *\) *)
    (* (match file.defined with *)
    (*  | None -> () *)
    (*  | Some defined ->  *)
    (* 	List.iter *)
    (* 	  (  *)
    (* 	    fun (fct_decl:Callgraph_t.fonction) ->  self#function_to_dot fct_decl filepath *)
    (* 	  ) *)
    (* 	  defined *)
    (* ); *)

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
    let v : Graph_func.function_decl =
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
    v

  (* method function_create_dot_edge (caller:Callgraph_t.fonction) (fct_file:string) : unit = *)

  (*   let vfct_caller : Graph_func.function_decl = self#function_create_dot_vertex caller.sign filepath in *)

  (*   (\* gfct_callers <- Graph_func.G.add_edge_e gfct_callers (Graph_func.G.E.create vcaller "internal" vcallee); *\) *)
  (*   if Graph_func.G.mem_vertex dot_fcg vfct_caller then *)
  (*     Printf.printf "function_create_dot_edge::WARNING:: Caller node \"%s\" does already exist !"  *)

end
;;

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon (maybe(sequence("other" %: string)))

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Dot backend for callgraph's json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun other () -> 
      
      let json_filename : String.t = "test.dir.callgraph.gen.json" in
      let dot_filename : String.t  = "test.dir.callgraph.gen.dot" in

      let dot_fcg : function_callgraph_to_dot = new function_callgraph_to_dot json_filename other in

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
