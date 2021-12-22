SIF.CoreManager = {
    Ready = false
}

function SIF.CoreManager:Startup(callback)
    -- Module startup chain
    SIF.ConfigManager:Startup(function()
        SIF.LogManager:Startup(function()
            SIF.ApiManager:Startup(function()
                SIF.CacheManager:Startup(function()
                    SIF.UpdateManager:Startup(function()
                        SIF.PlayerManager:Startup(function()
                            SIF.PluginManager:Startup(function()
                                callback()
                            end)
                        end)
                    end)
                end)
            end)
        end)
    end)
end

function SIF.CoreManager:MetricsTimer()
    SIF.LogManager:debugLog("core", "In metrics timer")
end

CreateThread(function()
    Wait(100)
    SIF.CoreManager:Startup(function()
        SIF.CoreManager.Ready = true
        SIF.LogManager:infoLog("core", "SonoranCAD Integration Framework - Initialized")
        TriggerEvent("SIF::Core:StartupCompleted")
        CreateThread(function() SIF.CoreManager:MetricsTimer() end)
    end)
end)