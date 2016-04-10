(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

(*********************************** Unitary Tests **********************************************)

let test_complete_callgraph () =

    (* Add a new file *)
    let new_filename = "another_new_file.json" in
    let new_file : Callgraph_t.file =
      {
        name = new_filename;
        kind = "src";
        id = None;
        includes = None;
        calls = None;
        called = None;
        virtcalls = None;
        (* records = None; *)
        declared = None;
        defined = None;
      }
    in

    let fcg = new function_callgraph in
    fcg#complete_callgraph "/toto/tutu/tata/titi" None;
    fcg#complete_callgraph "/dir_a/dir_b/dir_c/toto/dir_d/dir_e/dir_f" (Some new_file);
    (* fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_b/dir_c" None; *)
    (* fcg#complete_callgraph "/dir_e/dir_r/dir_a/dir_z/dir_h/dir_z" None; *)
    fcg#output_fcg "complete_callgraph.unittest.gen.json";

    (* test get_file *)
    let _ = fcg#get_file "/dir_a/dir_b/dir_c/toto/dir_d/dir_e/dir_f/another_new_file.json" in
    let _ = fcg#get_file "/dir_a/dir_b/dir_c/toto/dir_d/toto.c" in
    ()

(* Check edition of a base dir to add a child subdir *)
let test_add_child () =

    let fcg = new function_callgraph in
    let dir = fcg#create_dir "/dir_a/dir_b" in
    let dir_b = fcg#get_dir "/dir_a/dir_b" in
    Printf.printf "dir_b: %s\n" dir_b.name;
    let dir_k = fcg#init_dir "dir_k" "dir_k_id" in
    dir.children <- Some [ "dir_b"; "dir_k" ];
    fcg#output_top "original.gen.json" (fcg#get_fcg_rootdir)
    (*fcg#output_fcg "my_callgraph.unittest.gen.json"*)

let test_copy_dir () =

    let fcg = new function_callgraph in
    let dir = fcg#create_dir "/dir_e/dir_r/dir_a/dir_b/dir_c" in
    let copie = fcg#copy_dir dir in
    fcg#output_dir "copie.gen.json" copie
    (*fcg#output_fcg "my_callgraph.unittest.gen.json"*)

let test_update_dir () =

    let fcg = new function_callgraph in
    let dir = fcg#init_top "/dir_e/dir_r/dir_a/dir_b/dir_c" in
    fcg#update_fcg_rootdir dir;
    fcg#output_fcg "my_callgraph.unittest.gen.json"

(* Check edition of a base dir to add a leaf child subdir and a file in it *)
let test_add_leaf_child () =

    let fcg = new function_callgraph in
    let dir = fcg#init_top "/dir_a/dir_b/dir_c" in
    (*let cpath = "/dir_a/dir_b/dir_c/dir_d/dir_e/dir_f" in*)
    let cpath = "/other_dir/dir_a/dir_b/dir_c/dir_d/dir_e/dir_f" in

    (*fcg#complete_fcg_dir dir cpath;*)
    fcg#update_fcg_rootdir dir;
    (*let rdir = fcg#get_fcg_rootdir in*)
    (*fcg#complete_fcg_dir rdir cpath;*)

    (* Add a new file *)
    let new_filename = "yet_another_new_file.json" in
    let new_file : Callgraph_t.file =
      {
        name = new_filename;
        kind = "src";
        id = None;
        includes = None;
        calls = None;
        called = None;
        virtcalls = None;
        (* records = None; *)
        declared = None;
        defined = None
      }
    in
    fcg#complete_fcg_file cpath new_file;

    (* Output the complete graph to check whether it has really been completed or not *)
    fcg#output_fcg "my_callgraph.unittest.gen.json"

let test_generate_ref_json () =

    let filename = "test_local_callcycle.c" in
    let file : Callgraph_t.file =
      {
        name = filename;
        kind = "src";
        id = None;
        includes = None;
        calls = None;
        called = None;
        virtcalls = None;
        (* records = None; *)
        declared = None;
        defined = None
      }
    in

    let fcg = new function_callgraph in

    fcg#file_add_include file "stdio.h";

    fcg#complete_callgraph "/root_dir/test_local_callcycle" (Some file);

    let rdir = fcg#get_fcg_rootdir in

    let dir = fcg#get_dir "/root_dir/test_local_callcycle" in
    fcg#dir_add_includes dir "includes";

    let file = fcg#get_file "/root_dir/test_local_callcycle/test_local_callcycle.c" in

    (match file with
     | None -> Common.notify_error Common.Internal_Error
     | Some file ->
       (
         let fct_main : Callgraph_t.fonction_def =
      	   {
      	     sign = "int main()";
             mangled = "_Main";
             virtuality = None;
             localdecl = None;
      	     locallees = Some [{ sign = "void a()"; virtuality="no"; mangled="_a" } ];
             extdecls = None;
      	     extcallees = None;
      	     virtcallees = None;
             nspc = None;
             record = None;
             threads = None;
      	   }
         in

         let printf : Callgraph_t.extfct_ref =
           {
             sign = "int printf()";
             virtuality = "no";
             mangled = "_Printf";
             file = "/path/to/stdio.h";
           }
         in

         let fct_a : Callgraph_t.fonction_def =
	   {
	     sign = "void a()";
             mangled = "_a";
             virtuality = None;
             localdecl = None;
	     locallees = Some [ { sign = "int b()"; virtuality = "no"; mangled = "_b" } ];
             extdecls = None;
	     extcallees = Some [ printf ];
      	     virtcallees = None;
             nspc = None;
             record = None;
             threads = None;
	   }
         in

         let fct_b_decl : Callgraph_t.fonction_decl =
	   {
	     sign = "int b()";
             mangled = "dc_b";
             virtuality = None;
             params = None;
             virtdecls = None;
             localdef = None;
	     locallers = Some [ { sign = "void a()"; virtuality = "no"; mangled = "_a" } ];
             extdefs = None;
	     extcallers = None;
      	     virtcallerdecls = None;
      	     virtcallerdefs = None;
             nspc = None;
             record = None;
             threads = None;
	   }
         in

         let fct_b_def : Callgraph_t.fonction_def =
	   {
	     sign = "int b()";
             mangled = "df_b";
             virtuality = None;
             localdecl = None;
	     locallees = Some [ { sign = "int c()"; virtuality = "no"; mangled = "_c" } ];
             extdecls = None;
	     extcallees = Some [ printf ];
      	     virtcallees = None;
             nspc = None;
             record = None;
             threads = None;
	   }
         in

         let fct_c_decl : Callgraph_t.fonction_decl =
	   {
	     sign = "int c()";
             mangled = "dc_c";
             virtuality = None;
             params = None;
             virtdecls = None;
             localdef = None;
	     locallers = Some [ { sign = "int b()"; virtuality = "no"; mangled = "_b" } ];
             extdefs = None;
	     extcallers = None;
      	     virtcallerdecls = None;
      	     virtcallerdefs = None;
             nspc = None;
             record = None;
             threads = None;
	   }
         in

         let fct_c_def : Callgraph_t.fonction_def =
	   {
	     sign = "int c()";
             mangled = "df_c";
             virtuality = None;
             localdecl = None;
	     locallees = Some [ { sign = "void a()"; virtuality = "no"; mangled = "_a" } ];
             extdecls = None;
	     extcallees = Some [ printf ];
      	     virtcallees = None;
             nspc = None;
             record = None;
             threads = None;
	   }
         in

         fcg#add_fct_defs file [fct_main; fct_a; fct_b_def; fct_c_def];
         fcg#add_fct_decls file [fct_b_decl; fct_c_decl]
       )
    );

    let fct_printf : Callgraph_t.fonction_decl =
      {
        sign = "int printf()";
        mangled = "dc_printf";
        virtuality = None;
        params = None;
        virtdecls = None;
        localdef = None;
        locallers = Some [ { sign = "void a()"; virtuality = "no"; mangled = "_a" };
                           { sign = "int b()"; virtuality = "no"; mangled = "_b" };
                           { sign = "int c()"; virtuality = "no"; mangled = "_c" } ];
        extdefs = None;
        extcallers = None;
        virtcallerdecls = None;
        virtcallerdefs = None;
        nspc = None;
        record = None;
        threads = None;
      }
    in

    let file_stdio : Callgraph_t.file =
      {
        name = "stdio.h";
        kind = "inc";
        id = None;
        includes = None;
        calls = None;
        called = None;
        virtcalls = None;
        (* records = None; *)
        declared = Some [fct_printf];
        defined = None;
      }
    in

    fcg#complete_callgraph "/root_dir/includes" (Some file_stdio);

    fcg#output_fcg "/try.dir.callgraph.gen.json"

(* let () = test_generate_ref_json() *)

(*
   test_complete_callgraph()
   test_add_child();
   test_copy_dir();
   test_update_dir();
   test_add_leaf_child()
 *)

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -package base64 -tag thread unitary_tests.native" *)
(* End: *)
