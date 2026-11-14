local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local AudioModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AudioModule"))

local AudioService = {}

-- Local-only audio state (persists for current session)
local musicSources = {}
local ambientSounds = {}
local lastWeatherState = "Clear"
local musicVolume = AudioModule.DefaultVolumes.MusicVolume
local ambientVolume = AudioModule.DefaultVolumes.AmbientVolume
local masterVolume = AudioModule.DefaultVolumes.MasterVolume
local isMuted = AudioModule:GetMuteState(player.UserId)

-- Music track mapping: weather preset -> track name
local MUSIC_TRACKS = {
    Clear = "Clear",
    Cloudy = "Cloudy",
    Rain = "Rain",
    Storm = "Storm",
}

-- Ambient sound configuration
-- IMPORTANT: All SoundIds use "rbxasset://sounds/PLACEHOLDER" — these are NOT valid Roblox audio.
-- Replace with verified Roblox asset IDs before production release.
local AMBIENT_SOUNDS = {
    Wind = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = true },
    Rain = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = true },
    Thunder = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = false },
    Waterfall = { SoundId = "rbxasset://sounds/PLACEHOLDER", Loop = true },
}

local function isPlaceholder(assetId)
    return assetId and string.find(assetId, "PLACEHOLDER") ~= nil
end

-- SoundGroup-based volume control to avoid global SoundService.MasterVolume writes
local masterGroup = Instance.new("SoundGroup")
masterGroup.Name = "SkylineRushMaster"
masterGroup.Parent = SoundService

local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "SkylineRushMusic"
musicGroup.Parent = masterGroup

local ambientGroup = Instance.new("SoundGroup")
ambientGroup.Name = "SkylineRushAmbient"
ambientGroup.Parent = masterGroup

masterGroup.Volume = masterVolume
musicGroup.Volume = musicVolume
ambientGroup.Volume = ambientVolume

-- Register SoundGroups with AudioModule as the authoritative mute controller.
-- Registration is retroactive: if the HUD muted before this script ran,
-- ApplyMuteState enforces that flag on the newly registered groups.
AudioModule:RegisterSoundGroups(masterGroup, musicGroup, ambientGroup)
AudioModule:SetVolumes(masterVolume, musicVolume, ambientVolume)
AudioModule:ApplyMuteState(player.UserId)

local audioInitialized = false

function AudioService:Initialize()
    -- Idempotent: initialize exactly once
    if audioInitialized then return end
    audioInitialized = true

    masterGroup.Volume = masterVolume
    musicGroup.Volume = musicVolume
    ambientGroup.Volume = ambientVolume

    self:SetupMusic()
    self:SetupAmbientSounds()
    self:SetupEnvironmentListeners()
end

function AudioService:SetupMusic()
    -- Music tracks are loaded from ReplicatedStorage.Assets.Music if available
    local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
    if not assetsFolder then
        return
    end
    local musicFolder = assetsFolder:FindFirstChild("Music")
    if not musicFolder then return end

    for weather, trackName in pairs(MUSIC_TRACKS) do
        local track = musicFolder:FindFirstChild(trackName)
        if track and track:IsA("Sound") then
            -- Safely skip empty or invalid asset IDs
            if AudioModule:ValidateAssetId(track.SoundId) then
                local source = Instance.new("Sound")
                source.Name = trackName
                source.SoundId = track.SoundId
                source.Looped = true
                source.Volume = 0
                source.SoundGroup = musicGroup
                source.Parent = SoundService
                musicSources[weather] = source
            end
        end
    end

    -- Start with Clear music
    if musicSources.Clear then
        musicSources.Clear:Play()
        musicSources.Clear.Volume = musicVolume
    end
end

function AudioService:SetupAmbientSounds()
    for name, config in pairs(AMBIENT_SOUNDS) do
        -- Safely skip empty or invalid asset IDs
        if AudioModule:ValidateAssetId(config.SoundId) then
            local source = Instance.new("Sound")
            source.Name = name
            source.SoundId = config.SoundId
            source.Looped = config.Loop
            source.Volume = 0
            source.SoundGroup = ambientGroup
            source.Parent = SoundService
            ambientSounds[name] = source
        end
    end

    -- Waterfall is always slightly audible
    if ambientSounds.Waterfall then
        ambientSounds.Waterfall.Volume = ambientVolume * 0.4
    end
end

function AudioService:SetupEnvironmentListeners()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local weatherSync = remotes:WaitForChild("WeatherSync")
    weatherSync.OnClientEvent:Connect(function(data)
        self:OnWeatherSync(data)
    end)

    local envCommand = remotes:WaitForChild("EnvironmentCommand")
    envCommand.OnClientEvent:Connect(function(command, value)
        self:OnEnvironmentCommand(command, value)
    end)

    -- Reliable handshake: request current weather state after listeners are connected.
    -- Ensures clients joining after the initial broadcast still receive weather data.
    local weatherRequest = remotes:FindFirstChild("WeatherRequest")
    if weatherRequest then
        pcall(function()
            weatherRequest:FireServer()
        end)
    end
