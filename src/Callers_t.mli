(* Auto-generated from "Callers.atd" *)
              [@@@ocaml.warning "-27-32-35-39"]

type dir = {
  dir: string;
  nb_files: int;
  nb_header_files: int;
  nb_source_files: int;
  nb_lines: int;
  nb_namespaces: int;
  nb_records: int;
  nb_threads: int;
  nb_decls: int;
  nb_defs: int;
  files: string list option;
  childrens: dir list option
}

type thread = {
  inst: string;
  routine_name: string;
  routine_sign: string;
  routine_mangled: string;
  routine_virtuality: string;
  routine_file: string;
  routine_line: int;
  routine_record: string;
  caller_sign: string;
  caller_mangled: string;
  id: string;
  loc: string
}

type inheritance = { record: string; file: string; debut: int; fin: int }

type record = {
  name: string;
  kind: string;
  nb_lines: int;
  debut: int;
  fin: int;
  nspc: string;
  inherits: inheritance list option;
  inherited: inheritance list option;
  methods: string list option;
  members: (string * string) list option;
  calls: string list option;
  called: string list option
}

type namespace = {
  name: string;
  records: string list option;
  calls: string list option;
  called: string list option
}

type file_metrics = {
  nb_lines: int;
  nb_namespaces: int;
  nb_records: int;
  nb_threads: int;
  nb_decls: int;
  nb_defs: int
}

type fct_param = { name: string; kind: string }

type extfctdecl = { sign: string; mangled: string; decl: string }

type builtin = { sign: string; decl: string }

type fct_def = {
  sign: string;
  nb_lines: int;
  deb: int;
  fin: int;
  mangled: string;
  virtuality: string option;
  params: fct_param list option;
  nspc: string option;
  recordName: string option;
  recordPath: string option;
  threads: string list option;
  decl: string option;
  locallees: string list option;
  extcallees: extfctdecl list option;
  builtins: builtin list option
}

type extfctdef = { sign: string; mangled: string; def: string }

type fct_decl = {
  sign: string;
  nb_lines: int;
  deb: int;
  fin: int;
  mangled: string;
  virtuality: string option;
  params: fct_param list option;
  nspc: string option;
  recordName: string option;
  recordPath: string option;
  threads: string list option;
  mutable redeclared: extfctdecl list option;
  redeclarations: extfctdecl list option;
  definitions: string list option;
  locallers: string list option;
  extcallers: extfctdef list option
}

type file = {
  file: string;
  kind: string;
  nb_lines: int;
  nb_namespaces: int;
  nb_records: int;
  nb_threads: int;
  nb_decls: int;
  nb_defs: int;
  path: string option;
  namespaces: namespace list option;
  records: record list option;
  threads: thread list option;
  declared: fct_decl list option;
  defined: fct_def list option
}

type fct = {
  sign: string;
  nb_lines: int;
  deb: int;
  fin: int;
  mangled: string;
  virtuality: string option;
  params: fct_param list option;
  nspc: string option;
  recordName: string option;
  recordPath: string option;
  threads: string list option
}

type extfct = { sign: string; mangled: string }

type dir_overview = {
  directory: string;
  path: string;
  depth: int;
  nb_files: int;
  nb_header_files: int;
  nb_source_files: int;
  nb_lines: int;
  nb_namespaces: int;
  nb_records: int;
  nb_threads: int;
  nb_decls: int;
  nb_defs: int;
  subdirs: string list option;
  files: file list
}

type dir_metrics = {
  nb_files: int;
  nb_header_files: int;
  nb_source_files: int;
  nb_lines: int;
  nb_namespaces: int;
  nb_records: int;
  nb_threads: int;
  nb_decls: int;
  nb_defs: int
}
