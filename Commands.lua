local _, DCC = ...

local USAGE = "Use /dcc, /dcc options, or /dcc debug."
local UNAVAILABLE = "Dyre's Cooldown Chimes is unavailable. Check the DCC login message."

-- Each command is one word; "" opens the settings. Handlers live in Core,
-- Chimes, and Options. Diagnostics also run when DCC is unavailable, to help
-- explain why.
local COMMANDS = {
    [""] = {handler = "OpenSettings"},
    options = {handler = "OpenSettings"},
    debug = {handler = "ReportDebug", always = true},
}

function DCC.ParseCommand(message)
    if type(message) ~= "string" then
        return nil, USAGE
    end
    local command = message:match("^%s*(.-)%s*$"):lower()
    if command:find("%s") or not COMMANDS[command] then
        return nil, USAGE
    end
    return command
end

function DCC.HandleCommand(message)
    local command, usage = DCC.ParseCommand(message)
    if not command then
        DCC.Report(usage)
        return
    end
    local entry = COMMANDS[command]
    if not DCC.available and not entry.always then
        DCC.Report(UNAVAILABLE)
        return
    end
    DCC[entry.handler]()
end
