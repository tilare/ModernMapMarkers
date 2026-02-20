local MMM_GUI = {}
local isPfUI = IsAddOnLoaded("pfUI")

function MMM_GUI.InitializeWorldMapControls()

    -- Filter Definitions
    local filterOptions = {
        { label = "All Markers",  value = "ALL",       isCheck = true, checked = true  },
        { label = "Dungeons",     value = "DUNGEON",   isCheck = true, checked = true  },
        { label = "Raids",        value = "RAID",      isCheck = true, checked = true  },
        { label = "World Bosses", value = "WORLDBOSS", isCheck = true, checked = true  },
        { label = "Transports", isHeader = true },
        { label = "  Boats",      value = "BOAT",      isCheck = true, checked = true  },
        { label = "  Zeppelins",  value = "ZEPPELIN",  isCheck = true, checked = true  },
        { label = "  Trams",      value = "TRAM",      isCheck = true, checked = true  },
        { label = "Transport Faction", isHeader = true },
        { label = "  Show All",   value = "ALL",       isCheck = true, checked = true,  isRadio = true, group = "fac" },
        { label = "  Alliance",   value = "Alliance",  isCheck = true, checked = false, isRadio = true, group = "fac" },
        { label = "  Horde",      value = "Horde",     isCheck = true, checked = false, isRadio = true, group = "fac" },
    }

    -- Load Saved Variables
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

    local dropdownWidth = 120
    local dropdownButtonWidth = 125 
    
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
    UIDropDownMenu_SetText("Filter Markers", filterFrame)
    UIDropDownMenu_JustifyText("RIGHT", filterFrame)


    -- Find Marker Dropdown
    local findFrame = CreateFrame("Frame", "ModernMapMarkersFind_Blizz", dropdownParent, "UIDropDownMenuTemplate")
    
    findFrame:SetFrameLevel(filterFrame:GetFrameLevel())
    local findBtn = getglobal(findFrame:GetName().."Button")
    if findBtn then findBtn:SetFrameLevel(findFrame:GetFrameLevel() + 2) end

    findFrame:SetPoint("TOPRIGHT", filterFrame, "BOTTOMRIGHT", 0, 0)
    
    -- Make the dropdown list open to the left instead of the right
    findFrame.point = "TOPRIGHT"
    findFrame.relativePoint = "BOTTOMRIGHT"
    findFrame.relativeTo = findFrame
    findFrame.xOffset = -5
    findFrame.yOffset = 15

    UIDropDownMenu_Initialize(findFrame, function(level)
        local flatData = ModernMapMarkers_GetFlatData()
        
        -- Sort: Level -> Name
        local function sortLvl(a, b)
            local _, _, alvlStr = string.find(a.description or "", "^(%d+)")
            local _, _, blvlStr = string.find(b.description or "", "^(%d+)")
            local alvl = tonumber(alvlStr) or 0
            local blvl = tonumber(blvlStr) or 0
            if alvl == blvl then return (a.name or "") < (b.name or "") end
            return alvl < blvl
        end

        if level == 1 then
            -- Continent
            local info = {}
            info.text = "          Kalimdor"
            info.value = 1
            info.hasArrow = 1
            info.notCheckable = 1
            UIDropDownMenu_AddButton(info, level)

            info.text = "          Eastern Kingdoms"
            info.value = 2
            info.hasArrow = 1
            info.notCheckable = 1
            UIDropDownMenu_AddButton(info, level)

        elseif level == 2 then
            -- Type
            local contID = UIDROPDOWNMENU_MENU_VALUE
            if contID then
                local info = {}
                info.text = "          Dungeons"
                info.value = contID .. ":DUNGEON"
                info.hasArrow = 1
                info.notCheckable = 1
                UIDropDownMenu_AddButton(info, level)

                info.text = "          Raids"
                info.value = contID .. ":RAID"
                info.hasArrow = 1
                info.notCheckable = 1
                UIDropDownMenu_AddButton(info, level)
            end

        elseif level == 3 then
            -- Instance
            local parentVal = UIDROPDOWNMENU_MENU_VALUE
            local _, _, cID, cType = string.find(parentVal, "^(%d+):(%w+)")
            cID = tonumber(cID)

            if cID and cType then
                local list = {}
                for _, data in ipairs(flatData) do
                    if data.continent == cID and data.type == cType then
                        table.insert(list, data)
                    end
                end
                table.sort(list, sortLvl)

                for _, dataRaw in ipairs(list) do
                    local data = dataRaw 
                    local info = {}
                    local lvlText = data.description and (" |cffaaaaaa(Lvl " .. data.description .. ")|r") or ""
                    info.text = data.name .. lvlText
                    info.value = data.id
                    info.notCheckable = 1
                    info.func = function()
                        ModernMapMarkers_FindMarker(data.id)
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end
    end)
    
    UIDropDownMenu_SetWidth(dropdownWidth, findFrame)
    UIDropDownMenu_SetButtonWidth(dropdownButtonWidth, findFrame)
    UIDropDownMenu_SetText("Find Marker", findFrame) 
    UIDropDownMenu_JustifyText("RIGHT", findFrame)
    
    -- pfUI Skinning
    if isPfUI and _G.pfUI and _G.pfUI.api and _G.pfUI.api.SkinDropDown then
        _G.pfUI.api.SkinDropDown(filterFrame)
        _G.pfUI.api.SkinDropDown(findFrame)
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

