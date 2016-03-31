(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   European IST STANCE project (2011-2015)                                  *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

(* constants *)
let rootdir_prefix = "/tmp/callers";;
let json_file_suffix = ".file.callers.gen.json";;
let json_dir_suffix = ".dir.callers.gen.json";;

(* Exceptions *)

exception Already_Configured
exception Already_Existing
exception Debug
exception Empty_File
exception Empty_Qualifier
exception Dir_Not_Found
exception File_Not_Found
exception IncompatibleType
exception Internal_Error
exception Invalid_argument
exception Malformed_Declaration_Definition
exception Malformed_Definition_Declaration
exception Malformed_Reference_Fct_Def         (* used in callers.ml and extract_fcg.ml *)
exception Malformed_Reference_Fct_Decl
exception Malformed_Extcallee_Definition
exception Malformed_Filename
exception Missing_File_Path
exception Missing_Input_Source_File
exception Missing_Options
exception More_Than_One_Definition
exception Namespace_Conflict
exception Not_Found_Function_Declaration
exception Not_Implemented
exception Not_Yet_Implemented
exception Symbol_Not_Found

exception TBC

exception Unexpected_Case
exception Unexpected_Case1
exception Unexpected_Case2
exception Unexpected_Case3
exception Unexpected_Case4
exception Unexpected_Case5
exception Unexpected_Case6
exception Unexpected_Case7

exception Unexpected_Error
exception Unexpected_Json_File_Format
exception Unexpected_Local_Declaration
exception Unexpected_Local_Definition
exception Unexpected_Extern_Declaration
exception Unexpected_Extern_Definition

exception Unsupported_Case
exception Unsupported_Class_Dependency_Type
exception Unsupported_File_Extension
exception Unsupported_Function_Kind
exception Unsupported_Recursive_Function
exception Unsupported_Virtuality_Keyword
exception Untested
exception Usage_Error
exception Wrong_Signature

exception Internal_Error_1
exception Internal_Error_2
exception Internal_Error_3
exception Internal_Error_4
exception Internal_Error_5
exception Internal_Error_6
exception Internal_Error_7
exception Internal_Error_8
exception Internal_Error_9
exception Internal_Error_10
exception Internal_Error_11
exception Internal_Error_12
exception Internal_Error_13
exception Internal_Error_14
exception Internal_Error_15
exception Internal_Error_16
exception Internal_Error_17

exception Unexpected_Error_1
exception Unexpected_Error_2
exception Unexpected_Error_3

module OutputFile
(OF : sig
  val name : string
  val ext : string
end)
  =
struct
  (*let filename : string = Printf.sprintf "%s.%s" (String.lowercase OF.name) OF.ext*)
  let filename : string = Printf.sprintf "%s.%s" OF.name OF.ext
  let outchan : out_channel = open_out filename
  let fmt : Format.formatter = Format.formatter_of_out_channel outchan
end

let file_get_kind (filename:string) : string =

  let file_ext =
    try
      let (_, file_ext) = Batteries.String.rsplit filename "." in file_ext
    with
      Not_found -> "none"
  in

  let kind =
    (match file_ext with
     | "c"
     | "tcc"
     | "cpp" -> "src"
     | "h"
     | "hh"
     | "hpp" -> "inc"
     | "none" ->
        (
          Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
          Printf.printf "Common.file_get_kind:WARNING: No_File_Extension in filename: %s\n" filename;
          Printf.printf "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\n";
          "inc"
        )
     | _ ->
        (
          Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
          Printf.printf "Common.file_get_kind:ERROR: Unsupported_File_Extension: %s\n" file_ext;
          Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
          raise Unsupported_File_Extension
        )
    )
  in
  kind

let is_same_string (str1:string) (str2:string) : bool =

  let cmp : int = String.compare str1 str2 in
  match cmp with
  | 0 -> true
  | _ -> false

let repeat_char (outchan:out_channel) (c:char) (n:int) : unit =

  if n < 0 then ()
  else
    for i = 0 to n do
      Printf.fprintf outchan "%c" c
    done

let search_pattern patt str : (int * int) option =

   let len = String.length str in
   try
     let b = String.index str patt in
     Some (b, len)
   with
     Not_found -> None

let rsearch_pattern patt str : (int * int) option =

   let len = String.length str in
   try
     let b = String.rindex str patt in
     Some (b, len)
   with
     Not_found -> None

let read_before_first patt name : string =

   let s = search_pattern patt name in
   (match s with
   | None ->
     (
       (* Printf.printf *)
       (* "read_before_first: not found pattern \"%c\" in name \"%s\", so return the full name\n" patt name; *)
       name
     )
   | Some(b,_) -> Str.string_before name b
   )

let read_before_last patt name : string =

   let s = rsearch_pattern patt name in
   (match s with
   | None ->
     (
       (* Printf.printf *)
       (* "read_before_last: not found pattern \"%c\" in name \"%s\", so return the full name\n" patt name; *)
       name
     )
   | Some(b,_) -> Str.string_before name b
   )

let read_after_first patt len name : string =

  let s = search_pattern patt name in
   (match s with
   | None ->
     (
       Printf.printf
        "read_after_first: not found pattern \"%c\" in name \"%s\", so return the full name\n" patt name;
       name
     )
   | Some(b,_) -> Str.string_after name (b+len)
   )

let read_after_last patt len name : string =

  let s = rsearch_pattern patt name in
   (match s with
   | None
   | Some (0,_) ->
     (
       (* Printf.printf *)
       (* "read_after_last: not found pattern \"%c\" in name \"%s\", so return the full name\n" patt name; *)
       name
     )
   | Some(b,_) -> Str.string_after name (b+len)
   )

let get_qualifiers (sep::string) (fullName:string) : string option =
  try
    (
      let (qualifiers, basename) = Batteries.String.rsplit fullName sep
      in
      Some qualifiers
    )
  with
    Not_found -> None

let get_root_qualifier (sep:string) (fullName:string) : string option =
  try
    (
      let (before, after) = Batteries.String.split fullName sep
      in
      (match before with
       | "" ->
          (
            try
              (
                let (a_before, a_after) = Batteries.String.split after sep
                in
                (match a_before with
                 | "" -> raise Empty_Qualifier
                 | qualifier -> Some qualifier
                )
              )
            with
              Not_found -> None
          )
       | qualifier -> Some qualifier
      )
    )
  with
    Not_found -> None

let get_namespace (fullName:string) : string =

  let root_namespace = get_root_qualifier "::" fullName
  in
  (match root_namespace with
   | None -> "::"
   | Some nspc -> nspc
  )

let read_module (fullName:string) : string option =

  get_root_qualifier "::" fullName

let get_fullname (name:string) : string =
   let n = read_after_last ':' 1 name in
   let m = read_module name
   in
   match m with
   | None -> n
   | Some m -> String.concat "_" [m;n]

let get_basename (name:string) =

  read_after_last '/' 1 name

let file_basename (filename:string) : string =

  let name = get_basename filename in

  read_before_last '.' name

  (* let b = rsearch_pattern '.' name in *)
  (* let basename =  *)
  (*   (match b with *)
  (*   | None -> raise Malformed_Filename *)
  (*   | Some b -> read_before_last '.' name) *)
  (* in *)
  (* basename *)

let file_extension (filename:string) : string =

  let fext = rsearch_pattern '.' filename in

  let fileext : string =
    (match fext with
    | None -> raise Malformed_Filename
    | Some ext -> read_after_last '.' 1 filename)
  in

  Printf.printf
    "common.file_extension: file: \"%s\", ext: \"%s\"\n" filename fileext;
  fileext

(* let file_has_extension (file:File.t) (ext:string) : bool = *)

(*   let filename = File.get_name file in *)
(*   let fileext = file_extension filename in *)
(*   if fileext = ext then *)
(*     true *)
(*   else *)
(*     false *)

(* let get_storage (kf:Cil_types.kernel_function) : string = *)

(*   let vi : Cil_types.varinfo = Kernel_function.get_vi kf in *)
(*   let storage : Cil_types.storage = vi.vstorage in *)
(*   match storage with *)
(*   | NoStorage -> "" *)
(*   | Static ->  "static" *)
(*   | Extern -> "extern" *)
(*   | Register -> "register" *)

(* class namedElement *)
class namedElement (sep:char) (fullName:string) =
object

  val fullName : string = fullName
  val sep : char = sep

  method get_fullName = fullName

  method get_name : string = read_after_last sep 1 fullName

  method get_module = read_module fullName

  method get_path : string =

    let dir = rsearch_pattern sep fullName in
    match dir with
    | Some d ->
      read_before_last sep fullName
    (* else get current directory *)
    | None -> Sys.getcwd ()
end

let create_named_element (sep:char) (fullName:string) : namedElement =

  new namedElement sep fullName

let get_root_dir (filepath:string) : string =

  let first_char = String.get filepath 0 in
  (* Printf.printf "first char: %c\n" first_char; *)
  let root_dir =
    (match first_char with
     | '/' ->
      (
        let truncated = read_after_first '/' 1 filepath in
        (* Printf.printf "truncated: %s\n" truncated; *)
        read_before_first '/' truncated
      )
     | _ -> read_before_first '/' filepath
    )
  in
  root_dir

(* Keep the rootdir prefix when present and add it when lacking*)
let check_root_dir (json_filepath:string) : string =

  (* Printf.printf "common.check_root_dir:BEGIN json_filepath: %s\n" json_filepath; *)

  (* check whether the input path begins with / or not *)
  let first_char = Batteries.String.get json_filepath 0 in
  (* Printf.printf "common.check_root_dir:DEBUG: The first character is: %c\n" first_char; *)
  let json_filepath =
    (match first_char with
     | '/' -> (* Printf.printf "common.check_root_dir:DEBUG: matched first character is slash\n" *)
        json_filepath
     | _ ->
        (
          Printf.printf "common.check_root_dir:WARNING: add a slash character to json_file \"%s\" \n" json_filepath;
          Printf.sprintf "/%s" json_filepath
        )
    )
  in
  let json_filepath : string =
    try
      let (_, _) = Batteries.String.split json_filepath rootdir_prefix in
      json_filepath
    with
    | Not_found ->
       (
         (* Add the rootdir_prefix to the input json filename *)
         (* Printf.printf "common.check_root_dir:DEBUG: prefixing json_filepath: %s with rootdir: %s\n" json_filepath rootdir_prefix; *)
         let json_filepath = String.concat "" [ rootdir_prefix; json_filepath ] in
         json_filepath
       )
  in
  json_filepath

(* Filter root dir when present in input filename *)
let filter_root_dir (filepath:string) : string =

  (* Printf.printf "common.filter_root_dir:BEGIN filepath: %s\n" filepath; *)
  let filepath : string =
    try
      let (rp, fp) = Batteries.String.split filepath rootdir_prefix in
      fp
    with
    | Not_found ->
       (
         Printf.printf "common.filter_root_dir:WARNING: no root dir prefix \"%s\"is present in filepath: %s\n" rootdir_prefix filepath;
         filepath
       )
  in
  (* Printf.printf "common.filter_root_dir:END filepath: %s\n" filepath; *)
  filepath

(* Filter json file suffix when present in input filename *)
(* suffix = .file.callers.gen.json | .dir.callers.gen.json *)
let filter_json_file_suffix (suffix:string) (json_filepath:string) : string =

  (* Printf.printf "filter_json_file_suffix:BEGIN json_filepath: %s\n" json_filepath; *)
  let json_filepath : string =
    try
      let (file, _) = Batteries.String.split json_filepath suffix in
      file
    with
    | Not_found ->
       (
         Printf.printf "common.filter_json_file_suffix:WARNING: no suffix \"%s\" is present in filepath: %s\n" suffix json_filepath;
         json_filepath
       )
  in
  (* Printf.printf "common.filter_json_file_suffic:END json_filepath: %s\n" json_filepath; *)
  json_filepath

let read_json_file (filepath:string) : string option =

  let json_filepath = check_root_dir filepath in

  try
    Printf.printf "common.read_json_file %s\n" json_filepath;
    (* Read JSON file into an OCaml string *)
    let content : string = Core.Std.In_channel.read_all json_filepath in
    if ( String.length content != 0 )
    then
      Some content
    else
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "common.read_json_file::ERROR::Empty_File::%s\n" json_filepath;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        None
      )
  with
  | Sys_error msg ->
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "common.read_json_file::ERROR::File_Not_Found::%s\n" json_filepath;
        Printf.printf "Sys_error msg: %s\n" msg;
        Printexc.print_backtrace stderr;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise File_Not_Found
      )
  | Yojson.Json_error msg ->
     (
       Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
       Printf.printf "common.read_json_file::ERROR::unexpected Yojson error when reading file::%s\n" json_filepath;
       Printf.printf "Yojson.Json_error msg: %s\n" msg;
       Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
       raise Unexpected_Error
     )

