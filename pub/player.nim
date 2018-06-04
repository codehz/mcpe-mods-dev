import tables, hashes, hook, unsafe, uuid
{.passL:"-L./out -lplayer_support".}

type
  Player* = distinct pointer
  Level* = distinct pointer
  NetworkIdentifier* = ptr object
  PlayerEventListener* = proc(player: Player)

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

proc `$`*(uuid: UUID) : string =
  ((array[0x10, byte])uuid).showUuid

proc hash*(player: Player): Hash {.borrow.}
proc `==`*(a, b: Player): bool {.borrow.}

proc hash*(uuid: UUID): Hash {.borrow.}
proc `==`*(a, b: UUID): bool {.borrow.}

proc getName(player: Player) : var cstring {. importc: "_ZNK6Entity10getNameTagEv" .}

proc onPlayerJoined*(listener: PlayerEventListener) {.importc.}
proc onPlayerLeft*(listener: PlayerEventListener) {.importc.}
proc player*(id: NetworkIdentifier): Player {.importc.}
proc level*(player: Player): Level {.importc:"_ZN6Entity8getLevelEv".}  
proc name*(player: Player): string = $player.getName()
proc uuid*(player: Player): UUID = cast[ptr UUID](cast[ptr int](player) + 1130)[]

proc getPlayerImpl(level: Level, uuid: ptr UUID): Player {.importc:"_ZNK5Level9getPlayerERKN3mce4UUIDE".}
proc getPlayer*(level: Level, uuid: UUID): Player = level.getPlayerImpl(uuid.unsafeAddr)