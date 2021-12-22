SIF.ConfigManager = {
    Ready = false,
    Settings = {},
    ProtectedSettings = { ['apiKey'] = true },
    KillSwitch = false
}

function SIF.ConfigManager:Startup(callback) 
    self.Settings = shallowcopy(SIFConfig)
    self.Ready = true
    callback()
end

function SIF.ConfigManager:Get(setting)
    if KillSwitch then
        return nil
    end
    if self.Settings[setting] then
        return self.Settings[setting]
    else
        return nil
    end
end

function SIF.ConfigManager:Set(setting, newvalue)
    self.Settings[setting] = newvalue
    return self
end

function SIF.ConfigManager:CheckConfiguration()
    CreateThread(function()
        Wait(2000)
        
    end)
end

RegisterNetEvent("SIF::Config:GetClientConfiguration")
AddEventHandler("SIF::Config:GetClientConfiguration", function()
    local source = source
    local payload = {}
    for key, value in pairs(self.Settings) do
        if self.ProtectedSettings[key] ~= nil then
            payload[key] = value
        end
    end
    TriggerClientEvent("SIF::Config:ClientConfiguration", source, payload)
end)

RegisterServerEvent("SIF::CRITICAL_ERROR")
AddEventHandler("SIF::CRITICAL_ERROR", function()
    SIF.LogManager:errorLog("core", "Critical error has been triggered. Framework execution halted.")
    SIF.ConfigManager.KillSwitch = true
end)