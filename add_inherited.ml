(* Copyright @: Thales Communications & Security *)
(* Author: Hugues Balp *)
(* This file completes json files generated by Callers with "inheriteds" members *)

exception Internal_Error
exception Unexpected_Case
exception Usage_Error
exception Missing_File_Path
(* exception TBC *)

module Callers = Map.Make(String);;
module Callees = Map.Make(String);;

class function_callers_json_parser (callee_json_filepath:string) = object(self)

  val callee_file_path : string = callee_json_filepath

  method read_json_file (filename:string) : Yojson.Basic.json =

    Printf.printf "In_channel read file %s...\n" filename;
    (* Read JSON file into an OCaml string *)
    let buf = Core.Std.In_channel.read_all filename in           
    (* Use the string JSON constructor *)
    let json1 = Yojson.Basic.from_string buf in
    json1

  method add_inherited_to_function (inherited:Callgraph_t.extfct) (fct:Callgraph_t.fct) : Callgraph_t.fct =

    Printf.printf "add the inherited \"%s\" to the inheriteds list of function \"%s\"...\n" inherited.sign fct.sign;

    let new_inheriteds =

      (match fct.inheriteds with	 
       
       | None -> inherited::[]

       | Some inheriteds -> inherited::inheriteds
      )
    in

    let updated_fct:Callgraph_t.fct = 
      {
	sign = fct.sign;
	line = fct.line;
	virtuality = fct.virtuality;
	locallers = fct.locallers;
	locallees = fct.locallees;
	inheriteds = Some new_inheriteds;
	inherits = fct.inherits;
	builtins = fct.builtins;
      }
    in
    updated_fct

  method add_inherited_to_file (inherited:Callgraph_t.extfct) (callee_sign:string) (callee_jsonfilepath:string) : unit = 

    Printf.printf "Try to add inherited \"%s\" to callee function \"%s\" defined in file \"%s\"...\n" inherited.sign callee_sign callee_jsonfilepath;
    (* Parse the json file of the callee function *)
    let dirpath : string = Common.read_before_last '/' callee_jsonfilepath in
    let filename : string = Common.read_after_last '/' 1 callee_jsonfilepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
    (* Use the atdgen Yojson parser *)
    let json : Yojson.Basic.json = self#read_json_file jsoname_file in
    let content : string = Yojson.Basic.to_string json in
    (* Printf.printf "Read callee file \"%s\" content is:\n %s: \n" filename content; *)
    (* Printf.printf "atdgen parsed json file is :\n"; *)
    let file : Callgraph_t.file = Callgraph_j.file_of_string content in
    (* print_endline (Callgraph_j.string_of_file file); *)
    
    (* Look for the callee function among all functions defined in the callee file *)
    let new_defined_functions : Callgraph_t.fct list =

      (match file.defined with

       | None -> 	      
	  (
	    (* Abnormal case. At least the callee function should normally be defined in the callee file. *)
	    Printf.printf "Suspect case. The callee function \"%s\" should normally be defined in the callee file \"%s\" ! However it might have been ignored by callers analysis of the callee file"
			  callee_sign callee_jsonfilepath;
	    []
	    (* raise Usage_Error *)
	  )

       | Some fcts ->

	  List.map
  	    (
  	      fun (fct:Callgraph_t.fct) -> 

	      let new_fct:Callgraph_t.fct = 

              (* Check whether the function is the callee one *)
	      if (String.compare fct.sign callee_sign == 0) then
		(
		  let callee = fct in

		  (* Check whether the inherited is already present in inheriteds list *)
		  Printf.printf "Check whether the inherited \"%s\" is already present in inheriteds list of callee function \"%s\"\n" 
				inherited.sign callee_sign;
		  
		  (* Parses the list of external callers *)
		  let new_callee:Callgraph_t.fct =

		    (match callee.inheriteds with

		     | None -> 
			(
			  (* Add the inherited if not present *)
			  Printf.printf "It is not present, so ";
			  self#add_inherited_to_function inherited fct 
			)

		     | Some inheriteds ->
			(
			  (* Look for the inherited "inherited.sign" *)
			  Printf.printf "Parse the external callers of callee function \"%s\" defined in file \"%s\"...\n" callee.sign file.file;
			  try
			    (
			      let inherited = 
				List.find
  				  (
  				    fun (f:Callgraph_t.extfct) -> 
				    Printf.printf "inherited: sign=\"%s\", decl=%s, def=%s\n" f.sign f.decl, f.def;
				    String.compare inherited.sign f.sign == 0
				  )
				  inheriteds
			      in
			      Printf.printf "The inherited \"%s\" is already present in the definition of callee function \"%s\", so there is nothing to edit.\n"
					    inherited.sign callee_sign;
			      fct
			    )
			  with
			    Not_found -> 
			    (
			      (* Add the inherited if not present *)
			      Printf.printf "It is not present, so ";
			      self#add_inherited_to_function inherited callee
			    )
			)
		    )
		  in
		  new_callee
		)
	      else
		fct
	      in
	      new_fct
	    )
	    fcts
      )
    in

    (* WARNING: in cases where the callee function is never used locally as a caller one,
        it might not yet been present in the input callee json file; therefore we have to add it once
        we know it is called from outside of the file. *)

    (* Check whether the callee function is well present in the callee file. *)
    try
      (
	let _ (*already_existing_callee_fct*) = 
	  List.find
	    (
  	      fun (fct:Callgraph_t.fct) -> String.compare fct.sign callee_sign == 0
	    )
	    new_defined_functions
	in

	(* The callee function does already exists in the callee file. *)

	let new_file : Callgraph_t.file = 
	  {
	    file = file.file;
	    path = file.path;
	    records = file.records;
	    defined = Some new_defined_functions;
	  }
	in
	self#print_edited_file new_file	jsoname_file
      )
    with
      Not_found -> 
      (
	Printf.printf "The callee function \"%s\" is not yet present in file \"%s\" as expected; so we add it to satisfy the external call relationship\n"
		      callee_sign file.file;

	let newly_added_callee_fct : Callgraph_t.fct = 
	  {
	    sign = callee_sign;
	    line = -1;
	    virtuality = None;
	    locallers = None;
	    locallees = None;
	    inheriteds = Some [ inherited ];
	    inherits = None;
	    builtins = None;
	  }
	in

	(* Now the caller function will be added to the callee file. *)
	let new_file : Callgraph_t.file = 
	  {
	    file = file.file;
	    path = file.path;
	    records = file.records;
	    defined = Some (newly_added_callee_fct::new_defined_functions);
	  }
	in
	self#print_edited_file new_file jsoname_file
      );
      
  method print_edited_file (edited_file:Callgraph_t.file) (json_filename:string) =

    let jfile = Callgraph_j.string_of_file edited_file in
    (* print_endline jfile; *)
    (* Write the new_file serialized by atdgen to a JSON file *)
    (* let new_jsonfilepath:string = Printf.sprintf "%s.new.json" json_filename in *)
    (* Core.Std.Out_channel.write_all new_jsonfilepath jfile *)
    Core.Std.Out_channel.write_all json_filename jfile

  method parse_current_file (*fct_sign:string*) (json_filepath:string) : (* Callgraph_t.fct option *) unit =

    (* Use the atdgen Yojson parser *)
    let dirpath : string = Common.read_before_last '/' json_filepath in
    let filename : string = Common.read_after_last '/' 1 json_filepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
    let json : Yojson.Basic.json = self#read_json_file jsoname_file in
    let content : string = Yojson.Basic.to_string json in
    (* Printf.printf "Read caller file \"%s\" content is:\n %s: \n" filename content; *)
    (* Printf.printf "atdgen parsed json file is :\n"; *)
    let file : Callgraph_t.file = Callgraph_j.file_of_string content in
    (* print_endline (Callgraph_j.string_of_file file); *)
    
    (* Parse the json functions contained in the current file *)
    (match file.defined with
     | None -> ()
     | Some fcts ->

        (* parse inherits of each function *)
	List.iter
  	  (
  	    fun (fct:Callgraph_t.fct) -> 

	    (* Parses external callees *)
	    (match fct.inherits with
	     | None -> ()
	     | Some inherits ->
		Printf.printf "Parse external callees of function \"%s\" defined in file \"%s\"...\n" fct.sign file.file;
		List.iter
		  ( 
		    fun (f:Callgraph_t.extfct) -> 

		    Printf.printf "inherits: sign=\"%s\", decl=%s, def=%s\n" f.sign f.decl f.def;
		    let inherited : Callgraph_t.extfct = 
		      {
			sign = fct.sign;
			decl = "unknownExtFctDecl";
			def = 
			  (match file.path with
			  | None -> raise Missing_File_Path
			  | Some path -> Printf.sprintf "%s/%s:%d" path file.file fct.line
			  );
		      }
		    in
		    let def_file : string = 
		      (match f.def with
		      | "unknownExtFctDef" -> 
			(
			  Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
			  Printf.printf "add_inheriteds.ml::ERROR::incomplete caller file json file:\"%s\"\n" json_filepath;
			  Printf.printf "You need first to complete inherits definitions by executing the add_inherits ocaml program\n";
			  Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
			  raise Usage_Error
			)
		      | "builtinFunctionDef" ->
			(
			  Printf.printf "IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n";
			  Printf.printf "add_inheriteds.ml::WARNING::the builtin function \"%s\" is called by function \"%s\" defined in json file:\"%s\"\n" f.sign fct.sign json_filepath;
			  Printf.printf "IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII\n";
			  "unknownBuiltinFunctionLocation"
			)
		      | "unlinkedInherits" ->
			(
			  Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
			  Printf.printf "add_inheriteds.ml::WARNING::incomplete caller file json file:\"%s\"\n" json_filepath;
			  Printf.printf "The link edition may have failed due to an incomplee defined symbols json file.\n";
			  Printf.printf "The unlinked symbol below is probably part of an external library:\n";
			  Printf.printf "caller symb: %s\n" fct.sign;
			  Printf.printf "unlinked inherits symb: %s\n" f.sign;
			  Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
			  "unknownLocation"
			)
		      | _ ->
			(
			  let loc : string list = Str.split_delim (Str.regexp ":") f.def in
			  (match loc with
			  | [ file; _ ] ->  file
			  | _ -> raise Unexpected_Case))
			)
		    in
		    (
		      match def_file with
		      | "unknownBuiltinFunctionLocation" 
		      | "unknownLocation" -> ()
		      | _ -> self#add_inherited_to_file inherited f.sign def_file
		    ) 
		  )
		  inherits
	    )
	  )
	  fcts
    )
end

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("file_json" %: string)

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Parses function's inherits from callers's generated json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun file_json () -> 
      
      let parser = new function_callers_json_parser file_json in

      parser#parse_current_file file_json;
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread add_inheriteds.native" *)
(* End: *)
