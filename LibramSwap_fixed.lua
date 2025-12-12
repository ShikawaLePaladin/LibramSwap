-- LibramSwap_fixed.lua (cleaned)
-- Minimal, cleaned implementation for LibramSwap (1.12)

local string_find = string.find
local string_gsub = string.gsub
local GetTime = GetTime
local BOOKTYPE_SPELL = BOOKTYPE_SPELL or "spell"

-- runtime debug logger (reads saved flag at runtime so it can be toggled)
local function LogDebug(msg)
    if type(LibramSwapDB) == "table" and LibramSwapDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap DEBUG]: "..tostring(msg).."|r")
    end
end

local NameIndex = {}
local IdIndex = {}
local lastSwapTime = 0
local perSpellHasSwapped = {}
local perSpellLastSwap = {}
-- track which spells have explicit user-saved selections (so we persist only those)
local UserSelections = {}

local SWAP_THROTTLE_GENERIC = 1.48
local PER_SPELL_THROTTLE = { ["Judgement"] = 7.8 }

local CONSECRATION_FAITHFUL = "Libram of the Faithful"
local CONSECRATION_FARRAKI  = "Libram of the Farraki Zealot"

LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
LibramSwapDB.map = (type(LibramSwapDB.map) == "table") and LibramSwapDB.map or {}
-- default to enabled unless explicitly disabled by user
if LibramSwapDB.enabled == nil then LibramSwapDB.enabled = true end

local function deepCopy(src)
    if type(src) ~= "table" then return src end
    local out = {}
    for k,v in pairs(src) do out[k] = deepCopy(v) end
    return out
end

-- backup of saved map under our control to detect external overwrites
local SavedMapBackup = {}
local watchdog_acc = 0
local WATCHDOG_INTERVAL = 10 -- seconds between checks

local function mapsEqual(a,b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k,v in pairs(a) do
        if b[k] ~= v then return false end
    end
    for k,v in pairs(b) do
        if a[k] ~= v then return false end
    end
    return true
end

-- Start with an empty runtime mapping. User selections (from savedvariables)
-- will be merged into this at PLAYER_LOGIN so there are NO default librams.
local LibramMap = {}
-- apply any explicit saved selections (persisted by LibramSwap_ApplySelection or profiles)
for k,v in pairs(LibramSwapDB.map) do
    if v == "__NONE__" then
        LibramMap[k] = nil
    else
        LibramMap[k] = v
    end
    UserSelections[k] = true
end
-- initialize backup after load
SavedMapBackup = deepCopy(LibramSwapDB.map)

-- expose mapping table to config UI (it expects a global `LibramMap`)
_G.LibramMap = LibramMap

local WatchedNames = {}
for _, name in pairs(LibramMap) do if type(name) == "string" then WatchedNames[name] = true end end

local function ItemIDFromLink(link)
    if not link then return nil end
    local _, _, id = string_find(link, "item:(%d+)")
    return id and tonumber(id) or nil
end

local function BuildBagIndex()
    for k in pairs(NameIndex) do NameIndex[k] = nil end
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if slots and slots > 0 then
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, name = string_find(link, "%[(.-)%]")
                    if name and WatchedNames[name] then
                        NameIndex[name] = {bag = bag, slot = slot, link = link}
                    end
                end
            end
        end
    end
end

local function HasItemInBags(itemName)
    if not itemName then return nil end
    local ref = NameIndex[itemName]
    if ref then
        local cur = GetContainerItemLink(ref.bag, ref.slot)
        if cur and string_find(cur, itemName, 1, true) then return ref.bag, ref.slot end
        BuildBagIndex()
        ref = NameIndex[itemName]
        if ref then return ref.bag, ref.slot end
        return nil
    end
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if slots and slots > 0 then
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot)
                if link and string_find(link, itemName, 1, true) then
                    NameIndex[itemName] = {bag = bag, slot = slot, link = link}
                    return bag, slot
                end
            end
        end
    end
    return nil
end

-- expose helper for config UI to check item presence
_G.LibramSwap_HasItem = HasItemInBags

