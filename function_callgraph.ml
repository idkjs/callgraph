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

  method complete_callgraph (filepath:string) : unit =

    let file_rootdir = Common.get_root_dir filepath in

    (* Check whether a callgraph root dir does already exists or not *)
    (match json_rootdir with
     | None ->
       (
         Printf.printf "Init rootdir: %s\n" file_rootdir;
         let fcg_dir = self#init_dir file_rootdir in
         let fcg_dir = self#complete_fcg_rootdir fcg_dir filepath in
         json_rootdir <- Some (fcg_dir)
       )
     | Some rootdir ->
     (
       (* Check whether rootdir are the same for the file and the fcg*)
       if (String.compare file_rootdir rootdir.name == 0) then
       (
         Printf.printf "Keep the callgraph rootdir %s for file %s\n" rootdir.name filepath;
         let fcg_dir = self#complete_fcg_rootdir rootdir filepath in
         json_rootdir <- Some fcg_dir
       )
       (* Check whether the name of the callgraph rootdir is included in the filepath rootdir *)
       else if (Batteries.String.exists filepath rootdir.name) then
       (
         Printf.printf "Change callgraph rootdir from %s to %s\n" rootdir.name file_rootdir;
         let fcg_rootdir = self#init_dir file_rootdir in
         let fcg_dir = self#complete_fcg_rootdir fcg_rootdir filepath in
         json_rootdir <- Some fcg_dir
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
	json_rootdir <- Some (Callgraph_j.dir_of_string content)
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
        (* Serialize the directory dir_root with atdgen. *)
        let jdir_root = Callgraph_j.string_of_dir rootdir in

        (* Write the directory dir_root serialized by atdgen to a JSON file *)
        Core.Std.Out_channel.write_all json_filepath jdir_root;
      )

end

let () =

    let fcg = new function_callgraph "my_callgraph.json" None in
    fcg#complete_callgraph "/dir_a/dir_b/dir_c/toto.c";
    fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_b/dir_c/toto.c";
    fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_z/dir_h/toto.j";
    fcg#write_fcg_jsonfile

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -tag thread function_callgraph.native" *)
(* End: *)
