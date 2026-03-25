--- Localization.lua - ModernMapMarkers Localization Core
--- Provides zone name reverse-lookup (localized -> English) and
--- all other translations (English -> localized) for non-English clients. See ./Locales

ModernMapMarkers_Locale = {}

-- Registered locale tables: ["deDE"] = { Zones = {}, Markers = {} }, ...
local LocaleData = {}

-- Active locale tables (set on VARIABLES_LOADED)
local Dictionary = nil  -- English -> Localized

local detectedLocale = nil

--- Register a locale's dictionary containing all translations from ./Locales/Locale_xxXX.lua
function ModernMapMarkers_Locale:RegisterDictionary(locale, tbl)
    if not LocaleData[locale] then LocaleData[locale] = {} end
    LocaleData[locale].Dictionary = tbl
end

function ModernMapMarkers_Locale:Initialize()
    detectedLocale = GetLocale()
    if not detectedLocale or detectedLocale == "enGB" then
        detectedLocale = "enUS" -- trusty enUS fallback. working out greatly atm
    end

    local data = LocaleData[detectedLocale]
    if data and data.Dictionary then
        Dictionary = data.Dictionary
    end
end

--- Given a localized zone name (from GetMapZones), return the English key
--- used in MarkerData.lua.  Returns the input unchanged for enUS or unknown names.
function ModernMapMarkers_Locale:GetEnglishZoneName(localizedName)
    local zoneId = MMM_PfDBHelper:GetZoneId(localizedName, detectedLocale)
    if not zoneId then
        return localizedName
    end
    local zoneName = MMM_PfDBHelper:GetZoneName(zoneId, "enUS")
    --self:Print("GetEnglishZoneName - localizedName: " .. tostring(localizedName) .. " --> " .. tostring(zoneName))
    return zoneName
end

--- Given an English zone name, return the localized display name.
--- Falls back to the English name if no translation exists.
function ModernMapMarkers_Locale:GetLocalizedZoneName(englishName)
    local zoneId = MMM_PfDBHelper:GetZoneId(englishName, "enUS")
    if not zoneId then
        return englishName
    end
    local zoneName = MMM_PfDBHelper:GetZoneName(zoneId, detectedLocale)
    --self:Print("GetLocalizedZoneName - englishName: " .. tostring(englishName) .. " --> " .. tostring(zoneName))
    return zoneName
end

--- Given an English string, returns the localized equivalent, either from pfDB or the Dictionary. Applies a string mask.
--- Falls back to the English name if no translation exists.
-- englishName : the string in English
-- type        : type can be "dungeon", "raid", "worldboss", "boat", "zepp", "tram"
-- mask        : string mask that should be applied like "Boat to %s"
function ModernMapMarkers_Locale:GetLocalizedString(englishName, type, mask)
    --self:Print("GetLocalizedString - englishName: " .. tostring(englishName) .. ", type: " .. tostring(type) .. ", mask: " .. tostring(mask))
    local localizedName = nil
    if not mask then -- see if we automatically need to choose a mask because of the type
        if type == "BOAT" then
            mask = "Boat to %s"
        elseif type == "ZEPP" or type == "ZEPPELIN" then
            mask = "Zeppelin to %s"
        elseif type == "TRAM" then
            mask = "Tram to %s"
        end
    end
    if Dictionary then
        local englishNameEnglishMask = englishName
        if mask then -- apply non-localized english mask if it exists
            englishNameEnglishMask = string.format(mask, englishName)
        end
        if Dictionary[englishNameEnglishMask] then
            return Dictionary[englishNameEnglishMask] -- we have a custom translation for this string, use it
        end
    end
    if type == "WORLDBOSS" then -- worldboss is the only type that is a unit name
        local unitId = MMM_PfDBHelper:GetUnitId(englishName, "enUS") -- first we get the unit id from pfDB
        if unitId then
            localizedName = MMM_PfDBHelper:GetUnitName(unitId, detectedLocale) -- now get localized unit name from pfDB
        end
    else -- all other types are zone names
        local zoneId = MMM_PfDBHelper:GetZoneId(englishName, "enUS") -- first we get the zone id from pfDB
        if zoneId then
            localizedName = MMM_PfDBHelper:GetZoneName(zoneId, detectedLocale) -- get localized zone name from pfDB
        end
    end
    if not localizedName and Dictionary then -- couldn't find it in zone or unit tables, try to get custom translation from ./Locales
        localizedName = Dictionary[englishName]
    end
    if mask then -- apply mask
        local localizedMask = mask
        if Dictionary and Dictionary[mask] then
            localizedMask = Dictionary[mask] -- we have a localized mask
        end
        if localizedName then -- all good. we have a localized name
            localizedName = string.format(localizedMask, localizedName)
        else -- second best option. we have no localized name. fallback to english name
            localizedName = string.format(localizedMask, englishName)
        end
    end
    if not localizedName then -- couldn't find anything anywhere. fall back to original english name
        localizedName = englishName
    end
    return localizedName
end

-- Safe call helper for listener
function ModernMapMarkers_Locale:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("ModernMapMarkers_Locale: " .. tostring(msg))
end