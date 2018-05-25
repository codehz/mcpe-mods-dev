import pub.hook, strformat, os, streams
const ModBase {.strdefine.}: string = ""
{.passL: &"{ModBase}/cpp.o -lstdc++".}

type
  Player = distinct pointer

let uuid_path = getCurrentDir() / "games" / "uuid.log"

proc name(player: Player) : var cstring {. importc: "_ZNK6Entity10getNameTagEv" .}
proc getUUID(player: Player) : var cstring {.importc.}

proc setupCommands(registry: pointer) {.importc.}

hook "_ZN10SayCommand5setupER15CommandRegistry":
  proc setupCommand(registry: pointer) {.refl.} =
    setupCommands(registry)

hook "_ZNK9minecraft3api15PlayerInterface23handlePlayerJoinedEventER6Player":
  proc onPlayerJoin(self: pointer, player: Player): void {. refl .} =
    let name = $player.name
    echo player.getUUID, "#", name
    try:
      let filestream = newFileStream(uuid_path, fmAppend, 4096)
      defer: filestream.close()
      filestream.writeLine($player.getUUID & "#" & $name)
    except: discard

proc mod_init(): void {. cdecl, exportc .} =
  echo "UUID Mod Loaded"
