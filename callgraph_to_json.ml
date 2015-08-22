
(* tangled from ~/org/technology/data/data.org *)

(*open Core.Std*)
open Callgraph_t

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("dir" %: string)
  +> anon ("file1" %: string)
  +> anon ("file2" %: string)

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Writes a test json file with one directory containing two files, each one defining two functions"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun dir file_1 file_2 () -> 

      let jsoname_dir1 : String.t = String.concat "" [ dir; ".dir.callers.gen.json" ] in
      let jsoname_file1 : String.t = String.concat "" [ file_1; ".file.callers.gen.json" ] in
      let jsoname_file2 : String.t = String.concat "" [ file_2; ".file.callers.gen.json" ] in
      
      let fct11 : Callgraph_t.fct = 
	{ 
	  sign = "void fct11()";
	  line = 11;
	  locallers = None;
	  locallees = Some [ "void fct12()" ];
	  extcallers = None;
	  extcallees = None
	} 
      in

      let extfct21 : Callgraph_t.extfct = 
	{
	  sign = "void fct21()";
	  (* file = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1/file2";	   *)
	  file = "/opt/uc_sso/src/callgraph/dir1/file2";	  
	}
      in

      let extfct22 : Callgraph_t.extfct = 
	{
	  sign = "void fct22()";
	  (* file = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1/file2";	   *)
	  file = "/opt/uc_sso/src/callgraph/dir1/file2";	  
	}
      in
	
      let fct12 = 
	{ 
	  sign = "void fct12()";
	  line = 12;
	  locallers = Some [ "void fct11()" ];
	  locallees = None;
	  extcallers = None;
	  extcallees = Some [ extfct21; extfct22 ];
	}
      in

      let fct13 : Callgraph_t.fct = 
	{ 
	  sign = "void fct13()";
	  line = 13;
	  locallers = Some [ "void fct13()" ];
	  locallees = None;
	  extcallers = None;
	  extcallees = None;
	} 
      in
      
      let file1 = 
	{
	  file = file_1;
	  (* path = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1"; *)
	  path = "/opt/uc_sso/src/callgraph/dir1";
	  defined = Some [fct11; fct12; fct13]
	} 
      in
      
      let jfile1 = Callgraph_j.string_of_file file1 in
      print_endline jfile1;
      (* Write the file1 serialized by atdgen to a JSON file *)
      Core.Std.Out_channel.write_all jsoname_file1 jfile1;

      let extfct12 : Callgraph_t.extfct = 
	{
	  sign = "void fct12()";
	  (* file = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1/file1";	   *)
	  file = "/opt/uc_sso/src/callgraph/dir1/file1";	  
	}
      in

      let fct21 = 
	{ 
	  sign = "void fct21()";
	  line = 21;
	  locallers = None;
	  locallees = None;
	  (* extcallers = Some [ extfct12 ]; *)
	  extcallers = None;
	  extcallees = None;
	} 
      in

      let extfct13 : Callgraph_t.extfct = 
	{
	  sign = "void fct13()";
	  (* file = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1/file1"; *)
	  file = "/opt/uc_sso/src/callgraph/dir1/file1";
	}
      in

      let fct22 = 
	{ 
	  sign = "void fct22()";
	  line = 22;
	  locallers = None;
	  locallees = None;
	  (* extcallers = Some [ extfct12 ]; *)
	  extcallers = None;
	  extcallees = Some [ extfct13 ];
	} 
      in
      
      let file2 = 
	{
	  file = file_2; 
	  (* path = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1"; *)
	  path = "/opt/uc_sso/src/callgraph/dir1";
	  defined = Some [fct21; fct22]
	} 
      in
      
      let jfile2 = Callgraph_j.string_of_file file2 in
      print_endline jfile2;
      (* Write the file2 serialized by atdgen to a JSON file *)
      Core.Std.Out_channel.write_all jsoname_file2 jfile2;

      (* Generation of the dir json file has been deactivated. *)
      (* It is not usefull for the moment. *)
      if false then
	(
	  let dir1 : Callgraph_t.dir = 
	    {
	      dir = dir; 
	      (* path = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1"; *)
	      path = "/opt/uc_sso/src/callgraph/dir1";
	      files = Some [ "file1"; "file2" ];
	      childrens = None
	    } 
	  in

	  (* Serialize the directory dir1 with atdgen. *)
	  let jdir1 = Callgraph_j.string_of_dir dir1 in
	  print_endline jdir1;

	  (* Write the directory dir1 serialized by atdgen to a JSON file *)
	  Core.Std.Out_channel.write_all jsoname_dir1 jdir1
	)
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread callgraph_to_json.native" *)
(* End: *)
