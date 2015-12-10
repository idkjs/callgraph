(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

exception Graph_Dir_Unsupported_Dir_Dependency_Type
exception Graph_Dir_Unsupported_Dir_Vertex_Style

(********************* Begin Directory Dependency Graph *********************)

type dir_decl =
{
  id : string;
  name : string;
  rpath : string;
  fpath : string;
  (* includes : string list; *)
  mutable uses : string list;
  sg : Graph.Graphviz.DotAttributes.subgraph;
  parent : dir_decl option;
  style : string;
}

(* representation of a node -- must be hashable *)
module Node = struct
  (* type t = int *)
  type t = dir_decl
  let compare = Pervasives.compare
  let hash = Hashtbl.hash
  let equal = (=)
end

(* representation of an edge -- must be comparable *)
module Edge = struct
  type t = string
  let compare = Pervasives.compare
  let equal = (=)
  let default = ""
end

(* a fileal/persistent graph *)
module G = Graph.Persistent.Digraph.ConcreteBidirectionalLabeled(Node)(Edge)

(* more modules available, e.g. graph traversal with depth-first-search *)
(* module D = Graph.Traverse.Dfs(G) *)

let a_color : int ref = ref 0;;

(* module for creating dot-files *)
module Dot = Graph.Graphviz.Dot(struct
  include G (* use the graph module from above *)
  let edge_attributes (a, e, b) = 
    let style = match e with
      | "contains" -> `Solid
      | "inc_internal" -> `Dashed
      | "inc_external" -> `Solid
      | "inv_internal" -> `Dashed
      | "inv_external" -> `Solid
      | "inc_external_of_focus" -> `Dashed
      (* | _ -> `Solid *)
      | t -> 
	(
	  Printf.printf "graph_dir:error: unsupported dir dependency type: %s\n" t;
	  raise Graph_Dir_Unsupported_Dir_Dependency_Type
	)
    in
    let arrowtail_style = match e with
      | "contains" -> `Dot
      | _ -> `Normal
    in
    let arrowhead_style = match e with
      (* | "contains" -> `Inv *)
      (* | "contains" -> `Dot *)
      | "contains" -> `Odot
      (* | "contains" -> `None *)
      | _ -> `Normal
    in
    a_color := !a_color + 100000;
    let color = match e with
      | "contains" -> 10000 (* blue *)
      | "inc_internal" -> 4711 (* dark blue *)
      | "inc_external" -> 4711 (* dark blue *)
      | "inc_external_of_focus" -> 16480000 (* orange (warning) *)
      | "inv_internal" -> 2300 (* blue *)
      | "inv_external" -> 2300 (* blue *)
      (* | _ -> !a_color *)
      | t -> 
	(
	  Printf.printf "graph_dir:error: unsupported dir dependency type: %s\n" t;
	  raise Graph_Dir_Unsupported_Dir_Dependency_Type
	)
    in
    (* let label = Printf.sprintf "%d" color *)
    let label = match e with
      | "contains" -> ""
      | "inc_internal" -> ""
      | "inc_external" -> ""
      | "inv_internal" -> ""
      | "inv_external" -> ""
      | "inc_external_of_focus" -> ""
      (* | _ -> e *)
      | t ->
    	(
    	  Printf.printf "graph_dir:error: unsupported dir dependency type: %s\n" t;
    	  raise Graph_Dir_Unsupported_Dir_Dependency_Type
    	)
    in
    [`Label label; `Color color; `Style style; `Arrowhead arrowhead_style; `Arrowtail arrowtail_style]

  let default_edge_attributes _ = []
  let get_subgraph v = (*Some v.sg*)
    (* (match v.parent with *)
    (* | None -> Printf.printf "dirdepgraph: no parent subgraph for v.name=%s in v.path=%s\n" v.name v.path *)
    (* | Some p -> Printf.printf "dirdepgraph: parent subgraph of v.name=%s in v.path=%s is p.name=%s\n" v.name v.path p.sg_name ); *)
    Printf.printf "dirdepgraph: parent subgraph of v.name=%s in v.path=%s is p.name=%s\n" v.name v.rpath v.sg.sg_name;
    Some v.sg
  let vertex_attributes v = 
    (* let label = v.name in *)
    (* let label = v.fpath in *)
    let label = v.rpath in
    (* let label = String.concat ":" [v.name; v.id] in *)
    match v.style with
    | "" -> [`Label label; `Shape `Box; `Style `Solid ]
    | "invis" -> [`Label label; `Shape `Box; `Style `Invis ]
    | _ -> raise Graph_Dir_Unsupported_Dir_Vertex_Style
  let vertex_name v = v.id
  let default_vertex_attributes _ = []
  let graph_attributes _ = []
  (* let graph_attributes g = [`Comment g.comment] *)
  (* let graph_attributes attr =  *)
  (*   let comment : string =  *)
  (*     try *)
  (* 	let cmnt = ref "" in *)
  (* 	let cmt:Graph.Graphviz.DotAttributes.graph =  *)
  (* 	  List.find *)
  (* 	    ( fun a ->  *)
  (* 	      match a with *)
  (* 	      | `Comment c ->  *)
  (* 		( *)
  (* 		  cmnt := c; *)
  (* 		  true *)
  (* 		) *)
  (* 	      | _ -> false ) *)
  (* 	    attr *)
  (* 	in *)
  (* 	!cmnt *)
  (* 	(\* match cmt with *\) *)
  (* 	(\* | `Comment -> c *\) *)
  (* 	(\* | None -> Common.Internal_Error *\) *)
  (*     with *)
  (* 	Not_found -> "" *)
  (*   in *)
  (*   [`Comment comment] *)
end)

(********************* End Dir Dependency Graph *********************)

let get_dir_id (path:string) : string =

  let regexp1 = Str.regexp "/" in
  let regexp2 = Str.regexp "\\." in
  let id1 : string = Str.global_replace regexp1 "_" path in
  let id2 : string = Str.global_replace regexp2 "_" id1 in
  id2

let get_dir_name (path:string) :string = Common.read_after_last '/' 1 path

(* let get_dir_path (path:string) :string = Common.read_before_last '/' path *)

let get_parent_path (path:string) :string = Common.read_before_last '/' path

let share_same_parent dir1 dir2 : bool = 

  let parent1 = get_parent_path dir1.fpath in
  let parent2 = get_parent_path dir2.fpath in  
  Common.is_same_string parent1 parent2

(********************* Class Dir *********************)

class dir (path:string) = object(self)

    val dir_id : string = get_dir_id path;
    val dir_path : string = path;      
    val dir_name : string = get_dir_name path;
    val parent_path : string = get_parent_path path;

    val mutable subdirs : string list = [];

    method get_name : string = dir_name

    method get_path : string = dir_path

    method add_subdir (subdir:string) : unit = 

      Printf.printf "graph_dir: add subdir=\"%s\" to dir=\"%s\"\n" subdir dir_name;
      subdirs <- subdir::subdirs

    method has_subdirs : bool = 

      let nb_subdirs = List.length subdirs in
      if nb_subdirs = 0 then
	(
	  Printf.printf "graph_dbg: directory located in ppath=\"%s\" has NO subdirs\n" dir_path;
	  false
	)
      else
	(
	  Printf.printf "graph_dbg: directory located in ppath=\"%s\" has subdirs\n" dir_path;
	  true
	)
end

(********************* Class Directories *********************)

class directories (root_directory:string) = object(self)

    (* Root directory *)
    val root_dir : string = 
      (
	Printf.printf "graph_dbg: set root path =\"%s\"" root_directory;
	root_directory
      )

    val mutable parent_path : string = root_directory

    val system_root_dir = ""

    method private reset_parent_path : unit = parent_path <- root_dir

    method private set_parent_path (path:string) : unit = parent_path <- path

    method private get_parent_path : string = parent_path
	
    (* Registered directories *)
    val mutable dirs : dir list = [];

    (* Get the directory instance located in path *)
    method get_dir (path:string) : dir option =

      try
	(
	  let d : dir =
	    List.find
	      (
		fun d ->

		  let cmp : int = String.compare d#get_path path in
		  match cmp with
		  | 0 -> true
		  | _ -> false
	      )
	      dirs
	  in
	  Printf.printf "graph_dir: get dir \"%s\" from path %s\n" d#get_name path;
	  Some d
	)
      with Not_found ->
	(
	  Printf.printf "graph_dir: no dir found with path %s\n" path;
	  None
	)

    (* Create a directory located in the input path.
       Raise an Already_Existing exception if this directory does already exists. *)
    method private create_dir (path:string) : dir option = 

      (* Check whether the directory doas already exists or not *)
      let dir = self#get_dir path in
      match dir with
      | Some d -> 
	(
	  Printf.printf "graph_dbg: try to create an already existing directory located in path=\"%s\"\n" path;
	  raise Common.Already_Existing
	)
      | None -> 
	(
	  (* Create the directory *)
	  Printf.printf "graph_dbg: create directory located in path=\"%s\"\n" path;
	  let new_dir = new dir path in
	  (* Register the directory *)
	  dirs <- new_dir::dirs;
	  Some new_dir
	)

    (* Create the user root directory
       Raise an Already_Existing exception if this directory does already exists. *)
    method create_user_root_dir (path:string) : dir option = 

      self#create_dir root_dir

    (* Create the system root directory
       Raise an Already_Existing exception if this directory does already exists. *)
    method create_system_root_dir : dir option = 

      self#create_dir system_root_dir

    (* Check if the input path is the root dir *)
    method private is_root_dir (path:string) : bool = 

      let cmp = String.compare root_dir path in
      match cmp with 
      | 0 -> ( Printf.printf "path=\"%s\" is the root_dir=\"%s\"\n" path root_dir; true )
      | _ -> ( Printf.printf "path=\"%s\" is not the root_dir=\"%s\"\n" path root_dir; false )

    (* Check if the input dir1_path is a subdir of the second dir2 path *)
    method is_subdir_of (dir1_path:string) (dir2_path:string) : bool = 

	let dir1_path_size = String.length dir1_path in
	let dir2_path_size = String.length dir2_path in
	if dir1_path_size < dir2_path_size
	then 
	  ( 
	    Printf.printf "debug_size: dir1_path=\"%s\" is not a substring of dir2_path=\"%s\"\n" dir1_path dir2_path; 
	    false
	  )
	else
	  try
	    let cmp_path = String.sub dir1_path 0 dir2_path_size in
	    let cmp = String.compare dir2_path cmp_path in
	    match cmp with 
	    | 0 -> ( Printf.printf "dir1_path=\"%s\" is a substring of dir2_path=\"%s\"\n" dir1_path dir2_path; true )
	    | _ -> ( Printf.printf "dir1_path=\"%s\" is not a substring of dir2_path=\"%s\"\n" dir1_path dir2_path; false )
	  with 
	    Invalid_argument _ -> ( Printf.printf "info: dir1_path=\"%s\" is not a substring of dir2_path=\"%s\"\n" dir1_path dir2_path; false )

    (* Check if the input path is a subdir of the root path *)
    method private is_root_subdir (path:string) : bool = 

      (* Check whether the path is the root dir or not *)
      if self#is_root_dir path 
      then
	false
      else
	(* Check if the input path is a subdir of the root path *)
	self#is_subdir_of path root_dir

    (* For valid root subdirs, returns the relative subpath.
       Raise an Invalid_Argument for invalid root subpaths. *)
    method get_root_subpath (path:string) : string =
	
      (* Check whether the path is a root subdir or not *)
      if self#is_root_subdir path 
      then
	let rsize = String.length root_dir in
	let size = String.length path in
	let relative_subpath : string = String.sub path (rsize + 1) (size - rsize -1) in
	Printf.printf "debug_relative_subpath: path=%s, relative_subpath=%s\n" path relative_subpath;
	relative_subpath
      else
	(* This path is not a path to a root subdir, so keep it unchanged ! *)
	path
	(* ( *)
	(*   Printf.printf "ERROR:debug_relative_subpath: path=%s, root_dir=%s\n" path root_dir; *)
	(*   raise Common.Invalid_argument *)
	(* ) *)

    (* Check whether directories instances are well present for the root subdirectory located in path 
       and all its parents directories. Create them otherwise.
       Raise an Invalid_Argument for invalid root subpaths. *)
    method private check_root_subdir (path:string) : unit =

	(* Get the root subpath *)
	let rpath = self#get_root_subpath path in
	match rpath with
	(* is not a root subdir*)
	| "none" -> raise Hbdbg_16
	(* is a root subdir*)
	| _ ->
	  (
	    self#set_parent_path root_dir;
	    
	    (* Navigate through the root subpath and check if a directory instance is well present.
	       Create it otherwise. *)
	    self#check_subdir rpath
	  )
	    
    (* Check whether instances are well present for the directory located in path 
       and all its parents directories. Create them otherwise. *)
    method private check_other_dir (path:string) : unit =

      self#set_parent_path system_root_dir;

      (* Navigate through the root subpath and check if a directory instance is well present.
	 Create it otherwise. *)
      self#check_subdir path

    (* Navigate through the subpath and check if a directory instance is well present.
       Create it otherwise. *)
    method private check_subdir (subpath:string) : unit =

      (*  Split the subpath into a list of strings *)
      let r = Str.regexp "/" in
      let loc : string list = Str.split r subpath in

      List.iter
	( 
	  fun l -> 

	    (* Get parent dir *)
	    let parent_path = self#get_parent_path in
	    let parent : dir option = self#get_dir parent_path in

	    (match parent with

	    (* Normally, a directory should always been found here *)
	    | None -> 
	      (
		Printf.printf "graph_dir: not found directory normally located in parent_path=%s !\n" parent_path;
		raise Hbdbg_151(* ; raise Common.Internal_Error *)
	      )
	    | Some p ->
	      (
		(* Update current_path *)
		let current_path = String.concat "/" [parent_path;l] in

		(* Tries to create the directory even if it exists *)
		(try
		   (
		     let current_dir = self#create_dir current_path in
		     match current_dir with
		     (* Normally, a directory should always been created here *)
		     | None -> (raise Hbdbg_16(* ; raise Common.Internal_Error *))
		     | Some c -> (* Add this subdirectory to the parent list of subdirs *)
		       p#add_subdir l
		   )
		 with
		   Common.Already_Existing -> ());
		
		(* Update parent_path *)
		self#set_parent_path current_path
	      );
	    )
	)
	loc
	  
    (* Check whether instances are well present for the directory located in path and all its parents directories. 
       Create them otherwise. *)
    method check_dir (path:string) : unit =

      (* Check whether the path is a root subdir or not *)
      if self#is_root_subdir path 
      then
	(
	  Printf.printf "HBDBG1: check_root_subdir path=%s, root_dir=%s\n" path root_dir;
	  self#check_root_subdir path
	)
      else
	self#check_other_dir path

end

(********************* End of File *********************)

(* Local Variables: *)
(* mode: tuareg *)
(* End: *)
