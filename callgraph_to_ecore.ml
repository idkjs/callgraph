(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

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
	 let dir_in : Xml.xml = Xmi.add_item "callgraph:dirs" [("xmi:version","2.0");
                                                               ("xmlns:xmi","http://www.omg.org/XMI");
                                                               ("xmlns:callgraph","http://callgraph");
                                                               ("path",rootdir.path)] []
	 in
         (* Parse directories *)
         let dirs : Xml.xml list =
           (match rootdir.dir with
            | None -> []
            | Some dirs ->
	       List.map
	         (
	           (* Add a uses xml entry *)
	           fun (dir:Callgraph_t.dir) ->
                   let dir_header : Xml.xml = Xmi.add_item "callgraph:dir" [("name", dir.name);
                                                                            ("path", dir.path)] [] in
	           let dir_out : Xml.xml = self#dir_to_ecore dir dir_header in
	           dir_out
	         )
	         dirs
           )
         in
         let dir_out : Xml.xml = Xmi.add_childrens dir_in dirs
         in
	 fcg_ecore <- dir_out
    )

  method dir_to_ecore (dir:Callgraph_t.dir) (parent_in:Xml.xml) : Xml.xml =

    Printf.printf "callgraph_to_ecore.ml::INFO::callgraph_dir_to_ecore: dir=\"%s\"...\n" dir.name;

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
	      let file_out : Xml.xml = self#file_to_ecore file dir.path in
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
       | Some children -> []
	  (* List.map *)
	  (*   ( *)
	  (*     (\* Add a children xml entry *\) *)
	  (*     fun (child:Callgraph_t.dir) -> *)
	  (*     let child_in : Xml.xml = Xmi.add_item "children" [("xmi:id", child.name); *)
	  (*       						("name", child.name)] [] in *)
	  (*     let child_out : Xml.xml = self#dir_to_ecore child child_in in *)
	  (*     child_out *)
	  (*   ) *)
	  (*   children *)
      )
    in
    let parent_out : Xml.xml = Xmi.add_childrens parent_out children
    in
    parent_out

  (* method file_get_function (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction option = *)

  (*   let search_fct_def = self#file_get_defined_function file fct_sign in *)

  (*   (match search_fct_def with *)
  (*    | None -> self#file_get_declared_function file fct_sign *)
  (*    | Some _ -> search_fct_def *)
  (*   ) *)

  (* method file_get_declared_function (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction option = *)

  (*   (\* Parse functions declared in file *\) *)
  (*   (match file.declared with *)
  (*    | None -> None *)
  (*    | Some declared -> *)
  (*       try *)
  (*         let found_fct : Callgraph_t.fonction = *)
  (*           List.find *)
  (*             ( *)
  (*       	fun (fct_decl:Callgraph_t.fonction) -> (String.compare fct_sign fct_decl.sign == 0) *)
  (*             ) *)
  (*             declared *)
  (*         in *)
  (*         Printf.printf "class function_callgraph_to_ecore::file_get_declared_function::FOUND_DECL_FCT:: declaration found for function \"%s\" in file \"%s\" !\n" fct_sign file.name; *)
  (*         Some found_fct *)
  (*       with *)
  (*         Not_found -> *)
  (*         ( *)
  (*           Printf.printf "class function_callgraph_to_ecore::file_get_declared_function::NOT_FOUND_DECL_FCT:: no declaration found for function \"%s\" in file \"%s\" !\n" fct_sign file.name; *)
  (*           None *)
  (*         ) *)
  (*   ) *)

  (* method file_get_defined_function (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction option = *)

  (*   (\* Parse functions defined in file *\) *)
  (*   (match file.defined with *)
  (*    | None -> None *)
  (*    | Some defined -> *)
  (*       try *)
  (*         let found_fct : Callgraph_t.fonction = *)
  (*           List.find *)
  (*             ( *)
  (*       	fun (fct_decl:Callgraph_t.fonction) -> (String.compare fct_sign fct_decl.sign == 0) *)
  (*             ) *)
  (*             defined *)
  (*         in *)
  (*         Printf.printf "class function_callgraph_to_ecore::file_get_defined_function::FOUND_DEF_FCT:: definition found for function \"%s\" in file \"%s\" !\n" fct_sign file.name; *)
  (*         Some found_fct *)
  (*       with *)
  (*         Not_found -> *)
  (*         ( *)
  (*           Printf.printf "class function_callgraph_to_ecore::file_get_defined_function::NOT_FOUND_DEF_FCT:: no definition found for function \"%s\" in file \"%s\" !\n" fct_sign file.name; *)
  (*           None *)
  (*         ) *)
  (*   ) *)

  method file_to_ecore (file:Callgraph_t.file) (path:string) =

    Printf.printf "callgraph_to_ecore.ml::INFO::callgraph_file_to_ecore: name=\"%s\"...\n" file.name;

    let filepath = Printf.sprintf "%s/%s" path file.name in

    let file_out : Xml.xml = Xmi.add_item "files" [("xmi:id", filepath);
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
	      fun (fct_decl:Callgraph_t.fonction_decl) -> self#function_decl_to_ecore fct_decl (*filepath*) "declared"
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
	      fun (fct_def:Callgraph_t.fonction_def) ->  self#function_def_to_ecore fct_def filepath "defined"
	    )
	    defined
      )
    in
    let file_out : Xml.xml = Xmi.add_childrens file_out defined
    in
    file_out

  method function_decl_to_ecore (fonction:Callgraph_t.fonction_decl) (kind:string) : Xml.xml =

    Printf.printf "c2e.function_decl_to_ecore:INFO: sign=\"%s\"...\n" fonction.sign;

    let flag : string =
      (match kind with
      | "declared"
      | "defined"
	-> kind
      | _ -> raise Common.Unsupported_Function_Kind
      )
    in

    let fonction_id =
      (match kind with
      | "declared" -> Printf.sprintf "dc: %s" fonction.sign
      | "defined" -> Printf.sprintf "df: %s" fonction.sign
      | _ -> raise Common.Unsupported_Function_Kind
      )
    in

    let virtuality = Callers.fct_virtuality_option_to_string fonction.virtuality in

    let fonction_out : Xml.xml = Xmi.add_item flag [("xmi:id", fonction_id);
						    ("sign", fonction.sign);
                                                    ("virtuality", virtuality)] []
    in

    (* Parse local definition *)
    let localdef : Xml.xml list =
      (match fonction.localdef with
       | None -> []
       | Some localdef ->
          [self#localdef_to_ecore fonction.sign localdef]
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out localdef in

    (* Parse local function callers *)
    let locallers : Xml.xml list =
      (match fonction.locallers with
       | None -> []
       | Some locallers ->
    	  List.map
    	    (
    	      fun (localler:Callgraph_t.fct_ref) -> self#localler_to_ecore fonction.sign (*filepath*) localler
    	    )
    	    locallers
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out locallers in

    (* Parse external function callers *)
    let extcallers : Xml.xml list =
      (match fonction.extcallers with
       | None -> []
       | Some extcallers ->
    	  List.map
    	    (
    	      fun (extcaller:Callgraph_t.extfct_ref) -> self#extcaller_to_ecore fonction.sign (*filepath*) extcaller
    	    )
    	    extcallers
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out extcallers in

    (* Parse virtual function redeclarations *)
    let virtredecls : Xml.xml list =
      (match fonction.virtdecls with
       | None -> []
       | Some virtredecls ->
    	  List.map
    	    (
    	      fun (virtdecl:Callgraph_t.fonction_decl) -> self#virtdecl_to_ecore fonction.sign virtdecl
    	    )
    	    virtredecls
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out virtredecls in

    (* Parse virtual function callers *)
    let virtcallers : Xml.xml list =
      (match fonction.virtcallers with
       | None -> []
       | Some virtcallers ->
    	  List.map
    	    (
    	      fun (virtcaller:Callgraph_t.extfct_ref) -> self#virtcaller_to_ecore fonction.sign virtcaller
    	    )
    	    virtcallers
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out virtcallers
    in
    fonction_out

  method function_def_to_ecore (fonction:Callgraph_t.fonction_def) (filepath:string) (kind:string) : Xml.xml =

    Printf.printf "c2e.function_def_to_ecore:INFO: sign=\"%s\"...\n" fonction.sign;

    let flag : string =
      (match kind with
      | "declared"
      | "defined"
	-> kind
      | _ -> raise Common.Unsupported_Function_Kind
      )
    in

    let fonction_id =
      (match kind with
      | "declared" -> Printf.sprintf "dc: %s" (*filepath*) fonction.sign
      | "defined" -> Printf.sprintf "df: %s" (*filepath*) fonction.sign
      | _ -> raise Common.Unsupported_Function_Kind
      )
    in

    let fonction_out : Xml.xml = Xmi.add_item flag [("xmi:id", fonction_id);
						    ("sign", fonction.sign)] []
    in

    (* Parse local function callees *)
    let locallees : Xml.xml list =
      (match fonction.locallees with
       | None ->
          (
            (* Printf.printf "c2e.function_def_to_ecore:DEBUG: no locallees for function \"%s\"\n" fonction.sign ; *)
            []
          )
       | Some locallees ->
    	  List.map
    	    (
    	      fun (locallee:Callgraph_t.fct_ref) -> self#locallee_to_ecore fonction.sign (*filepath*) locallee
    	    )
    	    locallees
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out locallees in

    (* Parse external function calls *)
    let extcallees : Xml.xml list =
      (match fonction.extcallees with
       | None ->
          (
            (* Printf.printf "c2e.function_def_to_ecore:DEBUG: no extcallees for function \"%s\"\n" fonction.sign; *)
            []
          )
       | Some extcallees ->
    	  List.map
    	    (
    	      fun (extcallee:Callgraph_t.extfct_ref) -> self#extcallee_to_ecore fonction.sign extcallee
    	    )
    	    extcallees
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out extcallees in

    (* Parse virtual function callees *)
    let virtcallees : Xml.xml list =
      (match fonction.virtcallees with
       | None ->
          (
            (* Printf.printf "c2e.function_def_to_ecore:DEBUG: no virtcallees for function \"%s\"\n" fonction.sign; *)
            []
          )
       | Some virtcallees ->
    	  List.map
    	    (
    	      fun (virtcallee:Callgraph_t.extfct_ref) -> self#virtcallee_to_ecore fonction.sign virtcallee
    	    )
    	    virtcallees
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out virtcallees
    in
    fonction_out

  method localdef_to_ecore (ldecl_sign:string) (ldef:Callgraph_t.fonction_def) : Xml.xml =

    let localdef_id = Printf.sprintf "df: %s" ldef.sign
    in
    let localdef_out : Xml.xml = Xmi.add_item "localdef" [("xmi:idref", localdef_id)] []
    in
    localdef_out

  method locallee_to_ecore (vcaller_sign:string) (*file:string*) (vcallee:Callgraph_t.fct_ref) : Xml.xml =

    let locallee_id = Printf.sprintf "dc: %s" (*file*) vcallee.sign
    in
    let locallee_out : Xml.xml = Xmi.add_item "locallees" [("xmi:idref", locallee_id)] []
    in
    locallee_out

  method localler_to_ecore (vcaller_sign:string) (*file:string*) (vcallee:Callgraph_t.fct_ref) : Xml.xml =

    let localler_id = Printf.sprintf "dc: %s" (*file*) vcallee.sign
    in
    let localler_out : Xml.xml = Xmi.add_item "locallers" [("xmi:idref", localler_id)] []
    in
    localler_out

  method extcaller_to_ecore (vcaller_sign:string) (vcallee:Callgraph_t.extfct_ref) : Xml.xml =

    let extcaller_id = Printf.sprintf "dc: %s" vcallee.sign
    in
    let extcaller_out : Xml.xml = Xmi.add_item "extcallers" [("xmi:idref", extcaller_id)] []
    in
    extcaller_out

  method extcallee_to_ecore (vcaller_sign:string) (vcallee:Callgraph_t.extfct_ref) : Xml.xml =

    Printf.printf "c2e.extcallee_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" vcaller_sign vcallee.sign;
    let extcallee_id = Printf.sprintf "dc: %s" (*vcallee.file*) vcallee.sign
    in
    let extcallee_out : Xml.xml = Xmi.add_item "extcallees" [("xmi:idref", extcallee_id)] []
    in
    extcallee_out

  method virtdecl_to_ecore (vdecl_sign:string) (vredecl:Callgraph_t.fonction_decl) : Xml.xml =

    let virtdecl_id = Printf.sprintf "dc: %s" vredecl.sign
    in
    let virtdecl_out : Xml.xml = Xmi.add_item "virtdecls" [("xmi:idref", virtdecl_id)] []
    in
    virtdecl_out

  method virtcallee_to_ecore (vcaller_sign:string) (vcallee:Callgraph_t.extfct_ref) : Xml.xml =

    let virtcallee_id = Printf.sprintf "dc: %s" (*vcallee.file*) vcallee.sign
    in
    let virtcallee_out : Xml.xml = Xmi.add_item "virtcallees" [("xmi:idref", virtcallee_id)] []
    in
    virtcallee_out

  method virtcaller_to_ecore (vcaller_sign:string) (vcaller:Callgraph_t.extfct_ref) : Xml.xml =

    let virtcaller_id = Printf.sprintf "dc: %s" (*vcaller.file*) vcaller.sign
    in
    let virtcaller_out : Xml.xml = Xmi.add_item "virtcallers" [("xmi:idref", vcaller.sign)] []
    in
    virtcaller_out

end
;;

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("callgraph_jsonfilepath" %: string)
  +> anon ("callgraph_ecorefilepath" %: string)

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Dot backend for callgraph's json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun callgraph_jsonfilepath callgraph_ecorefilepath () ->

      let ecore_fcg : function_callgraph_to_ecore = new function_callgraph_to_ecore in

      ecore_fcg#parse_jsonfile callgraph_jsonfilepath;

      ecore_fcg#rootdir_to_ecore();

      ecore_fcg#output_fcg_ecore callgraph_ecorefilepath;
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package xml-light -tag thread callgraph_to_ecore.native" *)
(* End: *)
