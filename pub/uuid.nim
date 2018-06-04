{.passL:"lib/uuid.o -lstdc++".}

type
  UUID* = distinct array[0x10, byte]

proc toUUID*(str: cstring): UUID {.importc.}