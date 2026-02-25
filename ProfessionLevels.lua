-- =====================================================
-- Profession Levels 2.4
-- • Per-character settings
-- • Preferences menu
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
        }
    end
    return ProfessionLevelsDB[charKey]
end

local settings = GetCharSettings()

-- =====================================================
-- Options Frame
-- =====================================================

local OptionsFrame = CreateFrame("Frame", "ProfessionLevelsOptions", PL)
OptionsFrame:SetWidth(280)
OptionsFrame:SetHeight(180)
OptionsFrame:SetPoint("TOPLEFT", PL, "TOPRIGHT", 5, 0)
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
optionsTitle:SetPoint("TOP", OptionsFrame, "TOP", 0, -10)
optionsTitle:SetText("Preferences")

local function CreateRadioButton(parent, label, index, yOffset)
    local rb = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    rb:SetPoint("TOPLEFT", 20, yOffset)
    
    local text = rb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", rb, "RIGHT", 4, 0)
    text:SetText(label)
    
    rb:SetScript("OnClick", function()
        for i = 1, 3 do
            _G[parent:GetName() .. "Radio" .. i]:SetChecked(i == index)
        end
        if index == 1 then
            settings.showPrimary = true
            settings.showSecondary = true
        elseif index == 2 then
            settings.showPrimary = true
            settings.showSecondary = false
        elseif index == 3 then
            settings.showPrimary = false
            settings.showSecondary = true
        end
        UpdateProfessions()
    end)
    
    return rb
end

local rb1 = CreateRadioButton(OptionsFrame, "Show Both", 1, -35)
local rb2 = CreateRadioButton(OptionsFrame, "Primary Only", 2, -60)
local rb3 = CreateRadioButton(OptionsFrame, "Secondary Only", 3, -85)

local function UpdateRadioButtons()
    if settings.showPrimary and settings.showSecondary then
        rb1:SetChecked(true)
    elseif settings.showPrimary then
        rb2:SetChecked(true)
    else
        rb3:SetChecked(true)
    end
end

local closeBtn = CreateFrame("Button", nil, OptionsFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", OptionsFrame, "TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
    OptionsFrame:Hide()
end)

local toggleCompact = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
toggleCompact:SetPoint("TOPLEFT", 20, -115)
toggleCompact.text = toggleCompact:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
toggleCompact.text:SetPoint("LEFT", toggleCompact, "RIGHT", 4, 0)
toggleCompact.text:SetText("Compact Mode")
toggleCompact:SetChecked(settings.compact)
toggleCompact:SetScript("OnClick", function()
    settings.compact = toggleCompact:GetChecked()
    UpdateProfessions()
end)

local toggleLock = CreateFrame("CheckButton", nil, OptionsFrame, "UICheckButtonTemplate")
toggleLock:SetPoint("TOPLEFT", 20, -140)
toggleLock.text = toggleLock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
toggleLock.text:SetPoint("LEFT", toggleLock, "RIGHT", 4, 0)
toggleLock.text:SetText("Lock Frame")
toggleLock:SetChecked(settings.locked)
toggleLock:SetScript("OnClick", function()
    settings.locked = toggleLock:GetChecked()
end)

-- =====================================================
-- Gear Button
-- =====================================================

local gearBtn = CreateFrame("Button", nil, PL)
gearBtn:SetWidth(20)
gearBtn:SetHeight(20)
gearBtn:SetPoint("TOPRIGHT", -6, -6)

local gearTex = gearBtn:CreateTexture(nil, "BACKGROUND")
gearTex:SetTexture("Interface\\BUTTONS\\UI-OptionsButton")
gearTex:SetAllPoints()
gearBtn:SetNormalTexture(gearTex)

gearBtn:SetScript("OnClick", function()
    if OptionsFrame:IsVisible() then
        OptionsFrame:Hide()
    else
        UpdateRadioButtons()
        toggleCompact:SetChecked(settings.compact)
        toggleLock:SetChecked(settings.locked)
        OptionsFrame:Show()
    end
end)

gearBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(gearBtn, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText("Preferences")
    GameTooltip:Show()
end)

gearBtn:SetScript("OnLeave", function()
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
        row.bar.bg:SetTexture(0, 0, 0, 0.5)
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
        bar = row.bar:SetPoint("RIGHT", row.value, "LEFT", -6, 0)
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

local function UpdateProfessions()

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
                    row.bar:SetStatusBarColor(0.2, 0.8, 0.2)
                else
                    row.bar:SetStatusBarColor(0.9, 0.7, 0.1)
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
        PL:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        UpdateProfessions()
    elseif msg == "config" or msg == "options" or msg == "settings" then
        UpdateRadioButtons()
        toggleCompact:SetChecked(settings.compact)
        toggleLock:SetChecked(settings.locked)
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
    UpdateProfessions()
end)
