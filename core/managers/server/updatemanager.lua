SIF.UpdateManager = {
    Ready = false
}

function SIF.UpdateManager:Startup(callback)
    SIF.LogManager:debugLog("update", "Update Manager started")
    self.Ready = true
    callback()
end