
========================
 Test Anything Protocol
========================

This module is for `Test Anything Protocol
<http://testanything.org/>`_, version 13.

A utility for writing TAP output called the ``TapWriter`` is defined
in ``tap.nim``:

.. code:: nim

   TapWriter = object

TAP primarily deals with things that are "ok," or "not ok." Some uses also include the use of test names or comments after each case. Because of this you will often see a function with no arguments, a function with a name argument, and a function with both name and comment arguments.

.. todo:: Variants that accept test numbers, in case tests are run out of order for some reason.

.. todo:: Wrappers that provide "assert_something" semantics, and emit proper difference messages.

.. todo:: Macros to provide a familiar interface for creating suites, teardowns, etc.

Lifecycle
---------

The typical lifecycle of a TapWriter is as follows:

 - Create one with a `make` proc.
 - Tell it how many tests you will run.
 - Run tests, reporting results with `ok` or `not_ok`.
 - Call `done` and quit.

.. code:: nim

  make_tap_writer(): TapWriter
  make_tap_writer(cases: int): TapWriter

Creates and returns a TAP writer.

If no number of cases are specified or the number of cases specified is zero, it is assumed a suite does not know how many tests it plans to run.

Otherwise it will prepare to run `cases` number of tests.

.. note::
   Strictly speaking it is not an error to run a number of tests different from what you planned, but most TAP harnesses consider this an error.

   One reason is to catch glitches such as a suite saying it will check 30 files and then checking 29, indicating an off-by-one error in a loop somewhere.

.. code:: nim

   start(writer: var TapWriter)

Indicates the test suite is now going to run.

This will print the TAP version header, and if necessary the test plan indicating how many test results to expect.

.. code:: nim

   done(writer: var TapWriter)

Indicates the test suite is finished.

If necessary the number of tests actually reported by the suite are printed as a test footer.

Test Results
------------

.. code:: nim

   proc ok(writer: var TapWriter)
   proc ok(writer: var TapWriter; name: string)
   proc ok(writer: var TapWriter; name, comment: string)

Indicates a test completed successfully. ``name`` is the optional name
of the test being run.

.. code:: nim

   proc not_ok(writer: var TapWriter)
   proc not_ok(writer: var TapWriter; name: string)
   proc not_ok(writer: var TapWriter; name, comment: string)
   proc fail(writer: var TapWriter)
   proc fail(writer: var TapWriter; name: string)
   proc fail(writer: var TapWriter; name, comment: string)

Indicates a test failed. ``name`` is the optional name of the test
being run.

`Fail` is a a synonym for `not ok`.

.. code:: nim

   proc skip(writer: var TapWriter)
   proc skip(writer: var TapWriter; name: string)
   proc skip(writer: var TapWriter; name, comment: string)

Indicates a test was not run. ``name`` is the optional name of the
test that was not run.

Extreme Failure
---------------

.. code:: nim

   proc bail_out(writer: var TapWriter)
   proc bail_out(writer: var TapWriter; reason: String)

Indicates a severe problem has ocurred, and the testing harness itself
has to abort. This is typically something *very* wrong like an
external database connection being lost, as simple failures should
probably be a failed test instead.
