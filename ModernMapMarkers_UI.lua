local MMM_GUI = {}
local isPfUI = IsAddOnLoaded("pfUI")
local L = ModernMapMarkers_Locale

function MMM_GUI.InitializeWorldMapControls()

    -- Filter Definitions
    local filterOptions = {
        { label = L:GetLocalizedMarkerName("All Markers"),  value = "ALL",       isCheck = true, checked = true  },
        { label = L:GetLocalizedMarkerName("Dungeons"),     value = "DUNGEON",   isCheck = true, checked = true  },
        { label = L:GetLocalizedMarkerName("Raids"),        value = "RAID",      isCheck = true, checked = true  },
        { label = L:GetLocalizedMarkerName("World Bosses"), value = "WORLDBOSS", isCheck = true, checked = true  },
        { label = L:GetLocalizedMarkerName("Transports"), isHeader = true },
        { label = "  " .. L:GetLocalizedMarkerName("Boats"),      value = "BOAT",      isCheck = true, checked = true  },
        { label = "  " .. L:GetLocalizedMarkerName("Zeppelins"),  value = "ZEPPELIN",  isCheck = true, checked = true  },
        { label = "  " .. L:GetLocalizedMarkerName("Trams"),      value = "TRAM",      isCheck = true, checked = true  },
        { label = L:GetLocalizedMarkerName("Transport Faction"), isHeader = true },
        { label = "  " .. L:GetLocalizedMarkerName("Show All"),   value = "ALL",       isCheck = true, checked = true,  isRadio = true, group = "fac" },
        { label = "  " .. L:GetLocalizedMarkerName("Alliance"),   value = "Alliance",  isCheck = true, checked = false, isRadio = true, group = "fac" },
        { label = "  " .. L:GetLocalizedMarkerName("Horde"),      value = "Horde",     isCheck = true, checked = false, isRadio = true, group = "fac" },
    }

    if ModernMapMarkersDB and ModernMapMarkersDB.filters then
        local saved = ModernMapMarkersDB.filters
        for _, item in ipairs(filterOptions) do
            if item.isCheck and item.value and item.value ~= "ALL" then
                if item.isRadio then
                    if saved.FACTION ~= nil then
                        item.checked = (saved.FACTION == item.value) or (item.value == "ALL" and saved.FACTION == "ALL")
                    end
                elseif saved[item.value] ~= nil then
                    item.checked = saved[item.value]
                end
            end
        end
        -- Auto-check "All Markers" if all individual filters are on
        local allOn = true
        for _, item in ipairs(filterOptions) do
            if item.isCheck and not item.isRadio and item.value ~= "ALL" then
                if not item.checked then allOn = false; break end
            end
        end
        filterOptions[1].checked = allOn
    end

    function ModernMapMarkers_SyncFilterUI(typeKey, state)
        for _, item in ipairs(filterOptions) do
            if item.isCheck and not item.isRadio and item.value == typeKey then
                item.checked = state
            end
        end
        local allOn = true
        for _, item in ipairs(filterOptions) do
            if item.isCheck and not item.isRadio and item.value ~= "ALL" then
                if not item.checked then allOn = false; break end
            end
        end
        filterOptions[1].checked = allOn
    end
    
    -- Determine Parent Frame (Standard or pfQuest)
    local dropdownParent = WorldMapFrame

    -- Dynamic dropdown width based on longest label
    local MIN_DROPDOWN_WIDTH = 120
    local PADDING = 35  -- space for checkbox/arrow/margins
    local longestLabel = 0

    -- Measure filter labels
    for _, item in ipairs(filterOptions) do
        local text = string.gsub(item.label, "^%s+", "")
        local len = string.len(text)
        if len > longestLabel then longestLabel = len end
    end

    -- Also measure button texts and find dropdown labels
    local buttonTexts = {
        L:GetLocalizedMarkerName("Filter Markers"),
        L:GetLocalizedMarkerName("Find Marker"),
        L:GetLocalizedZoneName("Kalimdor"),
        L:GetLocalizedZoneName("Eastern Kingdoms"),
        L:GetLocalizedMarkerName("Dungeons"),
        L:GetLocalizedMarkerName("Raids"),
    }
    for _, text in ipairs(buttonTexts) do
        local len = string.len(text)
        if len > longestLabel then longestLabel = len end
    end

    -- Approximate width: ~7px per character + padding, with minimum
    local dropdownWidth = math.max(MIN_DROPDOWN_WIDTH, longestLabel * 7 + PADDING)
    local dropdownButtonWidth = dropdownWidth + 5
    
    if _G.pfQuestMapDropdown then
        dropdownParent = _G.pfQuestMapDropdown:GetParent() or dropdownParent
    end

    -- Filter Dropdown
    local filterFrame = CreateFrame("Frame", "ModernMapMarkersFilter_Blizz", dropdownParent, "UIDropDownMenuTemplate")

    filterFrame:SetFrameStrata(dropdownParent:GetFrameStrata())
    filterFrame:SetFrameLevel(dropdownParent:GetFrameLevel() + 10)
    
    local filterBtn = getglobal(filterFrame:GetName().."Button")
    if filterBtn then filterBtn:SetFrameLevel(filterFrame:GetFrameLevel() + 2) end

    -- Positioning
    if _G.pfQuestMapDropdown then
        filterFrame:SetPoint("TOPRIGHT", _G.pfQuestMapDropdown, "BOTTOMRIGHT", 0, 0)
    else
        filterFrame:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -10, -40)
    end
    
    UIDropDownMenu_Initialize(filterFrame, function(level)
        for _, itemRaw in ipairs(filterOptions) do
            local item = itemRaw 

            if item.isHeader then
                local info = {}
                info.text = item.label
                info.isTitle = 1
                info.notCheckable = 1
                UIDropDownMenu_AddButton(info, level)
            else
                local info = {}
                info.text = string.gsub(item.label, "^%s+", "")
                info.value = item.value
                info.checked = item.checked
                info.keepShownOnClick = 1
                info.func = function()
                    if item.isRadio then
                        if item.checked then return end
                            for _, v in ipairs(filterOptions) do
                            if v.isRadio and v.group == item.group then v.checked = false end
                        end
                        item.checked = true
                        ModernMapMarkers_SetFactionFilter(item.value)
                    else
                        item.checked = not item.checked
                        if item.value == "ALL" then
                            for _, v in ipairs(filterOptions) do
                                if v.isCheck and not v.isRadio and v.value ~= "ALL" then
                                    v.checked = item.checked
                                end
                            end
                            ModernMapMarkers_SetFilter("ALL", item.checked)
                        else
                            ModernMapMarkers_SetFilter(item.value, item.checked)
                            local allOn = true
                            for _, v in ipairs(filterOptions) do
                                if v.isCheck and not v.isRadio and v.value ~= "ALL" then
                                    if not v.checked then allOn = false; break end
                                end
                            end
                            filterOptions[1].checked = allOn
                        end
                    end
                    ToggleDropDownMenu(1, nil, filterFrame) 
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)

    UIDropDownMenu_SetWidth(dropdownWidth, filterFrame)
    UIDropDownMenu_SetButtonWidth(dropdownButtonWidth, filterFrame)
    UIDropDownMenu_SetText(L:GetLocalizedMarkerName("Filter Markers"), filterFrame)
    UIDropDownMenu_JustifyText("RIGHT", filterFrame)


    -- Find Marker Toggle (UIDropDownMenuTemplate to match filter style)
    local findFrame = CreateFrame("Frame", "ModernMapMarkersFind_Blizz", dropdownParent, "UIDropDownMenuTemplate")
    findFrame:SetFrameStrata(filterFrame:GetFrameStrata())
    findFrame:SetFrameLevel(filterFrame:GetFrameLevel())

    local findBtn = getglobal(findFrame:GetName().."Button")
    if findBtn then findBtn:SetFrameLevel(findFrame:GetFrameLevel() + 2) end

    findFrame:SetPoint("TOPRIGHT", filterFrame, "BOTTOMRIGHT", 0, 0)

    UIDropDownMenu_SetWidth(dropdownWidth, findFrame)
    UIDropDownMenu_SetButtonWidth(dropdownButtonWidth, findFrame)
    UIDropDownMenu_SetText(L:GetLocalizedMarkerName("Find Marker"), findFrame)
    UIDropDownMenu_JustifyText("RIGHT", findFrame)

    -- Override the dropdown button to toggle our panel instead of opening a dropdown
    if findBtn then
        findBtn:SetScript("OnClick", function()
            local panel = getglobal("ModernMapMarkersFind_Panel")
            if panel then
                if panel:IsVisible() then
                    panel:Hide()
                else
                    UpdateFindPanel()
                    panel:Show()
                end
            end
        end)
    end

    -- Prevent the dropdown from opening normally via Initialize
    UIDropDownMenu_Initialize(findFrame, function() end)

    -- Find Marker Panel
    local PANEL_WIDTH = 220
    local ROW_HEIGHT = 16
    local MAX_VISIBLE_ROWS = 12
    local BUTTON_HEIGHT = 20
    local BUTTON_SPACING = 2
    local PANEL_PADDING = 8

    local findPanel = CreateFrame("Frame", "ModernMapMarkersFind_Panel", WorldMapFrame)
    findPanel:SetFrameStrata(filterFrame:GetFrameStrata())
    findPanel:SetFrameLevel(filterFrame:GetFrameLevel() + 20)
    findPanel:SetWidth(PANEL_WIDTH)
    findPanel:SetPoint("TOPRIGHT", findFrame, "BOTTOMRIGHT", -16, 0)
    findPanel:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    findPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    findPanel:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    findPanel:Hide()

    -- State
    local activeContinent = 1
    local activeType = "DUNGEON"

    -- Helper: Create a selector button
    local function CreateSelectorButton(name, parent, width, text)
        local btn = CreateFrame("Button", name, parent)
        btn:SetWidth(width)
        btn:SetHeight(BUTTON_HEIGHT)

        btn:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER", 0, 0)
        label:SetText(text)
        btn.label = label

        btn:SetScript("OnEnter", function()
            if not btn.isActive then
                btn:SetBackdropColor(0.3, 0.3, 0.3, 1)
            end
        end)
        btn:SetScript("OnLeave", function()
            if not btn.isActive then
                btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
            end
        end)

        btn.isActive = false
        btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        return btn
    end

    local function SetButtonActive(btn, active)
        btn.isActive = active
        if active then
            btn:SetBackdropColor(0.2, 0.4, 0.7, 1)
            btn:SetBackdropBorderColor(0.4, 0.6, 1.0, 1)
            btn.label:SetTextColor(1, 1, 1)
        else
            btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
            btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            btn.label:SetTextColor(0.8, 0.8, 0.8)
        end
    end

    -- Continent buttons
    local halfWidth = (PANEL_WIDTH - PANEL_PADDING * 2 - BUTTON_SPACING) / 2

    local btnKalimdor = CreateSelectorButton("MMMFind_Kalimdor", findPanel, halfWidth, L:GetLocalizedZoneName("Kalimdor"))
    btnKalimdor:SetPoint("TOPLEFT", findPanel, "TOPLEFT", PANEL_PADDING, -PANEL_PADDING)

    local btnEK = CreateSelectorButton("MMMFind_EK", findPanel, halfWidth, L:GetLocalizedZoneName("Eastern Kingdoms"))
    btnEK:SetPoint("TOPLEFT", btnKalimdor, "TOPRIGHT", BUTTON_SPACING, 0)

    -- Type buttons
    local thirdWidth = (PANEL_WIDTH - PANEL_PADDING * 2 - BUTTON_SPACING * 2) / 3

    local btnDungeon = CreateSelectorButton("MMMFind_Dungeon", findPanel, thirdWidth, L:GetLocalizedMarkerName("Dungeons"))
    btnDungeon:SetPoint("TOPLEFT", btnKalimdor, "BOTTOMLEFT", 0, -BUTTON_SPACING)

    local btnRaid = CreateSelectorButton("MMMFind_Raid", findPanel, thirdWidth, L:GetLocalizedMarkerName("Raids"))
    btnRaid:SetPoint("TOPLEFT", btnDungeon, "TOPRIGHT", BUTTON_SPACING, 0)

    local btnWorldBoss = CreateSelectorButton("MMMFind_WorldBoss", findPanel, thirdWidth, L:GetLocalizedMarkerName("World Bosses"))
    btnWorldBoss:SetPoint("TOPLEFT", btnRaid, "TOPRIGHT", BUTTON_SPACING, 0)

    -- Scroll frame for the instance list
    local listAreaTop = PANEL_PADDING + BUTTON_HEIGHT * 2 + BUTTON_SPACING * 2 + 4

    local scrollFrame = CreateFrame("ScrollFrame", "MMMFind_Scroll", findPanel, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", findPanel, "TOPLEFT", PANEL_PADDING, -listAreaTop)
    scrollFrame:SetPoint("BOTTOMRIGHT", findPanel, "BOTTOMRIGHT", -PANEL_PADDING - 22, PANEL_PADDING)

    -- Row buttons (reusable pool)
    local rowButtons = {}
    for i = 1, MAX_VISIBLE_ROWS do
        local row = CreateFrame("Button", "MMMFind_Row" .. i, findPanel)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
        row:SetPoint("RIGHT", scrollFrame, "RIGHT", 0, 0)

        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(row)
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")
        highlight:SetAlpha(0.4)

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT", row, "LEFT", 4, 0)
        nameText:SetJustifyH("LEFT")
        row.nameText = nameText

        local lvlText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        lvlText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        lvlText:SetJustifyH("RIGHT")
        row.lvlText = lvlText

        row:SetScript("OnEnter", function()
            if row.dataID then
                WorldMapTooltip:SetOwner(row, "ANCHOR_LEFT")
                WorldMapTooltip:AddLine(row.nameText:GetText(), 1, 0.82, 0)
                if row.lvlText:GetText() and row.lvlText:GetText() ~= "" then
                    WorldMapTooltip:AddLine(row.lvlText:GetText(), 1, 1, 1)
                end
                WorldMapTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            WorldMapTooltip:Hide()
        end)

        row:Hide()
        rowButtons[i] = row
    end

    -- Current filtered + sorted list cache
    local currentList = {}

    -- Sort function: level then name
    local function sortLvl(a, b)
        local _, _, alvlStr = string.find(a.description or "", "^(%d+)")
        local _, _, blvlStr = string.find(b.description or "", "^(%d+)")
        local alvl = tonumber(alvlStr) or 0
        local blvl = tonumber(blvlStr) or 0
        if alvl == blvl then return (a.name or "") < (b.name or "") end
        return alvl < blvl
    end

    -- Rebuild the filtered list and update the scroll frame
    local function RefreshFindList()
        local flatData = ModernMapMarkers_GetFlatData()
        currentList = {}

        for _, data in ipairs(flatData) do
            if data.continent == activeContinent and data.type == activeType then
                table.insert(currentList, data)
            end
        end
        table.sort(currentList, sortLvl)

        local totalRows = table.getn(currentList)
        local displayRows = math.min(totalRows, MAX_VISIBLE_ROWS)

        -- Resize panel to fit content
        local panelHeight = listAreaTop + (displayRows * ROW_HEIGHT) + PANEL_PADDING + 4
        if totalRows > MAX_VISIBLE_ROWS then
            panelHeight = listAreaTop + (MAX_VISIBLE_ROWS * ROW_HEIGHT) + PANEL_PADDING + 4
        end
        findPanel:SetHeight(panelHeight)

        FauxScrollFrame_Update(scrollFrame, totalRows, MAX_VISIBLE_ROWS, ROW_HEIGHT)

        local offset = FauxScrollFrame_GetOffset(scrollFrame)
        local lvlLabel = L:GetLocalizedMarkerName("Level") or "Level"

        for i = 1, MAX_VISIBLE_ROWS do
            local row = rowButtons[i]
            local dataIndex = offset + i

            if dataIndex <= totalRows then
                local data = currentList[dataIndex]
                local localizedName = L:GetLocalizedMarkerName(data.name)
                row.nameText:SetText(localizedName)

                if data.description then
                    row.lvlText:SetText(lvlLabel .. " " .. data.description)
                else
                    row.lvlText:SetText("")
                end

                -- Truncate name if it overlaps with level text
                row.nameText:SetWidth(row:GetWidth() - row.lvlText:GetStringWidth() - 16)

                row.dataID = data.id
                row:SetScript("OnClick", function()
                    ModernMapMarkers_FindMarker(data.id)
                end)
                row:Show()
            else
                row.nameText:SetText("")
                row.lvlText:SetText("")
                row.dataID = nil
                row:Hide()
            end
        end
    end

    scrollFrame:SetScript("OnVerticalScroll", function()
        FauxScrollFrame_OnVerticalScroll(ROW_HEIGHT, RefreshFindList)
    end)

    -- Button click handlers
    local function UpdateButtonStates()
        SetButtonActive(btnKalimdor,  activeContinent == 1)
        SetButtonActive(btnEK,        activeContinent == 2)
        SetButtonActive(btnDungeon,   activeType == "DUNGEON")
        SetButtonActive(btnRaid,      activeType == "RAID")
        SetButtonActive(btnWorldBoss, activeType == "WORLDBOSS")
    end

    btnKalimdor:SetScript("OnClick", function()
        activeContinent = 1
        UpdateButtonStates()
        RefreshFindList()
    end)

    btnEK:SetScript("OnClick", function()
        activeContinent = 2
        UpdateButtonStates()
        RefreshFindList()
    end)

    btnDungeon:SetScript("OnClick", function()
        activeType = "DUNGEON"
        UpdateButtonStates()
        RefreshFindList()
    end)

    btnRaid:SetScript("OnClick", function()
        activeType = "RAID"
        UpdateButtonStates()
        RefreshFindList()
    end)

    btnWorldBoss:SetScript("OnClick", function()
        activeType = "WORLDBOSS"
        UpdateButtonStates()
        RefreshFindList()
    end)

    -- UpdateFindPanel: called from the dropdown button override to refresh and show
    function UpdateFindPanel()
        UpdateButtonStates()
        RefreshFindList()
    end

    -- Close panel when the world map closes (1.12-compatible hook)
    local origOnHide = WorldMapFrame:GetScript("OnHide")
    WorldMapFrame:SetScript("OnHide", function()
        if origOnHide then origOnHide() end
        findPanel:Hide()
    end)

    -- Set initial button states
    UpdateButtonStates()

    -- pfUI Skinning
    if isPfUI and _G.pfUI and _G.pfUI.api then
        if _G.pfUI.api.SkinDropDown then
            _G.pfUI.api.SkinDropDown(filterFrame)
            _G.pfUI.api.SkinDropDown(findFrame)
        end
        if _G.pfUI.api.SkinButton then
            _G.pfUI.api.SkinButton(btnKalimdor)
            _G.pfUI.api.SkinButton(btnEK)
            _G.pfUI.api.SkinButton(btnDungeon)
            _G.pfUI.api.SkinButton(btnRaid)
            _G.pfUI.api.SkinButton(btnWorldBoss)
        end
    end
    
    -- Apply saved visibility state
    if ModernMapMarkersDB and ModernMapMarkersDB.hideDropdowns then
        filterFrame:Hide()
        findFrame:Hide()
    end

end

-- Debug Utilities
SLASH_MMMDEBUG1 = "/mmmzones"
SlashCmdList["MMMDEBUG"] = function()
    if not DEFAULT_CHAT_FRAME then return end
    for contID = 1, 2 do
        local contName = (contID == 1) and "Kalimdor" or "Eastern Kingdoms"
        DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7fModernMapMarkers:|r Zone Indexes for " .. contName .. ":")
        local zones = { GetMapZones(contID) }
        for i, zoneName in ipairs(zones) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ": " .. zoneName)
        end
    end
