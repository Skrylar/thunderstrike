
import coretypes, message

type
    MessageReceivedHook* = proc(message: ref Message) {.closure.}
    SupportedSuitesHook* = proc(message: ref Message) {.closure.}
    ResolveSpecifierHook* = proc(message: ref Message;
                                 index: int32;
                                 specifier: ref Message;
                                 what: int32;
                                 property: string): Handler {.closure.}
    SendNoticesHook* = proc(what: uint32;
                            message: ref Message = nil) {.closure.}

    HandlerWatcher = object
        #messenger*: Messenger
        handler*: Handler
        state*: uint32

    Handler* = ref object of RootObj
        fmessage_received*: MessageReceivedHook
        fget_supported_suites*: SupportedSuitesHook
        fresolve_specifier*: ResolveSpecifierHook
        fsend_notices*: SendNoticesHook
        flooper: Looper
        ffilters: seq[MessageFilter]
        fnext_handler: Handler
        fname: string
        fwatchers: seq[HandlerWatcher]

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

    MessageFilter* = ref object
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

proc locked*(self: Looper): bool =
    return false

# Handler watcher
# ===============

proc `==`(self, other: HandlerWatcher): bool =
    return (self.handler == other.handler) and (self.state == other.state)

# Handlers
# ========

proc is_watched*(self: Handler): bool =
    return len(self.fwatchers) > 0

proc message_received*(self: Handler; message: ref Message) =
    if self.fmessage_received != nil:
        self.fmessage_received(message)

proc do_send_notices(self: Handler; what: uint32; message: ref Message = nil) =
    # if nobody is in the forest, the tree doesn't make a sound...
    if not self.is_watched: return
    for x in self.fwatchers:
        if (x.state == WATCH_ALL) or (x.state == what):
            if x.handler != nil:
                x.handler.message_received(message)

proc init*(self: Handler; name: string; default_handlers: bool) =
    self.fname = name
    if not default_handlers: return
    self.fget_supported_suites = proc(data: ref Message) =
        # no supported suites, for now
        discard
    self.fresolve_specifier = proc(message: ref Message; index: int32; specifier: ref Message; what: int32; property: string): Handler =
        # no specifiers to resolve at this level
        return self
    self.fsend_notices = proc(what: uint32; message: ref Message) =
        self.do_send_notices(what, message)

proc make_handler*(name: string = ""; default_handlers: bool = true): Handler =
    new(result)
    result.init(name, default_handlers)

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
                        property: string): Handler =
    return self.fresolve_specifier(message, index, specifier, what, property)

proc name*(self: Handler): string {.inline.} =
    return self.fname

proc `name=`*(self: Handler; value: string) {.inline.} =
    # XXX do we need to tell anyone else we're renamed now?
    self.fname = value

proc filter_list*(self: Handler): seq[MessageFilter] {.inline.} =
    return self.ffilters

proc `filter_list=`*(self: var Handler; value: seq[MessageFilter]) {.inline.} =
    self.ffilters = value

proc add_filter*(self: Handler; filter: MessageFilter) =
    if not (filter in self.ffilters):
        self.ffilters.add(filter)

proc remove_filter*(self: Handler; filter: MessageFilter) =
    var i = self.ffilters.find(filter)
    if i >= 0:
        self.ffilters.delete(i)

proc next_handler*(self :Handler): Handler {.inline.} =
    return self.fnext_handler

proc `next_handler=`*(self, value: Handler) {.inline.} =
    assert(self.flooper != nil)
    assert(locked(self.flooper))
    assert(value.flooper == self.flooper)
    self.fnext_handler = value

proc send_notices_hook*(self: var Handler;
                        what: uint32;
                        message: ref Message = nil) =
    if self.fsend_notices != nil:
        self.fsend_notices(what, message)

#proc start_watching*(watcher: ref Messenger; what: uint32) =
    #assert(false, "Not implemented.")

proc start_watching*(self: Handler; watcher: Handler; what: uint32) =
    var watcher = HandlerWatcher(state: what, handler: watcher)
    if not (watcher in self.fwatchers):
        self.fwatchers.add(watcher)

#proc start_watching_all*(self: Handler; watcher: Messenger) =
    #assert(false, "Not implemented.")

proc start_watching_all*(self: Handler; watcher: Handler) =
    start_watching(self, watcher, WATCH_ALL)

#proc stop_watching_all*(self: Handler; watcher: Messenger) =
    #assert(false, "Not implemented.")

proc stop_watching_all*(self: Handler; watcher: Handler) =
    var i = 0
    while i < len(self.fwatchers):
        if self.fwatchers[i].handler == watcher:
            self.fwatchers.delete(i)
        else:
            inc i

#proc stop_watching*(self: Handler; watcher: Messenger; what: uint32) =
    #assert(false, "Not implemented.")

proc stop_watching*(self: Handler; watcher: Handler; what: uint32) =
    var watcher = HandlerWatcher(state: what, handler: watcher)
    var i = self.fwatchers.find(watcher)
    if i >= 0:
        self.fwatchers.delete(i)

proc send_notices*(self: Handler; what: uint32; message: ref Message = nil) =
    if self.fsend_notices != nil:
        self.fsend_notices(what, message)

var h = make_handler()
h.stop_watching(h, 1)

