import wit/[spin_http, wasi_outbound_http], types
import spin/private/utils
import std/[tables, options, uri]
from std/httpclient import HttpMethod

const httpMethods = {
  SPIN_HTTP_METHOD_GET: HttpGet,
  SPIN_HTTP_METHOD_POST: HttpPost,
  SPIN_HTTP_METHOD_PUT: HttpPut,
  SPIN_HTTP_METHOD_DELETE: HttpDelete,
  SPIN_HTTP_METHOD_PATCH: HttpPatch,
  SPIN_HTTP_METHOD_HEAD: HttpHead,
  SPIN_HTTP_METHOD_OPTIONS: HttpOptions
}.toTable

proc nth[T](base: ptr T, n: SomeInteger): ptr T =
  let size = sizeof T
  let header = addr(cast[ptr UncheckedArray[byte]](base)[n.int * size])
  cast[ptr T](header)

proc fromSpin(headers: spin_http_headers_t): HttpHeaders =
  result = newTable[string, string]()
  for i in 0..<headers.len:
    let header = headers.ptr.nth(i)
    result[$header.f0.ptr] = $header.f1.ptr

proc toSpin(headers: HttpHeaders): ptr spin_http_headers_t =
  result = create(spin_http_headers_t, 1)
  result.len = headers.len.uint
  result.ptr = create(spin_http_tuple2_string_string_t, result.len)
  var i = 0
  for key, val in headers:
    let header = result.ptr.nth(i)
    spinHttpStringSet(addr header.f0, newUnmanagedStr(key))
    spinHttpStringSet(addr header.f1, newUnmanagedStr(val))
    inc i

proc toSpin*(headers: Option[HttpHeaders]): ptr spin_http_option_headers_t =
  result = create(spin_http_option_headers_t, 1)
  if headers.isSome:
    result.isSome = true
    result.val = headers.get.toSpin[]

proc fromSpin(body: spin_http_option_body_t): Option[string] =
  if body.isSome:
    let len = body.val.len
    if len > 0:
      let str = newString(len)
      copyMem(unsafeAddr str[0], body.val.ptr, len)
      result = some(str)

proc toSpin*(body: Option[string]): ptr spin_http_option_body_t =
  result = create(spin_http_option_body_t, 1)
  if body.isSome:
    result.isSome = true
    var dataPtr = create(byte, body.get.len)
    copyMem(dataPtr, unsafeAddr body.get[0], body.get.len)
    result.val = spin_http_body_t(
      `ptr`: dataPtr,
      len: body.get.len.uint
    )

proc fromSpin*(request: spin_http_request_t): Request =
  Request(
    `method`: httpMethods[request.method],
    uri: parseUri($request.uri.ptr),
    headers: request.headers.fromSpin,
    body: request.body.fromSpin
  )

const outboundHttpMethods = {
  HttpGet: WASI_OUTBOUND_HTTP_METHOD_GET,
  HttpPost: WASI_OUTBOUND_HTTP_METHOD_POST,
  HttpPut: WASI_OUTBOUND_HTTP_METHOD_PUT,
  HttpDelete: WASI_OUTBOUND_HTTP_METHOD_DELETE,
  HttpPatch: WASI_OUTBOUND_HTTP_METHOD_PATCH,
  HttpHead: WASI_OUTBOUND_HTTP_METHOD_HEAD,
  HttpOptions: WASI_OUTBOUND_HTTP_METHOD_OPTIONS
}.toTable

proc fromWasi(headers: wasi_outbound_http_option_headers_t): Option[HttpHeaders] =
  if headers.isSome:
    var table = newTable[string, string]()
    for i in 0..<headers.val.len:
      let header = headers.val.ptr.nth(i)
      table[$header.f0.ptr] = $header.f1.ptr
    result = some(table)

proc toWasi(headers: HttpHeaders): ptr wasi_outbound_http_headers_t =
  result = create(wasi_outbound_http_headers_t, 1)
  result.len = headers.len.uint
  result.ptr = create(wasi_outbound_http_tuple2_string_string_t, result.len)
  for key, val in headers:
    result.len += 1
    let header = result.ptr.nth(result.len)
    wasiOutboundHttpStringSet(addr header.f0, newUnmanagedStr(key))
    wasiOutboundHttpStringSet(addr header.f1, newUnmanagedStr(val))

proc fromWasi(body: wasi_outbound_http_option_body_t): Option[string] =
  if body.isSome:
    let len = body.val.len
    if len > 0:
      let str = newString(len)
      copyMem(unsafeAddr str[0], body.val.ptr, len)
      result = some(str)

proc toWasi(body: Option[string]): ptr wasi_outbound_http_option_body_t =
  result = create(wasi_outbound_http_option_body_t, 1)
  if body.isSome:
    result.isSome = true
    var dataPtr = create(byte, body.get.len)
    copyMem(dataPtr, unsafeAddr body.get[0], body.get.len)
    result.val = wasi_outbound_http_body_t(
      `ptr`: dataPtr,
      len: body.get.len.uint
    )

proc toWasi*(req: Request): ptr wasi_outbound_http_request_t  =
  result = create(wasi_outbound_http_request_t, 1)
  result.method = outboundHttpMethods[req.method].uint8
  wasiOutboundHttpStringSet(addr result.uri, newUnmanagedStr($req.uri))
  result.headers = req.headers.toWasi[]
  result.body = req.body.toWasi[]

proc newWasiResponse*(): ptr wasi_outbound_http_response_t =
  create(wasi_outbound_http_response_t, 1)

proc fromWasi*(res: wasi_outbound_http_response_t): Response =
  result = Response(
    status: res.status,
    headers: res.headers.fromWasi,
    body: res.body.fromWasi
  )
