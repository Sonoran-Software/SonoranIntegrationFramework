--[[
    Sonoran Integration Framework

    Plugin: Locations
]]

CreateThread(function()
    while not SIF.PluginManager.Ready do
        Wait(0)
    end
    local LocationCache = nil
    SIF.PluginManager:LoadPlugin("locations", function(hook, pluginConfig)
        -- Initialization
        LocationCache = SIF.CacheManager:CreateCache("LocationCache")
        SIF.CacheManager:RegisterWatcher("LocationCache")

        hook:RegisterFunction("SendLocations", function()
            SIF.LogManager:debugLog("locations", "Hello, world!")
        end)

        hook:RegisterFunction("FindPlayerLocation", function(self, playerSrc)
            SIF.LogManager:debugLog("locations", "Hello, world! "..tostring(playerSrc))
        end)

        hook:RegisterFunction("Test", function(self, var1, var2, var3)
            SIF.LogManager:infoLog("locations", ("TEST FUNCTION: %s %s %s"):format(var1, var2, var3))
        end)

        CreateThread(function()
            Wait(1)
            hook.Functions:SendLocations()
            hook.Functions:Test("hello", "world", "foo")
        end)

    end)
end)