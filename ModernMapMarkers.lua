local MMM = CreateFrame("Frame", "ModernMapMarkersCore", UIParent)
MMM.markers = {}
MMM.Data = {}
MMM.ZoneMarkers = {}
MMM.FlatDropdownData = nil

-- Filter constants
local ALL_TYPES = { "DUNGEON", "RAID", "WORLDBOSS", "BOAT", "ZEPPELIN", "TRAM" }

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
                    atlasID     = m.atlas,
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
        if data.type == "DUNGEON" or data.type == "RAID" then
            local baseName = data.name or ""

            -- Clean suffix
            local dashIndex = string.find(baseName, " %- ")
            if dashIndex then
                baseName = string.sub(baseName, 1, dashIndex - 1)
            end

            local existingIndex = seenNames[baseName]
            if not existingIndex then
                -- Add new
                local dropData = {}
                for k, v in pairs(data) do dropData[k] = v end
                dropData.name = baseName
                table.insert(filteredData, dropData)
                seenNames[baseName] = table.getn(filteredData)
            else
                -- Override with canonical zone if needed
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
    for _, marker in ipairs(self.markers) do marker:Hide() end
    if not WorldMapFrame:IsVisible() then return end

    self:BuildData()

    local currentContinent = GetCurrentMapContinent()
    local currentZone      = GetCurrentMapZone()

    if currentContinent == 0 or currentZone == 0 then return end

    local zoneNames      = ZONE_CACHE[currentContinent]
    local currentZoneName = zoneNames and zoneNames[currentZone]
    if not currentZoneName then return end

    local zoneMarkers = MMM.ZoneMarkers[currentContinent] and MMM.ZoneMarkers[currentContinent][currentZoneName]

    if zoneMarkers then
        local markerIndex = 1
        for _, data in ipairs(zoneMarkers) do
            
            local showMarker = (MMM.filters[data.type] == true)

            -- Check faction filter
            if showMarker and (data.type == "BOAT" or data.type == "ZEPPELIN" or data.type == "TRAM") then
                if MMM.filters.FACTION ~= "ALL"
                   and data.description ~= "Neutral"
                   and data.description ~= MMM.filters.FACTION then
                    showMarker = false
                end
            end

            if showMarker then
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

                -- Metadata
                marker.name        = data.name
                marker.description = data.description
                marker.markerType  = data.type
                marker.atlasID     = data.atlasID
                marker.continent   = data.continent
                marker.zoneName    = data.zoneName

                marker:Show()
                markerIndex = markerIndex + 1
            end
        end
    end
end

-- AtlasTW Integration
function MMM:OnMarkerClick(marker)
    if marker.atlasID then
        if AtlasTW and AtlasTWOptions then
            -- Map Addon Continent (1=Kal, 2=EK) to Atlas ID (1=EK, 2=Kal)
            if marker.continent == 1 then
                AtlasTWOptions.AtlasType = 2
            else
                AtlasTWOptions.AtlasType = 1
            end

            AtlasTWOptions.AtlasZone = marker.atlasID

            if AtlasTWFrame and not AtlasTWFrame:IsVisible() then
                AtlasTW.ToggleAtlas()
            else
                AtlasTW.Refresh()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7fModernMapMarkers:|r Atlas-TW is not installed or enabled.")
        end
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

        marker:SetScript("OnClick", function() MMM:OnMarkerClick(this) end)

        marker:SetScript("OnEnter", function()
            WorldMapTooltip:SetOwner(this, "ANCHOR_RIGHT")
            WorldMapTooltip:AddLine(this.name, 1, 0.82, 0)

            if this.description then
                if this.markerType == "DUNGEON" or this.markerType == "RAID" or this.markerType == "WORLDBOSS" then
                    WorldMapTooltip:AddLine("Level: " .. this.description, 1, 1, 1, 1)
                elseif this.description == "Alliance" then
                    WorldMapTooltip:AddLine(this.description, 0.0, 0.47, 1.0, 1)
                elseif this.description == "Horde" then
                    WorldMapTooltip:AddLine(this.description, 1.0, 0.0, 0.0, 1)
                else
                    WorldMapTooltip:AddLine(this.description, 1, 1, 1, 1)
                end
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
    MMM:RefreshMarkers()
end

function ModernMapMarkers_SetFactionFilter(factionStr)
    MMM.filters.FACTION = factionStr
    MMM:RefreshMarkers()
end

function MMM:GetZoneIndex(continentID, zoneName)
    local zones = ZONE_CACHE[continentID] or {}
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
        end

        MMM:CacheZones()
        MMM:BuildData()
        MMM:RefreshMarkers()

    elseif event == "PLAYER_LOGOUT" then
        ModernMapMarkersDB = { filters = {} }
        for k, v in pairs(MMM.filters) do
            ModernMapMarkersDB.filters[k] = v
        end
    end
end)
MMM:RegisterEvent("VARIABLES_LOADED")
MMM:RegisterEvent("PLAYER_LOGOUT")
