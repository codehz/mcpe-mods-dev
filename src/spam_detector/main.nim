import pub.hook, pub.interp, sequtils, deques, strutils, tables, times, os, streams, json

type
  Limit = tuple[threshold, interval: int]

var
  record = initTable[string, seq[Deque[int64]]](16)
  limits: seq[Limit] = @[(5, 5), (10, 30)]
  commands = @["tellraw @a Spam detected: {{player}}", "kick {{player}}"]

proc readCfg(filename: string) =
  if existsFile(filename):
    try:
      let filestream = newFileStream(filename, fmRead, 4096)
      defer: filestream.close()
      let parsed = parseJson(filestream, filename)
      if parsed.kind != JObject:
        return
      if parsed.hasKey("limits") and parsed["limits"].kind == JArray:
        limits = newSeqOfCap[Limit](parsed["limits"].len)
        for limitNode in parsed["limits"]:
          var limit: Limit
          if limitNode.hasKey("threshold") and limitNode["threshold"].kind == JInt:
            limit.threshold = limitNode["threshold"].getInt()
          else:
            continue
          if limitNode.hasKey("interval") and limitNode["interval"].kind == JInt:
            limit.interval = limitNode["interval"].getInt()
          else:
            continue
          limits.add(limit)
      if parsed.hasKey("commands") and parsed["commands"].kind == JArray:
        commands = newSeqOfCap[string](parsed["commands"].len)
        for cmd in parsed["commands"]:
          commands.add(cmd.getStr())
      echo "§2[Spam Detector] §kLoaded"
    except IOError:
      echo "§4[Spam Detector] §kI/O Exception"
    except JsonParsingError:
      echo "§4[Spam Detector] §kJSON parsed failed"
    except FieldError:
      echo "§4[Spam Detector] §kJSON parsed failed(Field's type mismatch)"
    except:
      echo "§4[Spam Detector] §kUnknown error: ", getCurrentExceptionMsg()
  else:
    echo("§4[Spam Detector] §kNo config found(", filename,"), Fallback to default config.")

proc detectSpam(name: string) =
  let cur = getTime().toUnix
  if name in record:
    var rec = record[name]
    block detect:
      for idx, limit in limits:
        var list = rec[idx]
        while list.len > 0 and cur - list.peekFirst() > limit.interval:
          list.popFirst()
        list.addLast(cur)
        if list.len > limit.threshold:
          for cmd in commands:
            ExecCommand(cmd.replace("{{player}}", name))
          record.del(name)
          break detect
        else:
          rec[idx] = list
      record[name] = rec
  else:
    record.add(name, limits.map(proc (limit: Limit): Deque[int64] =
      var deq = initDeque[int64](16)
      deq.addLast(cur)
      deq
    ))

hook "_ZN17MinecraftEventing25fireEventPlayerMessageSayERKSsS1_":
  proc onSay(self: pointer, sender: var cstring, content: var cstring): void {. refl .} =
    detectSpam $sender

hook "_ZN17MinecraftEventing24fireEventPlayerMessageMeERKSsS1_":
  proc onMe(self: pointer, sender: var cstring, content: var cstring): void {. refl .} =
    detectSpam $sender

hook "_ZN17MinecraftEventing26fireEventPlayerMessageChatERKSsS1_":
  proc onChat(self: pointer, sender: var cstring, content: var cstring): void {. refl .} =
    detectSpam $sender

proc mod_init(): void {. cdecl, exportc .} =
  readCfg(getCurrentDir() / "games" / "spam_detector.json")