-- =====================================================
-- Profession Levels 3.0
-- Built From Stable 2.2 Base
-- Adds:
--   Primary / Secondary filtering
--   Smart resize floor
-- =====================================================

local PL = CreateFrame("Frame", "ProfessionLevelsFrame", UIParent)
PL:SetWidth(300)
PL:SetHeight(180)
PL:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
PL:SetMinResize(220, 120)
PL:SetClampedToScreen(true)
PL:EnableMouse(true)
PL:SetMovable(true)
PL:SetResizable(true)
PL:RegisterForDrag("LeftButton")

PL:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

-- =====================================================
-- Saved Variables
-- =====================================================

ProfessionLevelsDB = ProfessionLevelsDB or {}
ProfessionLevelsDB.locked = ProfessionLevelsDB.locked or false
ProfessionLevelsDB.compact = ProfessionLevelsDB.compact or false
ProfessionLevelsDB.showPrimary = ProfessionLevelsDB.showPrimary ~= false
ProfessionLevelsDB.showSecondary = ProfessionLevelsDB.showSecondary ~= false

-- =====================================================
-- Scroll Setup
-- =====================================================

local ScrollFrame = CreateFrame("ScrollFrame", nil, PL)
ScrollFrame:SetPoint("TOPLEFT", 10, -10)
ScrollFrame:SetPoint("BOTTOMRIGHT", -24, 10)

local Content = CreateFrame("Frame", nil, ScrollFrame)
Content:SetWidth(PL:GetWidth() - 40)
Content:SetHeight(1)
ScrollFrame:SetScrollChild(Content)

PL.rows = {}

-- =====================================================
-- Spell Icon Cache
-- =====================================================

local spellCache = {}
local function GetSpellIcon(skillName)
    if spellCache[skillName] then return spellCache[skillName] end
    for s = 1, 200 do
        local name = GetSpellName(s, "spell")
        if not name then break end
        if name == skillName then
            local tex = GetSpellTexture(s, "spell")
            spellCache[skillName] = tex
            return tex
        end
    end
end

-- =====================================================
-- Row Creation
-- =====================================================

local function CreateRow(index)
    local compact = ProfessionLevelsDB.compact
    local rowHeight = compact and 16 or 26
    local barHeight = compact and 0 or 12
    local font = compact and "GameFontHighlightSmall" or "GameFontNormal"

    local row = CreateFrame("Frame", nil, Content)
    row:SetHeight(rowHeight)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * (rowHeight + 4)))
    row:SetPoint("RIGHT", Content, "RIGHT", 0, 0)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(compact and 0 or 16)
    row.icon:SetHeight(compact and 0 or 16)
    row.icon:SetPoint("LEFT", 2, 0)
    row.icon:Hide()

    row.name = row:CreateFontString(nil, "OVERLAY", font)
    row.name:SetPoint("LEFT", row.icon, "RIGHT", compact and 0 or 6, 0)

    row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.value:SetPoint("RIGHT", row, "RIGHT", -6, 0)

    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetFrameLevel(row:GetFrameLevel() - 1)
    row.bar:SetHeight(barHeight)
    row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row.bar:SetPoint("LEFT", row.name, "RIGHT", 6, 0)
    row.bar:SetPoint("RIGHT", row.value, "LEFT", -6, 0)
    row.bar:Hide()

    row.bar.bg = row.bar:CreateTexture(nil, "BACKGROUND")
    row.bar.bg:SetAllPoints()
    row.bar.bg:SetTexture(0, 0, 0, 0.5)

    PL.rows[index] = row
    return row
end

local function ClearRows()
    for i = 1, table.getn(PL.rows) do
        PL.rows[i]:Hide()
    end
end

-- =====================================================
-- Update Function (Safe & Stable)
-- =====================================================

local function UpdateProfessions()

    ClearRows()
    Content:SetWidth(PL:GetWidth() - 40)

    local index = 1
    local contentHeight = 0
    local rowSpacing = ProfessionLevelsDB.compact and 18 or 30
    local currentSection = nil

    -- Expand headers
    for i = 1, GetNumSkillLines() do
        local name, isHeader, isExpanded = GetSkillLineInfo(i)
        if isHeader and not isExpanded then
            ExpandSkillHeader(i)
        end
    end

    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)

        if isHeader then
            if name == "Professions" then
                currentSection = "primary"
            elseif name == "Secondary Skills" then
                currentSection = "secondary"
            else
                currentSection = nil
            end

        elseif currentSection and rank and maxRank and maxRank > 0 then

            if (currentSection == "primary" and ProfessionLevelsDB.showPrimary)
            or (currentSection == "secondary" and ProfessionLevelsDB.showSecondary) then

                local row = PL.rows[index] or CreateRow(index)
                row:Show()

                row.name:SetText(name)
                row.value:SetText(rank.."/"..maxRank)

                if ProfessionLevelsDB.compact then
                    row.bar:Hide()
                    row.icon:Hide()
                    row.name:SetPoint("LEFT", 2, 0)
                else
                    row.bar:Show()
                    row.icon:Show()
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
    end

    Content:SetHeight(math.max(contentHeight, ScrollFrame:GetHeight()))

    -- Smart resize floor
    local minHeight = contentHeight + 40
    if PL:GetHeight() < minHeight then
        PL:SetHeight(minHeight)
    end
    PL:SetMinResize(220, minHeight)
end

-- =====================================================
-- Slash Commands
-- =====================================================

SLASH_PROFESSIONLEVELS1 = "/pl"
SlashCmdList["PROFESSIONLEVELS"] = function(arg)

    local msg = string.lower(arg or "")

    if msg == "primary" then
        ProfessionLevelsDB.showPrimary = true
        ProfessionLevelsDB.showSecondary = false
        UpdateProfessions()

    elseif msg == "secondary" then
        ProfessionLevelsDB.showPrimary = false
        ProfessionLevelsDB.showSecondary = true
        UpdateProfessions()

    elseif msg == "both" then
        ProfessionLevelsDB.showPrimary = true
        ProfessionLevelsDB.showSecondary = true
        UpdateProfessions()

    elseif msg == "compact" then
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
        PL:SetWidth(300)
        PL:SetHeight(180)
        PL:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        ProfessionLevelsDB.showPrimary = true
        ProfessionLevelsDB.showSecondary = true
        ProfessionLevelsDB.compact = false
        ProfessionLevelsDB.locked = false
        UpdateProfessions()
    end
end

-- =====================================================
-- Drag & Resize
-- =====================================================

PL:SetScript("OnDragStart", function()
    if not ProfessionLevelsDB.locked then this:StartMoving() end
end)

PL:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)

local resize = CreateFrame("Button", nil, PL)
resize:SetWidth(16)
resize:SetHeight(16)
resize:SetPoint("BOTTOMRIGHT", -6, 6)

resize:SetScript("OnMouseDown", function()
    if not ProfessionLevelsDB.locked then PL:StartSizing("BOTTOMRIGHT") end
end)

resize:SetScript("OnMouseUp", function()
    PL:StopMovingOrSizing()
end)

-- =====================================================
-- Events
-- =====================================================

PL:RegisterEvent("PLAYER_LOGIN")
PL:RegisterEvent("SKILL_LINES_CHANGED")

PL:SetScript("OnEvent", function()
    UpdateProfessions()
end)
