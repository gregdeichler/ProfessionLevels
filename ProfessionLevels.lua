-- =====================================================
-- Profession Levels 2.8
-- A profession tracking addon for Turtle WoW
-- 
-- Features:
--   - Track profession levels across your characters
--   - Monitor profession progress in real-time
--   - Per-character settings (position, display preferences)
--   - Primary/Secondary profession filtering
--   - Compact and Normal display modes
--   - Minimap button for quick access
--   - Hover highlights on rows
--   - Enhanced progress bar styling
--
-- Commands:
--   /pl config   - Open preferences menu
--   /pl compact - Switch to compact mode
--   /pl normal  - Switch to normal mode
--   /pl lock    - Lock frame position
--   /pl unlock  - Unlock frame position
--   /pl primary - Show primary professions only
--   /pl secondary - Show secondary skills only
--   /pl both    - Show both profession types
--   /pl reset   - Reset all settings
--
-- Minimap Button:
--   Click:       Toggle main frame
--   Shift+Click: Open settings
--   Drag:       Reposition button
--
-- Author: gregdeichler
-- =====================================================

local NORMAL_WIDTH = 300
local COMPACT_WIDTH = 190

local playerName = UnitName("player")
local realmName = GetRealmName()
local charKey = playerName .. "-" .. realmName

local PL = CreateFrame("Frame", "ProfessionLevelsFrame", UIParent)
PL:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
PL:SetClampedToScreen(true)
PL:EnableMouse(true)
PL:SetMovable(true)
PL:RegisterForDrag("LeftButton")
PL:SetResizable(false)

PL:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

ProfessionLevelsDB = ProfessionLevelsDB or {}

local settings
local sessionStartRanks = {}

local function GetCharSettings()
    ProfessionLevelsDB = ProfessionLevelsDB or {}
    if not ProfessionLevelsDB[charKey] then
        ProfessionLevelsDB[charKey] = {
            locked = false,
            compact = false,
            showPrimary = true,
            showSecondary = true,
            showMinimap = true,
            visible = true,
            showRemaining = true,
            minimapIcon = "Trade_Engineering",
            enabledProfessions = nil,
        }
    end

    if ProfessionLevelsDB[charKey].visible == nil then
        ProfessionLevelsDB[charKey].visible = true
    end
    if ProfessionLevelsDB[charKey].showRemaining == nil then
        ProfessionLevelsDB[charKey].showRemaining = true
    end

    return ProfessionLevelsDB[charKey]
end

local function EnsureSettings()
    if not settings then
        settings = GetCharSettings()
    end
    return settings
end

local minimapBtn
local minimapIcon
local divider
local togglePrimary
local toggleSecondary
local toggleCompact
local toggleLock
local toggleMinimap
local toggleRemaining

local function SavePoint(frame, key, point, relativeTo, relativePoint, xOfs, yOfs)
    EnsureSettings()
    settings[key] = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs,
    }
end

local function RestorePoint(frame, key, defaultPoint, defaultRelativeTo, defaultRelativePoint, defaultX, defaultY)
    EnsureSettings()
    local savedPoint = settings[key]
    frame:ClearAllPoints()
    if savedPoint then
        frame:SetPoint(savedPoint.point, defaultRelativeTo, savedPoint.relativePoint, savedPoint.x, savedPoint.y)
    else
        frame:SetPoint(defaultPoint, defaultRelativeTo, defaultRelativePoint, defaultX, defaultY)
    end
end

local function ExpandHeadersForScan()
    local collapsedHeaders = {}

    for i = GetNumSkillLines(), 1, -1 do
        local name, isHeader, isExpanded = GetSkillLineInfo(i)
        if isHeader and not isExpanded then
            collapsedHeaders[name] = true
            ExpandSkillHeader(i)
        end
    end

    return collapsedHeaders
end

