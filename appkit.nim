
import coretypes

type
    Message* = object
    	what: uint32

    Looper* = object of Handler

    MessageReceivedHook* = proc(message: ref Message) {.closure.}
    SupportedSuitesHook* = proc(message: ref Message) {.closure.}
    ResolveSpecifierHook* = proc(message: ref Message;
                                 index: int32;
                                 specifier: ref Message;
                                 what: int32;
                                 property: string): ref Handler {.closure.}
    SendNoticesHook* = proc(what: uint32;
                            message: ref Message = nil) {.closure.}

    Handler* = object
        fmessage_received*: MessageReceivedHook
        fget_supported_suites*: SupportedSuitesHook
        fresolve_specifier*: ResolveSpecifierHook
        fsend_notices*: SendNoticesHook
        flooper: ref Looper
        ffilters: seq[MessageFilter]
        fname: string

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

    Messenger* = object
        ftarget: ref Looper

    MessageQueue* = object
        fqueue: seq[ref Message]

    MessageRunner* = object
        finterval: BigTime
        fcount: int

    PropertyInfoAtom* = object
        name*: string
        # zero-terminated arrays
        commands: array[0..10] of uint32
        specifiers: array[0..10] of uint32
        usage: string
        extra: pointer

    PropertyInfo* = object
   	atoms*: seq[PropertyInfoAtom]

    Roster* = object

    Invoker* = object
        freply: Handler
        fmessage: Message
        fcommand: uint32
        ftimeout: BigTime

    Cursor* = object

    Clipboard* = object

    AboutRequestedHook* = proc() {.closure.}
    AppActivatedHook* = proc(active: bool) {.closure.}
    ArgvReceivedHook* = proc(argc: int32; args: seq[string]) {.closure.}
    PulseHook* = proc() {.closure.}
    QuitRequestedHook* = proc(): bool {.closure.}
    ReadyToRunHook* = proc() {.closure.}
    RefsReceivedHook* = proc(message: ref Message) {.closure.}

    Application* = object of Looper
        fabout_requested_hook*: AboutRequestedHook
        fapp_activated_hook*: AppActivatedHook
        fargv_received_hook*: ArgvReceivedHook
        fpulse_hook*: PulseHook
        fquit_requested_hook*: QuitRequestedHook
        fready_to_run_hook*: ReadyToRunHook
        frefs_received_hook*: RefsReceivedHook

# Messages
# ========

proc make_message(what: uint32): Message =
    result.what = what

data

bool
int8
int16
int32
int64
float32
float64
string
point
rect
message
messenger
pointer
flat

# Messengers
# ==========

proc make_messenger(): Messenger =
    # XXX this messenger has no target
    return

proc is_valid*(self: Messenger): bool =
    discard # TODO
proc lock_target*(self: var Messenger) =
    discard # TODO
proc lock_target_with_timeout*(self: var Messenger; timeout: BigTime) =
    discard # TODO

proc send*(self: var Messenger; message, reply_to: ref Message; delivery_timeout, reply_timeout: BigTime = INFINITE_TIMEOUT)  =
    discard # TODO
proc send*(self: var Messenger; message: ref Message; reply_to: ref Handler; delivery_timeout: BigTime) =
    discard # TODO
proc send*(self: var Messenger; message: ref Message; reply_to: Messenger; delivery_timeout: BigTime) =
    discard # TODO
proc send*(self: var Messenger; command: uint32; reply_to: ref Message) =
    discard # TODO
proc send*(self: var Messenger; command: uint32; reply_to: ref Handler) =
    discard # TODO

proc target*(self: Messenger): Looper {.inline.} =
    return self.ftarget
proc `target=`*(self: var Messenger; looper: ref Looper) =
    self.ftarget = looper

proc is_target_local*(self: var Messenger): bool =
    return true # TODO

proc team*(self: Messenger): TeamId =
    return TeamId(0) # TODO

proc `==`*(self, other: Messenger): bool =
    return self.target == other.target

