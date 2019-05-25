
Archivables
===========

Where Flattenable objects have to do with storing arbitrary binary
sequences in buffers with type codes, Archivables instead deal with
storing objects in an explicit structured format.

The format used to archive an object is the `Message`. You
write archived fields in to the message supplied to you, or
instantiate/decant an object from an existing message.

.. todo::

    Be Book mentions treating ``class`` field as an array, where child
    classes add themselves to the end as an object is archived. Should
    look in to the ramifications of this.

Archiving
---------

.. code:: nim

    proc archive(self: Type; archive: Message; deep: bool)

:self: The object to be archived.
:archive: A message to write information in to.
:deep: Whether a "deep copy" should be made in to the message.

Archive procedures are deeply advised to place a string in the
``class`` field, which informs later unarchival efforts on how to
find the proper procedure to read the object later on.

What a `deep` archive means is largely up to the objects themselves. It
could mean nothing at all, it could mean that short-lived handles
are written instead of doing nested writes, and so on.

Retrieving from an Archive
--------------------------

Be/Haiku refer to this as `instantiating` an object. Skrylar refers
to this as `decanting` an object. Java and Delphi refer to this as
`deserializing`.

In all cases you take a message where an object has been archived,
and pass it to a function that reverses the process and returns a
new object.

.. code:: nim

    proc instantiate(archive: ref Message): Type

.. todo::

    We need to think about how decanting works with through generics
    and closures.

    If an object knows all the things it expects to decant, then it
    can check the ``class`` field of an archive and call the known
    decanter right away. But if we need to start dealing with inherited
    objects / special cases, this could get inconvenient.

    Probably this is done by wrapping the typed ``instantiate`` in
    a closure with a known format, which can be put in a table to do
    class name -> closure lookups.

    Then we need to investigate the RTTI modules to see about
    returning the ``Any`` type and converting that in to something
    we have knowledge of.