-- Initialize on Load
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
    MMM_GUI.InitializeWorldMapControls()
    this:UnregisterEvent("VARIABLES_LOADED")
end)

_G.ModernMapMarkers_GUI = MMM_GUI


-- Hook the global dropdown toggle to open dropdown left
local original_ToggleDropDownMenu = ToggleDropDownMenu
function ToggleDropDownMenu(level, value, dropDownFrame, anchorName, xOffset, yOffset)
    original_ToggleDropDownMenu(level, value, dropDownFrame, anchorName, xOffset, yOffset)

    local currentLevel = level or 1
    
    if UIDROPDOWNMENU_OPEN_MENU == "ModernMapMarkersFind_Blizz" or UIDROPDOWNMENU_OPEN_MENU == "ModernMapMarkersFilter_Blizz" then
        
        if currentLevel > 1 then
            local currentList = getglobal("DropDownList" .. currentLevel)
            local parentList = getglobal("DropDownList" .. (currentLevel - 1))
            
            if currentList and parentList then
                currentList:ClearAllPoints()
                currentList:SetPoint("TOPRIGHT", parentList, "TOPLEFT", 0, 0)
            end
        end

        -- Arrows to left side
        local listFrameName = "DropDownList" .. currentLevel
        for i = 1, 32 do
            local expandArrow = getglobal(listFrameName .. "Button" .. i .. "ExpandArrow")
            if expandArrow and expandArrow:IsVisible() then
                local button = getglobal(listFrameName .. "Button" .. i)
                expandArrow:ClearAllPoints()
                expandArrow:SetPoint("LEFT", button, "LEFT", 5, 0)
                if expandArrow.GetNormalTexture and expandArrow:GetNormalTexture() then
                    expandArrow:GetNormalTexture():SetTexCoord(1, 0, 0, 1)
                end
            end
        end

    else
        -- Reset the arrows to the right after finished using MMM
        local listFrameName = "DropDownList" .. currentLevel
        for i = 1, 32 do
            local expandArrow = getglobal(listFrameName .. "Button" .. i .. "ExpandArrow")
            if expandArrow then
                local button = getglobal(listFrameName .. "Button" .. i)
                expandArrow:ClearAllPoints()
                expandArrow:SetPoint("RIGHT", button, "RIGHT", -5, 0) 
                if expandArrow.GetNormalTexture and expandArrow:GetNormalTexture() then
                    expandArrow:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                end
            end
        end
    end
end
