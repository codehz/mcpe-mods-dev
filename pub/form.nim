import player, json, hook, sequtils, unsafe, tables, hashes
{.passL:"lib/form.o -lstdc++ -L./out -lform_support".}

type
  Packet = distinct pointer
  Level = distinct pointer
  ServerNetworkHandler = ref object
    pad1: array[0x7, pointer]
    level: Level

proc sendPacket(player: Player, packet: Packet) {.importc:"_ZNK12ServerPlayer17sendNetworkPacketER6Packet".}
proc makeRequest(id: int, json: cstring): Packet {.importc.}
proc delete(packet: Packet) {.importc:"freeRequest".}
proc data(packet: Packet): cstring {.importc:"strRequest".}
# proc id(packet: Packet): int {.importc:"idRequest".}

type
  FormKind* {.pure.} = enum
    modal, custom, simple
  ControlKind* {.pure.} = enum
    label,input,toggle,slider,steps,dropdown
  Control* = object
    text*: string
    case kind*: ControlKind
    of ControlKind.label: nil
    of ControlKind.input: placeholder*, defaultInput*: string
    of ControlKind.toggle: defaultToggle*: bool
    of ControlKind.slider: min*, max*, step*, defaultSlider*: float32
    of ControlKind.steps:
      steps*: seq[string]
      defaultStep*: int
    of ControlKind.dropdown:
      options*: seq[string]
      defaultOption*: int
  FormModel* = object
    title*: string
    case kind*: FormKind
    of FormKind.modal:
      modal*, button1*, button2*: string
    of FormKind.custom:
      custom*: seq[Control]
    of FormKind.simple:
      simple*: string
      buttons*: seq[string]
  FormModelCallback* = proc (model: JsonNode)

proc `$`(fk: FormKind): string =
  case fk:
  of modal: "modal"
  of custom: "custom_form"
  of simple: "form"

proc `$`(fk: ControlKind): string =
  case fk:
  of label: "label"
  of input: "input"
  of toggle: "toggle"
  of slider: "slider"
  of steps: "step_slider"
  of dropdown: "dropdown"

proc `%`(ctl: Control): JsonNode =
  result = %* {
    "type": $ctl.kind,
    "text": ctl.text
  }
  case ctl.kind:
  of ControlKind.label: discard
  of ControlKind.input:
    result["placeholder"] = % ctl.placeholder
    result["default"] = % ctl.defaultInput
  of ControlKind.toggle:
    result["default"] = % ctl.defaultToggle
  of ControlKind.slider:
    result["min"] = % ctl.min
    result["max"] = % ctl.max
    result["step"] = % ctl.step
    result["default"] = % ctl.defaultSlider
  of ControlKind.steps:
    result["steps"] = % ctl.steps
    result["default"] = % ctl.defaultStep
  of ControlKind.dropdown:
    result["options"] = % ctl.options
    result["default"] = % ctl.defaultOption

proc `%`(model: FormModel): JsonNode =
  result = %* {
    "type": $model.kind,
    "title": model.title
  }
  case model.kind:
  of FormKind.modal:
    result["content"] = % model.modal
    result["button1"] = % model.button1
    result["button2"] = % model.button2
  of FormKind.custom:
    result["content"] = % model.custom
  of FormKind.simple:
    result["buttons"] = % model.buttons.mapIt(%* { "text": it })
    result["content"] = % model.simple

proc setPlayerFormCallback(player: Player, callback: FormModelCallback) {.importc.}
proc callback(player: Player): FormModelCallback {.importc:"queryPlayerFormCallback".}

hook "_ZN20ServerNetworkHandler6handleERK17NetworkIdentifierRK23ModalFormResponsePacket":
  proc resp(handler: ServerNetworkHandler, id: NetworkIdentifier, packet: Packet) =
    let cb = id.player.callback
    if cb != nil:
      cb(parseJson($packet.data))

type
  FormModelReq = object
    player: Player
    form: FormModel

proc sendForm*(player: Player, form: FormModel): FormModelReq =
  FormModelReq(player: player, form: form)

proc then*(req: FormModelReq, callback: FormModelCallback) =
  setPlayerFormCallback(req.player, callback)
  let packet = makeRequest(0, $ % req.form)
  req.player.sendPacket packet
  delete packet