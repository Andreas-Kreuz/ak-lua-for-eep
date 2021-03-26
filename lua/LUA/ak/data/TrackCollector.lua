if AkDebugLoad then print("Loading ak.data.TrackCollector ...") end
local TrackCollector = {}
local os = require("os")

local ServerController = require("ak.io.ServerController")
local debug = ServerController.debug

function tableLength(t) local i = 0 for _ in pairs(t) do i = i + 1 end return i end

local MAX_TRACKS = 50000

local registerFunction = {
    auxiliary = EEPRegisterAuxiliaryTrack,
    control = EEPRegisterControlTrack,
    road = EEPRegisterRoadTrack,
    rail = EEPRegisterRailTrack,
    tram = EEPRegisterTramTrack
}
local reservedFunction = {
    auxiliary = EEPIsAuxiliaryTrackReserved,
    control = EEPIsControlTrackReserved,
    road = EEPIsRoadTrackReserved,
    rail = EEPIsRailTrackReserved,
    tram = EEPIsTramTrackReserved
}
local EEPRollingstockModelTypeText = {
    [1] = "Tenderlok",
    [2] = "Schlepptenderlok",
    [3] = "Tender",
    [4] = "Elektrolok",
    [5] = "Diesellok",
    [6] = "Triebwagen",
    [7] = "U- oder S-Bahn",
    [8] = "Straßenbahn", -- German Umlaute are ok if stored as UTF-8
    [9] = "Güterwaggon", -- German Umlaute are ok if stored as UTF-8
    [10] = "Personenwaggon",
    [11] = "Luftfahrzeug",
    [12] = "Maschine",
    [13] = "Wasserfahrzeug",
    [14] = "LKW",
    [15] = "PKW"
}

local runtimeData = {}

--- Store runtime information
-- @author Frank Buchholz
function storeRunTime(group, time)
    -- collect and sum runtime date, needs rework
    if not runtimeData then
        runtimeData = {}
    end
    if not runtimeData[group] then
        runtimeData[group] = {
            id = group,
            count = 0,
            time = 0
        }
    end
    local runtime = runtimeData[group]
    runtime.count = runtime.count + 1
    runtime.time = runtime.time + time
end

--- Indirect call of EEP function (or any other function) including time measurement
-- @author Frank Buchholz
function executeAndStoreRunTime(func, group, ...)
    if not func then
        return
    end

    local t0 = os.clock()

    local result = {func(...)}

    local t1 = os.clock()
    storeRunTime(group, t1 - t0)

    return table.unpack(result)
end

--- Create dummy functions for EEP functions which are not yet available depending of the version of EEP
-- -- The minimal required version is EEP 11.3 Plug-In 3 which supports some quite important functions
-- local EEPGetSignalTrainsCount = EEPGetSignalTrainsCount or function()
--         return
--     end -- EEP 13.2

-- local EEPGetSignalTrainName = EEPGetSignalTrainName or function()
--         return
--     end -- EEP 13.2

-- Based on this concept we can redefine the functions, e.g. to collect some statistics data
--EEPGetRollingstockItemsCount = EEPGetRollingstockItemsCount  or function () return end -- EEP 13.2 Plug-In 2
local _EEPGetRollingstockItemsCount = EEPGetRollingstockItemsCount
local function EEPGetRollingstockItemsCount(...)
    return executeAndStoreRunTime(_EEPGetRollingstockItemsCount, "EEPGetRollingstockItemsCount", ...)
end

-- Ermittelt die Gesamtlänge des angegebenen Zuges.
local EEPGetTrainLength = EEPGetTrainLength or function()
        return
    end -- EEP 15.1 Plug-In 1

-- Ermittelt, welches Fahrzeug derzeit im Steuerdialog ausgewählt ist.
local EEPRollingstockGetActive = EEPRollingstockGetActive or function() -- (not used yet)
        return
    end -- EEP 15.1 Plug-In 1

-- Ermittelt, welcher Zug derzeit im Steuerdialog ausgewählt ist.
local EEPGetTrainActive = EEPGetTrainActive or function() -- (not used yet)
        return
    end -- EEP 15.1 Plug-In 1

