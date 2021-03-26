if AkDebugLoad then print("Loading ak.data.TrainsAndTracksJsonCollector ...") end
local ServerController = require("ak.io.ServerController")

TrainsAndTracksJsonCollector = {}
local TrackCollector = require("ak.data.TrackCollector")

local enabled = true
local initialized = false
TrainsAndTracksJsonCollector.name = "ak.data.TrainsAndTracksJsonCollector"

local data = {}

-- Identitfy track types for which data should get collected
local trackTypesAll = {"auxiliary", "control", "road", "rail", "tram"}
local trackTypes = {}
local activeEntries = ServerController.activeEntries
if not activeEntries or next(activeEntries) == nil then -- empty list
	-- All track types
	trackTypes = trackTypesAll
else	
	-- Selected track types
	for _, trackType in ipairs(trackTypesAll) do
		for key, value in pairs(activeEntries) do
			if value then
				if string.find(key, trackType) then
					table.insert(trackTypes, trackType)
					break
				end
			end
		end
	end
end

local trackCollectors = {}
do
    for _, trackType in ipairs(trackTypes) do
        trackCollectors[trackType] = TrackCollector:new(trackType)
    end
end

local function initializeTracks()
    for _, trackType in ipairs(trackTypes) do
        trackCollectors[trackType]:initialize()
    end
end

local function updateTracks()
    for _, trackType in ipairs(trackTypes) do
        local trainCollectorData = trackCollectors[trackType]:updateData()
        for key, value in pairs(trainCollectorData) do
            local newList = {}
            for _, o in pairs(value) do
                table.insert(newList, o)
            end
            data[key] = newList
        end
    end
end

function TrainsAndTracksJsonCollector.initialize()
    if not enabled or initialized then
        return
    end

    initializeTracks()

    initialized = true
end

function TrainsAndTracksJsonCollector.collectData()
    if not enabled then
        return
    end

    -- reset runtime data
    data["runtime"] = {}

    if not initialized then
        TrainsAndTracksJsonCollector.initialize()
    end

    updateTracks()

    return data
end

return TrainsAndTracksJsonCollector
