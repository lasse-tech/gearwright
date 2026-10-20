local _, T = ...

local UI = {}
T.UI = UI
T.Sections = {}

UI.GOLD  = { 1, 0.82, 0 }
UI.GREY  = { 0.6, 0.6, 0.6 }
UI.WHITE = { 1, 1, 1 }
UI.GREEN = { 0.25, 1, 0.25 }
UI.AMBER = { 1, 0.65, 0.1 }
UI.RED   = { 1, 0.3, 0.3 }

UI.READY = "Interface\\RaidFrame\\ReadyCheck-Ready"
UI.WAIT  = "Interface\\RaidFrame\\ReadyCheck-Waiting"
UI.NOT   = "Interface\\RaidFrame\\ReadyCheck-NotReady"
UI.ICON_FALLBACK = 136244   -- Trade_Engraving

function UI.Hex(c)
    return ("|cff%02x%02x%02x"):format(c[1] * 255, c[2] * 255, c[3] * 255)
end

function UI.Colored(c, text)
    return UI.Hex(c) .. text .. "|r"
end

function UI.AddLine(tt, text, c, wrap)
    tt:AddLine(text, c[1], c[2], c[3], wrap)
end

function UI.ItemName(itemID)
    local name = C_Item.GetItemNameByID(itemID)
    if not name then C_Item.RequestLoadItemDataByID(itemID) end
    return name
end

function UI.ItemColor(itemID)
    local c = ITEM_QUALITY_COLORS[C_Item.GetItemQualityByID(itemID) or -1]
    return c and { c.r, c.g, c.b } or UI.WHITE
end

function UI.ItemLink(itemID)
    return (select(2, C_Item.GetItemInfo(itemID)))
end

function UI.ItemIcon(itemID)
    return itemID and C_Item.GetItemIconByID(itemID) or UI.ICON_FALLBACK
end

function UI.Share(pick)
    return pick[2] and ("%d%%"):format(pick[2]) or nil
end
