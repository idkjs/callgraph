(* Copyright @: Thales Communications & Security *)
(* Author: Hugues Balp *)
(* This file completes json files generated by Callers with "extcallee_defs" members *)

exception Internal_Error
exception Unexpected_Case
exception Usage_Error
exception File_Not_Found
exception Symbol_Not_Found
exception TBC

module Callers = Map.Make(String);;
module Callees = Map.Make(String);;

class function_callees_json_parser (callee_json_filepath:string) = object(self)

  val callee_file_path : string = callee_json_filepath

  method read_json_file (filename:string) : Yojson.Basic.json =

    try
      Printf.printf "In_channel read file %s...\n" filename;
      (* Read JSON file into an OCaml string *)
      let buf = Core.Std.In_channel.read_all filename in
      (* Use the string JSON constructor *)
      let json1 = Yojson.Basic.from_string buf in
      json1
    with
      Sys_error _ -> 
	(
	  Printf.printf "add_extcallees::ERROR::File_Not_Found::%s" filename;
	  raise File_Not_Found
	)

  (** Return the location of the function definition when found in the inpout jsonfilepath *)
  method search_defined_symbol (fct_sign:string) (defined_symbols_jsonfilepath:string) : string option =

    Printf.printf "Return the location of the function's definition declared as \"%s\" when found in the defined symbols json file \"%s\"...\n" fct_sign defined_symbols_jsonfilepath;
    (* Parse the input json file *)
    (* Use the atdgen Yojson parser *)
    let json : Yojson.Basic.json = self#read_json_file defined_symbols_jsonfilepath in
    let content : string = Yojson.Basic.to_string json in
    let symbols : Callgraph_t.symbols = Callgraph_j.symbols_of_string content in
    print_endline (Callgraph_j.string_of_symbols symbols);
    
    (* Look for the callee function among all functions defined in the json file *)
    let searched_symbols : string option list =
      List.map
      (
	fun (file : Callgraph_t.file) -> 
	  (* Check whether the function is the searched one *)
	  let searched_symbol_def : string option = 
	    try
	      (
		let searched_symbol : Callgraph_t.fct option = 
		  (
		    match file.defined with
		    | None -> None
		    | Some symbols ->
		      Some (
			List.find
			  (
			    fun (fct : Callgraph_t.fct) -> String.compare fct.sign fct_sign == 0
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
		    let symb_def_loc : string =
		      Printf.sprintf "%s/%s:%d" file.path file.file found_symbol.line
		    in
		    Some symb_def_loc
		  )
		)
	      )
	    with
	      Not_found -> None
	  in
	  searched_symbol_def
      )
	symbols.defined_symbols
    in

    let searched_symbol : string option =
      try
	List.find
	  (
	    fun (result : string option) -> 
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
    (match searched_symbol with
    | None ->
      (
	Printf.printf "add_extcallees.ml::ERROR::Not found symbol \"%s\" in file \"%s\"" fct_sign defined_symbols_jsonfilepath;
	raise Symbol_Not_Found;
	None
      )
    | Some symbol_def ->
      (
	Printf.printf "add_extcallees.ml: INFO::Found definition of function \"%s\" in \"%s\"\n" fct_sign symbol_def;
	Some symbol_def
      )
    )
      
  method print_edited_file (edited_file:Callgraph_t.file) (json_filename:string) =

    let jfile = Callgraph_j.string_of_file edited_file in
    print_endline jfile;
    (* Write the new_file serialized by atdgen to a JSON file *)
    (* let new_jsonfilepath:string = Printf.sprintf "%s.new.json" json_filename in *)
    (* Core.Std.Out_channel.write_all new_jsonfilepath jfile *)
    Core.Std.Out_channel.write_all json_filename jfile

  method parse_caller_file (json_filepath:string) (defined_symbols_jsonfilepath:string): Callgraph_t.file =

    (* Use the atdgen Yojson parser *)
    let dirpath : string = Common.read_before_last '/' json_filepath in
    let filename : string = Common.read_after_last '/' 1 json_filepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
    let json : Yojson.Basic.json = self#read_json_file jsoname_file in
    let content : string = Yojson.Basic.to_string json in
    Printf.printf "Read caller file \"%s\" content is:\n %s: \n" filename content;
    Printf.printf "atdgen parsed json file is :\n";
    let file : Callgraph_t.file = Callgraph_j.file_of_string content in
    print_endline (Callgraph_j.string_of_file file);
    
    (* Parse the json functions contained in the current file *)
    let edited_functions:Callgraph_t.fct list =

      (match file.defined with
      | None -> []
      | Some fcts ->
	(
	  (* Parses all defined function *)
	  let edited_functions : Callgraph_t.fct list =

	    List.map
  	      (
  		fun (fct:Callgraph_t.fct) -> 
		  (
		    (* Edit external callees of each function *)
		    let edited_extcallees : Callgraph_t.extfct list option =

		      (match fct.extcallees with
		      | None -> None
		      | Some extcallees ->
			Printf.printf "Try to edit external callees of function \"%s\" declared in caller file \"%s\"...\n" fct.sign file.file;
			Some (
			  List.map
			  ( 
			    fun (f:Callgraph_t.extfct) -> 
			      (
				(* Check whether the extcallee definition does already exists or not *)
				let extcallee_def : string =

				  (match f.def with
				  | "unknownExtFctDef" ->
				    (
				      (* Location of extcallee linked definition is not yet known. *)
				      Printf.printf "Not found definition of extcallee: sign=\"%s\", decl=%s, def=?\n" f.sign f.decl;
				      
				      (Printf.printf "Try to look for symbol \"%s\" in the defined symbols json file \"%s\"...\n" f.sign defined_symbols_jsonfilepath;
				       let search_result : string option = self#search_defined_symbol f.sign defined_symbols_jsonfilepath
				       in
				       (match search_result with
				       | Some def_loc -> def_loc
				       | None -> 
					 (
					   Printf.printf "add_extcallees.ml::INFO:: Not found symbol \"%s\" inf file \"%s\"...\n" f.sign defined_symbols_jsonfilepath;
					   raise TBC
					 )
				       )
				      )
				    )
				  | _ -> f.def
				  )
				in

				Printf.printf "extcallee def: sign=\"%s\", decl=%s, def=%s\n" f.sign f.decl extcallee_def;
				let edited_extcallee : Callgraph_t.extfct =
				  {
		      		    sign = f.sign;
		      		    decl = f.decl;
		      		    def = extcallee_def;
				  }
				in
				edited_extcallee
			      )
			  )
			  extcallees
			)
		      )
		    in
		    let edited_function : Callgraph_t.fct =
		      {
  			sign = fct.sign;
  			line = fct.line;
  			locallers = fct.locallers;
  			locallees = fct.locallees;
  			extcallees = edited_extcallees;
  			extcallers = fct.extcallers;
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

    let edited_file : Callgraph_t.file = 
      {
	file = file.file;
	path = file.path;
	defined = Some edited_functions;
      }
    in
    edited_file

end

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("file_json" %: string)
  +> anon ("defined_symbols_jsonfilepath" %: string)

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Completes external callee's funcion definitions in callers's generated json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun file_json defined_symbols_jsonfilepath () -> 
	try
	  (
	    let parser = new function_callees_json_parser file_json in
	    let edited_file = parser#parse_caller_file file_json defined_symbols_jsonfilepath in

	    (* let jsoname_file = String.concat "." [ file_json; "edited.debug.json" ] in *)
	    let jsoname_file = String.concat "" [ file_json; ".file.callers.gen.json" ] in
	    parser#print_edited_file edited_file jsoname_file
	  )
	with
	  File_Not_Found _ -> raise Unexpected_Case
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread add_extcallees.native" *)
(* End: *)
