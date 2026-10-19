# Changelog

Player-facing changes for each Dyre's Cooldown Chimes release, newest first.
The release builder copies the section for the TOC version into the GitHub
release notes and the CurseForge changelog, and fails if that section is
missing.

## 0.1.0-beta

- First release: the cooldown chimes from Mage Tools Forever and Warlock Tools Forever, on their own, for every class. A sound plays just before your chosen spells are ready again, also in combat.
- Every rank of a spell counts: spells are matched by name.
- Spells for Mages (Cold Snap cancels the Frost chimes), Warlocks, Druids, Priests, Paladins, Warriors, Rogues (Preparation cancels the others), Hunters, and Shamans. Each has a switch and its own sound, Talent ready by default; Text to Speech says the spell, as in "Blink ready".
- Chime early: 0 to 3 seconds before a spell is ready, half a second by default.
- Needs Dyre's Sounds for its sounds. Without it, DCC says so once in chat and plays nothing.
- With Mage Tools Forever or Warlock Tools Forever also installed, DCC reminds you once at login to turn off their chimes, so you do not hear each one twice.
- The first time it runs on a Mage or Warlock, DCC copies your chime settings from Mage Tools Forever or Warlock Tools Forever.
- Settings are saved per character.
