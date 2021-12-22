SIF.ApiManager = {
    Ready = false,
    ApiUrls = {
        production = "https://api.sonorancad.com/",
        development = "https://cadapi.dev.sonoransoftware.com/"
    },
    ApiUrl = "",
    Call = {},
    RateLimitedEndpoints = {},
    ApiSendEnabled = true,
    ApiVersion = 0,
    ApiEndpoints = {}
}
function SIF.ApiManager:Startup(callback)
    SIF.LogManager:debugLog("api", "API Manager started")
    self.Ready = true
    CreateThread(function()
        while SIF.HttpdManager == nil do
            Wait(1)
        end
        SIF.HttpdManager:Startup()
    end)
    self.ApiUrl = self:GetApiUrl()
    self:VersionCheck()
    callback()
end

function SIF.ApiManager:GetApiUrl()
    if SIF.ConfigManager:Get("mode") == nil then
        return self.ApiUrls.production
    else
        if self.ApiUrls[SIF.ConfigManager:Get("mode")] ~= nil then
            return self.ApiUrls[SIF.ConfigManager:Get("mode")]
        else
            TriggerEvent("SIF::CRITICAL_ERROR")
            assert(false, "Invalid mode. Valid values are production, development")
        end
    end
end

function SIF.ApiManager:RegisterEndpoint(name, type, version)
    self.ApiEndpoints[name] = { type = type, version = version }
end

function SIF.ApiManager:VersionCheck()
    CreateThread(function()
        self.Call:GET_VERSION(function(result)
            self.ApiVersion = result
            SIF.LogManager:debugLog("api", ("Set version %s"):format(self.ApiVersion))
            SIF.LogManager:infoLog("api", ("Loaded community ID %s with API URL: %s"):format(SIF.ConfigManager:Get("communityID"), self.ApiUrl))
            self.ApiVersion = 0
            if SIF.ConfigManager:Get("primaryIdentifier") == "steam" and GetConvar("steam_webapiKey", "none") == "none" then
                errorLog("You have set SonoranCAD to Steam mode, but have not configured a Steam Web API key. Please see FXServer documentation. SonoranCAD will not function in Steam mode without this set.")
                TriggerEvent("SIF::CRITICAL_ERROR")
            end

            SIF.ApiManager.Call:GET_SERVERS(function(value)
                print("got "..tostring(value))
            end)
        end)
        
        --[[
        local versionfile = json.decode(LoadResourceFile(GetCurrentResourceName(), "/version.json"))
        local fxversion = versionfile.testedFxServerVersion
        local currentFxVersion = getServerVersion()
        if currentFxVersion ~= nil and fxversion ~= nil then
            if tonumber(currentFxVersion) < tonumber(fxversion) then
                warnLog(("SonoranCAD has been tested with FXServer version %s, but you're running %s. Please update ASAP."):format(fxversion, currentFxVersion))
            end
        end
        if GetResourceState("sonoran_updatehelper") == "started" then
            ExecuteCommand("stop sonoran_updatehelper")
        end
        --]]
    end)
end

function SIF.ApiManager:PerformHttpRequest(url, cb, method, data, headers)
    if not data then
        data = ""
    end
    if not headers then
        headers = {["X-User-Agent"] = "SonoranCAD"}
    end
    exports["sonorancadv3"]:HandleHttpRequest(url, cb, method, data, headers)
end