-- Ermittelt, welche relative Ausrichtung das angegebene Fahrzeug im Zugverband hat.
local EEPRollingstockGetOrientation = EEPRollingstockGetOrientation or function() -- (not used yet)
        return
    end -- EEP 15.1 Plug-In 1

local EEPRollingstockGetLength = EEPRollingstockGetLength or function()
        return
    end -- EEP 14.2

local EEPRollingstockGetMotor = EEPRollingstockGetMotor or function()
        return
    end -- EEP 14.2

local EEPRollingstockGetTrack = EEPRollingstockGetTrack or function()
        return
    end -- EEP 14.2

local EEPRollingstockGetModelType = EEPRollingstockGetModelType or function()
        return
    end -- EEP 14.2

local EEPRollingstockGetTagText = EEPRollingstockGetTagText or function()
        return
    end -- EEP 14.2


--- Ermittelt die Position des Rollmaterials im EEP-Koordinatensystem in Meter (m).
--  OK, PosX, PosY, PosZ = EEPRollingstockGetPosition("#Fahrzeug")
local EEPRollingstockGetPosition = EEPRollingstockGetPosition or function()
        return
    end -- EEP 16.1

--- Ermittelt, ob der Haken eines bestimmten Rollmaterials an oder ausgeschaltet ist.
-- OK, Status = EEPRollingstockGetHook("#Kranwagen")
-- Haken aus = 0, an = 1, in Betrieb = 3
local EEPRollingstockGetHook = EEPRollingstockGetHook or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt das Verhalten von Gütern am Kranhaken eines Rollmaterials
--  OK, Status = EEPRollingstockGetHookGlue("#Kranwagen")
-- Güterhaken aus = 0, an = 1, in Benutzung = 3
local EEPRollingstockGetHookGlue = EEPRollingstockGetHookGlue or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt die zurückgelegte Strecke des Rollmaterials in Meter (m)
--  OK, Mileage = EEPRollingstockGetMileage("#Fahrzeug")
local EEPRollingstockGetMileage = EEPRollingstockGetMileage or function()
        return
    end -- EEP 16.1

--- Ermittelt, ob der Rauch des benannten Rollmaterials, an- oder ausgeschaltet ist.
-- OK, Status = EEPRollingstockGetSmoke("#Fahrzeug")
-- aus = 0, angeschaltet = 1
local EEPRollingstockGetSmoke = EEPRollingstockGetSmoke or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt die Ausrichtung des Ladegutes in Grad (Â°)
-- OK, RotX, RotY, RotZ = EEPGoodsGetRotation("#Container")
local EEPGoodsGetRotation = EEPGoodsGetRotation or function() -- (not used yet)
        return
    end -- EEP 16.1

-- To be used in another modules:

--- Ermittelt die aktuelle Position der Kamera
-- OK, PosX, PosY, PosZ = EEPGetCameraPosition()
local EEPGetCameraPosition = EEPGetCameraPosition or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt die aktuelle Ausrichtung einer Kamera.
-- OK, RotX, RotY, RotZ = EEPGetCameraRotation()
local EEPGetCameraRotation = EEPGetCameraRotation or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt die Windstärke in Prozent (%)
--  OK, WindIntensity = EEPGetWindIntensity()
local EEPGetWindIntensity = EEPGetWindIntensity or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt die Niederschlagintensität in Prozent (%)
--  OK, RainIntensity = EEPGetRainIntensity()
local EEPGetRainIntensity = EEPGetRainIntensity or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt die Schneeintensitä in Prozent (%)
--  OK, SnowIntensity = EEPGetSnowIntensity()
local EEPGetSnowIntensity = EEPGetSnowIntensity or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt die Hagelintensität in Prozent (%)
-- OK, HailIntensity = EEPGetHailIntensity()
local EEPGetHailIntensity = EEPGetHailIntensity or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt die Nebelintensität in Prozent (%)
-- OK, FogIntensity = EEPGetFogIntensity()
local EEPGetFogIntensity = EEPGetFogIntensity or function() -- (not used yet)
        return
    end -- EEP 16.1

--- Ermittelt der Wolkenanteil in Prozent (%)
-- OK, CloudIntensity = EEPGetCloudIntensity()
local EEPGetCloudIntensity = EEPGetCloudIntensity or function() -- (not used yet)
        return
    end -- EEP 16.1

