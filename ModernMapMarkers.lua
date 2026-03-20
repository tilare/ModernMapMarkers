local MMM = CreateFrame("Frame", "ModernMapMarkersCore", UIParent)
MMM.markers = {}
MMM.Data = {}
MMM.ZoneMarkers = {}
MMM.FlatDropdownData = nil
MMM.ijInstalled = false

-- Localization shorthand
local L = ModernMapMarkers_Locale

-- Filter constants
local ALL_TYPES = { "DUNGEON", "RAID", "WORLDBOSS", "BOAT", "ZEPPELIN", "TRAM" }

-- InstanceJournal Integration
-- MMM markers to hide when IJ is installed (covered by IJ POI entrances)
local IJ_HIDDEN_MARKERS = {
    ["Blackrock Depths"]               = true,
    ["Lower Blackrock Spire"]          = true,
    ["Upper Blackrock Spire"]          = true,
    ["Blackwing Lair"]                 = true,
    ["Molten Core"]                     = true,
    ["Dire Maul - East"]               = true,
    ["Dire Maul - North"]              = true,
    ["Dire Maul - West"]               = true,
    ["Black Morass"]                    = true,
    ["The Deadmines"]                   = true,
    ["Temple of Ahn'Qiraj"]            = true,
    ["Ruins of Ahn'Qiraj"]             = true,
    ["Gnomeregan"]                      = true,
    ["Maraudon"]                        = true,
    ["Scarlet Monastery - Armory"]      = true,
    ["Scarlet Monastery - Cathedral"]   = true,
    ["Scarlet Monastery - Graveyard"]   = true,
    ["Scarlet Monastery - Library"]     = true,
    ["Uldaman - Main Entrance"]         = true,
    ["Uldaman - Back Entrance"]         = true,
    ["Wailing Caverns"]                 = true,
    ["Windhorn Canyon"]                  = true,
    ["Timbermaw Hold"]                   = true,
}

-- Map MMM marker names to IJ database keys for click behavior
-- { db = "DG" or "R", key = IJDB key }
local MMM_TO_IJ = {
    -- Dungeons
    ["Blackfathom Deeps"]                   = { db = "DG", key = "BFD" },
    ["Crescent Grove"]                      = { db = "DG", key = "CG" },
    ["Ragefire Chasm"]                      = { db = "DG", key = "RFC" },
    ["Razorfen Downs"]                      = { db = "DG", key = "RFD" },
    ["Razorfen Kraul"]                      = { db = "DG", key = "RFK" },
    ["Zul'Farrak"]                          = { db = "DG", key = "ZF" },
    ["Shadowfang Keep"]                     = { db = "DG", key = "SFK" },
    ["The Stockade"]                        = { db = "DG", key = "STOCKADES" },
    ["Stormwind Vault"]                     = { db = "DG", key = "SV" },
    ["Stormwind Vault - Horde Entrance"]    = { db = "DG", key = "SV" },
    ["Stratholme"]                          = { db = "DG", key = "STRAT" },
    ["Stratholme - Back Gate"]              = { db = "DG", key = "STRAT" },
    ["Scholomance"]                         = { db = "DG", key = "SCHOLO" },
    ["The Sunken Temple"]                   = { db = "DG", key = "ST" },
    ["Hateforge Quarry"]                    = { db = "DG", key = "HQ" },
    ["Dragonmaw Retreat"]                   = { db = "DG", key = "DMR" },
    ["Karazhan Crypt"]                      = { db = "DG", key = "KC" },
    ["Lower Blackrock Spire"]              = { db = "DG", key = "LBRS" },
    ["Upper Blackrock Spire"]              = { db = "DG", key = "UBRS" },
    ["Gilneas City"]                        = { db = "DG", key = "GC" },
    ["Stormwrought Ruins"]                  = { db = "DG", key = "SWR" },
    ["Stormwrought Ruins - Back Entrance"]  = { db = "DG", key = "SWR" },
    ["Frostmane Hollow"]                    = { db = "DG", key = "FH" },
    ["Windhorn Canyon"]                     = { db = "DG", key = "WHC" },
    -- Raids
    ["Onyxia's Lair"]                       = { db = "R", key = "ONY" },
    ["Emerald Sanctum"]                     = { db = "R", key = "ES" },
    ["Lower Karazhan Halls"]                = { db = "R", key = "KARA10" },
    ["Blackwing Lair"]                      = { db = "R", key = "BWL" },
    ["Tower of Karazhan"]                   = { db = "R", key = "KARA40" },
    ["Naxxramas"]                           = { db = "R", key = "NAXX" },
    ["Zul'Gurub"]                           = { db = "R", key = "ZG" },
    ["Timbermaw Hold"]                      = { db = "R", key = "TH" },
}

