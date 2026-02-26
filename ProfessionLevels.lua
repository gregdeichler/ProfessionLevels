-- =====================================================
-- Profession Levels 2.5
-- A profession tracking addon for Turtle WoW
-- 
-- Features:
--   - Track profession levels across your characters
--   - Monitor profession progress in real-time
--   - Per-character settings (position, display preferences)
--   - Primary/Secondary profession filtering
--   - Compact and Normal display modes
--   - Minimap button for quick access
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
--   Left Click:  Toggle main frame
--   Right Click: Open settings
--   Drag:       Reposition button
--
-- Author: gregdeichler
-- =====================================================

local NORMAL_WIDTH = 330
local COMPACT_WIDTH = 200

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

local function GetCharSettings()
    if not ProfessionLevelsDB[charKey] then
        ProfessionLevelsDB[charKey] = {
            locked = false,
            compact = false,
            showPrimary = true,
            showSecondary = true,
            showMinimap = true,
            minimapIcon = "Trade_Engineering",
        }
    end
    return ProfessionLevelsDB[charKey]
end

local settings = GetCharSettings()

local minimapBtn
local minimapIcon

-- =====================================================
-- Options Frame
-- =====================================================

local OptionsFrame = CreateFrame("Frame", "ProfessionLevelsOptions")
OptionsFrame:SetWidth(240)
OptionsFrame:SetHeight(200)
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
optionsTitle:SetText("Preferences")

local function CreateRadioButton(name, parent, label, yOffset)
    local rb = CreateFrame("CheckButton", name, parent, "UIRadioButtonTemplate")
    rb:SetPoint("TOPLEFT", 20, yOffset)
    
    local text = rb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", rb, "RIGHT", 4, 0)
    text:SetText(label)
    
    return rb
end

local radioBoth = CreateRadioButton("PLRadioBoth", OptionsFrame, "Show Both", -35)
local radioPrimary = CreateRadioButton("PLRadioPrimary", OptionsFrame, "Primary Only", -55)
local radioSecondary = CreateRadioButton("PLRadioSecondary", OptionsFrame, "Secondary Only", -75)

local selectedMode = 1

local function UpdateRadioSelection()
    radioBoth:SetChecked(selectedMode == 1)
    radioPrimary:SetChecked(selectedMode == 2)
    radioSecondary:SetChecked(selectedMode == 3)
end

radioBoth:SetScript("OnClick", function()
    selectedMode = 1
    settings.showPrimary = true
    settings.showSecondary = true
    UpdateRadioSelection()
    UpdateProfessions()
end)

radioPrimary:SetScript("OnClick", function()
    selectedMode = 2
    settings.showPrimary = true
    settings.showSecondary = false
    UpdateRadioSelection()
    UpdateProfessions()
end)

radioSecondary:SetScript("OnClick", function()
    selectedMode = 3
    settings.showPrimary = false
    settings.showSecondary = true
    UpdateRadioSelection()
    UpdateProfessions()
end)

local closeBtn = CreateFrame("Button", nil, OptionsFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", OptionsFrame, "TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
    OptionsFrame:Hide()
end)

local toggleCompact = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
toggleCompact:SetPoint("TOPLEFT", 20, -105)
toggleCompact.text = toggleCompact:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
toggleCompact.text:SetPoint("LEFT", toggleCompact, "RIGHT", 4, 0)
toggleCompact.text:SetText("Compact Mode")
toggleCompact:SetChecked(settings.compact)
toggleCompact:SetScript("OnClick", function()
    settings.compact = toggleCompact:GetChecked()
    UpdateProfessions()
end)

local toggleLock = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
toggleLock:SetPoint("TOPLEFT", 20, -130)
toggleLock.text = toggleLock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
toggleLock.text:SetPoint("LEFT", toggleLock, "RIGHT", 4, 0)
toggleLock.text:SetText("Lock Frame")
toggleLock:SetChecked(settings.locked)
toggleLock:SetScript("OnClick", function()
    settings.locked = toggleLock:GetChecked()
end)

local toggleMinimap = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
toggleMinimap:SetPoint("TOPLEFT", 20, -155)
toggleMinimap.text = toggleMinimap:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
toggleMinimap.text:SetPoint("LEFT", toggleMinimap, "RIGHT", 4, 0)
toggleMinimap.text:SetText("Show Minimap Button")
toggleMinimap:SetChecked(settings.showMinimap)
toggleMinimap:SetScript("OnClick", function()
    settings.showMinimap = toggleMinimap:GetChecked()
    if minimapBtn then
        if settings.showMinimap then
            minimapBtn:Show()
        else
            minimapBtn:Hide()
        end
    end
end)

-- =====================================================
-- Minimap Button
-- =====================================================

minimapBtn = CreateFrame("Button", "ProfessionLevelsMinimapBtn", Minimap)
minimapBtn:SetWidth(31)
minimapBtn:SetHeight(31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -10, -10)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

minimapIcon = minimapBtn:CreateTexture(nil, "ARTWORK")
minimapIcon:SetWidth(20)
minimapIcon:SetHeight(20)
minimapIcon:SetTexture("Interface\\Icons\\Trade_Engineering")
minimapIcon:SetPoint("CENTER", 0, 0)

