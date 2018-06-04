#include <string>
#include <sstream>
#include <climits>

#include <minecraft/command/Command.h>
#include <minecraft/command/CommandMessage.h>
#include <minecraft/command/CommandOutput.h>
#include <minecraft/command/CommandParameterData.h>
#include <minecraft/command/CommandRegistry.h>
#include <minecraft/command/CommandVersion.h>

struct Player;

struct CommandOrigin
{
  virtual ~CommandOrigin();
  virtual void getRequestId();
  virtual void getName();
  virtual void getBlockPosition();
  virtual void getWorldPosition();
  virtual void getLevel();
  virtual void getDimension();
  virtual Player &getEntity() const;
  virtual void getPermissionsLevel();
  virtual void clone();
  virtual void canCallHiddenCommands();
  virtual void hasChatPerms();
  virtual void hasTellPerms();
  virtual void canUseAbility(std::string const &);
  virtual void getSourceId();
  virtual void getSourceSubId();
  virtual void getOutputReceiver();
  virtual int getOriginType() const;
  virtual void toCommandOriginData();
  virtual void getUUID();
  virtual void _setUUID();
};

extern "C" const char *processCommand(Player &player);

struct DialogCommand : Command
{
  ~DialogCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("dialog", "Dialog Command", (CommandPermissionLevel)0, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<DialogCommand>("dialog", CommandVersion(1, INT_MAX));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    if (origin.getOriginType() != 0)
    {
      outp.addMessage("Player Required");
      outp.success();
      return;
    }
    auto ret = processCommand(origin.getEntity());
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
    DialogCommand::setup(registry);
  }
}