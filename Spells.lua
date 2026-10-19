local _, DCC = ...

-- Every chime spell and its defaults, in one place (author-approved: data-driven
-- and easy to change). Add a class or spell here; Core, Chimes, and Options
-- read only this table.

-- Spells that can chime, per class: Classic IDs, matched by name so every rank
-- counts. cooldown is the Classic length in seconds, used until DCC reads the
-- real one out of combat; on is the default switch; sound (optional) is its
-- default sound, a Dyre's Sounds key (else DCC.DEFAULT_SOUND). A spell with resets
-- cancels the chimes of its class's spells in that group (Cold Snap resets
-- the Frost spells, Preparation the Rogue's). Mage and Warlock carry MTF's and
-- WTF's lists; the others are new and not yet checked in client (TESTING.md).
DCC.CLASS_ORDER = {"MAGE", "WARLOCK", "DRUID", "PRIEST", "PALADIN", "WARRIOR", "ROGUE", "HUNTER", "SHAMAN"}
DCC.CHIME_SPELLS = {
    -- Mana Shield has no cooldown in Classic; it chimes only if the client reports one.
    MAGE = {
        {key = "blink", spell = 1953, label = "Blink", cooldown = 15, on = true},
        {key = "frostnova", spell = 122, label = "Frost Nova", cooldown = 25, on = true, group = "frost"},
        {key = "counterspell", spell = 2139, label = "Counterspell", cooldown = 24, on = true},
        {key = "iceblock", spell = 11958, label = "Ice Block", cooldown = 300, on = true, group = "frost"},
        {key = "icebarrier", spell = 11426, label = "Ice Barrier", cooldown = 30, on = true, group = "frost"},
        {key = "manashield", spell = 1463, label = "Mana Shield", on = true},
        {key = "evocation", spell = 12051, label = "Evocation", cooldown = 480, on = true},
        {key = "coldsnap", spell = 12472, label = "Cold Snap", cooldown = 600, on = false, resets = "frost"},
        {key = "fireward", spell = 543, label = "Fire Ward", cooldown = 30, on = false},
        {key = "frostward", spell = 6143, label = "Frost Ward", cooldown = 30, on = false, group = "frost"},
        {key = "coneofcold", spell = 120, label = "Cone of Cold", cooldown = 10, on = false, group = "frost"},
        {key = "fireblast", spell = 2136, label = "Fire Blast", cooldown = 8, on = false},
        {key = "presenceofmind", spell = 12043, label = "Presence of Mind", cooldown = 180, on = false},
        {key = "arcanepower", spell = 12042, label = "Arcane Power", cooldown = 180, on = false},
        {key = "combustion", spell = 11129, label = "Combustion", cooldown = 180, on = false},
    },
    -- Soulstone Resurrection is the Soulstone's use. Forever names Curse of
    -- Doom Bane of Doom.
    WARLOCK = {
        {key = "deathcoil", spell = 6789, label = "Death Coil", cooldown = 120, on = true},
        {key = "howl", spell = 5484, label = "Howl of Terror", cooldown = 40, on = true},
        {key = "shadowward", spell = 6229, label = "Shadow Ward", cooldown = 30, on = true},
        {key = "soulstone", spell = 20707, label = "Soulstone Resurrection", cooldown = 1800, on = true},
        {key = "feldomination", spell = 18708, label = "Fel Domination", cooldown = 900, on = true},
        {key = "shadowburn", spell = 17877, label = "Shadowburn", cooldown = 15, on = false},
        {key = "conflagrate", spell = 17962, label = "Conflagrate", cooldown = 10, on = false},
        {key = "amplifycurse", spell = 18288, label = "Amplify Curse", cooldown = 180, on = false},
        {key = "doom", spell = 603, label = "Bane of Doom", cooldown = 60, on = false},
        {key = "inferno", spell = 1122, label = "Inferno", cooldown = 3600, on = false},
    },
    DRUID = {
        {key = "barkskin", spell = 22812, label = "Barkskin", cooldown = 60, on = true},
        {key = "bash", spell = 5211, label = "Bash", cooldown = 60, on = true},
        {key = "innervate", spell = 29166, label = "Innervate", cooldown = 360, on = true},
        {key = "rebirth", spell = 20484, label = "Rebirth", cooldown = 1800, on = true},
        {key = "druidswiftness", spell = 17116, label = "Nature's Swiftness", cooldown = 180, on = false},
        {key = "frenziedregen", spell = 22842, label = "Frenzied Regeneration", cooldown = 180, on = false},
        {key = "dash", spell = 1850, label = "Dash", cooldown = 300, on = false},
        {key = "feralcharge", spell = 16979, label = "Feral Charge", cooldown = 15, on = false},
        {key = "tranquility", spell = 740, label = "Tranquility", cooldown = 300, on = false},
        {key = "challengingroar", spell = 5209, label = "Challenging Roar", cooldown = 600, on = false},
    },
    PRIEST = {
        {key = "psychicscream", spell = 8122, label = "Psychic Scream", cooldown = 30, on = true},
        {key = "fade", spell = 586, label = "Fade", cooldown = 30, on = true},
        {key = "innerfocus", spell = 14751, label = "Inner Focus", cooldown = 180, on = true},
        {key = "desperateprayer", spell = 13908, label = "Desperate Prayer", cooldown = 600, on = true},
        {key = "fearward", spell = 6346, label = "Fear Ward", cooldown = 30, on = false},
        {key = "mindblast", spell = 8092, label = "Mind Blast", cooldown = 8, on = false},
        {key = "silence", spell = 15487, label = "Silence", cooldown = 45, on = false},
        {key = "powerinfusion", spell = 10060, label = "Power Infusion", cooldown = 180, on = false},
    },
    PALADIN = {
        {key = "hammerofjustice", spell = 853, label = "Hammer of Justice", cooldown = 60, on = true},
        {key = "divineshield", spell = 642, label = "Divine Shield", cooldown = 300, on = true},
        {key = "blessingofprotection", spell = 1022, label = "Blessing of Protection", cooldown = 300, on = true},
        {key = "layonhands", spell = 633, label = "Lay on Hands", cooldown = 3600, on = true},
        {key = "divineprotection", spell = 498, label = "Divine Protection", cooldown = 300, on = false},
        {key = "consecration", spell = 26573, label = "Consecration", cooldown = 8, on = false},
        {key = "exorcism", spell = 879, label = "Exorcism", cooldown = 15, on = false},
        {key = "hammerofwrath", spell = 24275, label = "Hammer of Wrath", cooldown = 6, on = false},
        {key = "holyshock", spell = 20473, label = "Holy Shock", cooldown = 30, on = false},
        {key = "divinefavor", spell = 20216, label = "Divine Favor", cooldown = 120, on = false},
    },
    WARRIOR = {
        {key = "charge", spell = 100, label = "Charge", cooldown = 15, on = true},
        {key = "intercept", spell = 20252, label = "Intercept", cooldown = 30, on = true},
        {key = "berserkerrage", spell = 18499, label = "Berserker Rage", cooldown = 30, on = true},
        {key = "shieldwall", spell = 871, label = "Shield Wall", cooldown = 1800, on = true},
        {key = "laststand", spell = 12975, label = "Last Stand", cooldown = 600, on = true},
        {key = "pummel", spell = 6552, label = "Pummel", cooldown = 10, on = false},
        {key = "shieldbash", spell = 72, label = "Shield Bash", cooldown = 12, on = false},
        {key = "bloodrage", spell = 2687, label = "Bloodrage", cooldown = 60, on = false},
        {key = "intimidatingshout", spell = 5246, label = "Intimidating Shout", cooldown = 180, on = false},
        {key = "deathwish", spell = 12292, label = "Death Wish", cooldown = 180, on = false},
        {key = "recklessness", spell = 1719, label = "Recklessness", cooldown = 1800, on = false},
        {key = "retaliation", spell = 20230, label = "Retaliation", cooldown = 1800, on = false},
    },
    -- Preparation finishes the cooldown of the Rogue's other abilities.
    ROGUE = {
        {key = "kick", spell = 1766, label = "Kick", cooldown = 10, on = true, group = "rogue"},
        {key = "sprint", spell = 2983, label = "Sprint", cooldown = 300, on = true, group = "rogue"},
        {key = "evasion", spell = 5277, label = "Evasion", cooldown = 300, on = true, group = "rogue"},
        {key = "vanish", spell = 1856, label = "Vanish", cooldown = 300, on = true, group = "rogue"},
        {key = "blind", spell = 2094, label = "Blind", cooldown = 300, on = true, group = "rogue"},
        {key = "gouge", spell = 1776, label = "Gouge", cooldown = 10, on = false, group = "rogue"},
        {key = "kidneyshot", spell = 408, label = "Kidney Shot", cooldown = 20, on = false, group = "rogue"},
        {key = "adrenalinerush", spell = 13750, label = "Adrenaline Rush", cooldown = 300, on = false,
            group = "rogue"},
        {key = "bladeflurry", spell = 13877, label = "Blade Flurry", cooldown = 120, on = false, group = "rogue"},
        {key = "coldblood", spell = 14177, label = "Cold Blood", cooldown = 180, on = false, group = "rogue"},
        {key = "preparation", spell = 14185, label = "Preparation", cooldown = 600, on = false, resets = "rogue"},
    },
    -- The traps share one cooldown; Freezing Trap stands for them.
    HUNTER = {
        {key = "feigndeath", spell = 5384, label = "Feign Death", cooldown = 30, on = true},
        {key = "freezingtrap", spell = 1499, label = "Freezing Trap", cooldown = 15, on = true},
        {key = "rapidfire", spell = 3045, label = "Rapid Fire", cooldown = 300, on = true},
        {key = "intimidation", spell = 19577, label = "Intimidation", cooldown = 60, on = false},
        {key = "bestialwrath", spell = 19574, label = "Bestial Wrath", cooldown = 120, on = false},
        {key = "deterrence", spell = 19263, label = "Deterrence", cooldown = 300, on = false},
        {key = "scattershot", spell = 19503, label = "Scatter Shot", cooldown = 30, on = false},
        {key = "aimedshot", spell = 19434, label = "Aimed Shot", cooldown = 6, on = false},
        {key = "multishot", spell = 2643, label = "Multi-Shot", cooldown = 10, on = false},
        {key = "concussiveshot", spell = 5116, label = "Concussive Shot", cooldown = 12, on = false},
    },
    -- The shocks share one cooldown; Earth Shock, the interrupt, stands for them.
    SHAMAN = {
        {key = "earthshock", spell = 8042, label = "Earth Shock", cooldown = 6, on = true},
        {key = "groundingtotem", spell = 8177, label = "Grounding Totem", cooldown = 15, on = true},
        {key = "reincarnation", spell = 20608, label = "Reincarnation", cooldown = 3600, on = true},
        {key = "shamanswiftness", spell = 16188, label = "Nature's Swiftness", cooldown = 180, on = false},
        {key = "elementalmastery", spell = 16166, label = "Elemental Mastery", cooldown = 180, on = false},
        {key = "manatide", spell = 16190, label = "Mana Tide Totem", cooldown = 300, on = false},
        {key = "chainlightning", spell = 421, label = "Chain Lightning", cooldown = 6, on = false},
        {key = "stormstrike", spell = 17364, label = "Stormstrike", cooldown = 20, on = false},
        {key = "earthbindtotem", spell = 2484, label = "Earthbind Totem", cooldown = 15, on = false},
        {key = "astralrecall", spell = 556, label = "Astral Recall", cooldown = 900, on = false},
    },
}
