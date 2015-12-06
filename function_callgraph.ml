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
exception Usage_Error

(* Function callgraph *)
class function_callgraph (callgraph_jsonfile:string)
			 (other:string list option)
  = object(self)

  val json_filepath : string = callgraph_jsonfile

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

  method add_child_directory (parent:Callgraph_t.dir) (child:Callgraph_t.dir) : Callgraph_t.dir =

    let children : Callgraph_t.dir list option =
      (match parent.children with
       | None -> Some [child]
       | Some ch -> Some (child::ch)
      )
    in

    let pdir : Callgraph_t.dir =
      {
        name = parent.name;
        uses = parent.uses;
        children = children;
        files = parent.files
      }
    in
    pdir

  method add_file (dir:Callgraph_t.dir) (file:Callgraph_t.file) : unit =

    let files : Callgraph_t.file list option =
      (match dir.files with
       | None -> Some [file]
       | Some files -> Some (file::files)
      )
    in
    dir.files <- files

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
          (*fcg#write_fcg_jsonfile()*)
        )
    )

  (* Complete the input dir with the input child dir and all its contained directories *)
  method complete_fcg_dir (dir:Callgraph_t.dir) (childpath:string) : unit =

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
            ldir.children <- Some [cdir];

            (* Output only the ldir with its new child *)
            (*fcg#output_dir_tree "ldir.gen.json" ldir;*)
          )
        )
      )
    )

  method complete_callgraph (filepath:string) (file:Callgraph_t.dir option) : unit =

    let file_rootdir = Common.get_root_dir filepath in

    (* Check whether a callgraph root dir does already exists or not *)
    (match json_rootdir with
     | None ->
       (
         Printf.printf "Init rootdir: %s\n" file_rootdir;
         let fcg_dir = self#init_dir file_rootdir in
         let fcg_dir = self#complete_fcg_rootdir fcg_dir filepath in
         self#update_fcg_rootdir fcg_dir
       )
     | Some rootdir ->
     (
       (* Check whether rootdir are the same for the file and the fcg*)
       if (String.compare file_rootdir rootdir.name == 0) then
       (
         Printf.printf "Keep the callgraph rootdir %s for file %s\n" rootdir.name filepath;
         let fcg_dir = self#complete_fcg_rootdir rootdir filepath in
         self#update_fcg_rootdir fcg_dir
       )
       (* Check whether the name of the callgraph rootdir is included in the filepath rootdir *)
       else if (Batteries.String.exists filepath rootdir.name) then
       (
         Printf.printf "Change callgraph rootdir from %s to %s\n" rootdir.name file_rootdir;
         let fcg_rootdir = self#init_dir file_rootdir in
         let fcg_dir = self#complete_fcg_rootdir fcg_rootdir filepath in
         self#update_fcg_rootdir fcg_dir
       )
     )
    )

  method complete_fcg_rootdir (fcg_rootdir:Callgraph_t.dir) (filepath:string) : Callgraph_t.dir =

    (* Get the filename *)
    let (dirs, file) = Batteries.String.rsplit filepath "/" in
    Printf.printf "completed_fcg: dirs=%s, file=%s\n" dirs file;

    (* Get the directories *)
    let dirs = Batteries.String.nsplit dirs "/" in

    (match dirs with
     | _::rootdir::dirs ->
       (
         Printf.printf "Check whether the file rootdir=\"%s\" well matches the fcg_rootdir=\"%s\"...\n" rootdir fcg_rootdir.name;
         if (String.compare rootdir fcg_rootdir.name == 0) then
         (
           rdir <- self#copy_dir fcg_rootdir;
           cdir <- self#copy_dir fcg_rootdir;
           List.iter
            (fun dir ->
              Printf.printf "Check whether the dir=\"%s\" is already present in the parent dir=\"%s\"...\n" dir cdir.name;
              let dir_is_present : bool =
                (match cdir.children with
                  | None -> false
                  | Some children ->
                  (
                    try
                    (
                      List.find
                       (fun (child : Callgraph_t.dir) ->
                         String.compare dir child.name == 0
                       )
                      children;
                      true
                    )
                    with
                    | Not_found -> false
                  )
                )
              in
              (match dir_is_present with
               | true ->
                (
                  Printf.printf "The dir=\"%s\" is already present in the parent dir \"%s\", so we navigate through it\n" cdir.name dir
                  (*TBC*)
                )
               | false ->
                (
                  Printf.printf "The dir=\"%s\" is not yet present in the parent dir \"%s\", so we create it\n" cdir.name dir;
                  let fcg_dir = self#init_dir dir in
                  let cdir = self#add_child_directory cdir fcg_dir in
                  ()
                  (*TBC*)
                )
              )
            )
           dirs
         )
         else
         (
           Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
           Printf.printf "ERROR: the file rootdir=\"%s\" does not matches the fcg_rootdir=\"%s\"...\n" rootdir fcg_rootdir.name;
           Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
           raise Internal_Error
         )
       )
     | _ ->
       (
         Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
         Printf.printf "function_callgraph: ERROR, we should not be here normally\n";
         Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
         raise Internal_Error
       )
    );

    fcg_rootdir

  method parse_jsonfile () : unit =
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

  method write_fcg_jsonfile () : unit =

    match json_rootdir with
    | None ->
      (
        Printf.printf "WARNING: empty callgraph, so nothing to print\n";
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

let test_complete_graph () =

    let fcg = new function_callgraph "my_callgraph.unittest.gen.json" None in
    fcg#complete_callgraph "/dir_a/dir_b/dir_c" None;
    fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_b/dir_c" None;
    fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_z/dir_h/dir_z" None;
    fcg#write_fcg_jsonfile

(* Check edition of a base dir to add a child subdir *)
let test_add_child () =

    let fcg = new function_callgraph "my_callgraph.unittest.gen.json" None in
    let dir = fcg#create_dir_tree "/dir_a/dir_b" in
    let dir_b = fcg#get_child dir "dir_b" in
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

let test_copy_dir () =

    let fcg = new function_callgraph "my_callgraph.unittest.gen.json" None in
    let dir = fcg#create_dir_tree "/dir_e/dir_r/dir_a/dir_b/dir_c" in
    let copie = fcg#copy_dir dir in
    fcg#output_dir_tree "copie.gen.json" copie

let test_update_dir () =

    let fcg = new function_callgraph "my_callgraph.unittest.gen.json" None in
    let dir = fcg#create_dir_tree "/dir_e/dir_r/dir_a/dir_b/dir_c" in
    fcg#update_fcg_rootdir dir;
    fcg#write_fcg_jsonfile

(* Check edition of a base dir to add a leaf child subdir and a file in it *)
let test_add_leaf_child () =

    let fcg = new function_callgraph "my_callgraph.unittest.gen.json" None in
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
    fcg#write_fcg_jsonfile()

let () =

(*
   test_complete_graph();
   test_add_child();
   test_copy_dir();
   test_update_dir();
*)
   test_add_leaf_child()

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -tag thread function_callgraph.native" *)
(* End: *)