-- Redefine functions from EEP 11.0 to collect run time data
local _EEPGetTrainSpeed = EEPGetTrainSpeed
local function EEPGetTrainSpeed(...)
    return executeAndStoreRunTime(_EEPGetTrainSpeed, "EEPGetTrainSpeed", ...)
end
local _EEPGetRollingstockItemName = EEPGetRollingstockItemName or function()
        return
    end -- EEP 13.2 Plug-In 2
local function EEPGetRollingstockItemName(...)
    return executeAndStoreRunTime(_EEPGetRollingstockItemName, "EEPGetRollingstockItemName", ...)
end

function TrackCollector:updateTrains()
    runtimeData = {}
    local t0 = os.clock()

    -- Remove missing trains, i.e. which have been removed by coupling events or by entering a train yard
    for trainName, train in pairs(self.trains) do
        local haveSpeed, speed = EEPGetTrainSpeed(trainName) -- EEP 11.0
        if haveSpeed then
            -- update speed of train
            train.speed = tonumber(string.format("%.4f", speed or 0))

            -- reset set of occupied tracks
            self.trainInfo[trainName].occupiedTacks = {}
        else
            if debug and self.trains[trainName] then
                print(string.format("TrackCollector %s - Remove train: %s (%d trains remaining)",
                    self.trackType, trainName, tableLength(self.trains) - 1 ))
            end
            self.trains[trainName] = nil
            self.trainInfo[trainName] = nil
        end
    end

    local t1 = os.clock()
    storeRunTime(self.trackType .. "-trainTime (remove)", t1 - t0)

    -- Update the trains, if they are dirty or not yet in the list
    local movedTrains = {}

    for _, track in pairs(self.tracks) do
        local trackId = track.id
        -- Limitation: only the first train on a track is found
        local _, occupied, trainName = self.reservedFunction(trackId, true)
        if occupied then
            if trainName then
                if (not self.trains[trainName] or self.dirtyTrainNames[trainName]) then
                    self:updateTrain(trainName)
                    movedTrains[trainName] = true
                    self.dirtyTrainNames[trainName] = nil
                else
                    if self.trains[trainName].onTrack ~= trackId then
                        movedTrains[trainName] = true
                    end
                end

                -- Update the trains
                self:updateTrainInfo(trainName, trackId)
            end
        end
    end

    -- Process remaining dirty trains (happens rarly)
    for trainName, onTrack in pairs(self.dirtyTrainNames) do
        if not self.trains[trainName] then
            local haveSpeed, speed = EEPGetTrainSpeed(trainName) -- EEP 11.0
            if haveSpeed then
                if debug then
                    print(string.format("*Process dirty train %s onTrack %s", trainName, onTrack))
                end
                self:updateTrain(trainName)
                self:updateTrainInfo(trainName, onTrack)
                movedTrains[trainName] = true
                self.dirtyTrainNames[trainName] = nil
            end
        end
    end

    local t2 = os.clock()
    storeRunTime(self.trackType .. "-trainTime", t2 - t1)

    -- Update the rollingstock, if they are dirty or not yet in the list
    for rollingStockName, rollingStock in pairs(self.rollingStock) do
        -- Remove all rollingstock without a train
        if not self.trains[rollingStock.trainName] then
            if debug and self.rollingStock[rollingStockName] then
                print(string.format("TrackCollector %s - Remove rolling stock: %s (%d rolling stocks in total)",
                    self.trackType, rollingStockName, tableLength(self.rollingStock) - 1 ))
            end
            self.rollingStock[rollingStockName] = nil
            self.rollingStockInfo[rollingStockName] = nil
        end

        if movedTrains[rollingStock.trainName] then
            self:updateRollingStockInfo(rollingStockName)
        end
    end

    if debug and tableLength(self.dirtyTrainNames) > 0 then
        print(string.format("TrackCollector %s - Clean %d dirty trains",
            self.trackType, tableLength(self.dirtyTrainNames) ))
    end
    self.dirtyTrainNames = {}

    local t3 = os.clock()
    storeRunTime(self.trackType .. "-rollingStockTime", t3 - t2)
    -- [[
    if debug then
        print(string.format(
            "TrackCollector %s took"
            .. "\n    %.2f s to remove old trains,"
            .. "\n    %.2f s to update trains"
            .. "\n    %.2f s to update rollingstock",
            self.trackType,
            t1 - t0,
            t2 - t1,
            t3 - t2
        ))
     end
     --]]
