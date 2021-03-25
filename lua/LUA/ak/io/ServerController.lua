--- Export EEP data / read and execute commands.
-- LuaDoc: http://keplerproject.github.io/luadoc/manual.html
--
--[[ Usage:
-- Do NOT use this class manually
-- Use this class in XxxWebConnector to register JsonCollectors and commands
local ServerController = require("ak.io.ServerController")
--]] -- @author Andreas Kreuz
-- @release 0.10.2
if AkDebugLoad then print("Loading ak.io.ServerController ...") end
local AkWebServerIo = require("ak.io.AkWebServerIo")
local AkCommandExecutor = require("ak.io.AkCommandExecutor")
local os = require("os")

local ServerController = {}
ServerController.debug = AkStartWithDebug or false
ServerController.programVersion = "0.10.8"
local json

-- ACHTUNG: DIE VERWENDUNG ERFOLGT AUF EIGENE GEFAHR. ES IST GUT MÖGLICH,
--          DASS EEP ABSTÜRZT, WENN NICHT ALLE ABHÄNGIGKEITEN DER BIBLIOTHEK
--          GEFUNDEN WERDEN.
function ServerController.useDlls(enableDlls)
    if enableDlls then
        package.cpath = package.cpath .. ";.\\LUA\\ak\\?.dll"
        if ServerController.debug then print(package.cpath) end
        json = require("cjson")
        -- Important: Empty tables must not be packed as objects {}, but as lists []
        json.encode_empty_table_as_object(false)
    else
        json = require("ak.io.json")
    end
end
ServerController.useDlls(false)

-- checkServerStatus:
-- true: Check status of EEP-Web Server before updating the json file
-- false: Update json file without checking if the EEP-Web Server is ready
ServerController.checkServerStatus = true

-- List of entries which should be active (default = all)
-- Example: { ["api-entries"] = true, ["eep-version"] = true, }
ServerController.activeEntries = {}

local registeredJsonCollectors = {}
local collectedData = {}
local checksum = 0
local initialized = false

function ServerController.addAcceptedRemoteFunction(fName, f) AkCommandExecutor.addAcceptedRemoteFunction(fName, f) end

local function fillApiEntriesV1(orderedKeys)
    collectedData["api-entries"] = {}
    checksum = checksum + 1
    local apiEntries = {}
    local apiEntry
    for _, key in ipairs(orderedKeys) do
        local count = 0
        for _ in pairs(collectedData[key]) do count = count + 1 end

        local o = {name = key, url = "/api/v1/" .. key, count = count, checksum = checksum, updated = true}
        table.insert(apiEntries, o)

        if o.name == "api-entries" then apiEntry = o end
    end

    if apiEntry then apiEntry.count = #apiEntries end

    collectedData["api-entries"] = apiEntries
end

local function initializeJsonCollector(jsonCollector)
    local t0 = os.clock()
    jsonCollector.initialize()
    local t1 = os.clock()
    local timeDiff = t1 - t0
    if ServerController.debug then
        print(string.format('ServerController: initialize() %4.0f ms for "%s"', timeDiff * 1000, jsonCollector.name))
    end
end

local function collectFrom(jsonCollector, printFirstTime)
    local t0 = os.clock()
    local newData = jsonCollector.collectData()
    local t1 = os.clock()
    local timeDiff = t1 - t0
    if ServerController.debug and (timeDiff > 0.01 or printFirstTime) then
        print(string.format('ServerController: collectData() %4.0f ms for "%s"', timeDiff * 1000, jsonCollector.name))
    end
    return newData
end

local function collectData(printFirstTime)
    for _, jsonCollector in pairs(registeredJsonCollectors) do
        local newData = collectFrom(jsonCollector, printFirstTime)
        for key, value in pairs(newData) do collectedData[key] = value end
    end
end

--- Initialize data.
-- do it once
local function initialize()
    if ServerController.debug then print("ServerController: initialize()") end
    for _, jsonCollector in pairs(registeredJsonCollectors) do initializeJsonCollector(jsonCollector) end

    initialized = true
end

