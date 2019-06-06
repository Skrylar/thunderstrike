
==========
 Messages
==========

.. code:: nim
	  
   Message = object

Lifecycle
---------
   
.. code:: nim
	     
   proc init(message: Message; what: uint32): Message

.. code:: nim

   proc make_message(what: uint32): Message
   proc rez_message(what: uint32): Message

`make` creates and initializes a new message object.

`rez` additionally runs `GCref` on the resulting message, making it
suitable for use from C/Python.

Packaging data
--------------

.. code:: nim

   proc add_data(self: var Message;
                 name: string;
             typecode: TypeCode;
                 data: pointer;
               length: int;
           fixed_size: bool = true;
                count: int = 1): pointer {.discardable.}

:self:
:name: Key to store the data under. Does not need to be unique, with caveat.
:typecode: Type code to store the data under.
:data:
   Either a buffer to blit in to the message, or `nil` (see no-copy packaging.)
:length: Number of bytes to reserve inside the message for this data.
:fixed_size:
   Should there be more than one piece of data stored under the same key, it becomes an array. If the key is mared to hold `fixed-size` data, it will be known that every value has identical byte usage. This can increase bandwidth efficiency since we need only know the size of *one* item and their count, instead of having to skip over items individually.
:count:
   This *should* forewarn the message system you will be storing more than one thing under the key for this message. Our current implementation is built to permit arbitrary random packing, so this doesn't really do anything. Implementation changes are free to use it to pre-allocate space (see: fixed-sizes) though.
		 
No-copy packaging
^^^^^^^^^^^^^^^^^

If `data` is `nil`, space is still reserved inside the message but
no data is copied in to it. Instead a pointer to this writable space
is returned. You should write to this pointer and then throw it
away immediately.

The user story for no-copy packaging like this is so that objects
can be flattened immediately in to a message buffer, or for
example a string's length can be written followed by blitting that
string. Without the no-copy mode (as in Be/Haiku) you would have to
pack the objects to a holding area, then blit to the message.

Overhead
^^^^^^^^

The current format used internally is dubbed "random indexed block"
format, because it is based around messages being constructed at
random order in an append-only format. As such every block knows the
location of the next block in the chain, which can appear anywhere in
the buffer. Each field also knows the location of its next sibling,
also anywhere in the buffer.

Messages have a fixed overhead of 17 bytes, with an additional overhead
of 15 bytes (+length of field name) per field. Each value stored in
a field has eight bytes of overhead.

So a message such as:

- what: button
- pressed: boolean
- button: int8

Has a natural compact size of six bytes, but would be encoded as 38
bytes. This is an overhead of 600%. This only applies to very small
messages as the overhead of messages approaches 200% as their size
increases [tested via simulation with NumPy.]

Packaging convenience methods
-----------------------------

.. code:: nim

    proc add(self: Message; key: string; value: bool)
    proc add(self: Message; key: string; value: int8)
    proc add(self: Message; key: string; value: int16)
    proc add(self: Message; key: string; value: int32)
    proc add(self: Message; key: string; value: int64)
    proc add(self: Message; key: string; value: uint8)
    proc add(self: Message; key: string; value: uint16)
    proc add(self: Message; key: string; value: uint32)
    proc add(self: Message; key: string; value: uint64)
    proc add(self: Message; key: string; value: float32)
    proc add(self: Message; key: string; value: float64)
    proc add(self: Message; key: string; value: pointer)
    proc add(self: Message; key: string; value: string)

Adds `value` under the named field `key`.

Decanting data
--------------

.. code:: nim

    proc find_data(self: Message;
                    key: string;
               typecode: out TypeCode;
                   data: out pointer;
                 length: out int;
                  index: int = 0): bool

:self: The message to search for data in.
:key: Name of the field to look for.
:typecode: Where the data type held by this field is saved to.
:data: Where a pointer to the data held by this field is saved to.
:length: How many bytes of data are there to read?
:index: Which instance of this field to read? 0-based.

Looks for a field with a given `key` name in the message. Returns
information about the field if it was found. Otherwise it returns
false and the out vars are not written to.

.. warning::

    The pointer returned in to `data` is not yours to keep or
    edit. Deserialize your data and forget the pointer as soon as
    possible.

Decanting convenience methods
-----------------------------

These convenience methods allow you to ask for data directly; they
perform type checking and unpacking for you. Most of the time you
will be using the convenience methods.

.. code:: nim

    proc try_find_bool   (self: Message; key: string; default_value: bool   ; index: int = 0): bool
    proc try_find_int8   (self: Message; key: string; default_value: int8   ; index: int = 0): int8
    proc try_find_int16  (self: Message; key: string; default_value: int16  ; index: int = 0): int16
    proc try_find_int32  (self: Message; key: string; default_value: int32  ; index: int = 0): int32
    proc try_find_int64  (self: Message; key: string; default_value: int64  ; index: int = 0): int64
    proc try_find_uint8  (self: Message; key: string; default_value: uint8  ; index: int = 0): uint8
    proc try_find_uint16 (self: Message; key: string; default_value: uint16 ; index: int = 0): uint16
    proc try_find_uint32 (self: Message; key: string; default_value: uint32 ; index: int = 0): uint32
    proc try_find_uint64 (self: Message; key: string; default_value: uint64 ; index: int = 0): uint64
    proc try_find_float32(self: Message; key: string; default_value: float32; index: int = 0): float32
    proc try_find_float64(self: Message; key: string; default_value: float64; index: int = 0): float64
    proc try_find_pointer(self: Message; key: string; default_value: pointer; index: int = 0): pointer
    proc try_find_string (self: Message; key: string; default_value: string ; index: int = 0): string

Looks for a value of a given type, under the name `key`. If the value
is found and is the exact same type it will be returned. If the message
is not the exact type or is not found, the `default_value` is returned.

.. note::
    These are *strictly typed* getters; trying to read an ``int32``
    will not silently accept and upscale an ``int8``.

.. code:: nim

    proc try_find_int  (self: Message; key: string; default_value: int64  ; index: int = 0): int64
    proc try_find_uint (self: Message; key: string; default_value: uint64 ; index: int = 0): uint64
    proc try_find_float(self: Message; key: string; default_value: float64; index: int = 0): float64

These are permissive versions of the decanting methods from above. They
will attempt to read smaller fields of similar types in addition to
the largest field type.

.. todo:: Storing messages inside of messages.
.. todo:: Flattening of messages.

