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

(** Test schema and generator
    @author Sylvain Le Gall
  *)

(* END EXPORT *)

open OASISTypes
open OASISSchema
open OASISValues
open OASISUtils
open OASISGettext

let schema, generator =
  let schm =
   schema "Document"
  in
  let cmn_section_gen =
    OASISSection.section_fields 
      (fun () -> (s_ "document")) schm
      (fun (cs, _) -> cs)
  in
  let build_tools = 
    OASISBuildSection_intern.build_tools_field schm
      (fun (_, doc) -> doc.doc_build_tools)
  in
  let typ =
    new_field_plugin schm "Type"
      ~default:(OASISPlugin.builtin `Doc "none") 
      `Doc
      OASISPlugin.Doc.value
      (fun () ->
         s_ "Plugin to use to build documentation.")
      (fun (_, doc) -> doc.doc_type)
  in
  let custom =
    OASISCustom.add_fields schm ""
      (fun () -> s_ "Command to run before building the doc.")
      (fun () -> s_ "Command to run after building the doc.")
      (fun (_, doc) -> doc.doc_custom)
  in
  let title =
    new_field schm "Title"
      string_not_empty
      (fun () ->
         s_ "Title of the document.")
      (fun (_, doc) -> doc.doc_title)
  in
  let authors =
    new_field schm "Authors"
      ~default:[]
      (comma_separated string_not_empty)
      (fun () ->
         s_ "Authors of the document.")
      (fun (_, doc) -> doc.doc_authors)
  in
  let abstract =
    new_field schm "Abstract"
      ~default:None
      (opt string_not_empty)
      (fun () ->
         s_ "Short paragraph giving an overview of the document.")
      (fun (_, doc) -> doc.doc_abstract)
  in
  let doc_format =
    new_field schm "Format"
      ~default:OtherDoc
      (choices 
         (fun () -> "document format")
         ["HTML",       HTML "index.html";
          "Text",       DocText;
          "PDF",        PDF;
          "PostScript", PostScript;
          "Info",       Info "invalid.info";
          "DVI",        DVI;
          "Other",      OtherDoc])
      (fun () ->
         s_ "Format for the document.")
      (fun (_, doc) -> doc.doc_format)
  in
  let index =
    new_field schm "Index"
      ~default:None
      (opt file)
      (fun () ->
         s_ "Index or top-level file for the document, only apply to \
             HTML and Info.")
      (fun (_, doc) -> 
         match doc.doc_format with 
           | HTML idx | Info idx ->
               Some idx
           | DocText | PDF | PostScript | DVI | OtherDoc ->
               None)
  in
  let install_dir =
    new_field schm "InstallDir"
      ~default:None
      (opt (expandable file))
      (fun () ->
         s_ "Default target directory to install data and documentation.")
      (fun (_, doc) -> Some doc.doc_install_dir)
  in
  let build, install, data_files = 
   OASISBuildSection_intern.build_install_data_fields schm
     (fun (_, doc) -> doc.doc_build)
     (fun (_, doc) -> doc.doc_install)
     (fun (_, doc) -> doc.doc_data_files)
  in
    schm,
    (fun nm data ->
       Doc
         (cmn_section_gen nm data,
          (* TODO: find a way to code that in a way compatible with 
           * quickstart
           *)
          let doc_format =
            match doc_format data with 
              | HTML _ ->
                  begin
                    match index data with
                      | Some fn -> HTML fn
                      | None ->
                          failwithf1
                            (f_ "Index is mandatory for format HTML in \
                                 document %s")
                            nm
                  end
              | Info fn ->
                  begin
                    match index data with
                      | Some fn -> Info fn
                      | None ->
                          failwithf1
                            (f_ "Index is mandatory for format info in \
                                 document %s")
                            nm
                  end
              | DocText | PDF | PostScript | DVI | OtherDoc as fmt ->
                  fmt
          in
          let doc_install_dir =
            match install_dir data with
              | None ->
                  begin
                    match doc_format with
                      | HTML _     -> "$htmldir"
                      | DocText    -> "$docdir"
                      | PDF        -> "$pdfdir"
                      | PostScript -> "$psdir"
                      | Info _     -> "$infodir"
                      | DVI        -> "$dvidir"
                      | OtherDoc   -> "$docdir"
                  end
              | Some dir ->
                  dir
          in
            {
              doc_type        = typ data;
              doc_custom      = custom data;
              doc_build       = build data;
              doc_install     = install data;
              doc_install_dir = doc_install_dir;
              doc_title       = title data;
              doc_authors     = authors data;
              doc_abstract    = abstract data;
              doc_format      = doc_format;
              doc_data_files  = data_files data;
              doc_build_tools = build_tools data;
            }))