local function RestoreHeadersAfterScan(collapsedHeaders)
    if not CollapseSkillHeader then
        return
    end

    for i = GetNumSkillLines(), 1, -1 do
        local name, isHeader = GetSkillLineInfo(i)
        if isHeader and collapsedHeaders[name] then
            CollapseSkillHeader(i)
        end
    end
end

local function GetSessionGain(skillName, rank)
    local startRank = sessionStartRanks[skillName]

    if not startRank or rank < startRank then
        sessionStartRanks[skillName] = rank
        return 0
    end

    return rank - startRank
end

local function FormatValueText(skillName, rank, maxRank)
    local valueText = rank .. "/" .. maxRank
    local gain = GetSessionGain(skillName, rank)

    if gain > 0 then
        return valueText .. " (+" .. gain .. ")"
    end

    if settings.showRemaining and rank < maxRank then
        return valueText .. " (" .. (maxRank - rank) .. " left)"
    end

    return valueText
end

-- =====================================================
-- Options Frame
-- =====================================================

local OptionsFrame = CreateFrame("Frame", "ProfessionLevelsOptions")
OptionsFrame:SetWidth(280)
OptionsFrame:SetHeight(350)
OptionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
OptionsFrame:SetFrameStrata("DIALOG")
OptionsFrame:Hide()

OptionsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

local optionsTitle = OptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
optionsTitle:SetPoint("TOP", OptionsFrame, "TOP", 0, -12)
optionsTitle:SetText("Profession Settings")

local closeBtn = CreateFrame("Button", nil, OptionsFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", OptionsFrame, "TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
    OptionsFrame:Hide()
end)

local professionCheckboxes = {}

local function GetAllProfessions()
    local profs = {}
    local inProfessions = false

    local collapsedHeaders = ExpandHeadersForScan()

    for i = 1, GetNumSkillLines() do
        local name, isHeader = GetSkillLineInfo(i)
        if isHeader then
            if name == "Professions" then
                inProfessions = true
            elseif name == "Secondary Skills" then
                inProfessions = true
            else
                inProfessions = false
            end
        elseif inProfessions and name then
            table.insert(profs, name)
        end
    end

    RestoreHeadersAfterScan(collapsedHeaders)

    local _, class = UnitClass("player")
    if class == "ROGUE" then
        table.insert(profs, "Lockpicking")
    end
    
    return profs
end

local function RefreshDisplayCheckboxes()
    EnsureSettings()
    if togglePrimary then
        togglePrimary:SetChecked(settings.showPrimary)
    end
    if toggleSecondary then
        toggleSecondary:SetChecked(settings.showSecondary)
    end
    if toggleCompact then
        toggleCompact:SetChecked(settings.compact)
    end
    if toggleLock then
        toggleLock:SetChecked(settings.locked)
    end
    if toggleMinimap then
        toggleMinimap:SetChecked(settings.showMinimap)
    end
    if toggleRemaining then
        toggleRemaining:SetChecked(settings.showRemaining)
    end
end

