local _, T = ...
local L = T.L
local DB = T.DB
local UI = T.UI
local Layout = T.Layout

local Window = {}
T.Window = Window

local PAD, TITLE_H, SUB_H, FOOTER_H, SECTION_GAP = Layout.PAD, 20, 16, 22, 4
local SECTIONS = { "Enchants", "Gems", "Stats", "Consumables" }

local frame, charButton

local function specLine(specID)
    local _, specName, _, _, _, classFile = GetSpecializationInfoByID(specID)
    local name = specName .. " " .. LOCALIZED_CLASS_NAMES_MALE[classFile]
    name = RAID_CLASS_COLORS[classFile]:WrapTextInColorCode(name)
    local score = T.Data.specs[specID].score
    local source
    if DB.Content() == "raid" then
        source = L["Raid"]
    elseif score then
        source = L["Top M+ %d-%d"]:format(score[1], score[2])
    else
        source = L["Mythic+"]
    end
    return name .. "  " .. UI.Colored(UI.GREY, source)
end

local function styleToggle(button, active)
    local c = active and UI.GOLD or UI.GREY
    button.text:SetTextColor(c[1], c[2], c[3])
    button.line:SetShown(active)
end

local function createToggle(text, value)
    local b = CreateFrame("Button", nil, frame)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("CENTER")
    b.text:SetText(text)
    b:SetSize(math.max(28, b.text:GetStringWidth() + 10), 16)
    b.line = b:CreateTexture(nil, "ARTWORK")
    b.line:SetColorTexture(UI.GOLD[1], UI.GOLD[2], UI.GOLD[3], 0.8)
    b.line:SetHeight(1)
    b.line:SetPoint("BOTTOMLEFT", 4, 0)
    b.line:SetPoint("BOTTOMRIGHT", -4, 0)
    b:SetScript("OnClick", function()
        DB.SetContent(value)
        Window.Refresh()
    end)
    return b
end

local function docked()
    return DB.Profile().dock
end

local function place()
    frame:ClearAllPoints()
    if docked() then
        frame:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 2, 0)
        frame:SetFrameStrata(CharacterFrame:GetFrameStrata())
    else
        local pos = DB.WindowPos()
        frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
        frame:SetFrameStrata("MEDIUM")
    end
end

local function fontString(template)
    local fs = frame:CreateFontString(nil, "OVERLAY", template)
    fs:SetPoint("LEFT", PAD, 0)
    fs:SetPoint("RIGHT", -PAD, 0)
    fs:SetJustifyH("LEFT")
    return fs
end

local function create()
    frame = CreateFrame("Frame", "GearwrightFrame", UIParent, "BackdropTemplate")
    frame:SetSize(Layout.WIDTH, 120)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if docked() or DB.Profile().locked then return end
        self.moving = true
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        if not self.moving then return end
        self.moving = false
        self:StopMovingOrSizing()
        local left, top = self:GetLeft(), self:GetTop()
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        DB.SaveWindowPos("TOPLEFT", "BOTTOMLEFT", left, top)
    end)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then T.Addon.OpenOptions() end
    end)
    local flat = "Interface\\Buttons\\WHITE8X8"
    frame:SetBackdrop({ bgFile = flat, edgeFile = flat, edgeSize = 1 })
    frame:SetBackdropColor(0, 0, 0, 0.75)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", PAD, -6)
    title:SetText(L["Gearwright"])

    local close = CreateFrame("Button", "GearwrightCloseButton", frame, "UIPanelCloseButtonNoScripts")
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() Window.SetShown(false) end)

    frame.raid = createToggle(L["Raid"], "raid")
    frame.raid:SetPoint("RIGHT", close, "LEFT", -4, 0)
    frame.mplus = createToggle(L["M+"], "mplus")
    frame.mplus:SetPoint("RIGHT", frame.raid, "LEFT", 0, 0)

    frame.spec = fontString("GameFontHighlightSmall")
    frame.spec:SetPoint("TOP", 0, -TITLE_H - 4)
    frame.spec:SetWordWrap(false)

    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", PAD, -TITLE_H - SUB_H - 8)
    frame.content:SetPoint("TOPRIGHT", -PAD, -TITLE_H - SUB_H - 8)
    frame.content:SetHeight(1)

    frame.empty = fontString("GameFontHighlightSmall")
    frame.empty:SetPoint("TOP", frame.content, "TOP", 0, -4)
    frame.empty:SetText(L["No data for this specialization."])

    local footer = fontString("GameFontDisableSmall")
    footer:SetPoint("BOTTOM", 0, 6)
    footer:SetText(L["Data: top 50 Mythic+ (EU, US), %s"]:format(T.Data.generated))

    frame:Hide()
end

local function createCharButton()
    charButton = CreateFrame("Button", "GearwrightCharacterButton", CharacterFrame)
    charButton:SetSize(22, 22)
    charButton:SetPoint("RIGHT", CharacterFrameCloseButton, "LEFT", -2, 0)
    charButton:SetFrameLevel(CharacterFrame:GetFrameLevel() + 10)
    charButton:SetNormalTexture("Interface\\AddOns\\Gearwright\\Media\\Gearwright")
    charButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    charButton:SetScript("OnClick", function() Window.Toggle() end)
    charButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Gearwright"], 1, 1, 1)
        UI.AddLine(GameTooltip, L["Show or hide the best-in-slot overview."], UI.GREY, true)
        GameTooltip:Show()
    end)
    charButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function wanted()
    if docked() then return CharacterFrame:IsShown() and DB.DockShown() end
    return DB.WindowShown()
end

function Window.Initialize()
    if frame then return end
    create()
    createCharButton()
    CharacterFrame:HookScript("OnShow", Window.Update)
    CharacterFrame:HookScript("OnHide", Window.Update)
    Window.Update()
end

function Window.Update()
    place()
    frame:SetShown(wanted())
    Window.Refresh()
end

function Window.SetShown(shown)
    if docked() then
        DB.SetDockShown(shown)
        if shown and not CharacterFrame:IsShown() then ToggleCharacter("PaperDollFrame") end
    else
        DB.SetWindowShown(shown)
    end
    Window.Update()
end

function Window.Toggle()
    Window.SetShown(not frame:IsShown())
end

function Window.Refresh()
    if not frame or not frame:IsShown() then return end
    local raid = DB.Content() == "raid"
    styleToggle(frame.mplus, not raid)
    styleToggle(frame.raid, raid)

    local specID = T.Recommend.SpecID()
    local known = T.Recommend.SpecData(specID) ~= nil
    frame.spec:SetText(known and specLine(specID) or "")
    frame.empty:SetShown(not known)
    Layout.Begin(frame.content)
    if known then
        for i, name in ipairs(SECTIONS) do
            if i > 1 then Layout.Gap(SECTION_GAP) end
            T.Sections[name](specID)
        end
    end
    local height = known and Layout.Height() or 40
    frame:SetHeight(TITLE_H + SUB_H + 8 + height + FOOTER_H)
end
