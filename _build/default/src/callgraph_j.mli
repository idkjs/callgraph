(* Auto-generated from "callgraph.atd" *)
[@@@ocaml.warning "-27-32-35-39"]

type thread = Callgraph_t.thread = {
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

type inheritance = Callgraph_t.inheritance = { record: string; decl: string }

type record = Callgraph_t.record = {
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

type namespace = Callgraph_t.namespace = {
  name: string;
  mutable records: record list option;
  mutable calls: string list option;
  mutable called: string list option
}

type fct_ref = Callgraph_t.fct_ref = {
  sign: string;
  virtuality: string;
  mangled: string
}

type extfct_ref = Callgraph_t.extfct_ref = {
  sign: string;
  virtuality: string;
  mangled: string;
  file: string
}

type fonction_def = Callgraph_t.fonction_def = {
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

type fct_param = Callgraph_t.fct_param = { name: string; kind: string }

type fonction_decl = Callgraph_t.fonction_decl = {
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

type file = Callgraph_t.file = {
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

type dir = Callgraph_t.dir = {
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

type top = Callgraph_t.top = {
  path: string;
  id: string option;
  mutable namespaces: namespace list option;
  mutable physical_view: dir list option;
  mutable runtime_view: thread list option
}

type fonction = Callgraph_t.fonction = {
  sign: string;
  mangled: string;
  virtuality: string option;
  nspc: string option;
  record: string option;
  threads: string list option
}

type element = Callgraph_t.element = { id: string option }

type depends = Callgraph_t.depends = {
  id: string option;
  mutable includes: string list option;
  mutable calls: string list option;
  mutable called: string list option;
  mutable virtcalls: string list option
}

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

val write_fct_ref :
  Bi_outbuf.t -> fct_ref -> unit
  (** Output a JSON value of type {!fct_ref}. *)

val string_of_fct_ref :
  ?len:int -> fct_ref -> string
  (** Serialize a value of type {!fct_ref}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_fct_ref :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> fct_ref
  (** Input JSON data of type {!fct_ref}. *)

val fct_ref_of_string :
  string -> fct_ref
  (** Deserialize JSON data of type {!fct_ref}. *)

val write_extfct_ref :
  Bi_outbuf.t -> extfct_ref -> unit
  (** Output a JSON value of type {!extfct_ref}. *)

val string_of_extfct_ref :
  ?len:int -> extfct_ref -> string
  (** Serialize a value of type {!extfct_ref}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_extfct_ref :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> extfct_ref
  (** Input JSON data of type {!extfct_ref}. *)

val extfct_ref_of_string :
  string -> extfct_ref
  (** Deserialize JSON data of type {!extfct_ref}. *)

val write_fonction_def :
  Bi_outbuf.t -> fonction_def -> unit
  (** Output a JSON value of type {!fonction_def}. *)

val string_of_fonction_def :
  ?len:int -> fonction_def -> string
  (** Serialize a value of type {!fonction_def}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_fonction_def :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> fonction_def
  (** Input JSON data of type {!fonction_def}. *)

val fonction_def_of_string :
  string -> fonction_def
  (** Deserialize JSON data of type {!fonction_def}. *)

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

val write_fonction_decl :
  Bi_outbuf.t -> fonction_decl -> unit
  (** Output a JSON value of type {!fonction_decl}. *)

val string_of_fonction_decl :
  ?len:int -> fonction_decl -> string
  (** Serialize a value of type {!fonction_decl}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_fonction_decl :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> fonction_decl
  (** Input JSON data of type {!fonction_decl}. *)

val fonction_decl_of_string :
  string -> fonction_decl
  (** Deserialize JSON data of type {!fonction_decl}. *)

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

val write_top :
  Bi_outbuf.t -> top -> unit
  (** Output a JSON value of type {!top}. *)

val string_of_top :
  ?len:int -> top -> string
  (** Serialize a value of type {!top}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_top :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> top
  (** Input JSON data of type {!top}. *)

val top_of_string :
  string -> top
  (** Deserialize JSON data of type {!top}. *)

val write_fonction :
  Bi_outbuf.t -> fonction -> unit
  (** Output a JSON value of type {!fonction}. *)

val string_of_fonction :
  ?len:int -> fonction -> string
  (** Serialize a value of type {!fonction}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_fonction :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> fonction
  (** Input JSON data of type {!fonction}. *)

val fonction_of_string :
  string -> fonction
  (** Deserialize JSON data of type {!fonction}. *)

val write_element :
  Bi_outbuf.t -> element -> unit
  (** Output a JSON value of type {!element}. *)

val string_of_element :
  ?len:int -> element -> string
  (** Serialize a value of type {!element}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_element :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> element
  (** Input JSON data of type {!element}. *)

val element_of_string :
  string -> element
  (** Deserialize JSON data of type {!element}. *)

val write_depends :
  Bi_outbuf.t -> depends -> unit
  (** Output a JSON value of type {!depends}. *)

val string_of_depends :
  ?len:int -> depends -> string
  (** Serialize a value of type {!depends}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_depends :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> depends
  (** Input JSON data of type {!depends}. *)

val depends_of_string :
  string -> depends
  (** Deserialize JSON data of type {!depends}. *)

