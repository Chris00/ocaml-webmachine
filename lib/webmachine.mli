(*----------------------------------------------------------------------------
    Copyright (c) 2015 Inhabited Type LLC. All rights reserved.

    Proprietary and confidential.
  ----------------------------------------------------------------------------*)

open Cohttp

(** The [IO] module signature abstracts over monadic futures library. It is a
    much reduced version of the module signature that appears in Cohttp, and as
    such is compatible with any module that conforms to [Cohttp.S.IO]. *)
module type IO = sig
  type +'a t
  (** The type of a blocking computation *)

  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  (** The monadic bind operator for the type ['a t]. [m >>= f] will pass the
      result of [m] to [f], once the result is determined. *)

  val return : 'a -> 'a t
  (** [return a] creates a value of type ['a t] that is already determined. *)
end

(** The [Rd] module is the means by which handlers access and manipulate
    request-specific information. *)
module Rd : sig
  type 'body t =
    { version       : Code.version
    ; meth          : Code.meth
    ; uri           : Uri.t
    ; req_headers   : Header.t
    ; req_body      : 'body
    ; resp_headers  : Header.t
    ; resp_body     : 'body
    ; dispatch_path : string
    ; path_info     : (string * string) list
    } constraint 'body = [> `Empty]

  val make : ?dispatch_path:string -> ?path_info:(string * string) list
    -> ?resp_headers:Header.t -> ?resp_body:'a
    -> ?req_body:'a -> request:Request.t
    -> unit -> 'a t
  (** [make ~request ()] returns a ['body t] with the following fields
      pouplated from the [request] argument:
      {ul
      {- [uri]};
      {- [version]};
      {- [meth]}; and
      {- [req_headers]}}.

      All other fields will be populated with default values unless they are
      provided as optional arguments *)

  val with_req_headers  : (Header.t -> Header.t) -> 'a t -> 'a t
  (** [with_req_headers f t] is equivalent to [{ t with req_headers = f (t.req_headers) }] *)

  val with_resp_headers : (Header.t -> Header.t) -> 'a t -> 'a t
  (** [with_resp_headers f t] is equivalent to [{ t with resp_headers = f (t.resp_headers) }] *)

  val lookup_path_info      : string -> 'a t -> string option
  val lookup_path_info_exn  : string -> 'a t -> string
  (** [lookup_path_info_exn k t] is equivalent [List.assoc k t.path_info],
      which will throw a [Not_found] exception if the lookup fails. The
      non-[_exn] version will return an optional result. *)
end

module type S = sig
  module IO : IO

  type 'a result =
    | Ok of 'a
    | Error of int

  type ('a, 'body) op = 'body Rd.t -> ('a result * 'body Rd.t) IO.t
  type 'body provider = ('body, 'body) op
  type 'body acceptor = (bool, 'body) op

  val continue : 'a -> ('a, 'body) op
  val respond : ?body:'body -> int -> ('a, 'body) op

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
    method delete_resource : (bool, 'body) op
    method delete_completed : (bool, 'body) op
    method process_post : (bool, 'body) op
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

  val to_handler :
    resource:('body resource) -> body:'body -> request:Request.t ->
    (Code.status_code * Header.t * 'body * string list) IO.t

  val dispatch' :
    (string * (unit -> 'body resource)) list ->
    body:'body -> request:Request.t ->
    (Code.status_code * Header.t * 'body * string list) option IO.t

  val dispatch :
    ([`M of string | `L of string] list * bool * (unit -> 'body resource)) list ->
    body:'body -> request:Request.t ->
    (Code.status_code * Header.t * 'body * string list) option IO.t
end

module Make(IO:IO) : S
  with module IO = IO
