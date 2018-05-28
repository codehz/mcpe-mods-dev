#include <string>
#include <vector>

struct Player;

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

extern "C" void sendSystemMessage(Player &player, char *msg)
{
  TextPacket::createJukeboxPopup(msg).SendTo(player);
}