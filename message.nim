
import coretypes, geometry

type
    MessageBlock = object
        flags: uint8
        what: uint32
        block_size: int32 # binary versioning field
        first_field: uint32

    MessageSpecifierBlock = object
        flags: uint8
        next_block: uint32

    MessageFieldBlock = object
        flags: uint8
        prev: Message
        name_length: uint16 # name is directly after field block
        typecode: TypeCode
        next_value: uint32
        next_block: uint32

    MessageFieldValueBlock = object
        block_size: uint32
        prev: Message
        next_value: uint32

    MessageFlag* = enum
        FromRemote      # Message is from a remote system or thread.
        FromSystem      # Message is from the system.
        FromDragAndDrop # Message is the result of D&D.
        Delivered       # Message was delivered to a target.
        ExpectingReply  # Sender is awaiting a response.

    Message* = ref object
        flags: set[MessageFlag]  # Special flags
        reply_to: Handler        # Who to send reply to
        prev: Message            # Message we are a reply to
        specifiers: seq[Message] # Scripting specifiers
        buffer: seq[byte]        # Message bytes

    MessageReceivedHook* = proc(message, immediate_reply: Message) {.closure.}
    SupportedSuitesHook* = proc(message: Message) {.closure.}
    ResolveSpecifierHook* = proc(message: Message;
                                 index: int32;
                                 specifier: Message;
                                 what: int32;
                                 property: string): Handler {.closure.}
    SendNoticesHook* = proc(what: uint32;
                            message: Message = nil) {.closure.}

    HandlerWatcher = object
        #messenger*: Messenger
        handler*: Handler
        state*: uint32

    Handler* = ref object of RootObj
        fmessage_received*: MessageReceivedHook
        fget_supported_suites*: SupportedSuitesHook
        fresolve_specifier*: ResolveSpecifierHook
        fsend_notices*: SendNoticesHook
        flooper: Looper
        ffilters: seq[MessageFilter]
        fnext_handler: Handler
        fname: string
        fwatchers: seq[HandlerWatcher]

    Looper* = ref object of Handler
        fpreferred_handler: Handler
        fhandlers: seq[Handler]
        fcurrent_message: Message

    MessageSource* = enum
        AnySource
        RemoteSource
        LocalSource

    MessageDelivery* = enum
        AnyDelivery
        DroppedDelivery
        ProgrammedDelivery

    FilterResult* = enum
        SkipMessage
        DispatchMessage

    FilterHook* = proc(message: Message;
                       target: var ref Handler) {.closure.}

    MessageFilter* = ref object
        ffilter_any: bool
        ffilter: uint32
        fhook: FilterHook
        flooper: Handler
        fmessage_source: MessageSource
        fmessage_delivery: MessageDelivery

    MessageQueue* = object
        fqueue: seq[Message]

    Messenger* = ref object

proc looper*(self: Handler): Looper {.inline.} =
    return self.flooper

# MESSAGES
# ========

# TODO Delete data methods
# TODO Replace data methods
# ^The above two have the crinkle that they were not in the Be
# book, and the message format we're using was designed around an
# append-only premise.  We could implement a wasteful version easily,
# while a less wasteful method could require a little finesse.

# TODO make flattenable
# TODO put in bounds checking on deref
# ^ not a big deal for trusted code but if we start doing RPC with
# arbitrary software some of it might be defective

proc init(self: var MessageBlock; what: uint32) =
    self.flags = 0
    self.what = what
    self.block_size = MessageBlock.sizeof.int32
    self.first_field = 0

proc init*(self: Message; what: uint32) =
    set_len(self.buffer, MessageBlock.sizeof)
    var x: ptr MessageBlock
    x = cast[ptr MessageBlock](addr self.buffer[0])
    x[].init(what)

proc make_message*(what: uint32): Message =
    # put initial data block in our buffer and initialize it
    new(result)
    init(result, what)

