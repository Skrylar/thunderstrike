
import coretypes

type
    MessageBlock = object
        flags: uint8
        block_size: int
        what: uint32
        first_specifier: int
        first_field: int

    MessageSpecifierBlock = object
        flags: uint8
        block_size: int

    MessageFieldBlock = object
        flags: uint8
        name_length: int # name is directly after field block
        typecode: TypeCode
        next_value: int
        next_block: int

    MessageFieldValueBlock = object
        next_value: int

    Message* = object
        buffer: seq[byte]

# Messages
# ========

proc initialize(self: var MessageBlock; what: uint32) =
    self.flags = 0
    self.what = what
    self.block_size = MessageBlock.sizeof
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
        var me = cast[ptr MessageFieldBlock](unsafeaddr self.buffer[here])
        yield me
        here = me.next_block

iterator values(message: Message; self: ptr MessageFieldBlock): ptr MessageFieldValueBlock =
    var here = self.next_value
    while here != 0:
        var x = cast[ptr MessageFieldValueBlock](unsafeaddr message.buffer[here])
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
        if f.name_length != name.len: continue
        if equalmem(cast[pointer](cast[int](f) + MessageFieldBlock.sizeof), unsafeaddr name[0], f.name_length): return f

proc has_field*(self: Message; name: string): bool =
    return get_field(self, name) != nil

proc add_data*(self: var Message;
               name: string;
           typecode: TypeCode;
               data: pointer;
             length: int;
         fixed_size: bool = true;
              count: int = 1) =

    assert length >= 0
    assert count >= 0

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
        blk.name_length = len(name)
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
        inc point, MessageFieldValueBlock.sizeof
        copymem(cast[pointer](addr self.buffer[point]), data, length)

        var tail = tail_value(self, blk)
        if tail != nil:
            tail.next_value = rec
        else:
            blk.next_value = rec

    if not stored:
        # register with index
        var tail = self.tail_field
        if tail == nil:
            var head = cast[ptr MessageBlock](unsafeaddr self.buffer[0])
            head.first_field = int(rec)
        else:
            tail.next_block = int(rec)

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

#data
#
#bool
#int8
#int16
#int32
#int64
#float32
#float64
#string
#point
#rect
#message
#messenger
#pointer
#flat
#
