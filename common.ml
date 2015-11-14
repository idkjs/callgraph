(******************************************************************************)
(*   Copyright (C) 2014-2015 THALES Communication & Security                  *)
(*   All Rights Reserved                                                      *)
(*   KTD SCIS 2014-2015                                                       *)
(*   Use Case Legacy TOSA                                                     *)
(*   author: Hugues Balp                                                      *)
(*                                                                            *)
(******************************************************************************)

exception Missing_Options

exception Untested
exception Not_Yet_Implemented
exception Not_Implemented
exception Internal_Error
exception Debug
exception Invalid_argument
exception Already_Existing
exception Already_Configured
exception IncompatibleType
exception Missing_Input_Source_File
exception Malformed_Filename

(* exception Dbg_16 *)
(* exception Dbg_17 *)
(* exception Dbg_18 *)
(* exception Dbg_19 *)
(* exception Dbg_20 *)

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
   | None
   | Some (0,_) ->
     ( 
       (* Printf.printf *)
       (* "read_after_first: not found pattern \"%c\" in name \"%s\", so return the full name\n" patt name; *)
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
    "DBG file: \"%s\", ext: \"%s\"\n" filename fileext;
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

(* Local Variables: *)
(* mode: tuareg *)
(* End: *)
