# Testing

## Method

1. **Pinned source review.** Client behavior is read from Blizzard's FrameXML
   and generated API documentation at Gethe/wow-ui-source commit
   `943764493e6b16d63ded3ab304150d1f05e58b57` (`1.60.1.70338`). Source
   establishes declared APIs, templates, and code paths, not operational behavior.
2. **Automated mock tests.** `tests/run.lua` exercises startup, timing in and
   out of combat, learned cooldowns, Cold Snap and Preparation, the switches,
   sound choices through a stand-in for Dyre's Sounds (and the real library
   when a sibling `../DyresSounds` checkout exists), the missing-library
   message, saved-setting repair, slash commands and the conflict report,
   `/dcc debug`, and the reminder about Mage Tools Forever's and Warlock Tools
   Forever's chimes, against a minimal mock of the client. Mocks model secret
   values as values that raise errors on comparison, concatenation, indexing,
   or printing.
3. **In-client checks.** The checklist below covers everything mocks cannot.

```sh
.tools/luarocks-3.13.0-win32/win32/lua5.1/bin/lua5.1.exe tests/run.lua
.tools/luarocks-3.13.0-win32/win32/lua5.1/bin/luac5.1.exe -p Commands.lua Core.lua Chimes.lua Options.lua tests/run.lua
.tools/python-3.13.7/python.exe -m unittest discover -s tests -p 'test_*.py'
```

Tooling: portable Lua 5.1 (LuaRocks 3.13.0 Windows bundle), the official
python.org 3.13.7 embeddable archive, and actionlint 1.7.12 under the ignored
`.tools/` folder (copied from Dyre's Shields Up); CI uses ubuntu-24.04's
`lua5.1` package and native `python3`.

## Source findings

- `C_Spell.GetSpellCooldown` has `SecretWhenCooldownsRestricted`; in its
  result only `isEnabled`, `isActive`, and `isOnGCD` are never secret. No event
  fires when a cooldown ends. `C_Secrets.GetSpellCooldownSecrecy` reports a
  spell's cooldown secrecy (printed by `/dcc debug`).
- `UNIT_SPELLCAST_SUCCEEDED` carries `unitTarget`, `castGUID`, and `spellID`
  and is `SecretWhenUnitSpellCastRestricted`; DCC checks the spell ID with
  `issecretvalue` before using it.
- `C_AddOns.IsAddOnLoaded` returns `loadedOrLoading` and `loaded`.
- `Settings.RegisterVerticalLayoutCategory` returns the category and its
  layout; `CreateSettingsListSectionHeaderInitializer` and
  `SettingsListElementInitializer:SetParentInitializer` exist in
  Blizzard_Settings_Shared.

## Found in client

With Mage Tools Forever (MTF) and Warlock Tools Forever (WTF), whose chimes
DCC carries over unchanged in their timing:

- Your own `UNIT_SPELLCAST_SUCCEEDED` spell IDs stay readable in combat;
  aura APIs error in combat for AddOn code; the combat log
  (`COMBAT_LOG_EVENT_UNFILTERED`) is refused.
- `/mtf debug_chimes`: Classic IDs and names for every Mage chime spell; out
  of combat MTF read Blink's 15 s, Frost Nova's 25 s, and the wards' 30 s
  cooldowns; `C_Secrets.GetSpellCooldownSecrecy` returned 2 for all.
- The interface sound kits play from a timer, also in combat (found with
  Dyre's Sounds' catalog, which MTF and WTF shipped).

### Not yet checked in client

- DCC itself, its settings page, and Dyre's Sounds' nested menu in it.
- The spell IDs and Classic cooldowns for Druid, Priest, Paladin, Warrior,
  Rogue, Hunter, and Shaman (all new in DCC), and whether Forever renamed any
  of them (as it renamed Curse of Doom to Bane of Doom). `/dcc debug` prints
  each spell's name as the client knows it; `name=nil` means the ID is wrong.
- Classic cooldowns most likely to differ on Forever: Fear Ward (30 s),
  Blessing of Protection (300 s), Reincarnation (3600 s), Desperate Prayer
  and Elemental Mastery. DCC learns the real length after an out-of-combat
  cast, so a wrong Classic value only affects the first in-combat cast.
- Preparation resetting the Rogue's other cooldowns, and Cold Snap resetting
  the Frost spells, on Forever.
- That shared cooldowns (traps, shocks) chime once from the spell you cast.

## In-client checklist

- [ ] With Dyre's Sounds installed: the login banner shows the version and
      Dyre, on any class, and nothing about Dyre's Sounds.
- [ ] Without Dyre's Sounds: DCC says once to install it; the settings page
      shows the switches only; no Lua errors when a chime is due.
- [ ] `/dcc` opens Options > AddOns > Dyre's Cooldown Chimes with your class's
      spells, each with its sound under its switch; the menu of submenus
      shows the full name of the choice and plays a sound when chosen.
- [ ] As a Mage: Blink and Frost Nova chime half a second before they are
      ready, in and out of combat; a higher rank of Frost Nova chimes too;
      Cold Snap cancels Frost Nova's chime; Text to Speech says "Blink ready";
      the lead slider moves the chime.
- [ ] On each other class: `/dcc debug` shows `name=` for every spell (no
      `nil`), and a spell on by default chimes after a cast in combat.
- [ ] As a Rogue: Preparation cancels Sprint's chime.
- [ ] With MTF on a Mage (or WTF on a Warlock) and its chimes on: DCC says
      once at login to turn them off; with theirs off, it says nothing.
- [ ] Settings survive `/reload` and stay separate on a second character.
- [ ] Another AddOn claiming `/dcc` is reported at login, and `/chimes` works.
