import pub.hook, strformat
const ModBase {.strdefine.}: string = ""
{.passL: &"{ModBase}/cpp.o -lstdc++".}

proc sendMessage(player, packet: pointer) {.importc: "_ZNK12ServerPlayer17sendNetworkPacketER6Packet".}

proc ServerPlayer_sendNetworkPacket(player, packet: pointer) {.exportc.} = sendMessage(player, packet)

proc setupCommands(registry: pointer) {.importc.}

hook "_ZN10SayCommand5setupER15CommandRegistry":
  proc setupCommand(registry: pointer) {.refl.} =
    setupCommands(registry)

proc mod_init(): void {. cdecl, exportc .} =
  echo "Tellraw Loaded"