(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

open Callers_t

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

      let fct10 : Callers_t.fct_decl =
      	{
      	  sign = "void fct10()";
      	  deb = 10;
      	  fin = 123;
          nb_lines = 45;
          params = None;
          nspc = Some "tbc";
          mangled = "_DECL_FCT10";
      	  virtuality = None;
      	  locallers = None;
      	  extcallers = None;
      	  redeclarations = None;
      	  definitions = None;
      	  redeclared = None;
          recordName = None;
          recordPath = None;
          threads = None;
      	}
      in

      let fct11 : Callers_t.fct_def =
	{
	  (* eClass = Config.get_type_fct_decl(); *)
	  sign = "void fct11()";
	  deb = 11;
      	  fin = 123;
          nb_lines = 45;
          params = None;
          nspc = Some "tbc";
	  decl = None;
          mangled = "_DEF_FCT11";
	  virtuality = None;
	  (* locallers = None; *)
	  locallees = Some [ "void fct12()" ];
	  (* extcallers = None; *)
	  extcallees = None;
	  builtins = None;
          recordName = None;
          recordPath = None;
          threads = None;
	}
      in

      let extfct21 : Callers_t.extfctdecl =
	{
	  sign = "void fct21()";
	  (* decl = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1/file2:21"; *)
	  decl = "/opt/uc_sso/src/callgraph/dir1/file2:21";
          mangled = "_DECL_FCT21";
	}
      in

      let extfct22 : Callers_t.extfctdecl =
	{
	  sign = "void fct22()";
	  decl = "/opt/uc_sso/src/callgraph/dir1/file2:22";
          mangled = "_DECL_FCT22";
	}
      in

      let fct12_decl : Callers_t.fct_decl =
	{
	  (* eClass = Config.get_type_fct_def(); *)
	  sign = "void fct12()";
	  deb = 10;
      	  fin = 123;
          nb_lines = 45;
          params = None;
          nspc = Some "tbc";
          mangled = "_DECL_FCT12";
      	  virtuality = None;
	  locallers = Some [ "void fct11()" ];
      	  extcallers = None;
      	  redeclarations = None;
      	  definitions = None;
      	  redeclared = None;
          recordName = None;
          recordPath = None;
          threads = None;
	}
      in

      let fct12_def : Callers_t.fct_def =
	{
	  (* eClass = Config.get_type_fct_def(); *)
	  sign = "void fct12()";
	  deb = 22;
      	  fin = 123;
          nb_lines = 45;
          params = None;
          nspc = Some "tbc";
	  decl = Some "fct12_decl";
          mangled = "_DEF_FCT12";
	  virtuality = None;
	  locallees = None;
	  extcallees = Some [ extfct21; extfct22 ];
	  builtins = None;
          recordName = None;
          recordPath = None;
          threads = None;
	}
      in

      let fct13 : Callers_t.fct_decl =
	{
	  (* eClass = Config.get_type_fct_def(); *)
	  sign = "void fct13()";
	  deb = 13;
      	  fin = 123;
          nb_lines = 45;
          params = None;
          nspc = Some "tbc";
          mangled = "_DECL_FCT13";
	  virtuality = None;
	  locallers = Some [ "void fct13()" ];
	  extcallers = None;
      	  redeclarations = None;
      	  definitions = None;
      	  redeclared = None;
          recordName = None;
          recordPath = None;
          threads = None;
	}
      in

      let base_class0 : Callers_t.inheritance =
	{
          record = "class0";
	  file = "/path/to/class0";
          debut = 12;
          fin = 45;
	}
      in

      let child_class2 : Callers_t.inheritance =
	{
          record = "class2";
	  file = "/path/to/class2";
          debut = 13;
          fin = 46;
	}
      in

      let class1 : Callers_t.record =
	{
          name = "::module1::class1";
	  kind = "class";
	  debut = 13;
          fin = 57;
          nb_lines = 7;
          nspc = "::";
          calls = None;
          called = None;
	  inherits = Some [ base_class0 ];
	  inherited = Some [ child_class2 ];
          methods = Some [ "method1" ];
          members = None;
	}
      in

      let struct1 : Callers_t.record =
	{
          name = "::module1::struct1";
	  kind = "struct";
	  debut = 3;
          fin = 7;
          nb_lines = 9;
          nspc = "::";
	  inherits = None;
	  inherited = None;
          methods = Some [ "fonction2" ];
          members = None;
          calls = None;
          called = None;
	}
      in

      let module1 : Callers_t.namespace =
	{
	  name = "module1";
          records = None;
          calls = None;
          called = None;
	  (* qualifier = "toto::tata::module1"; *)
	  (* namespaces = None; *)
	  (* records = None; *)
	  (* defined = None; *)
	}
      in

      let file1 : Callers_t.file =
	{
	  file = file_1;
          kind = "src";
	  path = Some "/opt/uc_sso/src/callgraph/dir1";
	  namespaces = Some [module1];
	  records = Some [class1; struct1];
          threads = None;
	  declared = Some [ fct10; fct12_decl; fct13 ];
	  defined = Some [fct11; fct12_def];
          nb_lines = 17;
          nb_namespaces = 2;
          nb_records = 1;
          nb_threads = 0;
          nb_decls = 4;
          nb_defs = 5;
	}
      in

      Callers.print_callers_file file1 jsoname_file1;

      let extfct12 : Callers_t.extfctdef =
	{
	  sign = "void fct12()";
	  def = "/opt/uc_sso/src/callgraph/dir1/file1:12";
          mangled = "_DEF_FCT12";
	}
      in

      let fct21 : Callers_t.fct_decl =
	{
	  (* eClass = Config.get_type_fct_def();  *)
	  sign = "void fct21()";
	  deb = 21;
      	  fin = 123;
          nb_lines = 45;
          params = None;
          nspc = Some "tbc";
          mangled = "_DECL_FCT21";
	  virtuality = None;
	  locallers = None;
	  extcallers = Some [ extfct12 ];
      	  redeclarations = None;
      	  definitions = None;
      	  redeclared = None;
          recordName = None;
          recordPath = None;
          threads = None;
	}
      in

      let extfct13 : Callers_t.extfctdecl =
	{
	  sign = "void fct13()";
	  decl = "/opt/uc_sso/src/callgraph/dir1/file1:13";
          mangled = "_DECL_FCT13";
	}
      in

      let fct22 : Callers_t.fct_def =
	{
	  (* eClass = Config.get_type_fct_def();  *)
	  sign = "void fct22()";
	  deb = 22;
      	  fin = 123;
          nb_lines = 45;
          params = None;
          nspc = Some "tbc";
	  decl = Some "fct22_decl";
          mangled = "_DEF_FCT22";
	  virtuality = None;
	  locallees = None;
	  extcallees = Some [ extfct13 ];
	  builtins = None;
          recordName = None;
          recordPath = None;
          threads = None;
	}
      in

      let base_class1 : Callers_t.inheritance =
	{
          record = "class1";
	  file = "/path/to/class1";
          debut = 87;
          fin = 13;
	}
      in

      let class2 : Callers_t.record =
	{
	  (* eClass = Config.get_type_record(); *)
          (* name = "class2"; *)
          name = "::module1::class2";
	  kind = "class";
          debut = 83;
          fin = 14;
	  inherits = Some [ base_class1 ];
	  inherited = None;
          methods = Some [ "method2" ];
          nb_lines = 9;
          nspc = "::";
          members = None;
          calls = None;
          called = None;
	}
      in

      let struct2 : Callers_t.record =
	{
	  (* eClass = Config.get_type_record(); *)
          (* name = "struct2"; *)
          name = "::module1::struct2";
	  kind = "struct";
          debut = 32;
          fin = 90;
	  inherits = None;
	  inherited = None;
          methods = Some [ "fonction3" ];
          nb_lines = 9;
          nspc = "::";
          members = None;
          calls = None;
          called = None;
	}
      in

      let file2 : Callers_t.file =
	{
	  (* eClass = Config.get_type_file(); *)
	  file = file_2;
          kind = "src";
	  (* path = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1"; *)
	  path = Some "/opt/uc_sso/src/callgraph/dir1";
	  namespaces = None;
	  records = Some [class2; struct2];
          threads = None;
	  declared = Some [fct21];
	  defined = Some [fct22];
          nb_lines = 17;
          nb_namespaces = 2;
          nb_records = 1;
          nb_threads = 0;
          nb_decls = 4;
          nb_defs = 5;
	}
      in

      Callers.print_callers_file file2 jsoname_file2;

      if true then
	(
	  let dir1 : Callers_t.dir =
	    {
	      (* eClass = Config.get_type_dir(); *)
	      dir = dir;
	      (* path = "/mnt/users/balp/tests/data/interchange/atd/callgraph/dir1"; *)
	      (* path = "/opt/uc_sso/src/callgraph/dir1"; *)
	      files = Some [ "file1"; "file2" ];
	      childrens = None;
              nb_files = 2;
              nb_header_files = 12;
              nb_source_files = 34;
              nb_lines = 117;
              nb_namespaces = 2;
              nb_records = 1;
              nb_threads = 0;
              nb_decls = 4;
              nb_defs = 5;
	    }
	  in
          Callers.print_callers_dir dir1 jsoname_dir1
	)
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread callers_to_json.native" *)
(* End: *)
