-------------------------------------------------------------------------------
-- Title: Mik's Scrolling Battle Text Media
-- Author: Mikord
-------------------------------------------------------------------------------

-- Create module and set its name.
local module = {}
local moduleName = "Media"
MikSBT[moduleName] = module


-------------------------------------------------------------------------------
-- Imports.
-------------------------------------------------------------------------------

-- Local references to various modules for faster access.
local MSBTProfiles = MikSBT.Profiles
local L = MikSBT.translations

-- Local references to various functions for faster access.
local string_sub = string.sub
local string_len = string.len

-- Local Functions
local SplitString = MikSBT.SplitString

-------------------------------------------------------------------------------
-- Constants.
-------------------------------------------------------------------------------

-- The default sound files to use.
local DEFAULT_SOUND_FILES = {
	["MSBT Low Health"]		= "Interface\\Addons\\MikScrollingBattleText\\Sounds\\LowHealth.ogg",
	["MSBT Low Mana"]		= "Interface\\Addons\\MikScrollingBattleText\\Sounds\\LowMana.ogg",
	["MSBT Cooldown"]		= "Interface\\Addons\\MikScrollingBattleText\\Sounds\\Cooldown.ogg",
}

-- Set the default font files to use to the locale specific fonts.
local DEFAULT_FONT_FILES = L.FONT_FILES

-- LibSharedMedia support.
local SML = LibStub("LibSharedMedia-3.0")
local SML_LANG_MASK_ALL = 255


-------------------------------------------------------------------------------
-- Private variables.
-------------------------------------------------------------------------------

local fonts = {}
local sounds = {}
local sound_group = {}

-------------------------------------------------------------------------------
-- Font functions.
-------------------------------------------------------------------------------

-- ****************************************************************************
-- Registers a font.
-- See the included API.html file for usage info.
-- ****************************************************************************
local function RegisterFont(fontName, fontPath)
	-- Don't do anything if the font name or font path is invalid.
	if (type(fontName) ~= "string" or type(fontPath) ~= "string") then return end
	if (fontName == "" or fontPath == "") then return end

	-- Register with MSBT and shared media.
	fonts[fontName] = fontPath
	SML:Register("font", fontName, fontPath, SML_LANG_MASK_ALL)
end


-- ****************************************************************************
-- Returns an iterator for the table containing the registered fonts.
-- See the included API.html file for usage info.
-- ****************************************************************************
local function IterateFonts()
	return pairs(fonts)
end

-- ****************************************************************************
-- Splits the given string by the delimiter
-- Returns a table
-- ****************************************************************************
local function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

-------------------------------------------------------------------------------
-- Sound functions.
-------------------------------------------------------------------------------

-- ****************************************************************************
-- Registers a sound.
-- See the included API.html file for usage info.
-- ****************************************************************************
local function RegisterSound(soundName, soundGroup, soundPath)
	-- Don't do anything if the sound name or sound path is invalid.
	-- Allow non-string entries for soundPath as of Patch 8.2.0.
	if (type(soundName) ~= "string") then return end
	-- Ensure that the custom file path is either a number (FileDataID)
	-- Or a string that begins with "Interface" and ends with either ".mp3" or ".ogg"
	local soundPathLower = string.lower(soundPath)
	if (not soundPath or soundName == "" or soundPath == "" or (type(soundPath) == "string" and ((string.find(soundPathLower, "interface") or 0) ~= 1 or (not string.find(soundPathLower, ".mp3") and not string.find(soundPathLower, ".ogg"))))) then
		return
	end

	-- Register with MSBT.
	sounds[soundName] = soundPath

	if sound_group[soundGroup] == nil then
		sound_group[soundGroup] = {}
	end
	sound_group[soundGroup][soundName] = true

	-- Register with shared media.
	
	local combined = soundName.."-"..soundGroup
	SML:Register("sound", combined, soundPath)
end

-- ****************************************************************************
-- Given a sound name, return its sound group.
-- ****************************************************************************
local function GetSoundGroup(soundName)
	local name_group_table={}
		SplitString(soundName, "-", name_group_table)
	if #name_group_table == 2 then
		return name_group_table[2]
	end

	for groupName, inGroupSounds in pairs(sound_group) do
		if inGroupSounds[soundName] ~= nil then
			return groupName
		end
	end
	return "DefaultGroup"
end


local function Randomchoice(t) --Selects a random item from a table
    local keys = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    random_key = keys[math.random(1, #keys)]
    return random_key
end



-- ****************************************************************************
-- Given a sound group, return a random sound name and sound path
-- ****************************************************************************
local function GetRandomSoundFromGroup(soundGroupName)
	if sound_group[soundGroupName] ~= nil then
		local soundName = Randomchoice(sound_group[soundGroupName])
		local soundPath = sounds[soundName]
		return soundName, soundPath
	end
	return nil, nil
end


-- ****************************************************************************
-- Returns an iterator for the table containing the registered sounds.
-- See the included API.html file for usage info.
-- ****************************************************************************
local function IterateSounds()
	return pairs(sounds)
end


-------------------------------------------------------------------------------
-- Event handlers.
-------------------------------------------------------------------------------

-- ****************************************************************************
-- Called by shared media when media is registered.
-- ****************************************************************************
local function SMLRegistered(event, mediaType, name)
	if (mediaType == "font") then
		fonts[name] = SML:Fetch(mediaType, name)
	elseif (mediaType == "sound") then
		sounds[name] = SML:Fetch(mediaType, name)
	end
end


-- ****************************************************************************
-- Called when the mod variables are initialized.
-- ****************************************************************************
local function OnVariablesInitialized()
	-- Register custom fonts and sounds.
	for fontName, fontPath in pairs(MSBTProfiles.savedMedia.fonts) do RegisterFont(fontName, fontPath) end
	for soundName, soundPath in pairs(MSBTProfiles.savedMedia.sounds) do 
		local name_group_table={}
		SplitString(soundName, "-", name_group_table)
		RegisterSound(name_group_table[1], name_group_table[2], soundPath) 
	end
end


-------------------------------------------------------------------------------
-- Initialization.
-------------------------------------------------------------------------------

-- Register default fonts and sounds.
for fontName, fontPath in pairs(DEFAULT_FONT_FILES) do RegisterFont(fontName, fontPath) end
for soundName, soundPath in pairs(DEFAULT_SOUND_FILES) do 
	RegisterSound(soundName, "DefaultGroup", soundPath) 
end

-- Register the currently available fonts and sounds in shared media with MSBT.
for index, fontName in pairs(SML:List("font")) do fonts[fontName] = SML:Fetch("font", fontName) end
for index, soundName in pairs(SML:List("sound")) do sounds[soundName] = SML:Fetch("sound", soundName) end

-- Register a callback with shared media to keep MSBT synced.
SML.RegisterCallback("MSBTSharedMedia", "LibSharedMedia_Registered", SMLRegistered)




-------------------------------------------------------------------------------
-- Module interface.
-------------------------------------------------------------------------------

-- Protected Variables.
module.fonts = fonts
module.sounds = sounds
module.sound_group = sound_group

-- Protected Functions.
module.RegisterFont				= RegisterFont
module.RegisterSound			= RegisterSound
module.GetSoundGroup            = GetSoundGroup
module.GetRandomSoundFromGroup  = GetRandomSoundFromGroup
module.IterateFonts				= IterateFonts
module.IterateSounds			= IterateSounds
module.OnVariablesInitialized	= OnVariablesInitialized
