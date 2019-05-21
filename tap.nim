
type
    TapWriter* = object
        cases, already_run: int

# Creates a TAP writer that does not know how many tests it will run.
proc make_tap_writer*(): TapWriter =
    result.cases = 0
    result.already_run = 0

# Creates a TAP writer that expects to write a set number of cases.
proc make_tap_writer*(cases: int): TapWriter =
    result.cases = cases
    result.already_run = 0

proc start*(writer: var TapWriter) =
    echo "TAP version 13"
    if writer.cases > 0:
        echo "1..", writer.cases

proc ok*(writer: var TapWriter) =
    inc writer.already_run
    echo "ok ", writer.already_run

proc ok*(writer: var TapWriter; name: string) =
    inc writer.already_run
    echo "ok ", writer.already_run, " - ", name

proc ok*(writer: var TapWriter; name, comment: string) =
    inc writer.already_run
    if name.len > 0:
        echo "ok ", writer.already_run, " - ", name, " # ", comment
    else:
        echo "ok ", writer.already_run, " # ", comment

proc skip*(writer: var TapWriter) =
    inc writer.already_run
    echo "ok ", writer.already_run, " # SKIP"

proc skip*(writer: var TapWriter; name: string) =
    inc writer.already_run
    echo "ok ", writer.already_run, " - ", name, " # SKIP"

proc skip*(writer: var TapWriter; name, comment: string) =
    inc writer.already_run
    if name.len > 0:
        echo "not ok ", writer.already_run, " - ", name, " # SKIP ", comment
    else:
        echo "not ok ", writer.already_run, " # SKIP ", comment

proc not_ok*(writer: var TapWriter) =
    inc writer.already_run
    echo "not ok ", writer.already_run

proc not_ok*(writer: var TapWriter; name: string) =
    inc writer.already_run
    echo "not ok ", writer.already_run, " - ", name

proc not_ok*(writer: var TapWriter; name, comment: string) =
    inc writer.already_run
    if name.len > 0:
        echo "not ok ", writer.already_run, " - ", name, " # ", comment
    else:
        echo "not ok ", writer.already_run, " # ", comment

template fail(writer: var TapWriter) =
    not_ok(writer)

proc bailout*(writer: var TapWriter) =
    echo "Bail out!"

proc bailout*(writer: var TapWriter; reason: string) =
    echo "Bail out! ", reason

proc done*(writer: var TapWriter) =
    if writer.cases == 0:
        echo "1..", writer.already_run

