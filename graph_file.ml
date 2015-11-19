
exception Graph_File_Unknown_File_Dir
exception Unsupported_File_Dependency_Type

(********************* Begin File Dependency Graph *********************)

type file_decl =
{
  id : string;
  name : string;
  path : string;
  includes : string list;
  mutable uses : string list;  
  sg : Graph.Graphviz.DotAttributes.subgraph;
  (* functions : function_factory list; *)
  nested_dir : Graph_dir.dir_decl option;
  tree_dir : Graph_dir.dir_decl option;
}

let get_nested_dir (f:file_decl) : Graph_dir.dir_decl =

  match f.nested_dir with
  | None -> raise Graph_File_Unknown_File_Dir
  | Some fd -> fd

let get_tree_dir (f:file_decl) : Graph_dir.dir_decl =

  match f.tree_dir with
  | None -> raise Graph_File_Unknown_File_Dir
  | Some fd -> fd

let get_file_dirpath (f:file_decl) : string =

  let dpath : string = Common.read_before_last '/' f.path in
  dpath

let share_same_dir (f1:file_decl) (f2:file_decl) : bool =

  let f1_dir = get_file_dirpath f1 in
  let f2_dir = get_file_dirpath f2 in

  if f1_dir <> f2_dir
  then
    false
  else
    true

(* representation of a node -- must be hashable *)
module Node = struct
  (* type t = int *)
  type t = file_decl
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

(* a fileal/persistent graph *)
module G = Graph.Persistent.Digraph.ConcreteBidirectionalLabeled(Node)(Edge)
(* module F = Graph.Persistent.Digraph.ConcreteBidirectionalLabeled(Node)(Edge) *)

(* inspired from http://anne.pacalet.fr/Notes/doku.php?id=notes:0032_filter_ocamlgraph *)
module Reachability (P: sig val fwd: bool end) = Graph.Fixpoint.Make(G)
(struct
  type vertex = G.E.vertex
  type edge = G.E.t
  type g = G.t
  type data = bool
  let direction =
    if P.fwd then Graph.Fixpoint.Forward else Graph.Fixpoint.Backward
  let equal = (=)
  let join = (||)
  let analyze _ = (fun x -> x)
end)
module ReachabilityForward = Reachability (struct let fwd = true end)
module ReachabilityBackward = Reachability (struct let fwd = false end)

let fwd_root_vertex (v:G.E.vertex) : bool =
  Common.is_same_string v.name "test1.c"

let bwd_root_vertex (v:G.E.vertex) : bool =
  Common.is_same_string v.name "test1.c"

(* let build_subgraph (dot_filename:string) = *)
(*   let module S = Graph.Gmap.Edge (G) (G) (\*F*\) in *)
(*   S.filter_map select g *)

(* (\* more modules available, e.g. graph traversal with depth-first-search *\) *)
(* module D = Graph.Traverse.Dfs(G) *)

(* module for creating dot-files *)
module Dot = Graph.Graphviz.Dot(struct
  include G (* use the graph module from above *)
  let edge_attributes (a, e, b) = 
    let style = match e with
      | "inc_internal" -> `Dashed
      | "inc_external" -> `Solid
      | "inc_external_of_focus" -> `Dashed
      | "inv_external_of_focus" -> `Dashed
      | "inv_internal" -> `Dashed
      | "inv_external" -> `Solid
      | t -> 
	(
	  Printf.printf "graph_func:error: unsupported function dependency type: %s\n" t;
	  raise Unsupported_File_Dependency_Type
	)
    in
    let color = match e with
      | "inc_internal" -> 4711 (* dark blue *)
      | "inc_external" -> 4711 (* dark blue *)
      | "inc_external_of_focus" -> 16480000 (* orange (warning) *)
      | "inv_internal" -> 2300 (* blue *)
      | "inv_external" -> 2300 (* blue *)
      | "inv_external_of_focus" -> 16480000 (* orange (warning) *)
      | t -> 
	(
	  Printf.printf "graph_file:error: unsupported file dependency type: %s\n" t;
	  raise Unsupported_File_Dependency_Type
	)
      (* | _ -> 4711 *)
    in
    [`Label ""; `Color color; `Style style]
  let default_edge_attributes _ = []
  let get_subgraph v = 
    (* match v.dir with *)
    (* | None -> None *)
    (* | Some d -> Some d.sg *)
    Printf.printf "filedepgraph: parent subgraph of v.name=%s in v.path=%s is p.name=%s\n" v.name v.path v.sg.sg_name;
    Some v.sg
  let vertex_attributes v = [`Label v.name; `Shape `Box]
  let vertex_name v = v.id
  let default_vertex_attributes _ = []
  let graph_attributes _ = []
end)

(********************* End File Dependency Graph *********************)

(* Local Variables: *)
(* mode: tuareg *)
(* End: *)
