local _, T = ...
local L = T.L
local UI = T.UI

local STATE = {
    best  = { UI.READY, UI.WHITE },
    rank  = { UI.WAIT, UI.AMBER },
    alt   = { UI.WAIT, UI.AMBER },
    other = { UI.NOT, UI.RED },
    none  = { UI.NOT, UI.RED },
}

local function shortName(name)
    local short = name:match("^.- %- (.+)$")
    return short or name
end

local function display(name)
    local item = T.Data.enchants[name].item
    return shortName(item and UI.ItemName(item) or name), item
end

local function tooltip(slotID, picks, applied, state)
    return function(tt)
        local name, share = picks[1][1], picks[1][2]
        local item = T.Data.enchants[name].item
        if item then tt:SetItemByID(item) else tt:SetText(shortName(name), 1, 1, 1) end
        tt:AddLine(" ")
        if share then
            UI.AddLine(tt, L["Used by %d%% of the top players"]:format(share), UI.GOLD)
        else
            UI.AddLine(tt, L["Raid recommendation"], UI.GOLD)
        end
        if #picks > 1 then
            UI.AddLine(tt, L["Alternatives:"], UI.GREY)
            for i = 2, #picks do
                tt:AddDoubleLine("  " .. display(picks[i][1]), UI.Share(picks[i]) or "",
                    1, 1, 1, UI.GREY[1], UI.GREY[2], UI.GREY[3])
            end
        end
        if state == "none" then
            UI.AddLine(tt, L["Not enchanted"], UI.RED)
        elseif state then
            local text = T.Gear.EnchantText(slotID) or ("#" .. applied)
            UI.AddLine(tt, L["Equipped: %s"]:format(text), STATE[state][2])
        end
        if state == "rank" then UI.AddLine(tt, L["Lower quality than the best rank."], UI.AMBER) end
        if item then UI.AddLine(tt, L["Shift-click to link it in chat."], UI.GREY) end
    end
end

T.Sections.Enchants = function(specID)
    local rows = T.Recommend.Enchants(specID)
    local good, total = 0, 0
    for _, r in ipairs(rows) do
        if T.Gear.HasItem(r.slotID) and T.Gear.Enchantable(r.key, r.slotID) then
            r.applied = T.Gear.EnchantID(r.slotID)
            r.state = T.Recommend.EnchantState(r.picks, r.applied)
            total = total + 1
            if r.state == "best" then good = good + 1 end
        end
    end
    local summary = UI.Colored(good == total and UI.GREEN or UI.AMBER, good .. "/" .. total)
    if not T.Layout.Header("enchants", L["Enchants"], summary) then return end

    for _, r in ipairs(rows) do
        local text, item = display(r.picks[1][1])
        T.Layout.Row({
            icon = UI.ItemIcon(item),
            label = r.label,
            value = text,
            valueColor = r.state and UI.WHITE or UI.GREY,
            status = r.state and STATE[r.state][1],
            link = item and UI.ItemLink(item),
            tooltip = tooltip(r.slotID, r.picks, r.applied, r.state),
        })
    end
end
