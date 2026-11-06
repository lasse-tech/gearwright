local ADDON, T = ...
local L = T.L
local DB = T.DB

local category, layout

local ABOUT_TEMPLATE = "GearwrightAboutTemplate"
local ABOUT_FONT = "GameFontHighlight"
local ABOUT_BOTTOM_PAD = 8

-- Embedded libraries, as listed in embeds.xml and the README.
local LIBRARIES = "LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0"

-- The game font has no heart glyph.
local CHIP_TEXT = "Made with <3 in Europe"
local CHIP_GAP = 6
local CHIP_HEIGHT = 18
local CHIP_PAD_X = 8

GearwrightAboutMixin = {}

function GearwrightAboutMixin:Init(initializer)
    self.Text:SetText(initializer:GetData().text)

    local chip = self.Chip
    chip.Label:SetText(CHIP_TEXT)
    chip:ClearAllPoints()
    chip:SetPoint("TOPLEFT", self.Text, "BOTTOMLEFT", 0, -CHIP_GAP)
    chip:SetSize(math.ceil(chip.Label:GetStringWidth()) + 2 * CHIP_PAD_X, CHIP_HEIGHT)
end

local function metadata(field)
    local value = C_AddOns.GetAddOnMetadata(ADDON, field)
    return value ~= "" and value or nil
end

local function aboutText()
    local lines = {}

    local version = metadata("Version")
    if version then lines[#lines + 1] = L["Version %s"]:format(version) end

    local copyright = metadata("X-Copyright")
    if copyright then lines[#lines + 1] = "\194\169 " .. copyright end

    local footer = {}
    local website = metadata("X-Website")
    if website then footer[#footer + 1] = (website:gsub("^%a+://", "")) end
    local license = metadata("X-License")
    if license then footer[#footer + 1] = license .. " License" end
    if #footer > 0 then lines[#lines + 1] = table.concat(footer, " \194\183 ") end

    lines[#lines + 1] = L["Libraries: %s"]:format(LIBRARIES)

    return table.concat(lines, "\n")
end

local measure

local function textHeight(text)
    if not measure then
        measure = UIParent:CreateFontString(nil, "ARTWORK", ABOUT_FONT)
        measure:SetJustifyH("LEFT")
        measure:Hide()
    end
    measure:SetText(text)
    return measure:GetStringHeight()
end

local function addAbout()
    local text = aboutText()
    if text == "" then return end

    local initializer = Settings.CreateElementInitializer(ABOUT_TEMPLATE, { text = text })
    local extent = math.ceil(textHeight(text)) + CHIP_GAP + CHIP_HEIGHT + ABOUT_BOTTOM_PAD
    -- The settings list sizes rows by GetExtent().
    initializer.GetExtent = function() return extent end
    layout:AddInitializer(initializer)
end

local function refresh()
    T.Addon.Refresh()
end

local function update()
    T.Window.Update()
end

local function profileSetting(variableKey, variableType, name, default)
    return Settings.RegisterAddOnSetting(category, ADDON .. "_" .. variableKey, variableKey,
        DB.Profile(), variableType, name, default)
end

function T.SetupOptions()
    if category then return end

    category, layout = Settings.RegisterVerticalLayoutCategory(L["Gearwright"])

    addAbout()

    do
        local setting = profileSetting("content", Settings.VarType.String, L["Content"], "mplus")
        setting:SetValueChangedCallback(refresh)
        Settings.CreateDropdown(category, setting, function()
            local container = Settings.CreateControlTextContainer()
            container:Add("mplus", L["Mythic+"])
            container:Add("raid", L["Raid"])
            return container:GetData()
        end, L["Top Mythic+ players or top Mythic raiders"] .. "\n"
            .. L["Raid: leech first on head, shoulders, boots (not tanks)"])
    end

    do
        local setting = profileSetting("dock", Settings.VarType.Boolean, L["Dock to the character frame"], true)
        setting:SetValueChangedCallback(update)
        Settings.CreateCheckbox(category, setting,
            L["Right edge of the character frame, opens with it"] .. "\n" .. L["Off: free-standing, movable"])
    end

    local toggles = {
        { "showTooltip", L["Show tooltips"], true, L["Mouseover: item, alternatives, equipped"] },
        { "locked", L["Lock window"], false, L["Free-standing window only"] },
    }
    for _, t in ipairs(toggles) do
        local setting = profileSetting(t[1], Settings.VarType.Boolean, t[2], t[3])
        setting:SetValueChangedCallback(refresh)
        Settings.CreateCheckbox(category, setting, t[4])
    end

    do
        local proxy = { showMinimap = not DB.Profile().minimap.hide }
        local setting = Settings.RegisterAddOnSetting(category, ADDON .. "_showMinimap", "showMinimap",
            proxy, Settings.VarType.Boolean, L["Show minimap button"], true)
        setting:SetValueChangedCallback(function(_, value)
            DB.Profile().minimap.hide = not value
            local LDBIcon = LibStub("LibDBIcon-1.0", true)
            if not LDBIcon then return end
            if value then LDBIcon:Show(ADDON) else LDBIcon:Hide(ADDON) end
        end)
        Settings.CreateCheckbox(category, setting)
    end

    do
        local setting = profileSetting("elvuiSkin", Settings.VarType.Boolean,
            L["Allow ElvUI to skin this addon"], true)
        Settings.CreateCheckbox(category, setting, L["/reload required"])
    end

    Settings.RegisterAddOnCategory(category)
end

function T.OpenOptions()
    Settings.OpenToCategory(category:GetID())
end
