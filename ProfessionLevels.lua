-- =====================================================
-- Profession Levels 2.5
-- • Normal width: 330
-- • Compact width: 200 (tight layout)
-- • Auto height
-- • No resizing
-- =====================================================

local NORMAL_WIDTH = 330
local COMPACT_WIDTH = 200

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
ProfessionLevelsDB.locked = ProfessionLevelsDB.locked or false
ProfessionLevelsDB.compact = ProfessionLevelsDB.compact or false

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

    local compact = ProfessionLevelsDB.compact
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
        -- 🔥 Compact = ultra tight
        row.icon:Hide()
        row.bar:Hide()

        row.name:ClearAllPoints()
        row.name:SetPoint("LEFT", row, "LEFT", 4, 0)

        row.value:ClearAllPoints()
        row.value:SetPoint("RIGHT", row, "RIGHT", -4, 0)

    else
        -- Normal mode
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

local function UpdateProfessions()

    ClearRows()

    local compact = ProfessionLevelsDB.compact
    local width = compact and COMPACT_WIDTH or NORMAL_WIDTH

    PL:SetWidth(width)
    Content:SetWidth(width - 36)

    local index = 1
    local contentHeight = 0
    local rowSpacing = compact and 18 or 30
    local inSection = false

    for i = 1, GetNumSkillLines() do
        local name, isHeader, isExpanded = GetSkillLineInfo(i)
        if isHeader and not isExpanded then
            ExpandSkillHeader(i)
        end
    end

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
SlashCmdList["PROFESSIONLEVELS"] = function(arg)

    local msg = string.lower(arg or "")

    if msg == "compact" then
        ProfessionLevelsDB.compact = true
        UpdateProfessions()
    elseif msg == "normal" then
        ProfessionLevelsDB.compact = false
        UpdateProfessions()
    elseif msg == "lock" then
        ProfessionLevelsDB.locked = true
    elseif msg == "unlock" then
        ProfessionLevelsDB.locked = false
    elseif msg == "reset" then
        ProfessionLevelsDB.compact = false
        ProfessionLevelsDB.locked = false
        PL:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        UpdateProfessions()
    end
end

PL:SetScript("OnDragStart", function()
    if not ProfessionLevelsDB.locked then this:StartMoving() end
end)

PL:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)

PL:RegisterEvent("PLAYER_LOGIN")
PL:RegisterEvent("SKILL_LINES_CHANGED")

PL:SetScript("OnEvent", function()
    UpdateProfessions()
end)
