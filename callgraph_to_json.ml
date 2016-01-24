(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)
(* forked from callers_to_json.org *)

open Callgraph_t

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Writes a test json file with one directory containing two files, each one defining some functions"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun () ->

      let jsoname_dir : String.t = "test.dir.callgraph.gen.json" in

      let fct_main_def : Callgraph_t.fonction_def =
      	{
	  (* eClass = Config.callgraph_get_type_fonction(); *)
      	  sign = "int main()";
          mangled = "tbc";
      	  virtuality = None;
          localdecl = None;
          extdecl = None;
      	  locallees = Some [ { sign = "void a()"; virtuality = "no"; mangled = "tbc" } ];
      	  extcallees = None;
      	  virtcallees = None;
      	}
      in

       let printf : Callgraph_t.extfct_ref =
         {
           sign = "int printf()";
           mangled = "tbc";
           virtuality = "no";
           file = "/path/to/stdio.h";
         }
       in

      let fct_a : Callgraph_t.fonction_def =
	{
	  (* eClass = Config.callgraph_get_type_fonction(); *)
	  sign = "void a()";
          mangled = "tbc";
	  (* line = 11; *)
	  (* decl = None; *)
	  virtuality = None;
          localdecl = None;
          extdecl = None;
	  locallees = Some [ { sign = "int b()"; virtuality = "no"; mangled = "tbc" } ];
	  extcallees = Some [ printf ];
      	  virtcallees = None;
	  (* builtins = None; *)
	}
      in

      let fct_b_decl : Callgraph_t.fonction_decl =
	{
	  sign = "int b()";
          mangled = "tbc";
          localdef = None;
	  virtuality = None;
          virtdecls = None;
          extdefs = None;
	  locallers = Some [ { sign = "void a()"; virtuality = "no"; mangled = "tbc" } ];
	  extcallers = None;
      	  virtcallers = None;
	}
      in

      let fct_b_def : Callgraph_t.fonction_def =
	{
	  sign = "int b()";
          mangled = "tbc";
	  virtuality = None;
          localdecl = None;
          extdecl = None;
	  locallees = Some [ { sign = "int c()"; virtuality = "no"; mangled = "tbc" } ];
	  extcallees = Some [ printf ];
      	  virtcallees = None;
	}
      in

      let fct_c_decl : Callgraph_t.fonction_decl =
	{
	  sign = "int c()";
          mangled = "tbc";
	  virtuality = None;
          virtdecls = None;
          extdefs = None;
          localdef = None;
	  locallers = Some [ { sign = "int b()"; virtuality = "no"; mangled = "tbc" } ];
	  extcallers = None;
      	  virtcallers = None;
	}
      in

      let fct_c_def : Callgraph_t.fonction_def =
	{
	  sign = "int c()";
          mangled = "tbc";
	  virtuality = None;
          localdecl = None;
          extdecl = None;
	  locallees = Some [ { sign = "void a()"; virtuality = "no"; mangled = "tbc" } ];
	  extcallees = Some [ printf ];
      	  virtcallees = None;
	  (* builtins = None; *)
	}
      in

      (* let base_class0 : Callgraph_t.inheritance =  *)
      (* 	{  *)
      (*     record = "class0"; *)
      (* 	  decl = "/path/to/class0:pos"; *)
      (* 	} *)
      (* in *)

      (* let child_class2 : Callgraph_t.inheritance =  *)
      (* 	{  *)
      (*     record = "class2"; *)
      (* 	  decl = "/path/to/class2:pos"; *)
      (* 	} *)
      (* in *)

      (* let class1 : Callgraph_t.record =  *)
      (* 	{ *)
      (* 	  (\* eClass = Config.callgraph_get_type_record();  *\) *)
      (*     (\* name = "class1"; *\) *)
      (*     fullname = "::module1::class1"; *)
      (* 	  kind = "class"; *)
      (* 	  loc = 13; *)
      (* 	  inherits = Some [ base_class0 ]; *)
      (* 	  inherited = Some [ child_class2 ]; *)
      (* 	} *)
      (* in *)

      (* let struct1 : Callgraph_t.record =  *)
      (* 	{  *)
      (* 	  (\*eClass = Config.callgraph_get_type_record(); *\) *)
      (*     (\* name = "struct1"; *\) *)
      (*     fullname = "::module1::struct1"; *)
      (* 	  kind = "struct"; *)
      (* 	  loc = 20; *)
      (* 	  inherits = None; *)
      (* 	  inherited = None; *)
      (* 	} *)
      (* in *)

      (* let module1 : Callgraph_t.namespace =  *)
      (* 	{ *)
      (* 	  name = "module1"; *)
      (* 	  qualifier = "toto::tata::module1"; *)
      (* 	  (\* namespaces = None; *\) *)
      (* 	  (\* records = None; *\) *)
      (* 	  (\* defined = None; *\) *)
      (* 	} *)
      (* in *)

      let file_test : Callgraph_t.file =
	{
	  (* eClass = Config.callgraph_get_type_file(); *)
	  name = "test_local_callcycle.c";
          id = None;
	  includes = Some ["stdio.h"];
	  calls = Some ["stdio.h"];
	  (* path = Some "/opt/uc_sso/src/callgraph/dir_root"; *)
	  (* namespaces = Some [module1]; *)
	  (* records = Some [class1; struct1]; *)
	  declared = Some [fct_b_decl; fct_c_decl];
	  defined = Some [fct_main_def; fct_a; fct_b_def; fct_c_def];
          records = None;
	}
      in

      let fct_printf : Callgraph_t.fonction_decl =
	{
	  (* eClass = Config.callgraph_get_type_fonction(); *)
	  sign = "int printf()";
          mangled = "tbc";
	  (* line = 13; *)
	  (* decl = None; *)
	  virtuality = None;
          localdef = None;
          virtdecls = None;
          extdefs = None;
	  locallers =
            Some [
                { sign = "void a()"; virtuality = "no"; mangled = "tbc" };
                { sign = "int b()"; virtuality = "no"; mangled = "tbc" };
                { sign = "int c()"; virtuality = "no"; mangled = "tbc" }
              ];
	  extcallers = None;
      	  virtcallers = None;
	  (* builtins = None; *)
	}
      in

      let file_stdio : Callgraph_t.file =
	{
	  name = "stdio.h";
          id = None;
	  includes = None;
          calls = None;
	  (* path = Some "/path/to/file_stdio"; *)
	  (* namespaces = Some [module1]; *)
	  (* records = Some [class1; struct1]; *)
	  declared = Some [fct_printf];
	  defined = None;
          records = None;
	}
      in

      let dir_test : Callgraph_t.dir =
	{
	  name = "test_local_callcycle";
          id = None;
	  calls = Some ["includes"];
	  includes = Some ["includes"];
	  path = "/path/to/dir_test";
          parents = None;
	  children = None;
	  files = Some [ file_test ]
	}
      in

      let dir_includes : Callgraph_t.dir =
	{
	  name = "includes";
          id = None;
	  calls = None;
          includes = None;
	  path = "/path/to/dir_stdio";
          parents = None;
	  children = None;
	  files = Some [ file_stdio ]
	}
      in

      let dir_root : Callgraph_t.dir =
	{
	  name = "root_dir";
          id = None;
	  calls = None;
	  includes = None;
	  path = "/path/to/dir_root";
          parents = None;
	  children = Some [ "dir_test"; "dir_includes" ];
	  files = None;
	}
      in

      if true then
	(
          Common.print_callgraph_dir dir_root jsoname_dir
	);
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread callgraph_to_json.native" *)
(* End: *)
