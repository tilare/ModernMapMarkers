MMM_PfDBHelper = {}

local zones_by_name = {}
local units_by_name = {}

local zoneIdCache = {}
local zoneNameCache = {}
local unitIdCache = {}
local unitNameCache = {}
local zoneIdError = {}
local zoneNameError = {}
local unitIdError = {}
local unitNameError = {}

function MMM_PfDBHelper:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("MMM_PfDBHelper: " .. tostring(msg))
end

local function ensureZonesLookupTable(locale)
    zones_by_name = {[locale .. "-turtle"] = {}, [locale] = {}}
    if MMM_pfDB["zones"][locale] then
        for id, name in pairs(MMM_pfDB["zones"][locale]) do
            if type(name) == "string" then zones_by_name[locale][name] = id end
        end
    end
    if MMM_pfDB["zones"][locale .. "-turtle"] then
        for id, name in pairs(MMM_pfDB["zones"][locale .. "-turtle"]) do
            if type(name) == "string" then zones_by_name[locale .. "-turtle"][name] = id end
        end
    end
end

local function ensureUnitsLookupTable(locale)
    units_by_name = {[locale .. "-turtle"] = {}, [locale] = {}}
    if MMM_pfDB["units"][locale] then
        for id, name in pairs(MMM_pfDB["units"][locale]) do
            if type(name) == "string" then units_by_name[locale][name] = id end
        end
    end
    if MMM_pfDB["zones"][locale .. "-turtle"] then
        for id, name in pairs(MMM_pfDB["units"][locale .. "-turtle"]) do
            if type(name) == "string" then units_by_name[locale .. "-turtle"][name] = id end
        end
    end
end

function MMM_PfDBHelper:GetZoneId(zoneText, locale)
    --self:Print("GetZoneId - zoneText: " .. tostring(zoneText) .. ", locale: " .. tostring(locale))
    ensureZonesLookupTable(locale)
    if zoneIdCache[locale] and zoneIdCache[locale][zoneText] ~= nil then return zoneIdCache[locale][zoneText] end
    if not zones_by_name then return nil end -- sanity checks
    local zoneId = nil
    if zones_by_name[locale] and zones_by_name[locale][zoneText] then
        zoneId = zones_by_name[locale][zoneText]
    elseif zones_by_name[locale .. "-turtle"] and zones_by_name[locale .. "-turtle"][zoneText] then
        zoneId = zones_by_name[locale .. "-turtle"][zoneText]
    end
    if not zoneId and zoneIdError[zoneText] == nil then
        --MMM_PfDBHelper:Print("|cffff0000ERROR! GetZoneId - zoneId could not be retrieved for zoneName: '" .. tostring(zoneText) .. "'|r")
        if zoneText then
            zoneIdError[zoneText] = true
        end
    end
    zoneIdCache[locale] = zoneIdCache[locale] or {}
    zoneIdCache[locale][zoneText] = zoneId
    return zoneId
end

function MMM_PfDBHelper:GetZoneName(zoneId, locale)
    --self:Print("GetZoneName - zoneId: " .. tostring(zoneId) .. ", locale: " .. tostring(locale))
    if zoneNameCache[locale] and zoneNameCache[locale][zoneId] ~= nil then return zoneNameCache[locale][zoneId] end
    if not MMM_pfDB["zones"] then return nil end -- sanity checks
    local zoneName = nil
    if MMM_pfDB["zones"][locale] and MMM_pfDB["zones"][locale][zoneId] then
        zoneName = MMM_pfDB["zones"][locale][zoneId]
    elseif MMM_pfDB["zones"][locale .. "-turtle"] and MMM_pfDB["zones"][locale .. "-turtle"][zoneId] then
        zoneName = MMM_pfDB["zones"][locale .. "-turtle"][zoneId]
    end
    if not zoneName and zoneNameError[zoneId] == nil then
        --MMM_PfDBHelper:Print("|cffff0000ERROR! GetZoneName - zoneName could not be retrieved for zoneId: '" .. tostring(zoneId) .. "'|r")
        if zoneId then
            zoneNameError[zoneId] = true
        end
    end
    zoneNameCache[locale] = zoneNameCache[locale] or {}
    zoneNameCache[locale][zoneId] = zoneName
    return zoneName
end

function MMM_PfDBHelper:GetUnitId(unitName, locale)
    --self:Print("GetUnitId - unitName: " .. tostring(unitName) .. ", locale: " .. tostring(locale))
    ensureUnitsLookupTable(locale)
    if unitIdCache[locale] and unitIdCache[locale][unitName] ~= nil then return unitIdCache[locale][unitName] end
    if not units_by_name then return nil end -- sanity checks
    local unitId = nil
    if units_by_name[locale] and units_by_name[locale][unitName] then
        unitId = units_by_name[locale][unitName]
    elseif units_by_name[locale .. "-turtle"] and units_by_name[locale .. "-turtle"][unitName] then
        unitId = units_by_name[locale .. "-turtle"][unitName]
    end
    if not unitId and unitIdError[unitName] == nil then
        --MMM_PfDBHelper:Print("|cffff0000ERROR! GetUnitId - unitId could not be retrieved for zoneName: '" .. tostring(unitName) .. "'|r")
        if unitName then
            unitIdError[zoneId] = true
        end
    end
    unitIdCache[locale] = unitIdCache[locale] or {}
    unitIdCache[locale][unitName] = unitId
    return unitId
end

function MMM_PfDBHelper:GetUnitName(unitId, locale)
    --self:Print("GetUnitName - unitId: " .. tostring(unitId) .. ", locale: " .. tostring(locale))
    if unitNameCache[locale] and unitNameCache[locale][unitId] ~= nil then return unitNameCache[locale][unitId] end
    if not MMM_pfDB["units"] then return nil end -- sanity checks
    local unitName = nil
    if MMM_pfDB["units"][locale] and MMM_pfDB["units"][locale][unitId] then
        unitName = MMM_pfDB["units"][locale][unitId]
    elseif MMM_pfDB["units"][locale .. "-turtle"] and MMM_pfDB["units"][locale .. "-turtle"][unitId] then
        unitName = MMM_pfDB["units"][locale .. "-turtle"][unitId]
    end
    if not unitName and unitNameError[unitId] == nil then
        --MMM_PfDBHelper:Print("|cffff0000ERROR! GetUnitName - unitName could not be retrieved for unitId: '" .. tostring(unitId) .. "'|r")
        if unitId then
            unitNameError[unitId] = true
        end
    end
    unitNameCache[locale] = unitNameCache[locale] or {}
    unitNameCache[locale][unitId] = unitName
    return unitName
end