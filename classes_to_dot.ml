(* tangled from ~/org/technology/data/data.org *)
(* adapted from /media/users/balp/tests/data/interchange/json/test_random_event/test_yojson_read.ml *)

(* open Core.Std *)

(* exception Internal_Error *)
exception Internal_Error_1
exception Internal_Error_2
exception Internal_Error_3
exception Internal_Error_4
exception Internal_Error_5
exception Internal_Error_6
exception Internal_Error_7

exception Unexpected_Error_1
exception Unexpected_Error_2
exception Unexpected_Error_3

exception File_Not_Found
exception Usage_Error
(* exception TBC *)

module BaseClasses = Map.Make(String);;
module ChildClasses = Map.Make(String);;
module Calls = Map.Make(String);;

class classes_json_parser 
        (cclass_id:string) 
        (cclass_signature:string)
        (cclass_json_filepath:string)
        (other:string list option)
        (* (root_directory:string)  *)
  = object(self)

  val cclass_id : string = cclass_id

  val cclass_sign : string = cclass_signature

  val cclass_file_path : string = cclass_json_filepath

  val show_files : bool = 

    (match other with
    | None -> false
    | Some args -> 
      
      let show_files : string =
        try
          List.find
            (
              fun arg -> 
                (match arg with
                | "files" -> true
                | _ -> false
                )
            )
            args
        with
          Not_found -> "none"
      in
      (match show_files with
      | "files" -> true
      | "none"
      | _ -> false
      )
    )

  (* Base classes graph *)
  val mutable gbase_classes : Graph_func.G.t = Graph_func.G.empty

  (* Child classes graph *)
  val mutable gchild_classes : Graph_func.G.t = Graph_func.G.empty

  (* Function bclass to cclass  graph *)
  val mutable gchild2base_class : Graph_func.G.t = Graph_func.G.empty

  val mutable cclasses_table = ChildClasses.empty
  val mutable bclasses_table = ChildClasses.empty

  val mutable cclasses_calls_table = Calls.empty
  val mutable bclasses_calls_table = Calls.empty

  method read_json_file (filename:string) : Yojson.Basic.json =
    try
      Printf.printf "In_channel read file %s...\n" filename;
    (* Read JSON file into an OCaml string *)
      let buf = Core.Std.In_channel.read_all filename in           
    (* Use the string JSON constructor *)
      let json1 = Yojson.Basic.from_string buf in
      json1
    with
    | Sys_error msg -> 
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "funcion_bclasses_to_dot::ERROR::File_Not_Found::%s\n" filename;
        Printf.printf "Sys_error msg: %s\n" msg;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise File_Not_Found
      )

  method dump_class (class_sign:string) (json_file:string) : Graph_func.function_decl =

    (* Replace all / by _ in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\/") "_" json_file in

    (* Replace all '.' by '_' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\.") "_" fpath in

    (* Replace all '-' by '_' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\-") "_" fpath in

    (* Replace all '+' by 'p' in the file path *)
    let fpath : string = Str.global_replace (Str.regexp "\\+") "p" fpath in

    let filename : string = Filename.basename json_file in

    let file : Graph.Graphviz.DotAttributes.subgraph option = 
      if show_files then
        Some
          {
            sg_name = fpath;
            sg_attributes = [ `Label filename ];
            (* sg_parent = Some class_memberdef_factory.file.sg_name; *)
            sg_parent = None;
          }
      else
        None
    in
    let v : Graph_func.function_decl =
      {
        id = Printf.sprintf "\"%s\"" class_sign;
        name = Printf.sprintf "\"%s\"" class_sign;
        file_path = json_file;
        line = "unkownFunctionLine";
        bodyfile = json_file;
        bodystart = "unkownBodyStart";
        bodyend = "unkownBodyEnd";
        return_type = "unkownFunctionReturnType";
        argsstring = "unkownFunctionArgs";
        params = [];
        bclasses = [];
        cclasses = [];
        file = file
      }
    in
    v

  method parse_class_in_file (class_sign:string) (json_filepath:string) : Callgraph_t.class option =

    let dirpath : string = Common.read_before_last '/' json_filepath in
    let filename : string = Common.read_after_last '/' 1 json_filepath in
    let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.bclasses.gen.json" ] in
    let json : Yojson.Basic.json = self#read_json_file jsoname_file in
    let content : string = Yojson.Basic.to_string json in
    (* Printf.printf "Read %s content is:\n %s: \n" filename content; *)
    (* Printf.printf "atdgen parsed json file is :\n"; *)
    (* Use the atdgen JSON parser *)
    let file : Callgraph_t.file = Callgraph_j.file_of_string content in
    (* print_endline (Callgraph_j.string_of_file file); *)
    
    (* Parse the json functions contained in the current file *)
    (match file.defined with
     | None -> None
     | Some classes ->

        (* Look for the function "class_sign" among all the functions defined in file *)
        try
          (
            Some (
              List.find
              (
                fun (f:Callgraph_t.class) -> String.compare class_sign f.sign == 0
              )
              classes )
          )
        with
          Not_found -> None
    )

  method cclasses_register_function_call (call:string) : unit =
    
    cclasses_calls_table <- Calls.add call true cclasses_calls_table

  method cclasses_registered_as_function_call (call:string) : bool =

    try
      Calls.find call cclasses_calls_table
    with
      Not_found -> false

  method bclasses_register_function_call (call:string) : unit =
    
    bclasses_calls_table <- Calls.add call true bclasses_calls_table

  method bclasses_registered_as_function_call (call:string) : bool =

    try
      Calls.find call bclasses_calls_table
    with
      Not_found -> false

  method register_function_child_class (class_sign:string) : unit =
    
    cclasses_table <- ChildClasses.add class_sign true cclasses_table

  method registered_as_function_child_class (class_sign:string) : bool =

    try
      ChildClasses.find class_sign cclasses_table
    with
      Not_found -> false

  method register_function_base_class (class_sign:string) : unit =
    
    bclasses_table <- BaseClasses.add class_sign true bclasses_table

  method registered_as_function_base_class (class_sign:string) : bool =

    try
      BaseClasses.find class_sign bclasses_table
    with
      Not_found -> false

  method parse_function_and_cclasses (class_sign:string) (json_file:string) 
                                    (gbclass_sign:string) (gbclass_v:Graph_func.function_decl option) 
         : Graph_func.function_decl option =

    (* Printf.printf "DEBUG: parse_function_and_cclasses \"%s\" \"%s\" \"%s\"\n" class_sign json_file gbclass_sign; *)

    (* Parse current function *)
    let class = self#parse_class_in_file class_sign json_file in
    
    (match class with
     | None -> 
        Printf.printf "WARNING: no function found in file \"%s\" with signature=\"%s\" !\n" 
                      json_file class_sign;
        None

     | Some class -> 
        (
          let vbclass : Graph_func.function_decl = self#dump_class class.sign json_file in
          gchild_classes <- Graph_func.G.add_vertex gchild_classes vbclass;

          let call : string = String.concat "" [ gbclass_sign; " -> "; class_sign ]
          in

          if (self#registered_as_function_child_class class_sign)
             && (self#cclasses_registered_as_function_call call) then
            (
              Printf.printf "WARNING: cclass cycle detected including function \"%s\"\n" class_sign;
              (match gbclass_v with
              | None -> raise Internal_Error_1
              | Some gbclass -> 
                 gchild_classes <- Graph_func.G.add_edge_e gchild_classes (Graph_func.G.E.create gbclass "cycle" vbclass)
              );
              None
            )
          else
            (
              if not(self#cclasses_registered_as_function_call call) then
                self#cclasses_register_function_call call;

              if not(self#registered_as_function_child_class class_sign) then
                (
                  self#register_function_child_class class_sign;

                  (* Parse local cclasses *)
                  (match class.locclasses with
                   | None -> ()
                   | Some locclasses ->
                      Printf.printf "Parse local cclasses...\n";
                      List.iter
                        ( fun (f:string) -> 
                          Printf.printf "visit locclass: %s...\n" f;
                          let vcclass = self#parse_function_and_cclasses (f) (json_file) (class_sign) (Some vbclass) in
                          (match vcclass with
                           | None -> () (* cycle probably detected *)
                           | Some vcclass ->
                              gchild_classes <- Graph_func.G.add_edge_e gchild_classes (Graph_func.G.E.create vbclass "internal" vcclass)
                          )
                        )
                        locclasses
                  );

                  (* Parse remote cclasses *)
                  (match class.extcclasses with
                   | None -> ()
                   | Some extcclasses ->
                      Printf.printf "Parse remote cclasses...\n";
                      List.iter
                        ( fun (f:Callgraph_t.extclass) -> 

                          (match f.def with
                          | "unknownExtClassDef" -> 
                            (
                              Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
                              Printf.printf "WARNING: Unable to visit unknown extcclass: %s\n" f.sign;
                              Printf.printf "bclass sign is: %s\n" class.sign;
                              Printf.printf "cclass decl is: %s\n" f.decl;
                              Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
                              let loc : string list = Str.split_delim (Str.regexp ":") f.decl in
                              let file = 
                                (match loc with
                                | [ file; _ ] ->  file
                                | _ -> raise Internal_Error_2
                                )
                              in
                              let vcclass : Graph_func.function_decl = self#dump_class f.sign file in
                              gchild_classes <- Graph_func.G.add_edge_e gchild_classes (Graph_func.G.E.create vbclass "external" vcclass)
                            )
                          | "unlinkedExtCclass" -> 
                            (
                              Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
                              Printf.printf "WARNING: Unable to visit unlinked extcclass: %s\n" f.sign;
                              Printf.printf "bclass sign is: %s\n" class.sign;
                              Printf.printf "cclass decl is: %s\n" f.decl;
                              Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
                              let loc : string list = Str.split_delim (Str.regexp ":") f.decl in
                              let file = 
                                (match loc with
                                | [ file; _ ] ->  file
                                | _ -> raise Internal_Error_2
                                )
                              in
                              let vcclass : Graph_func.function_decl = self#dump_class f.sign file in
                              gchild_classes <- Graph_func.G.add_edge_e gchild_classes (Graph_func.G.E.create vbclass "external" vcclass)
                            )
                          | "builtinFunctionDef" -> 
                            (
                              let loc : string list = Str.split_delim (Str.regexp ":") f.decl in
                              let file = 
                                (match loc with
                                | [ file; _ ] ->  file
                                | _ -> raise Internal_Error_2
                                )
                              in
                              let vcclass : Graph_func.function_decl = self#dump_class f.sign file in
                              gchild_classes <- Graph_func.G.add_edge_e gchild_classes (Graph_func.G.E.create vbclass "external" vcclass)
                            )
                          | _ ->
                            (
                              let loc : string list = Str.split_delim (Str.regexp ":") f.def in
                              let file = 
                                (match loc with
                                | [ file; _ ] ->  file
                                | _ -> raise Internal_Error_2
                                )
                              in
                              let vcclass = self#parse_function_and_cclasses (f.sign) (file) (class_sign) (Some vbclass) in
                              (match vcclass with
                              (* | None -> raise Internal_Error *)
                              | None -> () (* cycle probably detected *)
                              | Some vcclass ->
                                gchild_classes <- Graph_func.G.add_edge_e gchild_classes (Graph_func.G.E.create vbclass "external" vcclass)
                              )
                            )
                          )
                        )
                        extcclasses
                  )
                );
              Some vbclass
            )
        )
    )

  method parse_function_and_bclasses (class_sign:string) (json_file:string) 
                                    (gcclass_sign:string) (gcclass_v:Graph_func.function_decl option) 
         : Graph_func.function_decl option =

    (* Printf.printf "DEBUG: parse_function_and_bclasses \"%s\" \"%s\" \"%s\"\n" class_sign json_file gcclass_sign; *)

    (* Parse current function *)
    let class = self#parse_class_in_file class_sign json_file in
    
    (match class with
     | None -> 
        Printf.printf "WARNING: no function found in file \"%s\" with signature=\"%s\" !\n" 
                      json_file class_sign;
        None

     | Some class -> 
        (
          let vcclass : Graph_func.function_decl = self#dump_class class.sign json_file in
          gbase_classes <- Graph_func.G.add_vertex gbase_classes vcclass;

          let call : string = String.concat "" [ class_sign; " -> "; gcclass_sign ]
          in

          if (self#registered_as_function_base_class class_sign)
             && (self#bclasses_registered_as_function_call call) then
            (
              Printf.printf "WARNING: bclass cycle detected including function \"%s\"\n" class_sign;
              (match gcclass_v with
               | None -> raise Internal_Error_3
               | Some gcclass -> 
                  gbase_classes <- Graph_func.G.add_edge_e gbase_classes (Graph_func.G.E.create vcclass "cycle" gcclass)
              );
              None
            )
          else
            (
              if not(self#bclasses_registered_as_function_call call) then
                self#bclasses_register_function_call call;

              if not(self#registered_as_function_base_class class_sign) then
                (
                  self#register_function_base_class class_sign;

                  if self#registered_as_function_child_class class_sign then
                    (
                      gchild2base_class <- Graph_func.G.add_vertex gchild2base_class vcclass;
                    );
                  
                  (* Parse local bclasses *)
                  (match class.lobclasses with
                   | None -> ()
                   | Some lobclasses ->
                      Printf.printf "Parse local bclasses...\n";
                      List.iter
                        ( fun (f:string) -> 
                          let vbclass = self#parse_function_and_bclasses f json_file class_sign (Some vcclass) in
                          (match vbclass with

                          | None -> raise Internal_Error_4 (* cycle probably detected *)
                           
                          | Some vbclass ->
                              (
                                gbase_classes <- Graph_func.G.add_edge_e gbase_classes (Graph_func.G.E.create vbclass "internal" vcclass);

                                if (self#registered_as_function_child_class class_sign) &&
                                     (self#registered_as_function_child_class f)         
                                then
                                  (
                                    gchild2base_class <- Graph_func.G.add_edge_e gchild2base_class (Graph_func.G.E.create vbclass "internal" vcclass);
                                  )
                              )
                          )
                        )
                        lobclasses
                  );

                  (* Parse remote bclasses *)
                  (match class.extbclasses with
                  | None -> ()
                  | Some extbclasses ->
                      Printf.printf "Parse remote bclasses...\n";
                      List.iter
                        ( fun (f:Callgraph_t.extclass) -> 

                          (match f.def with
                          | "unlinkedExtBclass" -> 
                              (
                                Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
                                Printf.printf "Unable to visit unlinked extbclass: %s\n" f.sign;
                                Printf.printf "Current bclass is: %s\n" class.sign;
                                Printf.printf "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww\n";
                              )
                          | _ ->
                            (
                              let file = 
                                let loc : string list = Str.split_delim (Str.regexp ":") f.def in
                                (match loc with
                                | [ file; _ ] ->  file
                                | _ -> 
                                  (
                                    Printf.printf "HBDBG: f.def: %s" f.def;
                                    raise Internal_Error_5
                                  )
                                )
                              in
                              let vbclass = self#parse_function_and_bclasses f.sign file class_sign (Some vcclass) in
                              (match vbclass with
                              | None -> raise Internal_Error_6 (* cycle probably detected *)
                              | Some vbclass ->
                                (
                                  gbase_classes <- Graph_func.G.add_edge_e gbase_classes (Graph_func.G.E.create vbclass "external" vcclass);
                                  
                                  if (self#registered_as_function_child_class class_sign) &&
                                    (self#registered_as_function_child_class f.sign)
                                  then
                                    (
                                      gchild2base_class <- Graph_func.G.add_edge_e gchild2base_class (Graph_func.G.E.create vbclass "external" vcclass);
                                    )
                                )
                              )
                            )
                          )
                        )
                        extbclasses
                  )
                );
              Some vcclass
            )
        )
    )
	
  (* method parse_json_dir (rootdir:string) : unit = *)

  (*   let jsoname_dir = String.concat "" [ rootdir; ".dir.bclasses.json" ] in *)
  (*   (\* let jsoname_dir = String.concat "" [ rootdir; ".dir.bclasses.json" ] in *\) *)
  (*   let json : Yojson.Basic.json = self#read_json_file jsoname_dir in *)
  (*   let content : string = Yojson.Basic.to_string json in *)
  (*   Printf.printf "Read directory content is:\n %s: \n" content; *)

  (*   Printf.printf "atdgen parsed json directory is :\n"; *)
  (*   (\* Use the atdgen JSON parser *\) *)
  (*   let dir : Callgraph_t.dir = Callgraph_j.dir_of_string content in *)
  (*   print_endline (Callgraph_j.string_of_dir dir); *)

  (*   (\* Parse the json files contained in the current directory *\) *)
  (*   (match dir.files with *)
  (*    | None -> () *)
  (*    | Some files -> List.iter ( fun f -> self#parse_json_file f ) files *)
  (*   ) *)

  method output_base_classes (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file gbase_classes

  method output_child_classes (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file gchild_classes

  method output_child2base_class (dot_filename:string) : unit =

    let file = open_out_bin dot_filename in
    Graph_func.Dot.output_graph file gchild2base_class

end

(* Anonymous argument *)
let spec =
  let open Core.Std.Command.Spec in
  empty
  +> anon ("direction" %: string)
  +> anon ("class1_json" %: string)
  +> anon ("class1_id" %: string)
  +> anon ("class1_sign" %: string)
  +> anon (maybe(sequence("other" %: string)))

(* Basic command *)
let command =
  Core.Std.Command.basic
    ~summary:"Parses base and/or child classes from bclasses's generated json files (direction=base|child|c2b)"
    ~readme:(fun () -> "More detailed information")
    spec
    (
      fun direction class1_json class1_id class1_sign other () -> 
      
      let parser = new classes_json_parser class1_id class1_sign class1_json other in

      try
      (
	match direction with

	 | "base" -> 
	    (
	      let _ = parser#parse_function_and_bclasses (class1_sign) (class1_json) "bclasses" None in
	      parser#output_base_classes (Printf.sprintf "%s.base.classes.gen.dot" class1_id)
	    )

	 | "child" -> 
	    (
	      let _ = parser#parse_function_and_cclasses (class1_sign) (class1_json) "cclasses" None in
	      parser#output_child_classes (Printf.sprintf "%s.child.classes.gen.dot" class1_id)
	    )

	 | "c2b" -> 
	    (match other with
	     | Some [class2_json; class2_id; class2_sign; "files"]
	     | Some [class2_json; class2_id; class2_sign ] ->
		(
		  Printf.printf "1) First retrieve all the cclasses of the bclass function \"%s\ defined in file \"%s\"\n" class1_sign class1_json;
		  let _ = parser#parse_function_and_cclasses (class1_sign) (class1_json) "cclasses" None in
		  Printf.printf "2) Then retrieve all the bclasses of the cclass function \"%s\ defined in file \"%s\"\n" class2_sign class2_json;
		  let _ = parser#parse_function_and_bclasses (class2_sign) (class2_json) "bclasses" None in 
		  parser#output_child_classes (Printf.sprintf "%s.child.classes.gen.dot" class1_id);
		  parser#output_base_classes (Printf.sprintf "%s.base.classes.gen.dot" class2_id);
		  Printf.printf "3) Now we can retrieve all the paths between child class \"%s\" and base class \"%s\"\n" class1_sign class2_sign;
		  parser#output_child2base_class (Printf.sprintf "%s.%s.c2b.gen.dot" class1_id class2_id)
		)
	     | None
	     | _ -> 
		(
		  Printf.printf "ERROR: \"c2b\" direction requires \"id\", \"sign\" and \"json\" file path of both bclass class1 and cclass class2 !\n";
		  raise Usage_Error
		)
	    )
	 | _ -> 
	    (
	      Printf.printf "ERROR: unsupported direction \"%s\"" direction;
	      raise Internal_Error_7
	    )
      )
      with
	File_Not_Found -> raise Unexpected_Error_3
    )

(* Running Basic Commands *)
let () =
  Core.Std.Command.run ~version:"1.0" ~build_info:"RWO" command

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package yojson -tag thread classes_to_dot.native" *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package ocamlgraph -tag thread classes_to_dot.native" *)
(* End: *)
