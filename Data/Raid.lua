local _, T = ...
T.Data = T.Data or {}

T.Data.raid = {
    all = {                                             -- not for tanks
        HEAD     = { "Enchant Helm - Empowered Hex of Leeching" },
        SHOULDER = { "Enchant Shoulders - Silvermoon's Mending" },
        FEET     = { "Enchant Boots - Shaladrassil's Roots" },
    },
    specs = {},                                         -- specID -> { SLOT = { name, ... } }
}