function ServerController.addJsonCollector(...)
    for _, jsonCollector in ipairs({...}) do
        -- Check the jsonCollector
        assert(jsonCollector.name and type(jsonCollector.name) == "string",
        -- "Der Name des Moduls muss gesetzt und ein String sein"
               "The name of the module must be defined and is has to be a string")
        assert(jsonCollector.initialize and type(jsonCollector.initialize) == "function",
        -- "Das Modul muss eine Funktion initialize() besitzen"
               string.format("jsonCollector %s must have a function initialize()", jsonCollector.name))
        assert(jsonCollector.collectData and type(jsonCollector.collectData) == "function",
        -- "Das Modul muss eine Funktion collectData() besitzen"
               string.format("jsonCollector %s must have a function collectData()", jsonCollector.name))

        -- Remember the jsonCollector by it's name
        if ServerController.debug then
            print(string.format("ServerController.addJsonCollector(%s)", jsonCollector.name))
        end
        registeredJsonCollectors[jsonCollector.name] = jsonCollector

        if initialized then initializeJsonCollector(jsonCollector) end
    end
end

local function expandData()
    -- add statistical data
    local orderedKeys = {}
    local exportData = {}
    for key, value in pairs(collectedData) do
        if next(ServerController.activeEntries) == nil or ServerController.activeEntries[key] then
		    -- empty list or requested entry type
            exportData[key] = value
            table.insert(orderedKeys, key)
        end
    end
    -- table.insert(orderedKeys, "api-entries")
    table.sort(orderedKeys)
    fillApiEntriesV1(orderedKeys)
    return exportData, orderedKeys
end

local function encode(exportData) return json.encode(exportData) end

local function writeData(jsonString) AkWebServerIo.updateJsonFile(jsonString) end

local i = -1

--- Main function of this module.
-- Call this function in main loop of EEP.
-- do it frequently
-- @param modulus Repetion frequency (0: always, 1: every 200 ms, 5: every second, ...)
function ServerController.communicateWithServer(modulus)
    -- default value for optional parameter
    if not modulus or type(modulus) ~= "number" then modulus = 5 end
    i = i + 1

    local overallTime0 = os.clock()
    local serverIsReady = not ServerController.checkServerStatus or AkWebServerIo.checkWebServer()

    -- initialization in first call
    local overallTime1 = os.clock()
    local printFirstTime = false
    if not initialized and serverIsReady then
        printFirstTime = true
        initialize()
    end

    -- process commands
    local overallTime2 = os.clock()
    AkWebServerIo.processNewCommands()

    -- export data regularly
    local overallTime3 = os.clock()
    local overallTime4 = overallTime3
    local overallTime5 = overallTime3
    local overallTime6 = overallTime3

    if modulus == 0 or i % modulus == 0 and serverIsReady then
        collectData(printFirstTime, modulus)
        overallTime4 = os.clock()

        local exportData = expandData()
        overallTime5 = os.clock()

        local jsonString = encode(exportData)
        overallTime6 = os.clock()

        writeData(jsonString)
    end

    local overallTime7 = os.clock()
    local timeDiff = overallTime7 - overallTime0
    local allowedTimeDiff = modulus * 0.200
    if ServerController.debug and printFirstTime or timeDiff > allowedTimeDiff then
        local format = (printFirstTime and "INITIALIZATION" or "WARNING") ..
                           ": ServerController.communicateWithServer() time is %3.0f ms --- " ..
                           "waitForServer: %.0f ms, " .. "initialize: %.0f ms, " .. "commands: %2.0f ms, " ..
                           "collect: %3.0f ms, " .. " expand: %3.0f ms " .. " encode: %3.0f ms " .. " write: %.0f ms" ..
                           " (allowed: %.0f ms)"
        print(string.format(format, (timeDiff) * 1000, (overallTime1 - overallTime0) * 1000,
                            (overallTime2 - overallTime1) * 1000, (overallTime3 - overallTime2) * 1000,
                            (overallTime4 - overallTime3) * 1000, (overallTime5 - overallTime4) * 1000,
                            (overallTime6 - overallTime5) * 1000, (overallTime7 - overallTime6) * 1000,
                            (allowedTimeDiff) * 1000))
    end
end

return ServerController
