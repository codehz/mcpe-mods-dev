{.passL:"lib/cppstring.o -lstdc++".}
proc allocString*(str: cstring): ptr cstring {.importc.}
proc freeString*(str: ptr cstring) {.importc.}
proc `$`*(str: ptr cstring): string = $str[]