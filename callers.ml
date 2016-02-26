(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(* This file defines accessors for Callers data types                         *)
(******************************************************************************)

let print_callers_file (edited_file:Callers_t.file) (json_filepath:string) =

  let json_filepath : string = Common.check_root_dir json_filepath in
  let jfile = Callers_j.string_of_file edited_file in
  Printf.printf "Callers.print_callers_file:DEBUG: tries to write json file %s\n" json_filepath;
  Core.Std.Out_channel.write_all json_filepath jfile

let print_callers_dir (edited_dir:Callers_t.dir) (json_dirpath:string) =

  let json_dirpath : string = Common.check_root_dir json_dirpath in
  let jdir = Callers_j.string_of_dir edited_dir in
  Printf.printf "Callers.print_callers_dir:DEBUG: tries to write json dir %s\n" json_dirpath;
  Core.Std.Out_channel.write_all json_dirpath jdir

let print_callers_dir_symbols (dir_symbols:Callers_t.dir_symbols) (json_dirpath:string) =

  let json_dirpath : string = Common.check_root_dir json_dirpath in
  let jdir = Callers_j.string_of_dir_symbols dir_symbols in
  Printf.printf "Callers.print_callers_dir_symbols:DEBUG: tries to write json dir %s\n" json_dirpath;
  Core.Std.Out_channel.write_all json_dirpath jdir

let parse_declared_fct_in_file (fct_sign:string) (json_filepath:string) : Callers_t.fct_decl option =

  Printf.printf "extract_fcg.parse_declared_fct_in_file:BEGIN fct_sign=%s, file=%s\n" fct_sign json_filepath;

  let dirpath : string = Common.read_before_last '/' json_filepath in
  let filename : string = Common.read_after_last '/' 1 json_filepath in
  let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
  let fct_decl : Callers_t.fct_decl option =
    (
      try
        (
	  let content = Common.read_json_file jsoname_file in
          (match content with
           | None -> None
           | Some content ->
              (
	        (* Printf.printf "Read %s content is:\n %s: \n" filename content; *)
	        (* Printf.printf "atdgen parsed json file is :\n"; *)
	        (* Use the atdgen JSON parser *)
	        let file : Callers_t.file = Callers_j.file_of_string content in
	        (* print_endline (Callers_j.string_of_file file); *)

	        (* Parse the json functions contained in the current file *)
	        (match file.declared with
	         | None -> None
	         | Some fcts ->

	            (* Look for the function "fct_sign" among all the functions declared in file *)
	            try
	              (
  		        Some (
		            List.find
  		              (
  			        fun (f:Callers_t.fct_decl) -> String.compare fct_sign f.sign == 0
		              )
		              fcts )
	              )
	            with
	              Not_found -> None
	        )
              )
          )
        )
      with Common.File_Not_Found ->
        (
	  Printf.printf "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii\n";
	  Printf.printf "parse_declared_fct_in_file:INFO: Ignore not found file \"%s\"" jsoname_file;
	  Printf.printf "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii\n";
	  None
        )
    )
  in
  Printf.printf "extract_fcg.parse_declared_fct_in_file:END fct_sign=%s, file=%s\n" fct_sign json_filepath;
  fct_decl

let parse_defined_fct_in_file (fct_sign:string) (json_filepath:string) : Callers_t.fct_def option =

  Printf.printf "extract_fcg.parse_defined_fct_in_file:BEGIN fct_sign=%s, file=%s\n" fct_sign json_filepath;

  let dirpath : string = Common.read_before_last '/' json_filepath in
  let filename : string = Common.read_after_last '/' 1 json_filepath in
  let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
  let fct_def : Callers_t.fct_def option =
    (
      try
        (
	  let content = Common.read_json_file jsoname_file in
          (match content with
           | None -> None
           | Some content ->
              (
	        (* Printf.printf "Read %s content is:\n %s: \n" filename content; *)
	        (* Printf.printf "atdgen parsed json file is :\n"; *)
	        (* Use the atdgen JSON parser *)
	        let file : Callers_t.file = Callers_j.file_of_string content in
	        (* print_endline (Callers_j.string_of_file file); *)

	        (* Parse the json functions contained in the current file *)
	        (match file.defined with
	         | None -> None
	         | Some fcts ->

	            (* Look for the function "fct_sign" among all the functions defined in file *)
	            try
	              (
                        let fct_decl =
		          List.find
  		            (
  			      fun (f:Callers_t.fct_def) -> String.compare fct_sign f.sign == 0
		            )
		            fcts
                        in
                        Some fct_decl
	              )
	            with
	              Not_found -> None
	        )
              )
          )
        )
      with Common.File_Not_Found ->
        (
	  Printf.printf "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii\n";
	  Printf.printf "parse_defined_fct_in_file:INFO: Ignore not found file \"%s\"" jsoname_file;
	  Printf.printf "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii\n";
	  None
        )
    )
  in
  Printf.printf "extract_fcg.parse_defined_fct_in_file:END fct_sign=%s, file=%s\n" fct_sign json_filepath;
  fct_def

(* Return the path of the file where the input defined function is declared *)
let fct_def_get_file_decl (fct_def_file:string) (fct_def:Callers_t.fct_def) : string option =

  let filepath =
    (match fct_def.decl with
     | None -> None
     | Some decl ->
        (
          let loc : string list = Str.split_delim (Str.regexp ":") decl in
	  let filepath =
	    (match loc with
	     | [ "local"; _ ] ->  Some fct_def_file
	     | [ file; _ ] ->  Some file
	     | _ -> None
	    )
	  in
          filepath
        )
    )
  in
  filepath

(* Return true if the input defined function is declared locally and false otherwise *)
(* exception: Not_Found_Function_Declaration *)
let fct_def_is_declared_locally (fct_def:Callers_t.fct_def) (fct_def_filepath:string) : bool =
  (
    match fct_def_get_file_decl fct_def_filepath fct_def with
    | None -> raise Common.Not_Found_Function_Declaration
    | Some fct_decl_filepath ->
       (** Compare function's declaration and definition file paths **)
       (
         if (String.compare fct_def_filepath fct_decl_filepath == 0) then
           true
         else
           false
       )
  )

(* The link editor uses only one definition per fct_decl, so there should be at most one fct_def
   in the definition list of a fct_decl. However it might append that some function is used
   in frame of different applications and different build.
   In case where the generated json files are reused for the analysis of different applications,
   then the number of definitions could be more than one.
   Hypothesis: we will exclude this case here and consider the json files as being analyzed only in one context.
   Precondition: at most one definition per fct_decl
   Exception: More_Than_One_Definition raised in the case the hypothesis is not true
 *)
let fct_decl_get_used_fct_def (fct_decl:Callers_t.fct_decl)
                              (fct_decl_filepath:string) : (string * Callers_t.fct_def) option =

  Printf.printf "callers.fct_decl_get_used_fct_def:BEGIN fct_decl: sign=%s, file=%s, line=%d\n"
                fct_decl.sign fct_decl_filepath fct_decl.line;

  let used_fct_def : (string * Callers_t.fct_def) option =

    (match fct_decl.definitions with

     | None ->
        (
          Printf.printf "callers.fct_decl_get_used_fct_def:WARNING: no known definition attached to function \"%s\" declared in file \"%s\" at line \"%d\"\n"
                        fct_decl.sign fct_decl_filepath fct_decl.line;
          None
        )

     | Some [fct_def] ->
        (
          let fct_def_file : string list = Str.split_delim (Str.regexp ":") fct_def in
	  let fct_def_file =
	    (match fct_def_file with
	     | [ "local"; _ ] ->  fct_decl_filepath
	     | [ file; _ ] ->  file
	     | _ -> raise Common.Malformed_Reference_Fct_Def
	    )
	  in
          let fct_def = parse_defined_fct_in_file fct_decl.sign fct_def_file in
          let used_fct_def =
            (match fct_def with
             | Some fct_def -> Some(fct_def_file, fct_def)
             | None -> None
            )
          in
          used_fct_def
        )
     | Some defs -> raise Common.More_Than_One_Definition
    )
  in
  (match used_fct_def with
   | Some (fct_def_file, fct_def) ->
      (
        Printf.printf "callers.fct_decl_get_used_fct_def:END:\nthe function \"%s\" declared in file \"%s\" at line \"%d\"\nis defined in file \"%s\" at line \"%d\"\n"
                      fct_decl.sign fct_decl_filepath fct_decl.line fct_def_file fct_def.line
      )
   | None ->
      (
        Printf.printf "callers.fct_decl_get_used_fct_def:END None fct_def returned for function sign=%s file=%s line=%d\n"
                      fct_decl.sign fct_decl_filepath fct_decl.line
      )
  );
  used_fct_def

(* Return a specific redeclaration when present in the input list or nothing otherwise *)
let search_redeclaration (redecls:Callers_t.extfctdecl list) (redecl_sign:string) : Callers_t.extfctdecl option =

  let searched_redecl =
    try
      (
        Some
          (List.find
             ( fun (redecl:Callers_t.extfctdecl) -> (String.compare redecl.sign redecl_sign == 0))
             redecls
          )
      )
    with
      Not_found -> None
  in
  searched_redecl

(* Return a specific redeclared function when present in the input list or nothing otherwise *)
let search_redeclared (redefs:Callers_t.extfctdecl list) (redef_sign:string) : Callers_t.extfctdecl option =

  let searched_redef =
    try
      (
        Some
          (List.find
             ( fun (redef:Callers_t.extfctdecl) -> (String.compare redef.sign redef_sign == 0))
             redefs
          )
      )
    with
      Not_found -> None
  in
  searched_redef

(* Raise an exception if the existing child redeclaration is not the base one *)
let add_base_virtual_decl (child_decl:Callers_t.fct_decl) (base_decl:Callers_t.extfctdecl) : unit =

  Printf.printf "callers.add_base_virtual_decl: child_decl=\"%s\", base_decl=\"%s\"\n" child_decl.sign base_decl.sign;

  (match child_decl.redeclared with
   | None ->
      (
        child_decl.redeclared <- Some base_decl
      )
   | Some child_redecl ->
      Printf.printf "callers.add_base_virtual_decl:WARNING: already existing virtual base declaration \"%s\" in decl \"%s\"\n" base_decl.sign child_decl.sign
  )

let file_get_declared_function (file:Callers_t.file) (fct_sign:string) : Callers_t.fct_decl option =

  Printf.printf "callers.file_get_declared_function:BEGIN fct_sign=%s file=%s\n" fct_sign file.file;

  (match file.declared with

   | None ->
      (
        Printf.printf "WARNING: the function \"%s\" is not declared in file \"%s\"\n" fct_sign file.file;
        None
      )

   | Some fcts ->
      (
        let fct_decl : Callers_t.fct_decl option =
          (try
              Some
                (List.find
                   (
                     fun (fct:Callers_t.fct_decl) ->
                     (
                       (* Check whether the declared function is the searched one *)
                       if (String.compare fct.sign fct_sign == 0) then
                         (
                           Printf.printf "the function \"%s\" is well declared in file \"%s\"\n" fct_sign file.file;
                           true
                         )
                       else
                         false
                     )
                   )
                   fcts
                )
            with
              Not_found ->
              (
                Printf.printf "WARNING: the function \"%s\" is not declared in file \"%s\"\n" fct_sign file.file;
                None
              )
          )
        in
        fct_decl
      )
  )

let file_get_defined_function (file:Callers_t.file) (fct_sign:string) : Callers_t.fct_def option =

  Printf.printf "callers.file_get_defined_function:BEGIN fct_sign=%s file=%s\n" fct_sign file.file;

  (match file.defined with

   | None ->
      (
        Printf.printf "WARNING: the function \"%s\" is not defined in file \"%s\"\n" fct_sign file.file;
        None
      )

   | Some fcts ->
      (
        let fct_def : Callers_t.fct_def option =
          (try
              Some
                (List.find
                   (
                     fun (fct:Callers_t.fct_def) ->
                     (
                       (* Check whether the defined function is the searched one *)
                       if (String.compare fct.sign fct_sign == 0) then
                         (
                           Printf.printf "the function \"%s\" is well defined in file \"%s\"\n" fct_sign file.file;
                           true
                         )
                       else
                         false
                     )
                   )
                   fcts
                )
            with
              Not_found ->
              (
                Printf.printf "WARNING: the function \"%s\" is not defined in file \"%s\"\n" fct_sign file.file;
                None
              )
          )
        in
        fct_def
      )
  )

let fct_virtuality_option_to_string (virtuality:string option) =

  (match virtuality with
  | None -> "no"
  | Some v -> v)

let file_edit_redeclared_fct (fct_sign:string) (redeclared:Callers_t.extfctdecl) (filepath:string) : unit =

  Printf.printf "callers.file_edit_redeclared_fct:BEGIN: child_sign=%s, base_sign=%s, filepath=%s\n" fct_sign redeclared.sign filepath;

  let jsoname_file = Printf.sprintf "%s.file.callers.gen.json" filepath in
  (
    let not_found_fct_decl () =
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "callers.file_edit_redeclared_fct:ERROR: Not_Found_Function_Declaration fct_sign=%s in file=%s\n" fct_sign jsoname_file;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise Common.Not_Found_Function_Declaration
      )
    in
    try
      (
	let content = Common.read_json_file jsoname_file in

          (match content with
           | None -> not_found_fct_decl ()
           | Some content ->
              (
	        let file : Callers_t.file = Callers_j.file_of_string content in
	        (* Get the list of declared functions contained in the current file *)
	        (match file.declared with
	         | None -> not_found_fct_decl ()
	         | Some fcts ->
	            (* Look for the function "fct_sign" among all the functions declared in file *)
	            try
	              (
                        let fct_decl =
		          List.find
  		            (
  			      fun (f:Callers_t.fct_decl) -> String.compare fct_sign f.sign == 0
		            )
		            fcts
                        in
                        Printf.printf "callers.file_edit_redeclared_fct:INFO: add redeclared method \"%s\" to function decl \"%s\" in file=\"%s\"\n" redeclared.sign fct_sign filepath;
                        fct_decl.redeclared <- Some redeclared;
                        (* Update the content of the json file *)
                        print_callers_file file jsoname_file
	              )
	            with
	              Not_found -> not_found_fct_decl ()
	        )
              )
          )
      )
    with Common.File_Not_Found ->
      (
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	Printf.printf "callers.file_edit_redeclared_fct:ERROR: File_Not_Found \"%s\"" jsoname_file;
	Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
	raise Common.File_Not_Found
      )
  );
  Printf.printf "callers.file_edit_redeclared_fct:END: child_sign=%s, base_child=%s, filepath=%s\n" fct_sign redeclared.sign filepath

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread callers.native" *)
(* End: *)
