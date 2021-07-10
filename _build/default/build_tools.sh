#!/bin/bash

atdgen -t Callers.atd && atdgen -j Callers.atd
atdgen -t callgraph.atd && atdgen -j callgraph.atd

ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread common.native
ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread callers.native

## ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread callers_to_json.native
## ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread callgraph_to_json.native

## ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread parse_json_dir.native
## ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread parse_json_symbols.native
ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread list_json_files_in_dirs.native

ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread extract_metrics.native

# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread list_all_symbols.native
# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread list_defined_symbols.native
# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread read_defined_symbols.native

# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread add_declarations.native
# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread add_definitions.native

# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread add_extcallees.native
# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -tag thread add_extcallers.native

ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -tag thread -package base64 function_callgraph.native
ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -tag thread -package base64 extract_fcg.native

ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -package xml-light -package base64 -tag thread callgraph_to_dot.native
ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -package xml-light -package base64 -tag thread callgraph_to_ecore.native

# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread add_inherited.native
# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread add_virtual_function_calls.native
# ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -package ocamlgraph -tag thread classes_depgraph.native