end

function TrackCollector:updateTrain(trainName)
    -- Store trains
    local haveRoute, route = EEPGetTrainRoute(trainName) -- EEP 11.2 Plugin 2

    local rollingStockCount = EEPGetRollingstockItemsCount(trainName) -- EEP 13.2 Plug-In 2
    local hasTrainLength, trainLength = EEPGetTrainLength(trainName) -- EEP 15.1 Plug-In 1

    local currentTrain = {
        id = trainName,
        route = haveRoute and route or "",
        rollingStockCount = rollingStockCount or 0,
        length = tonumber(string.format("%.2f", trainLength or 0)),
    }

    -- Save train
    if debug and not self.trains[trainName] then
        print(string.format("TrackCollector %s - Add train: %s (%d trains in total)",
            self.trackType, trainName, tableLength(self.trains) + 1 ))
    end
    self.trains[trainName] = currentTrain

    if rollingStockCount then
        for i = 0, (currentTrain.rollingStockCount - 1) do
            local rollingStockName = EEPGetRollingstockItemName(currentTrain.id, i) -- EEP 13.2 Plug-In 2
            local currentRollingStock = self:updateRollingStock(rollingStockName, currentTrain, i)
            if not hasTrainLength and trainLength then
                currentTrain.length = currentTrain.length + currentRollingStock
            end
        end
        currentTrain.length = tonumber(string.format("%.2f", currentTrain.length or 0))
    end
end

function TrackCollector:updateTrainInfo(trainName, trackId)
    local _, speed = EEPGetTrainSpeed(trainName) -- EEP 11.0
    local trainInfo = self.trainInfo[trainName] or {}

    -- update known trains
    trainInfo.id = trainName
    trainInfo.trackType = self.trackType
    trainInfo.speed = tonumber(string.format("%.4f", speed or 0))
    trainInfo.onTrack = trackId
    trainInfo.occupiedTacks = trainInfo.occupiedTacks or {}
    trainInfo.occupiedTacks[tostring(trackId)] = trackId

    -- add new trains
    if not self.trainInfo[trainName] then
        if debug then
            print(string.format("TrackCollector %s - Add trainInfo: %s",
                self.trackType, trainName))
        end
        self.trainInfo[trainName] = trainInfo
    end
end

function TrackCollector:updateRollingStock(rollingStockName, currentTrain, positionInTrain)
    -- 1 Kupplung scharf, 2 Abstoßen, 3 Gekuppelt
    local _, couplingFront = EEPRollingstockGetCouplingFront(rollingStockName) -- EEP 11.0
    local _, couplingRear = EEPRollingstockGetCouplingRear(rollingStockName) -- EEP 11.0

    local _, length = EEPRollingstockGetLength(rollingStockName) -- EEP 15
    local _, propelled = EEPRollingstockGetMotor(rollingStockName) -- EEP 14.2
    local _, modelType = EEPRollingstockGetModelType(rollingStockName) -- EEP 14.2
    local _, tag = EEPRollingstockGetTagText(rollingStockName) -- EEP 14.2

    local currentRollingStock = {
        name = rollingStockName,
        trainName = currentTrain.id,
        positionInTrain = positionInTrain,
        couplingFront = couplingFront,
        couplingRear = couplingRear,
        length = tonumber(string.format("%.2f", length or -1)),
        propelled = propelled or true,
        modelType = modelType or -1,
        modelTypeText = EEPRollingstockModelTypeText[modelType] or "",
        tag = tag or "",
    }

    -- Save rolling stock
    if debug and not self.rollingStock[rollingStockName] then
        print(string.format("TrackCollector %s - Add rolling stock: %s (%d rolling stocks in total)",
            self.trackType, rollingStockName, tableLength(self.rollingStock) + 1 ))
    end
    self.rollingStock[rollingStockName] = currentRollingStock

    return currentRollingStock
end