-- Keep POI submap zone markers
local IJ_SUBMAP_ZONES = {}

-- Default filters
MMM.filters = {
    DUNGEON   = true,
    RAID      = true,
    BOAT      = true,
    ZEPPELIN  = true,
    TRAM      = true,
    WORLDBOSS = true,
    FACTION   = "ALL"
}

-- Dirty-check state for RefreshMarkers
local lastContinent = nil
local lastZone      = nil
local forceRefresh  = false

-- Textures
local TEX_BASE = "Interface\\AddOns\\ModernMapMarkers\\Textures\\"
local TEXTURE_MAP = {
    DUNGEON   = TEX_BASE .. "dungeon.tga",
    RAID      = TEX_BASE .. "raid.tga",
    BOAT      = TEX_BASE .. "boat.tga",
    ZEPPELIN  = TEX_BASE .. "zepp.tga",
    TRAM      = TEX_BASE .. "tram.tga",
    WORLDBOSS = TEX_BASE .. "worldboss.tga",
}
local HIGHLIGHT_MAP = {
    DUNGEON   = TEX_BASE .. "dungeon-highlight.tga",
    RAID      = TEX_BASE .. "raid-highlight.tga",
}

-- Zone name cache
local ZONE_CACHE = {}
function MMM:CacheZones()
    ZONE_CACHE[1] = { GetMapZones(1) } -- Kalimdor
    ZONE_CACHE[2] = { GetMapZones(2) } -- Eastern Kingdoms
end

-- Map multi-entrance dungeons to a single zone
local CANONICAL_ZONE = {
    ["Blackrock Depths"]      = "Burning Steppes",
    ["Lower Blackrock Spire"] = "Burning Steppes",
    ["Upper Blackrock Spire"] = "Burning Steppes",
    ["Blackwing Lair"]        = "Burning Steppes",
    ["Molten Core"]           = "Burning Steppes",
    ["Stormwind Vault"]       = "Stormwind City",
}

-- Data Parsing
function MMM:BuildData()
    if self.dataBuilt then return end
    if not ModernMapMarkers_Points then return end

    MMM.Data = {}
    MMM.ZoneMarkers = {}

    local index = 1

    for contID, zones in pairs(ModernMapMarkers_Points) do
        MMM.ZoneMarkers[contID] = MMM.ZoneMarkers[contID] or {}

        for zoneName, markers in pairs(zones) do
            MMM.ZoneMarkers[contID][zoneName] = {}

            for _, m in ipairs(markers) do
                local typeUpper = string.upper(m.type or "UNKNOWN")
                if typeUpper == "ZEPP" then typeUpper = "ZEPPELIN" end

                local markerData = {
                    continent   = contID,
                    zoneName    = zoneName,
                    x           = m.x,
                    y           = m.y,
                    name        = m.name,
                    type        = typeUpper,
                    description = m.info,
                    id          = index
                }

                table.insert(MMM.Data, markerData)
                table.insert(MMM.ZoneMarkers[contID][zoneName], markerData)

                index = index + 1
            end
        end
    end
    self.dataBuilt = true
end

