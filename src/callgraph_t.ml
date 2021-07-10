(* Auto-generated from "callgraph.atd" *)
              [@@@ocaml.warning "-27-32-35-39"]

type thread = {
  inst_name: string;
  routine_file: string;
  routine_name: string;
  routine_sign: string;
  routine_mangled: string;
  caller_sign: string;
  caller_mangled: string;
  create_location: string;
  id: string
}

type inheritance = { record: string; decl: string }

type record = {
  fullname: string;
  kind: string;
  id: string option;
  mutable includes: string list option;
  mutable calls: string list option;
  mutable called: string list option;
  mutable virtcalls: string list option;
  decl: string;
  nspc: string;
  mutable parents: inheritance list option;
  mutable children: inheritance list option;
  mutable meth_decls: string list option;
  mutable meth_defs: string list option
}

type namespace = {
  name: string;
  mutable records: record list option;
  mutable calls: string list option;
  mutable called: string list option
}

type fct_ref = { sign: string; virtuality: string; mangled: string }

type extfct_ref = {
  sign: string;
  virtuality: string;
  mangled: string;
  file: string
}

type fonction_def = {
  sign: string;
  mangled: string;
  virtuality: string option;
  nspc: string option;
  record: string option;
  threads: string list option;
  mutable localdecl: fct_ref option;
  mutable locallees: fct_ref list option;
  mutable extdecls: extfct_ref list option;
  mutable extcallees: extfct_ref list option;
  mutable virtcallees: extfct_ref list option
}

type fct_param = { name: string; kind: string }

type fonction_decl = {
  sign: string;
  mangled: string;
  virtuality: string option;
  nspc: string option;
  record: string option;
  threads: string list option;
  mutable isdef: bool;
  mutable params: fct_param list option;
  mutable localdef: fct_ref option;
  mutable virtdecls: fct_ref list option;
  mutable locallers: fct_ref list option;
  mutable extdefs: extfct_ref list option;
  mutable extcallers: extfct_ref list option;
  mutable virtcallerdecls: extfct_ref list option;
  mutable virtcallerdefs: extfct_ref list option
}

type file = {
  name: string;
  kind: string;
  id: string option;
  mutable includes: string list option;
  mutable calls: string list option;
  mutable called: string list option;
  mutable virtcalls: string list option;
  mutable declared: fonction_decl list option;
  mutable defined: fonction_def list option
}

type dir = {
  name: string;
  path: string;
  id: string option;
  mutable includes: string list option;
  mutable calls: string list option;
  mutable called: string list option;
  mutable virtcalls: string list option;
  mutable children: string list option;
  mutable parents: string list option;
  mutable files: file list option
}

type top = {
  path: string;
  id: string option;
  mutable namespaces: namespace list option;
  mutable physical_view: dir list option;
  mutable runtime_view: thread list option
}

type fonction = {
  sign: string;
  mangled: string;
  virtuality: string option;
  nspc: string option;
  record: string option;
  threads: string list option
}

type element = { id: string option }

type depends = {
  id: string option;
  mutable includes: string list option;
  mutable calls: string list option;
  mutable called: string list option;
  mutable virtcalls: string list option
}
