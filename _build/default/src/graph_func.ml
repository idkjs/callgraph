(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

exception Unsupported_Function_Dependency_Type

(********************* Begin Function CallGraph *********************)

type function_decl =
  {
    id : string;
    name : string;
    virtuality : string;
    (* file_path : string; *)
    (* line : string; *)
    (* bodyfile : string; *)
    (* bodystart : string; *)
    (* bodyend : string; *)
    (* return_type : string; *)
    (* argsstring : string; *)
    (* params : string list; *)
    (* callers : string list; *)
    (* callees : string list; *)
    file : Graph.Graphviz.DotAttributes.subgraph option
  };;

(* return the path of the bodyfile when present, the path otherwise *)
(* let get_file_path (f:function_decl) : string = *)

(*   if f.bodyfile <> "unknownBodyFile"  *)
(*   then *)
(*     f.bodyfile *)
(*   else *)
(*     f.file_path *)

(* let share_same_file (f1:function_decl) (f2:function_decl) : bool = *)

(*   let f1_path = get_file_path f1 in *)
(*   let f2_path = get_file_path f2 in *)

(*   if f1_path <> f2_path *)
(*   then *)
(*     false *)
(*   else *)
(*     true *)

(* let get_filename (f:function_decl) : string = *)

(*   let fpath : string = get_file_path f in *)
(*   let filename : string = Common.read_after_last '/' 1 fpath in *)
(*   filename *)

(* let get_file_dir (f:function_decl) : string = *)

(*   let fpath : string = get_file_path f in *)
(*   let dpath : string = Common.read_before_last '/' fpath in *)
(*   dpath *)

(* let share_same_dir (f1:function_decl) (f2:function_decl) : bool = *)

(*   let f1_dir = get_file_dir f1 in *)
(*   let f2_dir = get_file_dir f2 in *)

(*   if f1_dir <> f2_dir *)
(*   then *)
(*     false *)
(*   else *)
(*     true *)

(* representation of a node -- must be hashable *)
module Node = struct
  (* type t = int *)
    type t = function_decl
    let compare = Pervasives.compare
    let hash = Hashtbl.hash
    let equal = (=)
  end

(* representation of an edge -- must be comparable *)
module Edge = struct
    type t = string
    let compare = Pervasives.compare
    let equal = (=)
    let default = ""
  end

(* a functional/persistent graph *)
module G = Graph.Persistent.Digraph.ConcreteBidirectionalLabeled(Node)(Edge)
(* module G = Graph.Persistent.Digraph.ConcreteLabeled(Node)(Edge) *)

(* more modules available, e.g. graph traversal with depth-first-search *)
(* module D = Graph.Traverse.Dfs(G) *)

let a_color : int ref = ref 0;;

(* module for creating dot-files *)
module Dot = Graph.Graphviz.Dot(struct
  include G (* use the graph module from above *)
  let edge_attributes (a, e, b) =
    a_color := !a_color + 1000000;
    let style = match e with
      | "cycle" -> `Solid
      | "external" -> `Solid
      | "internal" -> `Dashed
      | "virtual" -> `Dashed
      | "call_external_of_focus" -> `Dashed
      | t ->
	(
	  Printf.printf "graph_func:error: unsupported function dependency type: %s\n" t;
	  raise Unsupported_Function_Dependency_Type
	)
    in
    let color = match e with
      | "cycle" -> 16000000 (* red *)
      | "external" -> 2300 (* blue *)
      | "internal" -> 2300 (* blue *)
      | "virtual" -> 2002300 (* green *)
      | "call_external_of_focus" -> 16480000 (* orange (warning) *)
      | _ -> !a_color
    in
    (* let label = Printf.sprintf "%d" color *)
    let label = ""
    in
    [`Label label; `Color color; `Style style]
  let default_edge_attributes _ = []
  let get_subgraph v = v.file
  (* let vertex_attributes _ = [] *)
  let vertex_attributes v =
    let label = v.name
    in
    let color = match v.virtuality with
      | "no" -> 2300 (* blue *)
      | "declared"
      | "defined" -> 2002300 (* green *)
      | "pure" -> 2002300 (* orange (warning) *)
      | _ -> !a_color
    in
  [`Label label; `Color color]
  let vertex_name v = Printf.sprintf "\"%s\"" v.name
  let default_vertex_attributes _ = []
  let graph_attributes _ = []
end)

(********************* End Function CallGraph *********************)

(* Local Variables: *)
(* mode: tuareg *)
(* End: *)
