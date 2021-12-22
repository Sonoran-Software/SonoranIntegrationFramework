SIF.CacheManager = {
    Ready = false,
    Caches = {},
    WatchedCaches = {}
}

local Cache = {
    Values = {},
    Name = "",
    Get = function(key)
        return self.Values[key]
    end,
    Set = function(key, value)
        self.Values[key] = value
        if self.WatchedCaches[self.Name] then
            TriggerEvent("SIF::Cache:ValueChanged", self.Name, key, value)
        end
        return self.Values[key]
    end,
    Remove = function(key)
        self.Values[key] = nil
    end
}

function Cache:Create(name)
    self.Name = name
    return self
end

function SIF.CacheManager:Startup(callback)
    SIF.LogManager:debugLog("cache", "Cache Manager started")
    self.Ready = true
    callback()
end

function SIF.CacheManager:CreateCache(name)
    self.Caches[name] = Cache:Create(name)
    SIF.LogManager:debugLog("cache", ("Created cache %s"):format(name))
    return self.Caches[name]
end

function SIF.CacheManager:RegisterWatcher(name)
    SIF.LogManager:debugLog("cache", ("Created cache watcher %s"):format(name))
    self.WatchedCaches[name] = true
end

function SIF.CacheManager:GetFromCache(cache, key)
    if not self.Caches[cache] then
        return nil
    end
    return self.Caches[cache]:Get(key)
end

function SIF.CacheManager:SetFromCache(cache, key, value)
    if not self.Caches[cache] then
        return nil
    end
    self.Caches[cache]:Set(key, value)
    return self.Caches[cache]:Get(key)
end