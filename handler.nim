
import coretypes, message

type
    MessageReceivedHook* = proc(message: ref Message) {.closure.}
    SupportedSuitesHook* = proc(message: ref Message) {.closure.}
    ResolveSpecifierHook* = proc(message: ref Message;
                                 index: int32;
                                 specifier: ref Message;
                                 what: int32;
                                 property: string): ref Handler {.closure.}
    SendNoticesHook* = proc(what: uint32;
                            message: ref Message = nil) {.closure.}

    Handler* = ref object of RootObj
        fmessage_received*: MessageReceivedHook
        fget_supported_suites*: SupportedSuitesHook
        fresolve_specifier*: ResolveSpecifierHook
        fsend_notices*: SendNoticesHook
        flooper: Looper
        ffilters: seq[MessageFilter]
        fname: string

    Looper* = ref object of Handler

    MessageSource* = enum
        AnySource
        RemoteSource
        LocalSource

    MessageDelivery* = enum
        AnyDelivery
        DroppedDelivery
        ProgrammedDelivery

    FilterResult* = enum
        SkipMessage
        DispatchMessage

    FilterHook* = proc(message: ref Message;
                       target: var ref Handler) {.closure.}

    MessageFilter* = object
        ffilter_any: bool
        ffilter: uint32
        fhook: FilterHook
        flooper: Handler
        fmessage_source: MessageSource
        fmessage_delivery: MessageDelivery

    MessageQueue* = object
        fqueue: seq[ref Message]

# Looper
# ======

proc lock*(self: Looper; timeout: BigTime = INFINITE_TIMEOUT): bool =
    discard

proc unlock*(self: Looper) =
    discard

# Handlers
# ========

proc init*(self: Handler; name: string; default_handlers: bool) =
    self.fname = name
    discard default_handlers # ... for now

proc make_handler*(name: string = ""; default_handlers: bool = true): Handler =
    new(result)
    result.init(name, default_handlers)

proc message_received*(self: Handler; message: ref Message) =
    if self.fmessage_received != nil:
        self.fmessage_received(message)

proc get_supported_suites*(self: Handler; message: ref Message) =
    if self.fget_supported_suites != nil:
        self.fget_supported_suites(message)

proc lock_looper*(self: Handler; timeout: BigTime = INFINITE_TIMEOUT): bool =
    if self.flooper == nil: return false
    return self.flooper.lock(timeout)

proc unlock_looper*(self: Handler) =
    if self.flooper == nil: return
    self.flooper.unlock()

proc looper*(self: Handler): Looper {.inline.} =
    return self.flooper

proc resolve_specifier*(self: Handler;
                        message: ref Message;
                        index: int32;
                        specifier: ref Message;
                        what: int32;
                        property: string): ref Handler =
    return self.fresolve_specifier(message, index, specifier, what, property)

proc name*(self: Handler): string {.inline.} =
    return self.fname

proc `name=`*(self: var Handler; value: string) =
    # XXX do we need to tell anyone else we're renamed now?
    self.fname = value

proc filter_list*(self: Handler): seq[MessageFilter] {.inline.} =
    return self.ffilters

proc `filter_list=`*(self: var Handler; value: seq[MessageFilter]) {.inline.} =
    self.ffilters = value

proc add_filter*(filter: MessageFilter) =
    assert(false, "Not implemented.")

proc remove_filter*(filter: MessageFilter) =
    assert(false, "Not implemented.")

proc next_handler*(self: ref Handler): ref Handler {.inline.} =
    assert(false, "Not implemented.")

proc `next_handler=`*(self: ref Handler; value: ref Handler) {.inline.} =
    assert(false, "Not implemented.")

proc send_notices_hook*(self: var Handler;
                        what: uint32;
                        message: ref Message = nil) =
    if self.fsend_notices != nil:
        self.fsend_notices(what, message)

#proc start_watching*(watcher: ref Messenger; what: uint32) =
    #assert(false, "Not implemented.")
proc start_watching*(self: Handler; watcher: Handler; what: uint32) =
    assert(false, "Not implemented.")
#proc start_watching_all*(self: Handler; watcher: Messenger) =
    #assert(false, "Not implemented.")
proc start_watching_all*(self: Handler; watcher: Handler) =
    assert(false, "Not implemented.")
#proc stop_watching*(self: Handler; watcher: Messenger; what: uint32) =
    #assert(false, "Not implemented.")
proc stop_watching*(self: Handler; watcher: Handler; what: uint32) =
    assert(false, "Not implemented.")
#proc stop_watching_all*(self: Handler; watcher: Messenger) =
    #assert(false, "Not implemented.")
proc stop_watching_all*(self: Handler; watcher: Handler) =
    assert(false, "Not implemented.")




var h = make_handler()
h.start_watching_all(h)

