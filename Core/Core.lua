local ADDON, T = ...

local L = T.L
local DB = T.DB

_G.BINDING_CATEGORY_GEARWRIGHT      = L["Gearwright"]
_G.BINDING_NAME_GEARWRIGHT_TOGGLE   = L["Toggle Gearwright"]

local Gearwright = T.Addon

local ICON = "Interface\\AddOns\\Gearwright\\Media\\Gearwright"

function Gearwright.OnInitialize()
    DB.Initialize()

    T.SetupOptions()

    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if LDB then
        Gearwright.launcher = LDB:NewDataObject(ADDON, {
            type = "launcher",
            text = L["Gearwright"],
            icon = ICON,
            OnClick = function(_, button)
                if button == "RightButton" then
                    Gearwright.OpenOptions()
                else
                    T.Window.Toggle()
                end
            end,
            OnTooltipShow = function(tt)
                tt:AddLine(L["Gearwright"])
                tt:AddLine("|cffffff00" .. L["Click"] .. "|r " .. L["Show or hide the window"], 1, 1, 1)
                tt:AddLine("|cffffff00" .. L["Right-Click"] .. "|r " .. L["Options"], 1, 1, 1)
            end,
        })
        if LDBIcon then
            LDBIcon:Register(ADDON, Gearwright.launcher, DB.Profile().minimap)
        end
    end

    Gearwright.RegisterChatCommand("gw", "HandleSlash")
    Gearwright.RegisterChatCommand("gearwright", "HandleSlash")
end

function Gearwright.OnEnable()
    T.Window.Initialize()
    T.SkinElvUI()

    local refresh = function() Gearwright.Refresh() end
    for _, event in ipairs({
        "PLAYER_EQUIPMENT_CHANGED", "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
        "COMBAT_RATING_UPDATE", "MASTERY_UPDATE", "BAG_UPDATE_DELAYED",
        "SOCKET_INFO_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
    }) do
        Gearwright.RegisterEvent(event, refresh)
    end
    Gearwright.RegisterEvent("GET_ITEM_INFO_RECEIVED", function(_, _, success)
        if success then refresh() end
    end)
    Gearwright.RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player", refresh)
    Gearwright.RegisterUnitEvent("UNIT_STATS", "player", refresh)
end

function Gearwright.HandleSlash(input)
    input = (input or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if input == "config" or input == "options" then
        Gearwright.OpenOptions()
    elseif input == "raid" or input == "mplus" or input == "m+" then
        DB.SetContent(input == "raid" and "raid" or "mplus")
        Gearwright.Refresh()
    elseif input == "dock" then
        DB.Profile().dock = not DB.Profile().dock
        T.Window.Update()
    else
        T.Window.Toggle()
    end
end

function Gearwright.OpenOptions()
    T.OpenOptions()
end

local refreshPending = false
function Gearwright.Refresh()
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.2, function()
        refreshPending = false
        T.Window.Refresh()
    end)
end

function Gearwright_Binding()
    T.Window.Toggle()
end

function Gearwright_OnAddonCompartmentClick(_, button)
    if button == "RightButton" then
        Gearwright.OpenOptions()
    else
        T.Window.Toggle()
    end
end
