import pub.hook

hook "_ZN17MinecraftEventing25fireEventPlayerMessageSayERKSsS1_":
  proc onSay(self: pointer, sender: var cstring, content: var cstring): void =
    echo content

hook "_ZN17MinecraftEventing24fireEventPlayerMessageMeERKSsS1_":
  proc onMe(self: pointer, sender: var cstring, content: var cstring): void =
    echo("§l * ", sender, " ", content)

proc mod_init(): void {. cdecl, exportc .} =
  echo "Chat Log Loaded"