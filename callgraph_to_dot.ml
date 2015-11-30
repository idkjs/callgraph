(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   KTD SCIS 2014-2015                                                       *)
(*   Use Case Legacy TOSA                                                     *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)
(* forked from callers_to_json.org *)

open Callgraph_t

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty

(* Dot function callgraph *)
class callgraph_function_dot (callgraph_jsonfile:string) = object(self)

  val json_filepath : string = callgraph_jsonfile

  val mutable json_rootdir : Callgraph_t.dir option = None

  val mutable dot_fcg : Graph_func.G.t = Graph_func.G.empty

  method parse_jsonfile () : unit =
    try
      (
	Printf.printf "Read callgraph's json file \"%s\"...\n" json_filepath;
	(* Read JSON file into an OCaml string *)
	let content = Core.Std.In_channel.read_all json_filepath in
	(* Read the input callgraph's json file *)
	json_rootdir <- Some (Callgraph_j.dir_of_string content)
      )
    with
    | Sys_error msg -> 
       (
	 Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE";
	 Printf.printf "callgraph_function_dot::parse_jsonfile:ERROR: Ignore not found file \"%s\"" json_filepath;
	 Printf.printf "Sys_error msg: %s\n" msg;
	 Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE";
	 json_rootdir <- None
       )

  method callgraph_rootdir_to_dot () = 
    
    (match json_rootdir with
    | None -> ()
    | Some rootdir -> self#callgraph_dir_to_dot rootdir
    )

  method callgraph_dir_to_dot (dir:Callgraph_t.dir) =
    
    Printf.printf "callgraph_to_dot.ml::INFO::callgraph_dir_to_dot: dir=\"%s\"...\n" dir.name;

    (* Parse files located in dir *)
    (match dir.files with
     | None -> ()
     | Some files -> 
	List.iter
	  ( 
	    fun (file:Callgraph_t.file) ->  self#callgraph_file_to_dot file
	  )
	  files
    );

    (* Parse children directories *)
    (match dir.children with
     | None -> ()
     | Some children -> 
	List.iter
	  ( 
	    fun (child:Callgraph_t.dir) ->  self#callgraph_dir_to_dot child
	  )
	  children
    )

  method callgraph_file_to_dot (file:Callgraph_t.file) = 

    Printf.printf "callgraph_to_dot.ml::INFO::callgraph_file_to_dot: name=\"%s\"...\n" file.name;

    (* Parse functions declared in file *)
    (match file.declared with
     | None -> ()
     | Some declared -> 
	List.iter
	  ( 
	    fun (fct_decl:Callgraph_t.fonction) ->  self#callgraph_function_to_dot fct_decl
	  )
	  declared
    );

    (* Parse functions defined in file *)
    (match file.defined with
     | None -> ()
     | Some defined -> 
	List.iter
	  ( 
	    fun (fct_decl:Callgraph_t.fonction) ->  self#callgraph_function_to_dot fct_decl
	  )
	  defined
    );

    ()

  method callgraph_function_to_dot (fonction:Callgraph_t.fonction) = 
    
    Printf.printf "callgraph_to_dot.ml::INFO::callgraph_function_to_dot: sign=\"%s\"...\n" fonction.sign
(* let vcallee : Graph_func.function_decl = self#dump_fct fct.sign json_file in *)
(*     gfct_callers <- Graph_func.G.add_vertex gfct_callers vcallee *)

end
;;

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Dot backend for callgraph's json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun () -> 
      
      let jsoname_file : String.t = "test.dir.callgraph.gen.json" in

      let dot_callgraph : callgraph_function_dot = new callgraph_function_dot jsoname_file in

      dot_callgraph#parse_jsonfile();

      dot_callgraph#callgraph_rootdir_to_dot()
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package ocamlgraph -tag thread callgraph_to_dot.native" *)
(* End: *)
