
Points
======

.. code:: nim

    type
        Point[T:float32|float64|int] = object
            x, y: T

A point is a pair of coordinates, dubbed `X` and `Y`. They are very common in 2D graphics ;)

.. code:: nim

    const
        ORIGINi= Point[int](x: 0, y: 0)
        ORIGINf32= Point[float32](x: 0.0, y: 0.0)
        ORIGINf64= Point[float64](x: 0.0, y: 0.0)

The `origin point` is typically located at (0, 0) in most coordinate systems. These origin constants offer a convenient way to refer to that position, such as when dealing with defaults.

.. code:: nim

    proc constrain_to[T](self: var Point[T]; rect: Rect[T])
    proc echo[T](self: Point[T])
    proc set_xy[T](self: var Point[T]; x, y: T)
    proc `==`[T](self: var Point[T]; other: Point[T]): bool
    proc `+`[T](self, other: Point[T]): Point[T]
    proc `+=`[T](self: var Point[T]; other: Point[T]): Point[T]
    proc `-`[T](self, other: Point[T]): Point[T]
    proc `-=`[T](self: var Point[T]; other: Point[T]): Point[T]

