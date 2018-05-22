#include <string>
#include <sstream>
#include <climits>

#include <minecraft/command/Command.h>
#include <minecraft/command/CommandMessage.h>
#include <minecraft/command/CommandOutput.h>
#include <minecraft/command/CommandParameterData.h>
#include <minecraft/command/CommandRegistry.h>
#include <minecraft/command/CommandVersion.h>

extern "C" const char *processCommand();

struct PingCommand : Command
{
    ~PingCommand() override = default;
    static void setup(CommandRegistry &registry)
    {
        registry.registerCommand("ping", "Ping Command", (CommandPermissionLevel)0, (CommandFlag)0, (CommandFlag)0);
        registry.registerOverload<PingCommand>("ping", CommandVersion(1, INT_MAX));
    }

    void execute(CommandOrigin const &origin, CommandOutput &outp) override
    {
        auto ret = processCommand();
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
        PingCommand::setup(registry);
    }
}