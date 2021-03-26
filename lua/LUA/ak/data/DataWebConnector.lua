if AkDebugLoad then print("Loading ak.data.DataWebConnector ...") end
local ServerController = require("ak.io.ServerController")

local DataWebConnector = {}

function DataWebConnector.registerJsonCollectors()
    local activeEntries = ServerController.activeEntries

    local all = true
    if activeEntries and next(activeEntries) ~= nil then -- not empty list
        all = false
    end

    if all or activeEntries["free-slots"]
           or activeEntries["save-slots"]
    then
        ServerController.addJsonCollector(require("ak.data.DataSlotsJsonCollector"))
    end

    if all or activeEntries["signals"]
           or activeEntries["waiting-on-signals"]
    then
        ServerController.addJsonCollector(require("ak.data.SignalJsonCollector"))
    end

    if all or activeEntries["switches"]
    then
        ServerController.addJsonCollector(require("ak.data.SwitchJsonCollector"))
    end

    if all or activeEntries["structures"]
    then
        ServerController.addJsonCollector(require("ak.data.StructureJsonCollector"))
    end

    if all or activeEntries["times"]
    then
        ServerController.addJsonCollector(require("ak.data.TimeJsonCollector"))
    end

    -- Tracks
    local addTrackCollector = false
    if not all then
        local trackTypes = {"rail", "tram", "road", "auxiliary", "control"}
        for key, value in pairs(activeEntries) do
            if value then
                for _, trackType in ipairs(trackTypes) do
                    if string.find(key, trackType) then
                        addTrackCollector = true
                        break
                    end
                end
                if addTrackCollector then
                    break
                end
            end
        end
    end
    if all or addTrackCollector then
        ServerController.addJsonCollector(require("ak.data.TrainsAndTracksJsonCollector"))
    end
end

return DataWebConnector
