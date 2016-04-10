(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

let filter_xml_reserved_characters (identifier:string) : string =

  (* Replace all "<" by "{" in the input identifier *)
  let xml_id : string = Str.global_replace (Str.regexp "\\<") "{" identifier in
  (* Replace all ">" by "}" in the input identifier *)
  let xml_id : string = Str.global_replace (Str.regexp "\\>") "}" xml_id in
  (* Replace all "&" by "and" in the input identifier *)
  (* Otherwise SAXParser Error: Le nom de l'identité doit immédiatement suivre le caractère "&" dans la référence d'entité. *)
  let xml_id : string = Str.global_replace (Str.regexp "\\&") "and" xml_id in
  xml_id

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
         let rootdir_id =
           (match rootdir.id with
            | None -> B64.encode rootdir.path
            | Some id -> id
           )
         in
	 let dir_in : Xml.xml = Xmi.add_item "callgraph:top" [("xmi:version","2.0");
                                                              ("xmlns:xmi","http://www.omg.org/XMI");
                                                              ("xmlns:callgraph","http://callgraph");
                                                              ("path", rootdir.path);
                                                              ("id", rootdir_id)] []
	 in
         (* Print the logical view *)
         let namespaces : Xml.xml list =
           (match rootdir.namespaces with
            | None -> []
            | Some namespaces ->
	       List.map
	         (
	           (* Add a uses xml entry *)
	           fun (nspc:Callgraph_t.namespace) ->
	           let nspc_out : Xml.xml = self#namespace_to_ecore nspc in
	           nspc_out
	         )
	         namespaces
           )
         in
         let dir_out : Xml.xml = Xmi.add_childrens dir_in namespaces
         in
         (* Print the physical view *)
         let dirs : Xml.xml list =
           (match rootdir.physical_view with
            | None -> []
            | Some dirs ->
	       List.map
	         (
	           (* Add a uses xml entry *)
	           fun (dir:Callgraph_t.dir) ->
	           let dir_out : Xml.xml = self#dir_to_ecore dir in
	           dir_out
	         )
	         dirs
           )
         in
         let dir_out : Xml.xml = Xmi.add_childrens dir_out dirs
         in
         (* Print the runtime view *)
         let threads : Xml.xml list =
           (match rootdir.runtime_view with
            | None -> []
            | Some threads ->
	       List.map
	         (
	           (* Add a uses xml entry *)
	           fun (thr:Callgraph_t.thread) ->
	           let thr_out : Xml.xml = self#thread_to_ecore thr in
	           thr_out
	         )
	         threads
           )
         in
         let dir_out : Xml.xml = Xmi.add_childrens dir_out threads
         in
	 fcg_ecore <- dir_out
    )
  method namespace_to_ecore (namespace:Callgraph_t.namespace) : Xml.xml =

    Printf.printf "c2e.namespace_to_ecore:BEGIN: namespace=\"%s\"...\n" namespace.name;

    let namespace_id = B64.encode namespace.name in

    (* (\* Parse records *\) *)
    (* let namespace_params = *)
    (*   (match namespace.parents with *)
    (*    | None -> [] *)
    (*    | Some parents -> *)
    (*      ( *)
    (*        let parents : string = *)
    (*          List.fold_left *)
    (*            ( *)
    (*              fun (p:string) (parent:Callgraph_t.inheritance) -> *)
    (*              let parent_b64 = B64.encode parent.namespace in *)
    (*              Printf.sprintf "%s %s" parent_b64 p *)
    (*            ) *)
    (*            "" *)
    (*            parents *)
    (*        in *)
    (*        [("parents", parents)] *)
    (*      ) *)
    (*   ) *)
    (* in *)

    (* (\* Parse children classes *\) *)
    (* let namespace_params = *)
    (*   (match namespace.children with *)
    (*    | None -> namespace_params *)
    (*    | Some children -> *)
    (*      ( *)
    (*        let children : string = *)
    (*          List.fold_left *)
    (*            ( *)
    (*              fun (c:string) (child:Callgraph_t.inheritance) -> *)
    (*              let child_b64 = B64.encode child.namespace in *)
    (*              Printf.sprintf "%s %s" child_b64 c *)
    (*            ) *)
    (*            "" *)
    (*            children *)
    (*        in *)
    (*        ("children", children)::namespace_params *)
    (*      ) *)
    (*   ) *)
    (* in *)

    (* (\* Parse namespace's method's declarations *\) *)
    (* let namespace_params = *)
    (*   (match namespace.meth_decls with *)
    (*    | None -> namespace_params *)
    (*    | Some methods -> *)
    (*      ( *)
    (*        let decl_methods : string = *)
    (*          List.fold_left *)
    (*            ( *)
    (*              fun (m:string) (meth:string) -> *)
    (*              Printf.sprintf "dc%s %s" meth m *)
    (*            ) *)
    (*            "" *)
    (*            methods *)
    (*        in *)
    (*        ("meth_decls", decl_methods)::namespace_params *)
    (*      ) *)
    (*   ) *)
    (* in *)

    (* (\* Parse namespace's method's definitions *\) *)
    (* let namespace_params = *)
    (*   (match namespace.meth_defs with *)
    (*    | None -> namespace_params *)
    (*    | Some methods -> *)
    (*      ( *)
    (*        let def_methods : string = *)
    (*          List.fold_left *)
    (*            ( *)
    (*              fun (m:string) (meth:string) -> *)
    (*              Printf.sprintf "df%s %s" meth m *)
    (*            ) *)
    (*            "" *)
    (*            methods *)
    (*        in *)
    (*        ("meth_defs", def_methods)::namespace_params *)
    (*      ) *)
    (*   ) *)
    (* in *)

    (* (\* Parse namespace's calls *\) *)
    (* let namespace_params = *)
    (*   (match namespace.calls with *)
    (*    | None -> namespace_params *)
    (*    | Some rc_calls -> *)
    (*      ( *)
    (*        let cd_calls : string = *)
    (*          List.fold_left *)
    (*            ( *)
    (*              fun (c:string) (call:string) -> *)
    (*              let call_b64 = B64.encode call in *)
    (*              (\* Printf.printf "c2e.namespace_to_ecore:DEBUG: namespace:\"%s\", c:\"%s\", call=\"%s\", call_b64=\"%s\"\n" namespace.name c call call_b64; *\) *)
    (*              Printf.sprintf "%s %s" call_b64 c *)
    (*            ) *)
    (*            "" *)
    (*            rc_calls *)
    (*        in *)
    (*        (\* Printf.printf "c2e.namespace_to_ecore:INFO: namespace:\"%s\", calls:\"%s\"\n" namespace.name cd_calls; *\) *)
    (*        ("calls", cd_calls)::namespace_params *)
    (*      ) *)
    (*   ) *)
    (* in *)

    (* (\* Parse namespace's virtual calls *\) *)
    (* let namespace_params = *)
    (*   (match namespace.virtcalls with *)
    (*    | None -> namespace_params *)
    (*    | Some rc_virtcalls -> *)
    (*      ( *)
    (*        let cd_virtcalls : string = *)
    (*          List.fold_left *)
    (*            ( *)
    (*              fun (c:string) (call:string) -> *)
    (*              let call_b64 = B64.encode call in *)
    (*              (\* Printf.printf "c2e.namespace_to_ecore:DEBUG: namespace:\"%s\", c:\"%s\", call=\"%s\", call_b64=\"%s\"\n" namespace.name c call call_b64; *\) *)
    (*              Printf.sprintf "%s %s" call_b64 c *)
    (*            ) *)
    (*            "" *)
    (*            rc_virtcalls *)
    (*        in *)
    (*        (\* Printf.printf "c2e.namespace_to_ecore:INFO: namespace:\"%s\", virtcalls:\"%s\"\n" namespace.name cd_virtcalls; *\) *)
    (*        ("virtcalls", cd_virtcalls)::namespace_params *)
    (*      ) *)
    (*   ) *)
    (* in *)

    let namespace_name : string = filter_xml_reserved_characters namespace.name in
    let namespace_params = List.append [("name", namespace_name);
                                        ("id", namespace_id)] []
    in
    let namespace_out : Xml.xml = Xmi.add_item "callgraph:namespace" namespace_params []
    in
    (* Parse records *)
    let namespace_records =
      (match namespace.records with
       | None -> []
       | Some records ->
         (
           List.map
             (fun rc -> self#record_to_ecore rc)
             records
         )
      )
    in
    let namespace_out = Xmi.add_childrens namespace_out namespace_records
    in
    Printf.printf "c2e.namespace_to_ecore:END: namespace=\"%s\"...\n" namespace.name;
    namespace_out

  method record_to_ecore (record:Callgraph_t.record) : Xml.xml =

    Printf.printf "c2e.record_to_ecore:BEGIN: record=\"%s\"...\n" record.fullname;

    let record_id = B64.encode record.fullname in

    (* Parse base classes *)
    let record_params =
      (match record.parents with
       | None -> []
       | Some parents ->
         (
           let parents : string =
             List.fold_left
               (
                 fun (p:string) (parent:Callgraph_t.inheritance) ->
                 let parent_b64 = B64.encode parent.record in
                 Printf.sprintf "%s %s" parent_b64 p
               )
               ""
               parents
           in
           [("parents", parents)]
         )
      )
    in

    (* Parse children classes *)
    let record_params =
      (match record.children with
       | None -> record_params
       | Some children ->
         (
           let children : string =
             List.fold_left
               (
                 fun (c:string) (child:Callgraph_t.inheritance) ->
                 let child_b64 = B64.encode child.record in
                 Printf.sprintf "%s %s" child_b64 c
               )
               ""
               children
           in
           ("children", children)::record_params
         )
      )
    in

    (* Parse record's method's declarations *)
    let record_params =
      (match record.meth_decls with
       | None -> record_params
       | Some methods ->
         (
           let decl_methods : string =
             List.fold_left
               (
                 fun (m:string) (meth:string) ->
                 Printf.sprintf "dc%s %s" meth m
               )
               ""
               methods
           in
           ("meth_decls", decl_methods)::record_params
         )
      )
    in

    (* Parse record's method's definitions *)
    let record_params =
      (match record.meth_defs with
       | None -> record_params
       | Some methods ->
         (
           let def_methods : string =
             List.fold_left
               (
                 fun (m:string) (meth:string) ->
                 Printf.sprintf "df%s %s" meth m
               )
               ""
               methods
           in
           ("meth_defs", def_methods)::record_params
         )
      )
    in

    (* Parse record's calls *)
    let record_params =
      (match record.calls with
       | None -> record_params
       | Some rc_calls ->
         (
           let cd_calls : string =
             List.fold_left
               (
                 fun (c:string) (call:string) ->
                 let call_b64 = B64.encode call in
                 (* Printf.printf "c2e.record_to_ecore:DEBUG: record:\"%s\", c:\"%s\", call=\"%s\", call_b64=\"%s\"\n" record.fullname c call call_b64; *)
                 Printf.sprintf "%s %s" call_b64 c
               )
               ""
               rc_calls
           in
           (* Printf.printf "c2e.record_to_ecore:INFO: record:\"%s\", calls:\"%s\"\n" record.fullname cd_calls; *)
           ("calls", cd_calls)::record_params
         )
      )
    in

    (* Parse record's virtual calls *)
    let record_params =
      (match record.virtcalls with
       | None -> record_params
       | Some rc_virtcalls ->
         (
           let cd_virtcalls : string =
             List.fold_left
               (
                 fun (c:string) (call:string) ->
                 let call_b64 = B64.encode call in
                 (* Printf.printf "c2e.record_to_ecore:DEBUG: record:\"%s\", c:\"%s\", call=\"%s\", call_b64=\"%s\"\n" record.fullname c call call_b64; *)
                 Printf.sprintf "%s %s" call_b64 c
               )
               ""
               rc_virtcalls
           in
           (* Printf.printf "c2e.record_to_ecore:INFO: record:\"%s\", virtcalls:\"%s\"\n" record.fullname cd_virtcalls; *)
           ("virtcalls", cd_virtcalls)::record_params
         )
      )
    in

    let record_fullname : string = filter_xml_reserved_characters record.fullname in
    let record_params = List.append [("name", record_fullname);
                                     ("path", record.decl);
                                     ("id", record_id)]
                                    record_params
    in

    let parent_out : Xml.xml = Xmi.add_item "callgraph:record" record_params []
    in

    Printf.printf "c2e.record_to_ecore:END: record=\"%s\"...\n" record.fullname;
    parent_out

  method thread_to_ecore (thread:Callgraph_t.thread) : Xml.xml =

    Printf.printf "c2e.thread_to_ecore:BEGIN: thread inst=\"%s\", id=\"%s\"...\n" thread.inst_name thread.id;

    let routine_decl = Printf.sprintf "dc%s" thread.routine_mangled in

    let caller_def = Printf.sprintf "df%s" thread.caller_mangled in

    let thread_params = List.append [("inst_name", thread.inst_name);
                                     ("id", thread.id);
                                     ("routine_file", thread.routine_file);
                                     ("routine", routine_decl);
                                     (* ("routine_name", thread.routine_name); *)
                                     (* ("routine_sign", thread.routine_sign); *)
                                     (* ("routine_mangled", thread.routine_mangled); *)
                                     ("caller", caller_def);
                                     (* ("caller_sign", thread.caller_sign); *)
                                     (* ("caller_mangled", thread.caller_mangled); *)
                                     ("create_location", thread.create_location)]
                                    []
    in

    let parent_out : Xml.xml = Xmi.add_item "callgraph:thread" thread_params []
    in

    Printf.printf "c2e.thread_to_ecore:END: thread inst=\"%s\", id=\"%s\"...\n" thread.inst_name thread.id;
    parent_out

  method dir_to_ecore (dir:Callgraph_t.dir) : Xml.xml =

    Printf.printf "callgraph_to_ecore.ml::INFO::callgraph_dir_to_ecore: dir=\"%s\"...\n" dir.name;

    let dir_id =
      (match dir.id with
       | None -> B64.encode dir.path
       | Some id -> id
      )
    in

    (* Parse parents directories *)
    let dir_params =
      (match dir.parents with
       | None -> []
       | Some parents ->
          (
            let parents : string =
              List.fold_left
                (
                  fun (p:string) (parent:string) ->
                  let parent_b64 = B64.encode parent in
                  Printf.sprintf "%s %s" parent_b64 p
                )
                ""
                parents
            in
            ("parents", parents)::[]
          )
      )
    in

    (* Parse children directories *)
    let dir_params =
      (match dir.children with
       | None -> dir_params
       | Some children ->
          (
            let children : string =
              List.fold_left
                (
                  fun (c:string) (child:string) ->
                  let child_b64 = B64.encode child in
                  Printf.sprintf "%s %s" child_b64 c
                )
                ""
                children
            in
            ("children", children)::dir_params
          )
      )
    in

    (* Parse called directories *)
    let dir_params =
      (match dir.calls with
       | None -> dir_params
       | Some calls ->
          (
            let calls : string =
              List.fold_left
                (
                  fun (c:string) (call:string) ->
                  let call_b64 = B64.encode call in
                  Printf.sprintf "%s %s" call_b64 c
                )
                ""
                calls
            in
            ("calls", calls)::dir_params
          )
      )
    in

    let dir_params = List.append [("name", dir.name);
                                  ("path", dir.path);
                                  ("id", dir_id)]
                                 dir_params
    in

    let parent_out : Xml.xml = Xmi.add_item "callgraph:dir" dir_params []
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
    parent_out

  method file_to_ecore (file:Callgraph_t.file) (path:string) =

    Printf.printf "callgraph_to_ecore.ml::INFO::callgraph_file_to_ecore: name=\"%s\"...\n" file.name;

    let filepath = Printf.sprintf "%s/%s" path file.name in

    let file_id =
      (match file.id with
       | None -> B64.encode filepath
       | Some id -> id
      )
    in

    let file_out : Xml.xml =
      (match file.calls with
       | None -> Xmi.add_item "files" [("name", file.name); ("kind", file.kind); ("path", filepath); ("id", file_id)] []
       | Some calls ->
          (
            (* let calls = String.concat " " calls in *)
            let calls : string =
              List.fold_left
                (
                  fun (c:string) (call:string) ->
                  let call_b64 = B64.encode call in
                  Printf.sprintf "%s %s" call_b64 c
                )
                ""
                calls
            in
            Xmi.add_item "files" [("name", file.name); ("kind", file.kind); ("path", filepath); ("id", file_id); ("calls", calls)] []
          )
      )
    in

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
      | _ -> Common.notify_error Common.Unsupported_Function_Kind
      )
    in

    let fonction_id =
      (match kind with
      | "declared" -> Printf.sprintf "dc%s" fonction.mangled
      | "defined" -> Printf.sprintf "df%s" fonction.mangled
      | _ -> Common.notify_error Common.Unsupported_Function_Kind
      )
    in

    (* Parse external function callers *)
    let function_properties = self#extcaller_to_ecore fonction []
    in

    (* Parse virtual function caller's decl *)
    let function_properties = self#virtcallerdecl_to_ecore fonction function_properties
    in

    (* Parse virtual function caller's def *)
    let function_properties = self#virtcallerdef_to_ecore fonction function_properties
    in

    (* Parse local function callers *)
    let function_properties = self#localler_to_ecore fonction function_properties
    in

    (* Parse local definition *)
    let function_properties = self#localdef_to_ecore fonction function_properties
    in

    (* Parse external definition *)
    let function_properties = self#extdef_to_ecore fonction function_properties
    in

    (* Parse virtual function redeclarations *)
    let function_properties = self#virtdecl_to_ecore fonction function_properties
    in

    let virtuality = Callers.fct_virtuality_option_to_string fonction.virtuality
    in

    (* Add record when needed *)
    let function_properties =
      (match fonction.record with
       | None -> function_properties
       | Some rc ->
          (
            let xml_rec : string = filter_xml_reserved_characters rc in
            List.append [("record", xml_rec)] function_properties
          )
      )
    in

    (* Add threads when needed *)
    let function_properties =
      (match fonction.threads with
       | None -> function_properties
       (* | Some thr -> List.append [("threads", thr)] function_properties *)
       | Some thr ->
          (
            let threads = String.concat " " thr
            in
            List.append [("threads", threads)] function_properties
          )
      )
    in

    let fonction_sign : string = filter_xml_reserved_characters fonction.sign in

    let function_properties = List.append [("sign", fonction_sign);
                                       ("id", fonction_id);
                                       ("virtuality", virtuality)] function_properties
    in

    let fonction_out : Xml.xml = Xmi.add_item flag function_properties []
    in

    (* Parse function parameters *)
    let fonction_params : Xml.xml list =
      (match fonction.params with
       | None -> []
       | Some params ->
          List.map
            (
              (* Add a uses xml entry *)
              fun (param:Callgraph_t.fct_param) ->
              let parameter : Xml.xml = self#parameter_to_ecore param fonction.mangled in
              parameter
            )
            params
      )
    in
    let fonction_out : Xml.xml = Xmi.add_childrens fonction_out fonction_params
    in
    fonction_out

  method parameter_to_ecore (param:Callgraph_t.fct_param) (fct_decl_mangled:string) : Xml.xml =

    Printf.printf "c2e.parameter_to_ecore:INFO: param=\"%s\", kind=\"%s\"\n" param.name param.kind;

    let param_id : string = Printf.sprintf "%s_%s" fct_decl_mangled param.name
    in
    let param_name : string = filter_xml_reserved_characters param.name in
    let param_kind : string = filter_xml_reserved_characters param.kind in
    let param_properties = List.append [("name", param_name);
                                        ("kind", param_kind);
                                        ("id",   param_id)] []
    in
    let parameter : Xml.xml = Xmi.add_item "param" param_properties []
    in
    parameter

  method function_def_to_ecore (fonction:Callgraph_t.fonction_def) (filepath:string) (kind:string) : Xml.xml =

    Printf.printf "c2e.function_def_to_ecore:INFO: sign=\"%s\"...\n" fonction.sign;

    let flag : string =
      (match kind with
      | "declared"
      | "defined"
	-> kind
      | _ -> Common.notify_error Common.Unsupported_Function_Kind
      )
    in

    let fonction_id =
      (match kind with
      | "declared" -> Printf.sprintf "dc%s" fonction.mangled
      | "defined" -> Printf.sprintf "df%s" fonction.mangled
      | _ -> Common.notify_error Common.Unsupported_Function_Kind
      )
    in

    (* Parse local function declarations *)
    let fonction_params = self#localdecl_to_ecore fonction []
    in

    (* Parse external function declarations *)
    let fonction_params = self#extdecl_to_ecore fonction fonction_params
    in

    (* Parse external function callees *)
    let fonction_params = self#extcallee_to_ecore fonction fonction_params
    in

    (* Parse virtual function callees *)
    let fonction_params = self#virtcallee_to_ecore fonction fonction_params
    in

    (* Parse local function callees *)
    let fonction_params = self#locallee_to_ecore fonction fonction_params
    in

    let virtuality = Callers.fct_virtuality_option_to_string fonction.virtuality
    in

    (* Add records when needed *)
    let fonction_params =
      (match fonction.record with
       | None -> fonction_params
       | Some rc ->
          (
            let xml_rec : string = filter_xml_reserved_characters rc in
            List.append [("record", xml_rec)] fonction_params
          )
      )
    in

    (* Add threads when needed *)
    let fonction_params =
      (match fonction.threads with
       | None -> fonction_params
       (* | Some thr -> List.append [("threads", thr)] fonction_params *)
       | Some thr ->
          (
            let threads = String.concat " " thr
            in
            List.append [("threads", threads)] fonction_params
          )
      )
    in

    let fonction_sign : string = filter_xml_reserved_characters fonction.sign in
    let fonction_params = List.append [("sign", fonction_sign);
                                       ("id", fonction_id);
                                       ("virtuality", virtuality)] fonction_params
    in

    let fonction_out : Xml.xml = Xmi.add_item flag fonction_params []
    in
    fonction_out

  method localdef_to_ecore (fonction:Callgraph_t.fonction_decl) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.localdef with
     | None ->
        (
          (* Printf.printf "c2e.localdef_to_ecore:DEBUG: no localdef for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some localdef ->
        let localdef = Printf.sprintf "df%s" localdef.mangled
        (* Printf.printf "c2e.localdef_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" localdef.sign fonction.sign ; *)
        in
        ("localdef", localdef)::fonction_params
    )

  method localdecl_to_ecore (fonction:Callgraph_t.fonction_def) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.localdecl with
     | None ->
        (
          Printf.printf "c2e.localdecl_to_ecore:WARNING: no localdecl for function \"%s\"\n" fonction.sign;
          fonction_params
        )
     | Some localdecl ->
        let localdecl : string = Printf.sprintf "dc%s" localdecl.mangled
        in
        ("localdecl", localdecl)::fonction_params
    )

  method localler_to_ecore (fonction:Callgraph_t.fonction_decl) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.locallers with
     | None ->
        (
          (* Printf.printf "c2e.localler_to_ecore:DEBUG: no locallers for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some locallers ->
        let locallers : string =
    	  List.fold_left
    	    (
    	      fun (refs:string) (localler:Callgraph_t.fct_ref) ->
              let refs = Printf.sprintf "df%s %s" localler.mangled refs in
              (* Printf.printf "c2e.localler_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" localler.sign fonction.sign ; *)
              refs
    	    )
            ""
    	    locallers
        in
        ("locallers", locallers)::fonction_params
    )

  method locallee_to_ecore (fonction:Callgraph_t.fonction_def) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.locallees with
     | None ->
        (
          (* Printf.printf "c2e.locallee_to_ecore:DEBUG: no locallees for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some locallees ->
        let locallees : string =
    	  List.fold_left
    	    (
    	      fun (refs:string) (locallee:Callgraph_t.fct_ref) ->
              let refs = Printf.sprintf "dc%s %s" locallee.mangled refs in
              (* Printf.printf "c2e.locallee_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" fonction.sign locallee.sign; *)
              refs
    	    )
            ""
    	    locallees
        in
        ("locallees", locallees)::fonction_params
    )

  method extdef_to_ecore (fonction:Callgraph_t.fonction_decl) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.extdefs with
     | None ->
        (
          (* Printf.printf "c2e.extdef_to_ecore:DEBUG: no extdef for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some [extdef] ->
        let extdef = Printf.sprintf "df%s" extdef.mangled
        (* Printf.printf "c2e.extdef_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" extdef.sign fonction.sign ; *)
        in
        ("extdef", extdef)::fonction_params
     | _ -> Common.notify_error Common.Unsupported_Case
    )

  method extcaller_to_ecore (fonction:Callgraph_t.fonction_decl) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.extcallers with
     | None ->
        (
          (* Printf.printf "c2e.extcaller_to_ecore:DEBUG: no extcallers for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some extcallers ->
        let extcallers : string =
    	  List.fold_left
    	    (
    	      fun (refs:string) (extcaller:Callgraph_t.extfct_ref) ->
              let refs = Printf.sprintf "df%s %s" extcaller.mangled refs in
              (* Printf.printf "c2e.extcaller_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" extcaller.sign fonction.sign ; *)
              refs
    	    )
            ""
    	    extcallers
        in
        ("extcallers", extcallers)::fonction_params
    )

  method extcallee_to_ecore (fonction:Callgraph_t.fonction_def) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.extcallees with
     | None ->
        (
          (* Printf.printf "c2e.extcallee_to_ecore:DEBUG: no extcallees for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some extcallees ->
        let extcallees : string =
    	  List.fold_left
    	    (
    	      fun (refs:string) (extcallee:Callgraph_t.extfct_ref) ->
              let refs = Printf.sprintf "dc%s %s" extcallee.mangled refs in
              (* Printf.printf "c2e.extcallee_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" fonction.sign extcallee.sign; *)
              refs
    	    )
            ""
    	    extcallees
        in
        ("extcallees", extcallees)::fonction_params
    )

  method extdecl_to_ecore (fonction:Callgraph_t.fonction_def) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.extdecls with
     | None ->
        (
          Printf.printf "c2e.extdecl_to_ecore:WARNING: no extdecl for function \"%s\"\n" fonction.sign;
          fonction_params
        )
     | Some extdecls ->
        let extdecl : string =
    	  List.fold_left
    	    (
    	      fun (refs:string) (extdecl:Callgraph_t.extfct_ref) ->
              let refs = Printf.sprintf "dc%s %s" extdecl.mangled refs in
              refs
    	    )
            ""
    	    extdecls
        in
        (* Printf.printf "c2e.extdecl_to_ecore:DEBUG: extdecl=%s\n" extdecl; *)
        ("extdecl", extdecl)::fonction_params
    )

  method virtdecl_to_ecore (fonction:Callgraph_t.fonction_decl) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.virtdecls with
     | None ->
        (
          (* Printf.printf "c2e.virtdecl_to_ecore:DEBUG: no virtdecls for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some virtdecls ->
        let virtdecls : string =
    	  List.fold_left
    	    (
    	      fun (refs:string) (virtdecl:Callgraph_t.fct_ref) ->
              let refs = Printf.sprintf "dc%s %s" virtdecl.mangled refs in
              (* Printf.printf "c2e.virtdecl_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" fonction.sign virtdecl.sign; *)
              refs
    	    )
            ""
    	    virtdecls
        in
        ("virtdecls", virtdecls)::fonction_params
    )

  method virtcallerdecl_to_ecore (fonction:Callgraph_t.fonction_decl) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.virtcallerdecls with
     | None ->
        (
          (* Printf.printf "c2e.virtcallerdecl_to_ecore:DEBUG: no virtcallerdecls for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some virtcallerdecls ->
        let virtcallerdecls : string =
    	  List.fold_left
    	    (
    	      fun (refs:string) (virtcallerdecl:Callgraph_t.extfct_ref) ->
              (* let refs = Printf.sprintf "df%s %s" virtcallerdecl.mangled refs in *)
              let refs = Printf.sprintf "dc%s %s" virtcallerdecl.mangled refs in
              (* Printf.printf "c2e.virtcallerdecl_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" virtcallerdecl.sign fonction.sign ; *)
              refs
    	    )
            ""
    	    virtcallerdecls
        in
        ("virtcallerdecls", virtcallerdecls)::fonction_params
    )

  method virtcallerdef_to_ecore (fonction:Callgraph_t.fonction_decl) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.virtcallerdefs with
     | None ->
        (
          (* Printf.printf "c2e.virtcallerdef_to_ecore:DEBUG: no virtcallerdefs for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some virtcallerdefs ->
        let virtcallerdefs : string =
    	  List.fold_left
    	    (
    	      fun (refs:string) (virtcallerdef:Callgraph_t.extfct_ref) ->
              let refs = Printf.sprintf "df%s %s" virtcallerdef.mangled refs in
              (* Printf.printf "c2e.virtcallerdef_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" virtcallerdef.sign fonction.sign ; *)
              refs
    	    )
            ""
    	    virtcallerdefs
        in
        ("virtcallerdefs", virtcallerdefs)::fonction_params
    )

  method virtcallee_to_ecore (fonction:Callgraph_t.fonction_def) (fonction_params:(string * string) list) : (string * string ) list =

    (match fonction.virtcallees with
     | None ->
        (
          (* Printf.printf "c2e.virtcallee_to_ecore:DEBUG: no virtcallees for function \"%s\"\n" fonction.sign; *)
          fonction_params
        )
     | Some virtcallees ->
        let virtcallees : string =
    	  List.fold_left
    	    (
    	      fun (refs:string) (virtcallee:Callgraph_t.extfct_ref) ->
              let refs = Printf.sprintf "dc%s %s" virtcallee.mangled refs in
              (* Printf.printf "c2e.virtcallee_to_ecore:DEBUG: vcaller=%s, vcallee=%s\n" fonction.sign virtcallee.sign; *)
              refs
    	    )
            ""
    	    virtcallees
        in
        ("virtcallees", virtcallees)::fonction_params
    )

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
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -package xml-light -package base64 -tag thread callgraph_to_ecore.native" *)
(* End: *)
