import pub.hook

hook "_ZN17MinecraftEventing25fireEventPlayerMessageSayERKSsS1_":
  proc onSay(self: pointer, sender: var cstring, content: var cstring): void {. refl .} =
    echo content

hook "_ZN17MinecraftEventing24fireEventPlayerMessageMeERKSsS1_":
  proc onMe(self: pointer, sender: var cstring, content: var cstring): void {. refl .} =
    echo("§l * ", sender, " ", content)

hook "_ZN17MinecraftEventing26fireEventPlayerMessageChatERKSsS1_":
  proc onChat(self: pointer, sender: var cstring, content: var cstring): void {. refl .} =
    echo("§l", sender, "§r ", content)

proc mod_init(): void {. cdecl, exportc .} =
  echo "Chat Log Loaded"