local function CreateDisplayControls()
    if divider then
        return
    end

    divider = OptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    divider:SetText("Display Options")

    togglePrimary = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
    togglePrimary.text = togglePrimary:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    togglePrimary.text:SetPoint("LEFT", togglePrimary, "RIGHT", 4, 0)
    togglePrimary.text:SetText("Show Primary Professions")
    togglePrimary:SetScript("OnClick", function()
        settings.showPrimary = togglePrimary:GetChecked() and true or false
        UpdateProfessions()
    end)

    toggleSecondary = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
    toggleSecondary.text = toggleSecondary:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleSecondary.text:SetPoint("LEFT", toggleSecondary, "RIGHT", 4, 0)
    toggleSecondary.text:SetText("Show Secondary Skills")
    toggleSecondary:SetScript("OnClick", function()
        settings.showSecondary = toggleSecondary:GetChecked() and true or false
        UpdateProfessions()
    end)

    toggleCompact = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
    toggleCompact.text = toggleCompact:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleCompact.text:SetPoint("LEFT", toggleCompact, "RIGHT", 4, 0)
    toggleCompact.text:SetText("Compact Mode")
    toggleCompact:SetScript("OnClick", function()
        settings.compact = toggleCompact:GetChecked() and true or false
        UpdateProfessions()
    end)

    toggleLock = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
    toggleLock.text = toggleLock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleLock.text:SetPoint("LEFT", toggleLock, "RIGHT", 4, 0)
    toggleLock.text:SetText("Lock Frame")
    toggleLock:SetScript("OnClick", function()
        settings.locked = toggleLock:GetChecked() and true or false
    end)

    toggleMinimap = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
    toggleMinimap.text = toggleMinimap:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleMinimap.text:SetPoint("LEFT", toggleMinimap, "RIGHT", 4, 0)
    toggleMinimap.text:SetText("Show Minimap Button")
    toggleMinimap:SetScript("OnClick", function()
        settings.showMinimap = toggleMinimap:GetChecked() and true or false
        if minimapBtn then
            if settings.showMinimap then
                minimapBtn:Show()
            else
                minimapBtn:Hide()
            end
        end
    end)

    toggleRemaining = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
    toggleRemaining.text = toggleRemaining:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleRemaining.text:SetPoint("LEFT", toggleRemaining, "RIGHT", 4, 0)
    toggleRemaining.text:SetText("Show Remaining To Cap")
    toggleRemaining:SetScript("OnClick", function()
        settings.showRemaining = toggleRemaining:GetChecked() and true or false
        UpdateProfessions()
    end)
end

local function CreateProfessionCheckboxes()
    EnsureSettings()
    for _, cb in pairs(professionCheckboxes) do
        cb:Hide()
    end

    local profs = GetAllProfessions()
    local yOffset = -35

    for _, profName in ipairs(profs) do
        local professionName = profName
        if not professionCheckboxes[professionName] then
            local cb = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
            cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            cb.text:SetText(professionName)
            cb:SetPoint("TOPLEFT", 20, yOffset)
            cb:SetScript("OnClick", function()
                settings.enabledProfessions = settings.enabledProfessions or {}
                local isChecked = cb:GetChecked() and true or false
                settings.enabledProfessions[professionName] = isChecked
                UpdateProfessions()
            end)
            professionCheckboxes[professionName] = cb
        end

        local cb = professionCheckboxes[professionName]
        cb:ClearAllPoints()
        cb:SetPoint("TOPLEFT", 20, yOffset)
        if settings.enabledProfessions and settings.enabledProfessions[professionName] == false then
            cb:SetChecked(false)
        else
            cb:SetChecked(true)
        end
        cb:Show()
        
        yOffset = yOffset - 22
    end

    local bottomCheckboxesEnd = yOffset - 10

    CreateDisplayControls()

    divider:ClearAllPoints()
    divider:SetPoint("TOPLEFT", 20, bottomCheckboxesEnd)

    togglePrimary:ClearAllPoints()
    togglePrimary:SetPoint("TOPLEFT", 20, bottomCheckboxesEnd - 25)

    toggleSecondary:ClearAllPoints()
    toggleSecondary:SetPoint("TOPLEFT", 20, bottomCheckboxesEnd - 50)

    toggleCompact:ClearAllPoints()
    toggleCompact:SetPoint("TOPLEFT", 20, bottomCheckboxesEnd - 75)

    toggleLock:ClearAllPoints()
    toggleLock:SetPoint("TOPLEFT", 20, bottomCheckboxesEnd - 100)

    toggleMinimap:ClearAllPoints()
    toggleMinimap:SetPoint("TOPLEFT", 20, bottomCheckboxesEnd - 125)

    toggleRemaining:ClearAllPoints()
    toggleRemaining:SetPoint("TOPLEFT", 20, bottomCheckboxesEnd - 150)

    RefreshDisplayCheckboxes()

    OptionsFrame:SetHeight(math.max(370, 210 - bottomCheckboxesEnd))
end

-- =====================================================
-- Minimap Button
-- =====================================================

