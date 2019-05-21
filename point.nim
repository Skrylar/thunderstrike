
import rect

type
    Point*[T:float32|float64|int] = object
        x*, y*: T

const
    ORIGINi= Point[int](x: 0, y: 0)
    ORIGINf32= Point[float32](x: 0.0, y: 0.0)
    ORIGINf64= Point[float64](x: 0.0, y: 0.0)

# Modifies point so it is contained by a rectangle.
proc constrain_to*[T](self: var Point[T]; rect: Rect[T]) =
    # TODO
    return

# Echoes the point in the form Point(x, y)
proc echo*[T](self: Point[T]) =
    # TODO find idiomatic way to do a string conversion
    echo "Point(", self.x, ", ", self.y, ")"

# Change X and Y members simultaneously.
proc set_xy*[T](self: var Point[T]; x, y: T) =
    self.x = x
    self.y = y

proc `==`*[T](self: var Point[T]; other: Point[T]): bool =
    result = (self.x == other.x) and (self.y == other.y)

proc `+`*[T](self, other: Point[T]): Point[T] =
    result = Point[T](x: self.x + other.x, y: self.y + other.y)

proc `+=`*[T](self: var Point[T]; other: Point[T]): Point[T] =
    self.x += other.x
    self.y += other.y

proc `-`*[T](self, other: Point[T]): Point[T] =
    result = Point[T](x: self.x - other.x, y: self.y - other.y)

proc `-=`*[T](self: var Point[T]; other: Point[T]): Point[T] =
    self.x -= other.x
    self.y -= other.y

