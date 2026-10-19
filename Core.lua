local addonName, DCC = ...

-- Dyre's Cooldown Chimes: the cooldown chimes from Mage Tools Forever and
-- Warlock Tools Forever on their own, for any class. A sound just before a
-- chosen spell is ready again, also in combat. Spells match by name, so every
-- rank counts (the reason this exists beside the Cooldown Manager, which on
-- Forever treats each rank as a different spell). The sounds come from the
-- library Dyre's Sounds. This file owns saved settings and their repair, the
-- spell lists, the login banner, install and API checks, slash conflict
-- reporting, and startup.
local DEFAULT_TITLE = "Dyre's Cooldown Chimes"
local READY_MESSAGE = "  Ready. Type /dcc to open the settings."
local SLASH_KEY = "DYRESCOOLDOWNCHIMES"
local PRIMARY_SLASH = "/dcc"
local BACKUP_SLASH = "/chimes"
local MAX_SLASH_ALIASES = 10
DCC.available = false

function DCC.Report(message)
    DEFAULT_CHAT_FRAME:AddMessage("DCC: " .. tostring(message))
end

-- Combat data can be a secret value on the target client: code may store and
-- pass it on, but never compare, concatenate, index, or print it.
function DCC.IsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value) == true
end

-- Text for diagnostics that never touches a secret value's contents.
function DCC.Describe(value)
    if DCC.IsSecret(value) then
        return "secret"
    end
    return tostring(value)
end

-- Seconds before a cooldown ends that its chime plays, so you can act the
-- moment it is ready (as MageAlert's 14.5 s for Blink's 15).
DCC.LEAD_MIN = 0
DCC.LEAD_MAX = 3
DCC.LEAD_STEP = 0.5
DCC.DEFAULT_LEAD = 0.5
-- Interface: Talent ready (author-approved in MTF and WTF: a good sound for a
-- spell becoming available; players change any of them).
DCC.DEFAULT_SOUND = "talent"
-- A cooldown read in client, kept only when plausible (the longest Classic
-- cooldowns, Inferno and Lay on Hands, are an hour).
DCC.LEARNED_MIN = 1.5
DCC.LEARNED_MAX = 3600

-- The chime spells of a class, in settings order; none for a class without a list.
function DCC.ClassChimes(classFile)
    return DCC.CHIME_SPELLS[classFile] or {}
end

-- Dyre's Sounds, when installed with the contract DCC needs, else nil. The
-- TOC lists it as OptionalDeps, so DCC loads (and times chimes) without it.
local SOUNDS_CONTRACT = 1
local SOUNDS_FUNCTIONS = {"List", "Groups", "Label", "Resolve", "Play", "Choices", "SetupMenu"}

function DCC.SoundLibrary()
    local library = rawget(_G, "DyresSounds")
    if type(library) ~= "table" or type(library.RequireContract) ~= "function" then
        return nil, "missing"
    end
    library = library.RequireContract(SOUNDS_CONTRACT)
    if type(library) ~= "table" then
        return nil, "old"
    end
    for _, name in ipairs(SOUNDS_FUNCTIONS) do
        if type(library[name]) ~= "function" then
            return nil, "old"
        end
    end
    return library, "ok"
end

-- Dyre's Sounds is unlisted on CurseForge (author's choice, like QuestieDB), so
-- the message says where to get it.
local SOUNDS_WHERE = " Get it from CurseForge or github.com/jbedworth/DyresSounds."
local SOUNDS_MESSAGES = {
    missing = "Install Dyre's Sounds to hear the chimes. Without it, DCC still times them but plays nothing."
        .. SOUNDS_WHERE,
    old = "Update Dyre's Sounds to hear the chimes. This version is too old for DCC, so it plays nothing."
        .. SOUNDS_WHERE,
}

-- Says once per session what to install when the sounds are missing.
function DCC.ReportMissingSounds()
    local library, state = DCC.SoundLibrary()
    if library or DCC.soundsReported then
        return
    end
    DCC.soundsReported = true
    DCC.Report(SOUNDS_MESSAGES[state])
end

-- Reads TOC fields so the banner follows the packaged version; never gates operations.
local function Metadata(field)
    if type(C_AddOns) ~= "table" or type(C_AddOns.GetAddOnMetadata) ~= "function" then
        return nil
    end
    local value = C_AddOns.GetAddOnMetadata(addonName, field)
    if type(value) == "string" and value:find("%S") then
        return value
    end
end

