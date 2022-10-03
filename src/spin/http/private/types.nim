import std/[options, tables, uri]
from std/httpclient import HttpMethod
export HttpMethod

type
  HttpHeaders* = TableRef[string, string]
  Request* = object
    `method`*: HttpMethod
    uri*: Uri
    headers*: HttpHeaders
    body*: Option[string]
  Response* = object
    status*: uint16
    headers*: Option[HttpHeaders]
    body*: Option[string]
  WasiCode* = enum
    Success
    DestinationNotAllowed
    InvalidUrl
    RequestError
    RuntimeError