local _, T = ...

local Stats = {}
T.Stats = Stats

local CR_VERS_DONE = CR_VERSATILITY_DAMAGE_DONE

-- Midnight returns secret values in combat; comparing them raises an error.
local issecretvalue = issecretvalue or function() return false end

local function spellCrit()
    local best = 0
    for school = 2, 7 do
        best = math.max(best, GetSpellCritChance(school))
    end
    return best
end

-- percent, rating, rating index, coefficient of the rating bonus
local readers = {
    CRIT = function()
        local best, index = -1, nil
        for _, cr in ipairs({ CR_CRIT_MELEE, CR_CRIT_RANGED, CR_CRIT_SPELL }) do
            local rating = GetCombatRating(cr)
            if rating > best then best, index = rating, cr end
        end
        return math.max(GetCritChance(), GetRangedCritChance(), spellCrit()), best, index, 1
    end,
    HASTE = function()
        return GetHaste(), GetCombatRating(CR_HASTE_MELEE), CR_HASTE_MELEE, 1
    end,
    MASTERY = function()
        local effect, coefficient = GetMasteryEffect()
        return effect, GetCombatRating(CR_MASTERY), CR_MASTERY, coefficient
    end,
    VERS = function()
        return GetCombatRatingBonus(CR_VERS_DONE) + GetVersatilityBonus(CR_VERS_DONE),
            GetCombatRating(CR_VERS_DONE), CR_VERS_DONE, 1
    end,
}

function Stats.Readable()
    return not (issecretvalue(GetHaste()) or issecretvalue(GetCritChance())
        or issecretvalue(GetCombatRating(CR_MASTERY)))
end

-- Haste from rating multiplies with haste from talents and auras; the other stats add up.
local function convert(key, pct, own, goal, coefficient)
    if key == "HASTE" then
        return ((1 + pct / 100) * (1 + goal / 100) / (1 + own / 100) - 1) * 100
    end
    return pct + (goal - own) * coefficient
end

-- The top players' sheet percentages depend on buffs and spec quirks at logout, so the target
-- is their average rating, converted for this character: own percent, rating bonus swapped.
-- -> percent, rating, target percent; nil while secret
function Stats.Get(key, goalRating)
    local ok, pct, rating, index, coefficient = pcall(readers[key])
    if not ok or issecretvalue(pct) or issecretvalue(rating) or issecretvalue(coefficient) then return nil end
    local own = GetCombatRatingBonusForCombatRatingValue(index, rating)
    local goal = GetCombatRatingBonusForCombatRatingValue(index, goalRating)
    if not own or not goal or issecretvalue(own) or issecretvalue(goal) then return nil end
    return pct, rating, convert(key, pct, own, goal, coefficient)
end