minimapBtn.icon = minimapIcon

minimapBtn:SetScript("OnClick", function(self, button)
    if IsShiftKeyDown() then
        if settings.showPrimary and settings.showSecondary then
            selectedMode = 1
        elseif settings.showPrimary then
            selectedMode = 2
        else
            selectedMode = 3
        end
        UpdateRadioSelection()
        toggleCompact:SetChecked(settings.compact)
        toggleLock:SetChecked(settings.locked)
        OptionsFrame:Show()
    else
        if PL:IsVisible() then
            PL:Hide()
        else
            PL:Show()
        end
    end
end)

minimapBtn:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
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
    local rowHeight = compact and 16 or 26
    local barHeight = compact and 0 or 12
    local font = compact and "GameFontHighlightSmall" or "GameFontNormal"

    row:SetHeight(rowHeight)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 8, -((index - 1) * (rowHeight + 4)))
    row:SetPoint("RIGHT", Content, "RIGHT", -8, 0)

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
        row.name:SetPoint("LEFT", row, "LEFT", 4, 0)

        row.value:ClearAllPoints()
        row.value:SetPoint("RIGHT", row, "RIGHT", -4, 0)

    else
        row.icon:SetWidth(16)
        row.icon:SetHeight(16)
        row.icon:SetPoint("LEFT", 2, 0)
        row.icon:Show()

        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)

        row.value:ClearAllPoints()
        row.value:SetPoint("RIGHT", row, "RIGHT", -6, 0)

        row.bar:SetHeight(barHeight)
        row.bar:ClearAllPoints()
        row.bar:SetPoint("LEFT", row.name, "RIGHT", 6, 0)
        row.bar:SetPoint("RIGHT", row.value, "LEFT", -6, 0)
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

    ClearRows()

    local compact = settings.compact
    local width = compact and COMPACT_WIDTH or NORMAL_WIDTH

    PL:SetWidth(width)
    Content:SetWidth(width - 36)

    local index = 1
    local contentHeight = 0
    local rowSpacing = compact and 18 or 30

    for i = 1, GetNumSkillLines() do
        local name, isHeader, isExpanded = GetSkillLineInfo(i)
        if isHeader and not isExpanded then
            ExpandSkillHeader(i)
        end
    end

    local showPrimary = settings.showPrimary
    local showSecondary = settings.showSecondary

    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)

        if isHeader then
            if name == "Professions" then
                PL.currentSection = showPrimary and "primary" or nil
            elseif name == "Secondary Skills" then
                PL.currentSection = showSecondary and "secondary" or nil
            else
                PL.currentSection = nil
            end

        elseif PL.currentSection and rank and maxRank and maxRank > 0 then

            local row = PL.rows[index] or CreateRow(index)
            SetupRowLayout(row, index)
            row:Show()

            row.name:SetText(name)
            row.value:SetText(rank.."/"..maxRank)

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

    Content:SetHeight(contentHeight)
    PL:SetHeight(contentHeight + 40)
end

-- =====================================================
-- Slash Commands
-- =====================================================

SLASH_PROFESSIONLEVELS1 = "/pl"
SLASH_PROFESSIONLEVELS2 = "/professionlevels"
SlashCmdList["PROFESSIONLEVELS"] = function(arg)

    local msg = string.lower(arg or "")

    if msg == "compact" then
        settings.compact = true
        UpdateProfessions()
    elseif msg == "normal" then
        settings.compact = false
        UpdateProfessions()
    elseif msg == "lock" then
        settings.locked = true
    elseif msg == "unlock" then
        settings.locked = false
    elseif msg == "reset" then
        settings.compact = false
        settings.locked = false
        settings.showPrimary = true
        settings.showSecondary = true
        settings.showMinimap = true
        settings.minimapIcon = "Trade_Engineering"
        PL:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        minimapBtn:Show()
        UpdateProfessions()
    elseif msg == "config" or msg == "options" or msg == "settings" then
        if settings.showPrimary and settings.showSecondary then
            selectedMode = 1
        elseif settings.showPrimary then
            selectedMode = 2
        else
            selectedMode = 3
        end
        UpdateRadioSelection()
        toggleCompact:SetChecked(settings.compact)
        toggleLock:SetChecked(settings.locked)
        toggleMinimap:SetChecked(settings.showMinimap)
        OptionsFrame:Show()
    elseif msg == "primary" then
        settings.showPrimary = true
        settings.showSecondary = false
        UpdateProfessions()
    elseif msg == "secondary" then
        settings.showPrimary = false
        settings.showSecondary = true
        UpdateProfessions()
    elseif msg == "both" then
        settings.showPrimary = true
        settings.showSecondary = true
        UpdateProfessions()
    end
end

PL:SetScript("OnDragStart", function()
    if not settings.locked then this:StartMoving() end
end)

PL:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)

PL:RegisterEvent("PLAYER_LOGIN")
PL:RegisterEvent("SKILL_LINES_CHANGED")

PL:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
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
        PL:Show()
    end
    UpdateProfessions()
end)

PL:Show()
