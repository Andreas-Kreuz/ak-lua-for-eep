if AkDebugLoad then print("Loading ak.core.ModuleRegistry ...") end
local TableUtils = require("ak.util.TableUtils")
local os = require("os")
local ServerController = require("ak.io.ServerController")

local ModuleRegistry = {}
ModuleRegistry.debug = AkStartWithDebug or false
local enableServer = true
local initialized = false
---@type table<string,LuaModule>
local registeredLuaModules = {}
---@type string[]
local executionOrderModuleNames = {}

local function updateModuleOrder()
    TableUtils.clearArray(executionOrderModuleNames)
    for moduleName in pairs(registeredLuaModules) do table.insert(executionOrderModuleNames, moduleName) end
    table.sort(executionOrderModuleNames, function(n1, n2)
        if n1 == "ak.scheduler.SchedulerLuaModule" then return true end
        if n2 == "ak.scheduler.SchedulerLuaModule" then return false end
        return n1 < n2
    end)
end

function ModuleRegistry.getModuleNames()
    local copy = {}
    for i, v in ipairs(executionOrderModuleNames) do copy[i] = v end
    return copy
end

---
-- Registers a module to be used in EEP Web
-- @param module a module of type AkLuaControlModule
function ModuleRegistry.registerModules(...)
    assert(not initialized, "All tasks must be registered before ModuleRegistry.initTasks()")

    for _, module in ipairs({...}) do
        -- Check the module
        assert(module.name and type(module.name) == "string", "A module must have a string name")
        assert(type(module.enabled) == "boolean", string.format("Module %s must have a boolean enabled", module.name))
        assert(module.init and type(module.init) == "function",
               string.format("Module %s must have a function init()", module.name))
        assert(module.run and type(module.run) == "function",
               string.format("Module %s must have a function run()", module.name))

        -- Remember the module by it's name
        registeredLuaModules[module.name] = module
    end

    updateModuleOrder()

    -- pass the modules to the caller in the EEP script
    return registeredLuaModules
end

---
-- Unregisters a module
-- @param module a module of type AkLuaControlModule
function ModuleRegistry.unregisterModules(...)
    for _, module in ipairs({...}) do
        -- Check the module
        assert(module.name and type(module.name) == "string", "A module must have a string name")

        -- Remove the module by it's name
        registeredLuaModules[module.name] = nil
    end
    updateModuleOrder()
end

-- ACHTUNG: DIE VERWENDUNG ERFOLGT AUF EIGENE GEFAHR. ES IST GUT MÖGLICH,
--          DASS EEP ABSTÜRZT, WENN NICHT ALLE ABHÄNGIGKEITEN DER BIBLIOTHEK
--          GEFUNDEN WERDEN.
function ModuleRegistry.useDlls(enableDlls)
    assert(enableDlls == true or enableDlls == false)
    ServerController.useDlls(enableDlls)
end

local function initTask(module)
    if ModuleRegistry.debug then print(string.format('[ModuleRegistry] Begin initTask() for "%s"', module.name)) end
    local t0 = os.clock()
    module.init()
    local t1 = os.clock()
    local timeDiff = t1 - t0
    if ModuleRegistry.debug then
        print(string.format('[ModuleRegistry].initTask() %.3f seconds for "%s"', timeDiff, module.name))
    end
end

local function runTask(module)
    if ModuleRegistry.debug then print(string.format('[ModuleRegistry] Begin runTask() for "%s"', module.name)) end
    local t0 = os.clock()
    module.run()
    local t1 = os.clock()
    local timeDiff = t1 - t0
    -- print(string.format('[ModuleRegistry].runTask() %.3f seconds for "%s"', timeDiff, module.name))
    if ModuleRegistry.debug and timeDiff > 0.01 then
        print(string.format('[ModuleRegistry] WARNING: runTask() %.3f seconds for "%s"', timeDiff, module.name))
    end
end

---
-- This will init all registeredLuaModules
function ModuleRegistry.initTasks()
    if not initialized then
        for _, moduleName in ipairs(executionOrderModuleNames) do initTask(registeredLuaModules[moduleName]) end

        initialized = true
    end
end

---
-- This will run all registeredLuaModules
-- @param cycleCount Repetion frequency (1: every 200 ms, 5: every second, ...)
function ModuleRegistry.runTasks(cycleCount)
    local t1 = os.clock()
    if not initialized then ModuleRegistry.initTasks() end

    local t2 = os.clock()
    for _, moduleName in ipairs(executionOrderModuleNames) do runTask(registeredLuaModules[moduleName]) end

    local t3 = os.clock()
    if enableServer then
        -- Sorgt dafür, dass alle JsonDaten der registrieren XxxJsonColletor zum Server kommen
        -- und dass die Befehle des Servers ausgewertet werden
        ServerController.communicateWithServer(cycleCount)
    end
    local t4 = os.clock()

    if ModuleRegistry.debug then
        print(string.format("[ModuleRegistry] runTasks(%d) time: %.0f ms " ..
                            "(%.0f ms initTasks, %.0f ms runTask, %.0f ms serveData)",
                            cycleCount,
                            (t4 - t1) * 1000,    -- total time
                            (t2 - t1) * 1000,    -- initTasks
                            (t3 - t2) * 1000,    -- runTask
                            (t4 - t3) * 1000)    -- serveData
        )
    end
end

function ModuleRegistry.activateServer() enableServer = true end

function ModuleRegistry.deactivateServer() enableServer = false end

-- Register the core module to hold basic data
do
    local CoreLuaModule = require("ak.core.CoreLuaModule")
    CoreLuaModule.setRegisteredLuaModules(registeredLuaModules)
    ModuleRegistry.registerModules(CoreLuaModule)
end

return ModuleRegistry
