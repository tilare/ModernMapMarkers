kZoneNames = {GetMapZones(1)}
ekZoneNames = {GetMapZones(2)}

local markers = {}
local pinPool = {}
local debug = false

local config
local masterToggle
local dungeonRaidsToggle
local transportToggle
local worldBossToggle

local function print(string) 
    DEFAULT_CHAT_FRAME:AddMessage(string) 
end

-- Prevent the error `Interface\FrameXML\MoneyFrame.lua:185: attempt to perform arithmetic on local `money' (a nil value)`
-- Reference: https://github.com/veechs/Bagshui/blob/c70823167ae2581da7a777c073291805297cb0a2/Components/Bagshui.BlizzFixes.lua#L6
local oldMoneyFrame_UpdateMoney = MoneyFrame_UpdateMoney
function MoneyFrame_UpdateMoney()
    if this.moneyType == "STATIC" and this.staticMoney == nil then
        this.staticMoney = 0
    end
    oldMoneyFrame_UpdateMoney()
end

local function CreateMapPin(parent, x, y, size, texture, tooltipText, tooltipInfo, atlasID)
    if debug then
        print("Creating pin: " .. tooltipText)
    end
    
    local pin = tremove(pinPool)
    if not pin then
        pin = CreateFrame("Button", nil, parent)
        pin.texture = pin:CreateTexture(nil, "OVERLAY")
        pin.texture:SetAllPoints()
    end

    pin:SetParent(parent)
    pin:SetWidth(size)
    pin:SetHeight(size)
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", parent, "TOPLEFT", x, -y) 
    pin.texture:SetTexture(texture)
    pin:SetFrameLevel(parent:GetFrameLevel() + 3)
    pin:Show()

    local MapTooltip
    pin:SetScript("OnEnter", function()
        WorldMapTooltip:SetOwner(pin, "ANCHOR_BOTTOMRIGHT", -15, 15)
        WorldMapTooltip:SetText(tooltipText, 1, 1 ,1)
        if tooltipInfo == "Alliance" then
            WorldMapTooltip:AddLine(tooltipInfo, 0.145, 0.588, 0.745)
        elseif tooltipInfo == "Horde" then
            WorldMapTooltip:AddLine(tooltipInfo, 0.89, 0.161, 0.102)
        elseif tooltipInfo == "Neutral" then
            WorldMapTooltip:AddLine(tooltipInfo, 1, 1, 0)    
        elseif tooltipInfo ~= "" then 
            WorldMapTooltip:AddLine("Level: " .. tooltipInfo, 1,1,0)
        end
        WorldMapTooltip:Show()
    end)

    pin:SetScript("OnLeave", function()
        WorldMapTooltip:Hide()
    end)

    pin:SetScript("OnClick", function() 
        if texture == "Interface\\Addons\\ModernMapMarkers\\Textures\\worldboss.tga" then
            return
        end
        
        if atlasID ~= nil then
            -- Check if Atlas is present
            if AtlasFrame then
                -- Atlas uses opposite continent IDs to the client so we need to switch them!
                local currentContinent
                currentContinent = GetCurrentMapContinent()
                if currentContinent == 1 then
                    AtlasOptions.AtlasType = 2 -- 1 is EK, 2 is Kalimdor
                elseif currentContinent == 2 then
                    AtlasOptions.AtlasType = 1 -- 1 is EK, 2 is Kalimdor
                end
                
                AtlasOptions.AtlasZone = atlasID
                Atlas_Refresh();
                AtlasFrame:SetFrameStrata("FULLSCREEN")
                AtlasFrame:Show()
                if AtlasQuestFrame then
                    --Automatically opens the Atlas Quest popout for the zone
                    AtlasQuestFrame:Show()
                end
            end
        end
    end)
    return pin
end

