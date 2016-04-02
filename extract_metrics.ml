(******************************************************************************)
(*   Copyright (C) 2015 THALES Communication & Security                       *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2016)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(* This program extracts metrics provided by the callers's analysis           *)
(* adapted from list_defined_symbols.ml *)
(******************************************************************************)

let (includes_dir_to_ignore:string) = Printf.sprintf "%s/%s" Common.rootdir_prefix "includes"

let is_includes_dir_to_ignore (dirpath:string) : bool =

  if (String.compare dirpath includes_dir_to_ignore == 0) then true else false

let parse_json_file (filename:string) (content:string) : Callers_t.file =

  try
    (* Printf.printf "atdgen parsed json file is :\n"; *)
    (* Use the atdgen JSON parser *)
    let file : Callers_t.file = Callers_j.file_of_string content in
    (* print_endline (Callers_j.string_of_file file); *)
    file
  with
    Yojson.Json_error msg ->
      (
  	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
  	Printf.printf "extract_metrics::ERROR::Unexpected_Json_File_Format::%s\n" filename;
  	Printf.printf "This json file is not compatible with Caller's generated json files\n";
  	Printf.printf "Sys_error msg: %s\n" msg;
  	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
  	raise Common.Unexpected_Json_File_Format
      )

let read_file_metrics (full_file_content:Callers_t.file) : Callers_t.file =

  (* Printf.printf "metrics.read_file_metrics:BEGIN: %s\n" full_file_content.file; *)

  let file_metrics : Callers_t.file =
    {
      (* eClass = Config.get_type_file(); *)
      file = full_file_content.file;
      kind = full_file_content.kind;
      nb_lines = full_file_content.nb_lines;
      nb_namespaces = full_file_content.nb_namespaces;
      nb_records = full_file_content.nb_records;
      nb_threads = full_file_content.nb_threads;
      nb_decls = full_file_content.nb_decls;
      nb_defs = full_file_content.nb_defs;
      path = None;
      namespaces = None;
      records = None;
      threads = None;
      declared = None;
      defined = None;
    }
  in
  (* Printf.printf "metrics.file_metrics:END: %s\n"; *)
  file_metrics

let rec parse_json_dir (dir:Callers_t.dir) (depth:int) (dirfullpath:string) (all_symbols_jsonfile:Core.Std.Out_channel.t) : unit =

  Printf.printf "metrics.parse_json_dir:BEGIN: %s\n" dirfullpath;

  Printf.printf "metrics.parse_json_dir:DEBUG: ================================================================================\n";

  let defined_symbols_filename : string = "defined_symbols.dir.callers.gen.json" in

  let defined_symbols_filepath : string = Printf.sprintf "%s/%s" dirfullpath defined_symbols_filename in

  (* Printf.printf "metrics.parse_json_dir:DEBUG: Generate defined symbols: %s\n" defined_symbols_filepath; *)

  let files : Callers_t.file list =

    (match dir.files with
    | None -> []
    | Some files ->
      List.map
	( fun (f:string) ->

	  let jsoname_file : string = Printf.sprintf "%s/%s" dirfullpath f in
	  (* Printf.printf "Parse file: %s\n" jsoname_file; *)
	  (* Printf.printf "--------------------------------------------------------------------------------\n"; *)

	      let content = Common.read_json_file jsoname_file in

	      (match content with

	      | Some content ->

		(* Printf.printf "Read %s content is:\n %s: \n" f content; *)
		let full_file_content : Callers_t.file = parse_json_file jsoname_file content in

		(* (\* Keep only symbols signatures and locations *\) *)
		(* let filtered_file_content : Callers_t.file = filter_file_content full_file_content in *)
		(* filtered_file_content *)

		(* Retrieve metrics *)
		let file_metrics : Callers_t.file = read_file_metrics full_file_content in

                file_metrics

	      | None ->
                 (
                   Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
                   Printf.printf "metrics: not found indexed json file: %s\n" jsoname_file;
                   Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
                   raise Common.Missing_Json_File
	         )
              )
	)
	files
    )
  in

  (* Write the list of defined symbols to the JSON output file *)
  let defined_symbols : Callers_t.dir_overview =
    {
      (* eClass = Config.get_type_dir_overview(); *)
      directory = dir.dir;
      depth = depth;
      path = Filename.dirname dirfullpath;
      files = files;
      nb_files = List.length files;
      nb_header_files = -1;
      nb_source_files = -2;
      nb_lines = -3;
      nb_namespaces = -4;
      nb_records = -5;
      nb_threads = -6;
      nb_decls = -7;
      nb_defs = -8;
    }
  in

  (* Write symbols in current directory *)
  (* Callers.print_callers_dir_overview defined_symbols defined_symbols_filepath; *)
  let jfile = Callers_j.string_of_dir_overview defined_symbols in
  Core.Std.Out_channel.write_all defined_symbols_filepath jfile;
  (* Printf.printf "metrics.parse_json_dir:DEBUG: Generated file: %s\n" defined_symbols_filepath; *)

  (* Add the symbols in the global list *)
  if depth > 0 then
    Core.Std.Out_channel.output_char all_symbols_jsonfile ',';
  Core.Std.Out_channel.output_string all_symbols_jsonfile jfile;
  (* Printf.printf "metrics.parse_json_dir:DEBUG: Added symbols of dir: %s\n" dirfullpath; *)

  let subdirs : string list option =
    (match dir.childrens with
    | None -> None
    | Some subdirs ->
      Some (
	List.map
	(
	  fun (d:Callers_t.dir) ->
	    let dirpath : string = Printf.sprintf "%s/%s" dirfullpath d.dir in
            (* Filter the callers unique includes directory which is redundant with other dirs *)
            if ((depth == 0) && (is_includes_dir_to_ignore dirpath)) then
              (
                Printf.printf "WARNING: ignore callers includes directory: %s" d.dir;
                d.dir
              )
            else
              (
	        let depth = depth + 1 in
	        parse_json_dir d depth dirpath all_symbols_jsonfile;
	        d.dir
              )
	)
	subdirs
      )
    )
  in
  (* Printf.printf "metrics.parse_json_dir:END: %s\n" dirfullpath; *)
  ()

let extract_metrics
    (content:string)
    (dirfullpath:string)
    (all_symbols_jsonfilepath:string)
    (application_name:string option) : unit =

  (* Printf.printf "metrics.extract_metrics:BEGIN: %s" dirfullpath; *)
  (* Printf.printf "metrics.extract_metrics:DEBUG: atdgen parsed json directory is :\n"; *)
  (* Use the atdgen JSON parser *)
  let dir : Callers_t.dir = Callers_j.dir_of_string content in
  (* print_endline (Callers_j.string_of_dir dir); *)

  (* Parse the json files contained in the current directory *)
  let all_symbols_jsonfile : Core.Std.Out_channel.t = Core.Std.Out_channel.create all_symbols_jsonfilepath in
  let rootdir = Filename.basename dirfullpath in
  let rootpath = Filename.dirname dirfullpath in
  let allsymb_fileheader : string =
    (match application_name with
    | None ->
      Printf.sprintf "{\"dir\":\"%s\",\"path\":\"%s\",\"dir_overview\":[" rootdir rootpath
    | Some appli ->
      Printf.sprintf "{\"application\":\"%s\",\"dir\":\"%s\",\"path\":\"%s\",\"dir_overview\":[" rootdir appli rootpath
    )
  in
  Core.Std.Out_channel.output_string all_symbols_jsonfile allsymb_fileheader;
  parse_json_dir dir 0 dirfullpath all_symbols_jsonfile;
  Core.Std.Out_channel.output_string all_symbols_jsonfile "]}"

  (* Printf.printf "metrics.extract_metrics:END: %s" dirfullpath *)

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("defined_symbols_jsonfile" %: string)
  +> anon ("jsondirext" %: string)
  +> anon (maybe("application_name" %: string))

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"For each json directory generated by the callers's analysis, this program generates one json file listing all the symbols defined in this directory"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun all_symbols_jsonfile jsondirext application_name () ->

	try

	  let dirname : string = Filename.basename Common.rootdir_prefix
	  in
	  let jsoname_dir : string = Printf.sprintf "/%s.%s" dirname jsondirext
	  in
	  let content = Common.read_json_file jsoname_dir in

	  (match content with
	  | Some content ->
	    Printf.printf "Start generation of defined symbols' json file from the json root directory...\n";
	    (* Printf.printf "parsed content:\n %s: \n" content; *)
	    Printf.printf "--------------------------------------------------------------------------------\n";
	    extract_metrics content Common.rootdir_prefix all_symbols_jsonfile application_name
	  | None -> Printf.printf "extract_metrics::Usage_Error:empty_input_dir_json_file!\n")

	with
	| Common.File_Not_Found ->
	    (
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	      Printf.printf "File_Not_Found error ! \n";
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	    )
	| Common.Unexpected_Json_File_Format ->
	    (
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	      Printf.printf "Unexpected_Json_File_Format error ! \n";
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	    )
	| Common.Usage_Error ->
	    (
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	      Printf.printf "Usage_Error error ! \n";
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	    )
	| Common.Unexpected_Error ->
	    (
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	      Printf.printf "Unexpected error ! \n";
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	    )
	| Yojson.Json_error _ ->
	    (
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	      Printf.printf "Yojson.Json_error error ! \n";
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	    )
	| Sys_error msg ->
	    (
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	      Printf.printf "System error %s \n" msg;
	      Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	    )
	(* | _ ->  *)
	(*     ( *)
	(*       Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n"; *)
	(*       Printf.printf "Unknown error 2 ! \n"; *)
	(*       Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n"; *)
	(*     ) *)
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread extract_metrics.native" *)
(* End: *)