proc rez_message*(what: uint32): Message {.exportc,dynlib.} =
    result = make_message(what)
    GCref(result)

proc derez_message*(self: Message) {.exportc,dynlib.} =
    GCunref(self)

proc what*(self: Message): uint32 {.exportc:"message_get_what",dynlib.} = 
    var x: ptr MessageBlock
    x = cast[ptr MessageBlock](addr self.buffer[0])
    return x.what

proc `what=`*(self: Message; value: uint32) {.exportc:"message_set_what",dynlib.} =
    var x: ptr MessageBlock
    x = cast[ptr MessageBlock](addr self.buffer[0])
    x.what = value

iterator fields(self: Message): ptr MessageFieldBlock =
    # NB: we aren't modifying the datablocks, so unsafeaddr is fine
    var head = cast[ptr MessageBlock](unsafeaddr self.buffer[0])
    var here = head.first_field
    while here != 0:
        var me = cast[ptr MessageFieldBlock](unsafeaddr self.buffer[here.int])
        yield me
        here = me.next_block

iterator values(message: Message; self: ptr MessageFieldBlock): ptr MessageFieldValueBlock =
    var here = self.next_value
    while here != 0:
        var x = cast[ptr MessageFieldValueBlock](unsafeaddr message.buffer[here.int])
        yield x
        here = x.next_value

proc tail_value*(self: Message; blk: ptr MessageFieldBlock): ptr MessageFieldValueBlock =
    result = nil
    for f in self.values(blk):
        result = f

proc tail_field*(self: Message): ptr MessageFieldBlock =
    result = nil
    for f in self.fields:
        result = f

proc get_field*(self: Message; name: string): ptr MessageFieldBlock =
    result = nil
    for f in self.fields:
        if f.name_length.int != name.len: continue
        if equalmem(cast[pointer](cast[int](f) + MessageFieldBlock.sizeof), unsafeaddr name[0], f.name_length): return f

proc has_field*(self: Message; name: string): bool {.exportc:"message_has_field",dynlib.} =
    return get_field(self, name) != nil

proc add_data*(
          self: var Message;
          name: string;
      typecode: TypeCode;
          data: pointer;
        length: int;
    fixed_size: bool = true;
         count: int = 1): pointer {.discardable,exportc:"message_add_data",dynlib.} =

    # TODO change these to real exceptions
    assert length >= 0
    assert length <= high(uint32).int
    assert len(name) < high(uint16).int
    assert count >= 0

    result = nil

    var blk = self.get_field(name)
    var stored = (blk != nil)

    var point = len(self.buffer)
    let rec = len(self.buffer)

    if stored:
        # it's already here
        if blk.typecode != typecode:
            # used to be an exception
            return nil
        # its the right type so we can just append
        set_len(self.buffer, self.buffer.len + MessageFieldValueBlock.sizeof + length)
    else:
        set_len(self.buffer, self.buffer.len + MessageFieldBlock.sizeof + name.len + MessageFieldValueBlock.sizeof + length)
        blk = cast[ptr MessageFieldBlock](addr self.buffer[point])
        blk.flags = 0 # TODO fixed length flag
        blk.name_length = len(name).uint16
        blk.typecode = typecode
        blk.next_block = 0
        # copy string in to header
        inc point, MessageFieldBlock.sizeof
        var str = cast[pointer](addr self.buffer[point])
        copymem(str, unsafeaddr name[0], len(name))
        inc point, len(name)

    if length > 0 and count > 0:
        # copy data in to buffer
        let rec = point
        var val = cast[ptr MessageFieldValueBlock](addr self.buffer[point])
        val.next_value = 0
        val.block_size = length.uint32
        inc point, MessageFieldValueBlock.sizeof
        if data != nil:
            copymem(cast[pointer](addr self.buffer[point]), data, length)
        else:
            result = cast[pointer](addr self.buffer[point])

        var tail = tail_value(self, blk)
        if tail != nil:
            tail.next_value = rec.uint32
        else:
            blk.next_value = rec.uint32

    if not stored:
        # register with index
        var tail = self.tail_field
        if tail == nil:
            var head = cast[ptr MessageBlock](unsafeaddr self.buffer[0])
            head.first_field = int(rec).uint32
        else:
            tail.next_block = int(rec).uint32

