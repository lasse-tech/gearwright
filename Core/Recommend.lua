local _, T = ...
local L = T.L

local Recommend = {}
T.Recommend = Recommend

local ENCHANT_SLOTS = { "HEAD", "SHOULDER", "BACK", "CHEST", "WRIST", "HANDS", "LEGS", "FEET",
    "FINGER", "MAINHAND", "OFFHAND" }

local SLOT_LABELS = {
    HEAD = "HEADSLOT", SHOULDER = "SHOULDERSLOT", BACK = "BACKSLOT", CHEST = "CHESTSLOT",
    WRIST = "WRISTSLOT", HANDS = "HANDSSLOT", LEGS = "LEGSSLOT", FEET = "FEETSLOT",
    MAINHAND = "MAINHANDSLOT", OFFHAND = "SECONDARYHANDSLOT",
}

local function slotLabel(key, index)
    if key == "FINGER" then return L["Ring %d"]:format(index) end
    return _G[SLOT_LABELS[key]] or key
end

function Recommend.SpecID()
    local index = GetSpecialization()
    return index and (GetSpecializationInfo(index))
end

-- raid falls back to Mythic+ for specs with too few raiders
function Recommend.Source(specID)
    if T.DB.Content() == "raid" and T.Data.raidSpecs[specID] then return "raid" end
    return "mplus"
end

function Recommend.SpecData(specID)
    if not specID then return nil end
    if Recommend.Source(specID) == "raid" then return T.Data.raidSpecs[specID] end
    return T.Data.specs[specID]
end

local function role(specID)
    return (select(5, GetSpecializationInfoByID(specID)))
end

local function raidPicks(specID, key, data)
    local raid = T.Data.raid
    local names = raid.specs[specID] and raid.specs[specID][key]
    if not names and role(specID) ~= "TANK" then names = raid.all[key] end
    if not names then return data end
    local out, seen = {}, {}
    for _, name in ipairs(names) do
        out[#out + 1] = { name }
        seen[name] = true
    end
    for _, pick in ipairs(data or {}) do
        if not seen[pick[1]] then out[#out + 1] = pick end
    end
    return out
end

local function enchantPicks(specID, key)
    local spec = Recommend.SpecData(specID)
    local picks = spec and spec.enchants[key]
    if T.DB.Content() == "raid" then return raidPicks(specID, key, picks) end
    return picks
end

function Recommend.Enchants(specID)
    local rows = {}
    for _, key in ipairs(ENCHANT_SLOTS) do
        local picks = enchantPicks(specID, key)
        if picks and #picks > 0 then
            for i, slotID in ipairs(T.Gear.SLOTS[key]) do
                rows[#rows + 1] = { key = key, slotID = slotID, label = slotLabel(key, i), picks = picks }
            end
        end
    end
    return rows
end

-- best | rank | alt | other | none
function Recommend.EnchantState(picks, applied)
    if not applied then return "none" end
    for i, pick in ipairs(picks) do
        local data = T.Data.enchants[pick[1]]
        if data then
            for j, id in ipairs(data.ench) do
                if id == applied then
                    if i > 1 then return "alt" end
                    if j > 1 and data.ranked then return "rank" end
                    return "best"
                end
            end
        end
    end
    return "other"
end

function Recommend.Gems(specID)
    local spec = Recommend.SpecData(specID)
    return spec and spec.gems or {}
end

function Recommend.Consumables(specID)
    local c = T.Data.consumables
    local rows = {
        { label = L["Flask"], items = c.flask[Recommend.SpecData(specID).order[1]] },
        { label = L["Combat Potion"], items = c.potion, alt = c.potionAlt },
        { label = L["Food"], items = c.food },
        { label = L["Augment Rune"], items = c.rune },
    }
    if not c.noOil[specID] then rows[#rows + 1] = { label = L["Weapon Oil"], items = c.oil } end
    return rows
end
