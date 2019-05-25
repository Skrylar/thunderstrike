
import math, coretypes

type
    Point*[T:float32|float64|int] = object
        x*, y*: T

    Rect*[T:float32|float64|int] = object
        left*, top*, right*, bottom*: T

# POINTS
# =======================================================================

const
    ORIGINi= Point[int](x: 0, y: 0)
    ORIGINf32= Point[float32](x: 0.0, y: 0.0)
    ORIGINf64= Point[float64](x: 0.0, y: 0.0)

# Modifies point so it is contained by a rectangle.
proc constrain_to*[T](self: var Point[T]; rect: Rect[T]) =
    self.x = min(max(self.x, rect.left), rect.right)
    self.y = min(max(self.y, rect.top), rect.bottom)

# Returns a new point so it is contained by a rectangle.
proc with_constrain_to*[T](self: Point[T]; rect: Rect[T]): Point[T] =
    result = self
    result.constrain_to(rect)

# Echoes the point in the form Point(x, y)
proc echo*[T](self: Point[T]) =
    # TODO find idiomatic way to do a string conversion
    echo "Point(", self.x, ", ", self.y, ")"

# Change X and Y members simultaneously.
proc set_xy*[T](self: var Point[T]; x, y: T) =
    self.x = x
    self.y = y

proc negate*[T](self: var Point[T]) =
    self.x = -self.x
    self.y = -self.y

proc with_negation*[T](self: Point[T]): Point[T] =
    result = Point[T](x: -self.x, y: -self.y)

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

# Flattenable
# +++++++++++

proc flatten(self: buffer: pointer; headroom: uint) =
    # TODO

proc unflatten(self: buffer; buffer: pointer; size: uint) =
    # TODO

proc flattened_size(x: Point): int =
    return sizeof(x.x)+sizeof(s.y)

proc is_fixed_size(x: typedesc[Point]): bool {.inline.} =
    return true

proc is_fixed_size(x: Point): bool {.inline.} =
    return true

proc allows_type_code(x: typedesc[Point]; code: TypeCode): bool =
    return code == POINT_TYPE

proc allows_type_code(x: Point; code: TypeCode): bool =
    return allows_type_code(x.type, code)

proc type_code(x: typedesc[Point]): TypeCode {.inline.} =
    return POINT_TYPE

proc type_code(x: Point): TypeCode {.inline.} =
    return type_code(x.type)

# RECTANGLES
# =======================================================================

proc make_rect*[T](left, top, right, bottom: T): Rect[T] =
    result.left   = left
    result.top    = top
    result.right  = right
    result.bottom = bottom

proc make_rect*[T](leftTop, rightBottom: Point[T]): Rect[T] =
    result.left   = leftTop.x
    result.top    = leftTop.y
    result.right  = rightBottom.x
    result.bottom = rightBottom.y

proc width*[T](self: Rect[T]): T =
    result = self.right - self.left

proc height*[T](self: Rect[T]): T =
    result = self.bottom - self.top

proc `width=`*[T](self: Rect[T]; value: T) =
    self.right = self.left + value

proc `height=`*[T](self: Rect[T]; value: T) =
    self.bottom = self.top + value

proc contains*[T](self: Rect[T]; other: Point[T]): bool =
    result = (other.x >= self.left and other.x < self.right) and
        (other.y >= self.top and other.y < self.bottom)

proc contains*[T](self, other: Rect[T]): bool =
    if self.contains(other.lefttop) and self.contains(other.rightbottom):
        return true
    return false

proc intersects*[T](self, other: Rect[T]): bool =
    # https://stackoverflow.com/questions/13390333/two-rectangles-intersection
    if (self.right < other.left) or
        (other.right < self.left) or
        (self.bottom < other.top) or
        (other.bottom < self.top):
            return false
    return true

proc inset_by*[T](self: Rect[T]; x, y: T) =
    self.x -= x
    self.y -= y

proc outset_by*[T](self: Rect[T]; x, y: T) =
    self.x += x
    self.y += y

proc offset_by*[T](self: Rect[T]; x, y: T) =
    self.left += x
    self.right += x
    self.top += y
    self.bottom += y

proc offset_to*[T](self: Rect[T]; x, y: T) =
    var w, h: T
    w = width*[T](self)
    h = height*[T](self)
    self.left = x
    self.top = y
    self.width = w
    self.height = h

