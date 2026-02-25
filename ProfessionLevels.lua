-- =====================================================
-- Profession Levels 2.6 (Turtle Stable Build)
-- =====================================================

local FRAME_WIDTH = 300
local PADDING = 12
local ROW_SPACING_NORMAL = 30
local ROW_SPACING_COMPACT = 18

local PL = CreateFrame("Frame", "ProfessionLevelsFrame", UIParent)
PL:SetWidth(FRAME_WIDTH)
PL:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
PL:SetClampedToScreen(true)
PL:EnableMouse(true)
PL:SetMovable(true)
PL:RegisterForDrag("LeftButton")

PL:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

ProfessionLevelsDB = ProfessionLevelsDB or {}
ProfessionLevelsDB.locked = ProfessionLevelsDB.locked or false
ProfessionLevelsDB.compact = ProfessionLevelsDB.compact or false

local Content = CreateFrame("Frame", nil, PL)
Content:SetPoint("TOPLEFT", PADDING, -PADDING)
Content:SetWidth(FRAME_WIDTH - (PADDING * 2))

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
-- Row Setup
-- =====================================================

local function CreateRow(index)
    local row = CreateFrame("Frame", nil, Content)
    row:SetWidth(Content:GetWidth())
    PL.rows[index] = row
    return row
end

local function SetupRow(row, index, name, rank, maxRank)

    local compact = ProfessionLevelsDB.compact
    local rowHeight = compact and 16 or 26
    local rowSpacing = compact and ROW_SPACING_COMPACT or ROW_SPACING_NORMAL

    row:SetHeight(rowHeight)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * rowSpacing))

    -- Icon
    if not row.icon then
        row.icon = row:CreateTexture(nil, "ARTWORK")
    end

    if compact then
        row.icon:Hide()
    else
        row.icon:SetWidth(16)
        row.icon:SetHeight(16)
        row.icon:SetPoint("LEFT", 0, 0)
        row.icon:SetTexture(GetSpellIcon(name))
        row.icon:Show()
    end

    -- Name
    if not row.name then
        row.name = row:CreateFontString(nil, "OVERLAY")
    end

    row.name:SetFontObject(compact and "GameFontHighlightSmall" or "GameFontNormal")

    if compact then
        row.name:SetPoint("LEFT", row, "LEFT", 0, 0)
    else
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    end

    row.name:SetText(name)

    -- Value
    if not row.value then
        row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    end

    if compact then
        row.value:SetPoint("LEFT", row.name, "RIGHT", 6, 0)
    else
        row.value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    end

    row.value:SetText(rank.."/"..maxRank)

    -- Bar
    if not row.bar then
        row.bar = CreateFrame("StatusBar", nil, row)
        row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        row.bar.bg = row.bar:CreateTexture(nil, "BACKGROUND")
        row.bar.bg:SetAllPoints()
        row.bar.bg:SetTexture(0, 0, 0, 0.5)
    end

    if compact then
        row.bar:Hide()
    else
        row.bar:SetHeight(12)
        row.bar:SetPoint("LEFT", row.name, "RIGHT", 6, 0)
        row.bar:SetPoint("RIGHT", row.value, "LEFT", -6, 0)
        row.bar:SetMinMaxValues(0, maxRank)
        row.bar:SetValue(rank)
        row.bar:Show()

        if rank == maxRank then
            row.bar:SetStatusBarColor(0.2, 0.8, 0.2)
        else
            row.bar:SetStatusBarColor(0.9, 0.7, 0.1)
        end
    end

    row:Show()
end

local function ClearRows()
    for i = 1, table.getn(PL.rows) do
        PL.rows[i]:Hide()
    end
end

-- =====================================================
-- Core Update
-- =====================================================

local function BuildProfessionList()

    ClearRows()

    local index = 1
    local inSection = false
    local rowSpacing = ProfessionLevelsDB.compact and ROW_SPACING_COMPACT or ROW_SPACING_NORMAL

    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)

        if isHeader then
            if name == "Professions" or name == "Secondary Skills" then
                inSection = true
            else
                inSection = false
            end
        elseif inSection and rank and maxRank and maxRank > 0 then

            local row = PL.rows[index] or CreateRow(index)
            SetupRow(row, index, name, rank, maxRank)

            index = index + 1
        end
    end

    local totalHeight = ((index - 1) * rowSpacing) + (PADDING * 2)
    PL:SetHeight(totalHeight)
end

-- =====================================================
-- Events
-- =====================================================

PL:RegisterEvent("PLAYER_LOGIN")
PL:RegisterEvent("SKILL_LINES_CHANGED")

PL:SetScript("OnEvent", function()

    -- Expand headers first
    for i = 1, GetNumSkillLines() do
        local name, isHeader, isExpanded = GetSkillLineInfo(i)
        if isHeader and not isExpanded then
            ExpandSkillHeader(i)
        end
    end

    BuildProfessionList()
end)

-- =====================================================
-- Slash Commands
-- =====================================================

SLASH_PROFESSIONLEVELS1 = "/pl"
SlashCmdList["PROFESSIONLEVELS"] = function(arg)

    local msg = string.lower(arg or "")

    if msg == "compact" then
        ProfessionLevelsDB.compact = true
        BuildProfessionList()
    elseif msg == "normal" then
        ProfessionLevelsDB.compact = false
        BuildProfessionList()
    elseif msg == "lock" then
        ProfessionLevelsDB.locked = true
    elseif msg == "unlock" then
        ProfessionLevelsDB.locked = false
    elseif msg == "reset" then
        ProfessionLevelsDB.compact = false
        ProfessionLevelsDB.locked = false
        PL:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        BuildProfessionList()
    end
end

PL:SetScript("OnDragStart", function()
    if not ProfessionLevelsDB.locked then this:StartMoving() end
end)

PL:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)
