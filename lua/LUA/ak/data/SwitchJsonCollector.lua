if AkDebugLoad then print("Loading ak.data.SwitchJsonCollector ...") end
SwitchJsonCollector = {}
local enabled = true
local initialized = false
SwitchJsonCollector.name = "ak.data.SwitchJsonCollector"

local MAX_SWITCHES = 1000
local switches = {}

function SwitchJsonCollector.initialize()
    if not enabled or initialized then
        return
    end

    for id = 1, MAX_SWITCHES do
        local val = EEPGetSwitch(id)
        if val > 0 then -- yes, this is a switch
            local switch = {}
            switch.id = id
            table.insert(switches, switch)
        end
    end

    initialized = true
end

function SwitchJsonCollector.collectData()
    if not enabled then
        return
    end

    if not initialized then
        SwitchJsonCollector.initialize()
    end

    for i = 1, #switches do
        local switch = switches[i]
        switch.position = EEPGetSwitch(switch.id)
    end

    return {["switches"] = switches}
end

return SwitchJsonCollector
