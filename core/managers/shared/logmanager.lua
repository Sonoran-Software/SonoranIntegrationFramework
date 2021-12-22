SIF.LogManager = {
    Ready = false,
    MessageBuffer = {},
    MonitoredModules = {}
}


function SIF.LogManager:sendConsole(level, module, color, message)
    local logLevel = SIF.ConfigManager:Get("loggingMode")
    if logLevel == nil then
        logLevel = "info"
    end
    local time = os and os.date("%X") or LocalTime()
    local info = debug.getinfo(3, 'S')
    local source = "."
    if info.source:find("@@sonorancadv3") then
        source = info.source:gsub("@@sonorancadv3/","")..":"..info.linedefined
    end
    local msg = ""
    if logLevel == "verbose" then
        msg = ("[%s][%s][%s:%s%s^7]%s %s^0"):format(time, module, source, color, level, color, message)
    elseif logLevel == "coredebug" and module == "core" then
        msg = ("[%s][%s:%s%s^7](%s)%s %s^0"):format(time, module, source, color, level, color, message)
    elseif logLevel == "info" and (level == "INFO" or self.MonitoredModules[module] ~= nil) then
        msg = ("[%s][%s:%s%s^7](%s)%s %s^0"):format(time, module, "SonoranCAD", color, level, color, message)
    elseif logLevel == "errorsonly" and (level == "ERROR" or level == "WARNING") then
        msg = ("[%s][%s:%s%s^7](%s)%s %s^0"):format(time, module, "SonoranCAD", color, level, color, message)
    else
        return
    end
    print(msg)
    if not IsDuplicityVersion() then
        if #self.MessageBuffer > 10 then
            table.remove(self.MessageBuffer)
        end
        table.insert(self.MessageBuffer, 1, msg)
    end
end

function SIF.LogManager:Startup(callback)
    print(("^5%s^0"):format([[
        _____                                    _________    ____     
       / ___/____  ____  ____  _________ _____  / ____/   |  / __ \    
       \__ \/ __ \/ __ \/ __ \/ ___/ __ `/ __ \/ /   / /| | / / / /    
      ___/ / /_/ / / / / /_/ / /  / /_/ / / / / /___/ ___ |/ /_/ /     
     /____/\____/_/ /_/\____/_/   \__,_/_/ /_/\____/_/  |_/_____/      
                                                                       
    ]]))
    self:debugLog("logging", "Logging Manager started")
    callback()
end

function SIF.LogManager:infoLog(module, message)
    self:sendConsole("INFO", module, "^5", message)
end

function SIF.LogManager:debugLog(module, message)
    self:sendConsole("DEBUG", module, "^7", message)
end

function SIF.LogManager:warnLog(module, message)
    self:sendConsole("WARNING", module, "^3", message)
end

function SIF.LogManager:errorLog(module, message)
    self:sendConsole("ERROR", module, "^1", message)
end