# Handlers
# ========

proc message_received*(self: Handler; message: ref Message) =
    if fmessage_received != nil:
        self.fmessage_received(message)

proc get_supported_suites*(self: Handler; message: ref Message) =
    if fget_supported_suite != nil:
        self.fget_supported_suite(message)

proc lock_looper(self: var Handler) =
    discard # TODO
proc lock_looper_with_timeout(self: var Handler) =
    discard # TODO
proc unlock_looper(self: var Handler) =
    discard # TODO

proc looper*(self: Handler): ref Looper {.inline.} =
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
    return self.ffilter

proc `filter_list=`*(self: var Handler; value: seq[MessageFilter]) {.inline.} =
    self.ffilter = value

proc add_filter*(filter: MessageFilter) =
    discard # TODO

proc remove_filter*(filter: MessageFilter) =
    discard # TODO

proc next_handler*(self: ref Handler): ref Handler {.inline.} =
    discard # TODO

proc `next_handler=`*(self: ref Handler; value: ref Handler) {.inline.} =
    discard # TODO

proc send_notices_hook*(self: var Messenger;
                        what: uint32;
                        message: ref Message = nil) =
    if self.fsend_notices != nil:
        self.fsend_notices(what, message)

proc start_watch(watcher: ref Messenger; what: uint32) =
    discard # TODO
proc start_watch(watcher: ref Handler; what: uint32) =
    discard # TODO
proc start_watch_all(watcher: ref Messenger) =
    discard # TODO
proc start_watch_all(watcher: ref Handler) =
    discard # TODO
proc stop_watch(watcher: ref Messenger; what: uint32) =
    discard # TODO
proc stop_watch(watcher: ref Handler; what: uint32) =
    discard # TODO
proc stop_watch_all(watcher: ref Messenger) =
    discard # TODO
proc stop_watch_all(watcher: ref Handler) =
    discard # TODO

# Message Filters
# ---------------

proc make_message_filter(message_delivery: MessageDelivery;
                         message_source: MessageSource;
                         command: uint32;
                         filter: FilterHook = nil): MessageFilter =
    discard # TODO

proc make_message_filter(message_delivery: MessageDelivery;
                         message_source: MessageSource;
                         filter: FilterHook = nil): MessageFilter =
    discard # TODO

proc make_message_filter(command: uint32;
                         filter: FilterHook = nil): MessageFilter =
    discard # TODO

proc command*(self: MessageFilter): uint32 {.inline.} =
    return self.ffilter

proc filters_any_command(self: MessageFilter): bool {.inline.} =
    return self.ffilter_any

proc message_source*(self: MessageFilter): MessageSource {.inline.} =
    return self.fmessage_source

proc message_delivery*(self: MessageFilter): MessageDelivery {.inline.} =
    return self.fmessage_delivery

proc looper*(self: MessageFilter): ref Handler {.inline.} =
    return self.flooper

proc filter*(self: MessageFilter;
             message: ref Message;
             target: var ref Handler): FilterResult =
    discard # TODO

# Message Queue
# =============

proc add_message*(message: ref Message) =
    discard # TODO

proc remove_message*(message: ref Message) =
    discard # TODO

proc count_messages*(self: MessageQueue): int {.inline.} =
    return len(self.fqueue)

proc empty*(self: MessageQueue): bool {.inline.} 
    return self.count_messages == 0

proc find_message*(self: MessageQueue; index: int) =
    discard # TODO

proc find_message*(self: MessageQueue; what: uint32; index: int = 0): int =
    discard # TODO

proc lock(self: var MessageQueue): bool =
    discard # TODO

proc unlock(self: var MessageQueue) =
    discard # TODO

proc next_message*(self: var MessageQueue) =
    discard # TODO

# Message runner
# ==============

proc make_message_runner*(target: ref Messenger;
                          message: ref Message;
                          interval: BigTime;
                          count: int = -1;
                          reply_to: ref Messager = nil): MessageRunner =
    discard # TODO

