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

open Ctypes
open Unsigned
open View
open Fuse

type 'a request = 'a In_common.request
type 'a reply = 'a Out_common.reply
type hdr = Out_common.Hdr.t

module type GEN_READ = sig
  val deserialize :
    parse:('a request -> hdr structure -> int -> unit ptr -> 'b reply) ->
    'a request -> int -> char ptr -> 'b reply
end

module type READ = sig
  type t

  val deserialize    : 'a request -> int -> char ptr -> t reply
  val describe_reply : t reply -> string
end

module type WRITE = sig
  val write_reply_raw : _ request -> int -> char ptr -> unit
  val write_reply     : 'b request -> ('b request -> char carray) -> unit
  val write_ack       : 'b request -> unit
  val write_error     : _ request -> Unix.error -> unit

  val trace_channel   : out_channel
end

module type GEN_IO = sig
  include GEN_READ
  include WRITE
end

module type IO = sig
  include READ
  include WRITE
end

module type LINUX_7_8_PROTO = sig
  include module type of Out_common
  include module type of Out_linux_7_8
end
  with module Hdr  = Out_common.Hdr
  and  module Open = Out_common.Open

module Linux_7_8_wire = struct
  (* TODO: include optional raw bufs for non-conforming replies *)
  type t =
  | Init    of Out_common.Init.t     structure
  | Getattr of Out_linux_7_8.Attr.t  structure
  | Lookup  of Out_linux_7_8.Entry.t structure
  | Opendir of Out_common.Open.t     structure
  | Readdir of Out_common.Read.t     structure
  | Releasedir
  | Fsyncdir (* TODO: do *)
  | Rmdir
  | Mkdir   of Out_linux_7_8.Entry.t structure
  | Getxattr (* TODO: do *)
  | Setxattr (* TODO: do *)
  | Listxattr (* TODO: do *)
  | Removexattr (* TODO: do *)
  | Access
  | Forget (* TODO: should never happen? *)
  | Readlink of string
  | Open     of Out_common.Open.t       structure
  | Read     of Out_common.Read.t       structure
  | Write    of Out_common.Write.t      structure
  | Statfs   of Struct_common.Kstatfs.t structure
  | Flush
  | Release
  | Fsync
  | Unlink
  | Create   of Out_linux_7_8.Create.t  structure
  | Mknod    of Out_linux_7_8.Entry.t   structure
  | Setattr  of Out_linux_7_8.Attr.t    structure
  | Link     of Out_linux_7_8.Entry.t   structure
  | Symlink  of Out_linux_7_8.Entry.t   structure
  | Rename   of Out_linux_7_8.Entry.t   structure
  | Getlk (* TODO: do *)
  | Setlk (* TODO: do *)
  | Setlkw (* TODO: do *)
  | Interrupt (* TODO: do *)
  | Bmap (* TODO: do *)
  | Destroy
  | Other    of Opcode.t
  | Unknown  of int * int * unit ptr
end

module type LINUX_7_8_WIRE = sig
  type t = Linux_7_8_wire.t

  val parse : 'a request -> hdr structure -> int -> unit ptr -> t reply
end

module type LINUX_7_8 = sig
  include LINUX_7_8_PROTO
  include LINUX_7_8_WIRE

  include IO with type t := t
end

module type OSX_7_8_PROTO = sig
  include module type of Out_common
  include module type of Out_osx_7_8
end
  with module Hdr  = Out_common.Hdr
  and  module Open = Out_common.Open