function TrackCollector:updateRollingStockInfo(rollingStockName)
    local _, trackId, trackDistance, trackDirection, trackSystem = EEPRollingstockGetTrack(rollingStockName)
    -- EEP 14.2
    local hasPos, PosX, PosY, PosZ = EEPRollingstockGetPosition(rollingStockName) -- EEP 16.1
    local hasMileage, mileage = EEPRollingstockGetMileage(rollingStockName) -- EEP 16.1

    local rollingStockInfo = {
        name = rollingStockName,
        trackId = trackId or -1,
        trackDistance = tonumber(string.format("%.2f", trackDistance or -1)),
        trackDirection = trackDirection or -1,
        trackSystem = trackSystem or -1,
        posX = hasPos and tonumber(PosX) or -1,
        posY = hasPos and tonumber(PosY) or -1,
        posZ = hasPos and tonumber(PosZ) or -1,
        mileage = hasMileage and tonumber(mileage) or -1,
    }
    self.rollingStockInfo[rollingStockName] = rollingStockInfo
end

function TrackCollector:initialize()
    for id = 1, MAX_TRACKS do
        local exists = self.registerFunction(id)
        if exists then
            local track = {}
            track.id = id
            --track.position = val
            self.tracks[tostring(track.id)] = track
        end
    end

    self:updateTrains()
end

function TrackCollector:update()
    self:updateTrains()
end

