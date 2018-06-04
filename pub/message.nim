import player

{.passL:"lib/packet.o -lstdc++".}

proc sendMessage(player, packet: pointer) {.importc: "_ZNK12ServerPlayer17sendNetworkPacketER6Packet".}
proc ServerPlayer_sendNetworkPacket(player, packet: pointer) {.exportc.} = sendMessage(player, packet)

proc sendSystemMessage*(player: Player, msg: cstring) {.importc.}
