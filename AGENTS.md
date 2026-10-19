# Agent Guidelines

## Project purpose and scope

Dyre's Cooldown Chimes (DCC, `/dcc`) is a World of Warcraft: Forever AddOn
that plays a sound just before a chosen spell is ready again, also in combat,
for any class. It ships the cooldown chimes from Mage Tools Forever (MTF) and
Warlock Tools Forever (WTF) on their own (author-approved: features duplicated
between MTF and WTF become stand-alone "Dyre's ..." AddOns for any class).
Keep this feature set; do not add speculative features or frameworks without
agreement.

Naming (author-approved): the title starts with "Dyre's", so players can find
all of the author's AddOns by searching for it. The apostrophe is only in the
title: the folder, TOC, repository, saved variables, and globals use
`DyresCooldownChimes`. Commands `/dcc` and `/chimes` (backup), chat prefix
`DCC:`. Listings say plainly that it is for WoW: Forever.

### Every rank counts (author's reason for the AddOn, central)

- Blizzard's Cooldown Manager on Forever makes you manage each rank of a
  spell as if it were a different spell, and does not handle effects on
  multiple mobs correctly; that is why the author built WTF's tools, and why
  DCC exists beside the Cooldown Manager. README says so plainly.
- So spells are matched by name: each list entry holds one Classic spell ID,
  whose name (`C_Spell.GetSpellName`, read at login) is looked up for every
  cast. Never match chimes by spell ID, and never add one entry per rank.

### The chimes (built; carried over from MTF and WTF)

