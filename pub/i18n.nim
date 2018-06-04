import parsecfg, os, strutils

let path = getCurrentDir() / "games" / "i18n.ini"

proc tryLoad(): Config =
  if existsFile path:
    loadConfig(path)
  else:
    newConfig()

var dict = tryLoad()

proc saveConfig() =
  dict.writeConfig(path)

type
  Module = distinct string

proc loadI18n*(name: string): Module = (Module)name

proc getText*(query: Module, name: string): string = dict.getSectionValue((string)query, name)
proc getText*(query: Module, name: string, default: string): string =
  result = dict.getSectionValue((string)query, name)
  if result == "":
    result = default
    dict.setSectionKey((string)query, name, default)
    saveConfig()
proc getText*(query: Module, name: string, a: openArray[string]): string = dict.getSectionValue((string)query, name) % a
proc getText*(query: Module, name, default: string, a: openArray[string]): string =
  var temp = dict.getSectionValue((string)query, name)
  if temp == "":
    temp = default
    dict.setSectionKey((string)query, name, default)
    saveConfig()
  temp % a