import pub.hook, pub.message, pub.cppstring, parsecfg, strutils, os, math

type
  Level = distinct pointer
  Vec3[T] = tuple[x, y, z: T]

proc defaultSpawn(level: Level): var Vec3[int] {.importc:"_ZNK5Level15getDefaultSpawnEv".}
proc level(player: Player): Level {.importc:"_ZN6Entity8getLevelEv".}
proc dim(player: Player): int {.importc:"_ZNK6Entity14getDimensionIdEv".}
proc pos(player: Player): var Vec3[float32] {.importc:"_ZNK6Entity6getPosEv".}
proc cvt(vi: Vec3[int]): Vec3[float32] = ((float32)vi.x, (float32)vi.y, (float32)vi.z)

let op = allocString("op")
var radius = 50
var protectMsg = "Protected!"

proc isOperator(player: Player): bool

proc `<->`(a, b: Vec3[float32]): float32 = (a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2

hook "_ZN6Player13canUseAbilityERKSs":
  proc canUseAbility(player: Player, ability: ptr cstring): bool {.refl.} =
    if player.dim == 0 and $ability == "buildandmine" and not player.isOperator:
      let spawn = player.level.defaultSpawn.cvt
      let pos = player.pos()
      if (spawn <-> pos) < 2500:
        player.sendSystemMessage(protectMsg)
        return false

proc isOperator(player: Player): bool = player.canUseAbilityOrig(op)

proc mod_init(): void {. cdecl, exportc .} =
  try:
    let cfg = loadConfig(getCurrentDir() / "games" / "server.properties")
    let radiusStr = cfg.getSectionValue("", "spawn-radius")
    protectMsg = cfg.getSectionValue("", "spawn-protect-msg")
    radius = (parseInt radiusStr) ^ 2
  except:
    echo "Spawn radius load failed, use default"
  echo "Spawn Radius^2: ", radius