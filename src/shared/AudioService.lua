-- Shared Audio Service module
-- Provides audio configuration and helper functions for both client and server.
-- This module does NOT create Sound objects — it only provides configuration data.
-- Client-side audio logic lives in src/client/Services/AudioService.client.lua

local AudioService = {}

-- Default volume settings (can be overridden by Config)
AudioService.DefaultVolumes = {
    MasterVolume = 1.0,
    MusicVolume = 0.7,
    AmbientVolume = 0.5,
}

-- Music track mapping: weather preset -> track name
AudioService.MusicTracks = {
    Clear = "Clear",
    Cloudy = "Cloudy",
    Rain = "Rain",
    Storm = "Storm",
}

-- Ambient sound configuration
-- IMPORTANT: All SoundIds use "rbxasset://sounds/PLACEHOLDER" — these are NOT valid Roblox audio.
-- Replace with verified Roblox asset IDs before production release.
AudioService.AmbientSounds = {
    Wind = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = true },
    Rain = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = true },
    Thunder = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = false },
    Waterfall = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = true },
}

-- Check if an asset ID is a placeholder
function AudioService:IsPlaceholder(assetId)
    return assetId and string.find(assetId, "PLACEHOLDER") ~= nil
end

-- Get audio volumes from Config
function AudioService:GetVolumes()
    local Config = require(ReplicatedStorage.Shared.Config)
    local audioConfig = Config.World.Environment.Audio
    return {
        MasterVolume = audioConfig.MasterVolume,
        MusicVolume = audioConfig.MusicVolume,
        AmbientVolume = audioConfig.AmbientVolume,
    }
end

return AudioService