function TrackCollector:reactOnTrainChanges()
    --[[ (Re)define functions EEPOnTrainCoupling, EEPOnTrainLooseCoupling, and EEPOnTrainExitTrainyard
    to catch events from EEP which change the count and the names of trains.
    Limitation: there is no event on entering a train yard.

    As we have 5 trackTypes we end up with a chain of functions originating from 5 trackType instances.
    Therefore, any event gets called 5 times - once for every trackType.

    Caution: EEPMain gets called before EEPOnTrain-functions and testing if a track is occupied only retrieves
	one of the trains on that track.
    ->

    In case of a coupling event it happens that a train and its rolling stocks get deleted in one
    EEPMain call and then the rolling stocks get re-created in next EEPMain call.

    In case of a decoupling event it could happen
    a) that the new train is added before the event is processed (if EEPMain already picks up the new train) or
    b) added in one of the next EEPMain calls when one of the trains moves to another track (which could take a while).
    --]]

    -- Store original function
    local _EEPOnTrainCoupling = EEPOnTrainCoupling or function() -- EEP 14 Plug-In 1
        end
    -- React to train changes from EEP
    EEPOnTrainCoupling = function(trainA, trainB, trainNew)
        -- Mark these trains as dirty, i.e. refresh their data in next call of EEPMain

        -- Optional check: On this trackType we should find trainA and trainB (as well as trainNew which is either
		-- trainA or trainB) If this is not the case than this is not the correct trackType
        local checkA   = self.trains[trainA]   and true or false
        local checkB   = self.trains[trainB]   and true or false
        local checkNew = self.trains[trainNew] and true or false
        if not checkA and not checkB then
            -- Call the original function if none of the trains in known for this trackType
            return _EEPOnTrainCoupling(trainA, trainB, trainNew)
        end

        if debug then
            print("EEPOnTrainCoupling ", self.trackType,
                " trainA ",      trainA,   " ", ( checkA   and "ok" or 'missing' ), " ",
				self.trainInfo[trainA]   and self.trainInfo[trainA].onTrack   or -1,
                " trainB ",      trainB,   " ", ( checkB   and "ok" or 'missing' ), " ",
				self.trainInfo[trainB]   and self.trainInfo[trainB].onTrack   or -2,
                " -> trainNew ", trainNew, " ", ( checkNew and "ok" or 'new'     ), " ",
				self.trainInfo[trainNew] and self.trainInfo[trainNew].onTrack or -3
            )
        end

        local trackId =    self.trainInfo[trainA]   and self.trainInfo[trainA].onTrack
                        or self.trainInfo[trainB]   and self.trainInfo[trainB].onTrack
                        or self.trainInfo[trainNew] and self.trainInfo[trainNew].onTrack
                        or -1

        self.dirtyTrainNames[trainA]   = trackId
        self.dirtyTrainNames[trainB]   = trackId
        self.dirtyTrainNames[trainNew] = trackId

        -- Call the original function
        return _EEPOnTrainCoupling(trainA, trainB, trainNew)
    end


    -- Store original function
    local _EEPOnTrainLooseCoupling = EEPOnTrainLooseCoupling or function() -- EEP 14 Plug-In 1
        end
    -- React to train changes from EEP
    EEPOnTrainLooseCoupling = function(trainOld, trainA, trainB)
        -- Mark these trains as dirty, i.e. refresh their data

        -- Optional check: On this trackType we should find trainOld but not both trainA and trainB
        -- If this is not the case than this is not the correct trackType
        local checkOld = self.trains[trainOld] and true or false
        local checkA   = self.trains[trainA]   and true or false
        local checkB   = self.trains[trainB]   and true or false
        if not checkOld then
            -- Call the original function if the original trains in not known for this trackType
            return _EEPOnTrainLooseCoupling(trainOld, trainA, trainB)
        end

        if debug then
            print("EEPOnTrainLooseCoupling ", self.trackType,
                " trainOld ",   trainOld, " ", ( checkOld and "ok"   or 'missing' ), " ",
				self.trainInfo[trainOld] and self.trainInfo[trainOld].onTrack or -4,
                " ->  trainA ", trainA,   " ", ( checkA   and "keep" or 'new'     ), " ",
				self.trainInfo[trainA]   and self.trainInfo[trainA].onTrack   or -5,
                " trainB ",     trainB,   " ", ( checkB   and "keep" or 'new'     ), " ",
				self.trainInfo[trainB]   and self.trainInfo[trainB].onTrack   or -6
            )
        end

        local trackId =    self.trainInfo[trainOld] and self.trainInfo[trainOld].onTrack
                        or self.trainInfo[trainA]   and self.trainInfo[trainA].onTrack
                        or self.trainInfo[trainB]   and self.trainInfo[trainB].onTrack
                        or -1

        self.dirtyTrainNames[trainOld] = trackId
        self.dirtyTrainNames[trainA]   = trackId
        self.dirtyTrainNames[trainB]   = trackId

        -- Call the original function
        return _EEPOnTrainLooseCoupling(trainOld, trainA, trainB)
    end


    -- Store original function
    local _EEPOnTrainExitTrainyard = EEPOnTrainExitTrainyard or function() -- EEP 14 Plug-In 1
        end
    -- React to train changes from EEP
    EEPOnTrainExitTrainyard = function(depotId, trainName)
        -- Mark this train as dirty, i.e. refresh its data

        -- Optional check: On this trackType we should not find trainName
        -- If this is not the case than this is not the correct trackType
        local check    = self.trains[trainName] and true or false
        if check then
            -- Assertion failed
            print(string.format("EEPOnTrainExitTrainyard %s - Exit depot %s: Train %s alrady exists",
                self.trackType, depotId, trainName))
        end

        if debug then
            print("EEPOnTrainExitTrainyard ", self.trackType,
                " depotId ", depotId,
                " trainName ", trainName
            )
        end

        self.dirtyTrainNames[trainName] = true

        -- Call the original function
        return _EEPOnTrainExitTrainyard(depotId, trainName)
    end
end

function TrackCollector:updateData()
    self:updateTrains()
    return {
        [self.trackType .. "-tracks"] = self.tracks,
        [self.trackType .. "-trains"] = self.trains,
        [self.trackType .. "-train-infos-dynamic"] = self.trainInfo,
        [self.trackType .. "-rolling-stocks"] = self.rollingStock,
        [self.trackType .. "-rolling-stock-infos-dynamic"] = self.rollingStockInfo,
        [self.trackType .. "-runtime"] = runtimeData
    }
end

function TrackCollector:new(trackType)
    assert(trackType, 'Bitte geben Sie den Namen "trackType" an.')
    assert(registerFunction[trackType], "trackType must be one of 'auxiliary', 'control', 'road', 'rail', 'tram'")

    local o = {
        registerFunction = registerFunction[trackType],
        reservedFunction = reservedFunction[trackType],
        trackType = trackType,
        tracks = {},
        trains = {}, -- all currently known trains of this tracktype
        trainInfo = {},
        rollingStock = {},
        rollingStockInfo = {},
        dirtyTrainNames = {} -- all changes from outside will create an entry here
    }

    self.__index = self
    setmetatable(o, self)
    o:reactOnTrainChanges()
    return o
end

return TrackCollector
