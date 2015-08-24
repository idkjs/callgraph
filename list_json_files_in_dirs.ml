(* Copyright @: Thales Communications & Security *)
(* Author: Hugues Balp *)
(* This file generates a directory tree listing all json files of each directory *)

exception Unexpected_Error

(* List all json files present in the rootdir and all its subdirectories *)
let rec recursive_list_directories (rootpath:string) (fileext:string) : Callgraph_t.dir =
  try
    (
      Printf.printf "dir: %s\n" rootpath;
      let files : string array = Sys.readdir rootpath in
      let files = Array.to_list files in
      let files_maching_extension : string list = 
	List.filter
	  (
	    fun file -> 
	      let re = Str.regexp_string fileext in
	      try ignore (Str.search_forward re file 0); true
	      with Not_found -> false
	  )
	  files
      in
      List.iter
	(
	  fun file -> Printf.printf "file: %s\n" file;
	)
	files_maching_extension;
      let subdirs : string list = 
	List.filter 
	  (
	    fun (file:string) -> 
	      let path = Printf.sprintf "%s/%s" rootpath file in
	      Sys.is_directory path
	  ) 
	  files
      in
      let json_subdirs : Callgraph_t.dir list = 
	List.map
	  (
	    fun subdir -> 
	      (* Printf.printf "subdir: %s\n" subdir; *)
	      let path = Printf.sprintf "%s/%s" rootpath subdir in
	      recursive_list_directories path fileext
	  )
	  subdirs
      in
      let rootdir : string = Filename.basename rootpath in
      let json_files = 
	(match files_maching_extension with
	| [] -> None
	| files -> Some files)
      in
      let json_subdirs = 
	(match json_subdirs with
	| [] -> None
	| subdirs -> Some subdirs)
      in
      let jsondir : Callgraph_t.dir = 
	{
	  dir = rootdir;
	  files = json_files;
	  childrens = json_subdirs;
	} 
      in
      jsondir
    )
  with
    Sys_error msg -> 
      (
	Printf.printf "list_json_files_in_dirs.ml:ERROR: File not found error: %s\n" msg;
	raise Unexpected_Error
      )

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("rootdir" %: string)
  +> anon ("fileext" %: string)
  +> anon (maybe("jsondirext" %: string))

(* Basic command *)
let usage : string = "Generation of a directory tree listing all json files present in each directory\n"
let command =
  Core.Std.Command.basic
    ~summary:usage
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun rootpath fileext jsondirext () -> 

	Printf.printf "Listing files matching extension \"%s\" in rootdir \"%s\" and its subdirectories...\n" fileext rootpath;
	Printf.printf "--------------------------------------------------------------------------------\n";
	let jsondir = recursive_list_directories rootpath fileext in
	
	(* Serialize the directory dir1 with atdgen. *)
	let jdir = Callgraph_j.string_of_dir jsondir in

	(* print_endline jdir; *)
	
	(* Write the json directory serialized by atdgen to a JSON file *)
	let rootdir : string = Filename.basename rootpath in

	let json_dirname : string = 
	  (match jsondirext with
	  | None -> Printf.sprintf "%s/%s.dir.json" rootpath rootdir
	  | Some dirext -> Printf.sprintf "%s/%s.%s" rootpath rootdir dirext
	  )
	in
	Printf.printf "--------------------------------------------------------------------------------\n";
	Printf.printf "Generated file: %s\n" json_dirname;
	Core.Std.Out_channel.write_all json_dirname jdir
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread list_json_files_in_dirs.native" *)
(* End: *)
