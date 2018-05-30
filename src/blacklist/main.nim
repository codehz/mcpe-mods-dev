import pub.hook, pub.cppstring, strformat, strutils, os, sets, streams
const ModBase {.strdefine.}: string = ""
{.passL: &"{ModBase}/cpp.o -lstdc++".}

type
  Player = distinct pointer
  ServerNetworkHandler = distinct pointer
  CommandOutput = distinct pointer
  Minecraft = distinct pointer

var blacklist = initSet[string](64)
let path_blacklist = getCurrentDir() / "games" / "blacklist.txt"

proc checkRange(inStr: string, a, b: int): bool =
  for i in a..<b:
    if inStr[i] notin '0'..'9' and inStr[i] notin 'a'..'z': return false
  true

proc checkUUID(inStr: string): bool =
  for i in [8, 13, 18, 23]:
    if inStr[i] != '-': return false
  checkRange(inStr, 0, 8) and checkRange(inStr, 9, 13) and checkRange(inStr, 14, 18) and checkRange(inStr, 19, 23) and checkRange(inStr, 24, 36)

proc readBlacklist() =
  try:
    blacklist.clear
    for token in lines(path_blacklist):
      if token.len >= 36:
        if checkUUID(token):
          blacklist.incl(token[0..<36])
          echo "§2[Blacklist Mod] Added <" & token[0..<36] & ">"
        else:
          echo "§4[Blacklist Mod] Invalid UUID: " & token
    echo "§2[Blacklist Mod] Loaded " & $blacklist.len & " UUID."
  except IOError:
    echo("§4[Blacklist Mod] §kFailed to load blacklist(", path_blacklist, ").")

var
  handler: ServerNetworkHandler = nil

proc setupCommands(registry: pointer) {.importc.}

proc activeWhitelist(minecraft: Minecraft) {. importc: "_ZN9Minecraft17activateWhitelistEv" .}
proc kickPlayer(snh: ServerNetworkHandler, p: Player) {.importc:"_ZN20ServerNetworkHandler13_onPlayerLeftEP12ServerPlayer".}

proc showUuid(ba: array[0x10, byte]): string {.noSideEffect.} =
  const hexChars = "0123456789abcdef"

  result = newString(36)
  for i in 0..<4:
    result[2*i] = hexChars[int ba[7-i] shr 4 and 0xF]
    result[2*i+1] = hexChars[int ba[7-i] and 0xF]
  result[8] = '-'
  for i in 4..<6:
    result[2*i+1] = hexChars[int ba[7-i] shr 4 and 0xF]
    result[2*i+2] = hexChars[int ba[7-i] and 0xF]
  result[13] = '-'
  for i in 6..<8:
    result[2*i+2] = hexChars[int ba[7-i] shr 4 and 0xF]
    result[2*i+3] = hexChars[int ba[7-i] and 0xF]
  result[18] = '-'
  for i in 8..<10:
    result[2*i+3] = hexChars[int ba[23-i] shr 4 and 0xF]
    result[2*i+4] = hexChars[int ba[23-i] and 0xF]
  result[23] = '-'
  for i in 10..<16:
    result[2*i+4] = hexChars[int ba[23-i] shr 4 and 0xF]
    result[2*i+5] = hexChars[int ba[23-i] and 0xF]

proc banPlayer(uuid: var array[0x10, byte], reason: ptr cstring) {.exportc.} =
  blacklist.incl(uuid.showUuid)
  try:
    let stream = newFileStream(path_blacklist, fmAppend)
    defer: stream.close()
    stream.writeLine(uuid.showUuid)
  except:
    echo "§4[Blacklist Mod] Blacklist Not Saved"

proc pardonPlayer(uuid: var array[0x10, byte], reason: ptr cstring) {.exportc.} =
  let uuitStr = uuid.showUuid
  blacklist.excl(uuitStr)
  try:
    let file = open(path_blacklist, fmRead)
    defer: close(file)
    let contents = readAll(file)
    let stream = newFileStream(path_blacklist, fmWrite)
    defer: close(stream)
    for line in splitLines(contents):
      if not line.startsWith(uuitStr):
        stream.writeLine(line)
  except:
    echo "§4[Blacklist Mod] Blacklist Not Saved"

proc kickPlayer(p: Player) {. cdecl, exportc .} =
  handler.kickPlayer(p)

var
  isFirst = true

proc appendOutput(outp: CommandOutput, data: cstring) {.importc.}

proc showBlacklist(outp: CommandOutput) {.exportc.} =
  for item in blacklist:
    outp.appendOutput(item)

hook "_ZN20ServerNetworkHandler24updateServerAnnouncementEv":
  proc setSNH(snh: ServerNetworkHandler) {.refl.} =
    if isFirst:
      isFirst = false
      handler = snh
      readBlacklist()

hook "_ZN10SayCommand5setupER15CommandRegistry":
  proc setupCommand(registry: pointer) {.refl.} =
    setupCommands(registry)

hook "_ZNK9Whitelist9isAllowedERKN3mce4UUIDERKSs":
  proc isAllowed(list: pointer, uuid: var array[0x10, byte], text: var cstring): bool =
    if uuid.showUuid in blacklist:
      echo "§4[Blacklist Mod] Blocked ", uuid.showUuid
      return false
    return true

proc mod_init(): void {. cdecl, exportc .} =
  echo "Blacklist Mod Loaded"

var mc: Minecraft = nil

hook "_ZN9Minecraft12initCommandsEv":
  proc initCommands(minecraft: Minecraft) {. refl .} =
    mc = minecraft

proc mod_set_server(_: pointer): void {. cdecl, exportc .} =
  mc.activeWhitelist