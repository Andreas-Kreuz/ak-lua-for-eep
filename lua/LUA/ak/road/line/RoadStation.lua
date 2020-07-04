if AkDebugLoad then
    print("Loading ak.road.line.RoadStation ...")
end

local Train = require("ak.train.Train")
local StationQueue = require("ak.road.line.StationQueue")
local StorageUtility = require("ak.storage.StorageUtility")

---@class RoadStation
local RoadStation = {}
RoadStation.debug = false
local allStations = {}

local function queueToText(queue)
    if (queue) then
        local trainsNames = {}
        for _, trainName in ipairs(queue.entriesByArrival) do
            table.insert(trainsNames, trainName)
        end
        return table.concat({}, "|")
    else
        return ""
    end
end

local function queueFromText(pipeSeparatedText)
    local queue = StationQueue:new()
    for element in string.gmatch(pipeSeparatedText, "[^|]+") do
        -- print(element)
        queue:push(element, 0)
    end
    return queue
end

local function save(station)
    if station.eepSaveId ~= -1 then
        local data = {}
        data["q"] = queueToText(station.queue)
        StorageUtility.saveTable(station.eepSaveId, data, "Station " .. station.name)
    end
end

local function load(station)
    if station.eepSaveId ~= -1 then
        local data = StorageUtility.loadTable(station.eepSaveId, "Station " .. station.name)
        station.queue = queueFromText(data["q"] or "")
    else
        station.queue = StationQueue:new()
    end
end

function RoadStation:trainArrivesIn(trainName, timeInMinutes)
    assert(type(trainName) == "string", "Provide 'trainName' as 'string' was " .. type(trainName))
    assert(type(timeInMinutes) == "number", "Provide 'timeInMinutes' as 'number' was ".. type(timeInMinutes))

    local train = Train.forName(trainName)
    local routeName = train:getRoute()
    assert(type(routeName) == "string", "routeName must be of type 'string' was " .. type(routeName))

    local platform
    if self.routes
        and self.routes[routeName]
        and self.routes[routeName].platform then
        platform = self.routes[routeName].platform
    else
        -- if RoadStation.debug then
            print("[RoadStation] " .. self.name
                .. " NO PLATFORM FOR TRAIN: " .. trainName
                .. (routeName and " (" .. routeName .. ")" or ""))
            platform = "1"
        -- end
    end

    if RoadStation.debug then
        print(
            string.format(
                "[RoadStation] %s: Planning Arrival of %s in %d min on platform %s",
                self.name,
                trainName,
                timeInMinutes,
                platform)
    )
    end

    self.queue:push(trainName, timeInMinutes, platform)
    self:updateDisplays()
end

function RoadStation:trainLeft(trainName)
    self.queue:pop(trainName)
    self:updateDisplays()
end

function RoadStation:setPlatform(route, platform)
    assert(type(route) == "table", "Provide 'route' as 'table' was ".. type(route))
    assert(route.type == "Route", "Provide 'route' as 'Route'")
    assert(type(platform) == "number", "Provide 'platform' as 'number' was ".. type(platform))

    local routeName = route.routeName
    platform = tostring(platform)

    self.routes = self.routes or {}
    self.routes[routeName] = self.routes[routeName] or {}
    self.routes[routeName].platform = platform
end

function RoadStation:updateDisplays()
    for platform, displays in pairs(self.displays) do
        if RoadStation.debug then print("[RoadStation] update display for platform " .. platform) end
        local entries = self.queue:getTrainEntries(platform ~= "ALL" and platform or nil)
        for _, display in ipairs(displays) do
            if RoadStation.debug then
                print("[RoadStation] update display for platform " .. display.structure
                    .. " with " .. #entries .. " entries")
            end
            display.model.displayEntries(display.structure, entries, self.name, platform)
        end
    end
end

function RoadStation:addDisplay(structure, model, platform)
    platform = platform and tostring(platform) or "1"
    assert(structure)
    assert(model)
    platform = platform and tostring(platform) or nil
    self.displays[platform or "ALL"] = self.displays[platform or "ALL"] or {}
    table.insert(self.displays[platform or "ALL"], {structure = structure, model = model})
    model.initStation(structure, self.name, platform)
end

--- Creates a new Bus or Tram Station
---@param name string @Name der Fahrspur einer Kreuzung
---@param eepSaveId number, @EEPSaveSlot-Id fuer das Speichern der Fahrspur
---@return RoadStation
function RoadStation:new(name, eepSaveId)
    assert(name, 'Bitte geben Sie den Namen "name" fuer diese Fahrspur an.')
    assert(type(name) == "string", "Name ist kein String")
    assert(eepSaveId, 'Bitte geben Sie den Wert "eepSaveId" fuer diese Fahrspur an.')
    assert(type(eepSaveId) == "number")
    if eepSaveId ~= -1 then
        StorageUtility.registerId(eepSaveId, "Lane " .. name)
    end
    local o = {
        type = "RoadStation",
        name = name,
        eepSaveId = eepSaveId,
        queue = StationQueue:new(),
        displays = {}
    }

    self.__index = self
    setmetatable(o, self)
    load(o)
    save(o)
    allStations[name] = o
    return o
end

function RoadStation.stationByName(stationName)
    return allStations[stationName]
end

return RoadStation
