(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(* This file defines accessors for Callers data types                         *)
(******************************************************************************)

exception More_Than_One_Definition

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
  		        Some (
		            List.find
  		              (
  			        fun (f:Callers_t.fct_def) -> String.compare fct_sign f.sign == 0
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
	  Printf.printf "parse_defined_fct_in_file:INFO: Ignore not found file \"%s\"" jsoname_file;
	  Printf.printf "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii\n";
	  None
        )
    )
  in
  Printf.printf "extract_fcg.parse_defined_fct_in_file:END fct_sign=%s, file=%s\n" fct_sign json_filepath;
  fct_def

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
     | Some defs -> raise More_Than_One_Definition
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
let search_redeclaration (redecls:Callers_t.extfct list) (redecl_sign:string) : Callers_t.extfct option =

  let searched_redecl =
    try
      (
        Some
          (List.find
             ( fun (redecl:Callers_t.extfct) -> (String.compare redecl.sign redecl_sign == 0))
             redecls
          )
      )
    with
      Not_found -> None
  in
  searched_redecl

(* Return a specific redefinition when present in the input list or nothing otherwise *)
let search_redefinition (redefs:Callers_t.extfct list) (redef_sign:string) : Callers_t.extfct option =

  let searched_redef =
    try
      (
        Some
          (List.find
             ( fun (redef:Callers_t.extfct) -> (String.compare redef.sign redef_sign == 0))
             redefs
          )
      )
    with
      Not_found -> None
  in
  searched_redef

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

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread callers.native" *)
(* End: *)
