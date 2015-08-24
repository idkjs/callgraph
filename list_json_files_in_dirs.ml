(* Copyright @: Thales Communications & Security *)
(* Author: Hugues Balp *)
(* This file generates a directory tree listing all json files of each directory *)

exception Unexpected_Error

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("rootdir" %: string)

(* List all json files present in the rootdir and all its subdirectories *)
let recursive_list_directories (rootdir:string) : unit =

  try
    (
      let files : string array = Sys.readdir rootdir in
      let files = Array.to_list files
      in
      List.iter
	(
	  fun file -> 
	    Printf.printf "file: %s\n" file;
	)
	files
    )
  with
    Sys_error msg -> 
      (
	Printf.printf "list_json_files_in_dirs.ml:ERROR: %s\n" msg;
	raise Unexpected_Error
      )

(* Basic command *)
let usage : string = "Generation of a directory tree listing all json files present in each directory\n"
let command =
  Core.Std.Command.basic
    ~summary:usage
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun rootdir () -> 

	Printf.printf "Listing json files in rootdir \"%s\" and its subdirectories...\n" rootdir;
	Printf.printf "--------------------------------------------------------------------------------\n";
	recursive_list_directories rootdir
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread list_json_files_in_dirs.native" *)
(* End: *)


