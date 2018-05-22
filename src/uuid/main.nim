import pub.hook, strformat
const ModBase {.strdefine.}: string = ""
{.passL: &"{ModBase}/cpp.o -lstdc++".}

proc setupCommands(registry: pointer) {.importc.}

hook "_ZN10SayCommand5setupER15CommandRegistry":
  proc setupCommand(registry: pointer) {.refl.} =
    setupCommands(registry)

proc mod_init(): void {. cdecl, exportc .} =
  echo "UUID Mod Loaded"
