local _, T = ...
T.Data = T.Data or {}

T.Data.consumables = {
    flask = {                                           -- by the spec's top secondary stat
        CRIT    = { 241326, 241327, 245929, 245928 },   -- Flask of the Shattered Sun
        HASTE   = { 241324, 241325, 245931, 245930 },   -- Flask of the Blood Knights
        MASTERY = { 241322, 241323, 245933, 245932 },   -- Flask of the Magisters
        VERS    = { 241320, 241321, 245926, 245927 },   -- Flask of Thalassian Resistance
    },
    potion = { 241308, 241309, 245898, 245897 },        -- Light's Potential
    potionAlt = { 241288, 241289 },                     -- Potion of Recklessness
    food = {                                            -- highest secondary stat
        275264, 275267,                                 -- Amani Cornucopia (feast), hearty
        275265, 275268,                                 -- Loa's Gathering
        275266, 275269,                                 -- Feast of Knowledge
        275260, 275262,                                 -- Puffer Plate
        275261, 275263,                                 -- Sweet-And-Sour Skewers
        275258, 275259,                                 -- Venom-Spiced Cutlets
    },
    rune = { 259085, 274797 },                          -- Void-Touched, Tidesworn Augment Rune
    oil = { 243734, 243733 },                           -- Thalassian Phoenix Oil
    noOil = { [253] = true, [254] = true },             -- ranged hunters: scopes, not oil
}