local function ReportLoaded(available)
    local banner = Metadata("Title") or DEFAULT_TITLE
    local version, author = Metadata("Version"), Metadata("Author")
    if version then
        banner = banner .. " " .. version
    end
    if author then
        banner = banner .. " by " .. author
    end
    DCC.Report(banner)
    if available then
        DCC.Report(READY_MESSAGE)
    end
end

-- Functions other runtime files must define. A mixed install of old and new
-- files otherwise fails silently, because the client hides Lua errors by default.
local REQUIRED_NAMESPACE = {"ParseCommand", "HandleCommand", "InitializeChimes", "PreviewChime", "ReportDebug",
    "InitializeOptions", "OpenSettings"}
-- Client APIs the chimes cannot work without. Reading cooldowns
-- (C_Spell.GetSpellCooldown) is optional: without it DCC uses Classic's lengths.
local REQUIRED_APIS = {
    {"C_Timer", "After"},
    {"C_Spell", "GetSpellName"},
    {nil, "GetTime"},
    {nil, "CreateFrame"},
}

local function CheckInstalledFiles()
    if type(DCC.CHIME_SPELLS) ~= "table" then
        return false, "AddOn files are from different versions (missing Spells.lua). Reinstall every "
            .. "Dyre's Cooldown Chimes file, then restart the client."
    end
    for _, name in ipairs(REQUIRED_NAMESPACE) do
        if type(DCC[name]) ~= "function" then
            return false, "AddOn files are from different versions (missing " .. name
                .. "). Reinstall every Dyre's Cooldown Chimes file, then restart the client."
        end
    end
    for _, api in ipairs(REQUIRED_APIS) do
        local owner = _G
        if api[1] then
            owner = rawget(_G, api[1])
        end
        if type(owner) ~= "table" or type(owner[api[2]]) ~= "function" then
            local name = api[1] and (api[1] .. "." .. api[2]) or api[2]
            return false, "This client lacks " .. name .. ", so the chimes stay off."
        end
    end
    return true
end

function DCC.SanitizeLead(value)
    if type(value) ~= "number" or value ~= value then
        return DCC.DEFAULT_LEAD
    end
    local stepped = math.floor(value / DCC.LEAD_STEP + 0.5) * DCC.LEAD_STEP
    return math.max(DCC.LEAD_MIN, math.min(DCC.LEAD_MAX, stepped))
end

