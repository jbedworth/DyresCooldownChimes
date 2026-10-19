-- Lua 5.1 mock suite for Dyre's Cooldown Chimes. Run from the repository root:
--   lua5.1 tests/run.lua
-- These mocks test AddOn logic, not Forever compatibility, protected actions,
-- secret-value behavior, layout, or taint; TESTING.md lists in-client checks.
-- Every test gets its own globals, clock, timers, event frames, and namespace.
if _VERSION ~= "Lua 5.1" then
    io.stderr:write("This suite requires Lua 5.1; found " .. tostring(_VERSION) .. "\n")
    os.exit(1)
end

local tests = {}
local function test(name, body)
    tests[#tests + 1] = {name = name, body = body}
end
local function equal(actual, expected, context)
    if actual ~= expected then
        error((context or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end
local function contains(actual, fragment, context)
    if type(actual) ~= "string" or not actual:find(fragment, 1, true) then
        error((context or "text") .. ": expected text containing " .. fragment .. ", got " .. tostring(actual), 2)
    end
end

local ADDON = "DyresCooldownChimes"
local SIBLING_SOUNDS = "../DyresSounds"
local SPELLS = {
    [1953] = "Blink", [122] = "Frost Nova", [865] = "Frost Nova", [10230] = "Frost Nova",
    [2139] = "Counterspell", [11958] = "Ice Block", [11426] = "Ice Barrier", [1463] = "Mana Shield",
    [12051] = "Evocation", [12472] = "Cold Snap", [543] = "Fire Ward", [6143] = "Frost Ward",
    [120] = "Cone of Cold", [2136] = "Fire Blast", [12043] = "Presence of Mind", [12042] = "Arcane Power",
    [11129] = "Combustion", [133] = "Fireball",
    [1766] = "Kick", [1767] = "Kick", [2983] = "Sprint", [5277] = "Evasion", [1856] = "Vanish",
    [14185] = "Preparation", [6789] = "Death Coil",
}
local BLINK, FROST_NOVA, FROST_NOVA_4, COLD_SNAP, FIREBALL = 1953, 122, 10230, 12472, 133
local KICK_2, SPRINT, PREPARATION = 1767, 2983, 14185

-- A secret stands in for the client's opaque combat values; tests mark them with
-- issecretvalue, and any comparison, concatenation, or printing raises an error.
local function secret()
    return setmetatable({}, {
        __eq = function() error("compared a secret value") end,
        __lt = function() error("compared a secret value") end,
        __le = function() error("compared a secret value") end,
        __concat = function() error("concatenated a secret value") end,
        __tostring = function() error("printed a secret value") end,
        __index = function() error("indexed a secret value") end,
    })
end

local function tocFiles(path)
    local files = {}
    for line in io.lines(path) do
        if line:match("%S") and not line:match("^#") then
            files[#files + 1] = line
        end
    end
    return files
end

local function fileExists(path)
    local handle = io.open(path, "r")
    if handle then
        handle:close()
        return true
    end
    return false
end

-- A stand-in for Dyre's Sounds' contract 1, recording what it plays. It knows
-- talent, magical (MTF's old key effectmagical), and voice; voice plays only
-- when state.voice is set, as the library offers it only with a voice.
local function fakeSounds(state, contract)
    local labels = {talent = "Interface: Talent ready", magical = "Dyre's Picks: Magical disappear",
        voice = "Text to Speech"}
    local aliases = {effectmagical = "magical"}
    local library = {}
    function library.RequireContract(minimum)
        if type(minimum) == "number" and minimum <= contract then
            return library
        end
    end
    function library.Resolve(key)
        key = aliases[key] or key
        return labels[key] and key or nil
    end
    function library.Label(key)
        return labels[library.Resolve(key) or ""]
    end
    function library.List() return {} end
    function library.Groups() return {} end
    function library.Play(key, speech)
        key = library.Resolve(key)
        if not key or (key == "voice" and not state.voice) then
            return false
        end
        state.played[#state.played + 1] = {key = key, speech = speech, at = state.now}
        return true
    end
    function library.Choices()
        return function() return {{value = "talent"}, {value = "magical"}} end
    end
    function library.SetupMenu(initializer)
        initializer.nestedMenu = true
    end
    return library
end

-- A fresh client and a fresh load of the AddOn, then ADDON_LOADED and
-- PLAYER_LOGIN unless options.noLogin. Options:
--   class      the player's class file (default MAGE)
--   sounds     "fake" (default), "old", "none", or "real" (the sibling checkout)
--   db         saved DyresCooldownChimesDB
--   loaded     other loaded AddOns by name; globals: extra globals
--   remove     globals to drop; skip: runtime files not to load
local function fixture(options)
    options = options or {}
    local state = {frames = {}, messages = {}, now = 100, combat = false, secrets = {}, timers = {},
        settings = {}, initializers = {}, headings = {}, played = {}, cooldowns = {}, opened = nil}
    local env = setmetatable({}, {__index = _G})
    env._G = env
    env.SlashCmdList = {}
    env.DEFAULT_CHAT_FRAME = {AddMessage = function(_, message) state.messages[#state.messages + 1] = message end}
    env.issecretvalue = function(value) return state.secrets[value] == true end
    env.GetTime = function() return state.now end
    env.UnitClass = function() return "Player", options.class or "MAGE" end
    env.C_Timer = {After = function(seconds, callback)
        state.timers[#state.timers + 1] = {at = state.now + seconds, callback = callback}
    end}
    local function secretValue()
        local value = secret()
        state.secrets[value] = true
        return value
    end
    env.C_Spell = {
        GetSpellName = function(spellID)
            if SPELLS[spellID] then
                return SPELLS[spellID]
            end
            -- An unknown spell returns no value, as the client does.
        end,
        GetSpellCooldown = function(spellID)
            if state.combat then
                return {startTime = secretValue(), duration = secretValue(), isEnabled = true}
            end
            local cooldown = state.cooldowns[spellID]
            if cooldown then
                return {startTime = cooldown.start, duration = cooldown.duration}
            end
            return {startTime = 0, duration = 0}
        end,
    }
    env.C_Secrets = {GetSpellCooldownSecrecy = function() return state.combat and secretValue() or 2 end}
    env.C_SpellBook = {IsSpellKnown = function(spellID) return SPELLS[spellID] ~= nil end}
    env.C_AddOns = {
        GetAddOnMetadata = function(_, field)
            return ({Title = "Dyre's Cooldown Chimes", Version = "0.1.0-beta", Author = "Dyre"})[field]
        end,
        IsAddOnLoaded = function(name) return (options.loaded or {})[name] == true, false end,
    }
    env.CreateFrame = function()
        local frame = {events = {}, units = {}}
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:RegisterUnitEvent(event, unit) self.events[event] = true; self.units[event] = unit end
        function frame:SetScript(_, script) self.script = script end
        state.frames[#state.frames + 1] = frame
        return frame
    end
    -- Settings: records every setting and initializer by variable.
    local function initializer(kind, setting, extra)
        local entry = {kind = kind, setting = setting, extra = extra}
        function entry:SetParentInitializer(parent, predicate) self.parent = parent; self.predicate = predicate end
        state.initializers[#state.initializers + 1] = entry
        return entry
    end
    env.Settings = {
        VarType = {Boolean = "boolean", Number = "number", String = "string"},
        RegisterVerticalLayoutCategory = function(name)
            state.category = {name = name, GetID = function() return 42 end}
            return state.category, {AddInitializer = function(_, heading) state.headings[#state.headings + 1] = heading end}
        end,
        RegisterProxySetting = function(_, variable, varType, name, default, getValue, setValue)
            local setting = {variable = variable, varType = varType, name = name, default = default}
            function setting:GetValue() return getValue() end
            function setting:SetValue(value) setValue(value) end
            state.settings[variable] = setting
            return setting
        end,
        RegisterAddOnCategory = function(registered) state.registered = registered end,
        CreateCheckbox = function(_, setting, tooltip) return initializer("checkbox", setting, tooltip) end,
        CreateSlider = function(_, setting, sliderOptions) return initializer("slider", setting, sliderOptions) end,
        CreateSliderOptions = function(minValue, maxValue, step) return {min = minValue, max = maxValue, step = step} end,
        CreateDropdown = function(_, setting, choices, tooltip)
            local entry = initializer("dropdown", setting, tooltip)
            entry.choices = choices
            return entry
        end,
        CreateControlTextContainer = function() return {} end,
        OpenToCategory = function(id) state.opened = id end,
    }
    env.CreateSettingsListSectionHeaderInitializer = function(text) return {heading = text} end
    for key, value in pairs(options.globals or {}) do env[key] = value end
    local sounds = options.sounds or "fake"
    if sounds == "fake" then
        env.DyresSounds = fakeSounds(state, 1)
    elseif sounds == "old" then
        env.DyresSounds = fakeSounds(state, 0)
    elseif sounds == "real" then
        env.SOUNDKIT = {UI_ORDERHALL_TALENT_READY_TOAST = 73280}
        env.PlaySound = function(kit) state.played[#state.played + 1] = {kit = kit, at = state.now} end
        env.PlaySoundFile = function(file) state.played[#state.played + 1] = {file = file, at = state.now} end
        local libraryNamespace = {}
        for _, path in ipairs(tocFiles(SIBLING_SOUNDS .. "/DyresSounds.toc")) do
            local chunk = assert(loadfile(SIBLING_SOUNDS .. "/" .. path))
            setfenv(chunk, env)
            chunk("DyresSounds", libraryNamespace)
        end
    end
    for _, name in ipairs(options.remove or {}) do env[name] = nil end
    env.DyresCooldownChimesDB = options.db
    local skip = {}
    for _, name in ipairs(options.skip or {}) do skip[name] = true end
    state.toc = tocFiles(ADDON .. ".toc")
    local ns = {}
    for _, path in ipairs(state.toc) do
        if not skip[path] then
            local chunk = assert(loadfile(path))
            setfenv(chunk, env)
            chunk(ADDON, ns)
        end
    end
    state.env, state.ns = env, ns
    function state.fire(event, ...)
        for _, frame in ipairs(state.frames) do
            if frame.events[event] and frame.script and (not frame.units[event] or frame.units[event] == ...) then
                frame.script(frame, event, ...)
            end
        end
    end
    function state.advance(seconds)
        local target = state.now + seconds
        while true do
            local nextIndex
            for index, timer in ipairs(state.timers) do
                if timer.at <= target and (not nextIndex or timer.at < state.timers[nextIndex].at) then
                    nextIndex = index
                end
            end
            if not nextIndex then
                break
            end
            local timer = table.remove(state.timers, nextIndex)
            state.now = math.max(state.now, timer.at)
            timer.callback()
        end
        state.now = target
    end
    function state.cast(spellID, cooldown)
        if cooldown then
            state.cooldowns[spellID] = {start = state.now, duration = cooldown}
        end
        state.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", spellID)
    end
    function state.slash(text)
        env.SlashCmdList.DYRESCOOLDOWNCHIMES(text)
    end
    function state.last()
        return state.messages[#state.messages]
    end
    function state.find(fragment)
        for _, message in ipairs(state.messages) do
            if message:find(fragment, 1, true) then
                return message
            end
        end
    end
    function state.count(fragment)
        local count = 0
        for _, message in ipairs(state.messages) do
            if message:find(fragment, 1, true) then
                count = count + 1
            end
        end
        return count
    end
    if not options.noLogin then
        state.fire("ADDON_LOADED", ADDON)
        state.fire("PLAYER_LOGIN")
    end
    return state
end

-- Install and startup ---------------------------------------------------------------

test("the TOC loads the runtime files in order and lists Dyre's Sounds as optional", function()
    local toc = table.concat(tocFiles(ADDON .. ".toc"), ",")
    equal(toc, "Commands.lua,Spells.lua,Core.lua,Chimes.lua,Options.lua")
    local text = assert(io.open(ADDON .. ".toc")):read("*a")
    contains(text, "## OptionalDeps: DyresSounds")
    equal(text:find("## Dependencies", 1, true), nil, "never a hard dependency")
    contains(text, "## SavedVariablesPerCharacter: DyresCooldownChimesDB")
    contains(text, "## Category: Buffs & Debuffs")
    contains(text, "## Title: Dyre's Cooldown Chimes")
end)
test("login says who made it and how to open the settings, on any class", function()
    for _, class in ipairs({"MAGE", "PRIEST", "WARRIOR"}) do
        local state = fixture({class = class})
        equal(state.messages[1], "DCC: Dyre's Cooldown Chimes 0.1.0-beta by Dyre", class)
        equal(state.messages[2], "DCC:   Ready. Type /dcc to open the settings.", class)
        equal(#state.messages, 2, class .. ": nothing else to say")
        equal(state.ns.available, true)
    end
end)
test("a mixed install says what is missing and stays off", function()
    local state = fixture({skip = {"Chimes.lua"}})
    equal(state.ns.available, false)
    contains(state.last(), "missing InitializeChimes")
    state.slash("options")
    contains(state.last(), "unavailable")
end)
test("a client without C_Timer.After says so and stays off", function()
    local state = fixture({remove = {"C_Timer"}})
    equal(state.ns.available, false)
    equal(state.last(), "DCC: This client lacks C_Timer.After, so the chimes stay off.")
end)

-- Timing ---------------------------------------------------------------------------

test("out of combat a chime plays half a second before the cooldown read after the cast", function()
    local state = fixture()
    state.cast(FROST_NOVA, 23)
    equal(state.ns.db.learned.frostnova, nil, "read 0.1 s after the cast")
    state.advance(0.1)
    equal(state.ns.db.learned.frostnova, 23, "the real length is learned")
    state.advance(22.3)
    equal(#state.played, 0, "not before the lead")
    state.advance(0.2)
    equal(#state.played, 1, "one chime, from the read cooldown, not Classic's 25 s")
    equal(state.played[1].key, "talent", "Talent ready by default")
    equal(state.played[1].speech, "Frost Nova ready")
    state.advance(5)
    equal(#state.played, 1, "the Classic schedule was replaced")
end)
test("every rank counts: a spell is matched by its name", function()
    local state = fixture()
    state.cast(FROST_NOVA_4, 25)
    state.advance(30)
    equal(#state.played, 1)
    equal(state.played[1].speech, "Frost Nova ready")
end)
test("in combat the secret cooldown is never read; Classic's length is used", function()
    local state = fixture()
    state.combat = true
    state.cast(BLINK)
    state.advance(14.4)
    equal(#state.played, 0)
    state.advance(0.2)
    equal(#state.played, 1, "Blink's Classic 15 s minus the 0.5 s lead")
    equal(state.ns.db.learned.blink, nil, "nothing learned from a secret cooldown")
end)
test("in combat a length learned out of combat is used, and kept across sessions", function()
    local state = fixture()
    state.cast(BLINK, 13)
    state.advance(20)
    equal(state.ns.db.learned.blink, 13)
    local again = fixture({db = state.ns.db})
    again.combat = true
    again.cast(BLINK)
    again.advance(12.4)
    equal(#again.played, 0)
    again.advance(0.2)
    equal(#again.played, 1, "13 s learned, minus the lead")
end)
test("the lead moves the chime, in steps of half a second from 0 to 3", function()
    local state = fixture()
    state.settings.DCC_LEAD:SetValue(2)
    state.combat = true
    state.cast(BLINK)
    state.advance(12.9)
    equal(#state.played, 0)
    state.advance(0.2)
    equal(#state.played, 1)
    local ns = state.ns
    equal(ns.SanitizeLead(1.3), 1.5)
    equal(ns.SanitizeLead(9), 3)
    equal(ns.SanitizeLead(-1), 0)
    equal(ns.SanitizeLead(0 / 0), 0.5, "NaN")
    equal(ns.SanitizeLead("2"), 0.5)
end)
test("casting again replaces the earlier chime; other spells and casts are ignored", function()
    local state = fixture()
    state.combat = true
    state.cast(BLINK)
    state.advance(5)
    state.cast(BLINK)
    state.cast(FIREBALL)
    state.cast(999999)
    state.advance(14.4)
    equal(#state.played, 0, "the first schedule was replaced")
    state.advance(0.2)
    equal(#state.played, 1)
    state.advance(60)
    equal(#state.played, 1)
end)
test("a secret spell ID or someone else's cast is ignored without touching it", function()
    local state = fixture()
    local hidden = secret()
    state.secrets[hidden] = true
    state.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", hidden)
    state.fire("UNIT_SPELLCAST_SUCCEEDED", "target", "Cast-2", BLINK)
    state.advance(60)
    equal(#state.played, 0)
end)
test("Cold Snap cancels the Frost chimes, not the others", function()
    local state = fixture()
    state.combat = true
    state.cast(FROST_NOVA)
    state.cast(BLINK)
    state.advance(3)
    state.cast(COLD_SNAP)
    state.advance(30)
    equal(#state.played, 1, "Blink chimes; Frost Nova was reset")
    equal(state.played[1].speech, "Blink ready")
end)
test("Preparation cancels the Rogue's other chimes", function()
    local state = fixture({class = "ROGUE"})
    state.combat = true
    state.cast(KICK_2)
    state.cast(SPRINT)
    state.cast(PREPARATION)
    state.advance(400)
    equal(#state.played, 0, "Preparation itself is off by default")
    state.settings.DCC_CHIME_PREPARATION:SetValue(true)
    state.cast(PREPARATION)
    state.advance(600)
    equal(#state.played, 1)
    equal(state.played[1].speech, "Preparation ready")
end)
test("only your own class's spells chime", function()
    local state = fixture({class = "PRIEST"})
    state.combat = true
    state.cast(BLINK)
    state.advance(60)
    equal(#state.played, 0)
end)

-- Switches and sounds ---------------------------------------------------------------

test("each spell's switch and the master switch silence its chime", function()
    local state = fixture()
    state.combat = true
    state.settings.DCC_CHIME_BLINK:SetValue(false)
    state.cast(BLINK)
    state.advance(20)
    equal(#state.played, 0, "Blink switched off")
    state.settings.DCC_CHIME_BLINK:SetValue(true)
    state.settings.DCC_ENABLED:SetValue(false)
    state.cast(BLINK)
    state.advance(20)
    equal(#state.played, 0, "all chimes off")
    state.settings.DCC_ENABLED:SetValue(true)
    state.cast(BLINK)
    state.advance(20)
    equal(#state.played, 1)
    equal(state.ns.db.spells.coldsnap, false, "Cold Snap starts off, as in MTF")
end)
test("choosing a sound saves it, plays it once, and the chime uses it", function()
    local state = fixture()
    local sound = state.settings.DCC_CHIME_BLINK_SOUND
    equal(sound:GetValue(), "talent")
    sound:SetValue("magical")
    equal(state.ns.db.sounds.blink, "magical")
    equal(#state.played, 1, "a preview")
    equal(state.played[1].key, "magical")
    sound:SetValue("kazoo")
    equal(state.ns.db.sounds.blink, "magical", "an unknown key is refused")
    state.combat = true
    state.cast(BLINK)
    state.advance(20)
    equal(state.played[#state.played].key, "magical")
end)
test("Text to Speech says the spell; without a voice the default plays", function()
    local state = fixture()
    state.voice = true
    state.settings.DCC_CHIME_BLINK_SOUND:SetValue("voice")
    equal(state.played[1].key, "voice")
    equal(state.played[1].speech, "Blink ready")
    state.voice = false
    state.ns.PreviewChime("blink")
    equal(state.played[2].key, "talent", "the default when the voice cannot play")
end)
test("the settings page: master switch, lead, then each spell with its sound under it", function()
    local state = fixture()
    equal(state.category.name, "Dyre's Cooldown Chimes")
    equal(state.registered, state.category)
    local slider = state.initializers[2]
    equal(slider.kind, "slider")
    equal(slider.extra.min, 0)
    equal(slider.extra.max, 3)
    equal(slider.extra.step, 0.5)
    equal(state.headings[1].heading, "Spells")
    local switch, dropdown = state.initializers[3], state.initializers[4]
    equal(switch.setting.name, "Blink")
    equal(dropdown.kind, "dropdown")
    equal(dropdown.parent, switch, "the sound sits under its switch")
    equal(dropdown.nestedMenu, true, "Dyre's Sounds' nested menu")
    equal(dropdown.predicate(), true)
    state.settings.DCC_CHIME_BLINK:SetValue(false)
    equal(dropdown.predicate(), false)
    equal(#state.initializers, 2 + 15 * 2, "every Mage spell has a switch and a sound")
    state.slash("")
    equal(state.opened, 42)
end)
test("a class without chime spells gets a page that says so", function()
    local state = fixture({class = "DEATHKNIGHT"})
    equal(state.headings[1].heading, "Your class has no chime spells yet.")
    equal(#state.initializers, 2)
end)

-- Without Dyre's Sounds -------------------------------------------------------------

test("without Dyre's Sounds chimes are timed, nothing plays, and DCC says so once", function()
    local state = fixture({sounds = "none", db = {sounds = {blink = "effectmagical"}}})
    equal(state.count("Install Dyre's Sounds"), 1)
    contains(state.find("Install Dyre's Sounds"), "DCC: ")
    contains(state.find("Install Dyre's Sounds"), "github.com/jbedworth/DyresSounds", "says where to get it")
    state.combat = true
    state.cast(BLINK)
    state.advance(20)
    equal(#state.played, 0)
    state.ns.ReportMissingSounds()
    state.ns.PreviewChime("blink")
    equal(state.count("Install Dyre's Sounds"), 1, "once per session")
    equal(state.ns.db.sounds.blink, "effectmagical", "a saved choice is kept for when it is installed")
    equal(state.settings.DCC_CHIME_BLINK_SOUND, nil, "no sound menus to fill")
    equal(state.initializers[3].kind, "checkbox")
    equal(state.initializers[4].kind, "checkbox")
    contains(state.initializers[1].extra, "Install Dyre's Sounds")
    state.slash("debug")
    contains(state.find("debug class="), "sounds=missing")
end)
test("an older Dyre's Sounds is treated as missing, with an update message", function()
    local state = fixture({sounds = "old"})
    equal(state.count("Update Dyre's Sounds"), 1)
    state.combat = true
    state.cast(BLINK)
    state.advance(20)
    equal(#state.played, 0)
end)
test("with the real Dyre's Sounds, a preview plays and old MTF keys carry over", function()
    if not fileExists(SIBLING_SOUNDS .. "/DyresSounds.toc") then
        print("# skipped: no sibling Dyre's Sounds checkout")
        return
    end
    local state = fixture({sounds = "real", db = {sounds = {blink = "effectmagical", frostnova = "kazoo"}}})
    equal(state.ns.db.sounds.blink, "magical", "MTF's and WTF's keys map to the library's")
    equal(state.ns.db.sounds.frostnova, "talent")
    state.ns.PreviewChime("blink")
    equal(state.played[1].file, "Interface\\AddOns\\DyresSounds\\Sounds\\MagicalDisappear.mp3")
    state.combat = true
    state.cast(FROST_NOVA)
    state.advance(30)
    equal(state.played[2].kit, 73280, "Talent ready")
end)

-- Saved settings --------------------------------------------------------------------

test("saved settings are repaired: wrong types, unknown keys, and implausible lengths", function()
    local state = fixture({db = {enabled = "yes", lead = 7, spells = {blink = false, frostnova = "on", bogus = true},
        sounds = {blink = "magical", frostnova = 5, counterspell = "kazoo"},
        learned = {blink = 14, frostnova = 0.5, iceblock = 99999, evocation = "8"}, extra = true}})
    local db = state.ns.db
    equal(db.enabled, true)
    equal(db.lead, 3)
    equal(db.spells.blink, false, "a saved switch is kept")
    equal(db.spells.frostnova, true, "a damaged switch takes its default")
    equal(db.spells.bogus, nil)
    equal(db.sounds.blink, "magical")
    equal(db.sounds.frostnova, "talent")
    equal(db.sounds.counterspell, "talent")
    equal(db.learned.blink, 14)
    equal(db.learned.frostnova, nil)
    equal(db.learned.iceblock, nil)
    equal(db.learned.evocation, nil)
    equal(db.extra, nil)
    equal(state.env.DyresCooldownChimesDB, db)
    local fresh = state.ns.SanitizeDB("broken")
    equal(fresh.enabled, true)
    equal(fresh.lead, 0.5)
    equal(fresh.spells.deathcoil, true, "every class's spells have defaults")
    equal(fresh.sounds.kick, "talent")
end)
test("the spell lists: unique keys, Classic IDs, defaults, and reset groups", function()
    local ns = fixture({noLogin = true}).ns
    local seen = {}
    for _, classFile in ipairs(ns.CLASS_ORDER) do
        local list = ns.CHIME_SPELLS[classFile]
        equal(type(list), "table", classFile)
        local groups = {}
        for _, chime in ipairs(list) do
            equal(seen[chime.key], nil, "unique key " .. chime.key)
            seen[chime.key] = true
            equal(type(chime.spell), "number", chime.key)
            equal(type(chime.label), "string", chime.key)
            equal(type(chime.on), "boolean", chime.key)
            equal(#chime.label <= 40, true, chime.key)
            if chime.group then groups[chime.group] = true end
        end
        for _, chime in ipairs(list) do
            if chime.resets then
                equal(groups[chime.resets], true, chime.key .. " resets a group of its class")
            end
        end
    end
    equal(#ns.CHIME_SPELLS.MAGE, 15, "MTF's list")
    equal(#ns.CHIME_SPELLS.WARLOCK, 10, "WTF's list")
end)

-- Commands --------------------------------------------------------------------------

test("slash commands: /dcc and /chimes, usage for anything else", function()
    local state = fixture()
    equal(state.env.SLASH_DYRESCOOLDOWNCHIMES1, "/dcc")
    equal(state.env.SLASH_DYRESCOOLDOWNCHIMES2, "/chimes")
    state.slash("  OPTIONS ")
    equal(state.opened, 42)
    state.slash("blink now")
    equal(state.last(), "DCC: Use /dcc, /dcc options, or /dcc debug.")
    state.slash("reset")
    equal(state.last(), "DCC: Use /dcc, /dcc options, or /dcc debug.")
    equal(state.ns.ParseCommand(nil), nil)
end)
test("another AddOn using /dcc is reported once at login", function()
    local state = fixture({noLogin = true})
    state.env.SlashCmdList.OTHERADDON = function() end
    state.env.SLASH_OTHERADDON1 = "/DCC"
    state.fire("ADDON_LOADED", ADDON)
    state.fire("PLAYER_LOGIN")
    equal(state.count("also uses /dcc"), 1)
    equal(state.find("also uses"), "DCC: Another AddOn (OTHERADDON) also uses /dcc. Use /chimes instead.")
end)
test("/dcc debug lists the library, spells, and recent events, also in combat", function()
    local state = fixture()
    state.cast(BLINK, 15)
    state.advance(0.1)
    state.combat = true
    state.slash("debug")
    contains(state.find("debug class="), "class=MAGE available=true enabled=true lead=0.5 sounds=installed "
        .. "otherChimes=none")
    local blink = state.find("debug blink ")
    contains(blink, "name=Blink known=true on=true sound=talent classic=15 learned=15 readNow=nil secrecy=secret")
    contains(state.find("debug manashield "), "classic=nil")
    contains(state.find("debug lastCast="), "blink")
    contains(state.find("debug log "), "scheduled blink")
    equal(state.find("debug kick "), nil, "only your class's spells")
end)
test("/dcc debug runs even when DCC is unavailable", function()
    local state = fixture({skip = {"Options.lua"}})
    equal(state.ns.available, false)
    state.slash("debug")
    contains(state.find("debug class="), "available=false")
end)

-- Mage Tools Forever and Warlock Tools Forever ---------------------------------------

test("with MTF's chimes on, a Mage is told once to turn them off", function()
    local state = fixture({loaded = {MageToolsForever = true},
        globals = {MageToolsForeverDB = {chimes = {enabled = true}}}})
    equal(state.count("Mage Tools Forever also plays cooldown chimes"), 1)
    equal(state.find("also plays"), "DCC: Mage Tools Forever also plays cooldown chimes, so you may hear "
        .. "some twice. Turn off its Cooldown chimes until its next update.")
    equal(state.env.MageToolsForeverDB.chimes.enabled, true, "their settings are only read")
    state.slash("debug")
    contains(state.find("debug class="), "otherChimes=Mage Tools Forever")
end)
test("on its first run DCC copies a Mage's chime settings from Mage Tools Forever, once", function()
    local mtf = {chimes = {enabled = true, lead = 1.5, spells = {blink = false, coldsnap = true},
        sounds = {blink = "effectmagical"}, learned = {blink = 13}}}
    local state = fixture({loaded = {MageToolsForever = true}, globals = {MageToolsForeverDB = mtf}})
    local db = state.env.DyresCooldownChimesDB
    equal(db.lead, 1.5)
    equal(db.spells.blink, false)
    equal(db.spells.coldsnap, true)
    equal(db.spells.frostnova, true, "a spell they never set keeps DCC's default")
    equal(db.sounds.blink, "magical", "their old sound keys are mapped by Dyre's Sounds")
    equal(db.sounds.frostnova, "talent", "a sound they never set keeps the default")
    equal(db.learned.blink, 13)
    equal(state.count("Copied your chime settings from Mage Tools Forever."), 1)
    equal(state.env.MageToolsForeverDB, mtf, "their settings are only read")
    local again = fixture({loaded = {MageToolsForever = true}, globals = {MageToolsForeverDB = mtf},
        db = {lead = 0.5}})
    equal(again.env.DyresCooldownChimesDB.lead, 0.5, "only on the first run: DCC's own settings win after")
    equal(again.find("Copied your chime settings"), nil)
    local priest = fixture({class = "PRIEST", loaded = {MageToolsForever = true}, globals = {MageToolsForeverDB = mtf}})
    equal(priest.find("Copied your chime settings"), nil, "only from the class's own AddOn")
end)
test("a spell's own default sound comes from the spell data", function()
    local state = fixture({skip = {}})
    local chime = state.ns.CHIME_SPELLS.MAGE[1]
    chime.sound = "magical"
    local db = state.ns.SanitizeDB({})
    equal(db.sounds[chime.key], "magical")
    equal(db.sounds[state.ns.CHIME_SPELLS.MAGE[2].key], "talent", "others keep DCC.DEFAULT_SOUND")
    chime.sound = nil
end)
test("no warning when their chimes are off, on another class, or with DCC's off", function()
    local off = fixture({loaded = {MageToolsForever = true},
        globals = {MageToolsForeverDB = {chimes = {enabled = false}}}})
    equal(off.find("also plays"), nil)
    local priest = fixture({class = "PRIEST", loaded = {MageToolsForever = true, WarlockToolsForever = true}})
    equal(priest.find("also plays"), nil, "MTF runs only on a Mage, WTF only on a Warlock")
    local warlock = fixture({class = "WARLOCK", loaded = {WarlockToolsForever = true}})
    equal(warlock.count("Warlock Tools Forever also plays cooldown chimes"), 1, "their default is on")
    local quiet = fixture({class = "WARLOCK", loaded = {WarlockToolsForever = true}, db = {enabled = false}})
    equal(quiet.find("also plays"), nil)
end)

local failed = 0
for index, entry in ipairs(tests) do
    local ok, message = xpcall(entry.body, debug.traceback)
    if ok then
        print("ok " .. index .. " - " .. entry.name)
    else
        failed = failed + 1
        print("not ok " .. index .. " - " .. entry.name)
        print(message)
    end
end
print("")
print(#tests .. " tests: " .. (#tests - failed) .. " passed, " .. failed .. " failed")
print("Mock results do not establish in-client compatibility.")
if failed > 0 then
    os.exit(1)
end
