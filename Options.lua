local _, DCC = ...

-- One settings page in Blizzard's vertical layout, with proxy settings that
-- read and write DyresCooldownChimesDB directly: the master switch, the lead,
-- then each of your class's spells with its own sound in a dropdown under its
-- switch (author-approved in MTF), a menu of submenus from Dyre's Sounds.
local TITLE = "Dyre's Cooldown Chimes"
local UNAVAILABLE = "The AddOn settings page is unavailable on this client."
local NO_SPELLS = "Your class has no chime spells yet."

local REQUIRED_SETTINGS = {
    "RegisterVerticalLayoutCategory", "RegisterProxySetting", "RegisterAddOnCategory", "CreateCheckbox",
    "CreateSlider", "CreateSliderOptions", "CreateDropdown", "CreateControlTextContainer", "OpenToCategory",
}

local category, layout

local function HasSettingsAPI()
    if type(Settings) ~= "table" or type(Settings.VarType) ~= "table" then
        return false
    end
    for _, name in ipairs(REQUIRED_SETTINGS) do
        if type(Settings[name]) ~= "function" then
            return false
        end
    end
    return true
end

local function Proxy(variable, variableType, name, default, getValue, setValue)
    return Settings.RegisterProxySetting(category, variable, variableType, name, default, getValue, setValue)
end

local function SliderOptions(minValue, maxValue, step)
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    if type(MinimalSliderWithSteppersMixin) == "table" and type(options.SetLabelFormatter) == "function" then
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    end
    return options
end

local function Heading(text)
    if type(CreateSettingsListSectionHeaderInitializer) == "function" and type(layout) == "table"
            and type(layout.AddInitializer) == "function" then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end
end

-- One spell: its switch, and its sound under it when Dyre's Sounds is installed.
local function AddSpell(chime, library)
    local variable = "DCC_CHIME_" .. chime.key:upper()
    local setting = Proxy(variable, Settings.VarType.Boolean, chime.label, chime.on,
        function() return DCC.db.spells[chime.key] end,
        function(value) DCC.db.spells[chime.key] = value == true end)
    local switch = Settings.CreateCheckbox(category, setting, "Play a sound just before " .. chime.label
        .. " is ready again.")
    if not library then
        return
    end
    local sound = Proxy(variable .. "_SOUND", Settings.VarType.String, "Sound", DCC.DEFAULT_SOUND,
        function() return DCC.db.sounds[chime.key] end,
        function(value)
            local key = library.Resolve(value)
            if key then
                DCC.db.sounds[chime.key] = key
                DCC.PreviewChime(chime.key)
            end
        end)
    local dropdown = Settings.CreateDropdown(category, sound, library.Choices(),
        "The sound for " .. chime.label .. ". Choosing one plays it once. Text to Speech says \""
            .. chime.label .. " ready\".")
    library.SetupMenu(dropdown)
    if type(dropdown.SetParentInitializer) == "function" then
        dropdown:SetParentInitializer(switch, function() return DCC.db.spells[chime.key] end)
    end
end

function DCC.InitializeOptions()
    if not HasSettingsAPI() then
        return
    end
    local library = DCC.SoundLibrary()
    category, layout = Settings.RegisterVerticalLayoutCategory(TITLE)
    local enabled = Proxy("DCC_ENABLED", Settings.VarType.Boolean, "Cooldown chimes", true,
        function() return DCC.db.enabled end,
        function(value) DCC.db.enabled = value == true end)
    local tooltip = "A sound just before your chosen spells are ready again, also in combat. Every rank of a "
        .. "spell counts."
    if not library then
        tooltip = tooltip .. " Install Dyre's Sounds to hear them and to choose each spell's sound."
    end
    Settings.CreateCheckbox(category, enabled, tooltip)
    local lead = Proxy("DCC_LEAD", Settings.VarType.Number, "Chime early (seconds)", DCC.DEFAULT_LEAD,
        function() return DCC.db.lead end,
        function(value) DCC.db.lead = DCC.SanitizeLead(value) end)
    Settings.CreateSlider(category, lead, SliderOptions(DCC.LEAD_MIN, DCC.LEAD_MAX, DCC.LEAD_STEP),
        "How long before a cooldown ends the chime plays, so you can act the moment it is ready.")
    local spells = DCC.ClassChimes(DCC.classFile)
    Heading(#spells > 0 and "Spells" or NO_SPELLS)
    for _, chime in ipairs(spells) do
        AddSpell(chime, library)
    end
    Settings.RegisterAddOnCategory(category)
end

function DCC.OpenSettings()
    if not category then
        DCC.Report(UNAVAILABLE)
        return
    end
    Settings.OpenToCategory(category:GetID())
end