-- Get deduplicated data for dropdowns
function ModernMapMarkers_GetFlatData()
    MMM:BuildData()

    if MMM.FlatDropdownData then return MMM.FlatDropdownData end

    local filteredData = {}
    local seenNames = {}

    for _, data in ipairs(MMM.Data) do
        if data.type == "DUNGEON" or data.type == "RAID" or data.type == "WORLDBOSS" then
            local baseName = data.name or ""

            local dashIndex = string.find(baseName, " %- ")
            if dashIndex then
                baseName = string.sub(baseName, 1, dashIndex - 1)
            end

            local existingIndex = seenNames[baseName]
            if not existingIndex then
                local dropData = {}
                for k, v in pairs(data) do dropData[k] = v end
                dropData.name = baseName
                table.insert(filteredData, dropData)
                seenNames[baseName] = table.getn(filteredData)
            else
                local canon = CANONICAL_ZONE[baseName]
                if canon and data.zoneName == canon then
                    local dropData = {}
                    for k, v in pairs(data) do dropData[k] = v end
                    dropData.name = baseName
                    filteredData[existingIndex] = dropData
                end
            end
        end
    end

    MMM.FlatDropdownData = filteredData
    return filteredData
end

-- Drawing Logic
function MMM:RefreshMarkers()
    if not WorldMapFrame:IsVisible() then return end

    self:BuildData()

    local currentContinent = GetCurrentMapContinent()
    local currentZone      = GetCurrentMapZone()

    -- Dirty-check: skip full redraw if zone hasn't changed and no force refresh
    if not forceRefresh
       and currentContinent == lastContinent
       and currentZone == lastZone then
        return
    end

    lastContinent = currentContinent
    lastZone      = currentZone
    forceRefresh  = false

    if currentContinent == 0 or currentZone == 0 then
        self:HideAllMarkers()
        return
    end

    local zoneNames      = ZONE_CACHE[currentContinent]
    local currentZoneName = zoneNames and zoneNames[currentZone]
    if not currentZoneName then
        self:HideAllMarkers()
        return
    end

    -- Translate localized zone name to English key used in MarkerData
    local englishZoneName = L:GetEnglishZoneName(currentZoneName)

    local zoneMarkers = MMM.ZoneMarkers[currentContinent] and MMM.ZoneMarkers[currentContinent][englishZoneName]

    local markerIndex = 0

    if zoneMarkers then
        for _, data in ipairs(zoneMarkers) do

            local showMarker = (MMM.filters[data.type] == true)

            -- Hide markers replaced by InstanceJournal
            if showMarker and MMM.ijInstalled then
                if data.type == "WORLDBOSS" then
                    showMarker = false
                elseif IJ_HIDDEN_MARKERS[data.name] then
                    showMarker = false
                end
            end

            -- Check faction filter
            if showMarker and (data.type == "BOAT" or data.type == "ZEPPELIN" or data.type == "TRAM") then
                if MMM.filters.FACTION ~= "ALL"
                   and data.description ~= "Neutral"
                   and data.description ~= MMM.filters.FACTION then
                    showMarker = false
                end
            end

            if showMarker then
                markerIndex = markerIndex + 1
                local marker = self:GetOrCreateMarker(markerIndex)

                -- Sizing
                if data.type == "DUNGEON" or data.type == "RAID" or data.type == "WORLDBOSS" then
                    marker:SetWidth(32)
                    marker:SetHeight(32)
                else
                    marker:SetWidth(24)
                    marker:SetHeight(24)
                end

                -- Position
                local width  = WorldMapDetailFrame:GetWidth()
                local height = WorldMapDetailFrame:GetHeight()
                marker:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", data.x * width, -data.y * height)

                -- Texture
                local tex = TEXTURE_MAP[data.type] or "Interface\\Minimap\\POIIcons"
                if marker.lastTexture ~= tex then
                    marker.texture:SetTexture(tex)
                    marker.lastTexture = tex
                end

                local hlTex = HIGHLIGHT_MAP[data.type]
                if marker.lastHighlight ~= hlTex then
                    if hlTex then
                        marker:SetHighlightTexture(hlTex)
                    elseif marker.lastHighlight then
                        marker:SetHighlightTexture("")
                    end
                    marker.lastHighlight = hlTex
                end

                -- Metadata
                marker.name        = L:GetLocalizedMarkerName(data.name)
                marker.nameEN      = data.name
                marker.description = data.description
                marker.markerType  = data.type
                marker.continent   = data.continent
                marker.zoneName    = data.zoneName

                marker:Show()
            end
        end
    end

    -- Hide any excess markers from the previous zone
    self:HideMarkersFrom(markerIndex + 1)
end

-- Hide all markers in the pool
function MMM:HideAllMarkers()
    self:HideMarkersFrom(1)
