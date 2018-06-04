import strutils, hashes

type
  UUID* = object
    mostSigBits, leastSigBits: int64

proc hash*(uuid: UUID): Hash =
  result = uuid.mostSigBits.hash() !& uuid.leastSigBits.hash()
  result = !$result
proc `==`*(a, b: UUID): bool =
  a.mostSigBits == b.mostSigBits and a.leastSigBits == b.leastSigBits

proc showUuid(ba: array[0x10, byte]): string {.noSideEffect.} =
  const hexChars = "0123456789abcdef"

  result = newString(36)
  for i in 0..<4:
    result[2*i] = hexChars[int ba[7-i] shr 4 and 0xF]
    result[2*i+1] = hexChars[int ba[7-i] and 0xF]
  result[8] = '-'
  for i in 4..<6:
    result[2*i+1] = hexChars[int ba[7-i] shr 4 and 0xF]
    result[2*i+2] = hexChars[int ba[7-i] and 0xF]
  result[13] = '-'
  for i in 6..<8:
    result[2*i+2] = hexChars[int ba[7-i] shr 4 and 0xF]
    result[2*i+3] = hexChars[int ba[7-i] and 0xF]
  result[18] = '-'
  for i in 8..<10:
    result[2*i+3] = hexChars[int ba[23-i] shr 4 and 0xF]
    result[2*i+4] = hexChars[int ba[23-i] and 0xF]
  result[23] = '-'
  for i in 10..<16:
    result[2*i+4] = hexChars[int ba[23-i] shr 4 and 0xF]
    result[2*i+5] = hexChars[int ba[23-i] and 0xF]

proc `$`*(uuid: UUID) : string =
  cast[array[0x10, byte]](uuid).showUuid

proc uuidsParseHexInt(s: string, maxLen: int): int64 =
  if s.isNil or s.len == 0:
    raise newException(ValueError, "UUID part is empty")
  if s.len > maxLen or s.len > sizeof(result) * 2:
    raise newException(ValueError, "UUID part is longer than expected")
  for c in s:
    case c
    of '0'..'9':
      result = result shl 4 or (ord(c) - ord('0'))
    of 'a'..'f':
      result = result shl 4 or (ord(c) - ord('a') + 10)
    of 'A'..'F':
      result = result shl 4 or (ord(c) - ord('A') + 10)
    else: raise newException(ValueError, "Invalid hex string: " & s)

proc toUUID*(s: string): UUID =
  let parts = s.split('-')
  var mostSigBits: int64 = uuidsParseHexInt(parts[0], 8)
  mostSigBits = mostSigBits shl 16
  mostSigBits = mostSigBits or uuidsParseHexInt(parts[1], 4)
  mostSigBits = mostSigBits shl 16
  mostSigBits = mostSigBits or uuidsParseHexInt(parts[2], 4)

  var leastSigBits: int64 = uuidsParseHexInt(parts[3], 4)
  leastSigBits = leastSigBits shl 48
  leastSigBits = leastSigBits or uuidsParseHexInt(parts[4], 12)

  result = UUID(mostSigBits: mostSigBits, leastSigBits: leastSigBits)
  discard