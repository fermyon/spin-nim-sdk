# spin-nim-sdk

### HTTP trigger

Real documentation coming soon. Meanwhile, a trivial example:
```nim
import spin/http
import tables, options, strutils, strformat
from std/httpclient import HttpMethod

httpComponent do (req: Request) -> Response:
  var capitals = {
    "Japan": "Tokyo",
    "Norway": "Oslo",
    "Greece": "Athens"
  }.toTable
  case req.method
  of HttpGet:
    let city = req.uri.query
    if city in capitals:
      result.status = 200
      result.body = some(capitals[city])
    else:
      result.status = 404
  of HttpPost:
    if req.body.isSome:
      let parsed = req.body.get.split(',')
      if parsed.len == 2:
        let
          country = parsed[0]
          capital = parsed[1]
        result.status = 200
        result.body = some(&"The capital of {country} is {capital}")
      else:
        result.status = 400
        result.body = some("Invalid data")
  else:
    result.status = 405
```