import pub.hook, strformat, os, json, streams, options
const ModBase {.strdefine.}: string = ""
{.passL: &"{ModBase}/cpp.o -lstdc++".}

type
  SimpleCfg = tuple[name, desc, res: string]

var
  cfg = none(SimpleCfg)

proc readCfg(filename: string) =
  if existsFile(filename):
    try:
      let filestream = newFileStream(filename, fmRead, 4096)
      defer: filestream.close()
      let parsed = parseJson(filestream, filename)
      var name, desc, res: string
      if parsed.hasKey("name") and parsed["name"].kind == JString:
        name = parsed["name"].getStr
      else:
        echo "§4[Simple Command Mod] §kname is required"
        return
      if parsed.hasKey("desc") and parsed["desc"].kind == JString:
        desc = parsed["desc"].getStr
      else:
        desc = name
      if parsed.hasKey("res") and parsed["res"].kind == JString:
        res = parsed["res"].getStr
      else:
        echo "§4[Simple Command Mod] §kres is required"
        return
      cfg = (name, desc, res).some()
      echo "§2[Simple Command Mod] §kloaded command: ", name
    except IOError:
      echo "§4[Simple Command Mod] §kI/O Exception"
    except JsonParsingError:
      echo "§4[Simple Command Mod] §kJSON parsed failed"
    except FieldError:
      echo "§4[Simple Command Mod] §kJSON parsed failed(Field's type mismatch)"
    except:
      echo "§4[Simple Command Mod] §kUnknown error"
  else:
    echo("§4[Simple Command Mod] §kNo config found(", filename,"), won't register the command.")

proc setupCommands(registry: pointer, name, desc: cstring) {.importc.}

proc processCommand(): cstring {. cdecl, exportc .}  = cfg.get.res

hook "_ZN10SayCommand5setupER15CommandRegistry":
  proc setupCommand(registry: pointer) {.refl.} =
    cfg.map do (config: SimpleCfg): setupCommands(registry, config.name, config.desc)

proc mod_init(): void {. cdecl, exportc .} =
  let cfg = getCurrentDir() / "games" / "simple_cmd.json"
  readCfg(cfg)