end

-- Hide markers from startIndex onwards
function MMM:HideMarkersFrom(startIndex)
    for i = startIndex, table.getn(self.markers) do
        if self.markers[i] then
            self.markers[i]:Hide()
        end
    end
end

-- Invalidate dirty-check so next RefreshMarkers does a full redraw
function MMM:InvalidateCache()
    forceRefresh = true
end

-- Get IJ instance from MMM marker English name
function MMM:GetIJInstance(nameEN)
    if not MMM.ijInstalled or not nameEN then return nil end
    local mapping = MMM_TO_IJ[nameEN]
    if not mapping then return nil end
    local dbTable = (mapping.db == "R") and IJDB.R or IJDB.DG
    if not dbTable then return nil end
    return dbTable[mapping.key]
end

-- InstanceJournal Integration
function MMM:OnMarkerClick(marker, button)
    if not MMM.ijInstalled then return end

    local instance = MMM:GetIJInstance(marker.nameEN)
    if not instance then return end

    if button == "RightButton" then
        -- Right-click: open IJ journal page
        if not IJ_InstanceJournalFrame:IsShown() then
            IJ_InstanceJournalFrame:Show()
        end
        if instance.Type == IJLib.InstanceType.Raid then
            IJ_ShowRaids = true
            PanelTemplates_SetTab(IJ_InstanceJournalFrame, 2)
        else
            IJ_ShowRaids = false
            PanelTemplates_SetTab(IJ_InstanceJournalFrame, 1)
        end
        IJ_ShowEncounter(instance)
        WorldMapFrame:Hide()
    else
        -- Left-click: navigate to instance submap
        SetMapZoom(tonumber(instance.MapId), 1)
    end
end

-- Marker Pool
function MMM:GetOrCreateMarker(index)
    if not self.markers[index] then
        local marker = CreateFrame("Button", "ModernMapMarkerIcon"..index, WorldMapButton)
        marker:SetWidth(24)
        marker:SetHeight(24)
        marker:SetFrameLevel(WorldMapButton:GetFrameLevel() + 5)

        local tex = marker:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints(marker)
        marker.texture = tex

        marker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        marker:SetScript("OnClick", function() MMM:OnMarkerClick(this, arg1) end)

        marker:SetScript("OnEnter", function()
            WorldMapTooltip:SetOwner(this, "ANCHOR_RIGHT")
            WorldMapTooltip:AddLine(this.name, 1, 0.82, 0)

            if this.description then
                if this.markerType == "DUNGEON" or this.markerType == "RAID" or this.markerType == "WORLDBOSS" then
                    local lvlLabel = L:GetLocalizedMarkerName("Level") or "Level"
                    WorldMapTooltip:AddLine(lvlLabel .. ": " .. this.description, 1, 1, 1, 1)
                elseif this.description == "Alliance" then
                    WorldMapTooltip:AddLine(L:GetLocalizedMarkerName("Alliance"), 0.0, 0.47, 1.0, 1)
                elseif this.description == "Horde" then
                    WorldMapTooltip:AddLine(L:GetLocalizedMarkerName("Horde"), 1.0, 0.0, 0.0, 1)
                else
                    WorldMapTooltip:AddLine(L:GetLocalizedMarkerName(this.description), 1, 1, 1, 1)
                end
            end

            -- IJ tooltips for dungeon/raid markers
            if MMM.ijInstalled and MMM:GetIJInstance(this.nameEN) then
                WorldMapTooltip:AddLine(L:GetLocalizedMarkerName("Left-Click: View Map"), 0.5, 0.5, 0.5)
                WorldMapTooltip:AddLine(L:GetLocalizedMarkerName("Right-Click: Instance Journal"), 0.5, 0.5, 0.5)
            end

            WorldMapTooltip:Show()
        end)

        marker:SetScript("OnLeave", function() WorldMapTooltip:Hide() end)

        self.markers[index] = marker
    end
    return self.markers[index]
end

-- Hooks & API
function ModernMapMarkers_SetFilter(key, state)
    if key == "ALL" then
        for _, t in ipairs(ALL_TYPES) do
            MMM.filters[t] = state
        end
    else
        MMM.filters[key] = state
    end
    MMM:InvalidateCache()
    MMM:RefreshMarkers()
