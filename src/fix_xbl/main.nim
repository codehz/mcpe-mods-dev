import pub.hook

hook "_ZN15PlayScreenModel27fetchThirdPartyServerWorldsEv":
  proc fetchThirdPartyServerWorlds(x: pointer): pointer =
    echo "Cancel Fetch"
    nil

proc mod_init(): void {. cdecl, exportc .} =
  echo "Try to fix XBL"
