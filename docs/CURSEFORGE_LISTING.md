# CurseForge listing

Copy-ready text for the CurseForge project form. Keep it aligned with README.md
and the tested client; do not advertise clients or versions that have not been
tested.

## Project fields

| Field | Value |
| --- | --- |
| Name | Dyre's Cooldown Chimes |
| Class | Addons |
| Main category | Buffs & Debuffs. Keep it identical to the TOC `## Category`, which groups the AddOn in the in-game AddOn list. |
| Additional categories | None yet (CurseForge allows up to 4; unrelated ones can send the project back for changes). |
| Relations | Dyre's Sounds, required dependency (set by each CI upload) |
| Author shown | Dyre, set through the CurseForge account's username |
| License | MIT License |
| Source | https://github.com/jbedworth/DyresCooldownChimes |
| Issues | https://github.com/jbedworth/DyresCooldownChimes/issues |

## Summary

A sound just before your spells are ready again, for any class in World of Warcraft: Forever, also in combat. Every rank of a spell counts.

## Description

Paste this with the description editor in Markdown mode. Pasted into the rich
text editor, the headings, bullets, and bold show as raw, escaped markdown.

Per-file changelogs need no manual text: each CI upload uses the version's
`CHANGELOG.md` section, through `release-notes.md`.

```markdown
**Dyre's Cooldown Chimes** plays a sound just before your spells are ready again, for any class, also in combat. It is the cooldown chimes from Mage Tools Forever and Warlock Tools Forever, on their own.

### Why not the Cooldown Manager?
On Forever, the game's Cooldown Manager treats each rank of a spell as a different spell, and does not handle effects on several mobs correctly. Dyre's Cooldown Chimes matches spells by name, so every rank counts.

### Chimes
- Cast a spell, and a chime plays just before it is ready again: 0 to 3 seconds early, half a second by default.
- Works in combat: DCC times each cooldown from your cast, and learns the real length out of combat.
- Each spell has a switch and its own sound, from a menu grouped like the Cooldown Manager's. Text to Speech says "Blink ready".
- Spells for Mages, Warlocks, Druids, Priests, Paladins, Warriors, Rogues, Hunters, and Shamans. Cold Snap and Preparation cancel the chimes of the spells they reset.

### Needs Dyre's Sounds
The sounds come from **Dyre's Sounds**; the CurseForge app installs it for you. Without it, DCC says so in chat and plays nothing.

### With Mage Tools Forever or Warlock Tools Forever
They still play their own chimes. Until their next update, turn off their Cooldown chimes, or you hear each chime twice. DCC reminds you once at login.

### Commands
- `/dcc` or `/dcc options` opens the settings (Options > AddOns).
- `/dcc debug` shows what DCC knows about your spells.
- `/chimes` works the same, in case another AddOn uses `/dcc`.

### Compatibility
Beta, for the Forever beta client 1.60.1. If a client update removes an API it needs, it says so in chat and the chimes stay off.

WowUp users (2.24.0 or later): install from the repository URL, and Dyre's Sounds the same way; GitHub releases carry the Forever metadata WowUp needs.

Source, issues, and license (MIT): https://github.com/jbedworth/DyresCooldownChimes
```
