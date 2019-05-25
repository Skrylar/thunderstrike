
Messengers
==========

Factories
---------

.. code:: nim

    proc make_messenger(): Messenger

Validity testing
----------------

.. code:: nim

    proc is_valid(self: Messenger): bool

Checks whether this messenger is able to deliver messages to its target.

Locking
-------

.. code:: nim

    proc lock_target(self: var Messenger)
    proc lock_target_with_timeout(self: var Messenger; timeout: BigTime)

.. todo::

    These seem to rely on locking a looper, but those should be paired
    with calls to unlock. Neither Be or Haiku book seems to have a
    paired unlock, or a version which returns a locker, so these should
    remain unimplemented here until we figure out what to do with that.

Message transmission
--------------------

Messages have two basic versions:

:command: A compact, single integer is sent to trigger a notification.
:message: A structured message is constructed and sent.

Commands are useful when information is already known or shared by
other means, or messages that do not require parameters (such as
"pause," "resume," or "clicked button X.")

There are then two behaviors:

:synchronous:
    A message is delivered, then the caller waits for a response.
:asynchronous:
    A message is delivered and the caller continues. Responses are
    delegated to another messenger.

In all cases, sending a message will block until delivery is
complete. Only once the message has been placed in an appropriate
mailbox will execution continue.

.. code:: nim

    proc send(self: var Messenger;
              message, reply_to: Message;
              delivery_timeout, reply_timeout: BigTime = INFINITE_TIMEOUT)
    proc send(self: var Messenger;
              message: Message;
              reply_to: Handler;
              delivery_timeout: BigTime)

Sends a `message` to the messenger's target. This is a synchronous
operation.

If `reply_to` is a message, the reply is written to this object.

If `reply_to` is a handler, a message is constructed and dispatched
to the handler upon completion.

.. code:: nim

    proc send(self: var Messenger; message: Message; reply_to: Messenger; delivery_timeout: BigTime)

Sends a `message` to the messenger's target. This is an asynchronous
operation.

When the recipient responds, the message is dispatched to the supplied
messenger.

.. code:: nim

    proc send(self: var Messenger;
              command: uint32;
              reply_to: Message)
    proc send(self: var Messenger;
              command: uint32;
              reply_to: Handler)

Sends a `command` to the messenger's target. This is a synchronous
operation.

If `reply_to` is a message, the reply is written to this object.

If `reply_to` is a handler, a message is constructed and dispatched
to the handler upon completion.

Target information
------------------

.. code:: nim

    proc `target=`(self: var Messenger; looper: ref Looper)

Changes the target of this messenger to a local looper.

.. code:: nim

    proc is_target_local(self: var Messenger): bool

Returns whether the messenger dispatches to the same team/process
that it belongs to.

.. code:: nim

    proc team(self: Messenger): TeamId

Returns the Team that the messenger will deliver messages to. This
can either be the current team/process (local messages) or another
process on the computer (non-local messages.)

.. todo::

    Think about whether team IDs should always 1:1 to processes,
    or whether we should support some erlang-style clustering thing.

Operators
---------

.. code:: nim

    proc `==`(self, other: Messenger): bool

Two messengers are equal if they have the same target.

