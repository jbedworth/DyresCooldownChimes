local _, DCC = ...

-- Cooldown chimes (author-approved in MTF, after MageAlert, and ported to WTF):
-- a sound just before a chosen spell is ready again, also in combat. The
-- client hides cooldown details from AddOns in combat and offers no event
-- when a cooldown ends, and the combat log is closed to AddOns. Your own cast
-- (UNIT_SPELLCAST_SUCCEEDED) stays readable in combat, so DCC times each
-- cooldown itself from it: the length it last read for that spell out of
-- combat, else Classic's, and right after an out-of-combat cast it reads the
-- real time left. A spell is matched by its name, so every rank counts.

-- Seconds after a cast before DCC reads its cooldown, once the client has set it.
local READ_DELAY = 0.1
-- Shorter cooldowns are the global cooldown, not the spell's own.
local GLOBAL_COOLDOWN = 1.5
-- The latest casts, schedules, and chimes, for /dcc debug.
local LOG_SIZE = 12

local chimes = {list = {}, byName = {}, generation = {}, readyAt = {}, lastCast = nil, log = {}}

local function Log(text)
    table.insert(chimes.log, 1, {time = GetTime(), text = text})
    chimes.log[LOG_SIZE + 1] = nil
end

-- A chime's own sound through Dyre's Sounds; Text to Speech says
-- "<Spell> ready". A sound the client cannot play (no voice installed) falls
-- back to the default. Without the library nothing plays.
local function Play(chime)
    local library = DCC.SoundLibrary()
    if not library then
        return false
    end
    if library.Play(DCC.db.sounds[chime.key], chime.label .. " ready") then
        return true
    end
    return library.Play(DCC.DEFAULT_SOUND, chime.label .. " ready")
end

local function FindChime(key)
    for _, classFile in ipairs(DCC.CLASS_ORDER) do
        for _, chime in ipairs(DCC.ClassChimes(classFile)) do
            if chime.key == key then
                return chime
            end
        end
    end
end

-- Plays a chime's sound once, so the settings page can preview it.
function DCC.PreviewChime(key)
    local chime = FindChime(key)
    if chime then
        Play(chime)
    end
end

local function Cancel(chime)
    chimes.generation[chime.key] = (chimes.generation[chime.key] or 0) + 1
    chimes.readyAt[chime.key] = nil
end

-- Chimes `lead` seconds before a cooldown of this many seconds ends; a newer
-- schedule for the same spell replaces this one.
local function Schedule(chime, seconds, source)
    Cancel(chime)
    local generation = chimes.generation[chime.key]
    chimes.readyAt[chime.key] = GetTime() + seconds
    Log(string.format("scheduled %s #%d in %.1fs (%s)", chime.key, generation, seconds, source))
    C_Timer.After(math.max(0, seconds - DCC.db.lead), function()
        if chimes.generation[chime.key] ~= generation then
            return
        end
        chimes.readyAt[chime.key] = nil
        if DCC.db.enabled and DCC.db.spells[chime.key] then
            Log(string.format("played %s #%d", chime.key, generation))
            Play(chime)
        end
    end)
end

-- The cooldown as the client reports it, or nil while it is secret or idle.
local function ReadCooldown(spellID)
    if type(C_Spell.GetSpellCooldown) ~= "function" then
        return nil
    end
    local info = C_Spell.GetSpellCooldown(spellID)
    if type(info) ~= "table" then
        return nil
    end
    local start, duration = info.startTime, info.duration
    if DCC.IsSecret(start) or DCC.IsSecret(duration) or type(start) ~= "number" or type(duration) ~= "number"
        or duration <= GLOBAL_COOLDOWN then
        return nil
    end
    return duration, start + duration - GetTime()
end

-- Right after a cast, the real cooldown: learned for next time, and the
-- chime rescheduled to it.
local function Refine(chime, spellID)
    local duration, left = ReadCooldown(spellID)
    if not duration then
        return
    end
    DCC.db.learned[chime.key] = math.max(DCC.LEARNED_MIN,
        math.min(DCC.LEARNED_MAX, math.floor(duration * 10 + 0.5) / 10))
    if left > 0 then
        Schedule(chime, left, "read")
    end