let parse_namespace_in_file (namespace_name:string) (namespace_filepath:string) : Callers_t.namespace option =

  let dirpath : string = read_before_last '/' namespace_filepath in
  let filename : string = read_after_last '/' 1 namespace_filepath in
  let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
  let content = read_json_file jsoname_file in
  (match content with
   | None -> None
   | Some content ->
      (
        (* Printf.printf "Read %s content is:\n %s: \n" filename content; *)
        (* Printf.printf "atdgen parsed json file is :\n"; *)
        (* Use the atdgen JSON parser *)
        let file : Callers_t.file = Callers_j.file_of_string content in
        (* print_endline (Callers_j.string_of_file file); *)

        (* Parse the json functions contained in the current file *)
        (match file.namespaces with
         | None -> None
         | Some namespaces ->

	    (* Look for the function "namespace_name" among all the functions defined in file *)
	    try
	      (
                let full_namespace_name = Printf.sprintf "::%s" namespace_name in
  	        Some (
	            List.find
  	              (
  		        fun (n:Callers_t.namespace) -> ((String.compare namespace_name n.name == 0)||(String.compare full_namespace_name n.name == 0))
	              )
	              namespaces)
	      )
	    with
	      Not_found -> None
        )
      )
  )

let parse_record_in_file (record_name:string) (record_filepath:string) : Callers_t.record option =

  let dirpath : string = read_before_last '/' record_filepath in
  let filename : string = read_after_last '/' 1 record_filepath in
  let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
  let content = read_json_file jsoname_file in
  (match content with
   | None -> None
   | Some content ->
      (
        (* Printf.printf "Read %s content is:\n %s: \n" filename content; *)
        (* Printf.printf "atdgen parsed json file is :\n"; *)
        (* Use the atdgen JSON parser *)
        let file : Callers_t.file = Callers_j.file_of_string content in
        (* print_endline (Callers_j.string_of_file file); *)

        (* Parse the json functions contained in the current file *)
        (match file.records with
         | None -> None
         | Some records ->

	    (* Look for the function "record_name" among all the functions defined in file *)
	    try
	      (
                let full_record_name = Printf.sprintf "::%s" record_name in
  	        Some (
	            List.find
  	              (
  		        fun (r:Callers_t.record) -> ((String.compare record_name r.name == 0)||(String.compare full_record_name r.name == 0))
	              )
	              records)
	      )
	    with
	      Not_found -> None
        )
      )
  )