proc count*(self: MessageRunner): int {.inline.} =
    return self.fcount

proc `count=`*(self: MessageRunner; value: int) {.inline.} =
    self.fcount = value

proc interval*(self: MessageRunner): BigTime {.inline.} =
    return self.finterval

proc `interval=`*(self: MessageRunner; value: BigTime) {.inline.} =
    self.finterval = value

# Property information
# ====================

proc make_property_info*(): PropertyInfo =
    discard # TODO

proc make_property_info*(): PropertyInfo =
    discard # TODO

proc find_match(message: ref Message;
                index: int32;
                spec: ref Message;
                form: int32;
                property: string;
                data: pointer = nil) =
    discard # TODO

proc echo*(self: PropertyInfo) =
    echo "PropertyInfo(TODO)"

# Roster
# ======

proc activate_app*(team: team_id) =
    discard # TODO

proc add_to_recent_documents*(document: EntryRef;
                              app_sig: string = nil) =
    discard # TODO

proc get_recent_documents*(ref_list: var Message;
                           max_count: int32;
                           of_type: string = nil;
                           opened_by_app_sig: string = nil) =
    discard # TODO

proc get_recent_documents*(ref_list: var Message;
                           max_count: int32;
                           of_type_list: []string = nil;
                           opened_by_app_sig: string = nil) =
    discard # TODO

proc add_to_recent_folders*(folder: Entry_ref;
                            app_sig: string = nil) =
    discard # TODO

proc get_recent_folders*(ref_list: var Message;
                         max_count: int32
                         opened_by_app_sig: string = nil) =
    discard # TODO

proc broadcast*(message: var Message) =
    discard # TODO

proc broadcast*(message: var Message;
                reply_to: ref Messenger) =
    discard # TODO

proc find_app*(mimetype: string;
               app: EntryRef) =
    discard # TODO

proc find_app*(file: EntryRef;
               app: var EntryRef) =
    discard # TODO

proc get_app_info*(signature: string;
                   app_info: var AppInfo) =
    discard # TODO

proc get_app_info*(executable: EntryRef;
                   app_info: var AppInfo) =
    discard # TODO

proc get_running_app_info*(team: TeamId;
                           app_info: var AppInfo) =
    discard # TODO

proc get_active_app_info*(app_info: var AppInfo) =
    discard # TODO

proc get_app_list*(): seq[TeamId] =
    discard # TODO

proc get_app_list*(signature: string): seq[TeamId] =
    discard # TODO

proc get_recent_apps*(ref_list: var Message,
                      max_count: int32) =
    discard # TODO

proc launch*(mimetype: string;
             message: ref message = nil,
             team: TeamId = 0) =
    discard # TODO

proc launch*(mimetype: string;
             messages,: seq[ref message];
             team: TeamId = 0) =
    discard # TODO

proc launch*(mimetype: string;
             argc: int;
             argv: seq[string];
             team: TeamId = 0) =
    discard # TODO

proc launch*(file: EntryRef;
             message: ref message = nil,
             team: TeamId = 0) =
    discard # TODO

proc launch*(file: EntryRef;
             messages,: seq[ref message];
             team: TeamId = 0) =
    discard # TODO

proc launch*(file: EntryRef;
             argc: int;
             argv: seq[string];
             team: TeamId = 0) =
    discard # TODO

proc start_watching*(target: var Messenger
                     events: uint32) =
    discard # TODO

proc stop_watching*(target: var Messenger) =
    discard # TODO

proc team_for*(signature: string): TeamId =
    discard # TODO

proc team_for*(executable: EntryRef): TeamId =
    discard # TODO

proc is_running*(signature: string): bool =
    discard # TODO

proc is_running*(executable: EntryRef): bool =
    discard # TODO

# Invoker
# =======

proc make_invoker*(): Invoker =
    discard # TODO
proc make_invoker*(message: Message; messenger: Messenger): Invoker =
    discard # TODO