local function UpdateMarkers()
    if not ModernMapMarkersDB.showMarkers then
        return
    end
    
    if not WorldMapFrame:IsVisible() then
        return
    end
    
    -- Make sure Atlas is installed
    if AtlasFrame and not Atlas_CheckAddonInstalled then
        if debug then
            print("Atlas is installed but missing required function Atlas_CheckAddonInstalled")
        end
    end

    if not ModernMapMarkers_Points then
        return
    end

    local currentContinent = GetCurrentMapContinent()
    local currentZone = GetCurrentMapZone()

    for _, pin in pairs(markers) do
        pin:Hide()
        tinsert(pinPool, pin)
    end
    markers = {}

    local worldMap = WorldMapDetailFrame
    local mapWidth, mapHeight = worldMap:GetWidth(), worldMap:GetHeight()

    for i, data in pairs(ModernMapMarkers_Points) do
        local isMatching = false
        local cont, zoneID, x, y, label, kind, info, atlasID = unpack(data)
        
        local shouldDisplay = true
        
        if kind == "dungeon" or kind == "raid" then
            shouldDisplay = ModernMapMarkersDB.showDungeonRaids
        elseif kind == "worldboss" then
            shouldDisplay = ModernMapMarkersDB.showWorldBosses
        elseif kind == "boat" or kind == "zepp" or kind == "tram" then
            shouldDisplay = ModernMapMarkersDB.showTransport
        end
        
        if shouldDisplay then
            if currentZone == zoneID and currentContinent == cont then
                isMatching = true
            end

            if isMatching then
                local size = 32
                local texture = "Interface\\Addons\\ModernMapMarkers\\Textures\\POIIcons.blp"
                
                if kind == "raid" then
                    texture = "Interface\\Addons\\ModernMapMarkers\\Textures\\raid.tga"
                elseif kind == "worldboss" then
                    texture = "Interface\\Addons\\ModernMapMarkers\\Textures\\worldboss.tga"
                elseif kind == "zepp" then
                    texture = "Interface\\Addons\\ModernMapMarkers\\Textures\\zepp.tga"
                    size = 24
                elseif kind == "boat" then
                    texture = "Interface\\Addons\\ModernMapMarkers\\Textures\\boat.tga"
                    size = 24
                elseif kind == "tram" then
                    texture = "Interface\\Addons\\ModernMapMarkers\\Textures\\tram.tga"
                    size = 24
                else -- Dungeon
                    texture = "Interface\\Addons\\ModernMapMarkers\\Textures\\dungeon.tga"
                end

                local px, py = x * mapWidth, y * mapHeight
                local pin = CreateMapPin(worldMap, px, py, size, texture, label, info, atlasID)        

                markers[i] = pin
            end
        end
    end
end

local function CreateToggleCheckbox(parent, x, y, text, optionKey)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)
    checkbox:SetWidth(24)
    checkbox:SetHeight(24)
    
    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(text)
    
    checkbox:SetScript("OnClick", function()
        local isChecked = checkbox:GetChecked()
        if isChecked then
            ModernMapMarkersDB[optionKey] = true
        else
            ModernMapMarkersDB[optionKey] = false
        end
        
        if debug then
            print("Checkbox " .. text .. " is now set to: " .. tostring(ModernMapMarkersDB[optionKey]))
        end
        UpdateMarkers()
    end)
    
    return checkbox
end

local function UpdateCheckboxStates()
    if masterToggle then
        masterToggle:SetChecked(ModernMapMarkersDB.showMarkers)
    end
    if dungeonRaidsToggle then
        dungeonRaidsToggle:SetChecked(ModernMapMarkersDB.showDungeonRaids)
    end
    if transportToggle then
        transportToggle:SetChecked(ModernMapMarkersDB.showTransport)
    end
    if worldBossToggle then
        worldBossToggle:SetChecked(ModernMapMarkersDB.showWorldBosses)
    end
end

