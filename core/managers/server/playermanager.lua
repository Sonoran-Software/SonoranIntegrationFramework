SIF.PlayerManager = {
    Ready = false,
    CurrentPlayerCount = 0,
    PlayerCaches = {}
}

function SIF.PlayerManager:Startup(callback)
    SIF.LogManager:debugLog("player", "Player Manager started")
    self.Ready = true
    callback()
end