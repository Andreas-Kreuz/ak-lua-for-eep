print"Lade ak.data.StructurePublisher ..."
StructurePublisher = {}
local AkStatistik = require("ak.io.AkStatistik")
local enabled = true
local initialized = false
StructurePublisher.name = "ak.data.StructurePublisher"

local MAX_STRUCTURES = 50000
local structures = {}

EEPStructureGetPosition = EEPStructureGetPosition or function()
        return
    end -- EEP 14.2
EEPStructureGetModelType = EEPStructureGetModelType or function()
        return
    end -- EEP 14.2
EEPStructureGetTagText = EEPStructureGetTagText or function()
        return
    end -- EEP 14.2

function StructurePublisher.initialize()
    if not enabled or initialized then
        return
    end

    for i = 0, MAX_STRUCTURES do
        local name = "#" .. tostring(i)

        local hasLight = EEPStructureGetLight(name) -- EEP 11.1 Plug-In 1
        local hasSmoke = EEPStructureGetSmoke(name) -- EEP 11.1 Plug-In 1
        local hasFire = EEPStructureGetFire(name) -- EEP 11.1 Plug-In 1

        if hasLight or hasSmoke or hasFire then
            local structure = {}
            structure.name = name

            local _, pos_x, pos_y, pos_z = EEPStructureGetPosition(name)
            local _, modelType = EEPStructureGetModelType(name)
            -- local EEPStructureModelTypeText = {
            --     -- not used yet
            --     ["16"] = "Gleis/Gleisobjekt",
            --     ["17"] = "Schiene/Gleisobjekt",
            --     ["18"] = "Straße/Gleisobjekt",
            --     ["19"] = "Sonstiges/Gleisobjekt",
            --     ["22"] = "Immobilie",
            --     ["23"] = "Landschaftselement/Fauna",
            --     ["24"] = "Landschaftselement/Flora",
            --     ["25"] = "Landschaftselement/Terra",
            --     ["38"] = "Landschaftselement/Instancing"
            -- }
            local _, tag = EEPStructureGetTagText(name)

            structure.pos_x = pos_x or 0 --string.format("%.2f", pos_x)
            structure.pos_y = pos_y or 0 --string.format("%.2f", pos_y)
            structure.pos_z = pos_z or 0 --string.format("%.2f", pos_z)
            structure.modelType = modelType or 0
            structure.tag = tag or ""
            table.insert(structures, structure)
        end
    end

    initialized = true
end

function StructurePublisher.updateData()
    if not enabled then
        return
    end

    if not initialized then
        StructurePublisher.initialize()
    end

    for i = 1, #structures do
        local structure = structures[i]

        local _, light = EEPStructureGetLight(structure.name) -- EEP 11.1 Plug-In 1
        local _, smoke = EEPStructureGetSmoke(structure.name) -- EEP 11.1 Plug-In 1
        local _, fire = EEPStructureGetFire(structure.name) -- EEP 11.1 Plug-In 1

        structure.light = light
        structure.smoke = smoke
        structure.fire = fire
    end

    AkStatistik.writeLater("structures", structures)
end

return StructurePublisher
