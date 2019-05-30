
import coretypes

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
        name_length: uint16 # name is directly after field block
        typecode: TypeCode
        next_value: uint32
        next_block: uint32

    MessageFieldValueBlock = object
        block_size: uint32
        next_value: uint32

    Message* = object
        specifiers: seq[Message]
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

proc add_data*(
          self: var Message;
          name: string;
      typecode: TypeCode;
          data: pointer;
        length: int;
    fixed_size: bool = true;
         count: int = 1): pointer {.discardable.} =

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
proc add*(self: var Message; key: string; value: pointer) =
  self.add_data(key, POINTER_TYPE, cast[pointer](unsafeaddr value), value.sizeof)
# [[[end]]]

proc add*(self: var Message; key: string; value: string) =
    # XXX assuming strings are made of chars
    var x = self.add_data(key, STRING_TYPE, nil, len(value))
    copymem(x,
        unsafeaddr value[0],
        len(value))

proc find_data*(
            self: Message;
             key: string;
        typecode: out TypeCode;
            data: out pointer;
          length: out int;
           index: int = 0): bool =
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

#string
#point
#rect
#message
#messenger
#flat

# [[[cog
# for x in pairs:
#   cog.outl("""proc try_find_{0}*(self: Message; key: string; default_value: {0}; index: int = 0): {0} =
#   var data: pointer
#   var dlen: int
#   var code: TypeCode
#   var found: bool
#   found = self.find_data(key, code, data, dlen, index)
#   if (not found) or (code != {1}):
#     return default_value
#   assert dlen == {0}.sizeof
#   result = cast[ptr {0}](data)[]
#   """.format(x[0], x[1]))
# ]]]
proc try_find_bool*(self: Message; key: string; default_value: bool; index: int = 0): bool =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != BOOL_TYPE):
    return default_value
  assert dlen == bool.sizeof
  result = cast[ptr bool](data)[]
  
proc try_find_int8*(self: Message; key: string; default_value: int8; index: int = 0): int8 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != INT8_TYPE):
    return default_value
  assert dlen == int8.sizeof
  result = cast[ptr int8](data)[]
  
proc try_find_int16*(self: Message; key: string; default_value: int16; index: int = 0): int16 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != INT16_TYPE):
    return default_value
  assert dlen == int16.sizeof
  result = cast[ptr int16](data)[]
  
proc try_find_int32*(self: Message; key: string; default_value: int32; index: int = 0): int32 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != INT32_TYPE):
    return default_value
  assert dlen == int32.sizeof
  result = cast[ptr int32](data)[]
  
proc try_find_int64*(self: Message; key: string; default_value: int64; index: int = 0): int64 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != INT64_TYPE):
    return default_value
  assert dlen == int64.sizeof
  result = cast[ptr int64](data)[]
  
proc try_find_uint8*(self: Message; key: string; default_value: uint8; index: int = 0): uint8 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != UINT8_TYPE):
    return default_value
  assert dlen == uint8.sizeof
  result = cast[ptr uint8](data)[]
  
proc try_find_uint16*(self: Message; key: string; default_value: uint16; index: int = 0): uint16 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != UINT16_TYPE):
    return default_value
  assert dlen == uint16.sizeof
  result = cast[ptr uint16](data)[]
  
proc try_find_uint32*(self: Message; key: string; default_value: uint32; index: int = 0): uint32 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != UINT32_TYPE):
    return default_value
  assert dlen == uint32.sizeof
  result = cast[ptr uint32](data)[]
  
proc try_find_uint64*(self: Message; key: string; default_value: uint64; index: int = 0): uint64 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != UINT64_TYPE):
    return default_value
  assert dlen == uint64.sizeof
  result = cast[ptr uint64](data)[]
  
proc try_find_float32*(self: Message; key: string; default_value: float32; index: int = 0): float32 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != FLOAT_TYPE):
    return default_value
  assert dlen == float32.sizeof
  result = cast[ptr float32](data)[]
  
proc try_find_float64*(self: Message; key: string; default_value: float64; index: int = 0): float64 =
  var data: pointer
  var dlen: int
  var code: TypeCode
  var found: bool
  found = self.find_data(key, code, data, dlen, index)
  if (not found) or (code != DOUBLE_TYPE):
    return default_value
  assert dlen == float64.sizeof
  result = cast[ptr float64](data)[]
  
proc try_find_pointer*(self: Message; key: string; default_value: pointer; index: int = 0): pointer =
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

proc push_specifier*(self: var Message; specifier: string) =
    var s = make_message(MSG_SPECIFIER)
    s.add("name", specifier)
    self.specifiers.add(s)

proc pop_specifier*(self: var Message): string =
    if self.specifiers.len == 0:
        return ""
    var m = self.specifiers.pop()
    result = m.try_find_string("name", "")

