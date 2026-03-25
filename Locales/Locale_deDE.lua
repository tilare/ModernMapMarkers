--- Locale_deDE.lua - German Localization for ModernMapMarkers

ModernMapMarkers_Locale:RegisterMarkers("deDE", {
    ["Kalimdor"]            = "Kalimdor",
    ["Eastern Kingdoms"]    = "Östliche Königreiche",
    -- Dungeon masks
    -- %s will get substituted with the localized Dungeon name
    ["%s - East"]           = "%s - Ost", -- Dire Maul
    ["%s - West"]           = "%s - West", -- Dire Maul
    ["%s - North"]          = "%s - Nord", -- Dire Maul
    ["%s - Back Entrance"]  = "%s - Hintereingang", -- Stormwrought Ruins, Uldaman
    ["Lower %s"]            = "Untere %s", -- Lower Blackrock Spire
    ["Upper %s"]            = "Obere %s", -- Upper Blackrock Spire
    ["%s - Armory"]         = "%s - Waffenkammer", -- Scarlet Monastery
    ["%s - Cathedral"]      = "%s - Kathedrale", -- Scarlet Monastery
    ["%s - Graveyard"]      = "%s - Friedhof", -- Scarlet Monastery
    ["%s - Library"]        = "%s - Bibliothek", -- Scarlet Monastery
    ["%s - Back Gate"]      = "%s - Hintertor", -- Stratholme
    ["%s - Horde Entrance"] = "%s - Horde-Eingang", -- Stormwind Vault
    ["%s - Main Entrance"]  = "%s - Haupteingang", -- Uldaman

    -- Transport masks
    -- %s will get substituted with the destination's localized name
    ["Boat to %s"]      = "Schiff nach %s",
    ["Zeppelin to %s"]  = "Zeppelin nach %s",
    ["Tram to %s"]      = "Tiefenbahn nach %s",
    -- translations that need manual adjustment
    ["Boat to Menethil Harbor"]        = "Schiff zum Hafen von Menethil",
    ["Boat to Theramore Isle"]         = "Schiff zur Insel Theramore",
    ["Boat to Sparkwater Port"]        = "Schiff zum Funkelwasserhafen",
    ["Boat to The Forgotten Coast"]    = "Schiff zur Vergessenen Küste",
    ["Boat to Sardor-Island"]          = "Schiff zur Insel Sardor",
    ["Zeppelin to Grom'gol Base Camp"] = "Zeppelin zum Basislager von Grom'gol",

    -- Tooltip labels
    ["Level"]    = "Stufe",
    ["Alliance"] = "Allianz",
    ["Horde"]    = "Horde",
    ["Neutral"]  = "Neutral",

    -- UI labels
    ["All Markers"]        = "Alle Markierungen",
    ["Dungeons"]           = "Dungeons",
    ["Raids"]              = "Schlachtzüge",
    ["World Bosses"]       = "Weltbosse",
    ["Transports"]         = "Transporte",
    ["Boats"]              = "Schiffe",
    ["Zeppelins"]          = "Zeppeline",
    ["Trams"]              = "Bahnen",
    ["Transport Faction"]  = "Transportfraktion",
    ["Show All"]           = "Alle zeigen",
    ["Filter Markers"]     = "Markierungen filtern",
    ["Find Marker"]        = "Markierung finden",

    -- InstanceJournal tooltips
    ["Left-Click: View Map"] = "Linksklick: Karte anzeigen",
    ["Right-Click: Instance Journal"] = "Rechtsklick: Instanz-Journal",

    -- Chat messages
    ["Dropdown menus hidden."] = "Dropdown-Menüs ausgeblendet.",
    ["Dropdown menus shown."] = "Dropdown-Menüs eingeblendet.",
})
