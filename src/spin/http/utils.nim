import private/types
import std/[options, tables]

proc `?&`*(headers: HttpHeaders, key: string): Option[string] =
  if headers.hasKey(key):
    some(headers[key])
  else:
    none(string)

proc `?&`*(params: seq[tuple[key, value: string]], key: string): Option[string] =
  for (k, v) in params:
    if k == key:
      return some(v)
  return none(string)
