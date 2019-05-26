
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
        name: pointer
        name_length: int
        typecode: TypeCode
        next_block: int

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

proc add_data*(name: string;
           typecode: TypeCode;
               data: pointer;
             length: int;
         fixed_size: bool = true;
              count: int = 1) =
    discard

iterator fields(self: Message): ptr MessageFieldBlock =
    # NB: we aren't modifying the datablocks, so unsafeaddr is fine
    var head = cast[ptr MessageBlock](unsafeaddr self.buffer[0])
    var here = head.first_field
    while here != 0:
        var me = cast[ptr MessageFieldBlock](unsafeaddr self.buffer[here])
        yield me
        here = me.next_block

proc has_field*(self: Message; name: string): bool =
    result = false
    for f in self.fields:
        if f.name_length != name.len: continue
        if equalmem(f.name, unsafeaddr name[0], f.name_length): return true

var msg = make_message(0)

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