module Osx_7_8_wire = struct
  (* TODO: include optional raw bufs for non-conforming replies *)
  type t =
  | Init    of Out_common.Init.t   structure
  | Getattr of Out_osx_7_8.Attr.t  structure
  | Lookup  of Out_osx_7_8.Entry.t structure
  | Opendir of Out_common.Open.t   structure
  | Readdir of Out_common.Read.t   structure
  | Releasedir
  | Fsyncdir (* TODO: do *)
  | Rmdir
  | Mkdir   of Out_osx_7_8.Entry.t structure
  | Getxattr (* TODO: do *)
  | Setxattr (* TODO: do *)
  | Listxattr (* TODO: do *)
  | Removexattr (* TODO: do *)
  | Access
  | Forget (* TODO: should never happen? *)
  | Readlink of string
  | Open     of Out_common.Open.t       structure
  | Read     of Out_common.Read.t       structure
  | Write    of Out_common.Write.t      structure
  | Statfs   of Struct_common.Kstatfs.t structure
  | Flush
  | Release
  | Fsync
  | Unlink
  | Create   of Out_osx_7_8.Create.t    structure
  | Mknod    of Out_osx_7_8.Entry.t     structure
  | Setattr  of Out_osx_7_8.Attr.t      structure
  | Link     of Out_osx_7_8.Entry.t     structure
  | Symlink  of Out_osx_7_8.Entry.t     structure
  | Rename   of Out_osx_7_8.Entry.t     structure
  | Getlk (* TODO: do *)
  | Setlk (* TODO: do *)
  | Setlkw (* TODO: do *)
  | Interrupt (* TODO: do *)
  | Bmap (* TODO: do *)
  | Destroy
  | Other    of Opcode.t
  | Unknown  of int * int * unit ptr
end

module type OSX_7_8_WIRE = sig
  type t = Osx_7_8_wire.t

  val parse : 'a request -> hdr structure -> int -> unit ptr -> t reply
end

module type OSX_7_8 = sig
  include OSX_7_8_PROTO
  include OSX_7_8_WIRE

  include IO with type t := t
end

module type LINUX_7_8_OVER_OSX_7_8 = sig
  include LINUX_7_8_PROTO
  include OSX_7_8_WIRE

  include IO with type t := t
end

module type OSX_7_8_OVER_LINUX_7_8 = sig
  include OSX_7_8_PROTO
  include LINUX_7_8_WIRE

  include IO with type t := t
end

module Io : GEN_IO = struct
  module Hdr = Out_common.Hdr

  let write_reply_raw req sz ptr =
    let len = Fuse.(
      try
        Unix_unistd.write req.chan.fd (to_voidp ptr) sz
      with Unix.Unix_error(err,fn,param) ->
        raise (ProtocolError
                 (req.chan,
                  (Printf.sprintf "Unix Error on %s(%S): %s" fn param
                     (Unix.error_message err))))
    )
    in
    if sz <> len
    then raise Fuse.(
      ProtocolError
        (req.chan,
         (Printf.sprintf "Tried to write %d but only wrote %d" sz len)))

  let write_reply req arrfn =
    let arr = arrfn req in
    let sz  = CArray.length arr + Hdr.hdrsz in
    let ptr = CArray.start arr -@ Hdr.hdrsz in
    write_reply_raw req sz ptr

  let write_ack req = write_reply req (Hdr.packet ~count:0)

  (** Can raise Fs.UnknownErrno (TODO: ?) *)
  let write_error req err =
    let phost = Fuse.(req.chan.host.unix_errno) in
    let nerrno = match Unix_errno.(to_code ~host:phost err) with
      | Some errno -> Int32.of_int (-errno)
      | None -> raise (Fuse.UnknownErrno err)
    in
    write_reply req (Hdr.packet ~nerrno ~count:0)

  let deserialize ~parse req =
    fun len buf ->
      let hdr_ptr = coerce (ptr char) (ptr Hdr.t) buf in
      let hdr = !@ hdr_ptr in
      let sz = getf hdr Hdr.size in
      if len <> sz then raise
        (ProtocolError
           (req.chan,
            (Printf.sprintf "Packet has %d bytes but only read %d" sz len)));
      parse req hdr (sz - Hdr.hdrsz) (to_voidp (buf +@ Hdr.hdrsz))

  (* can be overridden by include *)
  let trace_channel = stderr
end

