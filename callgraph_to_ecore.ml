(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   KTD SCIS 2014-2015                                                       *)
(*   Use Case Legacy TOSA                                                     *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)
(* derived from callgraph_to_dot.ml *)

exception NOT_FOUND_LOCAL_FUNCTION
exception UNSUPPORTED_RECURSIVE_FUNCTION
exception UNSUPPORTED_FUNCTION_KIND

(* Ecore function callgraph *)
class function_callgraph_to_ecore
  = object(self)

  inherit Function_callgraph.function_callgraph

  val mutable fcg_ecore : Xml.xml = Xmi.add_item "empty" [] [];

  method output_fcg_ecore (ecore_filename:string) : unit =

    let file = open_out_bin ecore_filename in
    Xmi.output_xml_file ecore_filename fcg_ecore

  method rootdir_to_ecore () =

    match json_rootdir with
    | None -> ()
    | Some rootdir ->
       (
	 let dir_in : Xml.xml = Xmi.add_item "callgraph:dir" [("xmi:version","2.0");
       							      ("xmlns:xmi","http://www.omg.org/XMI");
       							      ("xmlns:callgraph","http://callgraph");
       							      ("name",rootdir.name)] []
	 in
	 let dir_out : Xml.xml = self#dir_to_ecore rootdir "" dir_in
	 in
	 fcg_ecore <- dir_out
    )

  method dir_to_ecore (dir:Callgraph_t.dir) (path:string) (parent_in:Xml.xml) : Xml.xml =

    Printf.printf "callgraph_to_ecore.ml::INFO::callgraph_dir_to_ecore: dir=\"%s\"...\n" dir.name;

    let dirpath = Printf.sprintf "%s/%s" path dir.name in

    (* Parse uses directories *)
    let uses : Xml.xml list =
      (match dir.uses with
       | None -> []
       | Some uses ->
	  List.map
	    (
	      (* Add a uses xml entry *)
	      fun (used_dir:string) ->
	      let dir_out : Xml.xml = Xmi.add_item "uses" [("xmi:idref", used_dir)] [] in
	      dir_out
	    )
	    uses
      )
    in
    let parent_out : Xml.xml = Xmi.add_childrens parent_in uses
    in

    (* Parse files located in dir *)
    let files : Xml.xml list =
      (match dir.files with
       | None -> []
       | Some files ->
	  List.map
	    (
	      (* Add a file xml entry *)
	      fun (file:Callgraph_t.file) ->
	      let file_out : Xml.xml = self#file_to_ecore file dirpath in
	      file_out
	    )
	    files
      )
    in
    let parent_out : Xml.xml = Xmi.add_childrens parent_out files
    in

    (* Parse children directories *)
    let children : Xml.xml list =
      (match dir.children with
       | None -> []
       | Some children ->
	  List.map
	    (
	      (* Add a children xml entry *)
	      fun (child:Callgraph_t.dir) ->
	      let child_in : Xml.xml = Xmi.add_item "children" [("xmi:id", child.name);
								("name", child.name)] [] in
	      let child_out : Xml.xml = self#dir_to_ecore child dirpath child_in in
	      child_out
	    )
	    children
      )
    in
    let parent_out : Xml.xml = Xmi.add_childrens parent_out children
    in
    parent_out

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
	  Printf.printf "class function_callgraph_to_ecore::file_get_declared_function::FOUND_DECL_FCT:: declaration found for function \"%s\" in file \"%s\" !\n" fct_sign file.name;
	  Some found_fct
	with
	  Not_found ->
	  (
	    Printf.printf "class function_callgraph_to_ecore::file_get_declared_function::NOT_FOUND_DECL_FCT:: no declaration found for function \"%s\" in file \"%s\" !\n" fct_sign file.name;
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
	  Printf.printf "class function_callgraph_to_ecore::file_get_defined_function::FOUND_DEF_FCT:: definition found for function \"%s\" in file \"%s\" !\n" fct_sign file.name;
	  Some found_fct
	with
	  Not_found ->
	  (
	    Printf.printf "class function_callgraph_to_ecore::file_get_defined_function::NOT_FOUND_DEF_FCT:: no definition found for function \"%s\" in file \"%s\" !\n" fct_sign file.name;
	    None
	  )
    )

  method file_to_ecore (file:Callgraph_t.file) (path:string) =

    Printf.printf "callgraph_to_ecore.ml::INFO::callgraph_file_to_ecore: name=\"%s\"...\n" file.name;

    let filepath = Printf.sprintf "%s/%s" path file.name in

    let file_out : Xml.xml = Xmi.add_item "files" [("xmi:id", file.name);
						   ("name", file.name)] [] in

    (* Parse uses files *)
    let uses : Xml.xml list =
      (match file.uses with
       | None -> []
       | Some uses ->
          List.map
            (
	      (* Add a uses xml entry *)
              fun (used_file:string) ->
	      let file_out : Xml.xml = Xmi.add_item "uses" [("xmi:idref", used_file)] [] in
	      file_out
            )
            uses
      )
    in
    let file_out : Xml.xml = Xmi.add_childrens file_out uses in

    (* Parse functions declared in file *)
    let declared : Xml.xml list =
      (match file.declared with
       | None -> []
       | Some declared ->
	  List.map
	    (
	      fun (fct_decl:Callgraph_t.fonction) -> self#function_to_ecore fct_decl filepath "declared"
	    )
	    declared
      )
    in
    let file_out : Xml.xml = Xmi.add_childrens file_out declared in

    (* Parse functions defined in file *)
    let defined : Xml.xml list =
      (match file.defined with
       | None -> []
       | Some defined ->
	  List.map
	    (
	      fun (fct_decl:Callgraph_t.fonction) ->  self#function_to_ecore fct_decl filepath "defined"
	    )
	    defined
      )
    in
    let file_out : Xml.xml = Xmi.add_childrens file_out defined
    in
    file_out

  method function_to_ecore (fonction:Callgraph_t.fonction) (filepath:string) (kind:string) =

    Printf.printf "class function_callgraph_to_ecore::function_to_ecore::INFO: sign=\"%s\"...\n" fonction.sign;

    let flag : string =
      (match kind with
      | "declared"
      | "defined"
	-> kind
      | _ -> raise UNSUPPORTED_FUNCTION_KIND
      )
    in
    let fonction_out : Xml.xml = Xmi.add_item flag [("xmi:id", fonction.sign);
						    ("sign", fonction.sign)] []
    in

    (* Parse local function calls *)
    let locallees : Xml.xml list =
      (match fonction.locallees with
       | None -> []
       | Some locallees ->
    	  List.map
    	    (
    	      fun (locallee:string) -> self#locallee_to_ecore fonction.sign locallee
    	    )
    	    locallees
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out locallees in
   
    (* Parse external function calls *)
    let extcallees : Xml.xml list =
      (match fonction.extcallees with
       | None -> []
       | Some extcallees ->
    	  List.map
    	    (
    	      fun (extcallee:string) -> self#extcallee_to_ecore fonction.sign extcallee
    	    )
    	    extcallees
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out extcallees
    in
    fonction_out
     
  method locallee_to_ecore (vcaller_sign:string) (vcallee_sign:string) : Xml.xml =

    let locallee_out : Xml.xml = Xmi.add_item "locallees" [("xmi:idref", vcallee_sign)] []
    in
    locallee_out

  method extcallee_to_ecore (vcaller_sign:string) (vcallee_sign:string) : Xml.xml =

    let extcallee_out : Xml.xml = Xmi.add_item "extcallees" [("xmi:idref", vcallee_sign)] []
    in
    extcallee_out

end
;;

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("callgraph_jsonfilepath" %: string)

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Dot backend for callgraph's json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun callgraph_jsonfilepath () ->

      let ecore_filename : String.t  = Printf.sprintf "%s.callgraph" callgraph_jsonfilepath in

      let dot_filename : String.t  = Printf.sprintf "%s.dot" callgraph_jsonfilepath in

      let dot_fcg : function_callgraph_to_ecore = new function_callgraph_to_ecore in

      dot_fcg#parse_jsonfile callgraph_jsonfilepath;

      dot_fcg#rootdir_to_ecore();

      dot_fcg#output_fcg_ecore ecore_filename;
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package xml-light -tag thread callgraph_to_ecore.native" *)
(* End: *)
