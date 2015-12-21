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
exception File_Not_Found
exception IncompatibleType
exception Internal_Error
exception Invalid_argument
exception Malformed_Declaration_Definition
exception Malformed_Definition_Declaration
exception Malformed_Reference_Fct_Def (* used in callers.ml *)
exception Malformed_Extcallee_Definition
exception Malformed_Filename
exception Missing_File_Path
exception Missing_Input_Source_File
exception Missing_Options
exception Not_Implemented
exception Not_Yet_Implemented
exception Symbol_Not_Found
exception TBC
exception Unexpected_Case
exception Unexpected_Error
exception Unexpected_Json_File_Format
exception Unsupported_Case
exception Unsupported_Class_Dependency_Type
exception Unsupported_Function_Kind
exception Unsupported_Recursive_Function
exception Unsupported_Virtuality_Keyword
exception Untested
exception Usage_Error

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

let read_module fullName =

   let s = search_pattern ':' fullName in
   let modul =
     (match s with
     | None
     | Some (0,_) -> "unspecified_module"
     | Some(b,_) -> Str.string_before fullName b
     )
   in
   modul

let get_fullname name =
   let n = read_after_last ':' 1 name in
   let m = read_module name
   in
   match m with
   | "unspecified_module" -> n
   | "unknown_module" -> raise Internal_Error
   | _ -> String.concat "_" [m;n]

let get_basename (name:string) =

  read_after_last '/' 1 name

let file_basename (filename:string) : string =

  let name = get_basename filename in

  read_before_last '.' name

  (* let b = rsearch_pattern '.' name in *)
  (* let basename =  *)
  (*   (match b with *)
  (*   | None -> raise Common.Malformed_Filename *)
  (*   | Some b -> Common.read_before_last '.' name) *)
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
    "Common.file_extension: file: \"%s\", ext: \"%s\"\n" filename fileext;
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

  (* Printf.printf "Common.check_root_dir:BEGIN json_filepath: %s\n" json_filepath; *)

  (* check whether the input path begins with / or not *)
  let first_char = Batteries.String.get json_filepath 0 in
  (* Printf.printf "Common.check_root_dir:DEBUG: The first character is: %c\n" first_char; *)
  let json_filepath =
    (match first_char with
     | '/' -> (* Printf.printf "Common.check_root_dir:DEBUG: matched first character is slash\n" *)
        json_filepath
     | _ ->
        (
          Printf.printf "Common.check_root_dir:WARNING: add a slash character to json_file \"%s\" \n" json_filepath;
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
         (* Printf.printf "Common.check_root_dir:DEBUG: prefixing json_filepath: %s with rootdir: %s\n" json_filepath rootdir_prefix; *)
         let json_filepath = String.concat "" [ rootdir_prefix; json_filepath ] in
         json_filepath
       )
  in
  json_filepath

(* Filter root dir when present in input filename *)
let filter_root_dir (filepath:string) : string =

  (* Printf.printf "Common.filter_root_dir:BEGIN filepath: %s\n" filepath; *)
  let filepath : string =
    try
      let (rp, fp) = Batteries.String.split filepath rootdir_prefix in
      fp
    with
    | Not_found ->
       (
         Printf.printf "Common.filter_root_dir:WARNING: no root dir prefix \"%s\"is present in filepath: %s\n" rootdir_prefix filepath;
         filepath
       )
  in
  (* Printf.printf "Common.filter_root_dir:END filepath: %s\n" filepath; *)
  filepath

(* Filter json file suffix when present in input filename *)
(* suffix = .file.callers.gen.json | .dir.callers.gen.json *)
let filter_json_file_suffix (suffix:string) (json_filepath:string) : string =

  (* Printf.printf "Common.filter_json_file_suffix:BEGIN json_filepath: %s\n" json_filepath; *)
  let json_filepath : string =
    try
      let (file, _) = Batteries.String.split json_filepath suffix in
      file
    with
    | Not_found ->
       (
         Printf.printf "Common.filter_json_file_suffix:WARNING: no suffix \"%s\" is present in filepath: %s\n" suffix json_filepath;
         json_filepath
       )
  in
  (* Printf.printf "Common.filter_json_file_suffic:END json_filepath: %s\n" json_filepath; *)
  json_filepath

let read_json_file (filepath:string) : string option =

  let json_filepath = check_root_dir filepath in

  try
    Printf.printf "Common.read_json_file %s\n" json_filepath;
    (* Read JSON file into an OCaml string *)
    let content : string = Core.Std.In_channel.read_all json_filepath in
    if ( String.length content != 0 )
    then
      Some content
    else
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "Common.read_json_file::ERROR::Empty_File::%s\n" json_filepath;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        None
      )
  with
  | Sys_error msg ->
      (
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        Printf.printf "Common.read_json_file::ERROR::File_Not_Found::%s\n" json_filepath;
        Printf.printf "Sys_error msg: %s\n" msg;
        Printexc.print_backtrace stderr;
        Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
        raise File_Not_Found
      )
  | Yojson.Json_error msg ->
     (
       Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
       Printf.printf "Common.read_json_file::ERROR::unexpected Yojson error when reading file::%s\n" json_filepath;
       Printf.printf "Yojson.Json_error msg: %s\n" msg;
       Printf.printf "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE\n";
       raise Unexpected_Error
     )

let print_callers_file (edited_file:Callers_t.file) (json_filepath:string) =

  let json_filepath : string = check_root_dir json_filepath in
  let jfile = Callers_j.string_of_file edited_file in
  Printf.printf "Common.print_callers_file:DEBUG: tries to write json file %s\n" json_filepath;
  Core.Std.Out_channel.write_all json_filepath jfile

let print_callers_dir (edited_dir:Callers_t.dir) (json_dirpath:string) =

  let json_dirpath : string = check_root_dir json_dirpath in
  let jdir = Callers_j.string_of_dir edited_dir in
  Printf.printf "Common.print_callers_dir:DEBUG: tries to write json dir %s\n" json_dirpath;
  Core.Std.Out_channel.write_all json_dirpath jdir

let print_callers_dir_symbols (dir_symbols:Callers_t.dir_symbols) (json_dirpath:string) =

  let json_dirpath : string = check_root_dir json_dirpath in
  let jdir = Callers_j.string_of_dir_symbols dir_symbols in
  Printf.printf "Common.print_callers_dir_symbols:DEBUG: tries to write json dir %s\n" json_dirpath;
  Core.Std.Out_channel.write_all json_dirpath jdir

(* let print_callgraph_file (edited_file:Callgraph_t.file) (json_filepath:string) = *)

(*   let json_filepath : string = check_root_dir json_filepath in *)
(*   let jfile = Callgraph_j.string_of_file edited_file in *)
(*   Printf.printf "Common.print_callgraph_file:DEBUG: tries to write json file %s\n" json_filepath; *)
(*   Core.Std.Out_channel.write_all json_filepath jfile *)

let print_callgraph_dir (edited_dir:Callgraph_t.dir) (json_dirpath:string) =

  let json_dirpath : string = check_root_dir json_dirpath in
  let jdir = Callgraph_j.string_of_dir edited_dir in
  Printf.printf "Common.print_callgraph_dir:DEBUG: tries to write json dir %s\n" json_dirpath;
  Core.Std.Out_channel.write_all json_dirpath jdir

(* Local Variables: *)
(* mode: tuareg *)
(* End: *)
