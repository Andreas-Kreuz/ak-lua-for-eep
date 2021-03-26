if AkDebugLoad then print("Loading ak.core.CoreLuaModule ...") end

---@class LuaModule
CoreLuaModule = {}
CoreLuaModule.id = "8aeef2ab-8672-4f9a-a929-d62845f5f1fc"
CoreLuaModule.enabled = true
local initialized = false
-- Jedes Modul hat einen eindeutigen Namen
CoreLuaModule.name = "ak.core.CoreLuaModule"
local registeredLuaModules = nil

function CoreLuaModule.setRegisteredLuaModules(modules)
    registeredLuaModules = modules
end

--- Diese Funktion wird einmalig durch ModuleRegistry.initTasks() aufgerufen
-- Ist ein Modul für EEPWeb vorhanden, dann sollte es in dieser Funktion aufgerufen werden
-- @author Andreas Kreuz
function CoreLuaModule.init()
    if not CoreLuaModule.enabled or initialized then
        return
    end

    -- Hier wird der CoreWebConnector registriert, so dass die Kommunikation mit der WebApp funktioniert
    local CoreWebConnector = require("ak.core.CoreWebConnector")
    CoreWebConnector.setRegisteredLuaModules(registeredLuaModules)
    CoreWebConnector.registerJsonCollectors();

    initialized = true
end

--- Diese Funktion wird regelmäßig durch ModuleRegistry.runTasks() aufgerufen
-- @author Andreas Kreuz
function CoreLuaModule.run()
    if not CoreLuaModule.enabled then
        return
    end

    -- Hier folgen die wiederkehrenden Funktionen jedes Moduls (müssen dann nicht in EEPMain aufgerufen werden)
    -- Das CoreModul hat keine wiederkehrenden Funktionen
end

--- Über diese Funktion kann das EEP Skript die Optionen des Moduls setzen
-- @author Frank Buchholz
-- @options List of options { debug = true/false, waitForServer = true/false, activeEntries = array of entry names, }
local ServerController = require("ak.io.ServerController")
function CoreLuaModule.setOptions(options)

    -- Debug-Funktionen aktivieren
    if options.debug ~= nil then
        ServerController.debug = options.debug
    end

    -- Jeweils vor den Datenexport prüfen, ob der EEP-Webserver aktiv ist
    if options.waitForServer ~= nil then
        ServerController.checkServerStatus = options.waitForServer
        if ServerController.debug then
            print("CoreLuaModule waitForServer: ", options.waitForServer)
        end
    end

    -- Auswahl der zu exportierende Datenpakete (Default: alle)
    if options.activeEntries then
        if next(options.activeEntries) == nil then
            ServerController.activeEntries = {}
            if ServerController.debug then
                print("CoreLuaModule activeEntries: set to default (all)")
            end
        else
            for key, value in pairs(options.activeEntries) do
                if ServerController.activeEntries[key] or value then
                    ServerController.activeEntries[key] = value
                    if ServerController.debug then
                        print("CoreLuaModule activeEntries: ",key," ",value)
                    end
                end
            end
        end
    end
end

return CoreLuaModule