proc count_values*(self: Message; key: string): int {.exportc:"message_count_values",dynlib.} =
    result = 0
    var f = get_field(self, key)
    if f == nil:
        return 0
    for v in values(self, f):
        inc result

# [[[cog
# pairs = [('bool', 'BOOL_TYPE'),
# ('int8', 'INT8_TYPE'),
# ('int16', 'INT16_TYPE'),
# ('int32', 'INT32_TYPE'),
# ('int64', 'INT64_TYPE'),
# ('uint8', 'UINT8_TYPE'),
# ('uint16', 'UINT16_TYPE'),
# ('uint32', 'UINT32_TYPE'),
# ('uint64', 'UINT64_TYPE'),
# ('float32', 'FLOAT_TYPE'),
# ('float64', 'DOUBLE_TYPE'),
# ('pointer', 'POINTER_TYPE')]
# for x in pairs:
#   cog.outl("""proc add*(self: var Message; key: string; value: {0}) {{.exportc:"message_add_{0}", dynlib.}} =
#   self.add_data(key, {1}, cast[pointer](unsafeaddr value), value.sizeof)""".format(x[0], x[1]))
#]]]
proc add*(self: var Message; key: string; value: bool) {.exportc:"message_add_bool", dynlib.} =
  self.add_data(key, BOOL_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: int8) {.exportc:"message_add_int8", dynlib.} =
  self.add_data(key, INT8_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: int16) {.exportc:"message_add_int16", dynlib.} =
  self.add_data(key, INT16_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: int32) {.exportc:"message_add_int32", dynlib.} =
  self.add_data(key, INT32_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: int64) {.exportc:"message_add_int64", dynlib.} =
  self.add_data(key, INT64_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: uint8) {.exportc:"message_add_uint8", dynlib.} =
  self.add_data(key, UINT8_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: uint16) {.exportc:"message_add_uint16", dynlib.} =
  self.add_data(key, UINT16_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: uint32) {.exportc:"message_add_uint32", dynlib.} =
  self.add_data(key, UINT32_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: uint64) {.exportc:"message_add_uint64", dynlib.} =
  self.add_data(key, UINT64_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: float32) {.exportc:"message_add_float32", dynlib.} =
  self.add_data(key, FLOAT_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: float64) {.exportc:"message_add_float64", dynlib.} =
  self.add_data(key, DOUBLE_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: pointer) {.exportc:"message_add_pointer", dynlib.} =
  self.add_data(key, POINTER_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
# [[[end]]]

proc add*(self: var Message; key: string; value: string) {.exportc:"message_add_string",dynlib.} =
    # XXX assuming strings are made of chars
    var x = self.add_data(key, STRING_TYPE, nil, len(value))
    copymem(x,
        unsafeaddr value[0],
        len(value))

proc find_data*(
            self: Message;
             key: string;
        typecode: var TypeCode;
            data: var pointer;
          length: var int;
           index: int = 0): bool {.exportc:"message_find_data",dynlib.} =
    result = false
    var header = self.get_field(key)
    if header == nil: return

    var skip = index
    typecode = header.typecode
    for value in self.values(header):
        # skip as many as we need to
        if skip > 0:
            dec skip
            continue
        data = cast[pointer](cast[int](value) + MessageFieldValueBlock.sizeof)
        length = value.block_size.int
        return true

#point
#rect
#message
#messenger
#flat

# [[[cog
# for x in pairs:
#   cog.outl("""proc try_find_{0}*(
#   self: Message; key: string;
#   default_value: {0};
#   index: int = 0): {0} {{.exportc:"message_try_find_{0}", dynlib.}} =
#        var data: pointer
#        var dlen: int
#        var code: TypeCode
#        var found: bool
#        found = self.find_data(key, code, data, dlen, index)
#        if (not found) or (code != {1}):
#            return default_value
#        assert dlen == {0}.sizeof
#        result = cast[ptr {0}](data)[]
#   """.format(x[0], x[1]))
# ]]]
proc try_find_bool*(
  self: Message; key: string;
  default_value: bool;
  index: int = 0): bool {.exportc:"message_try_find_bool", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != BOOL_TYPE):
           return default_value
       assert dlen == bool.sizeof
       result = cast[ptr bool](data)[]
  
proc try_find_int8*(
  self: Message; key: string;
  default_value: int8;
  index: int = 0): int8 {.exportc:"message_try_find_int8", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != INT8_TYPE):
           return default_value
       assert dlen == int8.sizeof
       result = cast[ptr int8](data)[]
  
proc try_find_int16*(
  self: Message; key: string;
  default_value: int16;
  index: int = 0): int16 {.exportc:"message_try_find_int16", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != INT16_TYPE):
           return default_value
       assert dlen == int16.sizeof
       result = cast[ptr int16](data)[]
  
proc try_find_int32*(
  self: Message; key: string;
  default_value: int32;
  index: int = 0): int32 {.exportc:"message_try_find_int32", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != INT32_TYPE):
           return default_value
       assert dlen == int32.sizeof
       result = cast[ptr int32](data)[]
  
proc try_find_int64*(
  self: Message; key: string;
  default_value: int64;
  index: int = 0): int64 {.exportc:"message_try_find_int64", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != INT64_TYPE):
           return default_value
       assert dlen == int64.sizeof
       result = cast[ptr int64](data)[]
  
proc try_find_uint8*(
  self: Message; key: string;
  default_value: uint8;
  index: int = 0): uint8 {.exportc:"message_try_find_uint8", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != UINT8_TYPE):
           return default_value
       assert dlen == uint8.sizeof
       result = cast[ptr uint8](data)[]
  
proc try_find_uint16*(
  self: Message; key: string;
  default_value: uint16;
  index: int = 0): uint16 {.exportc:"message_try_find_uint16", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != UINT16_TYPE):
           return default_value
       assert dlen == uint16.sizeof
       result = cast[ptr uint16](data)[]
  
proc try_find_uint32*(
  self: Message; key: string;
  default_value: uint32;
  index: int = 0): uint32 {.exportc:"message_try_find_uint32", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != UINT32_TYPE):
           return default_value
       assert dlen == uint32.sizeof
       result = cast[ptr uint32](data)[]
  
proc try_find_uint64*(
  self: Message; key: string;
  default_value: uint64;
  index: int = 0): uint64 {.exportc:"message_try_find_uint64", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != UINT64_TYPE):
           return default_value
       assert dlen == uint64.sizeof
       result = cast[ptr uint64](data)[]
  
proc try_find_float32*(
  self: Message; key: string;
  default_value: float32;
  index: int = 0): float32 {.exportc:"message_try_find_float32", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != FLOAT_TYPE):
           return default_value
       assert dlen == float32.sizeof
       result = cast[ptr float32](data)[]
  
proc try_find_float64*(
  self: Message; key: string;
  default_value: float64;
  index: int = 0): float64 {.exportc:"message_try_find_float64", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != DOUBLE_TYPE):
           return default_value
       assert dlen == float64.sizeof
       result = cast[ptr float64](data)[]
  
proc try_find_pointer*(
  self: Message; key: string;
  default_value: pointer;
  index: int = 0): pointer {.exportc:"message_try_find_pointer", dynlib.} =
       var data: pointer
       var dlen: int
       var code: TypeCode
       var found: bool
       found = self.find_data(key, code, data, dlen, index)
       if (not found) or (code != POINTER_TYPE):
           return default_value
       assert dlen == pointer.sizeof
       result = cast[ptr pointer](data)[]
  
# [[[end]]]

proc try_find_string*(self: Message; key: string; default_value: string; index: int = 0): string =
    var data: pointer
    var dlen: int
    var code: TypeCode
    var found: bool
    found = self.find_data(key, code, data, dlen, index)
    if (not found) or (code != STRING_TYPE):
        return default_value
    set_len(result, dlen)
    copymem(addr result[0], data, dlen)

proc try_find_float*(self: Message; key: string; default_value: float64; index: int = 0): float64 =
    var data: pointer
    var dlen: int
    var code: TypeCode
    var found: bool
    found = self.find_data(key, code, data, dlen, index)
    if not found:
        return default_value
    if code == FLOAT_TYPE:
        result = cast[ptr float32](data)[].float64
    elif code == DOUBLE_TYPE:
        result = cast[ptr float64](data)[]
    else:
        return default_value

proc push_specifier*(self: var Message; specifier: string) =
    var s = make_message(MSG_SPECIFIER)
    s.add("name", specifier)
    self.specifiers.add(s)

proc pop_specifier*(self: var Message): string =
    if self.specifiers.len == 0:
        return ""
    var m = self.specifiers.pop()
    result = m.try_find_string("name", "")

proc passes_filters*(self: Handler; message: Message): bool =
    # XXX should check list of filters and run them against the
    # message; then return if this handler is willing to accept the
    # message after all that
    return true # TODO

proc message_received*(self: Handler; message: Message; immediate_reply: Message = nil) =
    if self.fmessage_received != nil:
        self.fmessage_received(message, immediate_reply)

proc post_message*(self: Looper; message: Message) =
    # TODO once we are threaded, post to message queue
    # TODO what should we do if we're running on async?

    var h = self.fpreferred_handler
    if h == nil: return
    if h.passes_filters(message):
        h.message_received(message)

proc post_message*(self: Looper; message: Message; handler, reply_to: Handler) =
    # TODO once we are threaded, post to message queue
    # TODO what should we do if we're running on async?

    # we can handle this at runtime by failing silently, but its bad
    # code so we should whip the programmer with a stick at debug time
    assert(handler != nil)
    assert(handler.looper == self)
    if handler == nil: return
    if handler.looper != self: return

    message.reply_to = reply_to
    if handler.passes_filters(message):
        handler.message_received(message)

proc post_message*(self: Looper; command: uint32) =
    var msg = make_message(command)
    self.post_message(msg)

proc post_message*(self: Looper; command: uint32; handler, reply_to: Handler) =
    var msg = make_message(command)
    self.post_message(msg, handler, reply_to)

proc send_reply*(self: Message; command: uint32; reply_to: Handler = nil; timeout: BigTime = INFINITE_TIMEOUT) =
    if self.reply_to == nil: return # can't reply

    if self.reply_to.looper != nil:
        self.reply_to.looper.post_message(command, self.reply_to, reply_to)
    else:
        assert(false, "Synchronous reply is not implemented")

proc send_reply*(self: Message; reply: Message; reply_to: Handler = nil; timeout: BigTime = INFINITE_TIMEOUT) =
    if self.reply_to == nil: return # can't reply
    reply.prev = self
    
    if self.reply_to.looper != nil:
        self.reply_to.looper.post_message(reply, self.reply_to, reply_to)
    else:
        assert(false, "Synchronous reply is not implemented")

proc send_reply*(self: Message; reply: Message; reply_to: Messenger; timeout: BigTime = INFINITE_TIMEOUT) =
    discard # TODO

proc send_reply*(self: Message; command: uint32; reply_to: Message) =
    reply_to.what = NO_REPLY
    if self.reply_to == nil: return # can't reply

    # this is a command, so it's a special no-data message
    # TODO profiling to see if a free list of commands is a good idea?
    var m = make_message(command)
    m.prev = self
    self.reply_to.message_received(m, reply_to)

proc send_reply*(self, reply,reply_to: Message; timeout: BigTime = INFINITE_TIMEOUT) =
    reply_to.what = NO_REPLY
    if self.reply_to == nil: return # can't reply
    reply.prev = self
    self.reply_to.message_received(reply, reply_to)

proc is_empty*(self: Message): bool =
    var head = cast[ptr MessageBlock](unsafeaddr self.buffer[0])
    return head.first_field == 0

proc is_reply*(self: Message): bool =
    return self.prev != nil

proc is_system*(self: Message): bool =
    return FromSystem in self.flags

proc is_source_waiting*(self: Message): bool =
    return ExpectingReply in self.flags

proc is_source_remote*(self: Message): bool =
    return FromRemote in self.flags

proc was_delivered*(self: Message): bool =
    return Delivered in self.flags

proc was_dropped*(self: Message): bool =
    return FromDragAndDrop in self.flags

proc previous*(self: Message): Message =
    return self.prev

proc drop_point*(self: Message; offset: ref Point = 0): Point =
    discard # TODO

# Looper
# ======

proc init*(self: Looper; name: string = ""; default_handlers: bool = true) =
    discard # TODO

proc lock*(self: Looper; timeout: BigTime = INFINITE_TIMEOUT): bool =
    # XXX this is only valid until we start supporting threads
    return true

proc unlock*(self: Looper) =
    # XXX this is only valid until we start supporting threads
    discard

proc locked*(self: Looper): bool =
    # XXX this is only valid until we start supporting threads
    return false

proc add_handler*(self: Looper; handler: Handler) =
    if handler.flooper != nil:
        return
    if not (handler in self.fhandlers):
        handler.flooper = self
        self.fhandlers.add(handler)

template `+=`*(self: Looper; handler: Handler) =
    add_handler(self, handler)

proc remove_handler*(self: Looper; handler: Handler) =
    var index = self.fhandlers.find(handler)
    if index >= 0:
        self.fhandlers[index].flooper = nil
        self.fhandlers.delete(index)

template `-=`*(self: Looper; handler: Handler) =
    remove_handler(self, handler)

proc current_message*(self: Looper): Message =
    return self.fcurrent_message

proc detach_current_message*(self: Looper): Message = discard # TODO

proc count_handlers*(self: Looper): int32 =
    return len(self.fhandlers).int32

proc handler_at*(self: Looper; index: int32): Handler =
    if (index < 0) or (index >= len(self.fhandlers).int32):
        return nil
    return self.fhandlers[index]

proc index_of*(self: Looper; handler: Handler): int32 =
    return self.fhandlers.find(handler).int32

proc preferred_handler*(self: Looper): Handler {.inline.} =
    return self.fpreferred_handler

proc `preferred_handler=`*(self: Looper; handler: Handler) {.inline.} =
    assert((handler == self) or (handler.looper == self),
        "Handler should be the looper, or belong to it.")
    self.fpreferred_handler = handler

# Handler watcher
# ===============

proc `==`(self, other: HandlerWatcher): bool =
    return (self.handler == other.handler) and (self.state == other.state)

# Handlers
# ========

proc is_watched*(self: Handler): bool =
    return len(self.fwatchers) > 0

proc do_send_notices(self: Handler; what: uint32; message: Message = nil) =
    # if nobody is in the forest, the tree doesn't make a sound...
    if not self.is_watched: return
    for x in self.fwatchers:
        if (x.state == WATCH_ALL) or (x.state == what):
            if x.handler != nil:
                x.handler.message_received(message)

proc init*(self: Handler; name: string; default_handlers: bool) =
    self.fname = name
    if not default_handlers: return
    self.fget_supported_suites = proc(data: Message) =
        # no supported suites, for now
        discard
    self.fresolve_specifier = proc(message: Message; index: int32; specifier: Message; what: int32; property: string): Handler =
        # no specifiers to resolve at this level
        return self
    self.fsend_notices = proc(what: uint32; message: Message) =
        self.do_send_notices(what, message)
        self.fmessage_received = proc(message, imm_reply: Message) =
            if imm_reply != nil:
                imm_reply.what = MESSAGE_NOT_UNDERSTOOD
            else:
                message.send_reply(MESSAGE_NOT_UNDERSTOOD)

proc make_handler*(name: string = ""; default_handlers: bool = true): Handler =
    new(result)
    result.init(name, default_handlers)

proc get_supported_suites*(self: Handler; message: Message) =
    if self.fget_supported_suites != nil:
        self.fget_supported_suites(message)

proc lock_looper*(self: Handler; timeout: BigTime = INFINITE_TIMEOUT): bool =
    if self.flooper == nil: return false
    return self.flooper.lock(timeout)

proc unlock_looper*(self: Handler) =
    if self.flooper == nil: return
    self.flooper.unlock()

proc resolve_specifier*(self: Handler;
                        message: Message;
                        index: int32;
                        specifier: Message;
                        what: int32;
                        property: string): Handler =
    return self.fresolve_specifier(message, index, specifier, what, property)

proc name*(self: Handler): string {.inline.} =
    return self.fname

proc `name=`*(self: Handler; value: string) {.inline.} =
    # XXX do we need to tell anyone else we're renamed now?
    self.fname = value

proc filter_list*(self: Handler): seq[MessageFilter] {.inline.} =
    return self.ffilters

proc `filter_list=`*(self: var Handler; value: seq[MessageFilter]) {.inline.} =
    self.ffilters = value

proc add_filter*(self: Handler; filter: MessageFilter) =
    if not (filter in self.ffilters):
        self.ffilters.add(filter)

proc remove_filter*(self: Handler; filter: MessageFilter) =
    var i = self.ffilters.find(filter)
    if i >= 0:
        self.ffilters.delete(i)

proc next_handler*(self :Handler): Handler {.inline.} =
    return self.fnext_handler

proc `next_handler=`*(self, value: Handler) {.inline.} =
    assert(self.flooper != nil)
    assert(locked(self.flooper))
    assert(value.flooper == self.flooper)
    self.fnext_handler = value

proc send_notices_hook*(self: var Handler;
                        what: uint32;
                        message: Message = nil) =
    if self.fsend_notices != nil:
        self.fsend_notices(what, message)

#proc start_watching*(watcher: ref Messenger; what: uint32) =
    #assert(false, "Not implemented.")

proc start_watching*(self: Handler; watcher: Handler; what: uint32) =
    var watcher = HandlerWatcher(state: what, handler: watcher)
    if not (watcher in self.fwatchers):
        self.fwatchers.add(watcher)

#proc start_watching_all*(self: Handler; watcher: Messenger) =
    #assert(false, "Not implemented.")

proc start_watching_all*(self: Handler; watcher: Handler) =
    start_watching(self, watcher, WATCH_ALL)

#proc stop_watching_all*(self: Handler; watcher: Messenger) =
    #assert(false, "Not implemented.")

proc stop_watching_all*(self: Handler; watcher: Handler) =
    var i = 0
    while i < len(self.fwatchers):
        if self.fwatchers[i].handler == watcher:
            self.fwatchers.delete(i)
        else:
            inc i

#proc stop_watching*(self: Handler; watcher: Messenger; what: uint32) =
    #assert(false, "Not implemented.")

proc stop_watching*(self: Handler; watcher: Handler; what: uint32) =
    var watcher = HandlerWatcher(state: what, handler: watcher)
    var i = self.fwatchers.find(watcher)
    if i >= 0:
        self.fwatchers.delete(i)

proc send_notices*(self: Handler; what: uint32; message: Message = nil) =
    if self.fsend_notices != nil:
        self.fsend_notices(what, message)

# Looper again
# ============

proc make_looper*(name: string = ""; default_handlers: bool = true): Looper =
    new(result)
    init(result.Handler, name, default_handlers)
    init(result, name, default_handlers)