module Linux_7_8 : LINUX_7_8 = struct
  include Out_common
  include Out_linux_7_8
  include Io

  include Linux_7_8_wire

  let parse ({Fuse.chan} as req) hdr len buf = (* TODO: test Opcode.Unknown *)
    try
      let opcode = In_common.Hdr.(getf req.hdr opcode) in
      Fuse.({chan; hdr; pkt=Opcode.(match opcode with
      | FUSE_INIT        -> Init       (!@ (from_voidp Init.t buf))
      | FUSE_GETATTR     -> Getattr    (!@ (from_voidp Attr.t buf))
      | FUSE_LOOKUP      -> Lookup     (!@ (from_voidp Entry.t buf))
      | FUSE_OPENDIR     -> Opendir    (!@ (from_voidp Open.t buf))
      | FUSE_READDIR     -> Readdir    (!@ (from_voidp Read.t buf))
      | FUSE_RELEASEDIR  -> Releasedir
      | FUSE_FSYNCDIR    -> Fsyncdir
      | FUSE_RMDIR       -> Rmdir
      | FUSE_MKDIR       -> Mkdir      (!@ (from_voidp Entry.t buf))
      | FUSE_GETXATTR    -> Getxattr
      | FUSE_SETXATTR    -> Setxattr
      | FUSE_LISTXATTR   -> Listxattr
      | FUSE_REMOVEXATTR -> Removexattr
      | FUSE_ACCESS      -> Access
      | FUSE_FORGET      -> Forget
      | FUSE_READLINK    -> Readlink   (coerce (ptr void) string buf)(*TODO:0?*)
      | FUSE_OPEN        -> Open       (!@ (from_voidp Open.t buf))
      | FUSE_READ        -> Read       (!@ (from_voidp Read.t buf))
      | FUSE_WRITE       -> Write      (!@ (from_voidp Write.t buf))
      | FUSE_STATFS      -> Statfs     (!@ (from_voidp Struct_common.Kstatfs.t buf))
      | FUSE_FLUSH       -> Flush
      | FUSE_RELEASE     -> Release
      | FUSE_FSYNC       -> Fsync
      | FUSE_UNLINK      -> Unlink
      | FUSE_CREATE      -> Create     (!@ (from_voidp Create.t buf))
      | FUSE_MKNOD       -> Mknod      (!@ (from_voidp Entry.t buf))
      | FUSE_SETATTR     -> Setattr    (!@ (from_voidp Attr.t buf))
      | FUSE_LINK        -> Link       (!@ (from_voidp Entry.t buf))
      | FUSE_SYMLINK     -> Symlink    (!@ (from_voidp Entry.t buf))
      | FUSE_RENAME      -> Rename     (!@ (from_voidp Entry.t buf))
      | FUSE_GETLK       -> Getlk
      | FUSE_SETLK       -> Setlk
      | FUSE_SETLKW      -> Setlkw
      | FUSE_INTERRUPT   -> Interrupt
      | FUSE_BMAP        -> Bmap
      | FUSE_DESTROY     -> Destroy
      | FUSE_IOCTL
      | FUSE_POLL
      | FUSE_NOTIFY_REPLY
      | FUSE_BATCH_FORGET
      | FUSE_FALLOCATE
      | FUSE_SETVOLNAME
      | FUSE_GETXTIMES
      | FUSE_EXCHANGE    -> Other opcode
      )})
    with Opcode.Unknown opcode ->
      Fuse.({chan; hdr; pkt=(Unknown (opcode, len, buf))})

  let deserialize req = deserialize ~parse req

  let describe_reply ({chan; pkt}) =
    let host = chan.Fuse.host in
    match pkt with
    | Init i -> Init.describe i
    | Getattr a -> "GETATTR FIXME" (* TODO: more *)
    | Lookup e -> Entry.describe ~host e
    | Opendir o -> "OPENDIR FIXME" (* TODO: more *)
    | Readdir r -> "READDIR FIXME" (* TODO: more *)
    | Releasedir -> "RELEASEDIR"
    | Fsyncdir -> "FSYNCDIR"
    | Rmdir -> "RMDIR"
    | Mkdir e -> Entry.describe ~host e
    | Getxattr -> "GETXATTR"
    | Setxattr -> "SETXATTR"
    | Listxattr -> "LISTXATTR"
    | Removexattr -> "REMOVEXATTR"
    | Access -> "ACCESS"
    | Forget -> "FORGET"
    | Readlink r -> r
    | Open o -> "OPEN FIXME" (* TODO: more *)
    | Read r -> "READ FIXME" (* TODO: more *)
    | Write w -> "WRITE FIXME" (* TODO: more *)
    | Statfs s -> "STATFS FIXME" (* TODO: more *)
    | Flush -> "FLUSH"
    | Release -> "RELEASE"
    | Fsync -> "FSYNC"
    | Unlink -> "UNLINK"
    | Create c -> "CREATE FIXME" (* TODO: more *)
    | Mknod e -> Entry.describe ~host e
    | Setattr a -> "SETATTR FIXME" (* TODO: more *)
    | Link e -> Entry.describe ~host e
    | Symlink e -> Entry.describe ~host e
    | Rename e -> Entry.describe ~host e
    | Getlk -> "GETLK"
    | Setlk -> "SETLK"
    | Setlkw -> "SETLKW"
    | Interrupt -> "INTERRUPT"
    | Bmap -> "BMAP"
    | Destroy -> "DESTROY"
    | Other opcode -> "OTHER ("^(Opcode.to_string opcode)^")"
    | Unknown (o,l,b) -> "UNKNOWN FIXME" (* TODO: more *)

