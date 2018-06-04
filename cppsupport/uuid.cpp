#include <iostream>
#include <iomanip>
#include <cstdlib>
#include <ios>
#include <string>
#include <sstream>

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

UUID toUUID(std::string str)
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

extern "C" UUID toUUID(const char *uuid) {
  return toUUID(std::string(uuid));
}