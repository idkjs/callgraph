(******************************************************************************)
(*   Copyright (C) 2015 THALES Communication & Security                       *)
(*   All Rights Reserved                                                      *)
(*   KTD SCIS 2014-2015                                                       *)
(*   Use Case Legacy TOSA                                                     *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(* This file generates a directory tree listing all json files of each directory *)
(******************************************************************************)

let is_not_ignored (dir:string) (ignored:string list) : bool =
  try
    let _ : string =
      List.find
	( fun i ->
	  (* Printf.printf "HBDBG:is_ignored i=%s =?= dir=%s\n" dir; *)
	  if String.compare i dir == 0
	  then
	    (
	      Printf.printf "ignored dir: \"%s\"\n" dir;
	      true
	    )
	  else
	    false
	)
	ignored
    in
    false
  with
    Not_found -> true

(* List all json files present in the rootdir and all its subdirectories *)
let rec recursive_list_directories (rootpath:string) (fileext:string) (ignored:string option): Callers_t.dir option =
  try
    (
      (* Printf.printf "dir: %s\n" rootpath; *)
      let ignored_dirs : string list =
	match ignored with
	| None -> []
	| Some dirs ->
	  (
	    (* Printf.printf "ignored dirs: %s\n" dirs; *)
	    Str.split (Str.regexp ":") dirs
	  )
      in
      let files : string array = Sys.readdir rootpath in
      let files = Array.to_list files in
      let files_maching_extension : string list =
	List.filter
	  (
	    fun file ->
	      let re = Str.regexp_string fileext in
	      try (
		ignore (Str.search_forward re file 0);
		true
	      )
	      with Not_found -> false
	  )
	  files
      in
      (* List.iter *)
      (*   ( *)
      (*     fun file -> Printf.printf "file: %s\n" file; *)
      (*   ) *)
      (*   files_maching_extension; *)

      let subdirs : string list =
	List.filter
	  (
	    fun (dir:string) ->
	      let path = Printf.sprintf "%s/%s" rootpath dir in
	      if Sys.is_directory path && is_not_ignored dir ignored_dirs then
		true
	      else
		false
	  )
	  files
      in
      let some_subdirs : (Callers_t.dir option) list =
	List.map
	  (
	    fun subdir ->
	      (* Printf.printf "subdir: %s\n" subdir; *)
	      let path = Printf.sprintf "%s/%s" rootpath subdir in
	      recursive_list_directories path fileext ignored
	  )
	  subdirs
      in
      let rootdir : string = Filename.basename rootpath in
      let json_files =
	(match files_maching_extension with
	| [] -> None
	| files -> Some files)
      in
      let json_subdirs : Callers_t.dir list option =
	let dirs_opt : Callers_t.dir option list =
	  List.filter
	    (
	      fun (dir_opt : Callers_t.dir option) ->
		(match dir_opt with
		| None -> false
		| Some d -> true)
	    )
	    some_subdirs
	in
	let dirs : Callers_t.dir list =
	  List.map
	    ( fun dir_opt ->
	      (match dir_opt with
	      | None -> raise Common.Unexpected_Error
	      | Some d -> d
	      )
	    )
	    dirs_opt
	in
	(match dirs with
	| [] -> None
	| subdirs -> Some subdirs)
      in
      let jsondir : Callers_t.dir =
	{
	  (* eClass = Config.get_type_dir(); *)
	  dir = rootdir;
	  files = json_files;
	  childrens = json_subdirs;
	}
      in
      Some jsondir
    )
  with
    Sys_error msg ->
      (
	Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
	Printf.printf "list_json_files_in_dirs.ml:WARNING: File not found: %s\n" msg;
	Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
	None
	(* raise Common.Unexpected_Error *)
      )

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("rootdir" %: string)
  +> anon ("fileext" %: string)
  +> anon ("jsondirext" %: string)
  +> anon (maybe("ignore" %: string))

(* Basic command *)
let usage : string = "Generation of a directory tree listing all json files present in each directory\n"
let command =
  Core.Std.Command.basic
    ~summary:usage
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun rootpath fileext jsondirext ignored () ->

	Printf.printf "Listing files matching extension \"%s\" in rootdir \"%s\" and its subdirectories...\n" fileext rootpath;
	(* Printf.printf "--------------------------------------------------------------------------------\n"; *)
	let jsondir = recursive_list_directories rootpath fileext ignored in
	let jsondir =
	  (match jsondir with
	  | None -> raise Common.Unexpected_Error
	  | Some dir -> dir
	  )
	in

	(* Write the json directory serialized by atdgen to a JSON file *)
	let rootdir : string = Filename.basename rootpath in
	let json_dirname : string = Printf.sprintf "%s/%s.%s" rootpath rootdir jsondirext
	in
	(* Printf.printf "--------------------------------------------------------------------------------\n"; *)
	Printf.printf "Generated file: %s\n" json_dirname;
        Common.print_callers_dir jsondir json_dirname
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread list_json_files_in_dirs.native" *)
(* End: *)