local function SplitNameAndRank(spec)
    if not spec then return nil end
    local _, _, base, rnum = string_find(spec, "^(.-)%s*%(%s*[Rr][Aa][Nn][Kk]%s*(%d+)%s*%)%s*$")
    if base then return (string_gsub(base, "%s+$", "")), ("Rank " .. rnum) end
    return (string_gsub(spec, "%s+$", "")), nil
end

local function IsSpellReady(spellSpec)
    local base, reqRank = SplitNameAndRank(spellSpec)
    for i = 1, 300 do
        local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
        if not name then break end
        if name == base and (not reqRank or (rank and rank == reqRank)) then
            local start, duration, enabled = GetSpellCooldown(i, BOOKTYPE_SPELL)
            if enabled == 0 then return false end
            if start == 0 or duration == 0 then return true end
            local remaining = (start + duration) - GetTime()
            return remaining <= 0
        end
    end
    return false
end

local function ResolveLibramForSpell(spellName)
    LogDebug("ResolveLibramForSpell called for: "..tostring(spellName) .. " (mapping -> "..tostring(LibramMap[spellName])..")")
    if LibramSwapDB and LibramSwapDB.enabledMap and LibramSwapDB.enabledMap[spellName] == false then
        return nil
    end
    if spellName == "Consecration" then
        local choice = LibramMap["Consecration"]
        -- Treat any legacy/undesired 'Auto' marker as no selection so the user must choose explicitly
        if type(choice) == "string" and string.lower(choice) == "auto" then choice = nil end
        if choice and HasItemInBags(choice) then return choice end
        return nil
    end
    local libram = LibramMap[spellName]
    if not libram then
        LogDebug("No user selection for spell: "..tostring(spellName))
        return nil
    end
    if libram == "None" then return nil end
    if spellName == "Flash of Light" then
        if not HasItemInBags("Libram of Light") and HasItemInBags("Libram of Divinity") then
            libram = "Libram of Divinity"
        end
    end
    -- ensure the user-selected libram is present in bags before returning it; avoids attempted equips that will fail
    if HasItemInBags(libram) then
        LogDebug("Resolved libram '"..tostring(libram).."' for spell '"..tostring(spellName).."'")
        return libram
    else
        LogDebug("Requested libram '"..tostring(libram).."' for spell '"..tostring(spellName).."' not present in bags.")
        return nil
    end
end

local function EquipLibramForSpell(spellName, itemName)
    if not itemName then return false end
    LogDebug("EquipLibramForSpell called for spell='"..tostring(spellName).."' item='"..tostring(itemName).."'")
    -- check common equipment slots (main/off/ranged) to avoid re-equipping
    local slotChecks = {16, 17, 18}
    for _, s in ipairs(slotChecks) do
        local equipped = GetInventoryItemLink("player", s)
        if equipped and string_find(equipped, itemName, 1, true) then
            return false
        end
    end
    if CursorHasItem and CursorHasItem() then
        LogDebug("Cannot equip - cursor occupied when trying to equip '"..tostring(itemName).."' for '"..tostring(spellName).."'.")
        return false
    end
    local bag, slot = HasItemInBags(itemName)
    if bag and slot then
        LogDebug("Found '"..tostring(itemName).."' in bag="..tostring(bag).." slot="..tostring(slot).."; attempting UseContainerItem()")
        UseContainerItem(bag, slot)
        return true
    end
    LogDebug("Item '"..tostring(itemName).."' not found in bags when equipping for '"..tostring(spellName).."'.")
    return false
end

