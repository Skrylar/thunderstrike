
Geometry
========

Points
------

.. code:: nim

    type
        Point[T:float32|float64|int] = object
            x, y: T

A point is a pair of coordinates, dubbed `X` and `Y`. They are very
common in 2D graphics ;)

.. code:: nim

    const
        ORIGINi= Point[int](x: 0, y: 0)
        ORIGINf32= Point[float32](x: 0.0, y: 0.0)
        ORIGINf64= Point[float64](x: 0.0, y: 0.0)

The `origin point` is typically located at (0, 0) in most coordinate
systems. These origin constants offer a convenient way to refer to
that position, such as when dealing with defaults.

.. code:: nim

    proc constrain_to[T](self: var Point[T]; rect: Rect[T])

Adjusts the point so it fits within `rect`.

.. code:: nim

    proc with_constrain_to[T](self: Point[T]; rect: Rect[T]): Point[T]

Returns a new rectangle that fits within `rect`.

.. code:: nim

    proc echo[T](self: Point[T])

Echoes this point in the form `Point(x,y)` to stdout.

.. code:: nim

    proc set_xy[T](self: var Point[T]; x, y: T)

.. code:: nim

    proc negate[T](self: var Point[T])

.. code:: nim

    proc with_negation[T](self: Point[T]): Point[T]

.. code:: nim

    proc `==`[T](self: var Point[T]; other: Point[T]): bool

.. code:: nim

    proc `+`[T](self, other: Point[T]): Point[T]

.. code:: nim

    proc `+=`[T](self: var Point[T]; other: Point[T]): Point[T]

.. code:: nim

    proc `-`[T](self, other: Point[T]): Point[T]

.. code:: nim

    proc `-=`[T](self: var Point[T]; other: Point[T]): Point[T]


.. code:: nim

    proc flatten(self: Point; headroom: uint)
    proc unflatten(self: Point; buffer: pointer; size: uint)
    proc flattened_size(x: Point): int
    proc is_fixed_size(x: typedesc[Point]): bool
    proc is_fixed_size(x: Point): bool
    proc allows_type_code(x: typedesc[Point]; code: TypeCode): bool
    proc allows_type_code(x: Point; code: TypeCode): bool
    proc type_code(x: typedesc[Point]): TypeCode
    proc type_code(x: Point): TypeCode

These make it so that a point can be flattened.

.. todo:: Not implemented.

Rect
----

.. code:: nim

    type
        Rect*[T:float32|float64|int] = object
            left*, top*, right*, bottom*: T

.. code:: nim

    proc make_rect*[T](left, top, right, bottom: T): Rect[T] =
    proc make_rect*[T](leftTop, rightBottom: Point[T]): Rect[T] =
    proc width*[T](self: Rect[T]): T =
    proc height*[T](self: Rect[T]): T =
    proc `width=`*[T](self: Rect[T]; value: T) =
    proc `height=`*[T](self: Rect[T]; value: T) =
    proc contains*[T](self: Rect[T]; other: Point[T]): bool =
    proc contains*[T](self, other: Rect[T]): bool =
    proc intersects*[T](self, other: Rect[T]): bool =
    proc inset_by*[T](self: Rect[T]; x, y: T) =
    proc outset_by*[T](self: Rect[T]; x, y: T) =
    proc offset_by*[T](self: Rect[T]; x, y: T) =
    proc offset_to*[T](self: Rect[T]; x, y: T) =
    proc inset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
    proc with_inset_by*[T](self: Rect[T]; x, y: T): Rect[T] {.inline.} =
    proc with_inset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
    proc outset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
    proc with_outset_by*[T](self: Rect[T]; x, y: T): Rect[T] {.inline.} =
    proc with_outset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
    proc offset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
    proc with_offset_by*[T](self: Rect[T]; x, y: T): Rect[T] {.inline.} =
    proc with_offset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
    proc offset_to*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
    proc with_offset_to*[T](self: Rect[T]; x, y: T): Rect[T] {.inline.} =
    proc with_offset_to*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
    proc is_valid*[T](self: Rect[T]): bool =
    proc echo*[T](self: Rect[T]) =
    proc left_top*[T](self: Rect[T]): Point[T] {.inline.} =
    proc `left_top=`*[T](self: Rect[T]; value: Point[T]): Point[T] {.inline.} =
    proc left_bottom*[T](self: Rect[T]): Point[T] {.inline.} =
    proc `left_bottom=`*[T](self: Rect[T]; value: Point[T]): Point[T] {.inline.} =
    proc right_top*[T](self: Rect[T]): Point[T] {.inline.} =
    proc `right_top=`*[T](self: Rect[T]; value: Point[T]): Point[T] {.inline.} =
    proc right_bottom*[T](self: Rect[T]): Point[T] {.inline.} =
    proc `right_bottom=`*[T](self: Rect[T]; value: Point[T]): Point[T] {.inline.} =
    proc `==`*[T](self, other: Rect[T]): bool =
    proc `&`*[T](self, other: Rect[T]): Rect[T] =
    proc `|`*[T](self, other: Rect[T]): Rect[T] =

