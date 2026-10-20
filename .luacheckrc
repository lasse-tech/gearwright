std = "lua51"
max_line_length = 120
exclude_files = { "Libs/", "dist/", "tests/", "tools/", ".cache/" }
files["Data/Specs.lua"] = { max_line_length = false }   -- generated

globals = {                                 -- written by the addon
    "GearwrightDB",
    "Gearwright_Binding",
    "Gearwright_OnAddonCompartmentClick",
    "GearwrightAboutMixin",
    "BINDING_CATEGORY_GEARWRIGHT",
    "BINDING_NAME_GEARWRIGHT_TOGGLE",
    "SlashCmdList",
    "GearwrightFrame",
    "GearwrightCloseButton",
}

read_globals = {                            -- provided by the client
    "CharacterFrame", "CharacterFrameCloseButton", "ENCHANTED_TOOLTIP_LINE", "issecretvalue",
    "CR_CRIT_MELEE", "CR_CRIT_RANGED", "CR_CRIT_SPELL", "CR_HASTE_MELEE", "CR_MASTERY",
    "CR_VERSATILITY_DAMAGE_DONE", "STAT_CRITICAL_STRIKE", "STAT_HASTE", "STAT_MASTERY", "STAT_VERSATILITY",
    "BreakUpLargeNumbers", "C_AddOns", "C_Item", "C_Timer", "C_TooltipInfo", "ChatEdit_InsertLink",
    "CreateFrame", "ElvUI", "Enum", "GameTooltip", "GetCombatRating", "GetCombatRatingBonus",
    "GetCombatRatingBonusForCombatRatingValue", "GetCritChance", "GetHaste", "GetInventoryItemLink", "GetLocale",
    "GetMasteryEffect", "GetRangedCritChance", "GetRealmName", "GetSpecialization",
    "GetSpecializationInfo", "GetSpecializationInfoByID", "GetSpellCritChance", "GetVersatilityBonus",
    "ITEM_QUALITY_COLORS", "IsLoggedIn", "IsShiftKeyDown", "LibStub", "LOCALIZED_CLASS_NAMES_MALE",
    "RAID_CLASS_COLORS", "Settings", "ToggleCharacter", "UIParent", "UnitName", "strjoin", "strsplit",
    "tostringall",
}