end

function ModernMapMarkers_SetFactionFilter(factionStr)
    MMM.filters.FACTION = factionStr
    MMM:InvalidateCache()
    MMM:RefreshMarkers()
end

function MMM:GetZoneIndex(continentID, zoneName)
    local zones = ZONE_CACHE[continentID] or {}
    -- zoneName is English (from MarkerData), ZONE_CACHE has localized names
    local localizedName = L:GetLocalizedZoneName(zoneName)
    for i, name in ipairs(zones) do
        if name == localizedName then return i end
    end
    -- Fallback: try direct match (for enUS or untranslated zones)
    for i, name in ipairs(zones) do
        if name == zoneName then return i end
    end
    return 0
end

function ModernMapMarkers_FindMarker(dataIndex)
    MMM:BuildData()
    local data = MMM.Data[dataIndex]
    if not data then return end

    local zoneIndex = MMM:GetZoneIndex(data.continent, data.zoneName)
    if zoneIndex > 0 then
        SetMapZoom(data.continent, zoneIndex)
    end

    if not MMM.filters[data.type] then
        MMM.filters[data.type] = true
        if ModernMapMarkers_SyncFilterUI then
            ModernMapMarkers_SyncFilterUI(data.type, true)
        end
    end

    MMM:InvalidateCache()
    MMM:RefreshMarkers()
end

local original_WorldMapFrame_Update = WorldMapFrame_Update
function WorldMapFrame_Update()
    if original_WorldMapFrame_Update then
        original_WorldMapFrame_Update()
    end
    MMM:RefreshMarkers()
end

