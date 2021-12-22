SIF.CoreManager = {
    Ready = false
}

function SIF.CoreManager:Startup(callback)
    -- Module startup chain
    SIF.ConfigManager:Startup(function()
        SIF.LogManager:Startup(function()
            SIF.CacheManager:Startup(function()
                SIF.PluginManager:Startup(function()
                    SIF.LightingManager:Startup(function()
                        SIF.ClientManager:Startup(function()
                            callback()
                        end)
                    end)
                end)
            end)
        end)
    end)
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(10)
    end
    SIF.CoreManager:Startup(function()
        SIF.CoreManager.Ready = true
        SIF.LogManager:infoLog("core", "SonoranCAD Integration Framework - Initialized")
        TriggerEvent("SIF::Core:StartupCompleted")
    end)
end)