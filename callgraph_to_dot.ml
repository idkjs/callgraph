(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   KTD SCIS 2014-2015                                                       *)
(*   Use Case Legacy TOSA                                                     *)
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
    ~summary:"Dot backend for callgraph's json files"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun () -> 
      
      let jsoname_file : String.t = "test.dir.callgraph.gen.json" in

      try
	(
	  Printf.printf "In_channel read file %s...\n" jsoname_file;
	  (* Read JSON file into an OCaml string *)
	  let content = Core.Std.In_channel.read_all jsoname_file in
	  (* Use the string JSON constructor *)
	  (* let json = Yojson.Basic.from_string content in *)
	  (* Read the input callgraph's json file *)
	  let dir_root : Callgraph_t.dir = Callgraph_j.dir_of_string content in
	  (* TBC *)
	  ()
	)
      with
      | Sys_error msg -> 
	 (
	   Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE";
	   Printf.printf "callgraph_to_dot.ml:ERROR: Ignore not found file \"%s\"" jsoname_file;
	   Printf.printf "Sys_error msg: %s\n" msg;
	   Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
	 )
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread callgraph_to_dot.native" *)
(* End: *)
