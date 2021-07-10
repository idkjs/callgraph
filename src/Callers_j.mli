(* Auto-generated from "Callers.atd" *)
[@@@ocaml.warning "-27-32-35-39"]

type dir = Callers_t.dir = {
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

type thread = Callers_t.thread = {
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

type inheritance = Callers_t.inheritance = {
  record: string;
  file: string;
  debut: int;
  fin: int
}

type record = Callers_t.record = {
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

type namespace = Callers_t.namespace = {
  name: string;
  records: string list option;
  calls: string list option;
  called: string list option
}

type file_metrics = Callers_t.file_metrics = {
  nb_lines: int;
  nb_namespaces: int;
  nb_records: int;
  nb_threads: int;
  nb_decls: int;
  nb_defs: int
}

type fct_param = Callers_t.fct_param = { name: string; kind: string }

type extfctdecl = Callers_t.extfctdecl = {
  sign: string;
  mangled: string;
  decl: string
}

type builtin = Callers_t.builtin = { sign: string; decl: string }

type fct_def = Callers_t.fct_def = {
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

type extfctdef = Callers_t.extfctdef = {
  sign: string;
  mangled: string;
  def: string
}

type fct_decl = Callers_t.fct_decl = {
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

type file = Callers_t.file = {
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

type fct = Callers_t.fct = {
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

type extfct = Callers_t.extfct = { sign: string; mangled: string }

type dir_overview = Callers_t.dir_overview = {
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

type dir_metrics = Callers_t.dir_metrics = {
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

val write_dir :
  Bi_outbuf.t -> dir -> unit
  (** Output a JSON value of type {!dir}. *)

val string_of_dir :
  ?len:int -> dir -> string
  (** Serialize a value of type {!dir}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_dir :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> dir
  (** Input JSON data of type {!dir}. *)

val dir_of_string :
  string -> dir
  (** Deserialize JSON data of type {!dir}. *)

val write_thread :
  Bi_outbuf.t -> thread -> unit
  (** Output a JSON value of type {!thread}. *)

val string_of_thread :
  ?len:int -> thread -> string
  (** Serialize a value of type {!thread}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_thread :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> thread
  (** Input JSON data of type {!thread}. *)

val thread_of_string :
  string -> thread
  (** Deserialize JSON data of type {!thread}. *)

val write_inheritance :
  Bi_outbuf.t -> inheritance -> unit
  (** Output a JSON value of type {!inheritance}. *)

val string_of_inheritance :
  ?len:int -> inheritance -> string
  (** Serialize a value of type {!inheritance}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_inheritance :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> inheritance
  (** Input JSON data of type {!inheritance}. *)

val inheritance_of_string :
  string -> inheritance
  (** Deserialize JSON data of type {!inheritance}. *)

val write_record :
  Bi_outbuf.t -> record -> unit
  (** Output a JSON value of type {!record}. *)

val string_of_record :
  ?len:int -> record -> string
  (** Serialize a value of type {!record}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_record :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> record
  (** Input JSON data of type {!record}. *)

val record_of_string :
  string -> record
  (** Deserialize JSON data of type {!record}. *)

val write_namespace :
  Bi_outbuf.t -> namespace -> unit
  (** Output a JSON value of type {!namespace}. *)

val string_of_namespace :
  ?len:int -> namespace -> string
  (** Serialize a value of type {!namespace}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_namespace :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> namespace
  (** Input JSON data of type {!namespace}. *)

val namespace_of_string :
  string -> namespace
  (** Deserialize JSON data of type {!namespace}. *)

val write_file_metrics :
  Bi_outbuf.t -> file_metrics -> unit
  (** Output a JSON value of type {!file_metrics}. *)

val string_of_file_metrics :
  ?len:int -> file_metrics -> string
  (** Serialize a value of type {!file_metrics}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_file_metrics :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> file_metrics
  (** Input JSON data of type {!file_metrics}. *)

val file_metrics_of_string :
  string -> file_metrics
  (** Deserialize JSON data of type {!file_metrics}. *)

val write_fct_param :
  Bi_outbuf.t -> fct_param -> unit
  (** Output a JSON value of type {!fct_param}. *)

val string_of_fct_param :
  ?len:int -> fct_param -> string
  (** Serialize a value of type {!fct_param}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_fct_param :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> fct_param
  (** Input JSON data of type {!fct_param}. *)

val fct_param_of_string :
  string -> fct_param
  (** Deserialize JSON data of type {!fct_param}. *)

val write_extfctdecl :
  Bi_outbuf.t -> extfctdecl -> unit
  (** Output a JSON value of type {!extfctdecl}. *)

val string_of_extfctdecl :
  ?len:int -> extfctdecl -> string
  (** Serialize a value of type {!extfctdecl}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_extfctdecl :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> extfctdecl
  (** Input JSON data of type {!extfctdecl}. *)

val extfctdecl_of_string :
  string -> extfctdecl
  (** Deserialize JSON data of type {!extfctdecl}. *)

val write_builtin :
  Bi_outbuf.t -> builtin -> unit
  (** Output a JSON value of type {!builtin}. *)

val string_of_builtin :
  ?len:int -> builtin -> string
  (** Serialize a value of type {!builtin}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_builtin :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> builtin
  (** Input JSON data of type {!builtin}. *)

val builtin_of_string :
  string -> builtin
  (** Deserialize JSON data of type {!builtin}. *)

val write_fct_def :
  Bi_outbuf.t -> fct_def -> unit
  (** Output a JSON value of type {!fct_def}. *)

val string_of_fct_def :
  ?len:int -> fct_def -> string
  (** Serialize a value of type {!fct_def}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_fct_def :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> fct_def
  (** Input JSON data of type {!fct_def}. *)

val fct_def_of_string :
  string -> fct_def
  (** Deserialize JSON data of type {!fct_def}. *)

val write_extfctdef :
  Bi_outbuf.t -> extfctdef -> unit
  (** Output a JSON value of type {!extfctdef}. *)

val string_of_extfctdef :
  ?len:int -> extfctdef -> string
  (** Serialize a value of type {!extfctdef}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_extfctdef :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> extfctdef
  (** Input JSON data of type {!extfctdef}. *)

val extfctdef_of_string :
  string -> extfctdef
  (** Deserialize JSON data of type {!extfctdef}. *)

val write_fct_decl :
  Bi_outbuf.t -> fct_decl -> unit
  (** Output a JSON value of type {!fct_decl}. *)

val string_of_fct_decl :
  ?len:int -> fct_decl -> string
  (** Serialize a value of type {!fct_decl}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_fct_decl :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> fct_decl
  (** Input JSON data of type {!fct_decl}. *)

val fct_decl_of_string :
  string -> fct_decl
  (** Deserialize JSON data of type {!fct_decl}. *)

val write_file :
  Bi_outbuf.t -> file -> unit
  (** Output a JSON value of type {!file}. *)

val string_of_file :
  ?len:int -> file -> string
  (** Serialize a value of type {!file}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_file :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> file
  (** Input JSON data of type {!file}. *)

val file_of_string :
  string -> file
  (** Deserialize JSON data of type {!file}. *)

val write_fct :
  Bi_outbuf.t -> fct -> unit
  (** Output a JSON value of type {!fct}. *)

val string_of_fct :
  ?len:int -> fct -> string
  (** Serialize a value of type {!fct}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_fct :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> fct
  (** Input JSON data of type {!fct}. *)

val fct_of_string :
  string -> fct
  (** Deserialize JSON data of type {!fct}. *)

val write_extfct :
  Bi_outbuf.t -> extfct -> unit
  (** Output a JSON value of type {!extfct}. *)

val string_of_extfct :
  ?len:int -> extfct -> string
  (** Serialize a value of type {!extfct}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_extfct :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> extfct
  (** Input JSON data of type {!extfct}. *)

val extfct_of_string :
  string -> extfct
  (** Deserialize JSON data of type {!extfct}. *)

val write_dir_overview :
  Bi_outbuf.t -> dir_overview -> unit
  (** Output a JSON value of type {!dir_overview}. *)

val string_of_dir_overview :
  ?len:int -> dir_overview -> string
  (** Serialize a value of type {!dir_overview}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_dir_overview :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> dir_overview
  (** Input JSON data of type {!dir_overview}. *)

val dir_overview_of_string :
  string -> dir_overview
  (** Deserialize JSON data of type {!dir_overview}. *)

val write_dir_metrics :
  Bi_outbuf.t -> dir_metrics -> unit
  (** Output a JSON value of type {!dir_metrics}. *)

val string_of_dir_metrics :
  ?len:int -> dir_metrics -> string
  (** Serialize a value of type {!dir_metrics}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_dir_metrics :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> dir_metrics
  (** Input JSON data of type {!dir_metrics}. *)

val dir_metrics_of_string :
  string -> dir_metrics
  (** Deserialize JSON data of type {!dir_metrics}. *)

