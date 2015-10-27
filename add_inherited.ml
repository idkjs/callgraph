(* Copyright @: Thales Communications & Security *)
(* Author: Hugues Balp *)
(* This file completes json files generated by Callers with "inherited" classes *)

exception Internal_Error
exception Unexpected_Case
exception Usage_Error
exception Missing_File_Path
(* exception TBC *)

module Callers = Map.Make(String);;
module Classes = Map.Make(String);;

class class_parents_json_parser (class_json_filepath:string) = object(self)

  val class_file_path : string = class_json_filepath

  method read_json_file (filename:string) : Yojson.Basic.json =

    Printf.printf "In_channel read file %s...\n" filename;
    (* Read JSON file into an OCaml string *)
    let buf = Core.Std.In_channel.read_all filename in           
    (* Use the string JSON constructor *)
    let json1 = Yojson.Basic.from_string buf in
    json1

  method add_inherited_to_class (inherited:Callgraph_t.inheritance) (record:Callgraph_t.record) : Callgraph_t.record =

    Printf.printf "add the inherited class \"%s\" to the inherited list of class \"%s\"...\n" inherited.record record.name;

    let new_inherited =

      (match record.inherited with	 
       
       | None -> inherited::[]

       | Some inherited_classes -> inherited::inherited_classes
      )
    in

    let updated_record:Callgraph_t.record = 
      {
	name = record.name;
	kind = record.kind;
	loc = record.loc;
	inherited = Some new_inherited;
	inherits = record.inherits;
      }
    in
    updated_record

  method add_inherited_to_file (inherited:Callgraph_t.inheritance) (base_class:string) (class_jsonfilepath:string) : unit = 

    Printf.printf "Try to add inherited \"%s\" to base class \"%s\" defined in file \"%s\"...\n" inherited.record base_class class_jsonfilepath;
    (* Parse the json file of the base class *)
    let dirpath : string = Common.read_before_last '/' class_jsonfilepath in
    let filename : string = Common.read_after_last '/' 1 class_jsonfilepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
    (* Use the atdgen Yojson parser *)
    let json : Yojson.Basic.json = self#read_json_file jsoname_file in
    let content : string = Yojson.Basic.to_string json in
    (* Printf.printf "Read class file \"%s\" content is:\n %s: \n" filename content; *)
    (* Printf.printf "atdgen parsed json file is :\n"; *)
    let file : Callgraph_t.file = Callgraph_j.file_of_string content in
    (* print_endline (Callgraph_j.string_of_file file); *)
    
    (* Look for the base class among all classes defined in the class file *)
    let new_defined_classes : Callgraph_t.record list =

      (match file.records with

       | None -> 	      
	  (
	    (* Abnormal case. At least the base class should normally be defined in the class file. *)
	    Printf.printf "Suspect case. The base class \"%s\" should normally be defined in the class file \"%s\" ! However it might have been ignored by callers analysis of the class file"
			  base_class class_jsonfilepath;
	    []
	    (* raise Usage_Error *)
	  )

       | Some records ->

	  List.map
  	    (
  	      fun (record:Callgraph_t.record) -> 

	      let new_record:Callgraph_t.record = 

              (* Check whether the class is the class one *)
	      if (String.compare record.name base_class == 0) then
		(
		  let cclass = record in

		  (* Check whether the inherited class is already present in the list of inherited classes *)
		  Printf.printf "Check whether the inherited \"%s\" is already present in inherited list of base class \"%s\"\n" 
				inherited.record base_class;
		  
		  (* Parses the list of inherited classes *)
		  let new_class:Callgraph_t.record =

		    (match cclass.inherited with

		     | None -> 
			(
			  (* Add the inherited if not present *)
			  Printf.printf "It is not present, so ";
			  self#add_inherited_to_class inherited record 
			)

		     | Some children ->
			(
			  (* Look for the inherited class "inherited.record" *)
			  Printf.printf "Parse the base classes of class \"%s\" defined in file \"%s\"...\n" cclass.name file.file;
			  try
			    (
			      let inherited = 
				List.find
  				  (
  				    fun (i:Callgraph_t.inheritance) -> 
				    Printf.printf "inherited: record=\"%s\", decl=%s\n" i.record i.decl;
				    String.compare inherited.record i.record == 0
				  )
				  children
			      in
			      Printf.printf "The inherited class \"%s\" is already present in the definition of base class \"%s\", so there is nothing to edit.\n"
					    inherited.record base_class;
			      record
			    )
			  with
			    Not_found -> 
			    (
			      (* Add the inherited if not present *)
			      Printf.printf "It is not present, so ";
			      self#add_inherited_to_class inherited cclass
			    )
			)
		    )
		  in
		  new_class
		)
	      else
		record
	      in
	      new_record
	    )
	    records
      )
    in

    (* WARNING: in cases where the base class is never used locally as a caller one,
        it might not yet been present in the input class json file; therefore we have to add it once
        we know it is called from outside of the file. *)

    (* Check whether the base class is well present in the class file. *)
    try
      (
	let _ (*already_existing_class_record*) = 
	  List.find
	    (
  	      fun (record:Callgraph_t.record) -> String.compare record.name base_class == 0
	    )
	    new_defined_classes
	in

	(* The base class does already exists in the class file. *)

	let new_file : Callgraph_t.file = 
	  {
	    file = file.file;
	    path = file.path;
	    records = Some new_defined_classes;
	    defined = file.defined;
	  }
	in
	self#print_edited_file new_file	jsoname_file
      )
    with
      Not_found -> 
      (
	Printf.printf "The base class \"%s\" is not yet present in file \"%s\" as expected; so we add it to satisfy the inheritance relationship\n"
		      base_class file.file;

	let newly_added_class_record : Callgraph_t.record = 
	  {
	    name = base_class;
	    kind = "class";
	    loc = -1;
	    inherited = Some [ inherited ];
	    inherits = None;
	  }
	in

	(* Now the caller class will be added to the class file. *)
	let new_file : Callgraph_t.file = 
	  {
	    file = file.file;
	    path = file.path;
	    records = Some (newly_added_class_record::new_defined_classes);
	    defined = file.defined;
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

  method parse_current_file (*record_sign:string*) (json_filepath:string) : (* Callgraph_t.record option *) unit =

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
    
    (* Parse the json classes contained in the current file *)
    (match file.records with
     | None -> ()
     | Some records ->

        (* parse inherits of each class *)
	List.iter
  	  (
  	    fun (record:Callgraph_t.record) -> 

	    (* Parses inherited classes *)
	    (match record.inherits with
	     | None -> ()
	     | Some inherits ->
		Printf.printf "Parse inherited classes of class \"%s\" defined in file \"%s\"...\n" record.name file.file;
		List.iter
		  ( 
		    fun (i:Callgraph_t.inheritance) -> 

		    Printf.printf "inherits: record=\"%s\", decl=%s\n" i.record i.decl;
		    let inherited : Callgraph_t.inheritance = 
		      {
			record = record.name;
			decl = 
			  (match file.path with
			  | None -> raise Missing_File_Path
			  | Some path -> Printf.sprintf "%s/%s:%d" path file.file record.loc
			  );
		      }
		    in
		    let def_file : string = 
		      (match i.decl with
		      | "unknownInheritanceDef" -> 
			(
			  Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
			  Printf.printf "add_inherited.ml::ERROR::incomplete caller file json file:\"%s\"\n" json_filepath;
			  Printf.printf "You need first to complete inherits definitions by executing the add_inherits ocaml program\n";
			  Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
			  raise Usage_Error
			)
		      | "unlinkedInherits" ->
			(
			  Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
			  Printf.printf "add_inherited.ml::WARNING::incomplete caller file json file:\"%s\"\n" json_filepath;
			  Printf.printf "The link edition may have failed due to an incomplee defined symbols json file.\n";
			  Printf.printf "The unlinked symbol below is probably part of an external library:\n";
			  Printf.printf "caller symb: %s\n" record.name;
			  Printf.printf "unlinked inherits class: %s\n" i.record;
			  Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
			  "unknownLocation"
			)
		      | _ ->
			(
			  let loc : string list = Str.split_delim (Str.regexp ":") i.decl in
			  (match loc with
			  | [ file; _ ] ->  file
			  | _ -> raise Unexpected_Case))
			)
		    in
		    (
		      match def_file with
		      | "unknownBuiltinClassLocation" 
		      | "unknownLocation" -> ()
		      | _ -> self#add_inherited_to_file inherited i.record def_file
		    ) 
		  )
		  inherits
	    )
	  )
	  records
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
    ~summary:"Parses parent classes from callers's generated classes in json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun file_json () -> 
      
      let parser = new class_parents_json_parser file_json in

      parser#parse_current_file file_json;
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread add_inherited.native" *)
(* End: *)
