(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

(* Function callgraph *)
class function_callgraph
  = object(self)

  val mutable json_rootdir : Callgraph_t.top option = Some {
       path = "/tmp/callers";
       id = None;
       logical_view = None;
       physical_view = None;
       runtime_view = None;
     }

  val mutable cdir : Callgraph_t.dir =
    let dir : Callgraph_t.dir =
      {
        name = "tmpCurrDir";
        path = "pathCurrDir";
        id = None;
        includes = None;
        calls = None;
        virtcalls = None;
        children = None;
        parents = None;
        files = None
      }
    in
    dir

  val mutable rdir : Callgraph_t.dir =
    let dir : Callgraph_t.dir =
      {
        name = "tmpRootDir";
        path = "pathRootDir";
        id = None;
        includes = None;
        calls = None;
        virtcalls = None;
        children = None;
        parents = None;
        files = None
      }
    in
    dir

  method init_top (path:string) : Callgraph_t.top =

    let top : Callgraph_t.top =
      {
        path = path;
        id = None;
        logical_view = None;
        physical_view = None;
        runtime_view = None;
      }
    in
    top

  method init_dir (name:string) (path:string) (id:string) : Callgraph_t.dir =

    let dir : Callgraph_t.dir =
      {
        name = name;
        path = path;
        id = None;
        includes = None;
        calls = None;
        virtcalls = None;
        children = None;
        parents = None;
        files = None
      }
    in
    dir

  method copy_dir (org:Callgraph_t.dir) : Callgraph_t.dir =

    let dest : Callgraph_t.dir =
      {
        name = org.name;
        path = org.path;
        id = None;
        includes = None;
        calls = org.calls;
        virtcalls = None;
        children = org.children;
        parents = None;
        files = org.files
      }
    in
    dest

  (* Adds the "parent" dependency only if not already present between the two directories *)
  method dir_add_parent (dir:Callgraph_t.dir) (parent_path:string) : unit =

    Printf.printf "fcg.dir_add_parent:BEGIN: tries to add include dependency from dir \"%s\" to dir \"%s\"\n" dir.name parent_path;
    let parents : string list option =
      (match dir.parents with
       | None -> Some [parent_path]
       | Some parents ->
          (
            try
              (
                List.find
                  (
                    fun parent -> ( String.compare parent parent_path == 0 )
                  )
                  parents;
                (* Printf.printf "fcg.dir_add_parents:INFO: do not add already existing include dependency between directories %s and %s" dir.path parent_path; *)
                Some parents
              )
            with
              Not_found ->
              (
                Printf.printf "fcg.dir_add_parent:INFO: add an include dependency between directories %s and %s" dir.path parent_path;
                Some (parent_path::parents)
              )
          )
      )
    in
    dir.parents <- parents

  (* Adds the "child" dependency only if not already present between the two directories *)
  method dir_add_child (dir:Callgraph_t.dir) (child_path:string) : unit =

    Printf.printf "fcg.dir_add_child:BEGIN: tries to add include dependency from dir \"%s\" to dir \"%s\"\n" dir.name child_path;
    let children : string list option =
      (match dir.children with
       | None -> Some [child_path]
       | Some children ->
          (
            try
              (
                List.find
                  (
                    fun child -> ( String.compare child child_path == 0 )
                  )
                  children;
                (* Printf.printf "fcg.dir_add_children:INFO: do not add already existing include dependency between directories %s and %s" dir.path child_path; *)
                Some children
              )
            with
              Not_found ->
              (
                Printf.printf "fcg.dir_add_child:INFO: add an include dependency between directories %s and %s" dir.path child_path;
                Some (child_path::children)
              )
          )
      )
    in
    dir.children <- children

  (* Adds the "includes" dependency only if not already present between the two directories *)
  method dir_add_includes (dir:Callgraph_t.dir) (dirpath:string) : unit =

    Printf.printf "Try to add include dependency from dir \"%s\" to dir \"%s\"\n" dir.name dirpath;
    let includes : string list option =
      (match dir.includes with
       | None -> Some [dirpath]
       | Some includes ->
          (
            try
              (
                List.find
                  (
                    fun inc -> ( String.compare inc dirpath == 0 )
                  )
                  includes;
                (* Printf.printf "fcg.dir_add_includes:INFO: do not add already existing include dependency between directories %s and %s" dir.path dirpath; *)
                Some includes
              )
            with
              Not_found ->
              (
                Printf.printf "fcg.dir_add_includes:INFO: add an include dependency between directories %s and %s" dir.path dirpath;
                Some (dirpath::includes)
              )
          )
      )
    in
    dir.includes <- includes

  (* This method checks whether the input calls is already registered in the directory *)
  method dir_add_calls (caller_dir:Callgraph_t.dir) (callee_dirpath:string) : unit =

    Printf.printf "fcg.dir_add_calls:BEGIN: add the calls \"%s\" only if not already present in dir \"%s\"\n" callee_dirpath caller_dir.name;

    (* Do not add a calls dependency if caller and callees share exactly the same directory *)
    if( String.compare caller_dir.path callee_dirpath != 0 ) then
      (
        let present = self#get_calls_in_dir caller_dir callee_dirpath in
        (match present with
         | Some f -> Printf.printf "fcg.dir_add_calls:INFO: calls \"%s\" is already present in dir \"%s\"\n" callee_dirpath caller_dir.name;
         | None ->
            (
              Printf.printf "fcg.dir_add_calls:INFO: add calls \"%s\" to dir \"%s\"\n" callee_dirpath caller_dir.name;
              let calls : string list option =
                (match caller_dir.calls with
                 | None -> Some [callee_dirpath]
                 | Some calls -> Some (callee_dirpath::calls)
                )
              in
              caller_dir.calls <- calls
            )
        )
      )

  method dir_check_dep (caller_dir:Callgraph_t.dir) (callee_filepath:string) : unit =

    (* Add a child dir in case the callee_file is contained in caller dir *)
    let (callee_dirpath, _) = Batteries.String.rsplit callee_filepath "/" in
    if(Graph_dir.is_subdir_of callee_dirpath caller_dir.path) then
      (
        Printf.printf "fcg.dir_check_dep:DEBUG: dir2 is a subdir of dir1 with dir1=%s and dir2=%s\n" caller_dir.path callee_dirpath;
        self#dir_add_child caller_dir callee_dirpath
      )
    else
      (
        Printf.printf "fcg.dir_check_dep:DEBUG: dir2 is external to dir1 with dir1=%s and dir2=%s\n" caller_dir.path callee_dirpath;
      );

    (* Add a calls reference to fc_dir in case the callee_file is really called by dir and is different from dir *)
    if(String.compare caller_dir.path callee_filepath != 0) then
      (
        Printf.printf "fcg.dir_check_dep:INFO: add a calls link from dir1=%s to dir2=%s\n" caller_dir.path callee_dirpath;
        self#dir_add_calls caller_dir callee_dirpath
      )

  (* Add a file in the callgraph if not present *)
  method dir_get_file_or_add_new (file_path:string) : Callgraph_t.file =

    Printf.printf "extract_fcg.dir_get_file_or_add_new:BEGIN: %s\n" file_path;
    let (file_path, file_name) = Batteries.String.rsplit file_path "/" in
    let file_kind = Common.file_get_kind file_name in

    let file : Callgraph_t.file =
      {
        name = file_name;
        kind = file_kind;
        includes = None;
        id = None;
        calls = None;
        virtcalls = None;
        (* records = None; *)
        declared = None;
        defined = None;
      }
    in
    (* let rdir = self#get_fcg_rootdir in *)
    let file = self#complete_fcg_file file_path file in

    Printf.printf "extract_fcg.dir_get_file_or_add_new:END: %s\n" file_path;
    file

  (* This method checks whether the input file is already registered in the directory *)
  method dir_add_file (dir:Callgraph_t.dir) (file:Callgraph_t.file) : unit =

    Printf.printf "fcg.add_file:BEGIN: add the file \"%s\" only if not already present in dir \"%s\"\n" file.name dir.name;

    let present = self#get_file_in_dir dir file.name in
    (match present with
    | Some f -> Printf.printf "File \"%s\" is already present in dir \"%s\"\n" file.name dir.name;
    | None ->
       (
         Printf.printf "Add file \"%s\" to dir \"%s\"\n" file.name dir.name;
         let files : Callgraph_t.file list option =
           (match dir.files with
            | None -> Some [file]
            | Some files -> Some (file::files)
           )
         in
         dir.files <- files
       )
    )

  (* precondition: here we suppose that the record is not yet present in file *)
  method top_add_record (record:Callgraph_t.record) : unit =

    Printf.printf "fcg.top_add_record:BEGIN: add the record \"%s\"\n" record.fullname;

    let rootdir = self#get_fcg_rootdir in
    (match rootdir.logical_view with
     | None -> ( rootdir.logical_view <- Some [record])
     | Some records -> ( rootdir.logical_view <- Some (record::records))
    )

  method file_get_record_or_add_new (record_filepath:string) (record_name:string) : Callgraph_t.record =

    Printf.printf "fcg.file_get_record_or_add_new:BEGIN: record_name=%s, recode_filename=%s\n" record_name record_filepath;
    (* First we check if the record has already been registered or not *)
    let does_already_exist = self#get_record record_name in
    let fcg_record : Callgraph_t.record =
      (match does_already_exist with
       | None ->
          (
            let callers_record : Callers_t.record option = Common.parse_record_in_file record_name record_filepath in
            let record : Callgraph_t.record =
            (match callers_record with
               | None ->
                  (
                    let new_record : Callgraph_t.record =
                      {
                        fullname = record_name;
                        kind = "class";
                        decl = "UnknownRecordDeclFileLocation";
                        parents = None;
                        children = None;
                        meth_decls = None;
                        meth_defs = None;
                        id = None;
                        includes = None;
                        calls = None;
                        virtcalls = None;
                      }
                    in
                    new_record
                  )
               | Some rc ->
                  (
                    let base_classes : Callgraph_t.inheritance list option =
                      (match rc.inherits with
                      | None -> None
                      | Some parents ->
                         Some (
                             List.map
                               ( fun (bc:Callers_t.inheritance) ->
                                 let parent : Callgraph_t.inheritance =
                                   {
                                     record = bc.record;
                                     decl = bc.file;
                                   }
                                 in parent
                               )
                               parents
                           )
                      )
                    in
                    let child_classes : Callgraph_t.inheritance list option =
                      (match rc.inherited with
                      | None -> None
                      | Some children ->
                         Some (
                             List.map
                               ( fun (ch:Callers_t.inheritance) ->
                                 let child : Callgraph_t.inheritance =
                                   {
                                     record = ch.record;
                                     decl = ch.file;
                                   }
                                 in child
                               )
                               children
                           )
                      )
                    in
                    let record : Callgraph_t.record =
                      {
                        fullname = rc.name;
                        kind = rc.kind;
                        decl = record_filepath;
                        parents = base_classes;
                        children  = child_classes;
                        meth_decls = None;
                        meth_defs = None;
                        id = None;
                        calls = None;
                        virtcalls = None;
                        includes = None;
                      }
                    in
                    record
                  )
            )
            in
            self#top_add_record record;
            record
          )
       | Some existing_record -> existing_record
      )
    in
    Printf.printf "fcg.file_get_record_or_add_new:END: record_name=%s, recode_filename=%s\n" record_name record_filepath;
    fcg_record

  (* precondition: here we suppose that the thread is not yet present in file *)
  method top_add_thread (thread:Callgraph_t.thread) : unit =

    Printf.printf "fcg.top_add_thread:BEGIN: add the thread instance \"%s\"\n" thread.inst_name;

    let rootdir = self#get_fcg_rootdir in
    (match rootdir.runtime_view with
     | None -> ( rootdir.runtime_view <- Some [thread])
     | Some threads -> ( rootdir.runtime_view <- Some (thread::threads))
    )

  method file_get_thread_or_add_new (thread_filepath:string) (thr_inst_name:string) : Callgraph_t.thread =

    Printf.printf "fcg.file_get_thread_or_add_new:BEGIN: thr_inst_name=%s, thr_inst_filename=%s\n" thr_inst_name thread_filepath;
    (* First we check if the thread has already been registered or not *)
    let does_already_exist = self#get_thread thr_inst_name in
    let fcg_thread : Callgraph_t.thread =
      (match does_already_exist with
       | None ->
          (
            let does_thread_exist : Callers_t.thread option = Common.parse_thread_in_file thr_inst_name thread_filepath in
            let thread : Callgraph_t.thread =
              (match does_thread_exist with
               | None -> raise Common.Unexpected_Case
                 (* ( *)
                 (*   let new_thread : Callgraph_t.thread = *)
                 (*     { *)
                 (*       inst_name = thr_inst_name; *)
                 (*       routine_name = "unknown_routine_name"; *)
                 (*       routine_sign = "unknown_routine_sign"; *)
                 (*       routine_mangled = "unknown_routine_mangled"; *)
                 (*       caller_sign = "unknown_caller_sign"; *)
                 (*       caller_mangled = "unknown_caller_mangled"; *)
                 (*       create_location = "unknown_create_location"; *)
                 (*       id = "id"; *)
                 (*     } *)
                 (*   in *)
                 (*   new_thread *)
                 (* ) *)
               | Some thr ->
                   let existing_thread : Callgraph_t.thread =
                     {
                       inst_name = thr.inst;
                       routine_file = thr.routine_file;
                       routine_name = thr.routine_name;
                       routine_sign = thr.routine_sign;
                       routine_mangled = thr.routine_mangled;
                       (* caller_file = thr.caller_file; *)
                       caller_sign = thr.caller_sign;
                       caller_mangled = thr.caller_mangled;
                       create_location = thr.loc;
                       id = thr.id;
                     }
                   in
                   existing_thread
              )
            in
            self#top_add_thread thread;
            thread
          )
       | Some existing_thread -> existing_thread
      )
    in
    Printf.printf "fcg.file_get_thread_or_add_new:END: thr_inst_name=%s, thr_inst_filename=%s\n" thr_inst_name thread_filepath;
    fcg_thread

  (* Adds the "includes" dependency only if not already present between the two files *)
  method file_add_include (file:Callgraph_t.file) (filepath:string) (dir:string) : unit =

    Printf.printf "Try to add include dependency from file \"%s\" to file \"%s\"\n" file.name filepath;
    let includes : string list option =
      (match file.includes with
       | None -> Some [filepath]
       | Some includes ->
          (
            try
              (
                let filepath = Printf.sprintf "%s/%s" dir file.name in
                List.find
                  (
                    fun inc -> ( String.compare inc filepath == 0 )
                  )
                  includes;
                (* Printf.printf "fcg.file_add_includes:INFO: do not add already existing include dependency between files %s/%s and %s" dir file.name filepath; *)
                Some includes
              )
            with
              Not_found ->
              (
                Printf.printf "fcg.file_add_includes:INFO: add an include dependency between files %s/%s and %s" dir file.name filepath;
                Some (filepath::includes)
              )
          )
      )
    in
    file.includes <- includes

  (* Adds the "calls" dependency only if not already present between the two files *)
  method file_add_calls (caller_file:Callgraph_t.file) (caller_filepath:string) (callee_filepath:string) : unit =

    (* Printf.printf "fcg.file_add_calls:BEGIN: try to add function call dependency from file \"%s\" to file \"%s\"\n" caller_filepath callee_filepath; *)
    (* let callee_filepath_b64 = B64.encode callee_filepath in *)
    let calls : string list option =
      (match caller_file.calls with
       | None ->
          (
            Printf.printf "fcg.file_add_calls:END: add a function call dependency between files %s and %s\n" caller_filepath callee_filepath;
            (* Some [callee_filepath_b64] *)
            Some [callee_filepath]
          )
       | Some calls ->
          (
            try
              (
                List.find
                  (
                    (* fun call -> ( String.compare call callee_filepath_b64 == 0 ) *)
                    fun call -> ( String.compare call callee_filepath == 0 )
                  )
                  calls;
                (* Printf.printf "fcg.file_add_calls:END: do not add already existing function call dependency between files %s and %s\n" caller_filepath callee_filepath; *)
                Some calls
              )
            with
              Not_found ->
              (
                Printf.printf "fcg.file_add_calls:INFO: add a function call dependency between files %s and %s\n" caller_filepath callee_filepath;
                (* Some (callee_filepath_b64::calls) *)
                Some (callee_filepath::calls)
              )
          )
      )
    in
    caller_file.calls <- calls

  method file_list_calls (file:Callgraph_t.file) (filepath:string) : unit =

    (match file.calls with
       | None -> ()
                ; Printf.printf "fcg.file_list_calls:DEBUG: file \"%s\" has not yet calls dependencies\n" filepath
       | Some calls ->
          (
            List.iter
              (fun call ->
               Printf.printf "fcg.file_list_calls:DEBUG: file \"%s\" calls file \"%s\"\n" filepath call
              )
              calls
          )
    )

  method get_fct_decl (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction_decl option =

    try
      (
        (match file.declared with
         | None -> None
         | Some declared ->
           (
             let fct =
               List.find
                 (
                   fun (fct:Callgraph_t.fonction_decl) -> (String.compare fct.sign fct_sign == 0)
                 )
                 declared
             in
             Some fct
           )
        )
      )
    with
      Not_found -> None

  method add_fct_decls (file:Callgraph_t.file) (fct_decls:Callgraph_t.fonction_decl list) : unit =

    let decls : Callgraph_t.fonction_decl list option =
      (match file.declared with
       | None -> Some fct_decls
       | Some decls ->
          Some
            (
              List.fold_left
                (
                  fun (decls:Callgraph_t.fonction_decl list)
                      (def:Callgraph_t.fonction_decl) ->
                  def::decls
                )
                decls
                fct_decls
            )
      )
    in
    Printf.printf "fcg.add_fct_decls:INFO: Add the following fonction declarations in file \"%s\":\n" file.name;
    List.iter
      (fun (def:Callgraph_t.fonction_decl) -> Printf.printf " %s\n" def.sign )
      fct_decls;
    file.declared <- decls

  method get_fct_def (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction_def option =

    try
      (
        (match file.defined with
         | None -> None
         | Some defined ->
           (
             let fct =
               List.find
                 (
                   fun (fct:Callgraph_t.fonction_def) -> (String.compare fct.sign fct_sign == 0)
                 )
                 defined
             in
             Some fct
           )
        )
      )
    with
      Not_found -> None

  method add_fct_defs (file:Callgraph_t.file) (fct_defs:Callgraph_t.fonction_def list) : unit =

    let defs : Callgraph_t.fonction_def list option =
      (match file.defined with
       | None -> Some fct_defs
       | Some defs ->
         (
           Printf.printf "Preexisting fonction definitions in file \"%s\" are:\n" file.name;
           List.iter
             (fun (def:Callgraph_t.fonction_def) -> Printf.printf " %s\n" def.sign )
             defs;

           Some
             (
               List.fold_left
                 (
                   fun (defs:Callgraph_t.fonction_def list)
                       (def:Callgraph_t.fonction_def) ->
                   def::defs
                 )
                 defs
                 fct_defs
             )
         )
      )
    in
    Printf.printf "fcg.add_fct_defs:INFO: Add the following fonction definitions in file \"%s\":\n" file.name;
    List.iter
      (fun (def:Callgraph_t.fonction_def) -> Printf.printf " %s\n" def.sign )
      fct_defs;
    file.defined <- defs

  (* exception: Usage_Error in case "fct_def.sign != fct_decl.sign" *)
  method add_fct_localdecl (fct_def:Callgraph_t.fonction_def) (fct_decl:Callgraph_t.fonction_decl) : unit (* Callgraph_t.fonction_def *) =

    Printf.printf "fcg.add_fct_localdecl: fct=\"%s\"\n" fct_def.sign;

    if (String.compare fct_def.sign fct_decl.sign != 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_localdecl:ERROR: (fct_def==%s) != (fct_decl==%s)\n" fct_def.sign fct_decl.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct_def.localdecl with
     | None ->
        (
          let virtuality = Callers.fct_virtuality_option_to_string fct_decl.virtuality
          in
          let fdecl : Callgraph_t.fct_ref =
            {
              sign = fct_decl.sign;
              mangled = fct_decl.mangled;
              virtuality = virtuality;
            }
          in
          fct_def.localdecl <- Some fdecl
          (* fct_def *)
        )
     | Some localdecl ->
        (* Raise an exception if the existing local declaration is not the good one *)
        if( String.compare fct_def.sign localdecl.sign == 0) then
        (
          Printf.printf "fcg.function_callgraph:WARNING: already existing local declaration of function \"%s\"\n" fct_def.sign
          (* fct_def *)
        )
        else
        (
          raise Common.Unexpected_Local_Declaration
        )
    )

  (* exception: Usage_Error in case "fct_decl.sign != fct_def.sign" *)
  method add_fct_localdef (fct_decl:Callgraph_t.fonction_decl) (fct_def:Callgraph_t.fonction_def) : unit =

    Printf.printf "fcg.add_fct_localdef: fct=\"%s\"\n" fct_decl.sign;

    if (String.compare fct_decl.sign fct_def.sign != 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_localdef:ERROR: (fct_decl==%s) != (fct_def==%s)\n" fct_decl.sign fct_def.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct_decl.localdef with
     | None ->
        (
          let virtuality = Callers.fct_virtuality_option_to_string fct_def.virtuality
          in
          let fdef : Callgraph_t.fct_ref =
            {
              sign = fct_def.sign;
              mangled = fct_def.mangled;
              virtuality = virtuality;
            }
          in
          fct_decl.localdef <- Some fdef
        )
     | Some localdef ->
        (* Raise an exception if the existing local definition is not the good one *)
        if( String.compare fct_decl.sign localdef.sign == 0) then
        (
          Printf.printf "fcg.function_callgraph:WARNING: already existing local definition of function \"%s\"\n" fct_decl.sign
        )
        else
        (
          Printf.printf "fcg.function_callgraph:ERROR: unexpected local definition \"%s\" of function \"%s\"\n" localdef.sign fct_decl.sign;
          raise Common.Unexpected_Local_Definition
        )
    )

  (* exception: Usage_Error in case "fct_def.sign != fct_decl.sign" *)
  method add_fct_extdecl (fct_def:Callgraph_t.fonction_def) (fct_decl:Callgraph_t.fonction_decl) (fct_decl_file:string) : unit =

    Printf.printf "fcg.add_fct_extdecl: fct=\"%s\"\n" fct_def.sign;

    if (String.compare fct_def.sign fct_decl.sign != 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_extdecl:ERROR: (fct_def==%s) != (fct_decl==%s)\n" fct_def.sign fct_decl.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct_def.extdecls with
     | None ->
        (
          let virtuality = Callers.fct_virtuality_option_to_string fct_decl.virtuality
          in
          let fdecl : Callgraph_t.extfct_ref =
            {
              sign = fct_decl.sign;
              mangled = fct_decl.mangled;
              virtuality = virtuality;
              file = fct_decl_file;
            }
          in
          fct_def.extdecls <- Some [fdecl]
        )
     | Some [extdecl] ->
        (* Raise an exception if the existing local declaration is not the good one *)
        if( String.compare fct_def.sign extdecl.sign == 0) then
        (
          Printf.printf "fcg.function_callgraph:WARNING: already existing local declaration of function \"%s\"\n" fct_def.sign
        )
        else
        (
          raise Common.Unexpected_Extern_Declaration
        )
     | _ -> raise Common.Unexpected_Extern_Declaration
    )

  (* exception: Usage_Error in case "fct_decl.sign != fct_def.sign" *)
  method add_fct_extdef (fct_decl:Callgraph_t.fonction_decl) (fct_def:Callgraph_t.fonction_def) (fct_def_filepath:string) : unit =

    Printf.printf "fcg.add_fct_extdef: fct=\"%s\"\n" fct_decl.sign;

    if (String.compare fct_decl.sign fct_def.sign != 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_extdef:ERROR: (fct_decl==%s) != (fct_def==%s)\n" fct_decl.sign fct_def.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct_decl.extdefs with
     | None ->
        (
          let virtuality = Callers.fct_virtuality_option_to_string fct_def.virtuality
          in
          let fdef : Callgraph_t.extfct_ref =
            {
              sign = fct_def.sign;
              mangled = fct_def.mangled;
              virtuality = virtuality;
              file = fct_def_filepath;
            }
          in
          fct_decl.extdefs <- Some [fdef]
        )
     | Some [extdef] ->
        (* Raise an exception if the existing local definition is not the good one *)
        if( String.compare fct_decl.sign extdef.sign == 0) then
        (
          Printf.printf "fcg.function_callgraph:WARNING: already existing local definition of function \"%s\"\n" fct_decl.sign
        )
        else
        (
          raise Common.Unexpected_Extern_Definition
        )
     | _ -> raise Common.Unexpected_Extern_Definition
    )

  method add_fct_virtdecl (vfct_decl:Callgraph_t.fonction_decl) (vfct_redecl:Callgraph_t.fonction_decl) : unit =

    Printf.printf "fcg.add_fct_virtdecl: fct=\"%s\"\n" vfct_decl.sign;

    if (String.compare vfct_decl.sign vfct_redecl.sign != 0) then
      (
        Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
        Printf.printf "fcg: add_fct_virtdecl:WARNING: (vfct_decl==%s) != (vfct_redecl==%s)\n" vfct_decl.sign vfct_redecl.sign;
        Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
      );
    let virtuality = Callers.fct_virtuality_option_to_string vfct_redecl.virtuality in
    let virt_redecl : Callgraph_t.fct_ref =
      {
        sign = vfct_redecl.sign;
        mangled = vfct_redecl.mangled;
        virtuality = virtuality;
      }
    in
    (match vfct_decl.virtdecls with
     | None -> (vfct_decl.virtdecls <- Some [virt_redecl])
     | Some virtdecls ->
        (* Add the virtdecl only if it is not already present. *)
        (
          try
           let vf =
              List.find
               ( fun (vf:Callgraph_t.fct_ref) -> String.compare vf.sign vfct_redecl.sign == 0)
              virtdecls
           in ()
          with
            Not_found -> (vfct_decl.virtdecls <- Some (virt_redecl::virtdecls))
        )
    )

  (* exception: Usage_Error in case "fct.sign == locallee_sign" *)
  method add_fct_locallee (fct:Callgraph_t.fonction_def) (locallee:Callgraph_t.fct_ref) : unit =

    Printf.printf "fcg.add_fct_locallee: fct=\"%s\", locallee=\"%s\"\n" fct.sign locallee.sign;

    if (String.compare fct.sign locallee.sign == 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_locallee:ERROR: caller = callee = %s\n" locallee.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct.locallees with
     | None -> (fct.locallees <- Some [locallee])
     | Some locallees ->
        (* Add the locallee only if it is not already present. *)
        (
          try
           let l =
              List.find
               ( fun (l:Callgraph_t.fct_ref) -> String.compare l.sign locallee.sign == 0)
              locallees
           in ()
          with
            Not_found -> (fct.locallees <- Some (locallee::locallees))
        )
    )

  (* exception: Usage_Error in case "fct.sign == localler_sign" *)
  method add_fct_localler (fct:Callgraph_t.fonction_decl) (localler:Callgraph_t.fct_ref) : unit =

    Printf.printf "fcg.add_fct_localler: fct=\"%s\", localler=\"%s\"\n" fct.sign localler.sign;

    if (String.compare fct.sign localler.sign == 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_localler:ERROR: caller = callee = %s\n" localler.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct.locallers with
     | None -> (fct.locallers <- Some [localler])
     | Some locallers ->
       (* Add the localler only if it is not already present *)
       (
         try
          let l =
             List.find
              ( fun (l:Callgraph_t.fct_ref) -> String.compare l.sign localler.sign == 0)
             locallers
          in ()
         with
           Not_found -> (fct.locallers <- Some (localler::locallers))
       )
    )

  (* exception: Usage_Error in case "fct.sign == extcallee.sign" *)
  method add_fct_extcallee (fct:Callgraph_t.fonction_def) (extcallee:Callgraph_t.extfct_ref) : unit =

    Printf.printf "fcg.add_fct_extcallee: fct=\"%s\", extcallee=\"%s\"\n" fct.sign extcallee.sign;

    if (String.compare fct.sign extcallee.sign == 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_extcallee:ERROR: caller = callee = %s\n" extcallee.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct.extcallees with
     | None -> (fct.extcallees <- Some [extcallee])
     | Some extcallees ->
        (* Add the extcallee only if it is not already present. *)
        (
          try
           let l =
              List.find
               ( fun (l:Callgraph_t.extfct_ref) -> String.compare l.sign extcallee.sign == 0)
              extcallees
           in ()
          with
            Not_found -> (fct.extcallees <- Some (extcallee::extcallees))
        )
    )

  (* exception: Usage_Error in case "fct.sign == extcaller_sign" *)
  method add_fct_extcaller (fct:Callgraph_t.fonction_decl) (extcaller:Callgraph_t.extfct_ref) : unit =

    Printf.printf "fcg.add_fct_extcaller: fct=\"%s\", extcaller=\"%s\"\n" fct.sign extcaller.sign;

    if (String.compare fct.sign extcaller.sign == 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_extcaller:ERROR: caller = callee = %s\n" extcaller.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct.extcallers with
     | None -> (fct.extcallers <- Some [extcaller])
     | Some extcallers ->
        (* Add the extcaller only if it is not already present. *)
        (
          try
           let l =
              List.find
               ( fun (l:Callgraph_t.extfct_ref) -> String.compare l.sign extcaller.sign == 0)
              extcallers
           in ()
          with
            Not_found -> (fct.extcallers <- Some (extcaller::extcallers))
        )
    )

  (* exception: Usage_Error in case "fct.sign == virtcallee_sign" *)
  method add_fct_virtcallee (fct:Callgraph_t.fonction_def) (virtcallee:Callgraph_t.extfct_ref) : unit =

    Printf.printf "fcg.add_fct_virtcallee: fct=\"%s\", virtcallee=\"%s\"\n" fct.sign virtcallee.sign;

    if (String.compare fct.sign virtcallee.sign == 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_virtcallee:ERROR: caller = callee = %s\n" virtcallee.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct.virtcallees with
     | None -> (fct.virtcallees <- Some [virtcallee])
     | Some virtcallees ->
        (* Add the virtcallee only if it is not already present. *)
        (
          try
           let l =
              List.find
               ( fun (l:Callgraph_t.extfct_ref) -> String.compare l.sign virtcallee.sign == 0)
              virtcallees
           in ()
          with
            Not_found -> (fct.virtcallees <- Some (virtcallee::virtcallees))
        )
    )

  (* exception: Usage_Error in case "fct.sign == virtcaller_sign" *)
  method add_fct_virtcaller (fct:Callgraph_t.fonction_decl) (virtcaller:Callgraph_t.extfct_ref) : unit =

    Printf.printf "fcg.add_fct_virtcaller: fct=\"%s\", virtcaller=\"%s\", virtfile=\"%s\"\n" fct.sign virtcaller.sign virtcaller.file;

    if (String.compare fct.sign virtcaller.sign == 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_virtcaller:ERROR: caller = callee = %s\n" virtcaller.sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Usage_Error
      );

    (match fct.virtcallers with
     | None -> (fct.virtcallers <- Some [virtcaller])
     | Some virtcallers ->
        (* Add the virtcaller only if it is not already present. *)
        (
          try
           let l =
              List.find
               ( fun (l:Callgraph_t.extfct_ref) -> String.compare l.sign virtcaller.sign == 0)
              virtcallers
           in ()
          with
            Not_found -> (fct.virtcallers <- Some (virtcaller::virtcallers))
        )
    )

method record_has_method_decl (record:Callgraph_t.record) (method_sign:string) : bool =

  (match record.meth_decls with
   | None -> false
   | Some methods ->
      (
        try
          (
            let _ =
              List.find
                (
                  fun (meth_sign:string) -> (String.compare meth_sign method_sign == 0)
                )
                methods
            in
            true
          )
        with
          Not_found -> false
      )
  )

method record_has_method_def (record:Callgraph_t.record) (method_sign:string) : bool =

  (match record.meth_defs with
   | None -> false
   | Some methods ->
      (
        try
          (
            let _ =
              List.find
                (
                  fun (meth_sign:string) -> (String.compare meth_sign method_sign == 0)
                )
                methods
            in
            true
          )
        with
          Not_found -> false
      )
  )

  method record_add_method_decl (record:Callgraph_t.record) (method_decl:string) : unit =

    Printf.printf "fcg.record_add_method_decl:BEGIN: add the method decl \"%s\" only if not already present in record \"%s\"\n" method_decl record.fullname;

    let present = self#record_has_method_decl record method_decl in
    (match present with
    | true -> Printf.printf "fcg.record_add_method_decl:INFO: method decl \"%s\" is already present in record \"%s\"\n" method_decl record.fullname;
    | false ->
       (
         Printf.printf "fcg.record_add_method:INFO: add method decl \"%s\" to record \"%s\"\n" method_decl record.fullname;
         let methods : string list option =
           (match record.meth_decls with
            | None -> Some [method_decl]
            | Some methods -> Some (method_decl::methods)
           )
         in
         record.meth_decls <- methods
       )
    )

  method record_add_method_def (record:Callgraph_t.record) (method_def:string) : unit =

    Printf.printf "fcg.record_add_method_def:BEGIN: add the method definition \"%s\" only if not already present in record \"%s\"\n" method_def record.fullname;

    let present = self#record_has_method_def record method_def in
    (match present with
    | true -> Printf.printf "fcg.record_add_method_def:INFO: method definition \"%s\" is already present in record \"%s\"\n" method_def record.fullname;
    | false ->
       (
         Printf.printf "fcg.record_add_method:INFO: add method definition \"%s\" to record \"%s\"\n" method_def record.fullname;
         let methods : string list option =
           (match record.meth_defs with
            | None -> Some [method_def]
            | Some methods -> Some (method_def::methods)
           )
         in
         record.meth_defs <- methods
       )
    )

  (* Adds the "calls" dependency only if not already present between the two records *)
  method record_add_calls (caller_record:Callgraph_t.record) (callee_recordname:string) : unit =

    (* Printf.printf "fcg.record_add_calls:BEGIN: try to add function call dependency from record \"%s\" to record \"%s\"\n" caller_record.fullname callee_recordname; *)
    (* Filter any calls dependency between a record and itself *)
    let with_trema : string = Printf.sprintf "::%s" callee_recordname in
    if  ((String.compare caller_record.fullname callee_recordname == 0)
       ||(String.compare caller_record.fullname with_trema == 0))
    then
      (
        Printf.printf "fcg.record_add_calls:DEBUG: do not add a function call dependency between records %s and itself: %s !\n" caller_record.fullname callee_recordname
      )
    else
      (
        (* let callee_recordname_b64 = B64.encode callee_recordname in *)
        let calls : string list option =
          (match caller_record.calls with
           | None ->
              (
                Printf.printf "fcg.record_add_calls:INFO_1: add a function call dependency between records %s and %s\n" caller_record.fullname callee_recordname;
                (* Some [callee_recordname_b64] *)
                Some [callee_recordname]
              )
           | Some calls ->
              (
                try
                  (
                    List.find
                      (
                        (* fun call -> ( String.compare call callee_recordname_b64 == 0 ) *)
                        fun call ->
                        (
                          (String.compare call callee_recordname == 0) || (String.compare call with_trema == 0)
                        )
                      )
                      calls;
                    Printf.printf "fcg.record_add_calls:END: do not add already existing function call dependency between records %s and %s\n" caller_record.fullname callee_recordname;
                    Some calls
                  )
                with
                  Not_found ->
                  (
                    Printf.printf "fcg.record_add_calls:INFO_2: add a function call dependency between records %s and %s\n" caller_record.fullname callee_recordname;
                    (* Some (callee_recordname_b64::calls) *)
                    Some (callee_recordname::calls)
                  )
              )
          )
        in
        caller_record.calls <- calls
      )

  (* Adds the "virtcalls" dependency only if not already present between the two records *)
  method record_add_virtcalls (caller_record:Callgraph_t.record) (callee_recordname:string) : unit =

    (* Printf.printf "fcg.record_add_virtcalls:BEGIN: try to add function call dependency from record \"%s\" to record \"%s\"\n" caller_record.fullname callee_recordname; *)
    (* Filter any virtcalls dependency between a record and itself *)
    let with_trema : string = Printf.sprintf "::%s" callee_recordname in
    if  ((String.compare caller_record.fullname callee_recordname == 0)
       ||(String.compare caller_record.fullname with_trema == 0))
    then
      (
        Printf.printf "fcg.record_add_virtcalls:DEBUG: do not add a function call dependency between records %s and itself: %s !\n" caller_record.fullname callee_recordname
      )
    else
      (
        (* let callee_recordname_b64 = B64.encode callee_recordname in *)
        let virtcalls : string list option =
          (match caller_record.virtcalls with
           | None ->
              (
                Printf.printf "fcg.record_add_virtcalls:INFO_1: add a function call dependency between records %s and %s\n" caller_record.fullname callee_recordname;
                (* Some [callee_recordname_b64] *)
                Some [callee_recordname]
              )
           | Some virtcalls ->
              (
                try
                  (
                    List.find
                      (
                        (* fun call -> ( String.compare call callee_recordname_b64 == 0 ) *)
                        fun call ->
                        (
                          (String.compare call callee_recordname == 0) || (String.compare call with_trema == 0)
                        )
                      )
                      virtcalls;
                    Printf.printf "fcg.record_add_virtcalls:END: do not add already existing function call dependency between records %s and %s\n" caller_record.fullname callee_recordname;
                    Some virtcalls
                  )
                with
                  Not_found ->
                  (
                    Printf.printf "fcg.record_add_virtcalls:INFO_2: add a function call dependency between records %s and %s\n" caller_record.fullname callee_recordname;
                    (* Some (callee_recordname_b64::virtcalls) *)
                    Some (callee_recordname::virtcalls)
                  )
              )
          )
        in
        caller_record.virtcalls <- virtcalls
      )

  method create_dir (dirpath:string) : Callgraph_t.dir =

    Printf.printf "fcg.create_dir:BEGIN dirpath=\"%s\"\n" dirpath;

    let (_, dirname) = Batteries.String.rsplit dirpath "/" in

    let dir : Callgraph_t.dir =
      {
        name = dirname;
        path = dirpath;
        id = None;
        includes = None;
        calls = None;
        virtcalls = None;
        children = None;
        parents = None;
        files = None
      }
    in
    Printf.printf "fcg.create_dir:END dirpath=\"%s\"\n" dirpath;
    dir

  method get_file_in_dir (dir:Callgraph_t.dir) (filename:string) : Callgraph_t.file option =
    (* Printf.printf "fcg.get_file_in_dir:BEGIN: dir=%s, file=%s\n" dir.name filename; *)
    let file =
      (
        match dir.files with
        | None ->
           (
             Printf.printf "fcg.get_file_in_dir:WARNING: Not_Found_Files: no files in dir \"%s\"\n" dir.name;
             None
           )
        | Some files ->
           try
             (
               let file =
                 List.find
                   (fun ( f : Callgraph_t.file ) -> String.compare f.name filename == 0)
                   files
               in
               Printf.printf "Found file \"%s\" in dir \"%s\"\n" file.name dir.name;
               Some file
             )
           with
           | Not_found ->
              (
                Printf.printf "fcg.get_file_in_dir:WARNING: Not_Found_File: not found file \"%s\" in dir \"%s\"\n" filename dir.name;
                None
              )
      )
    in
    (* Printf.printf "fcg.get_file_in_dir:END: dir=%s, file=%s\n" dir.name filename; *)
    file

  method get_calls_in_dir (dir:Callgraph_t.dir) (callee:string) : string option =
    (* Printf.printf "fcg.get_calls_in_dir:BEGIN: dir=%s, calls=%s\n" dir.name calls; *)
    let callee =
      (
        match dir.calls with
        | None ->
           (
             Printf.printf "fcg.get_calls_in_dir:WARNING: Not_Found: no calls in dir \"%s\"\n" dir.name;
             None
           )
        | Some calls ->
           try
             (
               let callee =
                 List.find
                   (fun (c:string) -> String.compare c callee == 0)
                   calls
               in
               Printf.printf "Found callee \"%s\" in dir \"%s\"\n" callee dir.name;
               Some callee
             )
           with
           | Not_found ->
              (
                Printf.printf "fcg.get_calls_in_dir:WARNING: Not_Found_Calls: not found calls \"%s\" in dir \"%s\"\n" callee dir.name;
                None
              )
      )
    in
    (* Printf.printf "fcg.get_calls_in_dir:END: dir=%s, calls=%s\n" dir.name calls; *)
    callee

  (* Lookup for a specific file with already known filepath in a given directory *)
  (* warnings: Not_Found_File, Not_Found_Dir *)
  (* exceptions: Usage_Error *)
  method get_file (filepath:string) : Callgraph_t.file option =

    (* Printf.printf "fcg.get_file:BEGIN: dir=%s, filepath=%s\n" dir.name filepath; *)

    let file =
      (
        (* First lookup for the parent directory where the file is located *)
        let (filedir, filename) = Batteries.String.rsplit filepath "/" in
        let fdir : Callgraph_t.dir option = self#get_dir filedir in
        (match fdir with
         | None ->
            (
              Printf.printf "fcg.get_file:WARNING: Not_Found_Dir: not found file directory path \"%s\"\n" filepath;
              None
            )
         (* A leaf dir has been found *)
         | Some ldir ->
            (
              (* Check whether the leaf directory is the files's directory or not *)
              let (dirpath, dirname) = Batteries.String.rsplit filedir "/" in
              Printf.printf "fcg.get_file:INFO: Found parent directory \"%s\" of file \"%s\" located in path=\"%s\" where dirpath=\"%s\"\n" 
                            ldir.name filename filepath dirpath;
              self#get_file_in_dir ldir filename
            )
        )
      )
    in
    (* Printf.printf "fcg.get_file:END: dir=%s, filepath=%s\n" dir.name filepath; *)
    file

  (* Lookup for a directory *)
  (* warnings: Not_Found_File, Not_Found_Dir *)
  (* exceptions: Usage_Error *)
  method get_dir (dirpath:string) : Callgraph_t.dir option =

    Printf.printf "fcg.get_dir:BEGIN: Lookup for directory \"%s\"\n" dirpath;

    let rootdir = self#get_fcg_rootdir in
    let dir =
      (match rootdir.physical_view with
       | None ->
          (
            Printf.printf "fcg.get_dir:WARNING: no physical view has yet been created, especially no dir for path \"%s\"\n" dirpath;
            None
          )
       | Some dirs ->
          (
            try
              (
                let dir =
                  List.find
                    (fun (d:Callgraph_t.dir) -> String.compare d.path dirpath == 0)
                    dirs
                in
                Printf.printf "Found directory \"%s\" in path \"%s\"\n" dir.name dirpath;
                Some dir
              )
            with
              Not_found ->
              (
                Printf.printf "fcg.get_dir:WARNING: Not_Found_Dir: not found directory path \"%s\"\n" dirpath;
                None
              )
          )
      )
    in
    Printf.printf "fcg.get_dir:END: Lookup for directory \"%s\"\n" dirpath;
    dir

  (* Lookup for a specific subdir in a directory *)
  method dir_get_child (dir:Callgraph_t.dir) (child_path:string) : string option =

    (* Printf.printf "fcg.dir_get_child:BEGIN: Lookup for child dir \"%s\" in dir=\"%s\"\n" child dir.name; *)

    let subdir =

      (match dir.children with
       | None ->
         (
           Printf.printf "fcg.dir_get_child_path:INFO: No children in dir \"%s\"\n" dir.name;
           None
         )
       | Some children ->
        try
        (
          let subdir =
            List.find
             (fun (ch:string) -> String.compare ch child_path == 0)
             children
          in
          (* Printf.printf "fcg.dir_get_child:INFO: Found child \"%s\" in dir \"%s\"\n" child dir.name; *)
          Some subdir
        )
        with
        | Not_found ->
         (
           Printf.printf "fcg.dir_get_child_path:INFO: Not found child \"%s\" in dir \"%s\"\n" child_path dir.name;
           None
         )
      )
    in
    (* Printf.printf "fcg.dir_get_child:END: Lookup for child dir \"%s\" in dir=\"%s\"\n" child dir.name; *)
    subdir

  (* Lookup for a record *)
  method get_record (record_name:string) : Callgraph_t.record option =

    Printf.printf "fcg.get_record:BEGIN: Lookup for record \"%s\"\n" record_name;

    let rootdir = self#get_fcg_rootdir in
    let record =
      (match rootdir.logical_view with
       | None ->
          (
            Printf.printf "fcg.get_record:WARNING: no physical view has yet been created, especially no record for path \"%s\"\n" record_name;
            None
          )
       | Some records ->
          (
            try
              (
                let full_record_name = Printf.sprintf "::%s" record_name in
                let record =
                  List.find
                    (fun (rc:Callgraph_t.record) ->
                     (
                       Printf.printf "(rc1==%s)=?=(rn==%s)=?=(rc2==%s)\n" rc.fullname record_name full_record_name;
                       (String.compare rc.fullname record_name == 0)||(String.compare rc.fullname full_record_name == 0))
                    )
                    records
                in
                Printf.printf "Found record \"%s\" in path \"%s\"\n" record.fullname record_name;
                Some record
              )
            with
              Not_found ->
              (
                Printf.printf "fcg.get_record:WARNING: Not_Found_Record: not found record path \"%s\"\n" record_name;
                None
              )
          )
      )
    in
    Printf.printf "fcg.get_record:END: Lookup for record \"%s\"\n" record_name;
    record

  (* Lookup for a thread *)
  method get_thread (thr_inst_name:string) : Callgraph_t.thread option =

    Printf.printf "fcg.get_thread:BEGIN: Lookup for thread \"%s\"\n" thr_inst_name;

    let rootdir = self#get_fcg_rootdir in
    let thread =
      (match rootdir.runtime_view with
       | None ->
          (
            Printf.printf "fcg.get_thread:WARNING: no physical view has yet been created, especially no thread for path \"%s\"\n" thr_inst_name;
            None
          )
       | Some threads ->
          (
            try
              (
                let thread =
                  List.find
                    (fun (thr:Callgraph_t.thread) ->
                     (
                       Printf.printf "(thr1==%s)=?=(rn==%s)\n" thr.id thr_inst_name;
                       (String.compare thr.id thr_inst_name == 0)
                     )
                    )
                    threads
                in
                Printf.printf "Found thread \"%s\" in path \"%s\"\n" thread.id thr_inst_name;
                Some thread
              )
            with
              Not_found ->
              (
                Printf.printf "fcg.get_thread:WARNING: Not_Found_Thread: not found thread id \"%s\"\n" thr_inst_name;
                None
              )
          )
      )
    in
    Printf.printf "fcg.get_thread:END: Lookup for thread \"%s\"\n" thr_inst_name;
    thread

  (* Returns a reference to the callgraph rootdir *)
  (* exception: Usage_Error in case of inexistent or invalid reference. *)
  method get_fcg_rootdir : Callgraph_t.top =

    (match json_rootdir with
     | None ->
       (
         Printf.printf "fcg.get_fcg_rootdir:INFO:WARNING: No root node is yet attached to this callgraph\n";
         raise Common.Usage_Error
       )
     | Some rootdir ->
       (
         (* Printf.printf "fcg.get_fcg_rootdir:INFO: The path of the callgraph root dir is \"%s\"\n" rootdir.path; *)
         rootdir
       )
    )

  method update_fcg_rootdir (rootdir:Callgraph_t.top) : unit =

    Printf.printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n";
    Printf.printf "fcg.update_fcg_rootdir:INFO: rootdir=%s\n" rootdir.path;
    (match json_rootdir with
    | None -> Printf.printf "old rootdir: none\n";
    | Some rd -> Printf.printf "old rootdir: %s\n" rd.path;
    );
    Printf.printf "new rootdir: %s\n" rootdir.path;
    Printf.printf "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n";
    json_rootdir <- Some rootdir

  (* Complete the input file parent dir with the input file *)
  (* Warning: here, the filepath does not include the filename itself *)
  (* exception: Usage_Error in case the filepath root dir doesn't match the input dir name *)
  method complete_fcg_file (filepath:string) (file:Callgraph_t.file) : Callgraph_t.file =

    let (_, dirname) = Batteries.String.rsplit filepath "/" in

    Printf.printf "fcg.complete_fcg_file:BEGIN: dirname=\"%s\", filepath=\"%s/%s\"\n" dirname filepath file.name;

    Printf.printf "fcg.complete_fcg_file:INFO: Try to add file \"%s\" in dir=\"%s\"...\n" file.name filepath;

    (* Checker whether the parent directory does already exists for the file *)
    (* Add the required directory otherwise *)
    self#complete_fcg_dir filepath;

    let filedir = self#get_dir filepath in

    let file =
      (match filedir with
       | None ->
          (
            Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
            Printf.printf "fcg.complete_fcg_file:ERROR: Not found parent directory \"%s\" of file \"%s\"\n" filepath file.name;
            Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
            raise Common.Internal_Error
          )
       (* The file dir has well been found as expected *)
       | Some fdir ->
          (
            Printf.printf "fcg.complete_fcg_file:INFO: found parent directory \"%s\" of file \"%s\" located in path=\"%s\"\n" fdir.name file.name filepath;
            self#dir_add_file fdir file;
            file
          )
      )
    in
    Printf.printf "fcg.complete_fcg_file:END: dirname=\"%s\", filepath=\"%s\"\n" dirname filepath;
    file

  (* (\* Complete the input file when not found with the input record *\) *)
  (* method complete_fcg_record (record:Callgraph_t.record) : Callgraph_t.record = *)

  (*   Printf.printf "fcg.complete_fcg_record:BEGIN: record=\"%s\"\n" record.fullname; *)

  (*   Printf.printf "fcg.complete_fcg_record:INFO: Try to add record \"%s\"\"...\n" record.fullname; *)

  (*   let does_already_exist = self#get_record record.fullname in *)

  (*   let record = *)
  (*     (match does_already_exist with *)
  (*      | None -> *)
  (*         ( *)
  (*           Printf.printf "fcg.complete_fcg_record:INFO: not found record \"%s\", so we add it once\n" record.fullname; *)
  (*           self#top_add_record record; *)
  (*           record *)
  (*         ) *)
  (*      (\* The record is already present in the file, so we do not need to add it again *\) *)
  (*      | Some existing_record -> *)
  (*         ( *)
  (*           Printf.printf "fcg.complete_fcg_record:INFO: already found record \"%s\", so we do not need to add it again\n" record.fullname; *)
  (*           existing_record *)
  (*         ) *)
  (*     ) *)
  (*   in *)
  (*   Printf.printf "fcg.complete_fcg_record:END: record=\"%s\"\n" record.fullname; *)
  (*   record *)

  (* Create a new directory for the input path if it does not yet exist *)
  method complete_fcg_dir (dirpath:string) : unit =

    let (_, dirname) = Batteries.String.rsplit dirpath "/" in

    Printf.printf "fcg.complete_fcg_dir:BEGIN: dirname=\"%s\", dirpath=\"%s\"\n" dirname dirpath;

    let dirpath = Common.filter_root_dir dirpath in

    Printf.printf "fcg.complete_fcg_dir:INFO: check directory path \"%s\"...\n" dirpath;

    let dir = self#get_dir dirpath in

    (match dir with
    | None ->
       (
         Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
         Printf.printf "fcg.complete_fcg_dir:INFO: not found any dir \"%s\" through path \"%s\", so we need to create it\n" dirname dirpath;
         Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
         let rootdir = self#get_fcg_rootdir in
         let cdir = self#create_dir dirpath in
         (match rootdir.physical_view with
           | None -> ( rootdir.physical_view <- Some [cdir])
           | Some dirs -> ( rootdir.physical_view <- Some (cdir::dirs))
         )
       )
    | Some dir ->
      (
        Printf.printf "fcg.complete_fcg_dir:INFO: Found dir \"%s\" in path \"%s\", so return it as is\n" dirname dirpath;
        ()
      )
    );

    Printf.printf "fcg.complete_fcg_dir:END: dirname=\"%s\", dirpath=\"%s\"\n" dirname dirpath

  method complete_callgraph (filepath:string) (file:Callgraph_t.file option) : unit =

    Printf.printf "fcg.complete_callgraph:BEGIN: filepath=\"%s\"\n" filepath;

    (* Adds the rootdir_prefix = /tmp/callers *)
    (* let filepath = Common.check_root_dir filepath in *)
    (* let file_rootdir = Common.get_root_dir filepath in *)
    let (dirpath, filename) = Batteries.String.rsplit filepath "/" in

    (* Check whether a callgraph root dir does already exists or not *)
    (
      (match file with
       | None -> self#complete_fcg_dir dirpath
       | Some file -> (let _ = self#complete_fcg_file filepath file in ())
      )
    );

    Printf.printf "fcg.complete_callgraph:END: filepath=\"%s\"\n" filepath

  method parse_jsonfile (json_filepath:string) : unit =

    Printf.printf "fcg.parse_jsonfile:INFO: json_filepath=%s\n" json_filepath;
    try
      (
	Printf.printf "Read callgraph's json file \"%s\"...\n" json_filepath;
	(* Read JSON file into an OCaml string *)
	let content = Core.Std.In_channel.read_all json_filepath in
        (* Printf.printf "fcg.parse_jsonfile:DEBUG1: %s\n" content; *)
	(* Read the input callgraph's json file *)
        let top = (Callgraph_j.top_of_string content) in
        let file_content = (Callgraph_j.string_of_top top) in
        (* Printf.printf "fcg.parse_jsonfile:DEBUG2: %s\n" content; *)
	self#update_fcg_rootdir top;
        (* self#output_fcg "debug.json"; *)
      )
    with
    | Sys_error msg ->
       (
	 Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	 Printf.printf "class function_callgraph::parse_jsonfile:ERROR: Ignore not found file \"%s\"\n" json_filepath;
	 Printf.printf "Sys_error msg: %s\n" msg;
	 Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	 json_rootdir <- None
       )

  method output_file_calls_deps () : unit =

    match json_rootdir with
    | None ->
      (
        Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
        Printf.printf "WARNING: empty callgraph, so nothing to print\n";
        Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n"
      )
    | Some rootdir ->
      (
        (match rootdir.physical_view with
         | None -> ()
         | Some dirs ->
            List.iter
              (fun (dir:Callgraph_t.dir) ->
               (match dir.files with
                | None -> ()
                | Some files ->
                   List.iter
                     (
                       fun (file:Callgraph_t.file) ->
                       let filepath = Printf.sprintf "%s/%s" dir.path file.name in
                       self#file_list_calls file filepath
                     )
                     files
               )
              )
              dirs
        )
      )

  method output_fcg (json_filepath:string) : unit =

    match json_rootdir with
    | None ->
      (
        Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
        Printf.printf "WARNING: empty callgraph, so nothing to print\n";
        Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n"
      )
    | Some rootdir ->
      (
        self#output_top json_filepath rootdir
      )

  method output_dir (json_filepath:string) (dir:Callgraph_t.dir) : unit =

    Printf.printf "fcg.output_dir: write json file: %s\n" json_filepath;

    Common.print_callgraph_dir dir json_filepath

  method output_top (json_filepath:string) (dir:Callgraph_t.top) : unit =

    Printf.printf "fcg.output_top: write json file: %s\n" json_filepath;

    Common.print_callgraph_top dir json_filepath

end

(*********************************** Unitary Tests **********************************************)

let test_complete_callgraph () =

    (* Add a new file *)
    let new_filename = "another_new_file.json" in
    let new_file : Callgraph_t.file =
      {
        name = new_filename;
        kind = "src";
        id = None;
        includes = None;
        calls = None;
        virtcalls = None;
        (* records = None; *)
        declared = None;
        defined = None;
      }
    in

    let fcg = new function_callgraph in
    fcg#complete_callgraph "/toto/tutu/tata/titi" None;
    fcg#complete_callgraph "/dir_a/dir_b/dir_c/toto/dir_d/dir_e/dir_f" (Some new_file);
    (* fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_b/dir_c" None; *)
    (* fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_z/dir_h/dir_z" None; *)
    fcg#output_fcg "complete_callgraph.unittest.gen.json";

    (* test get_file *)
    let _ = fcg#get_file "/dir_a/dir_b/dir_c/toto/dir_d/dir_e/dir_f/another_new_file.json" in
    let _ = fcg#get_file "/dir_a/dir_b/dir_c/toto/dir_d/toto.c" in
    ()

(* Check edition of a base dir to add a child subdir *)
let test_add_child () =

    let fcg = new function_callgraph in
    let dir = fcg#create_dir "/dir_a/dir_b" in
    let dir_b = fcg#get_dir "/dir_a/dir_b" in
    let dir_b =
      (match dir_b with
      | None -> raise Common.Internal_Error
      | Some dir_b -> dir_b
      )
    in
    Printf.printf "dir_b: %s\n" dir_b.name;
    let dir_k = fcg#init_dir "dir_k" "dir_k_id" in
    dir.children <- Some [ "dir_b"; "dir_k" ];
    fcg#output_top "original.gen.json" (fcg#get_fcg_rootdir)
    (*fcg#output_fcg "my_callgraph.unittest.gen.json"*)

let test_copy_dir () =

    let fcg = new function_callgraph in
    let dir = fcg#create_dir "/dir_e/dir_r/dir_a/dir_b/dir_c" in
    let copie = fcg#copy_dir dir in
    fcg#output_dir "copie.gen.json" copie
    (*fcg#output_fcg "my_callgraph.unittest.gen.json"*)

let test_update_dir () =

    let fcg = new function_callgraph in
    let dir = fcg#init_top "/dir_e/dir_r/dir_a/dir_b/dir_c" in
    fcg#update_fcg_rootdir dir;
    fcg#output_fcg "my_callgraph.unittest.gen.json"

(* Check edition of a base dir to add a leaf child subdir and a file in it *)
let test_add_leaf_child () =

    let fcg = new function_callgraph in
    let dir = fcg#init_top "/dir_a/dir_b/dir_c" in
    (*let cpath = "/dir_a/dir_b/dir_c/dir_d/dir_e/dir_f" in*)
    let cpath = "/other_dir/dir_a/dir_b/dir_c/dir_d/dir_e/dir_f" in

    (*fcg#complete_fcg_dir dir cpath;*)
    fcg#update_fcg_rootdir dir;
    (*let rdir = fcg#get_fcg_rootdir in*)
    (*fcg#complete_fcg_dir rdir cpath;*)

    (* Add a new file *)
    let new_filename = "yet_another_new_file.json" in
    let new_file : Callgraph_t.file =
      {
        name = new_filename;
        kind = "src";
        id = None;
        includes = None;
        calls = None;
        virtcalls = None;
        (* records = None; *)
        declared = None;
        defined = None
      }
    in
    fcg#complete_fcg_file cpath new_file;

    (* Output the complete graph to check whether it has really been completed or not *)
    fcg#output_fcg "my_callgraph.unittest.gen.json"

let test_generate_ref_json () =

    let filename = "test_local_callcycle.c" in
    let file : Callgraph_t.file =
      {
        name = filename;
        kind = "src";
        id = None;
        includes = None;
        calls = None;
        virtcalls = None;
        (* records = None; *)
        declared = None;
        defined = None
      }
    in

    let fcg = new function_callgraph in

    fcg#file_add_include file "stdio.h";

    fcg#complete_callgraph "/root_dir/test_local_callcycle" (Some file);

    let rdir = fcg#get_fcg_rootdir in

    let dir = fcg#get_dir "/root_dir/test_local_callcycle" in

    (match dir with
     | None -> raise Common.Internal_Error
     | Some dir ->
       (
        fcg#dir_add_includes dir "includes";
       )
    );

    let file = fcg#get_file "/root_dir/test_local_callcycle/test_local_callcycle.c" in

    (match file with
     | None -> raise Common.Internal_Error
     | Some file ->
       (
         let fct_main : Callgraph_t.fonction_def =
      	   {
      	     sign = "int main()";
             mangled = "_Main";
             virtuality = None;
             localdecl = None;
      	     locallees = Some [{ sign = "void a()"; virtuality="no"; mangled="_a" } ];
             extdecls = None;
      	     extcallees = None;
      	     virtcallees = None;
             record = None;
             threads = None;
      	   }
         in

         let printf : Callgraph_t.extfct_ref =
           {
             sign = "int printf()";
             virtuality = "no";
             mangled = "_Printf";
             file = "/path/to/stdio.h";
           }
         in

         let fct_a : Callgraph_t.fonction_def =
	   {
	     sign = "void a()";
             mangled = "_a";
             virtuality = None;
             localdecl = None;
	     locallees = Some [ { sign = "int b()"; virtuality = "no"; mangled = "_b" } ];
             extdecls = None;
	     extcallees = Some [ printf ];
      	     virtcallees = None;
             record = None;
             threads = None;
	   }
         in

         let fct_b_decl : Callgraph_t.fonction_decl =
	   {
	     sign = "int b()";
             mangled = "dc_b";
             virtuality = None;
             virtdecls = None;
             localdef = None;
	     locallers = Some [ { sign = "void a()"; virtuality = "no"; mangled = "_a" } ];
             extdefs = None;
	     extcallers = None;
      	     virtcallers = None;
             record = None;
             threads = None;
	   }
         in

         let fct_b_def : Callgraph_t.fonction_def =
	   {
	     sign = "int b()";
             mangled = "df_b";
             virtuality = None;
             localdecl = None;
	     locallees = Some [ { sign = "int c()"; virtuality = "no"; mangled = "_c" } ];
             extdecls = None;
	     extcallees = Some [ printf ];
      	     virtcallees = None;
             record = None;
             threads = None;
	   }
         in

         let fct_c_decl : Callgraph_t.fonction_decl =
	   {
	     sign = "int c()";
             mangled = "dc_c";
             virtuality = None;
             virtdecls = None;
             localdef = None;
	     locallers = Some [ { sign = "int b()"; virtuality = "no"; mangled = "_b" } ];
             extdefs = None;
	     extcallers = None;
      	     virtcallers = None;
             record = None;
             threads = None;
	   }
         in

         let fct_c_def : Callgraph_t.fonction_def =
	   {
	     sign = "int c()";
             mangled = "df_c";
             virtuality = None;
             localdecl = None;
	     locallees = Some [ { sign = "void a()"; virtuality = "no"; mangled = "_a" } ];
             extdecls = None;
	     extcallees = Some [ printf ];
      	     virtcallees = None;
             record = None;
             threads = None;
	   }
         in

         fcg#add_fct_defs file [fct_main; fct_a; fct_b_def; fct_c_def];
         fcg#add_fct_decls file [fct_b_decl; fct_c_decl]
       )
    );

    let fct_printf : Callgraph_t.fonction_decl =
      {
        sign = "int printf()";
        mangled = "dc_printf";
        virtuality = None;
        virtdecls = None;
        localdef = None;
        locallers = Some [ { sign = "void a()"; virtuality = "no"; mangled = "_a" };
                           { sign = "int b()"; virtuality = "no"; mangled = "_b" };
                           { sign = "int c()"; virtuality = "no"; mangled = "_c" } ];
        extdefs = None;
        extcallers = None;
        virtcallers = None;
        record = None;
        threads = None;
      }
    in

    let file_stdio : Callgraph_t.file =
      {
        name = "stdio.h";
        kind = "inc";
        id = None;
        includes = None;
        calls = None;
        virtcalls = None;
        (* records = None; *)
        declared = Some [fct_printf];
        defined = None;
      }
    in

    fcg#complete_callgraph "/root_dir/includes" (Some file_stdio);

    fcg#output_fcg "/try.dir.callgraph.gen.json"

(* let () = test_generate_ref_json() *)

(*
   test_complete_callgraph()
   test_add_child();
   test_copy_dir();
   test_update_dir();
   test_add_leaf_child()
 *)

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -package base64 -tag thread function_callgraph.native" *)
(* End: *)
