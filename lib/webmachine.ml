(*----------------------------------------------------------------------------
    Copyright (c) 2015 Inhabited Type LLC. All rights reserved.

    Proprietary and confidential.
  ----------------------------------------------------------------------------*)

open Cohttp

module Util = Wm_util

module type S = sig
  module IO : Cohttp.S.IO

  type 'body rd =
    { request : Request.t
    ; request_body : 'body
    ; response_headers : Header.t
    }

  type 'a r = [`Cont of 'a | `Halt of int]

  type ('a, 'body) op = 'body rd -> ('a r * 'body rd) IO.t
  type 'body provider = 'body rd -> ('body r * 'body rd) IO.t
  type 'body acceptor = (bool * 'body, 'body) op

  class virtual ['body] resource : object
    constraint 'body = [> `Empty]

    method virtual content_types_provided : ((string * ('body provider)) list, 'body) op
    method virtual content_types_accepted : ((string * ('body acceptor)) list, 'body) op

    method resource_exists : (bool, 'body) op
    method service_available : (bool, 'body) op
    method auth_required : (bool, 'body) op
    method is_authorized : (bool, 'body) op
    method forbidden : (bool, 'body) op
    method malformed_request : (bool, 'body) op
    method uri_too_long : (bool, 'body) op
    method known_content_type : (bool, 'body) op
    method valid_content_headers : (bool, 'body) op
    method valid_entity_length : (bool, 'body) op
    method options : ((string * string) list, 'body) op
    method allowed_methods : (Code.meth list, 'body) op
    method known_methods : (Code.meth list, 'body) op
    method delete_resource : ((bool * 'body), 'body) op
    method delete_completed : (bool, 'body) op
    method process_post : ((bool * 'body), 'body) op
    method language_available : (bool, 'body) op
    method charsets_provided : ((string * ('body -> 'body)) list, 'body) op
    method encodings_provided : ((string * ('body -> 'body)) list, 'body) op
    method variances : (string list, 'body) op
    method is_conflict : (bool, 'body) op
    method multiple_choices : (bool, 'body) op
    method previously_existed : (bool, 'body) op
    method moved_permanently : (Uri.t option, 'body) op
    method moved_temporarily : (Uri.t option, 'body) op
    method last_modified : (string option, 'body) op
    method expires : (string option, 'body) op
    method generate_etag : (string option, 'body) op
    method finish_request : (unit, 'body) op
  end

  type 'body handler =
    ?body:'body -> request:Request.t -> unit ->
    (Response.t * 'body * string list) IO.t

  val to_handler : resource:'body resource -> 'body handler

  val dispatch : (string * 'body handler) list -> 'body handler
end

module Make(IO:Cohttp.S.IO) = struct
  module IO = IO
  open IO

  type 'body rd =
    { request : Request.t
    ; request_body : 'body
    ; response_headers : Header.t
    }

  type 'a r = [`Cont of 'a | `Halt of int]

  type ('a, 'body) op = 'body rd -> ('a r * 'body rd) IO.t
  type 'body provider = 'body rd -> ('body r * 'body rd) IO.t
  type 'body acceptor = (bool * 'body, 'body) op

  let cont (a, b) = return (`Cont a, b)

  class virtual ['body] resource = object
    constraint 'body = [> `Empty]

    method virtual content_types_provided : ((string * ('body provider)) list, 'body) op
    method virtual content_types_accepted : ((string * ('body acceptor)) list, 'body) op

    method resource_exists (rd:'body rd) : (bool r * 'body rd) IO.t =
      cont (true, rd)
    method service_available (rd:'body rd) : (bool r * 'body rd) IO.t =
      cont (true, rd)
    method auth_required (rd:'body rd) : (bool r * 'body rd) IO.t =
      cont (true, rd)
    method is_authorized (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (true, rd)
    method forbidden (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (false, rd)
    method malformed_request (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (false, rd)
    method uri_too_long (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (false, rd)
    method known_content_type (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (true, rd)
    method valid_content_headers (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (true, rd)
    method valid_entity_length (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (true, rd)
    method options (rd :'body rd) : ((string * string) list r * 'body rd) IO.t =
      cont ([], rd)
    method allowed_methods (rd :'body rd) : (Code.meth list r * 'body rd) IO.t =
      cont ([ `GET; `HEAD ], rd)
    method known_methods (rd :'body rd) : (Code.meth list r * 'body rd) IO.t =
      cont ([`GET; `HEAD; `POST; `PUT; `DELETE; `Other "TRACE"; `Other "CONNECT"; `OPTIONS], rd)
    method delete_resource (rd :'body rd) : ((bool * 'body) r * 'body rd) IO.t =
      cont ((false, `Empty), rd)
    method delete_completed (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (true, rd)
    method process_post (rd :'body rd) : ((bool * 'body) r * 'body rd) IO.t =
      cont ((false, `Empty), rd)
    method language_available (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (true, rd)
    method charsets_provided (rd :'body rd) : ((string * ('body -> 'body)) list r * 'body rd) IO.t =
      cont ([], rd)
    method encodings_provided (rd :'body rd) : ((string * ('body -> 'body)) list r * 'body rd) IO.t =
      cont (["identity", fun x -> x], rd)
    method variances (rd :'body rd) : (string list r * 'body rd) IO.t =
      cont ([], rd)
    method is_conflict (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (false, rd)
    method multiple_choices (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (false, rd)
    method previously_existed (rd :'body rd) : (bool r * 'body rd) IO.t =
      cont (false, rd)
    method moved_permanently (rd :'body rd) : (Uri.t option r * 'body rd) IO.t =
      cont (None, rd)
    method moved_temporarily (rd :'body rd) : (Uri.t option r * 'body rd) IO.t =
      cont (None, rd)
    method last_modified (rd :'body rd) : (string option r * 'body rd) IO.t =
      cont (None, rd)
    method expires (rd :'body rd) : (string option r * 'body rd) IO.t =
      cont (None, rd)
    method generate_etag (rd :'body rd) : (string option r * 'body rd) IO.t =
      cont (None, rd)
    method finish_request (rd :'body rd) : (unit r * 'body rd) IO.t =
      cont ((), rd)

    (* Missing POST is not allowed rn. *

    method post_is_create (rd :'body rd) : (bool * 'body rd) IO.r =
      cont (false, rd)
    method allow_missing_post (rd :'body rd) : (bool * 'body rd) IO.r =
      cont (false, rd)
    method create_path (rd :'body rd) : (string * 'body rd) IO.r =
      cont ("", rd)
    *)
  end

  let (>>~) m f = m f

  class ['body] logic ~(resource:'body resource) ~request ?(body=`Empty) () = object(self)
    constraint 'body = [> `Empty]

    val resource = resource
    val mutable path = ([] : string list)
    val mutable rd =
      { request
      ; request_body = (body : [> `Empty])
      ; response_headers = Header.init ()
      }
    val mutable content_type = None
    val mutable charset = None
    val mutable encoding = None
    val mutable response_body = `Empty


    method private encode_body =
      let cf =
        match charset with
        | None        -> fun x -> x
        | Some (_, f) ->  f
      in
      let ef =
        match encoding with
        | None        -> fun x -> x
        | Some (_, f) -> f
      in
      response_body <- ef (cf response_body)

    (** [#meth] returns the [Code.meth] of the [Request.t] object. *)
    method private meth =
      rd.request.Request.meth

    method private set_response_header k v =
      rd <- { rd with response_headers =
        Header.replace rd.response_headers k v }

    method private get_request_header k =
      Header.get rd.request.Request.headers k

    method private get_response_header k =
      Header.get rd.response_headers k

    method private respond ~status ?body () =
      let body =
        match body with
        | None -> response_body
        | Some body -> body
      in
      self#run_op resource#finish_request
      >>~ fun () -> return (Response.make ~status (), body)

    method private halt code : (Response.t * 'body) IO.t =
      let status = Code.status_of_code code in
      self#respond ~status ~body:`Empty ()

    method private choose_charset acceptable k =
      let open Accept in
      (* Shadow the definition in Accept because it requires that you provide a
       * quality, which should not be included *)
      let string_of_charset = function
        | AnyCharset -> "*"
        | Charset c  -> c
      in
      let acceptable =
        List.map (fun (q, c) -> (q, string_of_charset c)) acceptable
      in
      (* XXX(seliopou): This breaks the {run_op} so watch out in the even that
       * this, or {run_op} must change behavior in order to keep them
       * consistent. *)
      resource#charsets_provided rd
      >>= function
        | `Cont [], rd' ->
          rd <- rd'; k`Any
        | `Cont provided, rd' ->
          rd <- rd';
          charset <- Util.choose provided acceptable "iso-885a-1";
          k (`One charset)
        | `Halt n, rd' ->
          rd <- rd';
          self#halt n

    method private choose_encoding acceptable k =
      let open Accept in
      (* Shadow the definition in Accept because it requires that you provide a
       * quality, which should not be included *)
      let string_of_encoding = function
        | AnyEncoding -> "*"
        | Encoding e  -> e
        | Identity    -> "identity"
        | Gzip        -> "gzip"
        | Compress    -> "compress"
        | Deflate     -> "deflate"
      in
      let acceptable =
        List.map (fun (q, c) -> (q, string_of_encoding c)) acceptable
      in
      resource#encodings_provided rd
      >>= function
        | `Cont encodings, rd' ->
          rd <- rd';
          encoding <- Util.choose encodings acceptable "identity";
          k encoding
        | `Halt n, rd' ->
          rd <- rd';
          self#halt n

    (** [run_op op] runs [op] with the current request and response
        information, and will perform any appropriate bookkeeping that needs to
        be done given the result. *)
    method private run_op : 'a. ('a, 'body) op -> ('a -> (Response.t * 'body) IO.t) -> (Response.t * 'body) IO.t =
      fun op k -> op rd
        >>= function
          | `Cont a, rd' -> rd <- rd'; k a
          | `Halt n, rd' -> rd <- rd'; self#halt n

    method private run_provider : 'body provider -> _ -> (Response.t * 'body) IO.t =
      fun provider k ->
        provider rd
        >>= function
          | `Cont body', rd' ->
            response_body <- body;
            rd <- rd';
            k ()
          | `Halt n    , rd' ->
            rd <- rd';
            self#halt n

    method private accept_helper k =
      let header =
        match self#get_request_header "content-type" with
        | None       -> Some "application/octet-stream"
        | Some type_ -> Some type_
      in
      self#run_op resource#content_types_accepted
      >>~ fun provided ->
        match Util.MediaType.match_header provided header with
        | None                -> self#halt 415
        | Some(_, of_content) ->
          self#run_op of_content
          >>~ function (complete, body) ->
            response_body <- body;
            if complete then
              self#encode_body;
            k complete

    method private d state =
      path <- state :: path

    method run : (Response.t * 'body * string list) IO.t =
      self#v3b13 >>= fun (resp, body) -> return (resp, body, List.rev path)

    method v3b13 : (Response.t * 'body) IO.t =
      self#d "v3b13";
      self#run_op resource#service_available
      >>~ function
        | true  -> self#v3b12
        | false -> self#halt 503

    method v3b12 : (Response.t * 'body) IO.t =
      self#d "v3b12";
      let meth = self#meth in
      self#run_op resource#known_methods
      >>~ fun (meths:Code.meth list) ->
        if List.exists (fun x -> Code.compare_method meth x = 0) meths
          then self#v3b11
          else self#halt 501

    method v3b11 : (Response.t * 'body) IO.t =
      self#d "v3b11";
      self#run_op resource#uri_too_long
      >>~ function
        | true  -> self#halt 414
        | false -> self#v3b10

    method v3b10 : (Response.t * 'body) IO.t =
      self#d "v3b10";
      let meth = self#meth in
      self#run_op resource#allowed_methods
      >>~ fun (meths:Code.meth list) ->
        if List.exists (fun x -> Code.compare_method meth x = 0) meths
          then self#v3b9
          else self#halt 405

    method v3b9 : (Response.t * 'body) IO.t =
      self#d "v3b9";
      self#run_op resource#malformed_request
      >>~ function
        | true  -> self#halt 400
        | false -> self#v3b8

    method v3b8 : (Response.t * 'body) IO.t =
      self#d "v3b8";
      self#run_op resource#is_authorized
      >>~ function
        | true   -> self#v3b7
        | false  -> self#halt 401

    method v3b7 : (Response.t * 'body) IO.t =
      self#d "v3b7";
      self#run_op resource#forbidden
      >>~ function
        | true  -> self#halt 403
        | false -> self#v3b6

    method v3b6 : (Response.t * 'body) IO.t =
      self#d "v3b6";
      self#run_op resource#valid_content_headers
      >>~ function
        | true  -> self#v3b5
        | false -> self#halt 501

    method v3b5 : (Response.t * 'body) IO.t =
      self#d "v3b5";
      self#run_op resource#known_content_type
      >>~ function
        | true  -> self#v3b4
        | false -> self#halt 415

    method v3b4 : (Response.t * 'body) IO.t =
      self#d "v3b4";
      self#run_op resource#valid_entity_length
      >>~ function
        | true  -> self#v3b3
        | false -> self#halt 413

    method v3b3 : (Response.t * 'body) IO.t =
      self#d "v3b3";
      match self#meth with
      | `OPTIONS ->
        self#run_op resource#options
        >>~ fun headers ->
          List.iter (fun (k, v) -> self#set_response_header k v) headers;
          self#respond ~status:`OK ()
      | _ -> self#v3c3

    method v3c3 : (Response.t * 'body) IO.t =
      self#d "v3c3";
      self#run_op resource#content_types_provided
      >>~ fun content_types ->
        match self#get_request_header "accept" with
        | None   ->
          begin match content_types with
          | []   -> self#halt 500
          | t::_ ->
            content_type <- Some t;
            self#v3d4
          end
        | Some _ -> self#v3c4

    method v3c4 : (Response.t * 'body) IO.t =
      self#d "v3c4";
      self#run_op resource#content_types_provided
      >>~ fun content_types ->
        let header = self#get_request_header "accept" in
        match Util.MediaType.match_header content_types header with
        | None   -> self#halt 406
        | Some t ->
          content_type <- Some t;
          self#v3d4

    method v3d4 : (Response.t * 'body) IO.t =
      self#d "v3d4";
      match self#get_request_header "accept-language" with
      | None   -> self#v3e5
      | Some _ -> self#v3d5

    method v3d5 : (Response.t * 'body) IO.t =
      self#d "v3d5";
      self#run_op resource#language_available
      >>~ function
        | true  -> self#v3e5
        | false -> self#halt 406

    method v3e5 : (Response.t * 'body) IO.t =
      self#d "v3e5";
      match self#get_request_header "accept-charset" with
      | None   ->
        begin self#choose_charset (Accept.charsets None)
        >>~ function
          | `Any
          | `One (Some _) -> self#v3f6
          | `One None     -> self#halt 406
        end
      | Some _ -> self#v3e6

    method v3e6 : (Response.t * 'body) IO.t =
      self#d "v3e6";
      match self#get_request_header "accept-charset" with
      | None            -> assert false
      | Some acceptable ->
        begin self#choose_charset (Accept.charsets (Some acceptable))
        >>~ function
          | `Any
          | `One (Some _) -> self#v3f6
          | `One None     -> self#halt 406
        end

    method v3f6 : (Response.t * 'body) IO.t =
      self#d "v3f6";
      let type_ =
        match content_type with
        | None            -> assert false
        | Some (type_, _) -> type_
      in
      let value = match charset with
      | None             -> type_
      | Some (charset,_) -> Printf.sprintf "%s; charset=%s" type_ charset
      in
      self#set_response_header "Content-Type" value;
      match self#get_request_header "accept-encoding" with
      | None ->
        let acceptable = Accept.encodings (Some "identity;q=1.0,*;q=0.5") in
        self#choose_encoding acceptable >>~ fun chosen ->
        begin match chosen with
        | None   -> self#halt 406
        | Some _ -> self#v3g7
        end
      | Some _ -> self#v3f7

    method v3f7 : (Response.t * 'body) IO.t =
      self#d "v3f7";
      match self#get_request_header "accept-encoding" with
      | None            -> assert false
      | Some acceptable ->
        let acceptable = Accept.encodings (Some acceptable) in
        self#choose_encoding acceptable >>~ fun chosen ->
        begin match chosen with
        | None   -> self#halt 406
        | Some _ -> self#v3g7
        end

    method v3g7 : (Response.t * 'body) IO.t =
      self#d "v3g7";
      self#run_op resource#variances >>~ fun variances ->
      self#set_response_header "Vary" (String.concat ", " variances);
      self#run_op resource#resource_exists
      >>~ function
        | true  -> self#v3g8
        | false -> self#v3h7

    method v3g8 : (Response.t * 'body) IO.t =
      self#d "v3g8";
      match self#get_request_header "if-match" with
      | None   -> self#v3h10
      | Some _ -> self#v3g9

    method v3g9 : (Response.t * 'body) IO.t =
      self#d "v3g9";
      match self#get_request_header "if-match" with
      | None     -> assert false
      | Some "*" -> self#v3h10
      | Some _   -> self#v3g11

    method v3g11 : (Response.t * 'body) IO.t =
      self#d "v3g11";
      match self#get_request_header "if-match" with
      | None      -> assert false
      | Some etag ->
        self#run_op resource#generate_etag
        >>~ fun header ->
          begin match List.mem etag (Util.ETag.from_header header) with
          | true  -> self#v3h10
          | false -> self#halt 412
          end

    method v3h7 : (Response.t * 'body) IO.t =
      self#d "v3h7";
      match self#get_request_header "if-match" with
      | None   -> self#v3i7
      | Some _ -> self#halt 412

    method v3h10 : (Response.t * 'body) IO.t =
      self#d "v3h10";
      match self#get_request_header "if-unmodified-since" with
      | None   -> self#v3i12
      | Some _ -> self#v3h11

    method v3h11 : (Response.t * 'body) IO.t =
      self#d "v3h11";
      failwith "NYI: v3h11"

    method v3h12 : (Response.t * 'body) IO.t =
      self#d "v3h12";
      failwith "NYI: v3h12"

    method v3i4 : (Response.t * 'body) IO.t =
      self#d "v3i4";
      self#run_op resource#moved_permanently
      >>~ function
        | None     -> self#v3p3
        | Some uri ->
          self#set_response_header "Location" (Uri.to_string uri);
          self#respond ~status:`Moved_permanently ()

    method v3i7 : (Response.t * 'body) IO.t =
      self#d "v3i7";
      match self#meth with
      | `OPTIONS -> assert false
      | `PUT     -> self#v3i4
      | _        -> self#v3k7

    method v3i12 : (Response.t * 'body) IO.t =
      self#d "v3i12";
      match self#get_request_header "if-none-match" with
      | None   -> self#v3l13
      | Some _ -> self#v3i13

    method v3i13 : (Response.t * 'body) IO.t =
      self#d "v3i13";
      match self#get_request_header "if-none-match" with
      | None     -> assert false
      | Some "*" -> self#v3j18
      | Some _   -> self#v3k13

    method v3k7 : (Response.t * 'body) IO.t =
      self#d "v3k7";
      self#run_op resource#previously_existed
      >>~ function
        | true  -> self#v3k5
        | false -> self#v3l7

    method v3k5 : (Response.t * 'body) IO.t =
      (* XXX(seliopou): For now, no POSTs to non-existent resources allowed. *)
      self#d "v3k5";
      self#run_op resource#moved_permanently
      >>~ function
        | None     -> self#v3l5
        | Some uri ->
          self#set_response_header "Location" (Uri.to_string uri);
          self#respond ~status:`Moved_permanently ()

    method v3k13 : (Response.t * 'body) IO.t =
      self#d "v3k13";
      match self#get_request_header "if-none-match" with
      | None      -> assert false
      | Some etag ->
        self#run_op resource#generate_etag
        >>~ fun header ->
          begin match List.mem etag (Util.ETag.from_header header) with
          | true  -> self#v3j18
          | false -> self#v3l13
          end

    method v3l5 : (Response.t * 'body) IO.t =
      (* XXX(seliopou): For now, no POSTs to non-existent resources allowed. *)
      self#d "v3l5";
      self#run_op resource#moved_temporarily
      >>~ function
        | None     -> self#halt 410
        | Some uri ->
          self#set_response_header "Location" (Uri.to_string uri);
          self#respond ~status:`Temporary_redirect ()

    method v3l7 : (Response.t * 'body) IO.t =
      (* XXX(seliopou): For now, no POSTs to non-existent resources allowed. *)
      self#d "v3l7";
      match self#meth with
      | `OPTIONS -> assert false
      | _        -> self#halt 404

    method v3l13 : (Response.t * 'body) IO.t =
      self#d "v3l13";
      match self#get_request_header "if-modified-since" with
      | None   -> self#v3m16
      | Some _ -> self#v3l14

    method v3l14 : (Response.t * 'body) IO.t =
      self#d "v3l14";
      failwith "NYI: v3l14"

    method v3j18 =
      self#d "v3j18";
      match self#meth with
      | `GET | `HEAD -> self#halt 304
      | _            -> self#halt 412

    method v3m16 =
      self#d "v3m16";
      match self#meth with
      | `OPTIONS -> assert false
      | `DELETE  -> self#v3m20
      | _        -> self#v3n16

    method v3m20 =
      self#d "v3m20";
      self#run_op resource#delete_resource
      >>~ fun (deleted, body') ->
        response_body <- body';
        if deleted then
          self#run_op resource#delete_completed
          >>~ function
            | true  -> self#v3o20
            | false -> self#respond ~status:`Accepted ()
        else
          self#halt 500

    method v3n11 =
      self#d "v3n11";
      self#run_op resource#process_post
      >>~ fun (executed, body') ->
        if executed then begin
          response_body <- body';
          self#encode_body;
          match self#get_response_header "location" with
          | None   -> self#v3p11
          | Some _ -> self#respond ~status:`See_other ()
        end else
          self#halt 500

    method v3n16 =
      self#d "v3n16";
      match self#meth with
      | `OPTIONS | `DELETE -> assert false
      | `POST -> self#v3n11
      | _     -> self#v3o16

    method v3o14 =
      self#d "v3o14";
      self#run_op resource#is_conflict
      >>~ function
        | true  -> self#halt 409
        | false -> self#accept_helper (fun _ -> self#v3p11)

    method v3o16 =
      self#d "v3o16";
      match self#meth with
      | `OPTIONS | `DELETE | `POST -> assert false
      | `PUT -> self#v3o14
      | _    -> self#v3o18

    method v3o18 =
      self#d "v3o18";
      match self#meth with
      | `OPTIONS | `DELETE | `POST | `PUT -> assert false
      | _    ->
        let _, to_content =
          match content_type with
          | None   -> assert false
          | Some x -> x
        in
        self#run_op resource#generate_etag >>~ fun etag ->
          begin match etag with
          | None -> ()
          | Some etag -> self#set_response_header "ETag" (Util.ETag.escape etag)
          end;
          (* XXX(seliopou) last modified *)
          (* XXX(seliopou) expires *)
          self#run_provider to_content >>~ fun () ->
          self#encode_body;
          self#run_op resource#multiple_choices
          >>~ function
            | true  -> self#halt 300
            | false -> self#respond ~status:`OK ()

    method v3o20 =
      self#d "v3o20";
      match body with
      | `Empty -> self#v3o18
      | _      -> self#respond ~status:`No_content ()

    method v3p3 =
      self#d "v3p3";
      self#run_op resource#is_conflict
      >>~ function
        | true  -> self#halt 409
        | false -> self#accept_helper (fun _ -> self#v3p11)

    method v3p11 =
      self#d "v3p11";
      match self#get_response_header "location" with
      | None   -> self#v3o20
      | Some _ -> self#respond ~status:`Created ()
  end

  type 'body handler =
    ?body:'body -> request:Request.t -> unit ->
    (Response.t * 'body * string list) IO.t

  let to_handler ~resource ?body ~request () =
    let logic = new logic ~resource ~request ?body () in
    logic#run
  ;;

  let dispatch routes =
    let table =
      List.map (fun (p, h) -> Re_posix.(compile (re ("^" ^ p)), h)) routes
    in
    let rec loop ~path ?body ~request = function
      | []                     ->
        raise Not_found
      | (re, handler)::tbl ->
        if Re.execp re path
          then handler ?body ~request ()
          else loop ~path ?body ~request tbl
    in
    fun ?body ~request () ->
      let path = Uri.path (Cohttp.Request.uri request) in
      loop ~path ?body ~request table
end