end

module Osx_7_8 : OSX_7_8 = struct
  include Out_common
  include Out_osx_7_8
  include Io

  include Osx_7_8_wire

  let parse ({Fuse.chan} as req) hdr len buf = (* TODO: test Opcode.Unknown *)
    try
      let opcode = In_common.Hdr.(getf req.hdr opcode) in
      Fuse.({chan; hdr; pkt=Opcode.(match opcode with
      | FUSE_INIT        -> Init       (!@ (from_voidp Init.t buf))
      | FUSE_GETATTR     -> Getattr    (!@ (from_voidp Attr.t buf))
      | FUSE_LOOKUP      -> Lookup     (!@ (from_voidp Entry.t buf))
      | FUSE_OPENDIR     -> Opendir    (!@ (from_voidp Open.t buf))
      | FUSE_READDIR     -> Readdir    (!@ (from_voidp Read.t buf))
      | FUSE_RELEASEDIR  -> Releasedir
      | FUSE_FSYNCDIR    -> Fsyncdir
      | FUSE_RMDIR       -> Rmdir
      | FUSE_MKDIR       -> Mkdir      (!@ (from_voidp Entry.t buf))
      | FUSE_GETXATTR    -> Getxattr
      | FUSE_SETXATTR    -> Setxattr
      | FUSE_LISTXATTR   -> Listxattr
      | FUSE_REMOVEXATTR -> Removexattr
      | FUSE_ACCESS      -> Access
      | FUSE_FORGET      -> Forget
      | FUSE_READLINK    -> Readlink   (coerce (ptr void) string buf)(*TODO:0?*)
      | FUSE_OPEN        -> Open       (!@ (from_voidp Open.t buf))
      | FUSE_READ        -> Read       (!@ (from_voidp Read.t buf))
      | FUSE_WRITE       -> Write      (!@ (from_voidp Write.t buf))
      | FUSE_STATFS      -> Statfs     (!@ (from_voidp Struct_common.Kstatfs.t buf))
      | FUSE_FLUSH       -> Flush
      | FUSE_RELEASE     -> Release
      | FUSE_FSYNC       -> Fsync
      | FUSE_UNLINK      -> Unlink
      | FUSE_CREATE      -> Create     (!@ (from_voidp Create.t buf))
      | FUSE_MKNOD       -> Mknod      (!@ (from_voidp Entry.t buf))
      | FUSE_SETATTR     -> Setattr    (!@ (from_voidp Attr.t buf))
      | FUSE_LINK        -> Link       (!@ (from_voidp Entry.t buf))
      | FUSE_SYMLINK     -> Symlink    (!@ (from_voidp Entry.t buf))
      | FUSE_RENAME      -> Rename     (!@ (from_voidp Entry.t buf))
      | FUSE_GETLK       -> Getlk
      | FUSE_SETLK       -> Setlk
      | FUSE_SETLKW      -> Setlkw
      | FUSE_INTERRUPT   -> Interrupt
      | FUSE_BMAP        -> Bmap
      | FUSE_DESTROY     -> Destroy
      | FUSE_IOCTL
      | FUSE_POLL
      | FUSE_NOTIFY_REPLY
      | FUSE_BATCH_FORGET
      | FUSE_FALLOCATE
      | FUSE_SETVOLNAME
      | FUSE_GETXTIMES
      | FUSE_EXCHANGE    -> Other opcode
      )})
    with Opcode.Unknown opcode ->
      Fuse.({chan; hdr; pkt=(Unknown (opcode, len, buf))})

  let deserialize req = deserialize ~parse req

  let describe_reply ({chan; pkt}) =
    let host = chan.Fuse.host in
    match pkt with
    | Init i -> Init.describe i
    | Getattr a -> "GETATTR FIXME" (* TODO: more *)
    | Lookup e -> Entry.describe ~host e
    | Opendir o -> "OPENDIR FIXME" (* TODO: more *)
    | Readdir r -> "READDIR FIXME" (* TODO: more *)
    | Releasedir -> "RELEASEDIR"
    | Fsyncdir -> "FSYNCDIR"
    | Rmdir -> "RMDIR"
    | Mkdir e -> Entry.describe ~host e
    | Getxattr -> "GETXATTR"
    | Setxattr -> "SETXATTR"
    | Listxattr -> "LISTXATTR"
    | Removexattr -> "REMOVEXATTR"
    | Access -> "ACCESS"
    | Forget -> "FORGET"
    | Readlink r -> r
    | Open o -> "OPEN FIXME" (* TODO: more *)
    | Read r -> "READ FIXME" (* TODO: more *)
    | Write w -> "WRITE FIXME" (* TODO: more *)
    | Statfs s -> "STATFS FIXME" (* TODO: more *)
    | Flush -> "FLUSH"
    | Release -> "RELEASE"
    | Fsync -> "FSYNC"
    | Unlink -> "UNLINK"
    | Create c -> "CREATE FIXME" (* TODO: more *)
    | Mknod e -> Entry.describe ~host e
    | Setattr a -> "SETATTR FIXME" (* TODO: more *)
    | Link e -> Entry.describe ~host e
    | Symlink e -> Entry.describe ~host e
    | Rename e -> Entry.describe ~host e
    | Getlk -> "GETLK"
    | Setlk -> "SETLK"
    | Setlkw -> "SETLKW"
    | Interrupt -> "INTERRUPT"
    | Bmap -> "BMAP"
    | Destroy -> "DESTROY"
    | Other opcode -> "OTHER ("^(Opcode.to_string opcode)^")"
    | Unknown (o,l,b) -> "UNKNOWN FIXME" (* TODO: more *)

