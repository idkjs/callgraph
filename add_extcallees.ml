(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(* This file completes json files generated by Callers with "extcallee_defs" members *)
(******************************************************************************)

(* module Callers = Map.Make(String);; *)
(* module Callees = Map.Make(String);; *)

type callee = LocCallee of string | ExtCallee of Callers_t.extfct;;

class function_callees_json_parser (callee_json_filepath:string) = object(self)

  val callee_file_path : string = callee_json_filepath

  method search_symbol_in_directories (fct_sign:string) (dir:Callers_t.dir) (dirfullpath:string) : (string * int) option =

    Printf.printf "Parse dir: %s\n" dirfullpath;
    Printf.printf "================================================================================\n";

    let defined_symbols_filename : string = "defined_symbols.dir.callers.gen.json" in

    let defined_symbols_filepath : string = Printf.sprintf "%s/%s" dirfullpath defined_symbols_filename in

    Printf.printf "Read symbols defined in dir: %s\n" dirfullpath;

    let dir_symbols : Callers_t.dir_symbols option = self#read_defined_symbols_in_dir defined_symbols_filepath in

    let searched_symbol : (string * int) option =
      (
	match dir_symbols with
	| None -> None
	| Some dir_symbols ->
	  self#search_symbol_in_dir fct_sign dir_symbols
      )
    in

    (match searched_symbol with

    | None -> (* Not yet found symbol, so we look for it in childrens directories *)
      (
	Printf.printf "Not found symbol \"%s\" in directory \"%s\", so we look for it in childrens directories\n" fct_sign dirfullpath;

	let searched_symbol : (string * int) option =
	  (match dir.childrens with
	  | None -> None
	  | Some subdirs ->

	    let searched_symbols : (string * int) option list =
	      List.map
		(
		  fun (d:Callers_t.dir) ->
		    let dirpath : string = Printf.sprintf "%s/%s" dirfullpath d.dir in
		    let searched_symbol = self#search_symbol_in_directories fct_sign d dirpath in
		    searched_symbol
		)
		subdirs
	    in
	    let searched_symbol : (string * int) option = self#filter_found_symbol searched_symbols in
	    searched_symbol
	  )
	in
	searched_symbol
      )

    | Some found_symbol ->
      (
	Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	Printf.printf "FOUND symbol \"%s\" in directory \"%s\" !\n" fct_sign dirfullpath;
	Printf.printf "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF\n";
	searched_symbol
      )
    )

  (** Reads the symbols defined in input directory *)
  method read_defined_symbols_in_dir (defined_symbols_jsonfilepath:string) : Callers_t.dir_symbols option =

    Printf.printf "add_extcallees.read_defined_symbols_in_dir:INFO: defined_symbols_jsonfilepath=%s\n" defined_symbols_jsonfilepath;
    let content = Common.read_json_file defined_symbols_jsonfilepath in
    (match content with
    | None -> None
    | Some content ->
      (
	Printf.printf "Reads the symbols defined in file \"%s\"\n" defined_symbols_jsonfilepath;
	(* Printf.printf "DEBUG parsed content:\n %s: \n" content; *)
	Printf.printf "ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss\n";
	(* list_defined_symbols content rootdir_fullpath all_symbols_jsonfile application_name *)
	let dir_symbols : Callers_t.dir_symbols = Callers_j.dir_symbols_of_string content in
	(* print_endline (Callers_j.string_of_dir_symbols dir_symbols); *)
	Some dir_symbols
      )
    )

  (** Return the location of the function definition when defined in one of the searched directories *)
  method search_defined_symbol (fct_sign:string) (rootdir_fullpath:string) : (string * int) option =

    Printf.printf "add_extcallees.search_defined_symbol:INFO: return the location of function \"%s\" when found within root directory: \"%s\"\n" fct_sign rootdir_fullpath;

    let search_results : (string * int) option list  =
      List.map
	(
	  fun searched_dir_fullpath ->

	  (* Use the atdgen Yojson parser to parse the input directory tree json file *)
	  let jsondirext : string = "dir.callers.gen.json" in
	  let searched_dir_name : string = Filename.basename searched_dir_fullpath in
	  let searched_dir_jsoname : string = Printf.sprintf "%s/%s.%s" searched_dir_fullpath searched_dir_name jsondirext in
          Printf.printf "add_extcallees.search_defined_symbol:INFO: searched_dir_jsoname=%s\n" searched_dir_jsoname;
          Printf.printf "add_extcallees.search_defined_symbol:DEBUG: searched_dir_fullpath=%s\n" searched_dir_fullpath;
	  let searched_dir_content = Common.read_json_file searched_dir_jsoname in

	  (match searched_dir_content with
	   | None -> None
	   | Some searched_dir_content ->
	      (
		let searched_dir_tree : Callers_t.dir = Callers_j.dir_of_string searched_dir_content in

		(* Look for the symbol in all directories recursively. *)
		self#search_symbol_in_directories fct_sign searched_dir_tree searched_dir_fullpath
	      )
	  )
	)
	[rootdir_fullpath]
    in

    let found_symbol : (string * int) option =
      try
	(
	  List.find
	    ( fun result ->
	      (
		match result with
		| None -> false
		| Some (symb_def_file, symb_def_line) ->
		   (
		     Printf.printf "add_extcallees.ml: INFO::FOUND definition of function \"%s\" in \"%s:%d\"\n" fct_sign symb_def_file symb_def_line;
		     true
		   )
	      )
	    )
	    search_results
	)
      with
	Not_found ->
	(
	  Printf.printf "add_extcallees.ml::WARNING::NOT FOUND symbol \"%s\" in root directory \"%s\"\n" fct_sign rootdir_fullpath;
	  Printf.printf "The input defined symbols json file is incomplete.\n";
	  Printf.printf "The not found symbol is probably part of an external library.\n";
	  None
	)
    in
    found_symbol

  (** Return the location of the function definition when defined in the input directory symbols table *)
  method search_symbol_in_dir (fct_sign:string) (symbols:Callers_t.dir_symbols) : (string * int) option =

    Printf.printf "Search for the function's definition \"%s\" in directory \"%s\"...\n" fct_sign symbols.directory;
    (* print_endline (Callers_j.string_of_dir_symbols symbols); *)

    (* Look for the callee function among all functions defined in the json file *)
    let searched_symbols : (string * int) option list =
      List.map
      (
	fun (file : Callers_t.file) ->
	  (* Check whether the function is the searched one *)
	  let searched_symbol_def : (string * int) option =
	    try
	      (
		let searched_symbol : Callers_t.fct_def option =
		  (
		    match file.defined with
		    | None -> None
		    | Some symbols ->
		      Some (
			List.find
			  (
			    fun (fct : Callers_t.fct_def) ->
			      (* Printf.printf "DEBUG: Check whether the function is the searched one: \"%s\" =?= \"%s\"\n" fct.sign fct_sign; *)
			      String.compare fct.sign fct_sign == 0
			  )
			  symbols
		      )
		  )
		in
		(match searched_symbol with
		| None -> None
		| Some found_symbol ->
		  (
                    (* Filter the rootdir prefix "/tmp/callers" of the symbol's file path *)
                    (* found in file defined_symbols.dir.callers.gen.json *)
                    let symb_file = Common.filter_root_dir symbols.path in
		    (* Get the function definition location *)
		    let symb_def_file : string = Printf.sprintf "%s/%s/%s" symb_file symbols.directory file.file in
		    Printf.printf "DEBUG Found symbol \"%s\" in def=\"%s:%d\"\n" fct_sign symb_def_file found_symbol.line;
		    Some (symb_def_file, found_symbol.line)
		  )
		)
	      )
	    with
	      Not_found -> None
	  in
	  searched_symbol_def
      )
	symbols.file_symbols
    in
    self#filter_found_symbol searched_symbols

  method filter_found_symbol (searched_symbols : (string * int) option list) : (string * int) option =

    let searched_symbol : (string * int) option =
      try
	List.find
	  (
	    fun result ->
	      (* Check whether the function is the searched one *)
  	      (match result with
	      | None -> false
	      | Some _ -> true
	      )
	  )
	  searched_symbols
      with
	Not_found -> None
    in
    searched_symbol

  method parse_caller_file (json_filepath:string) (rootdir_fullpath:string) : Callers_t.file option =

    let dirpath : string = Common.read_before_last '/' json_filepath in
    let filename : string = Common.read_after_last '/' 1 json_filepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
    Printf.printf "add_extcallees.parse_caller_file:INFO: jsoname_file=%s\n" jsoname_file;
    Printf.printf "add_extcallees.parse_caller_file:DEBUG: dirpath=%s, filename=%s, json_filepath=%s\n" dirpath filename json_filepath;
    let content = Common.read_json_file jsoname_file in
    (match content with
    | None -> None
    | Some content ->
      (
	(* Printf.printf "Read caller file \"%s\" content is:\n %s: \n" filename content; *)
	(* Printf.printf "atdgen parsed json file is :\n"; *)
	let file : Callers_t.file = Callers_j.file_of_string content in

	(* Parse the json functions contained in the current file *)
	let edited_functions:Callers_t.fct_def list =

	  (match file.defined with
	  | None -> []
	  | Some fcts ->
	    (
	      (* Parses all defined function *)
	      let edited_functions : Callers_t.fct_def list =

		List.map
  		  (
  		    fun (fct:Callers_t.fct_def) ->
		      (
			(* For each external callee, check where it is really declared. *)
			(* If only one definition is attached to the declaration and is in fact located in the caller file, *)
			(* then replace this external callee function by a local one. *)
			(match fct.extcallees with
			| None -> fct
			| Some extcallees ->
			  (
			    Printf.printf "Try to edit external callees of function \"%s\" defined in caller file \"%s\"...\n" fct.sign file.file;

			    let edited_extcallees : callee list =

			      List.map
				(
				  fun (f:Callers_t.extfct) ->
				    (
				      (* Check whether the extcallee definition does already exists or not *)
				      let edited_callee : callee =

					(match f.def with
					| "builtinFunctionDef" ->
					  (
					    let (edited_extcallee : callee) = ExtCallee
					      {
		      				sign = f.sign;
		      				decl = f.decl;
		      				def = f.decl;
					      }
					    in
					    Printf.printf "BUILTIN extcallee: sign=\"%s\", decl=%s\n" f.sign f.decl;
					    edited_extcallee
					  )
					| "unknownExtFctDef" ->
					  (
					    (* Location of extcallee linked definition is not yet known. *)
					    Printf.printf "Not found definition of extcallee: sign=\"%s\", decl=%s, def=?\n" f.sign f.decl;

					    (Printf.printf "Try to look for symbol \"%s\" in the root directory \"%s\"...\n" f.sign rootdir_fullpath;
					     let search_result : (string * int) option = self#search_defined_symbol f.sign rootdir_fullpath
					     in
					     (match search_result with
					     | Some (def_file, def_line) ->
					       (
						 (* Check whether the definition is local to the caller file or external. *)
						 (* Printf.printf "add_extcallees.ml::INFO::Check whether the definition is local to the caller file or external.\n"; *)
						 (* Printf.printf "symb_def_file: %s\n" def_file; *)
						 (* Printf.printf "caller_file: %s\n" json_filepath; *)
						 if String.compare def_file json_filepath == 0 then
						   (
						     Printf.printf "add_extcallees.ml::INFO::the extcallee definition is local to the caller file, so replace it by a locallee !\n";
						     let new_locallee : callee = LocCallee f.sign in
						     Printf.printf "REPLACED extcallee by locallee: sign=\"%s\", line=%d\n" f.sign def_line;
						     new_locallee
						   )
						 else
						   (
						     (* let extcallee_def : string = Printf.sprintf "%s:%d" filepath def_line *)
						     let extcallee_def : string = Printf.sprintf "%s:%d" def_file def_line
						     in
						     Printf.printf "add_extcallees.ml::INFO::the extcallee definition is extern to the caller file, so edit its definition: new value is \"%s\"\n" extcallee_def;
						     (* Make sure the extcalle_def is wellformed or not *)
						     (match extcallee_def with
						     | "" -> raise Common.Malformed_Extcallee_Definition
						     | _ -> ());
						     let (edited_extcallee : callee) = ExtCallee
						       {
		      					 sign = f.sign;
		      					 decl = f.decl;
		      					 def = extcallee_def;
						       }
						     in
						     Printf.printf "EDITED extcallee: sign=\"%s\", decl=%s, def=%s\n" f.sign f.decl extcallee_def;
						     edited_extcallee
						   )
					       )
					     | None ->
					       (
						 Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
						 Printf.printf "add_extcallees.ml::WARNING::Not found symbol \"%s\" in root directory \"%s\"\n" f.sign rootdir_fullpath;
						 Printf.printf "The list of all defined symbols in input json files is incomplete.\n";
						 Printf.printf "The not found symbol is probably part of another external library.\n";
						 Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";

						 (* Keep the input excallee unchanged *)
						 let (edited_extcallee : callee) = ExtCallee
						   {
		      				     sign = f.sign;
		      				     decl = f.decl;
		      				     def = "unlinkedExtCallee";
						   }
						 in
						 Printf.printf "NOT_FOUND extcallee: sign=\"%s\", decl=%s, def=%s\n" f.sign f.decl f.def;
						 edited_extcallee
					       )
					     )
					    )
					  )
					| _ -> ExtCallee f
					)
				      in
				      edited_callee
				    )
				)
				extcallees
			    in
			    let external_callees : callee list =
			      List.filter
				(
				  fun callee ->
				    match callee with
				    | LocCallee _ -> false
				    | ExtCallee _ -> true
				)
				edited_extcallees
			    in
			    let new_local_callees : callee list =
			      List.filter
				(
				  fun callee ->
				    match callee with
				    | LocCallee _ -> true
				    | ExtCallee _ -> false
				)
				edited_extcallees
			    in
			    let extcallees : Callers_t.extfct list option =
			      (
				match external_callees with
				| [] -> None
				| _ ->
				  Some
				    (
				      List.map
					(fun extcallee ->
					  match extcallee with
					  | LocCallee _ -> raise Common.Internal_Error
					  | ExtCallee extc -> extc
					)
					external_callees
				    )
			      )
			    in
			    let locallees : string list option =
			      (
				fct.locallees;
				match new_local_callees with
				| [] -> fct.locallees
				| _ ->
				  (
				    let new_locallees : string list =
				      List.map
					(fun locallee ->
					  match locallee with
					  | LocCallee lc -> lc
					  | ExtCallee _ -> raise Common.Internal_Error
					)
					new_local_callees
				    in
				    let locallees : string list =
				      (match fct.locallees with
				      | None -> new_locallees
				      | Some locallees ->
					List.append locallees new_locallees)
				    in
				    Some locallees
				  )
			      )
			    in
			    let edited_function : Callers_t.fct_def =
			      {
				(* eClass = Config.get_type_fct_def(); *)
  				sign = fct.sign;
  				line = fct.line;
				decl = fct.decl;
				virtuality = fct.virtuality;
  				locallees = locallees;
  				extcallees = extcallees;
				builtins = fct.builtins;
			      }
			    in
			    edited_function
			  )
			)
		      )
		  )
		  fcts
	      in
	      edited_functions
	    )
	  )
	in

	let edited_file : Callers_t.file =
	  {
	    (* eClass = Config.get_type_file (); *)
	    file = file.file;
	    path = file.path;
	    namespaces = file.namespaces;
	    records = file.records;
	    declared = file.declared;
	    defined = Some edited_functions;
	  }
	in
	Some edited_file
      )
    )
end

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("file_json" %: string)
  +> anon ("rootdir_fullpath" %: string)

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Completes external callee's funcion definitions in callers's generated json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun file_json rootdir_fullpath () ->
	try
	  (
	    let parser = new function_callees_json_parser file_json in
	    let edited_file = parser#parse_caller_file file_json rootdir_fullpath in
	    (match edited_file with
	    | None -> ()
	    | Some edited_file ->
	      (
		(* let jsoname_file = String.concat "." [ file_json; "edited.debug.json" ] in *)
		let jsoname_file = String.concat "" [ file_json; ".file.callers.gen.json" ] in
		Callers.print_callers_file edited_file jsoname_file
	      )
	    )
	  )
	with
	| Common.File_Not_Found _ -> raise Common.Usage_Error
	(* | _ -> *)
	(*   ( *)
	(*     Printf.printf "add_extcallees::ERROR::unexpected error\n"; *)
	(*     raise Common.Unexpected_Error *)
	(*   ) *)
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread add_extcallees.native" *)
(* End: *)
