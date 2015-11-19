
exception Unsupported_Class_Dependency_Type

(********************* Begin Class CallGraph *********************)

type class_decl =
  {
    id : string;
    prot : string;
    name : string;
    file_path : string;
    line : string;
    bodyfile : string;
    bodystart : string;
    bodyend : string;
    (* return_type : string; *)
    (* argsstring : string; *)
    (* params : string list; *)
    (* callers : string list; *)
    (* callees : string list; *)
    file : Graph.Graphviz.DotAttributes.subgraph;
    includes : string list;
    members : string list;
    inherits : ( string * string ) list;
    variables_usedtypes : ( string * string ) list;
    (* mutable uses : string list;   *)
    sg : Graph.Graphviz.DotAttributes.subgraph;
  };;

(* return the path of the file where the class is defined *)
let get_file_path (c:class_decl) : string = c.file_path

let share_same_file (c1:class_decl) (c2:class_decl) : bool =

  let c1_path = get_file_path c1 in
  let c2_path = get_file_path c2 in

  if c1_path <> c2_path
  then
    false
  else
    true

let get_filename (c:class_decl) : string =

  let fpath : string = get_file_path c in
  let filename : string = Common.read_after_last '/' 1 fpath in
  filename

let get_file_dir (c:class_decl) : string =

  let fpath : string = get_file_path c in
  let dpath : string = Common.read_before_last '/' fpath in
  dpath

let share_same_dir (c1:class_decl) (c2:class_decl) : bool =

  let c1_dir = get_file_dir c1 in
  let c2_dir = get_file_dir c2 in

  if c1_dir <> c2_dir
  then
    false
  else
    true

(* representation of a node -- must be hashable *)
module Node = struct
  (* type t = int *)
  type t = class_decl
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
      | "external" -> `Solid
      | "internal" -> `Dashed
      | "inherits_public" -> `Solid
      | "inherits_protected" -> `Solid
      | "inherits_private" -> `Solid
      | "uses" -> `Solid
      | "call_external_of_focus" -> `Dashed
      | t -> 
	(
	  Printf.printf "graph_func:error: unsupported class dependency type: %s\n" t;
	  raise Unsupported_Class_Dependency_Type
	)
    in
    let arrowhead_style = match e with
      (* | "contains" -> `Inv *)
      (* | "contains" -> `Odot *)
      | "uses" -> `Dot
      (* | "contains" -> `None *)
      | _ -> `Normal
    in
    let color = match e with
      (* | "external" -> 16000000 (\* red *\) *)
      | "external" -> 2300 (* blue *)
      | "internal" -> 2300 (* blue *)
      | "uses" -> 371000000 (* black *)
      | "inherits_public" -> 4711 (* dark blue *)
      | "inherits_protected" -> 361000000 (* dark green *)
      | "inherits_private" -> 16000000 (* dark red *)
      | "call_external_of_focus" -> 16480000 (* orange (warning) *)
      | _ -> !a_color
    in
    (* let label = Printf.sprintf "%d" color *)
    let label = ""
    in
    [`Label label; `Color color; `Style style; `Arrowhead arrowhead_style]
  let default_edge_attributes _ = []
  let get_subgraph v = Some v.file
  let vertex_attributes v = 
    let label = v.name
    in
    [`Label label; `Shape `Box]
  let vertex_name v = v.id
  let default_vertex_attributes _ = []
  let graph_attributes _ = []
end)

(********************* End Class CallGraph *********************)

(* Local Variables: *)
(* mode: tuareg *)
(* End: *)
