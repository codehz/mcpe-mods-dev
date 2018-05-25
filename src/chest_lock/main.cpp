#include <string>
#include <sstream>
#include <climits>
#include <iostream>
#include <cstdio>

#include <minecraft/command/Command.h>
#include <minecraft/command/CommandMessage.h>
#include <minecraft/command/CommandOutput.h>
#include <minecraft/command/CommandParameterData.h>
#include <minecraft/command/CommandRegistry.h>
#include <minecraft/command/CommandVersion.h>

// extern "C" const char *processCommand();

struct ItemInstance
{
  bool isNull() const;
  bool hasCustomHoverName() const;
  std::string getCustomName() const;
};

struct BlockPos;

struct BlockEntity
{
  std::string &getCustomName() const;
};

struct BlockSource
{
  BlockEntity &getBlockEntity(BlockPos const &);
};

struct Entity
{
  const std::string &getNameTag() const;
  BlockSource &getRegion() const;
};

struct Player : Entity
{
  ItemInstance &getSelectedItem() const;
};

enum class TextPacketType;
struct Packet
{
};
extern "C" void ServerPlayer_sendNetworkPacket(Player &p, const Packet *packet);
struct TextPacket : Packet
{
  char filler[0x30];
  TextPacket(TextPacketType, std::string const &, std::string const &, std::vector<std::string> const &, bool, std::string const &);
  static TextPacket createJukeboxPopup(std::string const &);
  void SendTo(Player &p) { ServerPlayer_sendNetworkPacket(p, this); }
};

extern "C"
{
  char const *getSelectedName(const Player &player)
  {
    auto &item = player.getSelectedItem();
    if (!item.isNull() && item.hasCustomHoverName())
    {
      return item.getCustomName().c_str();
    }
    return nullptr;
  }

  BlockEntity &getBlockEntity(const Player &player, BlockPos const &pos)
  {
    auto &source = player.getRegion();
    return source.getBlockEntity(pos);
  }

  char const *getBlockEntityName(BlockEntity &entity) {
    return entity.getCustomName().c_str();
  }

  void sendSystemMessage(Player &player, char *msg) {
    TextPacket::createJukeboxPopup(msg).SendTo(player);
  }
}