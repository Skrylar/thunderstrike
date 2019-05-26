
==========
 Messages
==========

.. code:: nim
	  
   Message = object

Lifecycle
---------
   
.. code:: nim
	     
   proc make_message(what: uint32): Message

Packaging data
--------------

.. code:: nim

   proc add_data*(self: var Message;
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

If `data` is `nil`, space is still reserved inside the message but no data is copied in to it. Instead a pointer to this writable space is returned. You should write to this pointer and then throw it away immediately.

The user story for no-copy packaging like this is so that objects can be flattened immediately in to a message buffer, or for example a string's length can be written followed by blitting that string. Without the no-copy mode (as in Be/Haiku) you would have to pack the objects to a holding area, then blit to the message.

Overhead
^^^^^^^^

The current format used internally is dubbed "random indexed block" format, because it is based around messages being constructed at random order in an append-only format. As such every block knows the location of the next block in the chain, which can appear anywhere in the buffer. Each field also knows the location of its next sibling, also anywhere in the buffer.

Messages have a fixed overhead of 17 bytes, with an additional overhead of 15 bytes (+length of field name) per field. Each value stored in a field has eight bytes of overhead.

So a message such as:

- what: button
- pressed: boolean
- button: int8

Has a natural compact size of six bytes, but would be encoded as 38 bytes. This is an overhead of 600%. This only applies to very small messages as the overhead of messages approaches 200% as their size increases [tested via simulation with NumPy.]
