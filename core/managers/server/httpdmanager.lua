SIF.HttpdManager = {
    Ready = false
}

function SIF.HttpdManager:Startup()
    SIF.LogManager:debugLog("httpd", "HTTPd Manager started")
    self.Ready = true
end