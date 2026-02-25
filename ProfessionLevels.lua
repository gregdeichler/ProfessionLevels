-- =====================================================
-- Profession Levels 3 (For Turtle WoW)
-- Tracks primary & secondary professions per character
-- Supports per-character settings & simple config UI
-- =====================================================

-- Load libraries
local LibStub = LibStub
local LibProf = LibStub("LibProfessions-1.0")
local AceGUI = LibStub("AceGUI-3.0")

-- Initialize saved variables per character
ProfessionLevelsDB = ProfessionLevelsDB or {}
local db = ProfessionLevelsDB
db.profile = db.profile or {
    trackPrimary = true,
    trackSecondary = true,
}

-- Main frame for profession display
local PLFrame = CreateFrame("Frame", "ProfessionLevelsFrame", UIParent)
PLFrame:SetWidth(300)
PLFrame:SetHeight(180)
PLFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
PLFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
PLFrame:EnableMouse(true)
PLFrame:SetMovable(true)
PLFrame:RegisterForDrag("LeftButton")
PLFrame:SetScript("OnDragStart", PLFrame.StartMoving)
PLFrame:SetScript("OnDragStop", PLFrame.StopMovingOrSizing)

-- Title
PLFrame.title = PLFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
PLFrame.title:SetPoint("TOP", 0, -10)
PLFrame.title:SetText("Profession Levels")

-- Container for profession info
PLFrame.profText = PLFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
PLFrame.profText:SetPoint("TOPLEFT", 10, -40)
PLFrame.profText:SetJustifyH("LEFT")
PLFrame.profText:SetWidth(280)
PLFrame.profText:SetHeight(120)

-- Function: Get tracked professions based on settings
local function GetTrackedProfessions()
    local professions = {}
    for i, prof in ipairs(LibProf:GetProfessions()) do
        if (db.profile.trackPrimary and prof.isPrimary) or
           (db.profile.trackSecondary and prof.isSecondary) then
            table.insert(professions, prof)
        end
    end
    return professions
end

-- Function: Update the profession frame text
local function UpdateProfessionDisplay()
    local lines = {}
    for _, prof in ipairs(GetTrackedProfessions()) do
        table.insert(lines, string.format("%s: %d/%d", prof.name, prof.level, prof.maxLevel))
    end
    PLFrame.profText:SetText(table.concat(lines, "\n"))
end

-- Event frame to refresh when professions change
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")
eventFrame:SetScript("OnEvent", function()
    UpdateProfessionDisplay()
end)

-- ==========================
-- Config UI using AceGUI
-- ==========================
local function OpenConfigUI()
    -- Create main config window
    local configFrame = AceGUI:Create("Frame")
    configFrame:SetTitle("Profession Levels Settings")
    configFrame:SetStatusText("Toggle which professions to track")
    configFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    configFrame:SetLayout("Flow")
    configFrame:SetWidth(300)
    configFrame:SetHeight(150)

    -- Checkbox: Track Primary
    local primaryCheckbox = AceGUI:Create("CheckBox")
    primaryCheckbox:SetLabel("Track Primary Professions")
    primaryCheckbox:SetValue(db.profile.trackPrimary)
    primaryCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        db.profile.trackPrimary = value
        UpdateProfessionDisplay()
    end)
    configFrame:AddChild(primaryCheckbox)

    -- Checkbox: Track Secondary
    local secondaryCheckbox = AceGUI:Create("CheckBox")
    secondaryCheckbox:SetLabel("Track Secondary Professions")
    secondaryCheckbox:SetValue(db.profile.trackSecondary)
    secondaryCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        db.profile.trackSecondary = value
        UpdateProfessionDisplay()
    end)
    configFrame:AddChild(secondaryCheckbox)
end

-- Slash command to open config UI
SLASH_PROFLEVELS1 = "/proflevels"
SLASH_PROFLEVELS2 = "/pl"
SlashCmdList["PROFLEVELS"] = function(msg)
    OpenConfigUI()
end

-- Initial update
UpdateProfessionDisplay()
