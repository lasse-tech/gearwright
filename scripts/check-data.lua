local root = arg[1] or "."
local T = { L = setmetatable({}, { __index = function(_, k) return k end }) }

for _, file in ipairs({ "Data/Specs.lua", "Data/Raid.lua", "Data/Consumables.lua" }) do
    local chunk = assert(loadfile(root .. "/" .. file))
    chunk("Gearwright", T)
end

local D, errors = T.Data, 0
local function fail(fmt, ...)
    errors = errors + 1
    io.stderr:write("  " .. fmt:format(...) .. "\n")
end

local function enchant(name, where)
    local e = D.enchants[name]
    if not e then fail("%s: enchant %q not in T.Data.enchants", where, name)
    elseif #e.ench == 0 then fail("%s: enchant %q has no enchant IDs", where, name) end
end

local function checkSpecs(table, label)
    local count = 0
    for specID, spec in pairs(table) do
        count = count + 1
        local where = label .. " " .. specID
        if #spec.order ~= 4 then fail("%s: stat order has %d entries", where, #spec.order) end
        for _, key in ipairs(spec.order) do
            if not spec.ratings[key] then fail("%s: no target rating for %s", where, key) end
        end
        for slot, picks in pairs(spec.enchants) do
            for _, pick in ipairs(picks) do enchant(pick[1], where .. " " .. slot) end
        end
        for group, picks in pairs(spec.gems) do
            for _, pick in ipairs(picks) do
                if not D.gems[pick[1]] or #D.gems[pick[1]] == 0 then
                    fail("%s %s: gem %q has no item IDs", where, group, pick[1])
                end
            end
        end
    end
    return count
end

local specs = checkSpecs(D.specs, "spec")
local raidSpecs = checkSpecs(D.raidSpecs, "raid spec")
if not D.raidInfo or not D.raidInfo.name or not D.raidInfo.bosses then fail("T.Data.raidInfo is incomplete") end

for slot, names in pairs(D.raid.all) do
    for _, name in ipairs(names) do enchant(name, "raid " .. slot) end
end
for specID, slots in pairs(D.raid.specs) do
    for slot, names in pairs(slots) do
        for _, name in ipairs(names) do enchant(name, "raid spec " .. specID .. " " .. slot) end
    end
end

local c = D.consumables
for _, key in ipairs({ "CRIT", "HASTE", "MASTERY", "VERS" }) do
    if not c.flask[key] or #c.flask[key] == 0 then fail("consumables: no flask for %s", key) end
end
for _, key in ipairs({ "potion", "food", "rune", "oil" }) do
    if not c[key] or #c[key] == 0 then fail("consumables: %s is empty", key) end
end

if specs < 40 then fail("only %d specs (expected 40)", specs) end
if errors > 0 then
    io.stderr:write(("data: %d problem(s)\n"):format(errors))
    os.exit(1)
end
print(("data: %d M+ specs, %d raid specs, every pick resolves (generated %s)"):format(specs, raidSpecs,
    D.generated))