end

function AudioService:OnWeatherSync(data)
    local rainIntensity = data.RainIntensity or 0
    local windIntensity = data.WindIntensity or 0

    -- Determine weather preset from intensity
    local weatherPreset = "Clear"
    if rainIntensity > 0.8 then
        weatherPreset = "Storm"
    elseif rainIntensity > 0.5 then
        weatherPreset = "Rain"
    elseif rainIntensity > 0.2 then
        weatherPreset = "Cloudy"
    else
        weatherPreset = "Clear"
    end

    -- Transition music if weather changed
    if lastWeatherState ~= weatherPreset then
        self:TransitionMusic(weatherPreset)
        lastWeatherState = weatherPreset
    end

    -- Update ambient sound volumes based on weather intensity.
    -- Always read the current authoritative mute state; never rely on a stale snapshot.
    local currentMuted = AudioModule:GetMuteState(player.UserId)

    if currentMuted then
        self:TweenVolume(ambientSounds.Wind, 0)
        self:TweenVolume(ambientSounds.Rain, 0)
    else
        self:TweenVolume(ambientSounds.Wind, windIntensity * ambientVolume)
        self:TweenVolume(ambientSounds.Rain, rainIntensity * ambientVolume)
    end
end

function AudioService:OnEnvironmentCommand(command, value)
    -- Volume changes are local-only; server broadcasts them to all clients
    if command == "Volume" and type(value) == "table" then
        self:UpdateVolume(value)
    end
end

function AudioService:TransitionMusic(newWeather)
    -- Fade out current music
    for weather, source in pairs(musicSources) do
        if source.IsPlaying then
            self:TweenVolume(source, 0, 2)
            task.delay(2, function()
                source:Stop()
            end)
        end
    end

    -- Fade in new music
    local targetTrack = musicSources[newWeather]
    if targetTrack then
        targetTrack:Play()
        self:TweenVolume(targetTrack, musicVolume, 2)
    end
end

function AudioService:TweenVolume(source, targetVolume, duration)
    if not source or not source.Parent then return end
    duration = duration or 1
    local tween = TweenService:Create(source, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Volume = targetVolume
    })
    tween:Play()
end

function AudioService:ToggleMute()
    -- LOCAL-ONLY mute toggle: does NOT affect other players
    -- Uses AudioModule for per-player mute state tracking
    isMuted = AudioModule:ToggleMute(player.UserId)

    -- Zero out SoundGroup volumes when muted, restore individual levels when unmuted
    local masterScale = isMuted and 0 or masterVolume
    local musicScale = isMuted and 0 or musicVolume
    local ambientScale = isMuted and 0 or ambientVolume

    masterGroup.Volume = masterScale
    musicGroup.Volume = musicScale
    ambientGroup.Volume = ambientScale

    -- Update all music sources to restore correct levels when unmuted
    for _, source in pairs(musicSources) do
        source.Volume = isMuted and 0 or musicVolume
    end

    -- Update all ambient sources
    for name, source in pairs(ambientSounds) do
        if name == "Waterfall" then
            source.Volume = isMuted and 0 or (ambientVolume * 0.4)
        else
            source.Volume = isMuted and 0 or source.Volume
        end
    end
end

function AudioService:Icon()
    return isMuted and "🔇" or "🔊"
end

function AudioService:UpdateVolume(settings)
    musicVolume = settings.MusicVolume or musicVolume
    ambientVolume = settings.AmbientVolume or ambientVolume
    masterVolume = settings.MasterVolume or masterVolume

    -- Keep AudioModule's stored configured volumes in sync with runtime settings.
    AudioModule:SetVolumes(masterVolume, musicVolume, ambientVolume)

    -- Read current authoritative mute state; stale snapshots are unsafe.
    local currentMuted = AudioModule:GetMuteState(player.UserId)

    if currentMuted then
        -- Stay muted: all groups and sources remain silent.
        masterGroup.Volume = 0
        musicGroup.Volume = 0
        ambientGroup.Volume = 0
        for _, source in pairs(musicSources) do
            source.Volume = 0
        end
        for _, source in pairs(ambientSounds) do
            source.Volume = 0
        end
    else
        masterGroup.Volume = masterVolume
        musicGroup.Volume = musicVolume
        ambientGroup.Volume = ambientVolume

        for _, source in pairs(musicSources) do
            source.Volume = musicVolume
        end
        for name, source in pairs(ambientSounds) do
            if name == "Waterfall" then
                source.Volume = ambientVolume * 0.4
            else
                source.Volume = source.Volume
            end
        end
    end
end

AudioService:Initialize()

return AudioService