MMM:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if ModernMapMarkersDB and ModernMapMarkersDB.filters then
            for k, v in pairs(ModernMapMarkersDB.filters) do
                MMM.filters[k] = v
            end
        else
            -- First load: auto-detect player faction for transport filter
            local faction = UnitFactionGroup("player")
            if faction == "Alliance" or faction == "Horde" then
                MMM.filters.FACTION = faction
            end
        end

        L:Initialize()
        MMM:CacheZones()
        MMM:BuildData()

        -- Detect InstanceJournal
        if IJDB and IJLib and IJ_ShowInstanceEntrancesIcon then
            MMM.ijInstalled = true

            -- Build POI submap zone lookup
            if IJDB.POI then
                for _, poi in pairs(IJDB.POI) do
                    if poi.MapContinentId and poi.MapZoneId then
                        local key = tostring(poi.MapContinentId) .. ":" .. tostring(poi.MapZoneId)
                        IJ_SUBMAP_ZONES[key] = true
                    end
                end
            end

            -- Also include instance entrance locations inside other instance maps
            -- (e.g., Molten Core entrance inside BRD submap)
            local instanceMapIds = {}
            local allInstances = {}
            for _, inst in pairs(IJDB.DG or {}) do
                if inst.MapId then instanceMapIds[tostring(inst.MapId)] = true end
                table.insert(allInstances, inst)
            end
            for _, inst in pairs(IJDB.R or {}) do
                if inst.MapId then instanceMapIds[tostring(inst.MapId)] = true end
                table.insert(allInstances, inst)
            end
            for _, inst in ipairs(allInstances) do
                if inst.Entrances then
                    for _, ent in pairs(inst.Entrances) do
                        if ent.MapContinentId and ent.MapZoneId
                           and instanceMapIds[tostring(ent.MapContinentId)] then
                            local key = tostring(ent.MapContinentId) .. ":" .. tostring(ent.MapZoneId)
                            IJ_SUBMAP_ZONES[key] = true
                        end
                    end
                end
            end

            -- Hook IJ entrance markers: hide on world zones, keep in POI submaps
            -- In submaps, reskin entrance pins with MMM dungeon/raid textures
            local original_ShowEntrance = IJ_ShowInstanceEntrancesIcon
            IJ_ShowInstanceEntrancesIcon = function(instance)
                local key = tostring(GetCurrentMapContinent()) .. ":" .. tostring(GetCurrentMapZone())
                if IJ_SUBMAP_ZONES[key] then
                    original_ShowEntrance(instance)

                    -- Determine marker type and apply MMM filter
                    local isRaid = instance.Type == IJLib.InstanceType.Raid
                    local filterKey = isRaid and "RAID" or "DUNGEON"
                    local mmmTex = isRaid and TEXTURE_MAP.RAID or TEXTURE_MAP.DUNGEON

                    local cleanName = string.gsub(instance.Name or "", "%s+", "")
                    local prefix = "IJ_EntrancePin_" .. cleanName

                    for _, pin in ipairs(IJ_CreatedMapInstanceEntrance) do
                        local pinName = pin:GetName() or ""
                        if string.find(pinName, prefix, 1, true) and pin:IsVisible() then
                            -- Hide pin if MMM filter is disabled for this type
                            if not MMM.filters[filterKey] then
                                pin:Hide()
                            end
                            pin.icon:SetTexture(mmmTex)
                            pin.mmmInstance = instance

                            if not pin.mmmReskinned then
                                pin.mmmReskinned = true
                                pin.mmmTexture = mmmTex

                                local mmmHL = instance.Type == IJLib.InstanceType.Raid and HIGHLIGHT_MAP.RAID or HIGHLIGHT_MAP.DUNGEON
                                if mmmHL then
                                    pin:SetHighlightTexture(mmmHL)
                                end

                                local origOnEnter = pin:GetScript("OnEnter")
                                local origOnLeave = pin:GetScript("OnLeave")

                                pin:SetScript("OnEnter", function()
                                    if origOnEnter then origOnEnter() end
                                    this.icon:SetTexture(this.mmmTexture)

                                    -- MMM tooltip for IJ POI submap markers
                                    local inst = this.mmmInstance
                                    if inst then
                                        WorldMapTooltip:SetOwner(this, "ANCHOR_RIGHT")
                                        WorldMapTooltip:AddLine(inst.Name or "", 1, 0.82, 0)
                                        local minLvl = inst.MinLevel or 0
                                        local maxLvl = inst.MaxLevel or 0
                                        local lvlLabel = L:GetLocalizedMarkerName("Level") or "Level"
                                        WorldMapTooltip:AddLine(lvlLabel .. ": " .. minLvl .. "-" .. maxLvl, 1, 1, 1, 1)
                                        WorldMapTooltip:AddLine(L:GetLocalizedMarkerName("Left-Click: View Map"), 0.5, 0.5, 0.5)
                                        WorldMapTooltip:AddLine(L:GetLocalizedMarkerName("Right-Click: Instance Journal"), 0.5, 0.5, 0.5)
                                        WorldMapTooltip:Show()
                                    end
                                end)

                                pin:SetScript("OnLeave", function()
                                    if origOnLeave then origOnLeave() end
                                    this.icon:SetTexture(this.mmmTexture)
                                    WorldMapTooltip:Hide()
                                end)

                                -- Right click for IJ journal
                                pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                                local origOnClick = pin:GetScript("OnClick")
                                pin:SetScript("OnClick", function()
                                    if arg1 == "RightButton" and this.mmmInstance then
                                        local inst = this.mmmInstance
                                        if not IJ_InstanceJournalFrame:IsShown() then
                                            IJ_InstanceJournalFrame:Show()
                                        end
                                        if inst.Type == IJLib.InstanceType.Raid then
                                            IJ_ShowRaids = true
                                            PanelTemplates_SetTab(IJ_InstanceJournalFrame, 2)
                                        else
                                            IJ_ShowRaids = false
                                            PanelTemplates_SetTab(IJ_InstanceJournalFrame, 1)
                                        end
                                        IJ_ShowEncounter(inst)
                                        WorldMapFrame:Hide()
                                    else
                                        if origOnClick then origOnClick() end
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end

        MMM:InvalidateCache()
        MMM:RefreshMarkers()

    elseif event == "PLAYER_LOGOUT" then
        if not ModernMapMarkersDB then ModernMapMarkersDB = {} end
        ModernMapMarkersDB.filters = {}
        for k, v in pairs(MMM.filters) do
            ModernMapMarkersDB.filters[k] = v
        end
    end
end)
MMM:RegisterEvent("VARIABLES_LOADED")
MMM:RegisterEvent("PLAYER_LOGOUT")
