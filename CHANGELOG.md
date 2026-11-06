# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-11-06

### Changed
- Mythic+ and raid data refreshed (2026-11-06)
- Specialization from `C_SpecializationInfo`, Shift-click links through `ChatFrameUtil.InsertLink`
  (`GetSpecialization`, `GetSpecializationInfo` and `ChatEdit_InsertLink` are deprecated)
- About block in the options: the embedded libraries are credited, the separate author line is gone (the copyright line names him)
- Labels instead of sentences in the options, the tooltips and the empty window, in English and German

## [0.2.0] - 2026-10-29

### Changed
- Raid uses its own data: the top 50 Mythic raiders per spec from the top Mythic guilds of the current raid, with their own enchants, gems, stat targets and flask; a spec with too few raiders falls back to Mythic+ and says so
- Mythic+ data refreshed

## [0.1.0] - 2026-10-21

### Added
- Window docked to the character frame, or free-standing
- Enchants per slot with status (best, lower rank, alternative, other, none)
- Gems: recommended diamond and gems, socketed count, gem colours, empty sockets
- Stats as bars against the target: the top players' average rating, converted to percent for your character; locked during combat
- Consumables with carried count
- Mythic+ / Raid switch
- Data for all 40 specs from the Battle.net API and wago.tools
- Minimap button, addon compartment, key binding, `/gw`, English and German
- Licence: MIT
