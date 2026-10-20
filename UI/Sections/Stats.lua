local _, T = ...
local L = T.L
local UI = T.UI

local NAMES = {
    CRIT = STAT_CRITICAL_STRIKE, HASTE = STAT_HASTE, MASTERY = STAT_MASTERY, VERS = STAT_VERSATILITY,
}
local BAR_GREEN  = { 0.36, 0.64, 0.36 }
local BAR_YELLOW = { 0.78, 0.68, 0.30 }
local BAR_RED    = { 0.72, 0.30, 0.30 }
local ON_TARGET = 2
local NEAR_TARGET = 6
local MARK_AT = 0.8
local RETRY = 2

local retryPending = false

local function retryLater()
    if retryPending then return end
    retryPending = true
    C_Timer.After(RETRY, function()
        retryPending = false
        T.Window.Refresh()
    end)
end

local function barColor(pct, goal)
    local off = math.abs(pct - goal)
    if off <= ON_TARGET then return BAR_GREEN end
    if off <= NEAR_TARGET then return BAR_YELLOW end
    return BAR_RED
end

local function tooltip(key, pct, rating, goal, goalRating)
    return function(tt)
        tt:SetText(NAMES[key], 1, 1, 1)
        tt:AddDoubleLine(L["You"], ("%.1f%% (%s)"):format(pct, BreakUpLargeNumbers(rating)),
            UI.GREY[1], UI.GREY[2], UI.GREY[3], 1, 1, 1)
        tt:AddDoubleLine(L["Target"], ("%.1f%% (%s)"):format(goal, BreakUpLargeNumbers(goalRating)),
            UI.GREY[1], UI.GREY[2], UI.GREY[3], UI.GOLD[1], UI.GOLD[2], UI.GOLD[3])
        local diff = goalRating - rating
        local text = diff > 0 and L["%s rating short of the target"]
            or diff < 0 and L["%s rating above the target"] or L["On target"]
        UI.AddLine(tt, text:format(BreakUpLargeNumbers(math.abs(diff))), UI.WHITE)
        tt:AddLine(" ")
        UI.AddLine(tt, L["The target is the average rating of the top Mythic+ players of this spec, "
            .. "converted to percent for your character."], UI.GREY, true)
    end
end

-- last converted targets per spec, shown while the stats are secret
local goals = {}

local function statRow(i, specID, key, goalRating)
    local pct, rating, goal = T.Stats.Get(key, goalRating)
    goals[specID] = goals[specID] or {}
    if goal then goals[specID][key] = goal else goal = goals[specID][key] end
    local spec = {
        icon = false,
        flush = true,
        label = ("%d. %s"):format(i, NAMES[key]),
        labelColor = UI.WHITE,
        right = goal and ("%d%%"):format(math.floor(goal + 0.5)) or "\226\128\148",
        rightColor = goal and UI.GOLD or UI.GREY,
    }
    if pct then
        spec.value = ("%.1f%%"):format(pct)
        spec.bar = { value = pct, max = goal / MARK_AT, mark = goal, color = barColor(pct, goal) }
        spec.tooltip = tooltip(key, pct, rating, goal, goalRating)
    else
        spec.value, spec.valueColor = "\226\128\148", UI.GREY
    end
    T.Layout.Row(spec)
end

T.Sections.Stats = function(specID)
    local spec = T.Recommend.SpecData(specID)
    local readable = T.Stats.Readable()
    if not readable then retryLater() end
    local summary = readable and "" or UI.Colored(UI.GREY, L["locked by the game"])
    if not T.Layout.Header("stats", L["Stats"], summary) then return end
    for i, key in ipairs(spec.order) do
        statRow(i, specID, key, spec.ratings[key])
    end
end
