
Flattenable
===========

Any object is considered `flattenable` where the following operations are defined:

 - Flatten
 - Unflatten
 - Check flattened size
 - Check for a fixed size
 - Is a certain type code allowed?
 - What type code is assigned to this object?

.. note:: The nature of using generics in Nim means there is no static typing to ensure what you think is a flattenable really is. If the behaviors are not defined, you will get possibly strange compile errors.

Flattening does not particularly care about the format used to keep an object. You can use raw binary dumps, protocol buffers, JSON, and so forth. Anything which can be written to a memory buffer and later read back is allowed.

Flattening and Unflatten/Decanting
----------------------------------

.. code:: nim

  proc flatten(self: Thing; buffer: pointer; headroom: uint)

To `flatten` an object means to write information about it in to a `buffer`, such that it can be loaded back at a later date. The `buffer` is expected to have at least `headroom` bytes ready for use. If this is not enough space to write the object, an exception should be thrown.

Particularly smart callers will consult ``flattened_size`` to see in advance if there is enough space or if more space must be allocated.

Headrooms have certain maximums and we cannot be held responsible if television journalists start to investigate you ten minutes from now.

.. code:: nim

  proc unflatten(self: var Thing; buffer; buffer: pointer; size: uint)

Size testing
------------

.. code:: nim

  proc flattened_size(x: Thing): int

This returns the number of bytes required to store *this particular* object.

.. code:: nim

  proc flattened_size(x: typedesc[Thing]): int

This returns the number of bytes required to store an object of this type either:

- If ``is_fixed_size`` is true, then the size this object will always be.
- Otherwise, the size to store an object of this type when it is completely empty.

.. code:: nim

  proc is_fixed_size(x: typedesc[Thing]): bool
  proc is_fixed_size(x: Thing): bool

Returns whether or not each instance of this object always consumes the same number of bytes.

Type codes
----------

.. code:: nim

  proc allows_type_code(x: typedesc[Thing]; code: TypeCode): bool
  proc allows_type_code(x: Thing; code: TypeCode): bool

Returns whether or not this object understands the supplied type code, and is capable of unflattening.

Ideally ``allows_type_code`` should return ``true`` for any values that can be returned by ``type_code``.

.. code:: nim

  proc type_code(x: typedesc[Thing]): TypeCode
  proc type_code(x: Thing): TypeCode

Returns the type code used to represent this object on the wire.

It is allowable for the type code to vary depending on context. You should ideally not return a type code which would be rejected by ``allows_type_code`` however, or you may end up creating flattened objects which cannot later be read.

