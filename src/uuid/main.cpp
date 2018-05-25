#include <string>
#include <sstream>
#include <climits>
#include <cstdio>
#include <ios>
#include <iomanip>

#include <minecraft/command/Command.h>
#include <minecraft/command/CommandMessage.h>
#include <minecraft/command/CommandOutput.h>
#include <minecraft/command/CommandParameterData.h>
#include <minecraft/command/CommandRegistry.h>
#include <minecraft/command/CommandVersion.h>

template <typename T>
std::string stringify(T const &t)
{
  std::stringstream ss;
  ss << t;
  return ss.str();
}

struct UUID
{
  short p2, p1;
  unsigned p0, pr;
  short p4, p3;

  friend std::ostream &operator<<(std::ostream &os, const UUID &uuid)
  {
    os << std::hex << std::setfill('0') << std::setw(8)
       << uuid.p0 << '-' << std::setw(4)
       << uuid.p1 << '-'
       << uuid.p2 << '-'
       << uuid.p3 << '-'
       << uuid.p4 << std::setw(8) << uuid.pr;
    return os;
  }
};

struct Entity
{
  unsigned int fillerX[1130];
  UUID uuid;
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

struct UuidCommand : Command
{
  CommandSelectorPlayer target;
  ~UuidCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("uuid", "UUID Query", (CommandPermissionLevel)0, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<UuidCommand>("uuid", CommandVersion(1, INT_MAX),
                                           CommandParameterData(CommandSelectorPlayer::type_id(), &CommandRegistry::parse<CommandSelector<Player>>, "target", (CommandParameterDataType)0, nullptr, offsetof(UuidCommand, target), false, -1));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    auto res = target.results(origin);
    if (res.empty())
    {
      outp.addMessage("empty");
    }
    else
    {
      for (auto &ent : *res.content)
      {
        outp.addMessage(stringify(ent->uuid) + "#" + ent->getNameTag());
      }
    }
    outp.success();
  }
};

extern "C"
{
  void setupCommands(CommandRegistry &registry)
  {
    UuidCommand::setup(registry);
  }

  std::string *getUUID(Player *player) {
    static std::string tmp;
    tmp = stringify(player->uuid);
    return &tmp;
  }
}