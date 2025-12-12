if not DEFAULT_CHAT_FRAME or not CreateFrame or not SlashCmdList then
    return
else
    SLASH_LIBRAMCONFIG1 = "/libramconfig"
    SLASH_LIBRAMCONFIG2 = "/libramswapconfig"
    SLASH_LIBRAMDEBUG1 = "/libramdebug"

    -- disable chat traces by default; enable for debugging
    local DEBUG = (type(LibramSwapDB) == "table" and LibramSwapDB.debug) or false

    local frame = CreateFrame("Frame", "LibramSwapConfigFrame", UIParent)
    -- Early sanitization of SavedVariables to avoid indexing non-table values during addon load
    do
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        LibramSwapDB._broken_fields = LibramSwapDB._broken_fields or {}
        local function ensureTableFieldEarly(field)
            local v = LibramSwapDB[field]
            if type(v) ~= "table" then
                if v ~= nil then
                    LibramSwapDB._broken_fields[field] = v
                    if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: Found corrupted top-level field '"..tostring(field).."' ("..type(v).."). Moving to _broken_fields and replacing.|r") end
                end
                LibramSwapDB[field] = {}
            end
        end
        ensureTableFieldEarly("map")
        ensureTableFieldEarly("enabledMap")
        ensureTableFieldEarly("profiles")
    end
    -- utility: deep copy a table (used during initialization before other helpers are defined)
    local function deepCopy(src)
        if type(src) ~= "table" then return src end
        local out = {}
        for k,v in pairs(src) do out[k] = deepCopy(v) end
        return out
    end
    -- Larger frame for better ergonomics, positioned top-center and clamped to screen
    frame:SetWidth(720)
    frame:SetHeight(540)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -100)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = {left=6,right=6,top=6,bottom=6}})
    frame:SetBackdropColor(0,0,0,0.85)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    -- Use the captured `frame` variable instead of `self` to be robust
    -- across clients that do not pass the frame as the first argument.
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    frame:Hide()

    -- Scrollable area for the spell list
    local scroll = CreateFrame("ScrollFrame", "LibramSwap_ScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -96)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 12)
    local content = CreateFrame("Frame", "LibramSwap_ScrollChild", scroll)
    -- adjust content width to fit frame and leave space for indicators
    content:SetWidth(520)
    -- subtle background for the scroll area
    local bg = content:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", content, "TOPLEFT", -8, 8)
    bg:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 8, -8)
    bg:SetTexture("Interface\\DialogFrame\\UI-Panel-Background")
    bg:SetVertexColor(0.06, 0.06, 0.06, 0.6)
    -- compute content height to fit all rows; will be larger than visible area to enable scrolling
    local estimatedRows = 15
    local estimatedRowH = 34
    -- content height will be adjusted after widgets are created (based on actual spell count)
    content:SetHeight(estimatedRows * estimatedRowH + 40)
    content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 8, -8)
    scroll:SetScrollChild(content)

    local header = frame:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetPoint("TOP", frame, "TOP", 0, 16)
    header:SetWidth(720)
    header:SetHeight(64)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("LibramSwap — Configuration")
    title:SetTextColor(0.6, 0.9, 1.0)

    -- Active profile label (shows the profile the addon will load)
    local activeProfileLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    activeProfileLabel:SetPoint("TOP", title, "BOTTOM", 0, -4)
    activeProfileLabel:SetTextColor(0.9, 0.9, 0.6)
    activeProfileLabel:SetText("Active profile: None")

    -- Profile button removed per user request

    -- show decorative header/title for a cleaner look
    header:Show()
    title:Show()

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- Enable Escape key to close (Vanilla-compatible)
    table.insert(UISpecialFrames, "LibramSwapConfigFrame")

    -- Main quick Save and Sorts buttons (top-right, side-by-side)
    local mainSortBtn = CreateFrame("Button", "LibramSwap_SortsBtn", frame, "UIPanelButtonTemplate")
    mainSortBtn:SetWidth(72); mainSortBtn:SetHeight(20)
    mainSortBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -36)
    mainSortBtn:SetText("Sorts")

    local mainSaveBtn = CreateFrame("Button", "LibramSwap_MainSaveBtn", frame, "UIPanelButtonTemplate")
    mainSaveBtn:SetWidth(60); mainSaveBtn:SetHeight(20)
    mainSaveBtn:SetPoint("RIGHT", mainSortBtn, "LEFT", -8, 0)
    mainSaveBtn:SetText("Save")

    -- Consecration controls removed (visual cleanup requested)

    local delayLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    delayLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -44)
    delayLabel:SetText("Delay (seconds):")

    local delayBox = CreateFrame("EditBox", "LibramSwap_DelayBox", frame, "InputBoxTemplate")
    delayBox:SetWidth(64)
    delayBox:SetHeight(20)
    delayBox:SetPoint("LEFT", delayLabel, "RIGHT", 12, 0)
    delayBox:SetAutoFocus(false)
    delayBox:SetText(tostring(((type(LibramSwapDB) == "table") and LibramSwapDB.delay) or 0.02))
    delayBox:SetScript("OnEnterPressed", function()
        local v = tonumber(delayBox:GetText())
        if v then LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}; LibramSwapDB.delay = v; delayBox:ClearFocus() end
    end)
    delayBox:SetScript("OnEditFocusLost", function()
        local v = tonumber(delayBox:GetText())
        if v then LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}; LibramSwapDB.delay = v end
    end)

    -- checkbox to enable/disable using the small delay
    local useDelayChk = CreateFrame("CheckButton", "LibramSwap_UseDelayChk", frame, "UICheckButtonTemplate")
    useDelayChk:SetPoint("LEFT", delayBox, "RIGHT", 12, 0)
    useDelayChk:SetScript("OnClick", function()
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        local c = useDelayChk:GetChecked()
        -- Normalize to boolean (Handle both true/nil and 1/0 returns across clients)
        LibramSwapDB.useDelay = (c == true or c == 1) and true or false
    end)
    local useDelayLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    useDelayLabel:SetPoint("LEFT", useDelayChk, "RIGHT", 6, 0)
    useDelayLabel:SetText("Enable delay")

    -- Debug toggle: persist `LibramSwapDB.debug` so user can enable logging in-game
    local debugChk = CreateFrame("CheckButton", "LibramSwap_DebugChk", frame, "UICheckButtonTemplate")
    debugChk:SetPoint("LEFT", useDelayLabel, "RIGHT", 12, 0)
    debugChk:SetScript("OnClick", function()
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        local c = debugChk:GetChecked()
        LibramSwapDB.debug = (c == true or c == 1) and true or false
    end)
    local debugLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    debugLabel:SetPoint("LEFT", debugChk, "RIGHT", 6, 0)
    debugLabel:SetText("Enable debug")

    -- Slash command handler for quick debug toggle: /libramdebug on|off
    SlashCmdList["LIBRAMDEBUG"] = function(msg)
        local arg = string.lower(tostring(msg or ""))
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        if arg == "on" or arg == "1" or arg == "true" then
            LibramSwapDB.debug = true
            if type(debugChk) == "table" and type(debugChk.SetChecked) == "function" then debugChk:SetChecked(true) end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Debug enabled.|r")
        elseif arg == "off" or arg == "0" or arg == "false" then
            LibramSwapDB.debug = false
            if type(debugChk) == "table" and type(debugChk.SetChecked) == "function" then debugChk:SetChecked(false) end
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8888[LibramSwap]: Debug disabled.|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[LibramSwap]: Usage: /libramdebug on|off|1|0|true|false|r")
        end
    end

    -- Slash command to check which profile is currently active
    SlashCmdList["LIBRAMPROFILE"] = function()
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        local current = LibramSwapDB.selectedProfile or LibramSwapDB.lastUsedProfile or "None"
        local spellCount = (type(LibramSwapDB.spells) == "table") and table.getn(LibramSwapDB.spells) or 0
        DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Active profile: '"..tostring(current).."' ("..tostring(spellCount).." spells)|r")
    end
    SLASH_LIBRAMPROFILE1 = "/libramprofile"

    -- consecration label removed (visual cleanup)

    local defaultSpells = {
        "Holy Light","Flash of Light","Holy Strike","Seal of Righteousness","Seal of the Crusader","Cleanse","Blessing of Wisdom","Blessing of Might",
        "Greater Blessing of Light","Hammer of Justice","Greater Blessing of Sanctuary","Consecration",
        "Seal of Wisdom","Judgement","Greater Blessing of Wisdom","Devotion Aura","Blessing of Salvation","Blessing of Kings",
        "Holy Shield","Hand of Freedom"
    }
    -- Start with EMPTY spell list - user adds spells via Sorts Manager
    LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
    if type(LibramSwapDB.spells) ~= "table" then
        LibramSwapDB.spells = {}
    end
    -- defaultSpells is used in Sorts Manager as the pool of available spells

    local libramOptions = {
        "None",
        "Libram of the Faithful","Libram of the Farraki Zealot","Libram of Radiance","Libram of Light",
        "Libram of Grace","Libram of the Dreamguard","Libram of the Justicar","Libram of the Resolute",
        "Libram of the Eternal Tower","Libram of Final Judgement","Libram of Hope","Libram of Fervor",
        "Libram of Truth","Libram of Veracity","Libram of Divinity"
    }

    -- Backdrop that closes the picker when clicking outside
    local pickerBackdrop = CreateFrame("Frame", "LibramSwap_PickerBackdrop", UIParent)
    pickerBackdrop:SetAllPoints(UIParent)
    pickerBackdrop:EnableMouse(true)
    pickerBackdrop:Hide()

    -- Popup picker frame (simple custom list to avoid UIDropDownMenu fragility)
    -- Popup picker frame (scrollable custom list with a Close button)
    local picker = CreateFrame("Frame", "LibramSwap_Picker", UIParent)
    picker:SetWidth(220)
    local totalHeight = (table.getn(libramOptions) * 20) + 8
    local maxVisible = 200
    local visibleHeight = (totalHeight > maxVisible) and maxVisible or totalHeight
    picker:SetHeight(visibleHeight + 30) -- leave room for Close button
    picker:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 8, insets = {left=6,right=6,top=6,bottom=6}})
    picker:SetBackdropColor(0,0,0,0.95)
    picker:Hide()
    picker:SetFrameStrata("DIALOG")
    picker.buttons = {}

    -- scroll frame and content for the options
    local pScroll = CreateFrame("ScrollFrame", "LibramSwap_PickerScroll", picker, "UIPanelScrollFrameTemplate")
    pScroll:SetPoint("TOPLEFT", picker, "TOPLEFT", 8, -8)
    pScroll:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -28, -8)
    pScroll:SetHeight(visibleHeight)
    local pContent = CreateFrame("Frame", nil, pScroll)
    pContent:SetWidth(200)
    pContent:SetHeight(totalHeight)
    pScroll:SetScrollChild(pContent)

    for i,opt in ipairs(libramOptions) do
        local choice = opt
        local b = CreateFrame("Button", nil, pContent, "UIPanelButtonTemplate")
        b:SetHeight(18)
        b:SetWidth(200)
        b:SetPoint("TOPLEFT", pContent, "TOPLEFT", 0, -((i-1)*20) -4)
        b:SetText(choice)
        b:SetScript("OnClick", function()
            local sel = choice
            local spell = picker._spell
            -- Prefer the core ApplySelection API which persists and updates runtime state safely
            if type(LibramSwap_ApplySelection) == "function" then
                local ok, err = pcall(LibramSwap_ApplySelection, spell, (sel == "None") and nil or sel)
                if ok then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Selection saved for '"..tostring(spell).."' -> '"..tostring(sel).."'.|r")
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Error saving selection: "..tostring(err).."|r")
                end
            else
                -- Fallback: persist only the single key to savedvariables (do not overwrite the whole map)
                LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
                LibramSwapDB.map = (type(LibramSwapDB.map) == "table") and LibramSwapDB.map or {}
                LibramSwapDB.map[spell] = (sel == "None") and "__NONE__" or sel
                DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Selection saved for '"..tostring(spell).."' -> '"..tostring(sel).."'. (fallback)|r")
            end
            local bbtn = dropdowns and dropdowns[spell]
            if bbtn and bbtn.text then bbtn.text:SetText("  " .. (sel or "None")) end
            local ind = indicators and indicators[spell]
            local present = false
            if sel and sel ~= "None" and LibramSwap_HasItem then present = LibramSwap_HasItem(sel) end
            if ind and ind.tex then ind.tex:SetTexture(present and 0 or 1, present and 1 or 0, 0, 1) end
            picker:Hide(); pickerBackdrop:Hide()
            if frame and frame.Hide and frame.Show then frame:Hide(); frame:Show() end
        end)
        picker.buttons[i] = b
    end

    -- Close button
    local pClose = CreateFrame("Button", nil, picker, "UIPanelButtonTemplate")
    pClose:SetHeight(20); pClose:SetWidth(60)
    pClose:SetPoint("BOTTOM", picker, "BOTTOM", 0, 6)
    pClose:SetText("Close")
    pClose:SetScript("OnClick", function() picker:Hide(); pickerBackdrop:Hide() end)

    -- Backdrop click handler - will be enhanced after frames are created
    pickerBackdrop:SetScript("OnMouseDown", function()
        picker:Hide()
        if sortsFrame then sortsFrame:Hide() end
        if profileFrame then profileFrame:Hide() end
        pickerBackdrop:Hide()
    end)
    picker:SetScript("OnHide", function() pickerBackdrop:Hide() end)

    -- Ensure mouse-wheel works for the picker scroll
    pScroll:EnableMouseWheel(true)
    pScroll:SetScript("OnMouseWheel", function(_, delta)
        -- guard against nil delta (older clients or environments may not pass it)
        local d = delta or arg1 or -1
        if type(d) ~= "number" then d = tonumber(d) or -1 end
        local cur = pScroll:GetVerticalScroll() or 0
        local step = 40
        local maxScroll = 0
        if pScroll.GetVerticalScrollRange then
            maxScroll = pScroll:GetVerticalScrollRange()
        else
            local height = pContent and (pContent:GetHeight() or 0) or 0
            local viewH = pScroll and (pScroll:GetHeight() or 0) or 0
            maxScroll = math.max(0, height - viewH)
        end
        local new = cur - (d * step)
        if new < 0 then new = 0 end
        if new > maxScroll then new = maxScroll end
        pScroll:SetVerticalScroll(new)
    end)

    local function ShowLibramPicker(targetBtn, spell)
        picker._spell = spell
        picker:ClearAllPoints()
        picker:SetPoint("TOPLEFT", targetBtn, "BOTTOMLEFT", 0, -4)
        -- simple clamp: if the picker would go off bottom of screen, anchor above the button
        local top = picker:GetTop()
        if not top or top < 20 then
            picker:ClearAllPoints(); picker:SetPoint("BOTTOMLEFT", targetBtn, "TOPLEFT", 0, 4)
        end
        pickerBackdrop:Show()
        picker:Show()
        -- reset scroll to top
        if pScroll and pScroll.SetVerticalScroll then pScroll:SetVerticalScroll(0) end
    end

    local dropdowns = {}
    local indicators = {}
    local checks = {}
    local selectedProfile = nil
    local profileButtonsByName = {}
    
    -- Forward declarations for frames and functions created later
    local sortsFrame, profileFrame
    local rebuildSpellList, refreshProfiles, updateActiveProfileLabel

    -- Profiles UI: small popup to manage named profiles
    LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
    -- ensure profiles is a table; if it's corrupted (non-table), reset it
    if type(LibramSwapDB) ~= "table" or type(LibramSwapDB.profiles) ~= "table" then LibramSwapDB.profiles = {} end

    local function deepCopy(src)
        if type(src) ~= "table" then return src end
        local out = {}
        for k,v in pairs(src) do out[k] = deepCopy(v) end
        return out
    end

    -- sanitize profiles: remove non-table entries and coerce/clean subfields
    local function sanitizeProfiles()
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        LibramSwapDB._broken_profiles = LibramSwapDB._broken_profiles or {}
        LibramSwapDB._broken_fields = LibramSwapDB._broken_fields or {}

        -- If the top-level `profiles` field itself is corrupted (not a table), preserve it and replace
        if type(LibramSwapDB.profiles) ~= "table" then
            if LibramSwapDB.profiles ~= nil then
                LibramSwapDB._broken_fields.profiles = LibramSwapDB.profiles
                if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: Detected corrupted top-level 'profiles' ("..type(LibramSwapDB.profiles).."). Moved to _broken_fields.profiles and replaced.|r") end
            end
            LibramSwapDB.profiles = {}
            return
        end

        local removed = 0
        -- iterate safely over profiles; if pairs fails unexpectedly, catch it
        local ok, err = pcall(function()
            for name, payload in pairs(LibramSwapDB.profiles) do
                if type(payload) ~= "table" then
                    -- preserve broken entries for inspection instead of permanent deletion
                    LibramSwapDB._broken_profiles[name] = payload
                    LibramSwapDB.profiles[name] = nil
                    removed = removed + 1
                else
                    if type(payload.map) ~= "table" then payload.map = {} end
                    if type(payload.enabledMap) ~= "table" then payload.enabledMap = {} end
                    if type(payload.delay) ~= "number" then payload.delay = nil end
                    if payload.useDelay ~= true then payload.useDelay = false end
                    if type(payload.consecrationMode) ~= "string" then payload.consecrationMode = nil end
                end
            end
        end)
        if not ok then
            if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Error iterating profiles: "..tostring(err).." — resetting profiles storage.|r") end
            LibramSwapDB._broken_fields.profiles_iter_error = tostring(err)
            LibramSwapDB.profiles = {}
            return
        end

        if removed > 0 then
            if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: Moved " .. tostring(removed) .. " corrupted profile(s) to _broken_profiles.|r") end
        end
    end

    -- sanitize immediately so UI actions (save/load) don't index corrupted savedvariables
    sanitizeProfiles()

    local profileFrame = CreateFrame("Frame", "LibramSwap_ProfileFrame", UIParent)
    profileFrame:SetWidth(420)
    profileFrame:SetHeight(300)
    profileFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 8, insets = {left=6,right=6,top=6,bottom=6}})
    profileFrame:SetBackdropColor(0,0,0,0.95)
    profileFrame:SetFrameStrata("DIALOG")
    profileFrame:Hide()
    -- make the profile popup movable and keep it on-screen
    profileFrame:SetMovable(true)
    profileFrame:EnableMouse(true)
    profileFrame:RegisterForDrag("LeftButton")
    profileFrame:SetScript("OnDragStart", function() profileFrame:StartMoving() end)
    profileFrame:SetScript("OnDragStop", function()
        if profileFrame.StopMoving then
            profileFrame:StopMoving()
        elseif profileFrame.StopMovingOrSizing then
            profileFrame:StopMovingOrSizing()
        end
        -- save last position so the user keeps their placement
        local point, relTo, relPoint, x, y = profileFrame:GetPoint()
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        LibramSwapDB.profilePos = { point = point or "CENTER", relPoint = relPoint or "CENTER", x = x or 0, y = y or 0 }
    end)
    profileFrame:SetClampedToScreen(true)

    -- Enable Escape key to close (Vanilla-compatible)
    table.insert(UISpecialFrames, "LibramSwap_ProfileFrame")
    
    -- Add OnHide handler to close backdrop
    profileFrame:SetScript("OnHide", function() pickerBackdrop:Hide() end)

    local pfTitle = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pfTitle:SetPoint("TOP", profileFrame, "TOP", 0, -10)
    pfTitle:SetText("LibramSwap Profiles")

    local nameLabel = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 12, -40)
    nameLabel:SetText("Profile name:")

    local nameBox = CreateFrame("EditBox", "LibramSwap_ProfileName", profileFrame, "InputBoxTemplate")
    nameBox:SetWidth(160); nameBox:SetHeight(20)
    nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 8, 0)
    nameBox:SetAutoFocus(false)

    -- safe setter for the profile name editbox (fallback to global named EditBox)
    local function setProfileName(text)
        local edit = nameBox
        if type(edit) ~= "table" or type(edit.SetText) ~= "function" then
            edit = _G and _G["LibramSwap_ProfileName"] or nil
        end
        if type(edit) == "table" and type(edit.SetText) == "function" then
            pcall(edit.SetText, edit, tostring(text or ""))
            return true
        end
        return false
    end

    -- safe getter for the profile name editbox (trim spaces)
    local function safeGetName()
        local ok, res = pcall(function()
            -- prefer local nameBox, but fall back to global named EditBox if corrupted
            local edit = nameBox
            if type(edit) ~= "table" or type(edit.GetText) ~= "function" then
                edit = _G and _G["LibramSwap_ProfileName"] or nil
            end
            local raw = ""
            if type(edit) == "table" and type(edit.GetText) == "function" then
                raw = edit:GetText() or ""
            end
            raw = tostring(raw or "")
            -- manual trim of ASCII spaces
            local i = 1
            local j = string.len(raw or "")
            while i <= j and raw:sub(i,i) == " " do i = i + 1 end
            while j >= i and raw:sub(j,j) == " " do j = j - 1 end
            if i > j then return "" end
            return raw:sub(i, j)
        end)
        if not ok then return "" end
        return tostring(res or "")
    end

    -- First row: Create, Save, Load
    local createBtn = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    createBtn:SetWidth(80); createBtn:SetHeight(22)
    createBtn:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 0, -8)
    createBtn:SetText("Create")

    local saveBtn = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    saveBtn:SetWidth(80); saveBtn:SetHeight(22)
    saveBtn:SetPoint("LEFT", createBtn, "RIGHT", 8, 0)
    saveBtn:SetText("Save")

    local loadBtn = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    loadBtn:SetWidth(80); loadBtn:SetHeight(22)
    loadBtn:SetPoint("LEFT", saveBtn, "RIGHT", 8, 0)
    loadBtn:SetText("Load")

    -- Second row: Rename, Delete
    local renameBtn = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    renameBtn:SetWidth(80); renameBtn:SetHeight(22)
    renameBtn:SetPoint("TOPLEFT", createBtn, "BOTTOMLEFT", 0, -6)
    renameBtn:SetText("Rename")

    local delBtn = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    delBtn:SetWidth(80); delBtn:SetHeight(22)
    delBtn:SetPoint("LEFT", renameBtn, "RIGHT", 8, 0)
    delBtn:SetText("Delete")

    -- Close button top-right
    local closePf = CreateFrame("Button", nil, profileFrame, "UIPanelCloseButton")
    closePf:SetPoint("TOPRIGHT", profileFrame, "TOPRIGHT", -4, -4)
    closePf:SetScript("OnClick", function() profileFrame:Hide(); pickerBackdrop:Hide() end)

    renameBtn:SetScript("OnClick", function()
        local newName = safeGetName()
        if not newName or newName == "" then if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: Enter a new profile name to rename.|r") end return end
        if not selectedProfile or selectedProfile == "" then if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: No profile selected to rename.|r") end return end
        if newName == selectedProfile then if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: New name is the same as the current name.|r") end return end
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        LibramSwapDB.profiles = (type(LibramSwapDB.profiles) == "table") and LibramSwapDB.profiles or {}
        if LibramSwapDB.profiles[newName] then
            if type(StaticPopup_Show) == "function" then StaticPopup_Show("LIBRAMSWAP_OVERWRITE", newName, nil, newName); return end
        end
        -- perform rename by copying payload then deleting old key
        local payload = deepCopy(LibramSwapDB.profiles[selectedProfile] or {})
        LibramSwapDB.profiles[newName] = payload
        LibramSwapDB.profiles[selectedProfile] = nil
        selectedProfile = newName
        LibramSwapDB.selectedProfile = newName
        LibramSwapDB.lastUsedProfile = newName
        pcall(function() setProfileName("") end)
        refreshProfiles()
        if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Renamed profile to '"..tostring(newName).."'.|r") end
    end)

    -- list of existing profiles (simple scroll area)
    local pScroll = CreateFrame("ScrollFrame", "LibramSwap_ProfilesScroll", profileFrame, "UIPanelScrollFrameTemplate")
    -- place the profile list under the name/buttons row (2 rows now)
    pScroll:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 12, -145)
    pScroll:SetPoint("BOTTOMRIGHT", profileFrame, "BOTTOMRIGHT", -36, 12)
    local pContent = CreateFrame("Frame", nil, pScroll)
    -- wider for nicer button layout
    pContent:SetWidth(320)
    pContent:SetHeight(160)
    pScroll:SetScrollChild(pContent)

    local profileButtons = {}

    refreshProfiles = function()
        -- clear existing buttons
        for i,btn in ipairs(profileButtons) do btn:Hide(); btn:SetParent(nil) end
        profileButtons = {}
        profileButtonsByName = {}

        -- iterate profiles defensively; if something is corrupted, reset safely
        local ok, err = pcall(function()
            local i = 0
            local profiles = (type(LibramSwapDB) == "table" and type(LibramSwapDB.profiles) == "table") and LibramSwapDB.profiles or {}
                for name,_ in pairs(profiles) do
                    local pname = tostring(name)
                i = i + 1
                local btn = CreateFrame("Button", nil, pContent, "UIPanelButtonTemplate")
                btn:SetHeight(18); btn:SetWidth(200)
                btn:SetPoint("TOPLEFT", pContent, "TOPLEFT", 0, -((i-1)*20) -4)
                -- highlight texture (hidden by default)
                btn.hl = btn:CreateTexture(nil, "OVERLAY")
                btn.hl:SetAllPoints()
                btn.hl:SetTexture("Interface\\Buttons\\WHITE8X8")
                btn.hl:SetVertexColor(1, 0.85, 0, 0.25)
                btn.hl:Hide()
                -- Ensure the button has a FontString to display its text. Some button templates
                -- expose the fontstring via :GetFontString(); do not assume a `text` field exists.
                -- Ensure the button has a FontString to display its text before calling SetText.
                local fs = btn.GetFontString and btn:GetFontString()
                if not fs or type(fs.SetParent) ~= "function" then
                    fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    fs:SetAllPoints()
                    fs:SetJustifyH("CENTER")
                    btn:SetFontString(fs)
                else
                    fs:SetJustifyH("CENTER")
                end
                    btn:SetText(pname)
                    -- if this profile was previously selected, show its highlight
                    if selectedProfile and tostring(selectedProfile) == pname then
                        if btn.hl then btn.hl:Show() end
                    end
                btn:SetScript("OnClick", function()
                    -- select this profile
                        selectedProfile = pname
                        -- persist the selection so it can be restored after /reload
                        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
                        LibramSwapDB.selectedProfile = pname
                        -- also mark as last-used so it auto-loads on next login
                        LibramSwapDB.lastUsedProfile = pname
                        if type(GetTime) == "function" then LibramSwapDB.lastUsedTime = GetTime() end
                        pcall(function() setProfileName(pname) end)
                            pcall(updateActiveProfileLabel)
                    -- update highlights
                    for _, b in ipairs(profileButtons) do if b.hl then b.hl:Hide() end end
                    if btn.hl then btn.hl:Show() end
                end)
                profileButtons[i] = btn
                    profileButtonsByName[pname] = btn
            end
            pContent:SetHeight(math.max(120, (table.getn(profileButtons) * 20) + 8))
        end)
        if not ok then
            if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Error refreshing profiles: "..tostring(err).." — clearing profile list to avoid crash.|r") end
            LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
            LibramSwapDB._broken_fields = LibramSwapDB._broken_fields or {}
            LibramSwapDB._broken_fields.profiles_refresh_error = tostring(err)
            LibramSwapDB.profiles = {}
            profileButtons = {}
            pContent:SetHeight(120)
        end
    end

    updateActiveProfileLabel = function()
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        local cur = (type(LibramSwapDB.selectedProfile) == "string") and LibramSwapDB.selectedProfile or ((type(LibramSwapDB.lastUsedProfile) == "string") and LibramSwapDB.lastUsedProfile or nil)
        if cur and cur ~= "" then
            activeProfileLabel:SetText("Active profile: " .. tostring(cur))
        else
            activeProfileLabel:SetText("Active profile: None")
        end
    end

    local function saveProfile(name)
        if not name or name == "" then return end
        -- sanitize and coerce savedvariables before touching them
        local okSan, sanErr = pcall(sanitizeProfiles)
        if not okSan then if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: sanitizeProfiles failed: "..tostring(sanErr).."|r") end end
        local db = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        -- coerce primary tables to safe defaults
        if type(db.profiles) ~= "table" then db.profiles = {} end
        if type(db.map) ~= "table" then db.map = {} end
        if type(db.enabledMap) ~= "table" then db.enabledMap = {} end
        local profiles = db.profiles
        -- safe existing check without indexing if profiles is not a table
        local existing = (type(profiles) == "table") and profiles[name] or nil
        if type(existing) == "table" then
            if type(StaticPopup_Show) == "function" then
                StaticPopup_Show("LIBRAMSWAP_OVERWRITE", name, nil, name)
                return
            end
        end
        -- copy relevant settings defensively
        local payload = {}
        payload.map = (type(db.map) == "table") and deepCopy(db.map) or {}
        payload.enabledMap = (type(db.enabledMap) == "table") and deepCopy(db.enabledMap) or {}
        payload.spells = (type(db.spells) == "table") and deepCopy(db.spells) or {}
        payload.delay = (type(db.delay) == "number") and db.delay or nil
        payload.useDelay = (db.useDelay == true) and true or false
        payload.consecrationMode = (type(db.consecrationMode) == "string") and db.consecrationMode or nil
        -- write back safely
        if type(profiles) ~= "table" then profiles = {} end
        profiles[name] = payload
        db.profiles = profiles
        LibramSwapDB = db
        refreshProfiles()
    end

    -- Safer variant of saveProfile that constructs payloads from guarded copies
    local function safeSaveProfile(name)
        if not name or name == "" then return end
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        LibramSwapDB._broken_fields = LibramSwapDB._broken_fields or {}
        local db = LibramSwapDB

        -- Ensure primary containers are safe tables, preserve originals if corrupted
        if type(db.map) ~= "table" then if db.map ~= nil then db._broken_fields.map = db.map end db.map = {} end
        if type(db.enabledMap) ~= "table" then if db.enabledMap ~= nil then db._broken_fields.enabledMap = db.enabledMap end db.enabledMap = {} end
        if type(db.profiles) ~= "table" then if db.profiles ~= nil then db._broken_fields.profiles = db.profiles end db.profiles = {} end

        -- Build safe shallow copies
        local safeMap = {}
        for k,v in pairs(db.map or {}) do safeMap[k] = v end
        local safeEnabled = {}
        for k,v in pairs(db.enabledMap or {}) do safeEnabled[k] = v end

        local payload = {}
        payload.map = deepCopy(safeMap)
        payload.enabledMap = deepCopy(safeEnabled)
        payload.spells = deepCopy((type(db.spells) == "table") and db.spells or {})
        payload.delay = (type(db.delay) == "number") and db.delay or nil
        payload.useDelay = (db.useDelay == true) and true or false
        payload.consecrationMode = (type(db.consecrationMode) == "string") and db.consecrationMode or nil

        db.profiles = db.profiles or {}
        db.profiles[name] = payload
        LibramSwapDB = db
        -- mark this profile as the last-used so addon can auto-load it
        LibramSwapDB.selectedProfile = name
        LibramSwapDB.lastUsedProfile = name
        if type(GetTime) == "function" then LibramSwapDB.lastUsedTime = GetTime() end
        -- Always show save confirmation to user
        DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Profile '"..tostring(name).."' saved successfully.|r")
        -- refresh UI list
        refreshProfiles()
    end

    -- attach Create handler after safeSaveProfile is in scope
    if createBtn then
        createBtn:SetScript("OnClick", function()
            -- prefer user-entered name if present, otherwise auto-generate
            local name = nil
            -- try to read from the editbox directly (safe fallback if safeGetName not defined yet)
            local okRead, txt = pcall(function()
                local edit = nameBox
                if type(edit) ~= "table" or type(edit.GetText) ~= "function" then edit = _G and _G["LibramSwap_ProfileName"] or nil end
                if type(edit) == "table" and type(edit.GetText) == "function" then return tostring(string.gsub((edit:GetText() or ""), "^%s*(.-)%s*$", "%1")) end
                return ""
            end)
            if okRead and txt and txt ~= "" then name = txt end
            LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
            LibramSwapDB.profiles = (type(LibramSwapDB.profiles) == "table") and LibramSwapDB.profiles or {}
            if not name or name == "" then
                local base = "Profile"
                local idx = 1
                name = base .. " " .. tostring(idx)
                while LibramSwapDB.profiles[name] do
                    idx = idx + 1
                    name = base .. " " .. tostring(idx)
                end
            end
            -- if the profile already exists, confirm overwrite
            if LibramSwapDB.profiles and LibramSwapDB.profiles[name] then
                if type(StaticPopup_Show) == "function" then StaticPopup_Show("LIBRAMSWAP_OVERWRITE", name, nil, name); return end
            end
            local ok, err = pcall(safeSaveProfile, name)
            if not ok then
                if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Failed to create profile: "..tostring(err).."|r") end
                return
            end
            -- populate the name box for user clarity and refresh list
            pcall(function() setProfileName(name) end)
            -- focus and highlight the name box so user can rename immediately
            pcall(function()
                local edit = nameBox
                if type(edit) ~= "table" or type(edit.SetFocus) ~= "function" then edit = _G and _G["LibramSwap_ProfileName"] or nil end
                if type(edit) == "table" and type(edit.SetFocus) == "function" then
                    edit:SetFocus()
                    if type(edit.HighlightText) == "function" then pcall(edit.HighlightText, edit, 0, -1) end
                end
            end)
            selectedProfile = name
            -- update highlights
            for _, b in ipairs(profileButtons) do if b.hl then b.hl:Hide() end end
            if profileButtonsByName and profileButtonsByName[name] and profileButtonsByName[name].hl then profileButtonsByName[name].hl:Show() end
            if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Created profile '"..tostring(name).."'|r") end
            -- persist this profile as the last-used profile
            LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
            LibramSwapDB.selectedProfile = name
            LibramSwapDB.lastUsedProfile = name
            if type(GetTime) == "function" then LibramSwapDB.lastUsedTime = GetTime() end
            pcall(refreshProfiles)
        end)
    end

    local function loadProfile(name)
        if not name or name == "" then return end
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        local payload = (type(LibramSwapDB) == "table" and type(LibramSwapDB.profiles) == "table") and LibramSwapDB.profiles[name] or nil
        if not payload or type(payload) ~= "table" then
            if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Profile '" .. tostring(name) .. "' is invalid or missing.|r") end
            return
        end
        -- Validate payload subfields to avoid indexing non-table values
        LibramSwapDB.map = deepCopy((type(payload.map) == "table") and payload.map or {})
        LibramSwapDB.enabledMap = deepCopy((type(payload.enabledMap) == "table") and payload.enabledMap or {})
        LibramSwapDB.spells = deepCopy((type(payload.spells) == "table") and payload.spells or {})
        LibramSwapDB.delay = (type(payload.delay) == "number") and payload.delay or nil
        LibramSwapDB.useDelay = (payload.useDelay == true) and true or false
        LibramSwapDB.consecrationMode = (type(payload.consecrationMode) == "string") and payload.consecrationMode or nil
        
        -- Debug: show what mappings were loaded
        if DEBUG then
            local mapCount = 0
            for k,v in pairs(LibramSwapDB.map or {}) do
                mapCount = mapCount + 1
                DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap DEBUG]: Loaded mapping '"..tostring(k).."' -> '"..tostring(v).."'|r")
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap DEBUG]: Total mappings loaded: "..tostring(mapCount).."|r")
        end
        
        -- update runtime mapping and UI by applying selections via core API so persistence and backups are handled
        if not LibramMap then LibramMap = {} end
        -- clear existing runtime selections that are user-owned
        for k,_ in pairs(LibramSwapDB.map or {}) do LibramMap[k] = nil end
        if type(payload.map) == "table" then
            for k,v in pairs(payload.map) do
                if type(LibramSwap_ApplySelection) == "function" then
                    pcall(LibramSwap_ApplySelection, k, v)
                else
                    -- fallback: set individual keys safely
                    LibramSwapDB.map = LibramSwapDB.map or {}
                    LibramSwapDB.map[k] = v
                    LibramMap[k] = v
                end
            end
        end
        -- persist the selected profile and mark it as last-used so it auto-loads on next login
        selectedProfile = name
        LibramSwapDB.selectedProfile = name
        LibramSwapDB.lastUsedProfile = name
        if type(GetTime) == "function" then LibramSwapDB.lastUsedTime = GetTime() end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Profile '"..tostring(name).."' loaded.|r")
        pcall(updateActiveProfileLabel)
        pcall(rebuildSpellList)
        if frame and frame.Hide and frame.Show then frame:Hide(); frame:Show() end
    end

    local function deleteProfile(name)
        if not name or name == "" then return end
        local db = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        if type(db.profiles) ~= "table" then return end
        local profiles = db.profiles
        if not profiles[name] then return end
        -- confirm delete via StaticPopup if available, otherwise delete immediately
        if type(StaticPopup_Show) == "function" then
            StaticPopup_Show("LIBRAMSWAP_DELETE", name, nil, name)
            return
        end
        -- remove profile payload
        local payload = profiles[name]
        profiles[name] = nil
        db.profiles = profiles
        -- if this profile contributed runtime mappings, remove those keys from runtime and saved map
        if type(payload) == "table" and type(payload.map) == "table" then
            LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
            LibramSwapDB.map = (type(LibramSwapDB.map) == "table") and LibramSwapDB.map or {}
            for k,_ in pairs(payload.map) do
                LibramSwapDB.map[k] = nil
                if type(LibramMap) == "table" then LibramMap[k] = nil end
            end
        end
        -- if the deleted profile was the selected one, clear selection and last-used markers
        if db.selectedProfile and tostring(db.selectedProfile) == tostring(name) then 
            db.selectedProfile = nil
            db.lastUsedProfile = nil
            selectedProfile = nil
        end
        -- Force write to savedvariables
        LibramSwapDB = db
        -- refresh UI lists and spell list
        if type(DEFAULT_CHAT_FRAME) == "table" and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: Profile '"..tostring(name).."' deleted successfully.|r")
        end
        pcall(refreshProfiles)
        pcall(rebuildSpellList)
        pcall(updateActiveProfileLabel)
    end

    -- safeGetName moved earlier to be available for handlers

    saveBtn:SetScript("OnClick", function()
        local name = safeGetName()
        -- Debug: show what we read from the editbox and current selectedProfile
        pcall(function()
            local s = tostring(name or "")
            local sp = tostring(selectedProfile or "")
            if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[LibramSwap DEBUG]: save called; safeGetName='"..s.."', selectedProfile='"..sp.."'|r") end
        end)
        if (not name or name == "") and selectedProfile then name = selectedProfile end
        if not name or name == "" then
            if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: Please enter a profile name before saving.|r") end
            return
        end
        -- Ensure savedvariables are in sane state before saving
        local okPrep, prepErr = pcall(sanitizeProfiles)
        if not okPrep then if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Error preparing profiles: "..tostring(prepErr).."|r") end end

        local ok, err = pcall(safeSaveProfile, name)
        if not ok then
            if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Failed to save profile: "..tostring(err).."|r") end
            return
        end
        -- Provide clear confirmation and update UI list immediately
        if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Profile saved: '"..tostring(name).."'|r") end
        -- persist selectedProfile so it is restored after reload
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        LibramSwapDB.selectedProfile = name
        LibramSwapDB.lastUsedProfile = name
        if type(GetTime) == "function" then LibramSwapDB.lastUsedTime = GetTime() end
        pcall(function() setProfileName("") end)
        -- refresh the profiles list so the new profile appears
        pcall(refreshProfiles)
    end)

    loadBtn:SetScript("OnClick", function()
        local n = safeGetName()
        if (not n or n == "") and selectedProfile then n = selectedProfile end
        if n ~= "" then
            local okPrep, prepErr = pcall(sanitizeProfiles)
            if not okPrep then if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Error preparing profile load: " .. tostring(prepErr) .. "|r") end end
            local ok, err = pcall(loadProfile, n)
            if not ok then if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Error loading profile: " .. tostring(err) .. "|r") end end
        end
    end)

    delBtn:SetScript("OnClick", function()
        local n = safeGetName()
        if (not n or n == "") and selectedProfile then n = selectedProfile end
        if n ~= "" then
            local okPrep, prepErr = pcall(sanitizeProfiles)
            if not okPrep then if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Error preparing profile delete: " .. tostring(prepErr) .. "|r") end end
            local ok, err = pcall(deleteProfile, n)
            if not ok then if DEBUG then DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Error deleting profile: " .. tostring(err) .. "|r") end end
        end
    end)

    -- static popups for overwrite/delete confirmation
    StaticPopupDialogs = StaticPopupDialogs or {}
    StaticPopupDialogs["LIBRAMSWAP_OVERWRITE"] = {
        text = "Overwrite profile '%s'?",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            -- In Vanilla, popup data is passed via the 4th argument to StaticPopup_Show and available as arg1
            local name = arg1
            if not name and type(StaticPopup1) == "table" and StaticPopup1.data ~= nil then name = StaticPopup1.data end
            if not name then return end
            local db = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
            local profiles = (type(db.profiles) == "table") and db.profiles or {}
            local payload = {}
            payload.map = deepCopy((type(db.map) == "table") and db.map or {})
            payload.enabledMap = deepCopy((type(db.enabledMap) == "table") and db.enabledMap or {})
            payload.spells = deepCopy((type(db.spells) == "table") and db.spells or {})
            payload.delay = db.delay
            payload.useDelay = db.useDelay
            payload.consecrationMode = db.consecrationMode
            profiles[name] = payload
            db.profiles = profiles
            LibramSwapDB = db
            refreshProfiles()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopupDialogs["LIBRAMSWAP_DELETE"] = {
        text = "Delete profile '%s'?",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            -- In Vanilla, popup data is passed via the 4th argument to StaticPopup_Show and available globally
            local name = arg1
            if not name and type(StaticPopup1) == "table" and StaticPopup1.data ~= nil then name = StaticPopup1.data end
            if not name then return end
            local db = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
            if type(db.profiles) == "table" then
                local payload = db.profiles[name]
                db.profiles[name] = nil
                -- if the profile had a map, remove those runtime/saved keys to avoid stale selections
                if type(payload) == "table" and type(payload.map) == "table" then
                    db.map = (type(db.map) == "table") and db.map or {}
                    for k,_ in pairs(payload.map) do
                        db.map[k] = nil
                        if type(LibramMap) == "table" then LibramMap[k] = nil end
                    end
                end
            end
            -- if the deleted profile was the persisted selectedProfile or lastUsedProfile, clear them
            if db.selectedProfile and tostring(db.selectedProfile) == tostring(name) then db.selectedProfile = nil; selectedProfile = nil end
            if db.lastUsedProfile and tostring(db.lastUsedProfile) == tostring(name) then db.lastUsedProfile = nil end
            -- Force the savedvariables write
            LibramSwapDB = db
            LibramSwapDB.profiles = db.profiles
            if type(DEFAULT_CHAT_FRAME) == "table" and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: Profile '"..tostring(name).."' deleted successfully.|r")
            end
            pcall(refreshProfiles)
            pcall(rebuildSpellList)
            pcall(updateActiveProfileLabel)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    -- open/close profile popup (centered by default; user can drag to reposition)
    local function ShowProfilePopup()
        pickerBackdrop:Show()
        profileFrame:ClearAllPoints()
        -- restore saved position if available
        if type(LibramSwapDB) == "table" and type(LibramSwapDB.profilePos) == "table" then
            local p = LibramSwapDB.profilePos
            profileFrame:SetPoint(p.point or "CENTER", UIParent, p.relPoint or "CENTER", p.x or 0, p.y or 0)
        else
            profileFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        profileFrame:Show()
        refreshProfiles()
    end

    -- Hook main frame buttons: Save opens profile popup, Sorts opens the sorts manager
    if mainSaveBtn then mainSaveBtn:SetScript("OnClick", function() ShowProfilePopup() end) end

    -- Build a simple Sorts panel with search + add/remove functionality
    local sortsFrame = CreateFrame("Frame", "LibramSwap_SortsFrame", UIParent)
    sortsFrame:SetWidth(520); sortsFrame:SetHeight(480)
    sortsFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 8, insets = {left=6,right=6,top=6,bottom=6}})
    sortsFrame:SetBackdropColor(0,0,0,0.95)
    sortsFrame:SetFrameStrata("DIALOG")
    sortsFrame:Hide()
    sortsFrame:SetMovable(true); sortsFrame:EnableMouse(true)
    sortsFrame:RegisterForDrag("LeftButton")
    sortsFrame:SetScript("OnDragStart", function() sortsFrame:StartMoving() end)
    sortsFrame:SetScript("OnDragStop", function()
        if sortsFrame.StopMoving then sortsFrame:StopMoving() elseif sortsFrame.StopMovingOrSizing then sortsFrame:StopMovingOrSizing() end
        local point, relTo, relPoint, x, y = sortsFrame:GetPoint()
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        LibramSwapDB.sortsPos = { point = point or "CENTER", relPoint = relPoint or "CENTER", x = x or 0, y = y or 0 }
    end)

    local sfTitle = sortsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sfTitle:SetPoint("TOP", sortsFrame, "TOP", 0, -10)
    sfTitle:SetText("LibramSwap — Sorts Manager")
    sfTitle:SetTextColor(1.0, 0.82, 0)

    local searchLabel = sortsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", sortsFrame, "TOPLEFT", 12, -42)
    searchLabel:SetText("Search:")
    searchLabel:SetTextColor(1.0, 0.82, 0)

    local searchBox = CreateFrame("EditBox", "LibramSwap_SortsSearch", sortsFrame, "InputBoxTemplate")
    searchBox:SetWidth(220); searchBox:SetHeight(20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
    searchBox:SetAutoFocus(false)

    local sortsScroll = CreateFrame("ScrollFrame", "LibramSwap_SortsScroll", sortsFrame, "UIPanelScrollFrameTemplate")
    sortsScroll:SetPoint("TOPLEFT", sortsFrame, "TOPLEFT", 12, -72)
    sortsScroll:SetPoint("BOTTOMRIGHT", sortsFrame, "BOTTOMRIGHT", -36, 12)
    local sortsContent = CreateFrame("Frame", nil, sortsScroll)
    sortsContent:SetWidth(300)
    sortsContent:SetHeight(200)
    sortsScroll:SetScrollChild(sortsContent)

    local function isInMainList(name)
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        local list = (type(LibramSwapDB.spells) == "table") and LibramSwapDB.spells or {}
        for _,v in ipairs(list) do if v == name then return true end end
        return false
    end

    local function refreshSortsList()
        pcall(function()
            if sortsContent and sortsContent.GetChildren then
                for _, c in ipairs({sortsContent:GetChildren()}) do if c and type(c.Hide) == "function" then c:Hide(); if c.SetParent then c:SetParent(nil) end end end
            end
        end)
        local filter = ""
        if searchBox and type(searchBox.GetText) == "function" then
            filter = tostring(searchBox:GetText() or "")
        end
        filter = string.lower(filter)
        local pool = defaultSpells
        local idx = 0
        for i,name in ipairs(pool) do
            if filter == "" or string.find(string.lower(name), filter, 1, true) then
                local n = name
                idx = idx + 1
                local y = -8 - (idx-1) * 22
                local btn = CreateFrame("Button", nil, sortsContent, "UIPanelButtonTemplate")
                btn:SetHeight(20); btn:SetWidth(220)
                btn:SetPoint("TOPLEFT", sortsContent, "TOPLEFT", 8, y)
                btn:SetText(n)
                btn:SetScript("OnClick", function()
                    LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
                    if type(LibramSwapDB.spells) ~= "table" then LibramSwapDB.spells = {} end
                    LibramSwapDB.enabledMap = (type(LibramSwapDB.enabledMap) == "table") and LibramSwapDB.enabledMap or {}
                    
                    if isInMainList(n) then
                        -- Remove from spell list
                        for k,v in ipairs(LibramSwapDB.spells) do if v == n then table.remove(LibramSwapDB.spells, k); break end end
                        -- Also set to disabled/hidden in Configuration
                        LibramSwapDB.enabledMap[n] = false
                        if type(DEFAULT_CHAT_FRAME) == "table" and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[LibramSwap]: '"..tostring(n).."' removed from Configuration|r")
                        end
                    else
                        -- Add to spell list
                        table.insert(LibramSwapDB.spells, n)
                        -- Enable in Configuration
                        LibramSwapDB.enabledMap[n] = true
                        if type(DEFAULT_CHAT_FRAME) == "table" and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: '"..tostring(n).."' added to Configuration|r")
                        end
                    end
                    
                    spells = (type(LibramSwapDB.spells) == "table") and LibramSwapDB.spells or {}
                    refreshSortsList()
                    -- Force rebuild of Configuration spell list
                    if type(rebuildSpellList) == "function" then 
                        rebuildSpellList() 
                    end
                    -- Force refresh Configuration frame if it's visible
                    if frame and frame:IsShown() then
                        frame:Hide()
                        frame:Show()
                    end
                end)
                -- small label indicating action
                local actionLabel = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                actionLabel:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
                actionLabel:SetText(isInMainList(n) and "Remove" or "Add")
                actionLabel:SetTextColor(isInMainList(n) and 1.0 or 0.2, isInMainList(n) and 0.3 or 1.0, 0.2)
            end
        end
        sortsContent:SetHeight(math.max(140, idx * 22 + 8))
    end

    searchBox:SetScript("OnTextChanged", function() refreshSortsList() end)

    local function ShowSortsPopup()
        pickerBackdrop:Show()
        sortsFrame:ClearAllPoints()
        if type(LibramSwapDB) == "table" and type(LibramSwapDB.sortsPos) == "table" then
            local p = LibramSwapDB.sortsPos
            sortsFrame:SetPoint(p.point or "CENTER", UIParent, p.relPoint or "CENTER", p.x or 0, p.y or 0)
        else
            sortsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        sortsFrame:Show()
        refreshSortsList()
    end
    if mainSortBtn then mainSortBtn:SetScript("OnClick", function() ShowSortsPopup() end) end

    -- Close button top-right for Sorts manager
    local sortsClose = CreateFrame("Button", nil, sortsFrame, "UIPanelCloseButton")
    sortsClose:SetPoint("TOPRIGHT", sortsFrame, "TOPRIGHT", -4, -4)
    sortsClose:SetScript("OnClick", function() sortsFrame:Hide(); pickerBackdrop:Hide() end)

    -- Enable Escape key to close (Vanilla-compatible)
    table.insert(UISpecialFrames, "LibramSwap_SortsFrame")
    
    -- Add OnHide handler to close backdrop
    sortsFrame:SetScript("OnHide", function() pickerBackdrop:Hide() end)

    local yStart = -12
    local rowH = 34

    rebuildSpellList = function()
        -- Clear ALL previous widgets thoroughly
        pcall(function()
            if content and content.GetChildren then
                local children = {content:GetChildren()}
                for _, child in ipairs(children) do
                    if child then
                        if type(child.Hide) == "function" then child:Hide() end
                        if type(child.SetParent) == "function" then child:SetParent(nil) end
                    end
                end
            end
            -- Also clear any FontStrings
            if content and content.GetRegions then
                local regions = {content:GetRegions()}
                for _, region in ipairs(regions) do
                    if region and region ~= bg then
                        if type(region.Hide) == "function" then region:Hide() end
                        if type(region.SetParent) == "function" then region:SetParent(nil) end
                    end
                end
            end
        end)
        -- reset maps completely
        dropdowns = {}
        indicators = {}
        checks = {}

        -- ALWAYS read fresh spell list and enabledMap from savedvariables
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        local currentSpells = (type(LibramSwapDB.spells) == "table") and LibramSwapDB.spells or {}
        local enabledMap = (type(LibramSwapDB.enabledMap) == "table") and LibramSwapDB.enabledMap or {}
        
        local visibleRow = 0
        for i, spell in ipairs(currentSpells) do
            local s = spell
            -- SKIP completely if Sorts Manager turned this spell OFF
            if enabledMap[s] == false then
                -- Do not create any UI - completely hidden from Configuration
            else
            local y = yStart - visibleRow * rowH
            visibleRow = visibleRow + 1
            local lbl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("TOPLEFT", content, "TOPLEFT", 16, y)
            lbl:SetText(spell .. " :")
            lbl:SetTextColor(1, 0.82, 0)

            local chk = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
            chk:SetPoint("LEFT", lbl, "LEFT", -20, 0)
            chk:SetWidth(22); chk:SetHeight(22)
            chk:SetScript("OnClick", function()
                LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}; LibramSwapDB.enabledMap = (type(LibramSwapDB.enabledMap) == "table") and LibramSwapDB.enabledMap or {}
                local v = chk:GetChecked()
                if v == true or v == 1 then
                    LibramSwapDB.enabledMap[s] = true
                else
                    LibramSwapDB.enabledMap[s] = false
                end
            end)
            -- Initialize checkbox state from savedvariables
            if enabledMap[s] == false then
                chk:SetChecked(false)
            else
                chk:SetChecked(true)
            end
            checks[s] = chk

            local dname = "LibramSwap_Btn_" .. string.gsub(spell, "%s+", "")
            local btn = CreateFrame("Button", dname, content, "UIPanelButtonTemplate")
            btn:SetWidth(200)
            btn:SetHeight(24)
            btn:SetPoint("LEFT", lbl, "RIGHT", 12, -4)
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetAllPoints()
            btn.text:SetJustifyH("LEFT")
            
            -- Initialize button text with saved mapping
            local mappingSource = (type(LibramMap) == "table") and LibramMap or ((type(LibramSwapDB.map) == "table") and LibramSwapDB.map or {})
            local mapped = (type(mappingSource) == "table") and mappingSource[s] or nil
            if not mapped or mapped == "" or mapped == "__NONE__" then mapped = "None" end
            btn.text:SetText("  " .. tostring(mapped))
            
            dropdowns[s] = btn

            local ind = CreateFrame("Frame", nil, content)
            ind:SetPoint("LEFT", btn, "RIGHT", 12, 0)
            ind:SetWidth(12)
            ind:SetHeight(12)
            ind.tex = ind:CreateTexture(nil, "OVERLAY")
            ind.tex:SetAllPoints()
            -- Initialize indicator color based on item presence
            local present = false
            if mapped and mapped ~= "None" and LibramSwap_HasItem then present = LibramSwap_HasItem(mapped) end
            if present then
                ind.tex:SetTexture(0, 1, 0, 1)
            else
                ind.tex:SetTexture(1, 0, 0, 1)
            end
            indicators[s] = ind

            local sep = content:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT", content, "TOPLEFT", 12, y - (rowH - 8))
            sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", -12, y - (rowH - 8))
            sep:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
            sep:SetVertexColor(0.09, 0.09, 0.11, 0.6)

            btn:SetScript("OnClick", function() ShowLibramPicker(btn, s) end)
            btn:SetScript("OnEnter", function() GameTooltip:SetOwner(btn, "ANCHOR_RIGHT"); GameTooltip:SetText("Click to choose a libram") end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end

        -- adjust scroll child height dynamically (based on visible rows, not total spell count)
        local needed = (visibleRow * rowH) + 40
        content:SetHeight(needed)
    end

    -- initial build
    rebuildSpellList()

    -- enable mouse-wheel scrolling on the ScrollFrame (Classic-compatible)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        -- guard against nil delta (some clients/environments may pass nil)
        local d = delta or arg1 or -1
        if type(d) ~= "number" then d = tonumber(d) or -1 end

        local s = scroll
        local cur = s:GetVerticalScroll() or 0
        local step = 40
        -- prefer the built-in range if available (safer across clients)
        local maxScroll = 0
        if s.GetVerticalScrollRange then
            maxScroll = s:GetVerticalScrollRange()
        else
            local height = content and (content:GetHeight() or 0) or 0
            local viewH = s and (s:GetHeight() or 0) or 0
            maxScroll = math.max(0, height - viewH)
        end
        local new = cur - (d * step)
        if new < 0 then new = 0 end
        if new > maxScroll then new = maxScroll end
        s:SetVerticalScroll(new)
    end)

    -- Track first show to auto-load profile once
    local firstShow = true

    frame:SetScript("OnShow", function()
        -- sanitize saved profiles on first show to repair corrupted savedvariables
        sanitizeProfiles()
        -- Ensure main DB fields are tables to avoid indexing strings
        LibramSwapDB = (type(LibramSwapDB) == "table") and LibramSwapDB or {}
        if type(LibramSwapDB.map) ~= "table" then LibramSwapDB.map = {} end
        if type(LibramSwapDB.enabledMap) ~= "table" then LibramSwapDB.enabledMap = {} end
        if type(LibramSwapDB.profiles) ~= "table" then LibramSwapDB.profiles = {} end
        -- initialize delay controls
        if useDelayChk then
            if type(LibramSwapDB) == "table" and LibramSwapDB.useDelay then useDelayChk:SetChecked(true) else useDelayChk:SetChecked(false) end
        end
        if delayBox then
            delayBox:SetText(tostring(((type(LibramSwapDB) == "table") and LibramSwapDB.delay) or 0.02))
        end
        -- initialize debug checkbox and local DEBUG flag
        if type(debugChk) == "table" and type(debugChk.SetChecked) == "function" then
            if type(LibramSwapDB) == "table" and LibramSwapDB.debug then debugChk:SetChecked(true) else debugChk:SetChecked(false) end
        end
        DEBUG = (type(LibramSwapDB) == "table" and LibramSwapDB.debug) or false
        -- update active profile label when the config window is shown
        pcall(updateActiveProfileLabel)
        -- rebuildSpellList already initializes all dropdowns, checkboxes, and indicators
        -- so no need to duplicate that logic here
        
        -- Auto-load last used profile on first show (once per session)
        if firstShow then
            firstShow = false
            local pname = nil
            if type(LibramSwapDB.selectedProfile) == "string" then pname = LibramSwapDB.selectedProfile
            elseif type(LibramSwapDB.lastUsedProfile) == "string" then pname = LibramSwapDB.lastUsedProfile
            else
                -- if only one profile exists, use it
                local cnt = 0
                for k,_ in pairs(LibramSwapDB.profiles or {}) do cnt = cnt + 1; pname = k end
                if cnt ~= 1 then pname = nil end
            end
            if pname and type(LibramSwapDB.profiles) == "table" and type(LibramSwapDB.profiles[pname]) == "table" then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[LibramSwap]: Auto-loading profile '"..tostring(pname).."'...|r")
                pcall(loadProfile, pname)
                pcall(rebuildSpellList)
            end
        end
    end)

    SlashCmdList["LIBRAMCONFIG"] = function() if frame:IsShown() then frame:Hide() else frame:Show() end end
end