function LibramSwap_ApplySelection(spellName, libramName)
    if not spellName then return end
    -- normalize spellName and libramName (trim ASCII spaces) to avoid key mismatches
    local function trim(s)
        if type(s) ~= "string" then return s end
        return string_gsub(s, "^%s*(.-)%s*$", "%1")
    end
    spellName = trim(spellName)
    libramName = (libramName ~= nil) and trim(libramName) or libramName
    BuildBagIndex()
    perSpellHasSwapped[spellName] = nil
    perSpellLastSwap[spellName] = nil
    lastSwapTime = 0
    LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
    LibramSwapDB.map = (type(LibramSwapDB.map) == "table") and LibramSwapDB.map or {}
        if not libramName or libramName == "None" then
            -- user explicitly cleared the selection; persist a sentinel so this overrides defaults on reload
            local prev = LibramMap[spellName]
            LibramMap[spellName] = nil
            LibramSwapDB.map[spellName] = "__NONE__"
            UserSelections[spellName] = true
            -- remove the previously watched libram (if any) and update bag index
            if prev and WatchedNames[prev] then WatchedNames[prev] = nil end
            BuildBagIndex()
            -- update backup
            SavedMapBackup = deepCopy(LibramSwapDB.map)
            return
        end
        LibramMap[spellName] = libramName
        LibramSwapDB.map[spellName] = libramName
    -- debug hook: log when key spells are changed so we can diagnose saving issues
    if type(LibramSwapDB) == "table" and LibramSwapDB.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap DEBUG]: ApplySelection saved '"..tostring(spellName).."' -> '"..tostring(libramName).."'|r")
    end
    UserSelections[spellName] = true
    if EquipLibramForSpell then pcall(EquipLibramForSpell, spellName, libramName) end
    -- ensure watched names include this libram
    WatchedNames[libramName] = true
    BuildBagIndex()
    -- keep our backup in sync so watchdog won't restore a previous value
    SavedMapBackup = deepCopy(LibramSwapDB.map)
end

local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_LOGIN")
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:RegisterEvent("BAG_UPDATE")
Frame:RegisterEvent("PLAYER_LOGOUT")
Frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- Ensure bag index is current
        BuildBagIndex()
        -- If the saved-variables contain an explicit profile selection, restore it
        if type(LibramSwapDB) == "table" and type(LibramSwapDB.profiles) == "table" then
            -- prefer explicit selectedProfile, else fall back to lastUsedProfile, else auto-load the only profile if there is exactly one
            local pname = nil
            if type(LibramSwapDB.selectedProfile) == "string" then pname = LibramSwapDB.selectedProfile
            elseif type(LibramSwapDB.lastUsedProfile) == "string" then pname = LibramSwapDB.lastUsedProfile
            else
                -- if only one profile exists, use it
                local cnt = 0
                for k,_ in pairs(LibramSwapDB.profiles) do cnt = cnt + 1; pname = k end
                if cnt ~= 1 then pname = nil end
            end
            if pname and type(LibramSwapDB.profiles[pname]) == "table" then
                local payload = LibramSwapDB.profiles[pname]
                -- mark selectedProfile so UI reflects it
                LibramSwapDB.selectedProfile = pname
                -- apply profile payload
                if type(payload) == "table" then
                    if type(payload.map) == "table" then
                        -- Apply each profile entry via the core API so persistence and watchdog backup stay consistent
                        for k,v in pairs(payload.map) do
                            if type(LibramSwap_ApplySelection) == "function" then
                                pcall(LibramSwap_ApplySelection, k, v)
                            else
                                LibramSwapDB.map = LibramSwapDB.map or {}
                                LibramSwapDB.map[k] = v
                                LibramMap[k] = v
                            end
                        end
                        LibramSwapDB.map = deepCopy(payload.map)
                        SavedMapBackup = deepCopy(LibramSwapDB.map)
                        for k,_ in pairs(LibramSwapDB.map) do UserSelections[k] = true end
                    end
                    if type(payload.enabledMap) == "table" then
                        LibramSwapDB.enabledMap = deepCopy(payload.enabledMap)
                    end
                    if type(payload.spells) == "table" then
                        LibramSwapDB.spells = deepCopy(payload.spells)
                    end
                end
                -- Always show confirmation when profile is auto-loaded (visible to user)
                DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Profile '"..tostring(pname).."' loaded at login.|r")
            end
        end
        -- If there's a non-profile saved map (last-used choices), merge only the user's selections
        if type(LibramSwapDB) == "table" and type(LibramSwapDB.map) == "table" then
            -- sanitize any legacy 'Auto' markers so Consecration must be chosen explicitly
            local saved = deepCopy(LibramSwapDB.map)
            local sanitized = {}
            for k,v in pairs(saved) do
                if not (type(v) == "string" and string.lower(v) == "auto") then sanitized[k] = v end
            end
            -- overlay sanitized saved choices onto runtime map (do not overwrite defaults for missing keys)
            for k,v in pairs(sanitized) do
                if v == "__NONE__" then
                    LibramMap[k] = nil
                    UserSelections[k] = true
                else
                    LibramMap[k] = v
                    UserSelections[k] = true
                end
            end
            -- persist only the sanitized user selections back to savedvariables (avoid writing defaults)
            LibramSwapDB.map = deepCopy(sanitized)
        end
        -- rebuild watched names and bag index to reflect any restored choices
        for k in pairs(WatchedNames) do WatchedNames[k] = nil end
        for _, name in pairs(LibramMap) do if type(name) == "string" then WatchedNames[name] = true end end
        -- Ensure the global mapping table visible to the config UI matches runtime
        _G.LibramMap = LibramMap
        BuildBagIndex()
    elseif event == "BAG_UPDATE" then
        BuildBagIndex()
    elseif event == "PLAYER_LOGOUT" then
        -- savedvariables are updated on change by ApplySelection; avoid overwriting user's saved map with full defaults here
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        LibramSwapDB.map = (type(LibramSwapDB.map) == "table") and LibramSwapDB.map or {}
    end
