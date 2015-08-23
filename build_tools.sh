#!/bin/bash

atdgen -t callgraph.atd && atdgen -j callgraph.atd

ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread callgraph_from_json.native

ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread callgraph_to_json.native

ocamlbuild -use-ocamlfind -package atdgen -package core -tag thread add_extcallees.native

ocamlbuild -use-ocamlfind -package atdgen -package core -package ocamlgraph -tag thread add_extcallers.native

ocamlbuild -use-ocamlfind -package atdgen -package core -package ocamlgraph -tag thread function_callers_to_dot.native