minimapBtn = CreateFrame("Button", "ProfessionLevelsMinimapBtn", Minimap)
minimapBtn:SetWidth(31)
minimapBtn:SetHeight(31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetMovable(true)
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

minimapIcon = minimapBtn:CreateTexture(nil, "ARTWORK")
minimapIcon:SetWidth(20)
minimapIcon:SetHeight(20)
minimapIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
minimapIcon:SetPoint("CENTER", 0, 0)

local btnBorder = minimapBtn:CreateTexture(nil, "OVERLAY")
btnBorder:SetWidth(53)
btnBorder:SetHeight(53)
btnBorder:SetPoint("CENTER", 11, -11)
btnBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

minimapBtn.icon = minimapIcon

minimapBtn:SetScript("OnClick", function(self, button)
    if IsShiftKeyDown() then
        CreateProfessionCheckboxes()
        OptionsFrame:Show()
    else
        if PL:IsVisible() then
            settings.visible = false
            PL:Hide()
        else
            settings.visible = true
            PL:Show()
        end
    end
end)

minimapBtn:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    SavePoint(self, "minimapPosition", point, Minimap, relativePoint, xOfs, yOfs)
end)

minimapBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(minimapBtn, "ANCHOR_LEFT")
    GameTooltip:SetText("Profession Levels")
    GameTooltip:AddLine("Click: Toggle Frame", 1, 1, 1)
    GameTooltip:AddLine("Shift+Click: Settings", 1, 1, 1)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- =====================================================
-- Scroll Setup
-- =====================================================

local ScrollFrame = CreateFrame("ScrollFrame", nil, PL)
ScrollFrame:SetPoint("TOPLEFT", 18, -18)
ScrollFrame:SetPoint("BOTTOMRIGHT", -18, 18)

local Content = CreateFrame("Frame", nil, ScrollFrame)
ScrollFrame:SetScrollChild(Content)

PL.rows = {}

-- =====================================================
-- Icon Cache + Fallbacks
-- =====================================================

local spellCache = {}

local fallbackIcons = {
    ["Mining"] = "Interface\\Icons\\Trade_Mining",
    ["Herbalism"] = "Interface\\Icons\\Trade_Herbalism",
}

local function GetSpellIcon(skillName)
    if spellCache[skillName] then
        return spellCache[skillName]
    end

    for s = 1, 200 do
        local name = GetSpellName(s, "spell")
        if not name then break end
        if name == skillName then
            local tex = GetSpellTexture(s, "spell")
            if tex then
                spellCache[skillName] = tex
                return tex
            end
        end
    end

    return fallbackIcons[skillName] or "Interface\\Icons\\INV_Misc_Gear_01"
end

-- =====================================================
-- Row Creation
-- =====================================================

local function CreateRow(index)
    local row = CreateFrame("Frame", nil, Content)
    PL.rows[index] = row
    return row
end

local function SetupRowLayout(row, index)

    local compact = settings.compact
    local rowHeight = compact and 13 or 21
    local barHeight = compact and 0 or 12
    local font = compact and "GameFontHighlightSmall" or "GameFontNormal"

    row:SetHeight(rowHeight)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 6, -((index - 1) * (rowHeight + 3)))
    row:SetPoint("RIGHT", Content, "RIGHT", -6, 0)

    if not row.highlight then
        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints()
        row.highlight:SetTexture(0.3, 0.5, 0.8, 0.2)
        row.highlight:Hide()
    end

    row:EnableMouse(true)
    row:SetScript("OnEnter", function()
        row.highlight:Show()
    end)
    row:SetScript("OnLeave", function()
        row.highlight:Hide()
    end)

    if not row.icon then
        row.icon = row:CreateTexture(nil, "ARTWORK")
    end

    if not row.name then
        row.name = row:CreateFontString(nil, "OVERLAY")
    end

    if not row.value then
        row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    end

    if not row.bar then
        row.bar = CreateFrame("StatusBar", nil, row)
        row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        
        row.bar.bg = row.bar:CreateTexture(nil, "BACKGROUND")
        row.bar.bg:SetAllPoints()
        row.bar.bg:SetTexture(0, 0, 0, 0.2)
    end

    row.name:SetFontObject(font)

    if compact then
        row.icon:Hide()
        row.bar:Hide()

        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", row, "LEFT", 3, 0)

        row.value:ClearAllPoints()
        row.value:SetPoint("RIGHT", row, "RIGHT", -3, 0)

    else
        row.icon:SetWidth(14)
        row.icon:SetHeight(14)
        row.icon:SetPoint("LEFT", 2, 0)
        row.icon:Show()

        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)

        row.value:ClearAllPoints()
        row.value:SetPoint("RIGHT", row, "RIGHT", -4, 0)

        row.bar:SetHeight(barHeight)
        row.bar:ClearAllPoints()
        row.bar:SetPoint("LEFT", row.name, "RIGHT", 4, 0)
        row.bar:SetPoint("RIGHT", row.value, "LEFT", -4, 0)
        row.bar:Show()
    end
