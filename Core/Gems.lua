local _, T = ...

local Gems = {}
T.Gems = Gems

Gems.COLORS = { "GARNET", "PERIDOT", "AMETHYST", "LAPIS" }

local nameByItem, colorByItem, colorDiamond

local function index()
    if nameByItem then return end
    nameByItem, colorByItem, colorDiamond = {}, {}, {}
    for name, ids in pairs(T.Data.gems) do
        for _, id in ipairs(ids) do nameByItem[id] = name end
    end
    for color, ids in pairs(T.Data.gemColors) do
        for _, id in ipairs(ids) do colorByItem[id] = color end
    end
    for _, id in ipairs(T.Data.colorDiamonds) do colorDiamond[id] = true end
end

function Gems.Name(itemID)
    index()
    return nameByItem[itemID]
end

function Gems.Color(itemID)
    index()
    return colorByItem[itemID]
end

-- Powerful and Telluric diamonds grow with each distinct gem colour.
function Gems.CountsColors(picks, worn)
    index()
    for _, id in ipairs(worn) do
        if colorDiamond[id] then return true end
    end
    for _, pick in ipairs(picks.diamond or {}) do
        for _, id in ipairs(T.Data.gems[pick[1]] or {}) do
            if colorDiamond[id] then return true end
        end
    end
    return false
end
