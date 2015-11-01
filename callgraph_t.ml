(* Auto-generated from "callgraph.atd" *)


type dir = {
  dir: string;
  files: string list option;
  childrens: dir list option
}

type inheritance = { record: string; decl: string }

type record = {
  fullname: string;
  kind: string;
  loc: int;
  inherits: inheritance list option;
  inherited: inheritance list option
}

type namespace = { name: string; qualifier: string }

type extfct = { sign: string; decl: string; def: string }

type builtin = { sign: string; decl: string }

type fct_def = {
  sign: string;
  line: int;
  virtuality: string option;
  locallers: string list option;
  locallees: string list option;
  extcallers: extfct list option;
  extcallees: extfct list option;
  builtins: builtin list option
}

type file = {
  file: string;
  path: string option;
  namespaces: namespace list option;
  records: record list option;
  defined: fct_def list option
}

type dir_symbols = {
  directory: string;
  path: string;
  depth: int;
  file_symbols: file list;
  subdirs: string list option
}
