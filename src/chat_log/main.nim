import pub.hook, strutils

proc escape(inStr: cstring): string = ($inStr).replace('\x07', ' ')

hook "_ZN17MinecraftEventing25fireEventPlayerMessageSayERKSsS1_":
  proc onSay(self: pointer, sender: var cstring, content: var cstring): void {. refl .} =
    echo content.escape

hook "_ZN17MinecraftEventing24fireEventPlayerMessageMeERKSsS1_":
  proc onMe(self: pointer, sender: var cstring, content: var cstring): void {. refl .} =
    echo("§l * ", sender, " ", content.escape)

hook "_ZN17MinecraftEventing26fireEventPlayerMessageChatERKSsS1_":
  proc onChat(self: pointer, sender: var cstring, content: var cstring): void {. refl .} =
    echo("§l", sender, "§r ", content.escape)

proc mod_init(): void {. cdecl, exportc .} =
  echo "Chat Log Loaded"