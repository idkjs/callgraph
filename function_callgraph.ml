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

  method create_dir_tree (dirpaths:string) : Callgraph_t.dir =

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
                  | None -> ( Printf.printf "dir: %s\n" dir; None )
                  | Some ch -> ( Printf.printf "dir: %s, child: %s\n" dir ch.name; Some [ch])
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

  method get_leaf (dir:Callgraph_t.dir) (child_path:string) : Callgraph_t.dir option =

    let dirs = Batteries.String.nsplit child_path "/" in

    let leaf : Callgraph_t.dir option =

      (match dirs with
       | _::dirs ->
        (
          let pdir : Callgraph_t.dir option =
            List.fold_right
            (
              fun (dir:string) (child:Callgraph_t.dir option) ->

               let child : Callgraph_t.dir list option =
                 (match child with
                  | None -> ( Printf.printf "dir: %s\n" dir; None )
                  | Some ch -> ( Printf.printf "dir: %s, child: %s\n" dir ch.name; Some [ch])
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
          (match pdir with
           | None ->
             (
               Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
               Printf.printf "WARNING: not found child path \"%s\" in dir \%s\"\n" child_path dir.name;
               Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
               None
             )
           | Some dir -> pdir
          )
        )
       | _ ->
        (
          Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
          Printf.printf "WARNING_2: not found child path \"%s\" in dir \%s\"\n" child_path dir.name;
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

  method update_fcg_rootdir (rootdir:Callgraph_t.dir) : unit =

    json_rootdir <- Some rootdir

  method complete_callgraph (filepath:string) : unit =

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

  (* method get_relative_Dir_path (dir:Callgraph_t.dir) : string = *)
  (*   "unknownDirPath" *)

  (* method get_relative_file_path (file:Callgraph_t.file) : string = *)
  (*   "unknownFilePath" *)

  method write_fcg_jsonfile : unit =

    match json_rootdir with
    | None -> ()
    | Some rootdir ->
      (
        self#output_dir_tree json_filepath rootdir
      )

  method output_dir_tree (json_filepath:string) (dir:Callgraph_t.dir) : unit =

    (* Serialize the directory dir_root with atdgen. *)
    let jdir_root = Callgraph_j.string_of_dir dir in

    (* Write the directory dir_root serialized by atdgen to a JSON file *)
    Core.Std.Out_channel.write_all json_filepath jdir_root

end

let test_complete_graph () =

    let fcg = new function_callgraph "my_callgraph.unittest.gen.json" None in
    fcg#complete_callgraph "/dir_a/dir_b/dir_c/toto.c";
    fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_b/dir_c/toto.c";
    fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_z/dir_h/toto.j";
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

(* Check edition of a base dir to add a leaf child subdir *)
let test_add_leaf_child () =

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

let () =

   test_complete_graph();
   test_add_child();
   test_copy_dir();
   test_update_dir();
   test_add_leaf_child()

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -tag thread function_callgraph.native" *)
(* End: *)
