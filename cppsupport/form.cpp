#include <string>

struct Packet
{
  int v2, v1, v0;
  Packet() : v2(2), v1(1), v0(0) {}
  virtual ~Packet();
};

struct ModalFormRequestPacket : Packet
{
  int id;
  std::string json;
  ModalFormRequestPacket(int id, const char *json) : id(id), json(json)
  {
  }
  ~ModalFormRequestPacket();
};

extern "C"
{
  Packet *makeRequest(int id, const char *json)
  {
    return new ModalFormRequestPacket(id, json);
  }

  void freeRequest(Packet *packet)
  {
    delete packet;
  }

  const char *strRequest(ModalFormRequestPacket *packet)
  {
    return packet->json.c_str();
  }

  int idRequest(ModalFormRequestPacket *packet)
  {
    return packet->id;
  }
}