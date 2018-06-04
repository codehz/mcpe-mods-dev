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

enum class XTag : int
{
  SPAWN,
  HOME,
  BLACKLIST
};

static const char *XStrings[] = {"spawn", "Teleport to world spawn point", "home", "Teleport to home", "tpblacklist", "Edit teleport blacklist"};

extern "C" void processCommand(Player &, XTag x);

template <XTag x>
struct BaseCommand : Command
{
  ~BaseCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand(XStrings[(int)x * 2], XStrings[(int)x * 2 + 1], (CommandPermissionLevel)0, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<BaseCommand<x>>(XStrings[(int)x * 2], CommandVersion(1, INT_MAX));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    if (origin.getOriginType() != 0)
    {
      outp.addMessage("Player Required");
      outp.success();
      return;
    }
    processCommand(origin.getEntity(), x);
    outp.success();
  }
};

struct Entity
{
  unsigned int fillerX[1130];
  const std::string &getNameTag() const;
};

struct Player : Entity
{
};

template <typename T>
struct CommandSelectorResults
{
  std::shared_ptr<std::vector<T *>> content;
  bool empty() const;
};

struct CommandSelectorBase
{
  CommandSelectorBase(bool);
  virtual ~CommandSelectorBase();
};

template <typename T>
struct CommandSelector : CommandSelectorBase
{
  char filler[0x74];
  CommandSelector();

  const CommandSelectorResults<T> results(CommandOrigin const &) const;
};

struct CommandSelectorPlayer : CommandSelector<Player>
{
  CommandSelectorPlayer() : CommandSelector() {}
  ~CommandSelectorPlayer() {}

  static typeid_t<CommandRegistry> type_id()
  {
    static typeid_t<CommandRegistry> ret = type_id_minecraft_symbol<CommandRegistry>("_ZZ7type_idI15CommandRegistry15CommandSelectorI6PlayerEE8typeid_tIT_EvE2id");
    return ret;
  }
};

extern "C" const char *processTPA(Player &self, Player &target);

struct TPACommand : Command
{
  CommandSelectorPlayer target;
  ~TPACommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("tpa", "Request to teleport", (CommandPermissionLevel)0, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<TPACommand>("tpa", CommandVersion(1, INT_MAX),
                                          CommandParameterData(CommandSelectorPlayer::type_id(), &CommandRegistry::parse<CommandSelector<Player>>, "target", (CommandParameterDataType)0, nullptr, offsetof(TPACommand, target), false, -1));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    auto res = target.results(origin);
    if (res.empty())
    {
      outp.addMessage("empty");
    }
    else if (res.content->size() > 1)
    {
      outp.addMessage("Too many target.");
    }
    else
    {
      auto msg = processTPA(origin.getEntity(), *res.content->front());
      if (msg) {
        outp.addMessage(msg);
      }
    }
    outp.success();
  }
};

extern "C"
{
  void setupCommands(CommandRegistry &registry)
  {
    BaseCommand<XTag::SPAWN>::setup(registry);
    BaseCommand<XTag::HOME>::setup(registry);
    BaseCommand<XTag::BLACKLIST>::setup(registry);
    TPACommand::setup(registry);
  }
}