end

module Linux_7_8_of_osx_7_8 : LINUX_7_8_OVER_OSX_7_8  = struct
  include Out_common
  include Io

  type t = Osx_7_8.t

  let parse = Osx_7_8.parse
  let deserialize req = deserialize ~parse req
  let describe_reply = Osx_7_8.describe_reply

  module Struct = Struct.Linux_7_8

  module Create = struct
    include Linux_7_8.Create

    let create ~store_entry ~store_open req =
      let open Linux_7_8 in
      let entry = make Entry.t in
      store_entry entry req;
      let nodeid = getf entry Entry.nodeid in
      let generation = getf entry Entry.generation in
      let entry_valid = getf entry Entry.entry_valid in
      let attr_valid = getf entry Entry.attr_valid in
      let entry_valid_nsec = getf entry Entry.entry_valid_nsec in
      let attr_valid_nsec = getf entry Entry.attr_valid_nsec in
      let store_attr = Struct.store_attr_to_osx_7_8 (getf entry Entry.attr) in
      Osx_7_8.(
        Create.create
          ~store_entry:(Entry.store
                          ~nodeid
                          ~generation
                          ~entry_valid
                          ~attr_valid
                          ~entry_valid_nsec
                          ~attr_valid_nsec
                          ~store_attr
          )
          ~store_open
          req
      )
  end

  module Attr = struct
    include Linux_7_8.Attr

    let create ~attr_valid ~attr_valid_nsec ~store_attr req =
      let attr = make Struct.Attr.t in
      store_attr attr;
      let store_attr = Struct.store_attr_to_osx_7_8 attr in
      Osx_7_8.(Attr.create ~attr_valid ~attr_valid_nsec ~store_attr req)
  end

  module Entry = struct
    include Linux_7_8.Entry

    let create ~nodeid ~generation ~entry_valid ~attr_valid
        ~entry_valid_nsec ~attr_valid_nsec ~store_attr req =
      let attr = make Struct.Attr.t in
      store_attr attr;
      let store_attr = Struct.store_attr_to_osx_7_8 attr in
      Osx_7_8.Entry.create
        ~nodeid
        ~generation
        ~entry_valid
        ~attr_valid
        ~entry_valid_nsec
        ~attr_valid_nsec
        ~store_attr
        req
  end
