#include <string>
#include <sstream>
#include <climits>

#include <minecraft/command/Command.h>
#include <minecraft/command/CommandMessage.h>
#include <minecraft/command/CommandOutput.h>
#include <minecraft/command/CommandParameterData.h>
#include <minecraft/command/CommandRegistry.h>
#include <minecraft/command/CommandVersion.h>

struct Entity
{
  const std::string &getNameTag() const;
};

struct Player : Entity
{
};

struct Packet
{
};
enum class TextPacketType;

extern "C" void ServerPlayer_sendNetworkPacket(Player &p, const Packet *packet);

struct TextPacket : Packet
{
  char filler[0x30];
  TextPacket(TextPacketType, std::string const &, std::string const &, std::vector<std::string> const &, bool, std::string const &);
  static TextPacket createSystemMessage(std::string const&);
  void SendTo(Player &p) { ServerPlayer_sendNetworkPacket(p, this); }
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

struct TellRawCommand : Command
{
  CommandSelectorPlayer target;
  CommandMessage msg;
  ~TellRawCommand() override = default;
  static void setup(CommandRegistry &registry)
  {
    registry.registerCommand("tellraw", "Display raw message to player", (CommandPermissionLevel)1, (CommandFlag)0, (CommandFlag)0);
    registry.registerOverload<TellRawCommand>("tellraw", CommandVersion(1, INT_MAX),
                                              CommandParameterData(CommandSelectorPlayer::type_id(), &CommandRegistry::parse<CommandSelector<Player>>, "target", (CommandParameterDataType)0, nullptr, offsetof(TellRawCommand, target), false, -1),
                                              CommandParameterData(CommandMessage::type_id(), &CommandRegistry::parse<CommandMessage>, "message", (CommandParameterDataType)0, nullptr, offsetof(TellRawCommand, msg), false, -1));
  }

  void execute(CommandOrigin const &origin, CommandOutput &outp) override
  {
    auto res = target.results(origin);
    if (isValid(msg))
    {
      auto txt = msg.getMessage(origin);
      if (!res.empty())
      {
        for (auto it : *res.content)
        {
          TextPacket::createSystemMessage(txt).SendTo(*it);
        }
      }
    }
    outp.success();
  }
};

extern "C"
{
  void setupCommands(CommandRegistry &registry)
  {
    TellRawCommand::setup(registry);
  }
}