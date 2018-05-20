import pub.hook

import os
import sets

type
  Minecraft = distinct pointer
  UUID = distinct array[0x10, byte]

let path_whitelist = getCurrentDir() / "games" / "whitelist.txt"
let path_log = getCurrentDir() / "games" / "whitelist.log"

var whitelist = initSet[string](64)

whitelist.incl("23b50e5a-10d2-37d8-9dc4-983f83c55a3c")

func readWhitelist() =
  try:
    whitelist.clear
    for token in lines(path_whitelist):
      if token.len >= 36:
        whitelist.incl(token[0..<36])
        echo "§2[Whitelist Mod] Added <" & token[0..<36] & ">"
    echo "§2[Whitelist Mod] Loaded " & $whitelist.len & " UUID."
  except IOError:
    echo("§4[Whitelist Mod] §kFailed to load whitelist(", path_whitelist, ").")

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

proc `$`(uuid: UUID) : string =
  ((array[0x10, byte])uuid).showUuid

proc activeWhitelist(minecraft: Minecraft) {. importc: "_ZN9Minecraft17activateWhitelistEv" .}

var mc: Minecraft = nil

hook "_ZN9Minecraft12initCommandsEv":
  proc initCommands(minecraft: Minecraft) {. refl .} =
    mc = minecraft

hook "_ZNK9Whitelist9isAllowedERKN3mce4UUIDERKSs":
  proc isAllowed(list: pointer, uuid: var UUID, text: var cstring): bool =
    if $uuid in whitelist:
      echo "§2[Whitelist Mod] Allowed " & $uuid
      return true
    echo "§4[Whitelist Mod] Denied " & $uuid
    let f = open(path_log, fmAppend, 4096)
    defer: f.close()
    f.writeLine($uuid)
    return false

proc mod_init(): void {. cdecl, exportc .} =
  readWhitelist()

proc mod_set_server(_: pointer): void {. cdecl, exportc .} =
  mc.activeWhitelist
