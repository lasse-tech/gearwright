local _, T = ...

T.dbDefaults = {
    profile = {
        content     = "mplus",  -- mplus | raid
        dock        = true,
        showTooltip = true,
        locked      = false,
        elvuiSkin   = true,
        minimap     = { hide = false },
        window      = { point = "CENTER", relPoint = "CENTER", x = 300, y = 0, shown = false, dockShown = true },
    },
    char = {
        fold = {},
    },
}

local DB = {}
T.DB = DB

local function copyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            copyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function DB.Initialize()
    local sv = _G.GearwrightDB
    if type(sv) ~= "table" then
        sv = {}
        _G.GearwrightDB = sv
    end

    local charKey = (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")

    sv.profileKeys = sv.profileKeys or {}
    local profileKey = sv.profileKeys[charKey] or "Default"
    sv.profileKeys[charKey] = profileKey

    sv.profiles = sv.profiles or {}
    sv.profiles[profileKey] = sv.profiles[profileKey] or {}
    sv.char = sv.char or {}
    sv.char[charKey] = sv.char[charKey] or {}

    local db = { profile = sv.profiles[profileKey], char = sv.char[charKey] }
    copyDefaults(db.profile, T.dbDefaults.profile)
    copyDefaults(db.char, T.dbDefaults.char)

    T.Addon.db = db
    return db
end

function DB.Profile() return T.Addon.db.profile end
function DB.Char()    return T.Addon.db.char end

function DB.Content() return DB.Profile().content end
function DB.SetContent(content) DB.Profile().content = content end

function DB.IsFolded(key) return DB.Char().fold[key] == true end
function DB.ToggleFold(key)
    local fold = DB.Char().fold
    fold[key] = (not fold[key]) or nil
end

function DB.WindowPos() return DB.Profile().window end
function DB.WindowShown() return DB.Profile().window.shown == true end
function DB.SetWindowShown(shown) DB.Profile().window.shown = shown and true or false end
function DB.SaveWindowPos(point, relPoint, x, y)
    local w = DB.Profile().window
    w.point, w.relPoint, w.x, w.y = point, relPoint, x, y
end

function DB.DockShown() return DB.Profile().window.dockShown ~= false end
function DB.SetDockShown(shown) DB.Profile().window.dockShown = shown and true or false end
