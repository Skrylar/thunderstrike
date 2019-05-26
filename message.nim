
import coretypes

type
    MessageBlock = object
        flags: uint8
        what: uint32
        block_size: int32 # binary versioning field
        first_specifier: uint32
        first_field: uint32

    MessageSpecifierBlock = object
        flags: uint8
        next_block: uint32

    MessageFieldBlock = object
        flags: uint8
        name_length: uint16 # name is directly after field block
        typecode: TypeCode
        next_value: uint32
        next_block: uint32

    MessageFieldValueBlock = object
        block_size: uint32
        next_value: uint32

    Message* = object
        buffer: seq[byte]

# Messages
# ========

# TODO put in bounds checking on deref
# ^ not a big deal for trusted code but if we start doing RPC with arbitrary
# software some of it might be defective

proc initialize(self: var MessageBlock; what: uint32) =
    self.flags = 0
    self.what = what
    self.block_size = MessageBlock.sizeof.int32
    self.first_specifier = 0
    self.first_field = 0

proc make_message*(what: uint32): Message =
    # put initial data block in our buffer and initialize it
    set_len(result.buffer, MessageBlock.sizeof)
    var x: ptr MessageBlock
    x = cast[ptr MessageBlock](addr result.buffer[0])
    x[].initialize(what)

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

proc has_field*(self: Message; name: string): bool =
    return get_field(self, name) != nil

proc add_data*(self: var Message;
               name: string;
           typecode: TypeCode;
               data: pointer;
             length: int;
         fixed_size: bool = true;
              count: int = 1): pointer {.discardable.} =

    # TODO change these to real exceptions
    assert length >= 1
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
            # its the wrong type; we can't do anything!
            # TODO custom exception type?
            raise newException(IOError, "Field already exists in message, but is wrong type.")
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

proc count_values*(self: Message; key: string): int =
    result = 0
    var f = get_field(self, key)
    if f == nil:
        return 0
    for v in values(self, f):
        inc result

var msg = make_message(0)
assert(not msg.has_field("baguette"))
msg.add_data("baguette", 0, nil, 0)
var delicious = true
assert(msg.count_values("delicious") == 0)
msg.add_data("delicious", 38, addr delicious, delicious.sizeof)
assert(msg.has_field("delicious"))
assert(msg.count_values("delicious") == 1)
delicious = false
msg.add_data("delicious", 38, addr delicious, delicious.sizeof)
echo msg.count_values("delicious")
assert(msg.count_values("delicious") == 2)
msg.add_data("delicious", 38, addr delicious, delicious.sizeof)
assert(msg.count_values("delicious") == 3)
assert(msg.has_field("baguette"))

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
# ('float64', 'DOUBLE_TYPE')]
# for x in pairs:
#   cog.outl("""proc add*(self: var Message; key: string; value: {0}) =
#   self.add_data(key, {1}, cast[pointer](unsafeaddr value), value.sizeof)""".format(x[0], x[1]))
#]]]
proc add*(self: var Message; key: string; value: bool) =
  self.add_data(key, BOOL_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: int8) =
  self.add_data(key, INT8_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: int16) =
  self.add_data(key, INT16_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: int32) =
  self.add_data(key, INT32_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: int64) =
  self.add_data(key, INT64_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: uint8) =
  self.add_data(key, UINT8_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: uint16) =
  self.add_data(key, UINT16_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: uint32) =
  self.add_data(key, UINT32_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: uint64) =
  self.add_data(key, UINT64_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: float32) =
  self.add_data(key, FLOAT_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
proc add*(self: var Message; key: string; value: float64) =
  self.add_data(key, DOUBLE_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
# [[[end]]]


#string
#point
#rect
#message
#messenger
#pointer
#flat

