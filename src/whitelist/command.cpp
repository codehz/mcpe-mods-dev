#include <string>
#include <sstream>
#include <climits>

#include <minecraft/command/Command.h>
#include <minecraft/command/CommandMessage.h>
#include <minecraft/command/CommandOutput.h>
#include <minecraft/command/CommandParameterData.h>
#include <minecraft/command/CommandRegistry.h>
#include <minecraft/command/CommandVersion.h>

template <typename T>
bool isValid(T const &t)
{
  union {
    unsigned const *x;
    T const *tr;
  };
  tr = &t;
  return *x;
}

extern "C" const char *processCommand(const char *sub, const char *param);

struct WlReloadCommand : Command
{
    ~WlReloadCommand() override = default;
    static void setup(CommandRegistry &registry)
    {
        registry.registerCommand("wlreload", "Reload Whitelist", (CommandPermissionLevel)4, (CommandFlag)0, (CommandFlag)0);
        registry.registerOverload<WlReloadCommand>("wlreload", CommandVersion(1, INT_MAX));
    }

    void execute(CommandOrigin const &origin, CommandOutput &outp) override
    {
        auto ret = processCommand("reload", "");
        if (ret)
        {
            outp.addMessage(ret);
        }
        outp.success();
    }
};

struct WlAddCommand : Command
{
  CommandMessage msg;
  ~WlAddCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("wladd", "Whitelist Management", (CommandPermissionLevel)4, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<WlAddCommand, CommandParameterData>(
        "wladd", CommandVersion(1, INT_MAX),
        CommandParameterData(CommandMessage::type_id(), &CommandRegistry::parse<CommandMessage>, "UUID", (CommandParameterDataType)0, nullptr, offsetof(WlAddCommand, msg), false, -1));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    std::string data = "";
    if (isValid(msg))
    {
      data = msg.getMessage(origin);
    }
    auto ret = processCommand("add", data.c_str());
    if (ret)
    {
      outp.addMessage(ret);
    }
    outp.success();
  }
};

extern "C"
{
  void setupCommands(CommandRegistry &registry)
  {
    WlReloadCommand::setup(registry);
    WlAddCommand::setup(registry);
  }
}