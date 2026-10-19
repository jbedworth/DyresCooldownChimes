# Dyre's Cooldown Chimes

A sound just before your spells are ready again, for any class in World of
Warcraft: Forever (beta). It also works in combat. Settings are in
**Options → AddOns → Dyre's Cooldown Chimes**, or type `/dcc`. They are saved
per character.

It needs **Dyre's Sounds**, the sound library for Dyre's AddOns. Without it,
DCC tells you once in chat to install it, and plays nothing.

## Why not the Cooldown Manager?

The game's Cooldown Manager on Forever treats each rank of a spell as a
different spell, so you set up every rank again as you learn it, and it does
not handle effects on several mobs correctly. Dyre's Cooldown Chimes
matches spells by name: every rank of Frost Nova is Frost Nova.

## How it works

- Cast a spell, and a chime plays just before it is ready again. **Chime
  early** sets how long before: 0 to 3 seconds, half a second by default.
- The game hides cooldowns from AddOns in combat, so DCC times each one from
  your cast. Out of combat it reads the real cooldown and remembers it for
  next time; until then it uses the Classic cooldown.
- Each spell has a switch and its own sound, under the switch. The sound menu
  is grouped like the Cooldown Manager's; choosing a sound plays it. Every
  spell starts on **Interface: Talent ready**. **Text to Speech** says
  "Blink ready" in your game voice.
- Only your own class's spells are listed.

## Spells

On by default first; the rest start off.

| Class | On | Off |
|---|---|---|
| Mage | Blink, Frost Nova, Counterspell, Ice Block, Ice Barrier, Mana Shield, Evocation | Cold Snap, Fire Ward, Frost Ward, Cone of Cold, Fire Blast, Presence of Mind, Arcane Power, Combustion |
| Warlock | Death Coil, Howl of Terror, Shadow Ward, Soulstone Resurrection, Fel Domination | Shadowburn, Conflagrate, Amplify Curse, Bane of Doom, Inferno |
| Druid | Barkskin, Bash, Innervate, Rebirth | Nature's Swiftness, Frenzied Regeneration, Dash, Feral Charge, Tranquility, Challenging Roar |
| Priest | Psychic Scream, Fade, Inner Focus, Desperate Prayer | Fear Ward, Mind Blast, Silence, Power Infusion |
| Paladin | Hammer of Justice, Divine Shield, Blessing of Protection, Lay on Hands | Divine Protection, Consecration, Exorcism, Hammer of Wrath, Holy Shock, Divine Favor |
| Warrior | Charge, Intercept, Berserker Rage, Shield Wall, Last Stand | Pummel, Shield Bash, Bloodrage, Intimidating Shout, Death Wish, Recklessness, Retaliation |
| Rogue | Kick, Sprint, Evasion, Vanish, Blind | Gouge, Kidney Shot, Adrenaline Rush, Blade Flurry, Cold Blood, Preparation |
| Hunter | Feign Death, Freezing Trap, Rapid Fire | Intimidation, Bestial Wrath, Deterrence, Scatter Shot, Aimed Shot, Multi-Shot, Concussive Shot |
| Shaman | Earth Shock, Grounding Totem, Reincarnation | Nature's Swiftness, Elemental Mastery, Mana Tide Totem, Chain Lightning, Stormstrike, Earthbind Totem, Astral Recall |

- **Cold Snap** cancels the chimes of the Frost spells it resets, and
  **Preparation** the Rogue's other chimes.
- Mana Shield has no cooldown in Classic; it chimes only if the game reports
  one.
- Traps share one cooldown, so Freezing Trap stands for them; the shocks do
  too, so Earth Shock stands for them.

## With Mage Tools Forever or Warlock Tools Forever

From version 0.3.0, Mage Tools Forever and Warlock Tools Forever leave the
chimes to DCC when it is installed, so you hear each chime once. With an
older version, both play chimes: DCC reminds you once at login to turn off
**Cooldown chimes** in that AddOn's settings, or update it.

The first time DCC runs on a Mage or Warlock, it copies that character's
chime settings from Mage Tools Forever or Warlock Tools Forever: which spells
chime, their sounds, and how early.

## Commands

| Command | What it does |
|---|---|
| `/dcc`, `/dcc options` | Opens the settings |
| `/dcc debug` | Diagnostics: Dyre's Sounds, your class's spells, the cooldowns DCC uses, and the latest casts and chimes |

`/chimes` works the same, in case another AddOn uses `/dcc`.

## Compatibility

Beta, for the Forever beta client 1.60.1 (Interface 16001). DCC keeps working
on later beta builds; if a client update removes an API it needs, it says so
in chat and the chimes stay off.

**Verified in client** (with Mage Tools Forever and Warlock Tools Forever,
which time chimes the same way): your own casts stay readable in combat,
cooldowns are readable out of combat, Forever uses Classic's IDs for the Mage
spells, and the game's interface sounds play from a timer in combat.

**Not yet verified in client:** Dyre's Cooldown Chimes itself, and the spell
lists for Druids, Priests, Paladins, Warriors, Rogues, Hunters, and Shamans.
[TESTING.md](TESTING.md) has the checklist.

WowUp users (2.24.0 or later): install from the repository URL; GitHub releases
carry the Forever metadata WowUp needs. Install Dyre's Sounds the same way.

## License

MIT. See [LICENSE](LICENSE).
