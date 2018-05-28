import pub.hook

hook "_ZN14EndDragonFight15setDragonKilledER11EnderDragon":
  proc setDragonKilled(fight: ptr array[50, byte], dragon: pointer): pointer =
    result = setDragonKilledOrig(fight, dragon)
    fight[][37] = 0

proc mod_init(): void {. cdecl, exportc .} =
  echo "Dragon Fight Loaded"