--[[
    Sonoran Integration Framework

    Plugin: apicache

    Essential plugin for "caching" various data from SonoranCAD
]]

CreateThread(function()
    while not SIF.PluginManager.Ready do
        Wait(0)
    end
    SIF.PluginManager:LoadPlugin("apicache", function(hook, pluginConfig)

        local function UnitCacheRunner()

        end
        local function CallCacheRunner()

        end

        if SIF.ApiManager.ApiVersion > 2 then

        end
    end)
end)