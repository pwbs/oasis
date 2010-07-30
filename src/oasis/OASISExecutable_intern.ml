(********************************************************************************)
(*  OASIS: architecture for building OCaml libraries and applications           *)
(*                                                                              *)
(*  Copyright (C) 2008-2010, OCamlCore SARL                                     *)
(*                                                                              *)
(*  This library is free software; you can redistribute it and/or modify it     *)
(*  under the terms of the GNU Lesser General Public License as published by    *)
(*  the Free Software Foundation; either version 2.1 of the License, or (at     *)
(*  your option) any later version, with the OCaml static compilation           *)
(*  exception.                                                                  *)
(*                                                                              *)
(*  This library is distributed in the hope that it will be useful, but         *)
(*  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  *)
(*  or FITNESS FOR A PARTICULAR PURPOSE. See the file COPYING for more          *)
(*  details.                                                                    *)
(*                                                                              *)
(*  You should have received a copy of the GNU Lesser General Public License    *)
(*  along with this library; if not, write to the Free Software Foundation,     *)
(*  Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA               *)
(********************************************************************************)

(** Executable schema and generator
    @author Sylvain Le Gall
  *)

open OASISTypes
open OASISSchema
open OASISValues
open OASISUtils
open OASISGettext
open PropList.Field

let schema, generator =
  let schm =
    schema "Executable" 
  in
  let cmn_section_gen =
    OASISSection.section_fields (fun () -> (s_ "executable")) schm
  in
  let build_section_gen =
    OASISBuildSection_intern.section_fields (fun () -> (s_ "executable")) Byte schm
  in
  let main_is =
    new_field schm "MainIs" 
      (let base_value =
         regexp
           (Pcre.regexp ".*\\.ml$")
           (fun () -> s_ ".ml file")
       in
         {
           parse  = (fun ~ctxt str -> 
                       file.parse ~ctxt 
                         (base_value.parse ~ctxt str));
           update = update_fail;
           print  = (fun fn -> file.print (base_value.print fn));
         })
      (fun () -> 
         s_ "OCaml file (.ml) containing main procedure for the executable.")
  in
  let custom =
    new_field schm "Custom"
      ~default:false
      boolean
      (fun () ->
         s_ "Create custom bytecode executable.")
  in
    schm,
    (fun nm data -> 
       Executable
         (cmn_section_gen nm data,
          build_section_gen nm data,
          {
            exec_main_is = main_is data;
            exec_custom  = custom data;
          }))