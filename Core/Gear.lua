local _, T = ...

local Gear = {}
T.Gear = Gear

Gear.SLOTS = {
    HEAD = { 1 }, SHOULDER = { 3 }, BACK = { 15 }, CHEST = { 5 }, WRIST = { 9 }, HANDS = { 10 },
    LEGS = { 7 }, FEET = { 8 }, FINGER = { 11, 12 }, MAINHAND = { 16 }, OFFHAND = { 17 },
}

local SOCKET_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }

local enchantedPattern = "^" .. ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)") .. "$"

-- item:id:enchant:gem1:gem2:gem3:gem4
local function parseLink(link)
    local fields = { strsplit(":", link:match("item:([%-%d:]+)") or "") }
    local enchant = tonumber(fields[2])
    local gems = {}
    for i = 3, 6 do
        local id = tonumber(fields[i])
        if id and id > 0 then gems[#gems + 1] = id end
    end
    if enchant == 0 then enchant = nil end
    return enchant, gems
end

function Gear.EnchantID(slotID)
    local link = GetInventoryItemLink("player", slotID)
    return link and (parseLink(link))
end

function Gear.HasItem(slotID)
    return GetInventoryItemLink("player", slotID) ~= nil
end

function Gear.EnchantText(slotID)
    local data = C_TooltipInfo.GetInventoryItem("player", slotID)
    for _, line in ipairs(data and data.lines or {}) do
        local text = line.leftText and line.leftText:match(enchantedPattern)
        if text then return text end
    end
    return nil
end

function Gear.Enchantable(key, slotID)
    if key ~= "OFFHAND" then return true end
    local link = GetInventoryItemLink("player", slotID)
    return link ~= nil and select(6, C_Item.GetItemInfoInstant(link)) == Enum.ItemClass.Weapon
end

function Gear.Gems()
    local gems, empty = {}, 0
    for _, slotID in ipairs(SOCKET_SLOTS) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local _, ids = parseLink(link)
            for _, id in ipairs(ids) do gems[#gems + 1] = id end
            empty = empty + math.max(0, (C_Item.GetItemNumSockets(link) or 0) - #ids)
        end
    end
    return gems, empty
end
