import pub.hook, pub.unsafe, pub.form, pub.player, pub.uuid, pub.i18n, tables, json, strformat, hashes, times, os, sets, streams, parsecfg
const ModBase {.strdefine.}: string = ""
{.passL: &"{ModBase}/cpp.o -lstdc++".}

let lang = loadI18n("teleport")

proc setupCommands(registry: pointer) {.importc.}

type
  Vec3[T] = tuple[x, y, z: T]
  XTag = enum Spawn = 0, Home, Blacklist

proc name(player: Player) : var cstring {. importc: "_ZNK6Entity10getNameTagEv" .}
proc defaultSpawnPos(level: Level): var Vec3[int] {.importc:"_ZNK5Level15getDefaultSpawnEv".}
proc spawnPos(player: Player): Vec3[int] {.importc:"_ZN6Player16getSpawnPositionEv".}
proc pos(player: Player): var Vec3[float32] {.importc:"_ZNK6Entity6getPosEv".}
proc cvt(vi: Vec3[int]): Vec3[float32] = ((float32)vi.x, (float32)vi.y, (float32)vi.z)

proc teleport(none: pointer, player: Player, target: Vec3[float32], center: var Vec3[float32], dim: int) {.importc:"_ZNK15TeleportCommand8teleportER6Entity4Vec3PS2_11DimensionId".}

var
  zeroPoint: Vec3[float32] = (x: 0.0f, y: -1.0f, z:0.0f)
  tpCooldown = initTable[string, Time](16)
  tpBlacklist = initTable[string, HashSet[string]](16)

let BlacklistDB = getCurrentDir() / "games" / "teleport-blacklist.json"

proc loadConfig() =
  if existsFile BlacklistDB:
    let file = parseFile(BlacklistDB)
    if file.kind == JObject:
      for k, v in file:
        var xset = initSet[string]()
        if v.kind == JArray:
          for blp in v:
            if blp.kind == JString:
              xset.incl(blp.getStr())
        tpBlacklist[k] = xset

proc saveConfig() =
  let fs = newFileStream(BlacklistDB, fmWrite, 256)
  defer: fs.close()
  var js = newJObject()
  for k, v in tpBlacklist:
    js[k] = newJArray()
    for item in v:
      js[k].add(newJString(item))
  fs.write(js.pretty())

proc processCommand(player: Player, tag: XTag) {. cdecl, exportc .}  =
  case tag:
    of Spawn:
      teleport(nil, player, player.level.defaultSpawnPos.cvt, zeroPoint, 0)
    of Home:
      teleport(nil, player, player.spawnPos.cvt, zeroPoint, 0)
    of Blacklist:
      let xuuid = $player.uuid
      if xuuid notin tpBlacklist or tpBlacklist[xuuid].len == 0:
        player.sendForm(FormModel(
          kind: FormKind.modal,
          title: lang.getText("form-title", "Teleport Blacklist Management"),
          modal: lang.getText("blacklist-empty", "Blacklist is empty"),
          button1: lang.getText("form-ok", "OK"),
          button2: lang.getText("form-cancel", "Cancel")
        )).then do (data: JsonNode): discard
      else:
        var
          xset = tpBlacklist[xuuid]
        var parr = newSeqOfCap[Control](xset.len)
        var puuid = newSeqOfCap[string](xset.len)

        for x in xset:
          parr.add(Control(
            kind: ControlKind.toggle,
            text: x,
            defaultToggle: true
          ))
          puuid.add(x)
        player.sendForm(FormModel(
          kind: FormKind.custom,
          title: lang.getText("form-title", "Teleport Blacklist Management"),
          custom: parr
        )).then do (data: JsonNode):
          if data.kind == JArray:
            var i = 0
            var changed = false
            for item in data:
              if item.kind == JBool:
                if item.getBool() == false:
                  xset.excl(puuid[i])
                  changed = true
              i.inc()
            if changed:
              if xset.len == 0:
                tpBlacklist.del(xuuid)
              else:
                tpBlacklist[xuuid] = xset
              saveConfig()

proc addBlacklist(player, target: Player) =
  let
    xplayer = $player.uuid
    xtarget = $player.uuid
  if xplayer in tpBlacklist:
    var sets = tpBlacklist[xplayer]
    sets.incl(xtarget)
    tpBlacklist[xplayer] = sets
  else:
    tpBlacklist[xplayer] = [xtarget].toSet
  saveConfig()

proc processTPA(player, target: Player): cstring {. cdecl, exportc .} =
  let
    fname = $player.name
    xuuid = $target.uuid
  if xuuid in tpCooldown:
    let xtime = tpCooldown[xuuid]
    if xtime < getTime():
      tpCooldown.del(xuuid)
    else:
      return lang.getText("fail-cooldown", "Wait for teleport cooldown")
  if xuuid in tpBlacklist and $player.uuid in tpBlacklist[xuuid]:
    return lang.getText("fail-blocked", "$1 blocked your teleport request", [fname])
  target.sendForm(FormModel(
    kind: FormKind.simple,
    title: lang.getText("request-title", "Teleport Request"),
    simple: lang.getText("request-content", "Teleport Request From $1", [fname]),
    buttons: @[
      lang.getText("accept", "Accept"),
      lang.getText("reject", "Reject"),
      lang.getText("suspend", "Suspend request for 5 minutes"),
      lang.getText("block", "Block $1", [fname])]
  )).then do (data: JsonNode):
    if data.kind == JInt:
      case data.getInt():
      of 0: # Accept
        teleport(nil, target, player.pos, zeroPoint, 0)
      of 2: # Suspend
        tpCooldown[xuuid] = getTime() + 5.minutes
      of 3: # Block
        addBlacklist(target, player)
      else: discard
  return lang.getText("sent", "Teleport request sent.")

hook "_ZN10SayCommand5setupER15CommandRegistry":
  proc setupCommand(registry: pointer) {.refl.} =
    setupCommands(registry)

proc mod_init(): void {. cdecl, exportc .} =
  echo "Teleport Mod Loaded"
  loadConfig()