-- A saved sound key in the library's own spelling (it maps MTF's and WTF's
-- old keys), else the default (the spell's own, else DCC.DEFAULT_SOUND).
-- Without the library a saved key is kept as it is, so a missing library
-- never resets the player's choices.
function DCC.SanitizeSound(key, default)
    default = default or DCC.DEFAULT_SOUND
    if type(key) ~= "string" then
        return default
    end
    local library = DCC.SoundLibrary()
    if not library then
        return key
    end
    return library.Resolve(key) or default
end

-- Per-character settings in DyresCooldownChimesDB, repaired on load so a
-- damaged or older table can never break the AddOn. Every class's spells are
-- kept, so the table does not depend on when the class is known.
function DCC.SanitizeDB(db)
    db = type(db) == "table" and db or {}
    local spells = type(db.spells) == "table" and db.spells or {}
    local sounds = type(db.sounds) == "table" and db.sounds or {}
    local learned = type(db.learned) == "table" and db.learned or {}
    local clean = {
        enabled = db.enabled ~= false,
        lead = DCC.SanitizeLead(db.lead),
        spells = {},
        sounds = {},
        learned = {},
    }
    for _, classFile in ipairs(DCC.CLASS_ORDER) do
        for _, chime in ipairs(DCC.ClassChimes(classFile)) do
            if type(spells[chime.key]) == "boolean" then
                clean.spells[chime.key] = spells[chime.key]
            else
                clean.spells[chime.key] = chime.on
            end
            clean.sounds[chime.key] = DCC.SanitizeSound(sounds[chime.key], chime.sound)
            local seconds = learned[chime.key]
            if type(seconds) == "number" and seconds >= DCC.LEARNED_MIN and seconds <= DCC.LEARNED_MAX then
                clean.learned[chime.key] = seconds
            end
        end
    end
    return clean
end

-- Mage Tools Forever (on a Mage) and Warlock Tools Forever (on a Warlock)
-- still play their own chimes. DCC stands aside for neither; it says once at
-- login to turn theirs off, until they stand aside for DCC. Their saved
-- settings are only read, never written.
DCC.OTHER_CHIMES = {
    {addon = "MageToolsForever", title = "Mage Tools Forever", class = "MAGE", db = "MageToolsForeverDB"},
    {addon = "WarlockToolsForever", title = "Warlock Tools Forever", class = "WARLOCK",
        db = "WarlockToolsForeverDB"},
}

local function AddOnLoaded(name)
    if type(C_AddOns) ~= "table" or type(C_AddOns.IsAddOnLoaded) ~= "function" then
        return false
    end
    local loaded = C_AddOns.IsAddOnLoaded(name)
    return loaded == true
end

-- The titles of the other AddOns playing chimes on this character.
function DCC.OtherChimes(classFile)
    local titles = {}
    for _, other in ipairs(DCC.OTHER_CHIMES) do
        if other.class == classFile and AddOnLoaded(other.addon) then
            local saved = rawget(_G, other.db)
            local chimes = type(saved) == "table" and saved.chimes
            -- Their chimes are on by default.
            if type(chimes) ~= "table" or chimes.enabled ~= false then
                titles[#titles + 1] = other.title
            end
        end
    end
    return titles
end

-- On DCC's first run, copies this character's chime settings from Mage Tools
-- Forever or Warlock Tools Forever (author-approved), so a player keeps their
-- choices. Their saved settings load after DCC's (folder order), so this runs
-- at login. Their keys are DCC's own for Mage and Warlock; sounds are mapped
-- by the library.
function DCC.ImportOtherChimes(classFile)
    for _, other in ipairs(DCC.OTHER_CHIMES) do
        local saved = other.class == classFile and rawget(_G, other.db)
        local chimes = type(saved) == "table" and saved.chimes
        if type(chimes) == "table" then
            DyresCooldownChimesDB = DCC.SanitizeDB({enabled = DCC.db.enabled, lead = chimes.lead,
                spells = chimes.spells, sounds = chimes.sounds, learned = chimes.learned})
            DCC.db = DyresCooldownChimesDB
            DCC.Report("Copied your chime settings from " .. other.title .. ".")
            return true
        end
    end
    return false
end

local function ReportOtherChimes()
    if not DCC.db.enabled then
        return
    end
    for _, title in ipairs(DCC.OtherChimes(DCC.classFile)) do
        DCC.Report(title .. " also plays cooldown chimes, so you may hear some twice. Turn off its "
            .. "Cooldown chimes until its next update.")
    end
end

-- Another AddOn can register the same slash command; the last one loaded wins.
-- Returns the other command key, or nil when /dcc is ours alone.
local function FindSlashConflict()
    for key in pairs(SlashCmdList) do
        if key ~= SLASH_KEY then
            for index = 1, MAX_SLASH_ALIASES do
                local alias = _G["SLASH_" .. key .. index]
                if type(alias) == "string" and alias:lower() == PRIMARY_SLASH then
                    return key
                end
            end
        end
    end
end

SLASH_DYRESCOOLDOWNCHIMES1 = PRIMARY_SLASH
SLASH_DYRESCOOLDOWNCHIMES2 = BACKUP_SLASH
SlashCmdList[SLASH_KEY] = function(message) DCC.HandleCommand(message) end

local function LoadDB()
    -- No saved table yet: DCC's first run on this character.
    DCC.firstRun = DyresCooldownChimesDB == nil
    DyresCooldownChimesDB = DCC.SanitizeDB(DyresCooldownChimesDB)
    DCC.db = DyresCooldownChimesDB
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, loadedName)
    if event == "ADDON_LOADED" then
        if loadedName == addonName then
            self:UnregisterEvent("ADDON_LOADED")
            LoadDB()
        end
        return
    end
    self:UnregisterEvent("PLAYER_LOGIN")
    local available, message = CheckInstalledFiles()
    if available and not DCC.db then
        LoadDB()
    end
    DCC.available = available
    local _, classFile = UnitClass("player")
    DCC.classFile = classFile
    ReportLoaded(available)
    local conflict = FindSlashConflict()
    if conflict then
        DCC.Report("Another AddOn (" .. conflict .. ") also uses " .. PRIMARY_SLASH
            .. ". Use " .. BACKUP_SLASH .. " instead.")
    end
    if not available then
        DCC.Report(message)
        return
    end
    DCC.ReportMissingSounds()
    if DCC.firstRun then
        DCC.ImportOtherChimes(classFile)
    end
    ReportOtherChimes()
    -- Called here rather than from each file's own PLAYER_LOGIN handler, so
    -- startup never depends on event handler order.
    DCC.InitializeChimes(classFile)
    DCC.InitializeOptions()
end)
