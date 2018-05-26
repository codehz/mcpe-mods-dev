import pub.hook, strformat, strutils
const ModBase {.strdefine.}: string = ""
{.passL: &"{ModBase}/cpp.o -lstdc++".}

type
  Player = distinct pointer
  BlockEntity = distinct ptr ptr pointer
  BlockPos = distinct pointer

proc getSelectedName(player: Player): cstring {.importc.}
proc getBlockEntity(player: Player, pos: BlockPos): BlockEntity {.importc.}
proc getBlockEntityName(entity: BlockEntity): cstring {.importc.}
proc sendMessage(player, packet: pointer) {.importc: "_ZNK12ServerPlayer17sendNetworkPacketER6Packet".}
proc ServerPlayer_sendNetworkPacket(player, packet: pointer) {.exportc.} = sendMessage(player, packet)
proc sendSystemMessage(player: Player, msg: cstring) {.importc.}
proc shulkerBoxD2() {.importc:"_ZN21ShulkerBoxBlockEntityD2Ev".}

proc checkShulkerBox(target: BlockEntity): bool =
  return ((ptr ptr pointer)target)[][] == shulkerBoxD2

proc checkAccess(player: Player, pos: BlockPos): bool =
  let chestName = player.getBlockEntity(pos).getBlockEntityName()
  if chestName == nil: return true
  let chestStr = $chestName
  if chestStr.startsWith("Lock:"):
    let passwd = chestStr[5..<len(chestStr)]
    let name = player.getSelectedName()
    if name != passwd:
      player.sendSystemMessage("Locked!")
      return false
  return true

hook "_ZNK15ShulkerBoxBlock17playerWillDestroyER6PlayerRK8BlockPosRK5Block":
  proc playerWillDestroy(entity: BlockEntity, player: Player, pos: BlockPos, blk: pointer): pointer {.refl.} =
    if not checkAccess(player, pos): return nil

hook "_ZNK10ChestBlock3useER6PlayerRK8BlockPosP15ItemUseCallback":
  proc useChest(chest: BlockEntity, player: Player, pos: BlockPos, callback: pointer): pointer {.refl.} =
    if getBlockEntity(player, pos).checkShulkerBox and not checkAccess(player, pos): return nil

proc mod_init(): void {. cdecl, exportc .} =
  echo "Chest Lock Loaded"