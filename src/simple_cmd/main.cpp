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

struct SimpleCommand : Command
{
    ~SimpleCommand() override = default;
    static void setup(CommandRegistry &registry, const char *name, const char *desc)
    {
        registry.registerCommand(name, desc, (CommandPermissionLevel)0, (CommandFlag)0, (CommandFlag)0);
        registry.registerOverload<SimpleCommand>(name, CommandVersion(1, INT_MAX));
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
    void setupCommands(CommandRegistry &registry, const char *name, const char *desc)
    {
        SimpleCommand::setup(registry, name, desc);
    }
}