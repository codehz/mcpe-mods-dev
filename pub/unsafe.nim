template `+`*[T](p: ptr T, off: int): ptr T =
  cast[ptr T](cast[ByteAddress](p) +% off * sizeof(p[]))

template `+=`*[T](p: ptr T, off: int) =
  p = p + off

template `-`*[T](p: ptr T, off: int): ptr T =
  cast[ptr T](cast[ByteAddress](p) -% off * sizeof(p[]))

template `-`*[T](p: ptr T, q: ptr T): int =
  cast[ByteAddress](p) - cast[ByteAddress](q)
    
template `-=`*[T](p: ptr T, off: int) =
  p = p - off

template `[]`*[T](p: ptr T, off: int): T =
  (p + off)[]

template `[]=`*[T](p: ptr T, off: int, val: T) =
  (p + off)[] = val