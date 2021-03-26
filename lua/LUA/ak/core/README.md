---
layout: page_with_toc
title: Der Kern der App
subtitle: Dieser Teil enthält das Standardmodul
permalink: lua/ak/core/
feature-img: "/docs/assets/headers/SourceCode.png"
img: "/docs/assets/headers/SourceCode.png"
---

# Paket ak.core

- Dieses Paket enthält das Skript für das Einbinden und Starten der anderen Module.

Das Skript `ModuleRegistry` wird genutzt um die Module zu registrieren.
Die Einbindung von `ModuleRegistry.runTasks()` in `EEPMain()` sorgt dafür, dass die Tasks der Module ausgeführt werden.

## Verwendung

Hier ein minimales Beispiel (bei dem die Kreuzungssteuerung genutzt wird):

```lua
local ModuleRegistry = require("ak.core.ModuleRegistry")
ModuleRegistry.registerModules(
    -- require("ak.core.CoreLuaModule"), -- loaded automatically
    require("ak.road.CrossingLuaModul")
)

function EEPMain()
    ModuleRegistry.runTasks()
    return 1
end
```

## Verwendung von DataLuaModule / erweitertes Beispiel

Das Modul `DataLuaModule` kann, wie im vorigen Abschnitt beschrieben, aufgerufen werden.

Es bietet zusätzliche Optionen an, mit der die Auswahl den Daten-Kollektoren und die Auswahl der zu exportierenden Daten genau eingestellt werden kann.

Dazu dienen die zusätzlichen Funktionen `registerCollectors` und `setActiveEntries`, denen Listen der jeweils aktiven Objekten übergeben werden kann. Ohne diese Ausrufe, oder wenn eine leere Liste übergeben wird, werden alle Daten gesammelt und exportiert. Im Beispiel unten werden alle Optionen angegeben (kommentiert, so dass mit diesem Beispiel leere Listen genutzt werden.)

Mit der Funktion `setWaitForServer` kann festgelegt werden, ob die Dateien immer aktualiert werden sollen oder ob dies nur geschehen soll wenn der EEP-Webserver aktiv und empfangsbereit ist (default).

Die Funktion `runTasks()` besitzt einen zusätzlichen Parameter mit der angegeben werden kann nach wievielen Zyklen die Dateien aktualisiert werden sollen.

Die Standardfunktion `clearlog()` wird von dem Modul überladen. Damit wird dann nicht nur das Protokoll in EEP gelöscht sondern auch der Inhalt der exportierten Log-Datei.

```
clearlog() -- This call before loading EEP-Web clears the log within EEP but does not clear the log file of EEP Web

-- Load EEP Web Modules
local ModuleRegistry = require("ak.core.ModuleRegistry")
local modules = ModuleRegistry.registerModules(
    require("ak.core.CoreLuaModule"),
    require("ak.data.DataLuaModule")
)

-- Optional: Set options
modules["ak.core.CoreLuaModule"].setOptions({
    debug             = false,     -- Show additional debug information
    waitForServer     = false,     -- if false: Allow to update the json file without checking if the Web Server is ready
})

-- Optional: Set filter for data collector
modules["ak.core.CoreLuaModule"].setOptions({
    activeEntries = { -- Choose entries which get exported to file (default = empty list = all)
        -- You only need to provide these entries which you want to change
        -- Collector: common
        ["api-entries"]                             = false,

        -- Collector: "ak.data.TimeJsonCollector",
        ["times"]                                   = false,

        -- Collector: "ak.core.VersionJsonCollector",
        ["eep-version"]                             = false,

        -- Collector: "ak.data.TrainsAndTracksJsonCollector"
        ["rail-tracks"]                             = false,
        ["rail-trains"]                             = true,
        ["rail-train-infos-dynamic"]                = true,
        ["rail-rolling-stocks"]                     = true,
        ["rail-rolling-stock-infos-dynamic"]        = true,
        
        ["tram-tracks"]                             = false,
        ["tram-trains"]                             = true,
        ["tram-train-infos-dynamic"]                = true,
        ["tram-rolling-stocks"]                     = true,
        ["tram-rolling-stock-infos-dynamic"]        = true,

        ["road-tracks"]                             = false,
        ["road-trains"]                             = true,
        ["road-train-infos-dynamic"]                = true,
        ["road-rolling-stocks"]                     = true,
        ["road-rolling-stock-infos-dynamic"]        = true,

        ["auxiliary-tracks"]                        = false,
        ["auxiliary-trains"]                        = true,
        ["auxiliary-train-infos-dynamic"]           = true,
        ["auxiliary-rolling-stocks"]                = true,
        ["auxiliary-rolling-stock-infos-dynamic"]   = true,

        ["control-tracks"]                          = false,
        ["control-trains"]                          = false,
        ["control-train-infos-dynamic"]             = false,
        ["control-rolling-stocks"]                  = false,
        ["control-rolling-stock-infos-dynamic"]     = false,

        ["runtime"]                                 = true,

        -- Collector: "ak.data.SwitchJsonCollector"
        ["switches"]                                = false,

        -- Collector: "ak.data.SignalJsonCollector"
        ["signals"]                                 = false,
        ["waiting-on-signals"]                      = false,

        -- Collector: "ak.data.StructureJsonCollector"
        ["structures"]                              = false,

        -- Collector: "ak.data.DataSlotsJsonCollector"
        ["save-slots"]                              = false,
        ["free-slots"]                              = false,
    },
})

--clearlog() -- This call after loading EEP Web clears the log file, too

function EEPMain()
    ModuleRegistry.runTasks(1) -- 1: every 200 ms, 5: every second, ...
    return 1
end
```

## JSON Export beschleunigen

Optional kann für den JSON-Export eine für Windows gebaute Bibliothek (DLL) genutzt werden. Dafür wurde die Bibliothek
[lua-cjson2](https://luarocks.org/modules/criztianix/lua-cjson2) genutzt.
Der Export der JSON-Dateien wird dadurch stark beschleunigt.

```lua
-- ACHTUNG: DIE VERWENDUNG ERFOLGT AUF EIGENE GEFAHR. ES IST GUT MÖGLICH,
--          DASS EEP ABSTÜRZT, WENN NICHT ALLE ABHÄNGIGKEITEN DER BIBLIOTHEK
--          GEFUNDEN WERDEN.
ModuleRegistry.useDlls(true)
```

**ACHTUNG**: DIE VERWENDUNG ERFOLGT AUF EIGENE GEFAHR. ES IST GUT MÖGLICH, DASS EEP ABSTÜRZT,
WENN NICHT ALLE ABHÄNGIGKEITEN GEFUNDEN WERDEN.
