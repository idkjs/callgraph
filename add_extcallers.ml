(* Copyright @: Thales Communications & Security *)
(* Author: Hugues Balp *)
(* This file completes json files generated by Callers with "extcallers" members *)

exception Internal_Error
exception Unexpected_Case
exception Usage_Error
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

  method add_extcaller_to_function (extcaller:Callgraph_t.extfct) (fct:Callgraph_t.fct) : Callgraph_t.fct =

    Printf.printf "add the extcaller \"%s\" to the extcallers list of function \"%s\"...\n" extcaller.sign fct.sign;

    let new_extcallers =

      (match fct.extcallers with	 
       
       | None -> extcaller::[]

       | Some extcallers -> extcaller::extcallers
      )
    in

    let updated_fct:Callgraph_t.fct = 
      {
	sign = fct.sign;
	line = fct.line;
	locallers = fct.locallers;
	locallees = fct.locallees;
	extcallers = Some new_extcallers;
	extcallees = fct.extcallees;
	builtins = fct.builtins;
      }
    in
    updated_fct

  method add_extcaller_to_file (extcaller:Callgraph_t.extfct) (callee_sign:string) (callee_jsonfilepath:string) : unit = 

    Printf.printf "Try to add extcaller \"%s\" to callee function \"%s\" defined in file \"%s\"...\n" extcaller.sign callee_sign callee_jsonfilepath;
    (* Parse the json file of the callee function *)
    let dirpath : string = Common.read_before_last '/' callee_jsonfilepath in
    let filename : string = Common.read_after_last '/' 1 callee_jsonfilepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
    (* Use the atdgen Yojson parser *)
    let json : Yojson.Basic.json = self#read_json_file jsoname_file in
    let content : string = Yojson.Basic.to_string json in
    Printf.printf "Read callee file \"%s\" content is:\n %s: \n" filename content;
    Printf.printf "atdgen parsed json file is :\n";
    let file : Callgraph_t.file = Callgraph_j.file_of_string content in
    print_endline (Callgraph_j.string_of_file file);
    
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

		  (* Check whether the extcaller is already present in extcallers list *)
		  Printf.printf "Check whether the extcaller \"%s\" is already present in extcallers list of callee function \"%s\"\n" 
				extcaller.sign callee_sign;
		  
		  (* Parses the list of external callers *)
		  let new_callee:Callgraph_t.fct =

		    (match callee.extcallers with

		     | None -> 
			(
			  (* Add the extcaller if not present *)
			  Printf.printf "It is not present, so ";
			  self#add_extcaller_to_function extcaller fct 
			)

		     | Some extcallers ->
			(
			  (* Look for the extcaller "extcaller.sign" *)
			  Printf.printf "Parse the external callers of callee function \"%s\" defined in file \"%s\"...\n" callee.sign file.file;
			  try
			    (
			      let extcaller = 
				List.find
  				  (
  				    fun (f:Callgraph_t.extfct) -> 
				    Printf.printf "extcaller: sign=\"%s\", decl=%s, def=%s\n" f.sign f.decl, f.def;
				    String.compare extcaller.sign f.sign == 0
				  )
				  extcallers
			      in
			      Printf.printf "The extcaller \"%s\" is already present in the definition of callee function \"%s\", so there is nothing to edit.\n"
					    extcaller.sign callee_sign;
			      fct
			    )
			  with
			    Not_found -> 
			    (
			      (* Add the extcaller if not present *)
			      Printf.printf "It is not present, so ";
			      self#add_extcaller_to_function extcaller callee
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
	    locallers = None;
	    locallees = None;
	    extcallers = Some [ extcaller ];
	    extcallees = None;
	    builtins = None;
	  }
	in

	(* Now the caller function will be added to the callee file. *)
	let new_file : Callgraph_t.file = 
	  {
	    file = file.file;
	    path = file.path;
	    defined = Some (newly_added_callee_fct::new_defined_functions);
	  }
	in
	self#print_edited_file new_file jsoname_file
      );
      
  method print_edited_file (edited_file:Callgraph_t.file) (json_filename:string) =

    let jfile = Callgraph_j.string_of_file edited_file in
    print_endline jfile;
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
    Printf.printf "Read caller file \"%s\" content is:\n %s: \n" filename content;
    Printf.printf "atdgen parsed json file is :\n";
    let file : Callgraph_t.file = Callgraph_j.file_of_string content in
    print_endline (Callgraph_j.string_of_file file);
    
    (* Parse the json functions contained in the current file *)
    (match file.defined with
     | None -> ()
     | Some fcts ->

        (* parse extcallees of each function *)
	List.iter
  	  (
  	    fun (fct:Callgraph_t.fct) -> 

	    (* Parses external callees *)
	    (match fct.extcallees with
	     | None -> ()
	     | Some extcallees ->
		Printf.printf "Parse external callees of function \"%s\" defined in file \"%s\"...\n" fct.sign file.file;
		List.iter
		  ( 
		    fun (f:Callgraph_t.extfct) -> 

		    Printf.printf "extcallee: sign=\"%s\", decl=%s, def=%s\n" f.sign f.decl f.def;
		    let extcaller : Callgraph_t.extfct = 
		      {
			sign = fct.sign;
			decl = "unknownFctExtDecl";
			def = Printf.sprintf "%s/%s:%d" file.path file.file fct.line;
		      }
		    in
		    let def_file : string = 
		      (match f.def with
		      | "unknownExtFctDef" -> 
			(
			  Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
			  Printf.printf "add_extcallers.ml::ERROR::incomplete caller file json file:\"%s\"\n" json_filepath;
			  Printf.printf "You need first to complete extcallees definitions by executing the add_extcallees ocaml program\n";
			  Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
			  raise Usage_Error
			)
		      | _ ->
			(
			  let loc : string list = Str.split_delim (Str.regexp ":") f.def in
			  (match loc with
			  | [ file; _ ] ->  file
			  | _ -> raise Unexpected_Case))
			)
		    in
		    self#add_extcaller_to_file extcaller f.sign def_file
		  )
		  extcallees
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
    ~summary:"Parses function's extcallees from callers's generated json files"
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
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread add_extcallers.native" *)
(* End: *)
