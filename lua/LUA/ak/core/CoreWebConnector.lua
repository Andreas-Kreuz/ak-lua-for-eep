if AkDebugLoad then print("Loading ak.core.CoreWebConnector ...") end
local CoreWebConnector = {}
local ServerController = require("ak.io.ServerController")
local registeredLuaModules = nil
function CoreWebConnector.setRegisteredLuaModules(modules)
    registeredLuaModules = modules
end

function CoreWebConnector.registerJsonCollectors()
    local ModulesJsonCollector = require("ak.core.ModulesJsonCollector")
    ModulesJsonCollector.setRegisteredLuaModules(registeredLuaModules)
    ServerController.addJsonCollector(ModulesJsonCollector)

    if next(ServerController.activeEntries) == nil or ServerController.activeEntries["eep-version"] then
        ServerController.addJsonCollector(require("ak.core.VersionJsonCollector"))
    end
end

return CoreWebConnector
