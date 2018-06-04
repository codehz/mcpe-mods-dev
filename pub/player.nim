import tables, hashes, hook, unsafe, uuid
{.passL:"-L./out -lplayer_support".}

type
  Player* = distinct pointer
  Level* = distinct pointer
  NetworkIdentifier* = ptr object
  PlayerEventListener* = proc(player: Player)

proc hash*(player: Player): Hash {.borrow.}
proc `==`*(a, b: Player): bool {.borrow.}

proc getName(player: Player) : var cstring {. importc: "_ZNK6Entity10getNameTagEv" .}

proc onPlayerJoined*(listener: PlayerEventListener) {.importc.}
proc onPlayerLeft*(listener: PlayerEventListener) {.importc.}
proc player*(id: NetworkIdentifier): Player {.importc.}
proc level*(player: Player): Level {.importc:"_ZN6Entity8getLevelEv".}  
proc name*(player: Player): string = $player.getName()
proc uuid*(player: Player): UUID = cast[ptr UUID](cast[ptr int](player) + 1130)[]

proc getPlayerImpl(level: Level, uuid: ptr UUID): Player {.importc:"_ZNK5Level9getPlayerERKN3mce4UUIDE".}
proc getPlayer*(level: Level, uuid: UUID): Player = level.getPlayerImpl(uuid.unsafeAddr)