end

local function OnCast(spellID)
    if DCC.IsSecret(spellID) or type(spellID) ~= "number" then
        return
    end
    local name = C_Spell.GetSpellName(spellID)
    if DCC.IsSecret(name) or type(name) ~= "string" then
        return
    end
    local chime = chimes.byName[name]
    if not chime then
        return
    end
    chimes.lastCast = {key = chime.key, spell = spellID, time = GetTime()}
    Log(string.format("cast %s spell=%d", chime.key, spellID))
    if chime.resets then
        for _, other in ipairs(chimes.list) do
            if other.group == chime.resets and other ~= chime then
                Cancel(other)
            end
        end
        Log("reset " .. chime.resets)
    end
    local seconds = DCC.db.learned[chime.key] or chime.cooldown
    if seconds then
        Schedule(chime, seconds, DCC.db.learned[chime.key] and "learned" or "classic")
    end
    C_Timer.After(READ_DELAY, function() Refine(chime, spellID) end)
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, _, _, _, spellID)
    OnCast(spellID)
end)

-- Only the player's own class's spells, each found by the name of its
-- Classic ID, so a cast of any rank finds it.
function DCC.InitializeChimes(classFile)
    chimes.list = DCC.ClassChimes(classFile)
    chimes.byName = {}
    for _, chime in ipairs(chimes.list) do
        local name = C_Spell.GetSpellName(chime.spell)
        if type(name) == "string" and not DCC.IsSecret(name) then
            chimes.byName[name] = chime
        end
    end
    events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end

local SOUNDS_STATES = {ok = "installed", missing = "missing", old = "too old"}

-- /dcc debug: the library, the other AddOns playing chimes, each of your
-- class's chime spells as the client knows it, whether its cooldown is
-- readable now, the length DCC uses, the sound, and the latest events.
function DCC.ReportDebug()
    local function Report(text)
        DCC.Report("debug " .. text)
    end
    local db = DCC.db
    local _, state = DCC.SoundLibrary()
    local others = table.concat(DCC.OtherChimes(DCC.classFile), ", ")
    Report(string.format("class=%s available=%s enabled=%s lead=%s sounds=%s otherChimes=%s",
        tostring(DCC.classFile), tostring(DCC.available), tostring(db and db.enabled), tostring(db and db.lead),
        SOUNDS_STATES[state], others ~= "" and others or "none"))
    local secrecy = type(C_Secrets) == "table" and type(C_Secrets.GetSpellCooldownSecrecy) == "function"
    local readable = type(C_Spell) == "table" and type(C_Spell.GetSpellName) == "function"
    local now = GetTime()
    for _, chime in ipairs(DCC.ClassChimes(DCC.classFile)) do
        local known = type(C_SpellBook) == "table" and type(C_SpellBook.IsSpellKnown) == "function"
            and C_SpellBook.IsSpellKnown(chime.spell)
        -- The client returns no value for an unknown spell; tostring needs one.
        local name = readable and C_Spell.GetSpellName(chime.spell)
        local duration = readable and ReadCooldown(chime.spell)
        Report(string.format("%s name=%s known=%s on=%s sound=%s classic=%s learned=%s readNow=%s secrecy=%s "
            .. "readyIn=%s", chime.key, DCC.Describe(name), DCC.Describe(known),
            tostring(db and db.spells[chime.key]), tostring(db and db.sounds[chime.key]),
            tostring(chime.cooldown), tostring(db and db.learned[chime.key]), tostring(duration),
            secrecy and DCC.Describe(C_Secrets.GetSpellCooldownSecrecy(chime.spell)) or "n/a",
            chimes.readyAt[chime.key] and string.format("%.1fs", chimes.readyAt[chime.key] - now) or "-"))
    end
    local last = chimes.lastCast
    Report("lastCast=" .. (last and string.format("%s %.1fs ago", last.key, now - last.time) or "none"))
    for _, entry in ipairs(chimes.log) do
        Report(string.format("log %.1fs ago %s", now - entry.time, entry.text))
    end
end
