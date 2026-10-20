local _, T = ...

local function skinWindow(S)
    local window = _G.GearwrightFrame
    if not window or window.__elvuiSkinned then return end
    window:StripTextures()
    window:SetTemplate("Transparent")
    if _G.GearwrightCloseButton then S:HandleCloseButton(_G.GearwrightCloseButton) end
    window.__elvuiSkinned = true
end

function T.SkinElvUI()
    if T.ApplyElvUISkin then return T.ApplyElvUISkin() end
    if not _G.ElvUI then return end
    if not T.DB.Profile().elvuiSkin then return end

    local ok, E = pcall(function() return unpack(_G.ElvUI) end)
    if not ok or not E then return end
    local S = E:GetModule("Skins", true)
    if not S then return end

    local function skin()
        local blizzard = E.private and E.private.skins and E.private.skins.blizzard
        if not (blizzard and blizzard.enable and blizzard.misc) then return end
        skinWindow(S)
    end

    T.ApplyElvUISkin = skin
    skin()
end
