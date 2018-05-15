import pub.hook
import pub.interp

type
  Player = distinct pointer

proc name(player: Player) : var cstring {. importc: "_ZNK6Entity10getNameTagEv" .}

hook "_ZNK9minecraft3api15PlayerInterface23handlePlayerJoinedEventER6Player":
  proc onPlayerJoin(self: pointer, player: Player): void =
    ExecCommand("say §l" & $player.name & " Joined.")

hook "_ZNK9minecraft3api15PlayerInterface21handlePlayerLeftEventER6Player":
  proc onPlayerLeft(self: pointer, player: Player): void =
    ExecCommand("say §l" & $player.name & " Left.")

proc mod_init(): void {. cdecl, exportc .} =
  echo "Welcome Mod Loaded"