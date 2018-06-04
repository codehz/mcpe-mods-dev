import pub.hook, pub.player, pub.uuid, strformat, os, streams
const ModBase {.strdefine.}: string = ""
{.passL: &"{ModBase}/cpp.o -lstdc++".}

let uuid_path = getCurrentDir() / "games" / "uuid.log"

proc setupCommands(registry: pointer) {.importc.}

hook "_ZN10SayCommand5setupER15CommandRegistry":
  proc setupCommand(registry: pointer) {.refl.} =
    setupCommands(registry)

onPlayerJoined do (player: Player):
  let name = player.name
  echo player.uuid, "#", name
  try:
    let filestream = newFileStream(uuid_path, fmAppend, 4096)
    defer: filestream.close()
    filestream.writeLine($player.uuid & "#" & name)
  except: discard

proc mod_init(): void {. cdecl, exportc .} =
  echo "UUID Mod Loaded"
