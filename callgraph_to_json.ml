
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
	  virtuality = None;
	  locallers = None;
	  locallees = Some [ "void fct12()" ];
	  extcallers = None;
	  extcallees = None;
	  builtins = None;
	}
      in

      let extfct21 : Callgraph_t.extfct = 
	{
	  sign = "void fct21()";
	  (* decl = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1/file2:21"; *)
	  decl = "/opt/uc_sso/src/callgraph/dir1/file2:21";
	  def = "unknownExtFctDef"
	}
      in

      let extfct22 : Callgraph_t.extfct = 
	{
	  sign = "void fct22()";
	  (* decl = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1/file2:22"; *)
	  decl = "/opt/uc_sso/src/callgraph/dir1/file2:22";
	  def = "unknownExtFctDef"
	}
      in
	
      let fct12 = 
	{ 
	  sign = "void fct12()";
	  line = 12;
	  virtuality = None;
	  locallers = Some [ "void fct11()" ];
	  locallees = None;
	  extcallers = None;
	  extcallees = Some [ extfct21; extfct22 ];
	  builtins = None;
	}
      in

      let fct13 : Callgraph_t.fct = 
	{ 
	  sign = "void fct13()";
	  line = 13;
	  virtuality = None;
	  locallers = Some [ "void fct13()" ];
	  locallees = None;
	  extcallers = None;
	  extcallees = None;
	  builtins = None;
	}
      in

      let class1 : Callgraph_t.record = 
	{ 
          name = "class1";
	  kind = "class";
	  deb = 13;
	  fin = 45;
	}
      in

      let struct1 : Callgraph_t.record = 
	{ 
          name = "struct1";
	  kind = "struct";
	  deb = 20;
	  fin = 35;
	}
      in
      
      let file1 : Callgraph_t.file = 
	{
	  file = file_1;
	  (* path = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1"; *)
	  path = Some "/opt/uc_sso/src/callgraph/dir1";
	  records = Some [class1; struct1];
	  defined = Some [fct11; fct12; fct13];
	}
      in
      
      let jfile1 = Callgraph_j.string_of_file file1 in
      (* print_endline jfile1; *)
      (* Write the file1 serialized by atdgen to a JSON file *)
      Core.Std.Out_channel.write_all jsoname_file1 jfile1;

      let extfct12 : Callgraph_t.extfct = 
	{
	  sign = "void fct12()";
	  (* decl = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1/file1:12"; *)
	  decl = "/opt/uc_sso/src/callgraph/dir1/file1:12";
	  def = "unknownExtFctDef"
	}
      in

      let fct21 = 
	{ 
	  sign = "void fct21()";
	  line = 21;
	  virtuality = None;
	  locallers = None;
	  locallees = None;
	  (* extcallers = Some [ extfct12 ]; *)
	  extcallers = None;
	  extcallees = None;
	  builtins = None;
	} 
      in

      let extfct13 : Callgraph_t.extfct = 
	{
	  sign = "void fct13()";
	  (* decl = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1/file1:13"; *)
	  decl = "/opt/uc_sso/src/callgraph/dir1/file1:13";
	  def = "unknownExtFctDef"
	}
      in

      let fct22 = 
	{ 
	  sign = "void fct22()";
	  line = 22;
	  virtuality = None;
	  locallers = None;
	  locallees = None;
	  (* extcallers = Some [ extfct12 ]; *)
	  extcallers = None;
	  extcallees = Some [ extfct13 ];
	  builtins = None;
	} 
      in

      let class2 : Callgraph_t.record = 
	{ 
          name = "class2";
	  kind = "class";
	  deb = 14;
	  fin = 47;
	}
      in

      let struct2 : Callgraph_t.record = 
	{ 
          name = "struct2";
	  kind = "struct";
	  deb = 21;
	  fin = 36;
	}
      in
      
      let file2 = 
	{
	  file = file_2; 
	  (* path = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1"; *)
	  path = Some "/opt/uc_sso/src/callgraph/dir1";
	  records = Some [class2; struct2];
	  defined = Some [fct21; fct22]
	} 
      in
      
      let jfile2 = Callgraph_j.string_of_file file2 in
      (* print_endline jfile2; *)
      (* Write the file2 serialized by atdgen to a JSON file *)
      Core.Std.Out_channel.write_all jsoname_file2 jfile2;

      if true then
	(
	  let dir1 : Callgraph_t.dir = 
	    {
	      dir = dir; 
	      (* path = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1"; *)
	      (* path = "/opt/uc_sso/src/callgraph/dir1"; *)
	      files = Some [ "file1"; "file2" ];
	      childrens = None
	    } 
	  in

	  (* Serialize the directory dir1 with atdgen. *)
	  let jdir1 = Callgraph_j.string_of_dir dir1 in
	  (* print_endline jdir1; *)

	  (* Write the directory dir1 serialized by atdgen to a JSON file *)
	  Core.Std.Out_channel.write_all jsoname_dir1 jdir1;
	);

      (* Generation of the all json file has been deactivated. *)
      (* It is not more usefull now. *)
      (* if false then *)
      (* (\* if true then *\) *)
      (* 	( *)
      (* 	  let all_symb2 = Core.Std.Out_channel.create "all_symbols2.gen.json" in *)

      (* 	  Core.Std.Out_channel.output_string all_symb2 "{\"application\":\"myAppli\",\"path\":\"myRootPath\",\"dir_symbols\":["; *)

      (* 	  (\* Example generation of dir1_symbols *\) *)
      (* 	  let dir1_symbols : Callgraph_t.dir_symbols = *)
      (* 	    { *)
      (* 	      directory = "myDir1"; *)
      (* 	      depth = 2; *)
      (* 	      path = "myPath1"; *)
      (* 	      file_symbols = []; *)
      (* 	      subdirs = None; *)
      (* 	    } *)
      (* 	  in *)
      (* 	  (\* Serialize the ATD type dir1_symbols *\) *)
      (* 	  let jdir1_symbols = Callgraph_j.string_of_dir_symbols dir1_symbols in *)
      (* 	  Core.Std.Out_channel.output_string all_symb2 jdir1_symbols; *)

      (* 	  let dir2_symbols : Callgraph_t.dir_symbols = *)
      (* 	    { *)
      (* 	      directory = "myDir2"; *)
      (* 	      depth = 1; *)
      (* 	      path = "myPath2"; *)
      (* 	      file_symbols = []; *)
      (* 	      subdirs = None; *)
      (* 	    } *)
      (* 	  in *)
      (* 	  (\* Serialize the ATD type dir2_symbols *\) *)
      (* 	  let jdir2_symbols = Callgraph_j.string_of_dir_symbols dir2_symbols in *)

      (* 	  Core.Std.Out_channel.output_char all_symb2 ','; *)
      (* 	  Core.Std.Out_channel.output_string all_symb2 jdir2_symbols; *)

      (* 	  (\* Example generation of all_symbols *\) *)
      (* 	  let all_symbols : Callgraph_t.all_symbols = *)
      (* 	    { *)
      (* 	      application = Some "myAppli"; *)
      (* 	      dir = "myDir"; *)
      (* 	      path = "myRootPath"; *)
      (* 	      dir_symbols = [ dir1_symbols; dir2_symbols ]; *)
      (* 	    } *)
      (* 	  in *)

      (* 	  Core.Std.Out_channel.output_string all_symb2 "]}"; *)
      (* 	  (\* Core.Std.Out_channel.close all_symb2; *\) *)

      (* 	  (\* Serialize the ATD type all_symbols *\) *)
      (* 	  let jall_symbols = Callgraph_j.string_of_all_symbols all_symbols in *)
      (* 	  Core.Std.Out_channel.write_all "all_symbols1.gen.json" jall_symbols *)
      (* 	) *)
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread callgraph_to_json.native" *)
(* End: *)