let parse_thread_in_file (thr_id:string) (thread_filepath:string) : Callers_t.thread option =

  Printf.printf "common.parse_thread_in_file:BEGIN: thr_id=%s thr_filepath=%s\n" thr_id thread_filepath;
  let dirpath : string = read_before_last '/' thread_filepath in
  let filename : string = read_after_last '/' 1 thread_filepath in
  let jsoname_file = String.concat "" [ dirpath; "/"; filename; ".file.callers.gen.json" ] in
  let content = read_json_file jsoname_file in
  (match content with
   | None -> None
   | Some content ->
      (
        (* Printf.printf "Read %s content is:\n %s: \n" filename content; *)
        (* Printf.printf "atdgen parsed json file is :\n"; *)
        (* Use the atdgen JSON parser *)
        let file : Callers_t.file = Callers_j.file_of_string content in
        (* print_endline (Callers_j.string_of_file file); *)

        (* Parse the json functions contained in the current file *)
        (match file.threads with
         | None -> None
         | Some threads ->

	    (* Look for the function "thread_name" among all the functions defined in file *)
	    try
	      (
  	        Some (
	            List.find
  	              (
  		        fun (thr:Callers_t.thread) -> (String.compare thr_id thr.id == 0)
	              )
	              threads
                  )
	      )
	    with
	      Not_found -> None
        )
      )
  )