- The combat log is closed to AddOns (never register
  `COMBAT_LOG_EVENT_UNFILTERED`), `C_Spell.GetSpellCooldown` is secret under
  cooldown restrictions, and no event fires when a cooldown ends. Your own
  `UNIT_SPELLCAST_SUCCEEDED` spell IDs stay readable in combat (found in
  client). So DCC times each chime from your cast with `C_Timer.After`: the
  length it last read for that spell out of combat (saved per character, 1.5 s
  to 1 h), else the Classic length, minus the lead (setting 0-3 s in 0.5 s
  steps, default 0.5, as MageAlert's 14.5 s Blink). 0.1 s after a cast it
  reads the real cooldown when readable (never secret, longer than the global
  cooldown), learns it, and reschedules. A newer cast replaces the schedule.
- A spell with `resets` cancels the chimes of its class's spells in that
  `group`: Cold Snap the Frost spells (MTF's design), Preparation the Rogue's
  other abilities. Mana Shield has no Classic cooldown and chimes only if the
  client reports one.
- Only the player's own class's list is used and shown. The lists, in
  `Spells.lua` `CHIME_SPELLS`: Mage is MTF's and Warlock WTF's, unchanged
  (author-approved there); Druid, Priest, Paladin, Warrior, Rogue, Hunter, and
  Shaman are new, short, and not yet checked in client (TESTING.md). Each
  spell has a switch (defaults as MTF and WTF chose: the core defensive and
  utility spells on, rotation and long talent cooldowns off) and its own
  sound. Keys are unique across classes (`druidswiftness`,
  `shamanswiftness`); every class's spells are kept in the saved settings.
- A master switch "Cooldown chimes" silences all of them.

### Sounds come from Dyre's Sounds (author-approved)

- The library AddOn Dyre's Sounds (`src/DyresSounds`), through
  `DyresSounds.RequireContract(1)`: `Resolve` (MTF's and WTF's old keys map
  to the library's), `Play(key, speech)` with speech "<Spell> ready" for Text
  to Speech, `Choices()` and `SetupMenu(initializer)` for the nested sound
  menu under each switch (choosing a sound plays it), plus `List`, `Groups`,
  and `Label`, all checked as functions. Default sound "talent" (Interface:
  Talent ready, author-approved in MTF and WTF). A sound that cannot play (no
  text-to-speech voice) falls back to the default.
- The TOC lists it as `## OptionalDeps: DyresSounds`, never
  `## Dependencies`; CurseForge lists it as a required dependency
  (`RELATIONS` in scripts/publish_curseforge.py; confirm its slug once the
  project exists). Without the library, or with an older contract, DCC still
  loads and times chimes, plays nothing, shows the switches without sound
  menus, keeps saved sound keys as they are, and says once per session in
  chat what to install or update.
- DCC ships no sounds of its own; add none without agreement.

### MTF and WTF (the two-step move, author-approved)

- Step one (now): DCC ships while MTF (on a Mage) and WTF (on a Warlock) keep
  their own chimes. DCC stands aside for neither: it keeps chiming, and while
  its chimes are on it says once at login that the other AddOn also plays
  chimes and to turn those off. It detects them with
  `C_AddOns.IsAddOnLoaded`, the player's class, and their saved
  `MageToolsForeverDB.chimes.enabled` / `WarlockToolsForeverDB.chimes.enabled`
  (read only, never written; a missing table counts as on, their default).
  README tells players to turn off MTF's or WTF's chimes until their next
  update. Never edit MTF or WTF from this repository.
- On DCC's first run on a character (no saved table yet), it copies that
  character's MTF or WTF chime settings (author-approved): switches, sounds
  (mapped by Dyre's Sounds), lead, and learned cooldowns, read only. Their
  saved settings load after DCC's, so this runs at login, and once.
- Step two (later, in MTF and WTF): they stand aside for DCC. When
  `C_AddOns.IsAddOnLoaded("DyresCooldownChimes")` is true, MTF and WTF play no
  chimes and their chime settings say DCC plays them; later they drop their
  chimes, with a CHANGELOG note and a chat message. DCC then needs no change;
  its reminder simply stops showing once their chimes are off or gone. Keep
  DCC's detection working with both the old and the new MTF and WTF.

### Commands and settings

- One settings page (vertical layout, proxy settings on
  `DyresCooldownChimesDB`): "Cooldown chimes", "Chime early (seconds)" slider,
  a "Spells" heading (when the client has
  `CreateSettingsListSectionHeaderInitializer`), then each of your class's
  spells: a switch and, nested under it with `SetParentInitializer`, its
  Sound dropdown. A class without a list gets a heading saying so.
- `/dcc` and `/dcc options` open the settings; `/dcc debug` (runs even when
  DCC is unavailable) prints the class, Dyre's Sounds' state, the other
  AddOns playing chimes, each class spell (client name, known, switch, sound,
  Classic and learned lengths, readable now, secrecy, time left), the last
  cast, and the latest 12 log entries. Backup slash `/chimes`; a clash on
  `/dcc` is reported once at login.
- No class gate. DCC turns off only for a mixed install (missing namespace
  functions) or a client without `C_Timer.After`, `C_Spell.GetSpellName`,
  `GetTime`, or `CreateFrame`; reading cooldowns is optional.

## Project structure

- Runtime files: DyresCooldownChimes.toc, Commands.lua, Spells.lua, Core.lua,
  Chimes.lua, Options.lua, loaded in that order. Commands parses `/dcc`;
  Spells.lua holds every class's spells and defaults (author-approved: data-driven,
  one place; an optional `sound` per spell); Core owns saved settings and their repair, the Dyre's Sounds check, the
  login banner, install and API checks, the MTF/WTF reminder, slash conflict
  reporting, and startup; Chimes owns timing, playing, and `/dcc debug`;
  Options owns the settings page.
- tests/run.lua holds the Lua 5.1 mock suite. tests/test_*.py cover the
  release helpers in scripts/. .github/workflows/ holds CI, opt-in publishing,
  and the approval gate check.
- README.md is the user-facing overview, TESTING.md the verification method,
  source evidence, and in-client checklist, docs/RELEASE_PLAN.md the release
  process, docs/CURSEFORGE_LISTING.md the CurseForge form text, and
  CHANGELOG.md the per-release change list.
- Documentation describes purpose, design, rules, and methodology. Do not add
  dated status reports or test-result logs to the docs; CHANGELOG.md is the
  release record. Keep README's verified and not-yet-verified lists true.
- The project uses the MIT License. The public author name is `Dyre` (TOC
  `## Author`, login banner, listings); LICENSE keeps the legal name, John
  Bedworth, and the release builder requires that exact notice.
- The TOC uses `## Category: Buffs & Debuffs` (author-approved: the chimes
  cover a mix of combat and other cooldowns); keep it identical to the
  CurseForge main category, because the in-game AddOn list groups by exact
  text.
- No runtime assets. Add none without agreement.
- Git origin (when created): git@github.com:jbedworth/DyresCooldownChimes.git.
  Inspect Git state before acting and preserve user work. Text is LF under
  .gitattributes.

## Client and API verification

- Target: Forever beta 1.60.1, build 70338, Interface 16001, Lua 5.1. Pin
  source review to Gethe/wow-ui-source commit
  `943764493e6b16d63ded3ab304150d1f05e58b57`. Treat target-client
  documentation and FrameXML as authoritative; Retail and Classic examples are
  references only.
- Do not gate the runtime on client version, build, Interface, or class. Gate
  only on required APIs (Core's `REQUIRED_APIS`).
- The target client has Midnight's secret values and AddOn restrictions. Never
  compare, concatenate, index, or print a value that may be secret: check
  `DCC.IsSecret` first and print with `DCC.Describe`. Aura APIs error in
  combat for AddOn code; DCC reads no auras. Cooldown details are hidden in
  combat.
- Never register `COMBAT_LOG_EVENT_UNFILTERED`: the client refuses it.
- WoW APIs can return no values rather than nil; store results in locals before
  passing them to `tostring`. The client may not show Lua error popups, so
  diagnostics report errors in chat.

## Clean coding

- Lua 5.1 syntax and libraries only. Four-space indentation. Prefer local
  variables and functions; share state through the AddOn namespace. Expose
  globals only when WoW requires them (slash commands, saved variables),
  prefixed `DyresCooldownChimes` or `DCC`.
- Centralize meaningful constants; avoid unexplained magic numbers.
- Comment sparingly: non-obvious intent, API constraints, or tradeoffs.
- Event-driven work only; no polling or idle `OnUpdate` handlers. Timers run
  only for a scheduled chime or the read after a cast.

## Safety and error reporting

- Validate commands before changing settings. Treat bad commands, missing APIs,
  a missing library, and mixed installs as expected failures with concise
  feedback prefixed `DCC:`.
- Never prompt or open popups in combat. Never swallow errors with blanket
  `pcall` handlers or replace the error handler.
- Repair saved settings on load so a damaged or older table cannot break DCC.
- Startup is driven by Core at `PLAYER_LOGIN`; never rely on event handler
  order between files.

## Testing and documentation

- Run `.tools/luarocks-3.13.0-win32/win32/lua5.1/bin/lua5.1.exe tests/run.lua`
  and the bundled `luac5.1.exe -p` on every Lua file. Run
  `.tools/python-3.13.7/python.exe -m unittest discover -s tests -p 'test_*.py'`
  and actionlint on workflow changes. Report actual results; never invent them.
- Add focused tests alongside behavior changes. Mocks cannot prove
  protected-action rules, secret-value behavior, layout, or taint; those need
  the in-client checks in TESTING.md.

## Releases and collaboration

- Read docs/RELEASE_PLAN.md before packaging or changing release automation.
- Do not create commits, repositories, tags, uploads, or releases unless asked.
- Every release needs a `## <version>` section in CHANGELOG.md with
  player-facing changes; the builder puts it at the top of release-notes.md
  and fails without it.
- Package only DyresCooldownChimes.toc, Commands.lua, Spells.lua, Core.lua, Chimes.lua,
  Options.lua, and LICENSE under the top-level `DyresCooldownChimes/` folder,
  named `DyresCooldownChimes-<version>-forever.zip`, with the builder's
  BigWigs-format `release.json` (flavor `forever`) attached for WowUp.
- Publishing requires repository variables `ENABLE_GITHUB_RELEASES='true'`
  and, for CurseForge, `ENABLE_CURSEFORGE_UPLOADS='true'`, plus
  `CURSEFORGE_PROJECT_ID`, `CURSEFORGE_GAME_VERSION_ID`, and the `release`
  environment secret `CF_API_TOKEN` (an environment secret, never a repository
  secret). Both publish jobs use the `release` environment with a required
  reviewer; verify the gate with `gate-check.yml` before enabling publishing.
- Action pins are full commit SHAs; review any pin change against the GitHub API.
- Commit messages, when requested: imperative, capitalized subject, at most
  about 50 characters, no ending punctuation; short wrapped body when useful.
