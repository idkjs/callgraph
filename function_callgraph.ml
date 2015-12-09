(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   KTD SCIS 2014-2015                                                       *)
(*   Use Case Legacy TOSA                                                     *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)
(* moved from callgraph_to_dot.ml *)

exception Internal_Error
exception Not_Found_File
exception Usage_Error
exception Unsupported_Case

(* Function callgraph *)
class function_callgraph
  = object(self)

  val mutable json_rootdir : Callgraph_t.dir option = None

  val mutable cdir : Callgraph_t.dir =
    let dir : Callgraph_t.dir =
      {
        name = "tmpCurrDir";
        uses = None;
        children = None;
        files = None
      }
    in
    dir

  val mutable rdir : Callgraph_t.dir =
    let dir : Callgraph_t.dir =
      {
        name = "tmpRootDir";
        uses = None;
        children = None;
        files = None
      }
    in
    dir

  method init_dir (name:string) : Callgraph_t.dir =

    let dir : Callgraph_t.dir =
      {
        name = name;
        uses = None;
        children = None;
        files = None
      }
    in
    dir

  method copy_dir (org:Callgraph_t.dir) : Callgraph_t.dir =

    let dest : Callgraph_t.dir =
      {
        name = org.name;
        uses = org.uses;
        children = org.children;
        files = org.files
      }
    in
    dest

  method add_child_dir (parent:Callgraph_t.dir) (child:Callgraph_t.dir) : unit =

    let children : Callgraph_t.dir list option =
      (match parent.children with
       | None -> Some [child]
       | Some ch -> Some (child::ch)
      )
    in
    Printf.printf "Add child \"%s\" to parent dir \"%s\"\n" child.name parent.name;
    parent.children <- children

  method add_uses_dir (dir:Callgraph_t.dir) (dirpath:string) : unit =

    let uses : string list option =
      (match dir.uses with
       | None -> Some [dirpath]
       | Some uses -> Some (dirpath::uses)
      )
    in
    Printf.printf "Add uses reference of dir \"%s\" in dir \"%s\"\n" dirpath dir.name;
    dir.uses <- uses

  (* WARNING: this method does not check if the input file is already registered in the directory !
     This verification is performed for example in method function_callers_json_parser.callgraph_add_file()
  *)
  method add_file (dir:Callgraph_t.dir) (file:Callgraph_t.file) : unit =

    let files : Callgraph_t.file list option =
      (match dir.files with
       | None -> Some [file]
       | Some files -> Some (file::files)
      )
    in
    Printf.printf "Add file \"%s\" to dir \"%s\"\n" file.name dir.name;
    dir.files <- files

  method add_uses_file (file:Callgraph_t.file) (filepath:string) : unit =

    let uses : string list option =
      (match file.uses with
       | None -> Some [filepath]
       | Some uses -> Some (filepath::uses)
      )
    in
    Printf.printf "Add uses reference of file \"%s\" in file \"%s\"\n" filepath file.name;
    file.uses <- uses

  method get_fct_decl (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction option =

    try
      (
        (match file.declared with
         | None -> None
         | Some declared ->
           (
             let fct =
               List.find
                 (
                   fun (fct:Callgraph_t.fonction) -> (String.compare fct.sign fct_sign == 0)
                 )
                 declared
             in
             Some fct
           )
        )
      )
    with
      Not_found -> None

  method add_fct_decls (file:Callgraph_t.file) (fct_decls:Callgraph_t.fonction list) : unit =

    let decls : Callgraph_t.fonction list option =
      (match file.declared with
       | None -> Some fct_decls
       | Some decls ->
          Some
            (
              List.fold_left
                (
                  fun (decls:Callgraph_t.fonction list)
                      (def:Callgraph_t.fonction) ->
                  def::decls
                )
                decls
                fct_decls
            )
      )
    in
    Printf.printf "Add the following fonction declarations in file \"%s\":\n" file.name;
    List.iter
      (fun (def:Callgraph_t.fonction) -> Printf.printf " %s\n" def.sign )
      fct_decls;
    file.declared <- decls

  method get_fct_def (file:Callgraph_t.file) (fct_sign:string) : Callgraph_t.fonction option =

    try
      (
        (match file.defined with
         | None -> None
         | Some defined ->
           (
             let fct =
               List.find
                 (
                   fun (fct:Callgraph_t.fonction) -> (String.compare fct.sign fct_sign == 0)
                 )
                 defined
             in
             Some fct
           )
        )
      )
    with
      Not_found -> None

  method add_fct_defs (file:Callgraph_t.file) (fct_defs:Callgraph_t.fonction list) : unit =

    let defs : Callgraph_t.fonction list option =
      (match file.defined with
       | None -> Some fct_defs
       | Some defs ->
          Some
            (
              List.fold_left
                (
                  fun (defs:Callgraph_t.fonction list)
                      (def:Callgraph_t.fonction) ->
                  def::defs
                )
                defs
                fct_defs
            )
      )
    in
    Printf.printf "Add the following fonction definitions in file \"%s\":\n" file.name;
    List.iter
      (fun (def:Callgraph_t.fonction) -> Printf.printf " %s\n" def.sign )
      fct_defs;
    file.defined <- defs

  (* exception: Usage_Error in case "fct.sign == locallee_sign" *)
  method add_fct_locallee (fct:Callgraph_t.fonction) (locallee_sign:string) : unit =

    if (String.compare fct.sign locallee_sign == 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_locallee:ERROR: caller = callee = %s\n" locallee_sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Usage_Error
      );

    (match fct.locallees with
     | None -> (fct.locallees <- Some [locallee_sign])
     | Some locallees -> (fct.locallees <- Some (locallee_sign::locallees))
    )

  (* exception: Usage_Error in case "fct.sign == localler_sign" *)
  method add_fct_localler (fct:Callgraph_t.fonction) (localler_sign:string) : unit =

    if (String.compare fct.sign localler_sign == 0) then
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "fcg: add_fct_localler:ERROR: caller = callee = %s\n" localler_sign;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Usage_Error
      );

    (match fct.locallers with
     | None -> (fct.locallers <- Some [localler_sign])
     | Some locallers -> (fct.locallers <- Some (localler_sign::locallers))
    )

  method create_dir_tree (dirpaths:string) : Callgraph_t.dir =

    Printf.printf "Create dir tree \"%s\"\n" dirpaths;

    let dirs = Batteries.String.nsplit dirpaths "/" in

    let dir : Callgraph_t.dir =

      (match dirs with
       | _::dirs ->
        (
          let dir : Callgraph_t.dir option =
            List.fold_right
            (
              fun (dir:string) (child:Callgraph_t.dir option) ->

               let child : Callgraph_t.dir list option =
                 (match child with
                  | None -> (* Printf.printf "dir: %s\n" dir;*) None (**)
                  | Some ch -> (* Printf.printf "dir: %s, child: %s\n" dir ch.name;*) Some [ch] (**)
                 )
               in
               let parent : Callgraph_t.dir =
               {
                 name = dir;
                 uses = None;
                 children = child;
                 files = None
               }
               in
               Some parent
            )
            dirs
            None
          in
          (match dir with
           | None -> raise Internal_Error
           | Some dir -> dir
          )
        )
       | _ -> raise Internal_Error
      )
    in
    dir

  (* Check whether a child exists in dir with the input child_path. *)
  (* If true, return it, else return the nearest child leaf of dir and its path *)
  method get_leaf (rdir:Callgraph_t.dir) (child_path:string) : (string * Callgraph_t.dir) option =

    let child_rootdir = Common.get_root_dir child_path in
    if (String.compare child_rootdir rdir.name != 0) then
    (
      Printf.printf "Function_callgraph.get_leaf:ERROR: the childpath rootdir \"%s\" doesn't match the input dir name \"%s\"\n" child_rootdir rdir.name;
      raise Usage_Error
    );

    Printf.printf "rdir: %s\n" rdir.name;

    let dirs = Batteries.String.nsplit child_path "/" in

    let leaf : (string * Callgraph_t.dir) option =

      (match dirs with
       | _::dirs ->
        (
          let cdir : (string * Callgraph_t.dir) option * (string * Callgraph_t.dir) option =
            List.fold_left
            (
              fun (context:(string * Callgraph_t.dir) option * (string * Callgraph_t.dir) option) (dir:string) ->

               if (String.compare dir rdir.name == 0) then
               (
                 (Some (dir, rdir), None)
               )
               else
               (
                 (* Get the child belonging to the child_path if any *)
                 let child : (string * Callgraph_t.dir) option * (string * Callgraph_t.dir) option =
                   (match context with
                    | (None, leaf) ->
                      (
                        Printf.printf "Skip child \"%s\" not found in dir \"%s\"\n" dir rdir.name;
                        (None, leaf)
                      )
                    | (Some (lpath, parent), _) ->
                      (
                        Printf.printf "dir: %s, parent: %s, lpath: %s/%s\n" dir parent.name lpath dir;
                        let cdir = self#get_child parent dir in
                        (match cdir with
                         | None ->
                           (
                             Printf.printf "Return the leaf \"%s\" of rdir \"%s\" located in \"%s\"\n" parent.name rdir.name lpath;
                             (None, Some(lpath, parent))
                           )
                         | Some child ->
                           (
                             let cpath = Printf.sprintf "%s/%s" lpath dir in
                             Printf.printf "Found child \"%s\" of rdir \"%s\" located in \"%s\"\n" dir rdir.name cpath;
                             (Some (cpath, child), Some (cpath, child))
                           )
                        )
                      )
                  )
                 in
                 child
             )
            )
            (None, None)
            dirs
          in
          (match cdir with
           | (_, None) ->
             (
               Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
               Printf.printf "WARNING: not found any leaf for child path \"%s\" in dir \"%s\"\n" child_path rdir.name;
               Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
               None
             )
           | (_, leaf) -> leaf
          )
        )
       | _ ->
        (
          Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
          Printf.printf "WARNING_2: not found child path \"%s\" in dir \"%s\"\n" child_path rdir.name;
          Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
          None
        )
      )
    in
    leaf

  (* Lookup for a specific file with already known filepath in a given directory *)
  (* warnings: Not_Found_File, Not_Found_Dir *)
  (* exceptions: Usage_Error *)
  method get_file (dir:Callgraph_t.dir) (filepath:string) : Callgraph_t.file option =

    let file_rootdir = Common.get_root_dir filepath in

    if (String.compare file_rootdir dir.name != 0) then
    (
      Printf.printf "Function_callgraph.get_file:ERROR: the filepath rootdir \"%s\" doesn't match the input dir name \"%s\"\n" file_rootdir dir.name;
      raise Usage_Error
    );

    let (filepath, filename) = Batteries.String.rsplit filepath "/" in

    Printf.printf "\nLookup for file \"%s\" in dir=\"%s\" and its subdirectories...\n" filename filepath;

    (* First lookup for the parent directory where the file is located *)

    let fdir = self#get_leaf dir filepath in

    (match fdir with
      | None ->
        (
          Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
          Printf.printf "WARNING: Not_Found_Dir: not found file directory path \"%s\"\n" filepath;
          Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
          None
        )
      | Some (fpath, fdir) ->
        (
          Printf.printf "Found file directory path \"%s\" in dir \"%s\"\n" fpath dir.name;

          let file =

            (match fdir.files with

             | None ->
               (
                 Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
                 Printf.printf "WARNING: Not_Found_File: no files in dir \"%s\"\n" fpath;
                 Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
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
                 Printf.printf "Found file \"%s\" in dir \"%s\"\n" file.name filepath;
                 Some file
               )
               with
               | Not_found ->
                (
                  Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
                  Printf.printf "WARNING: Not_Found_File: not found file \"%s\" in dir \"%s\"\n" filename fpath;
                  Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
                  None
                )
            )
          in
          file
        )
    )

  (* Lookup for a specific subdir in a directory *)
  (* warnings: Not_Found_File, Not_Found_Dir *)
  (* exceptions: Usage_Error *)
  method get_dir (dir:Callgraph_t.dir) (childpath:string) : Callgraph_t.dir option =

    Printf.printf "Lookup for child dir \"%s\" in dir=\"%s\"\n" childpath dir.name;

    let subdir =self#get_leaf dir childpath in

    (match subdir with
     | None ->
        (
          Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
          Printf.printf "WARNING: Not_Found_Dir: not found child directory path \"%s\"\n" childpath;
          Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
          None
        )
     | Some (cpath, child) ->
        (
          Printf.printf "Found child \"%s\" in dir \"%s\"\n" childpath dir.name;
          Some child
        )
    )

  (* Lookup for a specific subdir in a directory *)
  method get_child (dir:Callgraph_t.dir) (child:string) : Callgraph_t.dir option =

    Printf.printf "Lookup for child dir \"%s\" in dir=\"%s\"\n" child dir.name;

    let subdir =

      (match dir.children with
       | None ->
         (
           Printf.printf "No children in dir \"%s\"\n" dir.name;
           None
         )
       | Some children ->
        try
        (
          let subdir =
            List.find
             (fun (ch:Callgraph_t.dir) -> String.compare ch.name child == 0)
             children
          in
          Printf.printf "Found child \"%s\" in dir \"%s\"\n" child dir.name;
          Some subdir
        )
        with
        | Not_found ->
         (
           Printf.printf "Not found child \"%s\" in dir \"%s\"\n" child dir.name;
           None
         )
      )
    in
    subdir

  (* Returns a reference to the callgraph rootdir *)
  (* exception: Usage_Error in case of inexistent or invalid reference. *)
  method get_fcg_rootdir : Callgraph_t.dir =

    (match json_rootdir with
     | None ->
       (
         Printf.printf "WARNING: No root node is yet attached to this callgraph\n";
         raise Usage_Error
       )
     | Some rootdir ->
       (
         Printf.printf "The name of the callgraph root dir is \"%s\"\n" rootdir.name;
         rootdir
       )
    )

  method update_fcg_rootdir (rootdir:Callgraph_t.dir) : unit =

    json_rootdir <- Some rootdir

  (* Complete the input dir with the input file and all its contained directories *)
  (* Warning: here, the filepath does not include the filename itself *)
  (* exception: Usage_Error in case the filepath root dir doesn't match the input dir name *)
  method complete_fcg_file (dir:Callgraph_t.dir) (filepath:string) (file:Callgraph_t.file) : unit =

    let file_rootdir = Common.get_root_dir filepath in
    if (String.compare file_rootdir dir.name != 0) then
    (
      Printf.printf "Function_callgraph.complete_fcg_file:ERROR: the filepath rootdir \"%s\" doesn't match the input dir name \"%s\"\n" file_rootdir dir.name;
      raise Usage_Error
    );

    Printf.printf "complete_fcg_file: Try to add file \"%s\" in dir=\"%s\"...\n" file.name filepath;

    (* Checker whether the input dir does already contain the directory path to the input file *)
    (* Add all required directories otherwise *)
    self#complete_fcg_dir dir filepath;

    let leaf = self#get_leaf dir filepath in
    (match leaf with
      | None ->
        (
          Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
          Printf.printf "ERROR: Not found any leaf in dir \"%s\" through path \"%s\"\n" dir.name filepath;
          Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
          raise Internal_Error
        )
      | Some (lpath, ldir) ->
        (
          Printf.printf "Found leaf \"%s\" at pos \"%s\" in dir \"%s\"\n" ldir.name lpath dir.name;
          Printf.printf "Add json file \"%s\"\n" file.name;
          self#add_file ldir file
          (*fcg#output_fcg()*)
        )
    )

  (* Complete the input dir with the input child dir and all its contained directories *)
  method complete_fcg_dir (dir:Callgraph_t.dir) (childpath:string) : unit =

    let rootdir = Common.get_root_dir childpath in
    if (String.compare rootdir dir.name != 0) then
    (
      Printf.printf "Function_callgraph.complete_fcg_dir:ERROR: the childpath rootdir \"%s\" doesn't match the input dir name \"%s\"\n" rootdir dir.name;
      raise Usage_Error
    );

    Printf.printf "complete_fcg_dir: Try to add child \"%s\" in dir=\"%s\"...\n" childpath dir.name;

    let leaf = self#get_leaf dir childpath in

    (match leaf with
    | None ->
      (
        Printf.printf "Not found any leaf in dir \"%s\" through path \"%s\"\n" dir.name childpath
      )
    | Some (lpath, ldir) ->
      (
        Printf.printf "Found leaf \"%s\" at pos \"%s\" in dir \"%s\"\n" ldir.name lpath dir.name;

        (* Get the remaining path to be created for adding the new child dir *)

        let (_, rpath) = Batteries.String.split childpath lpath in

        Printf.printf "Existing lpath is \"%s\"\n" lpath;

        (match rpath with
         | "" ->
          (
            Printf.printf "The child \"%s\" is already contained in dir \"%s\", so nothing to do here.\n" ldir.name dir.name;
          )
         | _ ->
          (
            Printf.printf "Path to be completed is \"%s\"\n" rpath;
            let cdir = self#create_dir_tree rpath in
            (*fcg#output_dir_tree "extension.fcg.gen.json" dir;*)

            (* Add the new child tree to the leaf *)
            (match ldir.children with
             | None -> (ldir.children <- Some [cdir])
             | Some children -> (ldir.children <- Some (cdir::children))
            )

            (* Output only the ldir with its new child *)
            (*fcg#output_dir_tree "ldir.gen.json" ldir;*)
          )
        )
      )
    )

  method complete_callgraph (filepath:string) (file:Callgraph_t.file option) : unit =

    let file_rootdir = Common.get_root_dir filepath in

    (* Check whether a callgraph root dir does already exists or not *)
    (match json_rootdir with
     | None ->
       (
         Printf.printf "Init rootdir: %s\n" file_rootdir;
         let fcg_dir = self#init_dir file_rootdir in
         (match file with
          | None -> self#complete_fcg_dir fcg_dir filepath
          | Some file -> self#complete_fcg_file fcg_dir filepath file
         );
         self#update_fcg_rootdir fcg_dir
       )
     | Some rootdir ->
       (
         (* Check whether root dirs are the same for the file and the fcg *)
         if (String.compare file_rootdir rootdir.name == 0) then
         (
           Printf.printf "Keep the callgraph rootdir %s for file %s\n" rootdir.name filepath;
           (match file with
            | None -> self#complete_fcg_dir rootdir filepath
            | Some file -> self#complete_fcg_file rootdir filepath file
           )
           (*self#update_fcg_rootdir fcg_dir*)
         )
         (* Check whether the name of the callgraph rootdir is included in the filepath rootdir *)
         else if (Batteries.String.exists filepath rootdir.name) then
         (
           Printf.printf "Change callgraph rootdir from %s to %s\n" rootdir.name file_rootdir;
           let rdir_sep = Printf.sprintf "/%s" rootdir.name in
           let (rootpath,childpath) = Batteries.String.split filepath rdir_sep in
           Printf.printf "root_path=%s, child_path=%s\n" rootpath childpath;
           let new_rdir : Callgraph_t.dir = self#init_dir file_rootdir in
           (* Add directories from new root dir down to the old root dir *)
           self#complete_fcg_dir new_rdir rootpath;

           (* Attach the old root dir to the new one *)
           (* let (_,pdir) = Batteries.String.rsplit rootpath "/" in *)
           (* Printf.printf "parent_dir=%s\n" pdir; *)
           (** Get a reference to the parent dir **)
           let pdir : (string * Callgraph_t.dir) option = self#get_leaf new_rdir rootpath in
           (match pdir with
            | None ->
               (
                 Printf.printf "ERROR: Not found any leaf in dir \"%s\" through path \"%s\"\n" new_rdir.name filepath;
                 raise Internal_Error
               )
            | Some (lpath, ldir) ->
               (
                 Printf.printf "Found leaf \"%s\" at pos \"%s\" in dir \"%s\"\n" ldir.name lpath new_rdir.name;
                 (* Complete the old root dir with some new child paths when needed *)
                 let old_rdir = self#get_fcg_rootdir in
                 let cpath = Printf.sprintf "/%s%s" rootdir.name childpath in
                 (match file with
                  | None -> self#complete_fcg_dir old_rdir cpath
                  | Some file -> self#complete_fcg_file old_rdir cpath file
                 );
                 (* Add the old root dir as a child of the present leaf *)
                 self#add_child_dir ldir old_rdir
               )
           );
           self#update_fcg_rootdir new_rdir
         )
         else
         (
           Printf.printf "Function_callgraph.complete_callgraph:UNIMPLEMENTED_CASE: rootdir=\"%s\", filepath=\"%s\"\n" rootdir.name filepath;
           raise Unsupported_Case
         )
       )
    )

  method parse_jsonfile (json_filepath:string) : unit =
    try
      (
	Printf.printf "Read callgraph's json file \"%s\"...\n" json_filepath;
	(* Read JSON file into an OCaml string *)
	let content = Core.Std.In_channel.read_all json_filepath in
	(* Read the input callgraph's json file *)
	self#update_fcg_rootdir (Callgraph_j.dir_of_string content)
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
        self#output_dir_tree json_filepath rootdir
      )

  method output_dir_tree (json_filepath:string) (dir:Callgraph_t.dir) : unit =

    Printf.printf "Write json file: %s\n" json_filepath;

    (* Serialize the directory dir_root with atdgen. *)
    let jdir_root = Callgraph_j.string_of_dir dir in

    (* Write the directory dir_root serialized by atdgen to a JSON file *)
    Core.Std.Out_channel.write_all json_filepath jdir_root

end

(*********************************** Unitary Tests **********************************************)

let test_complete_callgraph () =

    (* Add a new file *)
    let new_filename = "another_new_file.json" in
    let new_file : Callgraph_t.file =
      {
        name = new_filename;
        uses = None;
        declared = None;
        defined = None
      }
    in

    let fcg = new function_callgraph in
    fcg#complete_callgraph "/toto/tutu/tata/titi" None;
    fcg#complete_callgraph "/dir_a/dir_b/dir_c/toto/dir_d/dir_e/dir_f" (Some new_file);
    (* fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_b/dir_c" None; *)
    (* fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_z/dir_h/dir_z" None; *)
    fcg#output_fcg "complete_callgraph.unittest.gen.json";

    (* test get_file *)
    let rdir = fcg#get_fcg_rootdir in
    let _ = fcg#get_file rdir "/dir_a/dir_b/dir_c/toto/dir_d/dir_e/dir_f/another_new_file.json" in
    let _ = fcg#get_file rdir "/dir_a/dir_b/dir_c/toto/dir_d/toto.c" in
    ()

(* Check edition of a base dir to add a child subdir *)
let test_add_child () =

    let fcg = new function_callgraph in
    let dir = fcg#create_dir_tree "/dir_a/dir_b" in
    let dir_b = fcg#get_dir dir "/dir_a/dir_b" in
    let dir_b =
      (match dir_b with
      | None -> raise Internal_Error
      | Some dir_b -> dir_b
      )
    in
    Printf.printf "dir_b: %s\n" dir_b.name;
    let dir_k = fcg#init_dir "dir_k" in
    dir.children <- Some [ dir_b; dir_k ];
    fcg#output_dir_tree "original.gen.json" dir
    (*fcg#output_fcg "my_callgraph.unittest.gen.json"*)

let test_copy_dir () =

    let fcg = new function_callgraph in
    let dir = fcg#create_dir_tree "/dir_e/dir_r/dir_a/dir_b/dir_c" in
    let copie = fcg#copy_dir dir in
    fcg#output_dir_tree "copie.gen.json" copie
    (*fcg#output_fcg "my_callgraph.unittest.gen.json"*)

let test_update_dir () =

    let fcg = new function_callgraph in
    let dir = fcg#create_dir_tree "/dir_e/dir_r/dir_a/dir_b/dir_c" in
    fcg#update_fcg_rootdir dir;
    fcg#output_fcg "my_callgraph.unittest.gen.json"

(* Check edition of a base dir to add a leaf child subdir and a file in it *)
let test_add_leaf_child () =

    let fcg = new function_callgraph in
    let dir = fcg#create_dir_tree "/dir_a/dir_b/dir_c" in
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
        uses = None;
        declared = None;
        defined = None
      }
    in
    fcg#complete_fcg_file dir cpath new_file;

    (* Output the complete graph to check whether it has really been completed or not *)
    fcg#output_fcg "my_callgraph.unittest.gen.json"

let test_generate_ref_json () =

    let filename = "test_local_callcycle.c" in
    let file : Callgraph_t.file =
      {
        name = filename;
        uses = None;
        declared = None;
        defined = None
      }
    in

    let fcg = new function_callgraph in

    fcg#add_uses_file file "stdio.h";

    fcg#complete_callgraph "/root_dir/test_local_callcycle" (Some file);

    let rdir = fcg#get_fcg_rootdir in

    let dir = fcg#get_dir  rdir "/root_dir/test_local_callcycle" in

    (match dir with
     | None -> raise Internal_Error
     | Some dir ->
       (
        fcg#add_uses_dir dir "includes";
       )
    );

    let file = fcg#get_file rdir "/root_dir/test_local_callcycle/test_local_callcycle.c" in

    (match file with
     | None -> raise Internal_Error
     | Some file ->
       (
         let fct_main : Callgraph_t.fonction =
      	   {
      	     sign = "int main()";
      	     locallers = None;
      	     locallees = Some [ "void a()" ];
      	     extcallers = None;
      	     extcallees = None;
      	   }
         in

         let fct_a : Callgraph_t.fonction =
	   {
	     sign = "void a()";
	     locallers = None;
	     locallees = Some [ "int b()" ];
	     extcallers = None;
	     extcallees = Some [ "int printf()" ];
	   }
         in

         let fct_b : Callgraph_t.fonction =
	   {
	     sign = "int b()";
	     locallers = Some [ "void a()" ];
	     locallees = Some [ "int c()" ];
	     extcallers = None;
	     extcallees = Some [ "int printf()" ];
	   }
         in

         let fct_c : Callgraph_t.fonction =
	   {
	     sign = "int c()";
	     locallers = Some [ "int b()" ];
	     locallees = Some [ "void a()" ];
	     extcallers = None;
	     extcallees = Some [ "int printf()" ];
	   }
         in

         fcg#add_fct_defs file [fct_main; fct_a; fct_b; fct_c]
       )
    );

    let fct_printf : Callgraph_t.fonction =
      {
        sign = "int printf()";
        locallers = Some [ "void a()"; "int b()"; "int c()" ];
        locallees = None;
        extcallers = None;
        extcallees = None
      }
    in

    let file_stdio : Callgraph_t.file =
      {
        name = "stdio.h";
        uses = None;
        declared = Some [fct_printf];
        defined = None
      }
    in

    fcg#complete_callgraph "/root_dir/includes" (Some file_stdio);

    fcg#output_fcg "try.dir.callgraph.gen.json"


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
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -tag thread function_callgraph.native" *)
(* End: *)
