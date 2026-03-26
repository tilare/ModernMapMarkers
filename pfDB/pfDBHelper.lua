MMM_PfDBHelper = {}

local by_name = { zones = {}, units = {} }    -- by_name[kind][locale] = { ["Localized Name"] = id, ... }
local initialized = { zones = {}, units = {} } -- initialized[kind][locale] = true

local idCache   = { zones = {}, units = {} }   -- idCache[kind][locale][name] = id or false
local nameCache = { zones = {}, units = {} }   -- nameCache[kind][locale][id] = name or false

local idError   = { zones = {}, units = {} }   -- idError[kind][key] = true
local nameError = { zones = {}, units = {} }   -- nameError[kind][key] = true

function MMM_PfDBHelper:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("MMM_PfDBHelper: " .. tostring(msg))
end

local function ensureLookupTable(kind, locale)
    if not kind or not locale then return end
    if initialized[kind][locale] then return end

    by_name[kind][locale] = by_name[kind][locale] or {}

    local db = MMM_pfDB and MMM_pfDB[kind]
    -- vanilla locale (e.g. "enUS" or "deDE")
    if db[locale] then
        by_name[kind][locale] = by_name[kind][locale] or {}
        for id, name in pairs(db[locale]) do
            if type(name) == "string" then
                by_name[kind][locale][name] = id
            end
        end
    end

    -- turtle-specific locale (e.g. "enUS-turtle" or "deDE-turtle")
    local turtle_locale = locale .. "-turtle"
    if db[turtle_locale] then
        by_name[kind][turtle_locale] = by_name[kind][turtle_locale] or {}
        for id, name in pairs(db[turtle_locale]) do
            if type(name) == "string" then
                by_name[kind][turtle_locale][name] = id
            end
        end
    end

    initialized[kind][locale] = true
end

local function getId(kind, text, locale)
    if not kind or not text or not locale then return nil end
    ensureLookupTable(kind, locale)

    idCache[kind][locale] = idCache[kind][locale] or {}
    if idCache[kind][locale][text] then
        return idCache[kind][locale][text] -- we have a cached value. return it
    end

    local found = nil
    if by_name[kind][locale] and by_name[kind][locale][text] then
        found = by_name[kind][locale][text]
    else
        local turtle_locale = locale .. "-turtle"
        if by_name[kind][turtle_locale] and by_name[kind][turtle_locale][text] then
            found = by_name[kind][turtle_locale][text]
        end
    end

    if not found and idError[kind][text] == nil then
        idError[kind][text] = true
        --MMM_PfDBHelper:Print("ERROR getId - kind="..tostring(kind).." text="..tostring(text))
    end

    idCache[kind][locale][text] = found or false
    return found
end

local function getName(kind, id, locale)
    if not kind or not id or not locale then return nil end

    nameCache[kind][locale] = nameCache[kind][locale] or {}
    if nameCache[kind][locale][id] then
        return nameCache[kind][locale][id]
    end

    local found = nil
    local db = MMM_pfDB and MMM_pfDB[kind]
    if db[locale] and db[locale][id] then
        found = db[locale][id]
    else
        local turtle_locale = locale .. "-turtle"
        if db[turtle_locale] and db[turtle_locale][id] then
            found = db[turtle_locale][id]
        end
    end

    if not found and nameError[kind][id] == nil then
        nameError[kind][id] = true
        --MMM_PfDBHelper:Print("ERROR getName - kind="..tostring(kind).." id="..tostring(id))
    end

    nameCache[kind][locale][id] = found or false
    return found
end

function MMM_PfDBHelper:GetZoneId(zoneText, locale)
    return getId("zones", zoneText, locale)
end

function MMM_PfDBHelper:GetUnitId(unitText, locale)
    return getId("units", unitText, locale)
end

function MMM_PfDBHelper:GetZoneName(zoneId, locale)
    return getName("zones", zoneId, locale)
end

function MMM_PfDBHelper:GetUnitName(unitId, locale)
    return getName("units", unitId, locale)
end