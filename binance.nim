import asyncdispatch, httpclient, json, uri
import strformat
import nimcrypto, times, os

# Don't know why array concat does not exist..
proc concat[I1, I2: static[int]; T](a: array[I1, T], b: array[I2, T]): array[I1 + I2, T] =
  result[0..a.high] = a
  result[a.len..result.high] = b

type BinanceClient* = ref object
  apiKey: string
  apiSecret: string
  baseUrl: string

proc newBinanceClient*(apiKey = "", apiSecret = ""): BinanceClient =
  new result
  result.apiKey = apiKey
  result.apiSecret = apiSecret
  result.baseUrl = "https://api.binance.com/"

proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
  echo("Downloaded ", progress, " of ", total)
  echo("Current rate: ", speed div 1000, "kb/s")

proc get(client: BinanceClient, path: string | Uri, query: array, body = ""): Future[string] {.async.} =
  var httpClient = newAsyncHttpClient()
  httpClient.onProgressChanged = onProgressChanged
  #httpClient.headers = newHttpHeaders({ "Content-Type": "application/json" })
  #httpClient.headers = newHttpHeaders({ "Content-Type": "application/x-www-form-urlencoded" })
  httpClient.headers = newHttpHeaders({ "X-MBX-APIKEY": client.apiKey })

  #let body = %*{
  #    "data": "some text"
  #}
  
  let totalParams = encodeQuery(query) & body 
  let digest = $sha256.hmac(client.apiSecret, totalParams)
  let url = parseUri(client.baseUrl) / path ? query.concat({ "signature": $digest })
  echo "\nRequest url:\n" & $url

  let response = await httpClient.request($url, httpMethod = HttpGet)
  #let response = await client.request($url, httpMethod = HttpPost, body = $body)

  echo "\nStatus code: " & response.status

  echo "\nHeaders:\n"
  for key, value in response.headers:
    echo fmt"{key}:  {value}"

  echo "\nBody:\n"
  let responseBody = await response.body
  echo responseBody[0..300] & "...\nFull length: " & $len(responseBody)

  discard response

  return "\n\nDone"

proc connect*(client: BinanceClient): Future[string] {.async.} =
  let time = getTime()
  let timestamp = $initDuration(seconds = time.toUnix(), nanoseconds = time.nanosecond()).inMilliseconds
  let query = { "timestamp": $timestamp }
  return await get(client, "/sapi/v1/capital/config/getall", query)

