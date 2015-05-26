(*
 * Copyright (c) 2012-2015 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013-2015 Thomas Gazagnaire <thomas@gazazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

open Lwt
open Sexplib.Conv

module Client (Conduit:Conduit_mirage.S) = struct

  module Channel = Channel.Make(Conduit.Flow)
  module HTTP_IO = Cohttp_mirage_io.Make(Channel)

  module Net_IO = struct

    module IO = HTTP_IO

    type 'a io = 'a Lwt.t
    type ic = Channel.t
    type oc = Channel.t
    type flow = Conduit.flow

    type ctx = {
      resolver: Resolver_lwt.t;
      ctx: Conduit.ctx;
    } with sexp_of

    let default_ctx =
      { resolver = Resolver_mirage.localhost;
        ctx = Conduit.default_ctx }

    let connect_uri ~ctx uri =
      Resolver_lwt.resolve_uri ~uri ctx.resolver
      >>= fun endp ->
      Conduit.endp_to_client ~ctx:ctx.ctx endp
      >>= fun client ->
      Conduit.connect ~ctx:ctx.ctx client
      >>= fun (flow,ic,oc) ->
      let ch = Channel.create flow in
      return (flow, ch, ch)

    let close_in ic = ()
    let close_out ic = ()
    let close ic oc = ignore_result (Channel.close ic)

  end
  let ctx resolver ctx = { Net_IO.resolver; ctx }
  (* Build all the core modules from the [Cohttp_lwt] functors *)
  module XRequest = Cohttp_lwt.Make_request(HTTP_IO)
  module XResponse = Cohttp_lwt.Make_response(HTTP_IO)
  include Cohttp_lwt.Make_client(HTTP_IO)(XRequest)(XResponse)(Net_IO)

end

module Server (Flow: V1_LWT.FLOW) = struct

  module Channel = Channel.Make(Flow)
  module HTTP_IO = Cohttp_mirage_io.Make(Channel)
  module XRequest = Cohttp_lwt.Make_request(HTTP_IO)
  module XResponse = Cohttp_lwt.Make_response(HTTP_IO)
  include Cohttp_lwt.Make_server(HTTP_IO)(XRequest)(XResponse)

  let listen spec flow =
    let ch = Channel.create flow in
    callback spec flow ch ch

end
