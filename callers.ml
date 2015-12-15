(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(* This file defines accessors for Callers data types                         *)
(******************************************************************************)

let file_get_declared_function (file:Callers_t.file) (fct_sign:string) : Callers_t.fct_decl option =

  Printf.printf "callers.file_get_declared_function:BEGIN fct_sign=%s file=%s\n" fct_sign file.file;

  (match file.declared with

   | None ->
      (
        Printf.printf "WARNING: the function \"%s\" is not declared in file \"%s\"\n" fct_sign file.file;
        None
      )

   | Some fcts ->
      (
        let fct_decl : Callers_t.fct_decl option =
          (try
              Some
                (List.find
                   (
                     fun (fct:Callers_t.fct_decl) ->
                     (
                       (* Check whether the declared function is the searched one *)
                       if (String.compare fct.sign fct_sign == 0) then
                         (
                           Printf.printf "the function \"%s\" is well declared in file \"%s\"\n" fct_sign file.file;
                           true
                         )
                       else
                         false
                     )
                   )
                   fcts
                )
            with
              Not_found ->
              (
                Printf.printf "WARNING: the function \"%s\" is not declared in file \"%s\"\n" fct_sign file.file;
                None
              )
          )
        in
        fct_decl
      )
  )

let file_get_defined_function (file:Callers_t.file) (fct_sign:string) : Callers_t.fct_def option =

  Printf.printf "callers.file_get_defined_function:BEGIN fct_sign=%s file=%s\n" fct_sign file.file;

  (match file.defined with

   | None ->
      (
        Printf.printf "WARNING: the function \"%s\" is not defined in file \"%s\"\n" fct_sign file.file;
        None
      )

   | Some fcts ->
      (
        let fct_def : Callers_t.fct_def option =
          (try
              Some
                (List.find
                   (
                     fun (fct:Callers_t.fct_def) ->
                     (
                       (* Check whether the defined function is the searched one *)
                       if (String.compare fct.sign fct_sign == 0) then
                         (
                           Printf.printf "the function \"%s\" is well defined in file \"%s\"\n" fct_sign file.file;
                           true
                         )
                       else
                         false
                     )
                   )
                   fcts
                )
            with
              Not_found ->
              (
                Printf.printf "WARNING: the function \"%s\" is not defined in file \"%s\"\n" fct_sign file.file;
                None
              )
          )
        in
        fct_def
      )
  )

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread callers.native" *)
(* End: *)
