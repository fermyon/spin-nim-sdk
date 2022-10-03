# spin-nim-sdk

## Installation
```bash
git clone https://github.com/fermyon/spin-nim-sdk.git
cd spin-nim-sdk
nimble install
```

_Later this repo will be published at [Nim packages](https://github.com/nim-lang/packages)._

## Usage
This SDK allows you to create a spin nim component. At minimum, the following directory structure is needed:
```
nim_component
├── configs.nims
└── nim_component.nim
```

`configs.nims` configures the compiler and the linker so that it produces the desired wasi component.
```ini
--os:linux # Emscripten pretends to be linux.
--cpu:wasm32 # Emscripten is 32bits.
--cc:clang # Emscripten is very close to clang, so we ill replace it.
when defined(windows):
  --clang.exe:emcc.bat  # Replace C
  --clang.linkerexe:emcc.bat # Replace C linker
  --clang.cpp.exe:emcc.bat # Replace C++
  --clang.cpp.linkerexe:emcc.bat # Replace C++ linker.
else:
  --clang.exe:emcc  # Replace C
  --clang.linkerexe:emcc # Replace C linker
  --clang.cpp.exe:emcc # Replace C++
  --clang.cpp.linkerexe:emcc # Replace C++ linker.

--listCmd # List what commands we are running so that we can debug them.
# --gc:arc # GC:arc is friendlier with crazy platforms.
--mm:orc # GC:orc is friendlier with crazy platforms.
# --define:useMalloc
--exceptions:goto # Goto exceptions are friendlier with crazy platforms.
--define:noSignalHandler # Emscripten doesn't support signal handlers.
--noMain:on
--threads:off # 1.7.1 defaults this on

let outputName = projectName() & ".wasm"

switch("passL", "--no-entry -sSTANDALONE_WASM=1 -sERROR_ON_UNDEFINED_SYMBOLS=0")
switch("passL", "-o " & outputName)
```

_For now just copy-paste its contents from above. Later there will be a spin template so you won't have to worry about it._ 

## HTTP trigger
A trivial example:
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
