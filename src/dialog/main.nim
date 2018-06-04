import pub.hook, pub.form, pub.player, strformat, json
const ModBase {.strdefine.}: string = ""
{.passL: &"{ModBase}/cpp.o -lstdc++".}

# let TestForm = register do (player: Player, data: JsonNode): echo data.pretty()

# let TestForm = register(FormModelFactory(
#   builder: proc (player: Player): FormModel =
#     # FormModel(
#     #   kind: FormKind.modal,
#     #   title: "Test Title",
#     #   modal: "Test Data",
#     #   button1: "Ok",
#     #   button2: "Cancel"
#     # )
#     # FormModel(
#     #   kind: FormKind.simple,
#     #   title: "Simple",
#     #   simple: "Just Test",
#     #   buttons: @["A", "B", "C", "D", "E", "F", "G"]
#     # )
    # FormModel(
    #   kind: FormKind.custom,
    #   title: "Custom",
    #   custom: @[
    #     Control(text: "A Label", kind: ControlKind.label),
    #     Control(text: "A Input", kind: ControlKind.input, placeholder: "username", defaultInput: "CodeHz"),
    #     Control(text: "A Toggle", kind: ControlKind.toggle, defaultToggle: false),
    #     Control(text: "A Slider", kind: ControlKind.slider, min: -1.0, max: 1.0, step: 0.1, defaultSlider: 0.3),
    #     Control(text: "A Steps", kind: ControlKind.steps, steps: @["A", "B", "C", "D"], defaultStep: 1),
    #     Control(text: "A Dropdown", kind: ControlKind.dropdown, options: @["A", "B", "C", "D"], defaultOption: 1),
    #   ]
    # ),
#   callback: proc (player: Player, data: JsonNode) =
#     echo data.pretty()
# ))

proc setupCommands(registry: pointer) {.importc.}

proc processCommand(player: Player): cstring {. cdecl, exportc .} =
  player.sendForm(FormModel(
    kind: FormKind.custom,
    title: "Custom",
    custom: @[
      Control(text: "A Label", kind: ControlKind.label),
      Control(text: "A Input", kind: ControlKind.input, placeholder: "username", defaultInput: "CodeHz"),
      Control(text: "A Toggle", kind: ControlKind.toggle, defaultToggle: false),
      Control(text: "A Slider", kind: ControlKind.slider, min: -1.0, max: 1.0, step: 0.1, defaultSlider: 0.3),
      Control(text: "A Steps", kind: ControlKind.steps, steps: @["A", "B", "C", "D"], defaultStep: 1),
      Control(text: "A Dropdown", kind: ControlKind.dropdown, options: @["A", "B", "C", "D"], defaultOption: 1),
    ]
  )).then do (data: JsonNode): echo data.pretty()

hook "_ZN10SayCommand5setupER15CommandRegistry":
  proc setupCommand(registry: pointer) {.refl.} =
    setupCommands(registry)

proc mod_init(): void {. cdecl, exportc .} =
  echo "Dialog Loaded"