(* let print_callgraph_file (edited_file:Callgraph_t.file) (json_filepath:string) = *)

(*   let json_filepath : string = check_root_dir json_filepath in *)
(*   let jfile = Callgraph_j.string_of_file edited_file in *)
(*   Printf.printf "common.print_callgraph_file:DEBUG: tries to write json file %s\n" json_filepath; *)
(*   Core.Std.Out_channel.write_all json_filepath jfile *)

let print_callgraph_dir (edited_dir:Callgraph_t.dir) (json_dirpath:string) =

  let json_dirpath : string = check_root_dir json_dirpath in
  let jdir = Callgraph_j.string_of_dir edited_dir in
  Printf.printf "common.print_callgraph_dir:DEBUG: tries to write json dir %s\n" json_dirpath;
  Core.Std.Out_channel.write_all json_dirpath jdir

let print_callgraph_top (edited_dir:Callgraph_t.top) (json_dirpath:string) =

  let json_dirpath : string = check_root_dir json_dirpath in
  let jdir = Callgraph_j.string_of_top edited_dir in
  Printf.printf "common.print_callgraph_top:DEBUG: tries to write json dirs %s\n" json_dirpath;
  Core.Std.Out_channel.write_all json_dirpath jdir

let test_read_module (fullname:string) =

  let modul = read_module fullname in
  (match modul with
   | None -> Printf.printf "fullname: %s, no module\n" fullname
   | Some modul -> Printf.printf "fullname: %s, module: %s\n" fullname modul
  )
;;

let test_read_modules () =
  test_read_module "";
  test_read_module "a";
  test_read_module "a::b";
  test_read_module "a::b::c";
  test_read_module "::";
  test_read_module "::a";
  test_read_module "::a::b";
  test_read_module "::a::b::c"
;;

(* let () = test_read_modules () *)

(* Local Variables: *)
(* mode: tuareg *)
(* compile-command: "ocamlbuild -use-ocamlfind -package atdgen -package core -package batteries -tag thread common.native" *)
(* End: *)