proc make_invoker*(message: Message; handler: Handler; looper: Looper): Invoker =
    discard # TODO

proc begin_invoke_notify*(kind: uint32) =
    discard # TODO
proc end_invoke_notify*() =
    discard # TODO
proc invoke*(message: ref Message = nil) =
    discard # TODO
proc invoke_notify*(message: ref Message; kind: uint32) =
    discard # TODO
proc invoke_kind*(notify: var bool): uint32 =
    discard # TODO

proc handler_for_reply*(self: Invoker): Handler {.inline.} =
    return self.fhandler

proc `handler_for_reply=`*(self: Invoker; value: Handler) {.inline.} =
    self.fhandler = value

proc message*(self: Invoker): ref Message {.inline.} =
    return self.fmessage

proc `message=`*(self: Invoker: value: ref Message) {.inline.} =
    self.fmessage = value

proc command*(self: Invoker): uint32 {.inline.} =
    return self.fcommand

proc `command=`*(self: Invoker: value: uint32) {.inline.} =
    self.fcommand = value

proc set_target*(messenger: Messenger) =
    discard # TODO

proc set_target*(handler: Handler; looper: Looper = nil) =
    discard # TODO

proc target*(looper: var ref looper = nil): ref Handler =
    discard # TODO

proc is_target_local*(): bool =
    return true # TODO

proc messenger*(self: Invoker): Messenger =
    discard # TODO

proc timeout*(self: Invoker): BigTime =
    return self.ftimeout

proc `timeout=`*(self: Invoker; value: BigTime) =
    self.ftimeout = value

# Clipboard
# =========

proc make_clipboard*(name: string): Clipboard =
    discard # TODO

proc clear*(self: var Clipboard) =
    discard # TODO
proc commit*(self: var Clipboard) =
    discard # TODO
proc revert*(self: var Clipboard) =
    discard # TODO

proc data*(self: var Clipboard): ref Message =
    return nil # TODO

# These might get removed since they don't appear to mean much.
# 
# Be and Haiku have arbitrary application clipboards, while X11 has
# around 3 and Windows/mac have the 1.
# 
# Supporting clipboards via DDE or unix socket metaphors is possible. Note
# that in those cases there also isn't much meaning to the 'count'
# of unix sockets or DDE stuffs.
proc local_count(self: Clipboard): uint32 =
    return 0 # TODO
proc system_count(self: Clipboard): uint32 =
    return 0 # TODO

proc lock*(self: var Clipboard): bool =
    discard # TODO
proc unlock*(self: var Clipboard) =
    discard # TODO
proc is_locked*(self: Clipboard): bool =
    discard # TODO

proc name*(self: Clipboard): string {.inline.} =
    return self.fname

proc start_watching*(self: var Clipboard; target: Messenger) =
    discard # TODO
proc stop_watching*(self: var Clipboard; target: Messenger) =
    discard # TODO

# Application
# ===========

proc make_application*(signature: string): Application =
    discard # TODO

proc get_app_info*(self: Application; var AppInfo) =
    discard # TODO

proc get_supported_suites*(self: Application; message: var Message) =
    discard # TODO

proc is_launching*(self: Application): bool =
    discard # TODO

proc run*(self: Application) =
    discard # TODO

proc quit*(self: Application) =
    discard # TODO

proc hide_cursor*(self: var Application) =
    discard # TODO
proc show_cursor*(self: var Application) =
    discard # TODO
proc obscure_cursor*(self: var Application) =
    discard # TODO

proc is_cursor_hidden*(self: var Application): bool =
    discard # TODO
proc `is_cursor_hidden=`*(self: var Application; value: bool) =
    discard # TODO

proc pulse_rate*(self: Application): BigTime =
    discard # TODO
proc `pulse_rate=`*(self: var Application; value: BigTIme) =
    discard # TODO

proc window_at*(self: Application; index: int32) =
    discard # TODO
proc count_windows*(self: Application): int32 =
    discard # TODO

