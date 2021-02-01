import asyncdispatch, nim_binance_api, parsecfg

var config = loadConfig("config.ini")
let api = config.getSectionValue("","api")
let secret = config.getSectionValue("","secret")

proc main() {.async.} =
  let c = newBinanceClient(api, secret)
  echo await c.connect()


when isMainModule:
  waitFor main()