# Gearwright

World of Warcraft addon (Midnight, retail): best-in-slot enchants, gems, consumables and
secondary stat targets for your spec, docked to the character frame.

## Features
- **Enchants**: best enchant per slot, ✔ / ? / ✖ against what you wear
- **Gems**: diamond and gems of the top players, socketed count, missing colours, empty sockets
- **Stats**: crit, haste, mastery, versatility in priority order as bars against the target
  (green ±2, yellow ±6, red beyond); the target is the top players' average rating, converted to
  percent for your character; locked in combat
- **Consumables**: flask, combat potion, food, augment rune, weapon oil, with the count you carry
- **Mythic+ / Raid** switch: each with its own players, enchants, gems and stat targets
- Tooltips with alternatives; Shift-click links the item in chat
- English and German

## Installation
CurseForge, Wago, or the zip from the GitHub releases unpacked into
`World of Warcraft/_retail_/Interface/AddOns`.

## Usage
- Character frame (`C`): the window docks on the right; the Gearwright button next to the
  close button toggles it
- Minimap icon: click toggles the window, right-click opens the options
- `/gw`, `/gw raid`, `/gw mplus`, `/gw dock`, `/gw config`

## Data
- [Battle.net API](https://develop.battle.net): top 50 Mythic+ players and top 50 Mythic raiders
  per spec in EU and US (enchants, gems, average stats); raid falls back to Mythic+ for a spec
  with too few raiders
- [Raider.IO API](https://raider.io/api): top Mythic guilds of the current raid
- [wago.tools](https://wago.tools): Blizzard DB2 tables for the IDs
- Raid leech picks and consumables: curated in `Data/`

## Licence
© 2026 lasse tech, Lars Gossard — <lars@lasse-tech.de>

MIT — see [LICENSE](LICENSE). The embedded libraries
(LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0) keep their own licences.
