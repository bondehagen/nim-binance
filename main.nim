import asyncdispatch, binance, parsecfg

var config = loadConfig("config.ini")
let api = config.getSectionValue("","api")
let secret = config.getSectionValue("","secret")

proc asyncProc() {.async.} =
  let c = newBinanceClient(api, secret)
  echo await c.connect()

waitFor asyncProc()