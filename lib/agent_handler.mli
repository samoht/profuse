(*
 * Copyright (c) 2014 David Sheets <sheets@alum.mit.edu>
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

type 'a result =
| Ok of 'a
| Unix_error of Unix.error * string * string
| Err of exn

type fd = Unix.file_descr
type 'a perspective = uid:int32 -> gid:int32 -> 'a
type t = {
  mkdir  : (string -> int32 -> unit) perspective;
  mknod  : (string -> int32 -> int32 -> unit) perspective;
  access : (string -> Unix.access_permission list -> unit) perspective;
  chown  : (string -> int32 -> int32 -> unit) perspective;
  rmdir  : (string -> unit) perspective;
  open_  : (string -> Unix.open_flag list -> int32 -> fd) perspective;
}

val create : unit -> t
