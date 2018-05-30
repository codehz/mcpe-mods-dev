#include <string>
#include <cstdlib>
#include <sstream>
#include <climits>
#include <cstdio>
#include <ios>
#include <iomanip>
#include <iostream>

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

UUID getUUID(std::string str)
{
  UUID uuid;
  const char *cstr = str.c_str();
  uuid.p0 = std::strtoul(cstr, 0, 16);
  uuid.p1 = std::strtoul(cstr + 9, 0, 16);
  uuid.p2 = std::strtoul(cstr + 14, 0, 16);
  uuid.p3 = std::strtoul(cstr + 19, 0, 16);
  uuid.p4 = std::strtoul(str.substr(24, 4).c_str(), 0, 16);
  uuid.pr = std::strtoul(cstr + 28, 0, 16);
  return uuid;
}

struct Entity
{
  char fillerZ[44];
  char fillerX[0x117c];
  UUID uuid;
  char fillerY[0x142c - 0x117c - sizeof(UUID)];
  void *id;
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

extern "C" void kickPlayer(Player *p);
extern "C" void banPlayer(void *uuid, const std::string &str);
extern "C" void pardonPlayer(void *uuid, const std::string &str);

struct BanCommand : Command
{
  CommandSelectorPlayer target;
  ~BanCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("ban", "Ban player", (CommandPermissionLevel)2, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<BanCommand>("ban", CommandVersion(1, INT_MAX),
                                          CommandParameterData(CommandSelectorPlayer::type_id(), &CommandRegistry::parse<CommandSelector<Player>>, "target", (CommandParameterDataType)0, nullptr, offsetof(BanCommand, target), false, -1));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    auto res = target.results(origin);
    if (!res.empty())
    {
      for (auto &ent : *res.content)
      {
        banPlayer(&ent->uuid, "Banned");
        kickPlayer(ent);
        outp.addMessage("§4[Blacklist Mod] Banned " + stringify(ent->uuid));
      }
    }
    outp.success();
  }
};

struct BanUUIDCommand : Command
{
  CommandMessage uuid;
  ~BanUUIDCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("banuuid", "Ban player by UUID", (CommandPermissionLevel)2, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<BanUUIDCommand>("banuuid", CommandVersion(1, INT_MAX),
                                              CommandParameterData(CommandMessage::type_id(), &CommandRegistry::parse<CommandMessage>, "uuid", (CommandParameterDataType)0, nullptr, offsetof(BanUUIDCommand, uuid), false, -1));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    if (isValid(uuid))
    {
      auto str = uuid.getMessage(origin);
      if (str.length() == 36) {
        UUID uuid = getUUID(str);
        banPlayer(&uuid, "Banned");
        outp.addMessage("§4[Blacklist Mod] Banned " + str);
      }
    }
    outp.success();
  }
};

struct PardonCommand : Command {
  CommandMessage uuid;
  ~PardonCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("pardon", "Pardon player by UUID", (CommandPermissionLevel)2, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<PardonCommand>("pardon", CommandVersion(1, INT_MAX),
                                              CommandParameterData(CommandMessage::type_id(), &CommandRegistry::parse<CommandMessage>, "pardon", (CommandParameterDataType)0, nullptr, offsetof(PardonCommand, uuid), false, -1));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    if (isValid(uuid))
    {
      auto str = uuid.getMessage(origin);
      if (str.length() == 36) {
        UUID uuid = getUUID(str);
        pardonPlayer(&uuid, "Banned");
        outp.addMessage("§2[Blacklist Mod] Pardoned " + str);
      }
    }
    outp.success();
  }
};

struct KickCommand : Command
{
  CommandSelectorPlayer target;
  ~KickCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("kick", "Kick player", (CommandPermissionLevel)2, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<KickCommand>("kick", CommandVersion(1, INT_MAX),
                                           CommandParameterData(CommandSelectorPlayer::type_id(), &CommandRegistry::parse<CommandSelector<Player>>, "target", (CommandParameterDataType)0, nullptr, offsetof(KickCommand, target), false, -1));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    auto res = target.results(origin);
    if (!res.empty())
    {
      for (auto &ent : *res.content)
      {
        kickPlayer(ent);
        outp.addMessage("§4[Blacklist Mod] Kicked " + stringify(ent->uuid));
      }
    }
    outp.success();
  }
};

extern "C" void showBlacklist(CommandOutput &outp);

struct BlacklistCommand : Command
{
  ~BlacklistCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("blacklist", "Show blacklist", (CommandPermissionLevel)2, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<BlacklistCommand>("blacklist", CommandVersion(1, INT_MAX));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    showBlacklist(outp);
    outp.success();
  }
};

extern "C"
{
  void appendOutput(CommandOutput &outp, char *data) {
    outp.addMessage(data);
  }

  void setupCommands(CommandRegistry &registry)
  {
    BanCommand::setup(registry);
    BanUUIDCommand::setup(registry);
    PardonCommand::setup(registry);
    BlacklistCommand::setup(registry);
    KickCommand::setup(registry);
  }
}