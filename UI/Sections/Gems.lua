local _, T = ...
local L = T.L
local UI = T.UI

local COLORS = {
    GARNET   = { L["Garnet"], { 0.90, 0.35, 0.35 } },
    PERIDOT  = { L["Peridot"], { 0.55, 0.85, 0.35 } },
    AMETHYST = { L["Amethyst"], { 0.75, 0.50, 0.95 } },
    LAPIS    = { L["Lapis"], { 0.40, 0.60, 1.00 } },
}
local MISSING = { 0.33, 0.33, 0.33 }
local DIAMOND = { 0.75, 0.92, 1.00 }
local SWATCH = "|T%d:14:14:0:0:64:64:5:59:5:59:%d:%d:%d|t"

-- gem icon of that colour, dimmed when none is socketed
local function swatch(key, have)
    local c = have and { 1, 1, 1 } or MISSING
    local icon = UI.ItemIcon((T.Data.gemColors[key] or {})[1])
    return SWATCH:format(icon, c[1] * 255, c[2] * 255, c[3] * 255)
end

local function gemTooltip(pick, count, group)
    return function(tt)
        local id = (T.Data.gems[pick[1]] or {})[1]
        if id then tt:SetItemByID(id) else tt:SetText(pick[1], 1, 1, 1) end
        tt:AddLine(" ")
        if pick[2] then
            UI.AddLine(tt, L["Used by %d%% of the top players (%s)"]:format(pick[2], group), UI.GOLD)
        end
        UI.AddLine(tt, L["Socketed: %d"]:format(count), UI.WHITE)
        UI.AddLine(tt, L["Shift-click to link it in chat."], UI.GREY)
    end
end

local function colorsRow(worn)
    local have = {}
    for _, id in ipairs(worn) do
        local color = T.Gems.Color(id)
        if color then have[color] = true end
    end
    local parts, missing = {}, {}
    for _, key in ipairs(T.Gems.COLORS) do
        parts[#parts + 1] = swatch(key, have[key])
        if not have[key] then missing[#missing + 1] = COLORS[key][1] end
    end
    local count = #T.Gems.COLORS - #missing
    local all = #missing == 0
    T.Layout.Row({
        icon = false,
        label = L["Colors"],
        value = table.concat(parts, " "),
        right = ("%d/%d"):format(count, #T.Gems.COLORS),
        rightColor = all and UI.GREEN or UI.AMBER,
        status = all and UI.READY or UI.NOT,
        statusColor = not all and UI.AMBER or nil,
        tooltip = function(tt)
            tt:SetText(L["Gem colors"], 1, 1, 1)
            UI.AddLine(tt, L["Your diamond grows with every different gem color you have socketed."], UI.GREY, true)
            for _, key in ipairs(T.Gems.COLORS) do
                local name, c = COLORS[key][1], COLORS[key][2]
                UI.AddLine(tt, swatch(key, have[key]) .. " " .. UI.Colored(have[key] and c or MISSING, name), UI.WHITE)
            end
            if not all then UI.AddLine(tt, L["Missing: %s"]:format(table.concat(missing, ", ")), UI.AMBER, true) end
        end,
    })
end

local GROUPS = { { "diamond", "Diamond", 1 }, { "prismatic", "Gem", 2 } }

T.Sections.Gems = function(specID)
    local picks = T.Recommend.Gems(specID)
    local worn, empty = T.Gear.Gems()
    local recommended, count, matched = {}, {}, 0
    for _, group in pairs(picks) do
        for _, pick in ipairs(group) do recommended[pick[1]] = true end
    end
    for _, id in ipairs(worn) do
        local name = T.Gems.Name(id)
        if name then count[name] = (count[name] or 0) + 1 end
        if name and recommended[name] then matched = matched + 1 end
    end
    local total = #worn + empty
    local summary = total > 0
        and UI.Colored(matched == total and UI.GREEN or UI.AMBER, L["%d/%d sockets"]:format(matched, total)) or ""
    if not T.Layout.Header("gems", L["Gems"], summary) then return end

    for _, g in ipairs(GROUPS) do
        local list = picks[g[1]] or {}
        for i = 1, math.min(#list, g[3]) do
            local pick = list[i]
            local id = (T.Data.gems[pick[1]] or {})[1]
            local n = count[pick[1]] or 0
            local color = g[1] == "prismatic" and id and COLORS[T.Gems.Color(id)]
            T.Layout.Row({
                icon = UI.ItemIcon(id),
                label = color and color[1] or L[g[2]],
                labelColor = color and color[2] or g[1] == "diamond" and DIAMOND or nil,
                value = id and UI.ItemName(id) or pick[1],
                valueColor = id and UI.ItemColor(id) or UI.WHITE,
                right = "x" .. n,
                rightColor = n > 0 and UI.GREEN or UI.AMBER,
                status = n > 0 and UI.READY or UI.NOT,
                statusColor = n == 0 and UI.AMBER or nil,
                link = id and UI.ItemLink(id),
                tooltip = gemTooltip(pick, n, L[g[2]]),
            })
        end
    end
    if T.Gems.CountsColors(picks, worn) then colorsRow(worn) end
    if empty > 0 then
        T.Layout.Row({ icon = false, label = L["Empty"], value = L["%d empty sockets"]:format(empty),
            valueColor = UI.RED, status = UI.NOT })
    end
end
