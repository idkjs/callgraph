(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(* This file completes the function's declarations generated by Callers with "definitions" members *)
(* It is issued from a copy/paste from the add_extcallees.ml OCAML backend *)
(* The high-level specification of this backend can be formalized as follows: *)
(* V fct_def, ] fct_decl / fct_def.decl = fct_decl *)
(* with V = whatever & ] = there is *)
(******************************************************************************)

(* module Declaration = Map.Make(String);; *)

type declaration = Declaration of string;;

class function_declaration_json_parser (callee_json_filepath:string) = object(self)

  val callee_file_path : string = callee_json_filepath

  method search_declared_symbol_in_directories (fct_sign:string) (dir:Callers_t.dir) (dirfullpath:string) : (string * int) option =

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
	  self#search_declared_symbol_in_dir fct_sign dir_symbols
      )
    in

    (match searched_symbol with

    | None -> (* Not yet found symbol, so we look for it in childrens directories *)
      (
	Printf.printf "Not found declared symbol \"%s\" in directory \"%s\", so we look for it in childrens directories\n" fct_sign dirfullpath;

	let searched_symbol : (string * int) option =
	  (match dir.childrens with
	  | None -> None
	  | Some subdirs ->

	    let searched_symbols : (string * int) option list =
	      List.map
		(
		  fun (d:Callers_t.dir) ->
		    let dirpath : string = Printf.sprintf "%s/%s" dirfullpath d.dir in
		    let searched_symbol = self#search_declared_symbol_in_directories fct_sign d dirpath in
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

    let content = Common.read_json_file defined_symbols_jsonfilepath in
    (match content with
    | None -> None
    | Some content ->
      (
	Printf.printf "Reads the symbols defined in file \"%s\"\n" defined_symbols_jsonfilepath;
	(* Printf.printf "HBDBG parsed content:\n %s: \n" content; *)
	Printf.printf "ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss\n";
	(* list_defined_symbols content rootdir_fullpath all_symbols_jsonfile application_name *)
	let dir_symbols : Callers_t.dir_symbols = Callers_j.dir_symbols_of_string content in
	(* print_endline (Callers_j.string_of_dir_symbols dir_symbols); *)
	Some dir_symbols
      )
    )

  (** Return the location of the function declaration when defined in one of the searched directories *)
  method search_declared_symbol (fct_sign:string) (rootdir_fullpath:string) : (string * int) option =

    Printf.printf "Return the location of function \"%s\" when found within root directory: \"%s\"\n" fct_sign rootdir_fullpath;

    let search_results : (string * int) option list  =
      List.map
	(
	  fun searched_dir_fullpath ->

	  (* Use the atdgen Yojson parser to parse the input directory tree json file *)
	  let jsondirext : string = "dir.callers.gen.json" in
	  let searched_dir_name : string = Filename.basename searched_dir_fullpath in
	  let searched_dir_jsoname : string = Printf.sprintf "%s/%s.%s" searched_dir_fullpath searched_dir_name jsondirext in
	  let searched_dir_content : string option = Common.read_json_file searched_dir_jsoname in

	  (match searched_dir_content with
	   | None -> None
	   | Some searched_dir_content ->
	      (
		let searched_dir_tree : Callers_t.dir = Callers_j.dir_of_string searched_dir_content in
		(* Look for the symbol in all directories recursively. *)
		self#search_declared_symbol_in_directories fct_sign searched_dir_tree searched_dir_fullpath
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
		     Printf.printf "add_declarations.ml: INFO::FOUND definition of function \"%s\" in \"%s:%d\"\n" fct_sign symb_def_file symb_def_line;
		     true
		   )
	      )
	    )
	    search_results
	)
      with
	Not_found ->
	(
	  Printf.printf "add_declarations.ml::WARNING::NOT FOUND symbol \"%s\" in root directory \"%s\"\n" fct_sign rootdir_fullpath;
	  Printf.printf "The input defined symbols json file is incomplete.\n";
	  Printf.printf "The not found symbol is probably part of an external library.\n";
	  (* raise Symbol_Not_Found; *)
	  None
	)
    in
    found_symbol

  (** Return the location of the function definition when defined in the input directory symbols table *)
  method search_declared_symbol_in_dir (fct_sign:string) (symbols:Callers_t.dir_symbols) : (string * int) option =

    Printf.printf "Search for the function's definition \"%s\" in directory \"%s\"...\n" fct_sign symbols.directory;

    (* Look for the function declaration among all functions defined in the json file *)
    let searched_symbols : (string * int) option list =
      List.map
      (
	fun (file : Callers_t.file) ->
	  (* Check whether the function is the searched one *)
	  let searched_symbol_def : (string * int) option =
	    try
	      (
		let searched_symbol : Callers_t.fct_decl option =
		  (
		    match file.declared with
		    | None -> None
		    | Some symbols ->
		      Some (
			List.find
			  (
			    fun (fct : Callers_t.fct_decl) ->
			    (* Printf.printf "HBDBG6: Check whether the function is the searched one: \"%s\" =?= \"%s\"\n" fct.sign fct_sign; *)
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
		    (* Get the function definition location *)
		    let symb_def_file : string = Printf.sprintf "%s/%s/%s" symbols.path symbols.directory file.file in
		    Printf.printf "HBDBG7 Found symbol \"%s\" in def=\"%s:%d\"\n" fct_sign symb_def_file found_symbol.line;
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

  method parse_functions_declarations (json_filepath:string) (rootdir_fullpath:string) : Callers_t.file option =

    (* Use the atdgen Yojson parser *)
    let dirpath : string = Common.read_before_last '/' json_filepath in
    let filename : string = Common.read_after_last '/' 1 json_filepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
    let content = Common.read_json_file jsoname_file in
    (match content with
    | None -> None
    | Some content ->
      (
	(* Printf.printf "Read caller file \"%s\" content is:\n %s: \n" filename content; *)
	(* Printf.printf "atdgen parsed json file is :\n"; *)
	let file : Callers_t.file = Callers_j.file_of_string content in
	(* print_endline (Callers_j.string_of_file file); *)

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
		      (* check where the function is really declared. *)
		      Printf.printf "Try to edit declaration of function \"%s\" defined in file \"%s\"...\n" fct.sign file.file;

		      (* Check whether the definition's declaration does already exists or not *)
		      let edited_declaration : declaration =

			(match fct.decl with
			 | Some decl ->
			    (
			      (* Make sure decl and def signatures are the same *)
			      (* if not (String.compare fct.sign decl.sign == 0) then *)
			      (*   raise Internal_Error; *)
			      Printf.printf "ALREADY KNOWN declaration: sign=\"%s\", decl=%s\n" fct.sign decl;
			      Declaration decl
			    )
			 | None ->
			    (
			      (* Location of declaration is not yet known. *)
			      Printf.printf "No already existing declaration for function implementation: sign=\"%s\", line=\"%d\", decl=?\n" fct.sign fct.line;
			      (Printf.printf "Try to look for symbol \"%s\" in the root directory \"%s\"...\n" fct.sign rootdir_fullpath;
			       let search_result : (string * int) option = self#search_declared_symbol fct.sign rootdir_fullpath
			       in
			       (match search_result with
				| Some (def_file, def_line) ->
				   (
				     (* Check whether the definition is local to the caller file or external. *)
				     (* Printf.printf "add_declarations.ml::INFO::Check whether the definition is local to the caller file or external.\n"; *)
				     (* Printf.printf "symb_def_file: %s\n" def_file; *)
				     (* Printf.printf "caller_file: %s\n" json_filepath; *)
				     let declaration_def : string = Printf.sprintf "%s:%d" def_file def_line in
				     let definition_def : string = Printf.sprintf "%s:%d" file.file fct.line
				     in
				     (* Make sure the declaration_def is wellformed or not *)
				     (match declaration_def with
				      | "" -> raise Common.Malformed_Declaration_Definition
				      | _ -> ());
				     if String.compare def_file json_filepath == 0 then
				       (
					 Printf.printf "add_declarations.ml::INFO::the declaration definition is local to the caller file, so replace it by a locallee !\n";
				       )
				     else
				       (
					 Printf.printf "add_declarations.ml::INFO::the declaration definition is extern to the caller file, so edit its definition: new value is \"%s\"\n" declaration_def
				       );
				     let (edited_declaration : declaration) = Declaration declaration_def
				     in
				     Printf.printf "EDITED declaration: sign=\"%s\", decl=\"%s\", def=\"%s\"\n"
						   fct.sign declaration_def definition_def;
				     edited_declaration
				   )
				| None ->
				   (
				     Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
				     Printf.printf "add_declarations.ml::WARNING::Not found symbol \"%s\" in root directory \"%s\"\n"
						   fct.sign rootdir_fullpath;
				     Printf.printf "The list of all defined symbols in input json files is incomplete.\n";
				     Printf.printf "The not found symbol is probably part of another external library.\n";
				     Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
				     (* raise Symbol_Not_Found *)

				     let declaration_def = "unlinkedDeclaration" in
				     let definition_def = "unlinkedDefinition" in

				     (* Keep the input excallee unchanged *)
				     let (edited_declaration : declaration) = Declaration declaration_def
				     in
				     Printf.printf "NOT FOUND declaration: sign=\"%s\", decl=%s, def=%s\n" fct.sign declaration_def definition_def;
				     edited_declaration
				   )
			       )
			      )
			    )
			)
		      in
		      let edited_declaration : string =
			(match edited_declaration with
			   | Declaration d -> d
			)
		      in
		      let edited_function : Callers_t.fct_def =
			{
			  (* eClass = Config.get_type_fct_def (); *)
  			  sign = fct.sign;
  			  line = fct.line;
			  virtuality = fct.virtuality;
			  decl = Some edited_declaration;
  			  locallers = fct.locallers;
  			  locallees = fct.locallees;
  			  extcallees = fct.extcallees;
  			  extcallers = fct.extcallers;
			  builtins = fct.builtins;
			}
		      in
		      edited_function
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
    ~summary:"Completes function definitions with declarations in generated json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun file_json rootdir_fullpath () ->
	try
	  (
	    let parser = new function_declaration_json_parser file_json in
	    let edited_file = parser#parse_functions_declarations file_json rootdir_fullpath in
	    (match edited_file with
	    | None -> ()
	    | Some edited_file ->
	      (
		(* let jsoname_file = String.concat "." [ file_json; "edited.debug.json" ] in *)
		let jsoname_file = String.concat "" [ file_json; ".file.callers.gen.json" ] in
		Common.print_callers_file edited_file jsoname_file
	      )
	    )
	  )
	with
	| Common.File_Not_Found _ -> raise Common.Usage_Error
	| _ ->
	  (
	    Printf.printf "add_declarations::ERROR::unexpected error\n";
	    raise Common.Unexpected_Error
	  )
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread add_declarations.native" *)
(* End: *)