end

module Osx_7_8_of_linux_7_8 : OSX_7_8_OVER_LINUX_7_8 = struct
  include Out_common
  include Io

  type t = Linux_7_8.t

  let parse = Linux_7_8.parse
  let deserialize req = deserialize ~parse req
  let describe_reply = Linux_7_8.describe_reply

  module Struct = Struct.Osx_7_8

  module Create = struct
    include Osx_7_8.Create

    let create ~store_entry ~store_open req =
      let open Osx_7_8 in
      let entry = make Entry.t in
      store_entry entry req;
      let nodeid = getf entry Entry.nodeid in
      let generation = getf entry Entry.generation in
      let entry_valid = getf entry Entry.entry_valid in
      let attr_valid = getf entry Entry.attr_valid in
      let entry_valid_nsec = getf entry Entry.entry_valid_nsec in
      let attr_valid_nsec = getf entry Entry.attr_valid_nsec in
      let store_attr = Struct.store_attr_to_linux_7_8 (getf entry Entry.attr) in
      Linux_7_8.(
        Create.create
          ~store_entry:(Entry.store
                          ~nodeid
                          ~generation
                          ~entry_valid
                          ~attr_valid
                          ~entry_valid_nsec
                          ~attr_valid_nsec
                          ~store_attr
          )
          ~store_open
          req
      )
  end

  module Attr = struct
    include Osx_7_8.Attr

    let create ~attr_valid ~attr_valid_nsec ~store_attr req =
      let attr = make Struct.Attr.t in
      store_attr attr;
      let store_attr = Struct.store_attr_to_linux_7_8 attr in
      Linux_7_8.(Attr.create ~attr_valid ~attr_valid_nsec ~store_attr req)
  end

  module Entry = struct
    include Osx_7_8.Entry

    let create ~nodeid ~generation ~entry_valid ~attr_valid
        ~entry_valid_nsec ~attr_valid_nsec ~store_attr req =
      let attr = make Struct.Attr.t in
      store_attr attr;
      let store_attr = Struct.store_attr_to_linux_7_8 attr in
      Linux_7_8.Entry.create
        ~nodeid
        ~generation
        ~entry_valid
        ~attr_valid
        ~entry_valid_nsec
        ~attr_valid_nsec
        ~store_attr
        req
  end
end