end

local function ClearRows()
    for i = 1, table.getn(PL.rows) do
        PL.rows[i]:Hide()
    end
end

-- =====================================================
-- Update Function
-- =====================================================

function UpdateProfessions()
    EnsureSettings()

    ClearRows()

    local compact = settings.compact
    local width = compact and COMPACT_WIDTH or NORMAL_WIDTH

    PL:SetWidth(width)
    Content:SetWidth(width - 36)

    local index = 1
    local contentHeight = 0
    local rowSpacing = compact and 16 or 24
    local collapsedHeaders = ExpandHeadersForScan()

    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)

        if isHeader then
            if name == "Professions" or name == "Secondary Skills" then
                PL.currentSection = name
            else
                PL.currentSection = nil
            end

        elseif PL.currentSection and rank and maxRank and maxRank > 0 then
            local showProfession = true
            if PL.currentSection == "Professions" and not settings.showPrimary then
                showProfession = false
            elseif PL.currentSection == "Secondary Skills" and not settings.showSecondary then
                showProfession = false
            end
            if settings.enabledProfessions and settings.enabledProfessions[name] == false then
                showProfession = false
            end
            
            if showProfession then
                local row = PL.rows[index] or CreateRow(index)
                SetupRowLayout(row, index)
                row:Show()

                row.name:SetText(name)
                row.value:SetText(FormatValueText(name, rank, maxRank))

                if not compact then
                    row.icon:SetTexture(GetSpellIcon(name))
                    row.bar:SetMinMaxValues(0, maxRank)
                    row.bar:SetValue(rank)

                    if rank == maxRank then
                        row.bar:SetStatusBarColor(0.2, 0.75, 0.2)
                    else
                        row.bar:SetStatusBarColor(0.85, 0.65, 0.13)
                    end
                end

                index = index + 1
                contentHeight = contentHeight + rowSpacing
            end
        end
    end

    local _, class = UnitClass("player")
    if class == "ROGUE" then
        for i = 1, GetNumSkillLines() do
            local name, _, _, rank, _, _, maxRank = GetSkillLineInfo(i)
            if name == "Lockpicking" then
                local showLockpicking = true
                if settings.enabledProfessions and settings.enabledProfessions["Lockpicking"] == false then
                    showLockpicking = false
                end
                
                if showLockpicking then
                    local row = PL.rows[index] or CreateRow(index)
                    SetupRowLayout(row, index)
                    row:Show()

                    row.name:SetText(name)
                    row.value:SetText(FormatValueText(name, rank, maxRank))

                    if not compact then
                        row.icon:SetTexture("Interface\\Icons\\INV_ThrowingKnife_04")
                        row.bar:SetMinMaxValues(0, maxRank)
                        row.bar:SetValue(rank)

                        if rank == maxRank then
                            row.bar:SetStatusBarColor(0.2, 0.75, 0.2)
                        else
                            row.bar:SetStatusBarColor(0.85, 0.65, 0.13)
                        end
                    end

                    index = index + 1
                    contentHeight = contentHeight + rowSpacing
                end
                break
            end
        end
    end

    RestoreHeadersAfterScan(collapsedHeaders)

    Content:SetHeight(contentHeight)
    PL:SetHeight(contentHeight + 34)
