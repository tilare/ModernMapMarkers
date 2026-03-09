---
--- Localization.lua - ModernMapMarkers Localization Core
---
--- Provides zone name reverse-lookup (localized -> English) and
--- marker name translation (English -> localized) for non-English clients.
---
--- @compatible World of Warcraft 1.12 / Lua 5.0
---

ModernMapMarkers_Locale = {}

-- Registered locale tables: ["deDE"] = { Zones = {}, Markers = {} }, ...
local LocaleData = {}

-- Active locale tables (set on VARIABLES_LOADED)
local ActiveZones   = nil  -- English -> Localized zone names
local ReverseZones  = nil  -- Localized -> English zone names
local ActiveMarkers = nil  -- English -> Localized marker/instance names

local detectedLocale = nil

--- Register a locale's zone translations.
--- @param locale string  e.g. "deDE"
--- @param tbl table      English key -> Localized value
function ModernMapMarkers_Locale:RegisterZones(locale, tbl)
    if not LocaleData[locale] then LocaleData[locale] = {} end
    LocaleData[locale].Zones = tbl
end

--- Register a locale's marker/instance name translations.
--- @param locale string  e.g. "deDE"
--- @param tbl table      English key -> Localized value
function ModernMapMarkers_Locale:RegisterMarkers(locale, tbl)
    if not LocaleData[locale] then LocaleData[locale] = {} end
    LocaleData[locale].Markers = tbl
end

--- Called once at load time to activate the correct locale.
function ModernMapMarkers_Locale:Initialize()
    detectedLocale = GetLocale() or "enUS"

    local data = LocaleData[detectedLocale]

    if data and data.Zones then
        ActiveZones = data.Zones
        -- Build reverse lookup: localized -> English
        ReverseZones = {}
        for eng, loc in pairs(ActiveZones) do
            ReverseZones[loc] = eng
        end
    end

    if data and data.Markers then
        ActiveMarkers = data.Markers
    end
end

--- Given a localized zone name (from GetMapZones), return the English key
--- used in MarkerData.lua.  Returns the input unchanged for enUS or unknown names.
--- @param localizedName string
--- @return string
function ModernMapMarkers_Locale:GetEnglishZoneName(localizedName)
    if ReverseZones and ReverseZones[localizedName] then
        return ReverseZones[localizedName]
    end
    return localizedName
end

--- Given an English zone name, return the localized display name.
--- Falls back to the English name if no translation exists.
--- @param englishName string
--- @return string
function ModernMapMarkers_Locale:GetLocalizedZoneName(englishName)
    if ActiveZones and ActiveZones[englishName] then
        return ActiveZones[englishName]
    end
    return englishName
end

--- Given an English marker/instance name, return the localized display name.
--- Falls back to the English name if no translation exists.
--- @param englishName string
--- @return string
function ModernMapMarkers_Locale:GetLocalizedMarkerName(englishName)
    if ActiveMarkers and ActiveMarkers[englishName] then
        return ActiveMarkers[englishName]
    end
    return englishName
end

--- Returns the detected client locale string.
--- @return string
function ModernMapMarkers_Locale:GetLocale()
    return detectedLocale or "enUS"
end