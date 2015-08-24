(* Copyright @: Thales Communications & Security *)
(* Author: Hugues Balp *)
(* This file generates a directory tree listing all json files of each directory *)

exception Unexpected_Error

(* List all json files present in the rootdir and all its subdirectories *)
let rec recursive_list_directories (rootdir:string) (fileext:string) : unit =
  try
    (
      Printf.printf "directory: %s\n" rootdir;
      let files : string array = Sys.readdir rootdir in
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
	      let path = Printf.sprintf "%s/%s" rootdir file in
	      Sys.is_directory path
	  ) 
	  files
      in
      List.iter
	(
	  fun subdir -> 
	    Printf.printf "subdir: %s\n" subdir;
	    let path = Printf.sprintf "%s/%s" rootdir subdir in
	    recursive_list_directories path fileext
	)
	subdirs;
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

(* Basic command *)
let usage : string = "Generation of a directory tree listing all json files present in each directory\n"
let command =
  Core.Std.Command.basic
    ~summary:usage
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun rootdir fileext () -> 

	Printf.printf "Listing <files>.%s in rootdir \"%s\" and its subdirectories...\n" fileext rootdir;
	Printf.printf "--------------------------------------------------------------------------------\n";
	recursive_list_directories rootdir fileext
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread list_json_files_in_dirs.native" *)
(* End: *)