end

-- =====================================================
-- Slash Commands
-- =====================================================

SLASH_PROFESSIONLEVELS1 = "/pl"
SLASH_PROFESSIONLEVELS2 = "/professionlevels"
SlashCmdList["PROFESSIONLEVELS"] = function(arg)
    EnsureSettings()

    local msg = string.lower(arg or "")

    if msg == "compact" then
        settings.compact = true
        UpdateProfessions()
    elseif msg == "normal" then
        settings.compact = false
        UpdateProfessions()
    elseif msg == "lock" then
        settings.locked = true
        RefreshDisplayCheckboxes()
    elseif msg == "unlock" then
        settings.locked = false
        RefreshDisplayCheckboxes()
    elseif msg == "primary" then
        settings.showPrimary = true
        settings.showSecondary = false
        RefreshDisplayCheckboxes()
        UpdateProfessions()
    elseif msg == "secondary" then
        settings.showPrimary = false
        settings.showSecondary = true
        RefreshDisplayCheckboxes()
        UpdateProfessions()
    elseif msg == "both" then
        settings.showPrimary = true
        settings.showSecondary = true
        RefreshDisplayCheckboxes()
        UpdateProfessions()
    elseif msg == "show" then
        settings.visible = true
        PL:Show()
    elseif msg == "hide" then
        settings.visible = false
        PL:Hide()
    elseif msg == "remaining" then
        settings.showRemaining = not settings.showRemaining
        RefreshDisplayCheckboxes()
        UpdateProfessions()
    elseif msg == "reset" then
        settings.compact = false
        settings.locked = false
        settings.showPrimary = true
        settings.showSecondary = true
        settings.showMinimap = true
        settings.visible = true
        settings.showRemaining = true
        settings.minimapIcon = "Trade_Engineering"
        settings.enabledProfessions = nil
        settings.framePosition = nil
        settings.minimapPosition = nil
        RestorePoint(PL, "framePosition", "CENTER", UIParent, "CENTER", 0, 0)
        RestorePoint(minimapBtn, "minimapPosition", "TOPRIGHT", Minimap, "TOPRIGHT", -10, -10)
        minimapBtn:Show()
        PL:Show()
        RefreshDisplayCheckboxes()
        UpdateProfessions()
    elseif msg == "config" or msg == "options" or msg == "settings" then
        CreateProfessionCheckboxes()
        OptionsFrame:Show()
    end
end

PL:SetScript("OnDragStart", function()
    EnsureSettings()
    if not settings.locked then this:StartMoving() end
end)

PL:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
    SavePoint(this, "framePosition", point, UIParent, relativePoint, xOfs, yOfs)
end)

PL:RegisterEvent("VARIABLES_LOADED")
PL:RegisterEvent("PLAYER_LOGIN")
PL:RegisterEvent("SKILL_LINES_CHANGED")

PL:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        settings = GetCharSettings()
        return
    end

    EnsureSettings()

    if event == "PLAYER_LOGIN" then
        RestorePoint(PL, "framePosition", "CENTER", UIParent, "CENTER", 0, 0)
        RestorePoint(minimapBtn, "minimapPosition", "TOPRIGHT", Minimap, "TOPRIGHT", -10, -10)
        if minimapBtn then
            if settings.showMinimap then
                minimapBtn:Show()
            else
                minimapBtn:Hide()
            end
        end
        if minimapIcon then
            minimapIcon:SetTexture("Interface\\Icons\\" .. settings.minimapIcon)
        end
        RefreshDisplayCheckboxes()
    end
    UpdateProfessions()
    if settings.visible then
        PL:Show()
    else
        PL:Hide()
    end
end)

PL:Hide()
