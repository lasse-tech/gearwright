local _, T = ...
local L = T.L
local UI = T.UI

local function carried(items)
    local n = 0
    for _, id in ipairs(items or {}) do n = n + C_Item.GetItemCount(id) end
    return n
end

local function tooltip(row)
    return function(tt)
        tt:SetItemByID(row.items[1])
        if row.alt then
            tt:AddLine(" ")
            UI.AddLine(tt, L["Alternative: %s"]:format(UI.ItemName(row.alt[1]) or ("#" .. row.alt[1])), UI.GREY)
        end
        UI.AddLine(tt, L["Shift-click to link it in chat."], UI.GREY)
    end
end

T.Sections.Consumables = function(specID)
    if not T.Layout.Header("consumables", L["Consumables"]) then return end
    for _, c in ipairs(T.Recommend.Consumables(specID)) do
        local id = c.items[1]
        local n = carried(c.items) + carried(c.alt)
        T.Layout.Row({
            icon = UI.ItemIcon(id),
            label = c.label,
            value = UI.ItemName(id) or ("#" .. id),
            valueColor = UI.ItemColor(id),
            right = "x" .. n,
            rightColor = n > 0 and UI.GREEN or UI.RED,
            status = n > 0 and UI.READY or UI.NOT,
            link = UI.ItemLink(id),
            tooltip = tooltip(c),
        })
    end
end
