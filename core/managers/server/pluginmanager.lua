SIF.PluginManager = {
    Ready = false,
    Plugins = {}
}

local Plugin = {
    Name = "",
    Functions = {}
}

function Plugin:Create(name)
    self.Name = name
    return self
end

function Plugin:RegisterFunction(name, func)
    self.Functions[name] = func
    return self
end

function SIF.PluginManager:Startup(callback)
    SIF.LogManager:debugLog("plugin", "Plugin Manager started")
    self.Ready = true
    callback()
end

function SIF.PluginManager:LoadPlugin(name, callback)
    SIF.LogManager:debugLog("plugin", ("Loading plugin %s"):format(name))
    local plugin = Plugin:Create(name)
    local config = {}
    SIF.PluginManager.Plugins[name] = plugin
    callback(plugin, config)
end

function SIF.PluginManager:IsLoaded(name)
    if SIF.PluginManager.Plugins[name] ~= nil then
        return true
    else
        return false
    end
end