end

-- Slash command to toggle dropdown visibility
SLASH_MMM1 = "/mmm"
SlashCmdList["MMM"] = function()
    if type(ModernMapMarkersDB) ~= "table" then
        ModernMapMarkersDB = { filters = {} }
    end
    ModernMapMarkersDB.hideDropdowns = not ModernMapMarkersDB.hideDropdowns
    
    local filterFrame = getglobal("ModernMapMarkersFilter_Blizz")
    local findFrame   = getglobal("ModernMapMarkersFind_Blizz")
    local findPanel   = getglobal("ModernMapMarkersFind_Panel")
    
    if filterFrame and findFrame then
        if ModernMapMarkersDB.hideDropdowns then
            filterFrame:Hide()
            findFrame:Hide()
            if findPanel then findPanel:Hide() end
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7fModern|rMapMarkers: " .. L:GetLocalizedMarkerName("Dropdown menus hidden."))
            end
        else
            filterFrame:Show()
            findFrame:Show()
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7fModern|rMapMarkers: " .. L:GetLocalizedMarkerName("Dropdown menus shown."))
            end
        end
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
    L:Initialize()
    MMM_GUI.InitializeWorldMapControls()
    this:UnregisterEvent("VARIABLES_LOADED")
end)

_G.ModernMapMarkers_GUI = MMM_GUI