end)

-- lightweight watchdog to detect external overwrites of LibramSwapDB.map
Frame:RegisterEvent("PLAYER_LOGIN")
local last_update = 0
Frame:SetScript("OnUpdate", function(_, elapsed)
    watchdog_acc = watchdog_acc + (elapsed or 0)
    if watchdog_acc < WATCHDOG_INTERVAL then return end
    watchdog_acc = 0
    -- compare saved map to our backup; if different and user selections exist, restore
    if type(LibramSwapDB) ~= "table" then LibramSwapDB = {} end
    local cur = (type(LibramSwapDB.map) == "table") and LibramSwapDB.map or {}
    if not mapsEqual(cur, SavedMapBackup) then
        -- if we've recorded user selections, restore only those keys
        local changed = false
        for k,_ in pairs(UserSelections) do
            local expected = SavedMapBackup[k]
            local actual = cur[k]
            if expected ~= actual then
                cur[k] = expected
                changed = true
            end
        end
        if changed then
            LibramSwapDB.map = cur
            -- also restore runtime view (respect '__NONE__' sentinel)
            for k,v in pairs(cur) do
                if v == "__NONE__" then
                    LibramMap[k] = nil
                else
                    LibramMap[k] = v
                end
            end
            SavedMapBackup = deepCopy(cur)
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: Detected external change to saved map; restored user selections.|r")
        else
            -- update our backup to match current if nothing to restore
            SavedMapBackup = deepCopy(cur)
        end
    end
end)

local Original_CastSpellByName = CastSpellByName
function CastSpellByName(spellName, bookType)
    if LibramSwapDB.enabled then
        local base = SplitNameAndRank(spellName)
        local libram = ResolveLibramForSpell(base)
        if libram and IsSpellReady(spellName) then
            if base == "Judgement" then
                local hp = (UnitExists("target") and UnitHealth("target") and UnitHealthMax("target") and (UnitHealth("target")/UnitHealthMax("target")*100)) or nil
                if hp and hp <= 35 then EquipLibramForSpell(base, libram) end
            else
                local ok = EquipLibramForSpell(base, libram)
                if not ok then LogDebug("Failed to equip libram '"..tostring(libram).."' for spell '"..tostring(base).."'.") end
            end
        end
    end
    return Original_CastSpellByName(spellName, bookType)
end

local Orig_CastSpell = CastSpell
function CastSpell(spellIndex, bookType)
    -- treat nil bookType as spellbook usage (some clients call CastSpell(index) without bookType)
    if LibramSwapDB.enabled and (bookType == nil or bookType == BOOKTYPE_SPELL) then
        local name, rank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
        if name then
            local libram = ResolveLibramForSpell(name)
            if libram then
                local spec = (rank and rank ~= "") and (name .. "(" .. rank .. ")") or name
                    if IsSpellReady(spec) then
                        local ok = EquipLibramForSpell(name, libram)
                        if not ok then LogDebug("Failed to equip libram '"..tostring(libram).."' for spell '"..tostring(name).."' (book cast).") end
                    end
            end
        end
    end
    return Orig_CastSpell(spellIndex, bookType)
end
