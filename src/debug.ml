
let test_root_qualif (id:string) =

  let rq = Common.get_root_qualifier "::" id
  in
  (match rq with
    | Some rq -> Printf.printf "id: %s, root_qualif: %s\n" id rq
    | None -> Printf.printf "id: %s, no root_qualif\n" id
  )
;;

let testing_root_qualif () =

  test_root_qualif "";
  test_root_qualif "::";
  test_root_qualif "::::";
  test_root_qualif "toto";
  test_root_qualif "::toto";
  test_root_qualif "::::toto";
  test_root_qualif "::toto::titi";
  test_root_qualif "::::toto::titi";
  test_root_qualif "::tata::toto::titi";
  test_root_qualif "::::tata::toto::titi";
;;

let () =

  testing_root_qualif ()
;;

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread debug.native" *)
(* End: *)