# [[[cog
# ops = ['inset_by', 'outset_by', 'offset_by', 'offset_to']
# for op in ops:
#   cog.outl("""proc {0}*[T](self: Rect[T]; point: T): Rect[T] {{.inline.}} =
#    {0}(self, point.x, point.y)""".format(op))
#   cog.outl()
#   cog.outl("""proc with_{0}*[T](self: Rect[T]; x, y: T): Rect[T] {{.inline.}} =
#    result = self
#    {0}(self, x, y)""".format(op))
#   cog.outl()
#   cog.outl("""proc with_{0}*[T](self: Rect[T]; point: T): Rect[T] {{.inline.}} =
#    result = self
#    {0}(self, point.x, point.y)""".format(op))
#   cog.outl()
# ]]]
proc inset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
   inset_by(self, point.x, point.y)

proc with_inset_by*[T](self: Rect[T]; x, y: T): Rect[T] {.inline.} =
   result = self
   inset_by(self, x, y)

proc with_inset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
   result = self
   inset_by(self, point.x, point.y)

proc outset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
   outset_by(self, point.x, point.y)

proc with_outset_by*[T](self: Rect[T]; x, y: T): Rect[T] {.inline.} =
   result = self
   outset_by(self, x, y)

proc with_outset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
   result = self
   outset_by(self, point.x, point.y)

proc offset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
   offset_by(self, point.x, point.y)

proc with_offset_by*[T](self: Rect[T]; x, y: T): Rect[T] {.inline.} =
   result = self
   offset_by(self, x, y)

proc with_offset_by*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
   result = self
   offset_by(self, point.x, point.y)

proc offset_to*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
   offset_to(self, point.x, point.y)

proc with_offset_to*[T](self: Rect[T]; x, y: T): Rect[T] {.inline.} =
   result = self
   offset_to(self, x, y)

proc with_offset_to*[T](self: Rect[T]; point: T): Rect[T] {.inline.} =
   result = self
   offset_to(self, point.x, point.y)

# [[[end]]]

proc is_valid*[T](self: Rect[T]): bool =
    return (self.right >= self.left) and
        (self.bottom >= self.top)

proc echo*[T](self: Rect[T]) =
    echo "Rect(", self.x, ", ", self.y, ")"

# [[[cog
# for x in ['left', 'right']:
#   for y in ['top', 'bottom']:
#     cog.outl("""proc {0}_{1}*[T](self: Rect[T]): Point[T] {{.inline.}} =
#     result.x = self.{0}
#     result.y = self.{1}""".format(x, y))
#     cog.outl("""proc `{0}_{1}=`*[T](self: Rect[T]; value: Point[T]): Point[T] {{.inline.}} =
#     self.x = value.{0}
#     self.y = value.{1}""".format(x, y))
# ]]]
proc left_top*[T](self: Rect[T]): Point[T] {.inline.} =
    result.x = self.left
    result.y = self.top
proc `left_top=`*[T](self: Rect[T]; value: Point[T]): Point[T] {.inline.} =
    self.x = value.left
    self.y = value.top
proc left_bottom*[T](self: Rect[T]): Point[T] {.inline.} =
    result.x = self.left
    result.y = self.bottom
proc `left_bottom=`*[T](self: Rect[T]; value: Point[T]): Point[T] {.inline.} =
    self.x = value.left
    self.y = value.bottom
proc right_top*[T](self: Rect[T]): Point[T] {.inline.} =
    result.x = self.right
    result.y = self.top
proc `right_top=`*[T](self: Rect[T]; value: Point[T]): Point[T] {.inline.} =
    self.x = value.right
    self.y = value.top
proc right_bottom*[T](self: Rect[T]): Point[T] {.inline.} =
    result.x = self.right
    result.y = self.bottom
proc `right_bottom=`*[T](self: Rect[T]; value: Point[T]): Point[T] {.inline.} =
    self.x = value.right
    self.y = value.bottom
# [[[end]]]

proc `==`*[T](self, other: Rect[T]): bool =
    result = (self.left == self.left) and
        (self.right == self.right) and
        (self.top == self.top) and
        (self.bottom == self.bottom)

# Intersection
proc `&`*[T](self, other: Rect[T]): Rect[T] =
    result.left   = max(self.left, other.left)
    result.top    = max(self.top, other.top)
    result.right  = min(self.right, other.right)
    result.bottom = min(self.bottom, other.bottom)

# Union
proc `|`*[T](self, other: Rect[T]): Rect[T] =
    result.left   = min(self.left, other.left)
    result.top    = min(self.top, other.top)
    result.right  = max(self.right, other.right)
    result.bottom = max(self.bottom, other.bottom)

