#include <string>

extern "C" {
std::string *allocString(const char *str) {
  return new std::string(str);
}
void freeString(std::string *str) {
  delete str;
}
}