function SIF.ApiManager:PerformApiRequest(postData, ep, cb)
    SIF.LogManager:debugLog("api", ("Running API request %s: %s"):format(ep, json.encode(postData)))
    local endpoint = self.ApiEndpoints[ep]
    if not endpoint then
        SIF.LogManager:errorLog("api", ("Unsupported API request %s"):format(ep))
        return cb(nil, false)
    end
    local payload = {}
    payload["id"] = SIF.ConfigManager:Get("communityID")
    payload["key"] = SIF.ConfigManager:Get("apiKey")
    payload["data"] = postData
    payload["type"] = ep
    local url = ""
    local apiUrl = self.ApiUrl
    if endpoint == "support" then
        apiUrl = "https://api.sonoransoftware.com/"
        url = apiUrl..tostring(endpoint.type).."/"
    else
        url = apiUrl..tostring(endpoint.type).."/"..tostring(ep:lower())
    end
    if SIF.ConfigManager.KillSwitch then
        return
    elseif not self.ApiSendEnabled then
        SIF.LogManager:warnLog("api", "API sending is disabled, ignoring request.")
        return
    end

    if self.RateLimitedEndpoints[ep] == nil then
        self:PerformHttpRequest(url, function(statusCode, res, headers)
            SIF.LogManager:debugLog("api", ("Endpoint %s called with post data %s to url %s"):format(ep, json.encode(payload), url))
            if statusCode == 200 and res ~= nil then
                SIF.LogManager:debugLog("api", "result: "..tostring(res))
                if res == "Sonoran CAD: Backend Service Reached" or res == "Backend Service Reached" then
                    SIF.LogManager:errorLog("api", ("API ERROR: Invalid endpoint (URL: %s). Ensure you're using a valid endpoint."):format(url))
                else
                    cb(res, true)
                end
            elseif statusCode == 400 then
                SIF.LogManager:warnLog("api", "Bad request was sent to the API. Enable debug mode and retry your request. Response: "..tostring(res))
                -- additional safeguards
                if res == "INVALID COMMUNITY ID" or res == "API IS NOT ENABLED FOR THIS COMMUNITY" or string.find(res, "IS NOT ENABLED FOR THIS COMMUNITY") or res == "INVALID API KEY" then
                    SIF.LogManager:errorLog("api", "Fatal: Disabling API - an error was encountered that must be resolved. Please restart the resource after resolving: "..tostring(res))
                    self.ApiSendEnabled = false
                end
                cb(res, false)
            elseif statusCode == 404 then -- handle 404 requests, like from CHECK_APIID
                SIF.LogManager:debugLog("api", "404 response found")
                cb(res, false)
            elseif statusCode == 429 then -- rate limited :(
                if self.RateLimitedEndpoints[type] then
                    -- don't warn again, it's spammy. Instead, just print a debug
                    SIF.LogManager:debugLog("api", ("Endpoint %s ratelimited. Dropping request."):format(ep))
                    return
                end
                self.RateLimitedEndpoints[type] = true
                SIF.LogManager:warnLog("api", ("You are being ratelimited (last request made to %s) - Ignoring all API requests to this endpoint for 60 seconds. If this is happening frequently, please review your configuration to ensure you're not sending data too quickly."):format(ep))
                SetTimeout(60000, function()
                    self.RateLimitedEndpoints[type] = nil
                    SIF.LogManager:infoLog("api", ("Endpoint %s no longer ignored."):format(ep))
                end)
            elseif string.match(tostring(statusCode), "50") then
                SIF.LogManager:errorLog("api", ("API error returned (%s). Check status.sonoransoftware.com or our Discord to see if there's an outage."):format(statusCode))
                SIF.LogManager:debugLog("api", ("Error returned: %s %s"):format(statusCode, res))
            else
                SIF.LogManager:errorLog("api", ("CAD API ERROR (from %s): %s %s"):format(url, statusCode, res))
            end
        end, "POST", json.encode(payload), {["Content-Type"]="application/json"})
    else
        SIF.LogManager:debugLog("api", ("Endpoint %s is ratelimited. Dropped request: %s"):format(type, json.encode(payload)))
    end
end


------ API Calls ------- name, type, version, handlerfunc

-- Returns version as Integer
SIF.ApiManager:RegisterEndpoint("GET_VERSION", "general", 0)
function SIF.ApiManager.Call:GET_VERSION(cb)
    while not SIF.ApiManager.Ready do
        Wait(0)
    end
    SIF.ApiManager:PerformApiRequest({}, "GET_VERSION", function(result, ok)
        if not ok then
            SIF.LogManager:errorLog("api", "Failed to get version information. Is the API down? Please restart sonorancad.")
            TriggerEvent("SIF::CRITICAL_ERROR")
            return
        end
        self.ApiVersion = tonumber(string.sub(result, 1, 1))
        if self.ApiVersion < 2 then
            SIF.LogManager:errorLog("api", "ERROR: Your community cannot use any plugins requiring the API. Please purchase a subscription of Standard or higher.")
            TriggerEvent("SIF::CRITICAL_ERROR")
            return
        end
        cb(self.ApiVersion)
    end)
end

SIF.ApiManager:RegisterEndpoint("GET_SERVERS", "general", 2)
function SIF.ApiManager.Call:GET_SERVERS(cb)
    SIF.ApiManager:PerformApiRequest({}, "GET_SERVERS", function(result, ok)
        if not ok then
            return SIF.LogManager:errorLog("api", "Failed to get server data")
        end
        local info = json.decode(result)
        cb(info)
    end)
end

SIF.ApiManager:RegisterEndpoint("CALL_911", "emergency", 2)
function SIF.ApiManager.Call:CALL_911(caller, location, description, isEmergency, metadata, cb)
    SIF.ApiManager:PerformApiRequest({
        serverId = SIF.ConfigManager:Get("serverId"),
        caller = caller,
        location = location,
        description = description,
        isEmergency = isEmergency,
        metaData = metadata
    }, "CALL_911", function(result, ok)
        if not ok then
            return SIF.LogManager:errorLog("api", "Failed to create 911 call: "..tostring(result))
        end
        if result:match("EMERGENCY CALL ADDED ID:") then
            cb(result:match("%d+"))
        else
            return SIF.LogManager:errorLog("api", "Unexpected response from API in CALL_911: "..tostring(result))
        end
    end)
end