local function CreateConfigUI()
    config = CreateFrame("Frame", "MMMConfigFrame", UIParent)
    config:SetWidth(320)
    config:SetHeight(220)
    config:SetPoint("CENTER", UIParent, "CENTER")
    
    tinsert(UISpecialFrames, "MMMConfigFrame")
    config:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {
            left = 11,
            right = 11,
            top = 11,
            bottom = 11
        }
    })
    config:SetMovable(true)
    config:EnableMouse(true)
    config:RegisterForDrag("LeftButton")
    config:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    config:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)
    
    local title = config:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Modern Map Markers")

    local masterLabel = config:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    masterLabel:SetPoint("TOPLEFT", 20, -45)
    masterLabel:SetText("Enable Map Markers:")

    masterToggle = CreateFrame("CheckButton", nil, config, "UICheckButtonTemplate")
    masterToggle:SetPoint("LEFT", masterLabel, "RIGHT", 5, 0)
    masterToggle:SetWidth(24)
    masterToggle:SetHeight(24)

    masterToggle:SetScript("OnClick", function()
        local isChecked = masterToggle:GetChecked()
        if isChecked then
            ModernMapMarkersDB.showMarkers = true
        else
            ModernMapMarkersDB.showMarkers = false
        end
        
        if ModernMapMarkersDB.showMarkers then
            if debug then
                print("Map Markers: Enabled")
            end
        else
            if debug then
                print("Map Markers: Disabled")
            end
            for _, pin in pairs(markers) do
                pin:Hide()
                tinsert(pinPool, pin)
            end
            markers = {}
        end
        
        UpdateMarkers()
    end)

    dungeonRaidsToggle = CreateToggleCheckbox(config, 20, -75, "Show Dungeons & Raids", "showDungeonRaids")
    transportToggle = CreateToggleCheckbox(config, 20, -100, "Show Transport (Boats, Zeppelins, Trams)", "showTransport")
    worldBossToggle = CreateToggleCheckbox(config, 20, -125, "Show World Bosses", "showWorldBosses")

    local closeButton = CreateFrame("Button", nil, config, "UIPanelButtonTemplate")
    closeButton:SetWidth(80)
    closeButton:SetHeight(25)
    closeButton:SetPoint("BOTTOM", 0, 15)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        config:Hide()
    end)

    config:Hide()
end

local function InitializeSavedVariables()
    if not ModernMapMarkersDB then
        ModernMapMarkersDB = {
            showMarkers = true,
            showDungeonRaids = true,
            showTransport = true,
            showWorldBosses = true
        }
        if debug then
            print("Modern Map Markers: Created new saved variables with defaults")
        end
    else
        if ModernMapMarkersDB.showMarkers == nil then
            ModernMapMarkersDB.showMarkers = true
        end
        if ModernMapMarkersDB.showDungeonRaids == nil then
            ModernMapMarkersDB.showDungeonRaids = true
        end
        if ModernMapMarkersDB.showTransport == nil then
            ModernMapMarkersDB.showTransport = true
        end
        if ModernMapMarkersDB.showWorldBosses == nil then
            ModernMapMarkersDB.showWorldBosses = true
        end
    end
    
    if debug then
        print("Saved Variables Loaded:")
        print("  showMarkers: " .. tostring(ModernMapMarkersDB.showMarkers))
        print("  showDungeonRaids: " .. tostring(ModernMapMarkersDB.showDungeonRaids))
        print("  showTransport: " .. tostring(ModernMapMarkersDB.showTransport))
        print("  showWorldBosses: " .. tostring(ModernMapMarkersDB.showWorldBosses))
    end
end

local initialized = false

local frame = CreateFrame("Frame")

frame:RegisterEvent("WORLD_MAP_UPDATE")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "ModernMapMarkers" then
        CreateConfigUI()
        if debug then
            print("Modern Map Markers: Addon Loaded, UI Created")
        end
    elseif event == "VARIABLES_LOADED" then
        if not initialized then
            InitializeSavedVariables()
            UpdateCheckboxStates()
            initialized = true
            
            if debug then
                print("Modern Map Markers: Variables Loaded and Initialized")
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not initialized then
            InitializeSavedVariables()
            if not config then
                CreateConfigUI()
            end
            UpdateCheckboxStates()
            initialized = true
        end
        UpdateMarkers()
    elseif event == "WORLD_MAP_UPDATE" then
        if initialized then
            UpdateMarkers()
        end
    end
end)

local function CreateToggleCheckbox(parent, x, y, text, optionKey)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)
    checkbox:SetWidth(24)
    checkbox:SetHeight(24)
    
    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(text)
    
    checkbox:SetScript("OnClick", function()
        local isChecked = checkbox:GetChecked()
        if isChecked then
            ModernMapMarkersDB[optionKey] = true
        else
            ModernMapMarkersDB[optionKey] = false
        end
        
        if debug then
            print("Checkbox " .. text .. " is now set to: " .. tostring(ModernMapMarkersDB[optionKey]))
        end
        UpdateMarkers()
    end)
    
    return checkbox
end

SLASH_MMM1 = "/mmm"
SlashCmdList["MMM"] = function()
    if MMMConfigFrame and MMMConfigFrame:IsVisible() then
        MMMConfigFrame:Hide()
    else
        MMMConfigFrame:Show()
    end
end

if debug then
    DEFAULT_CHAT_FRAME:AddMessage("Modern Map Markers: Initial Load Complete")
end
