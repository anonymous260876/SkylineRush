-- Audio ModuleScript (Shared)
-- Provides per-player mute state and audio control functions.
-- Stores mute state per Player UserId so each player's mute is independent.
-- Used by LocalScripts via require() instead of global variables.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local self = {}
self._muteState = {} -- Private dictionary: UserId -> boolean
self._soundGroups = { master = nil, music = nil, ambient = nil }
self._volumes = {
    master = 1.0,
    music = 0.7,
    ambient = 0.5,
}

-- Default volume settings
self.DefaultVolumes = {
    MasterVolume = 1.0,
    MusicVolume = 0.7,
    AmbientVolume = 0.5,
}

-- Music track mapping: weather preset -> track name
self.MusicTracks = {
    Clear = "Clear",
    Cloudy = "Cloudy",
    Rain = "Rain",
    Storm = "Storm",
}

-- Ambient sound configuration
self.AmbientSounds = {
    Wind = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = true },
    Rain = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = true },
    Thunder = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = false },
    Waterfall = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = true },
}

-- Check if an asset ID is a placeholder or invalid
function self:IsPlaceholder(assetId)
    if not assetId then return true end
    return string.find(assetId, "PLACEHOLDER") ~= nil
        or assetId == ""
        or not string.find(assetId, "rbxasset://")
end

-- Validate that an asset ID is safe to use (not a placeholder)
function self:ValidateAssetId(assetId)
    if not assetId or type(assetId) ~= "string" then return false end
    if self:IsPlaceholder(assetId) then return false end
    -- Must be a valid Roblox asset URL format
    if not string.find(assetId, "rbxasset://") then return false end
    -- Extract the numeric ID after rbxasset:///
    local success, id = pcall(function()
        return tonumber(string.gsub(assetId, "rbxasset://", ""))
    end)
    if not success or not id then return false end
    -- Roblox asset IDs are typically positive integers
    return id > 0
end

-- Get whether a player is muted (local-only, does not affect other players)
function self:GetMuteState(player)
    local userId = type(player) == "number" and player or player.UserId
    return self._muteState[userId] or false
end

-- Toggle mute for a specific player (local-only, does not affect other players)
-- Returns the new mute state
function self:ToggleMute(player)
    local userId = type(player) == "number" and player or player.UserId
    self._muteState[userId] = not self._muteState[userId]
    local newState = self._muteState[userId]

    -- Zero out all registered SoundGroups when muted; restore configured volumes when unmuted.
    -- Use a pair list so unregistered (nil) groups are safely skipped.
    local entries = {
        { group = self._soundGroups.master, volume = self._volumes.master },
        { group = self._soundGroups.music, volume = self._volumes.music },
        { group = self._soundGroups.ambient, volume = self._volumes.ambient },
    }
    for _, e in ipairs(entries) do
        if e.group and e.group.Parent then
            e.group.Volume = newState and 0 or e.volume
        end
    end

    return newState
end

-- Apply the current mute state to all registered SoundGroups without toggling.
-- Useful after SoundGroups are registered to retroactively enforce an early mute.
function self:ApplyMuteState(player)
    local userId = type(player) == "number" and player or player.UserId
    local muted = self._muteState[userId]
    if not muted then return end -- Nothing to do if not muted

    local entries = {
        { group = self._soundGroups.master, volume = self._volumes.master },
        { group = self._soundGroups.music, volume = self._volumes.music },
        { group = self._soundGroups.ambient, volume = self._volumes.ambient },
    }
    for _, e in ipairs(entries) do
        if e.group and e.group.Parent then
            e.group.Volume = 0
        end
    end
end

-- Register SoundGroups owned by a client's AudioService so ToggleMute can control them.
-- Safe to call multiple times; subsequent calls overwrite previous registrations.
function self:RegisterSoundGroups(masterGroup, musicGroup, ambientGroup)
    self._soundGroups.master = masterGroup
    self._soundGroups.music = musicGroup
    self._soundGroups.ambient = ambientGroup
end

-- Store the configured (unmuted) volumes so ToggleMute can restore them exactly.
function self:SetVolumes(masterVolume, musicVolume, ambientVolume)
    self._volumes.master = masterVolume or self._volumes.master
    self._volumes.music = musicVolume or self._volumes.music
    self._volumes.ambient = ambientVolume or self._volumes.ambient
end

-- Get icon based on mute state
function self:GetIcon(isMuted)
    return isMuted and "🔇" or "🔊"
end

-- Set mute state explicitly (internal use)
function self:SetMuteState(player, state)
    local userId = type(player) == "number" and player or player.UserId
    self._muteState[userId] = state
end

-- Get audio volumes from Config
function self:GetVolumes()
    local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
    local audioConfig = Config.World.Environment.Audio
    return {
        MasterVolume = audioConfig.MasterVolume,
        MusicVolume = audioConfig.MusicVolume,
        AmbientVolume = audioConfig.AmbientVolume,
    }
end

return self
