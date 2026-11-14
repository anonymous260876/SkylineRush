local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage.Shared.Config)

local Environment = {}
local envConfig = Config.World.Environment
local weatherPresets = Config.World.WeatherPresets

function Environment:GetWeatherConfig()
    local timeOfDay = Lighting.ClockTime
    local weather = envConfig.Preset or "Clear"
    return weatherPresets[weather] or weatherPresets.Clear
end

function Environment:IsAdmin(player)
    local adminIds = envConfig.AdminIds or {}
    for _, id in ipairs(adminIds) do
        if player.UserId == id then return true end
    end
    -- In Studio, allow test players if configured or allowed
    if game:GetService("RunService"):IsStudio() and Config.AllowStudioGuestMode then
        return true
    end
    return false
end

function Environment:GetAudioVolumes()
    local audioConfig = envConfig.Audio
    return audioConfig.MasterVolume, audioConfig.MusicVolume, audioConfig.AmbientVolume
end

function Environment:GetWeatherIntensity(weatherName)
    local preset = weatherPresets[weatherName]
    return preset and preset.RainIntensity or 0
end

function Environment:Start()
    local cycleDuration = envConfig.CycleDuration or 600

    -- Validate cycle duration; fall back to default if invalid
    if type(cycleDuration) ~= "number" or cycleDuration <= 0 then
        cycleDuration = 600
        warn("[Environment] Invalid CycleDuration, falling back to 600 seconds (10 min)")
    end

    -- Setup RemoteEvents
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local cmdEvent = remotes:FindFirstChild("EnvironmentCommand") or Instance.new("RemoteEvent")
        cmdEvent.Name = "EnvironmentCommand"
        cmdEvent.Parent = remotes

        local weatherSync = remotes:FindFirstChild("WeatherSync") or Instance.new("RemoteEvent")
        weatherSync.Name = "WeatherSync"
        weatherSync.Parent = remotes

        local weatherRequest = remotes:FindFirstChild("WeatherRequest") or Instance.new("RemoteEvent")
        weatherRequest.Name = "WeatherRequest"
        weatherRequest.Parent = remotes

        -- Client-to-server admin commands
        cmdEvent.OnServerEvent:Connect(function(player, action, value)
            if not self:IsAdmin(player) then
                return
            end
            if action == "Weather" and type(value) == "string" then
                -- Validate weather preset name before applying
                if weatherPresets[value] then
                    envConfig.Preset = value
                    self:SyncWeatherToPlayers()
                else
                    warn("[Environment] Invalid weather preset:", value)
                end
            elseif action == "Time" and type(value) == "number" then
                Lighting.ClockTime = math.clamp(value, 0, 24)
            end
        end)

        -- Reliable handshake: client requests current weather state
        weatherRequest.OnServerEvent:Connect(function(player)
            -- Validate player exists and is in the game
            if not player.Parent then return end
            self:SyncWeatherToClient(player)
        end)

        -- Send current weather state to newly joining players
        Players.PlayerAdded:Connect(function(player)
            self:SyncWeatherToPlayers()
        end)
    end

    -- Ensure CycleTime is initialized before the cycle starts
    self.CycleTime = self.CycleTime or 0

    -- Day/Night cycle background task
    task.spawn(function()
        while true do
            self.CycleTime = (self.CycleTime + 1) % cycleDuration
            local timeOfDay = (self.CycleTime / cycleDuration) * 24
            Lighting.ClockTime = timeOfDay
            task.wait(1)
        end
    end)
end

function Environment:SyncWeatherToClient(player)
    local currentWeather = envConfig.Preset or "Clear"
    local preset = weatherPresets[currentWeather] or weatherPresets.Clear
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local weatherSync = remotes:FindFirstChild("WeatherSync") or Instance.new("RemoteEvent")
        weatherSync.Name = "WeatherSync"
        weatherSync.Parent = remotes
        weatherSync:FireClient(player, {
            RainIntensity = preset.RainIntensity,
            WindIntensity = preset.WindIntensity,
            Lighting = {
                Ambient = preset.Ambient,
                OutdoorAmbient = preset.OutdoorAmbient,
            },
            Atmosphere = {
                Density = preset.AtmosphereDensity,
                Haze = preset.Haze,
                Color = preset.FogColor or Color3.fromRGB(175, 217, 255),
            }
        })
    end
end

function Environment:SyncWeatherToPlayers()
    local currentWeather = envConfig.Preset or "Clear"
    local preset = weatherPresets[currentWeather] or weatherPresets.Clear
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local weatherSync = remotes:FindFirstChild("WeatherSync") or Instance.new("RemoteEvent")
        weatherSync.Name = "WeatherSync"
        weatherSync.Parent = remotes
        weatherSync:FireAllClients({
            RainIntensity = preset.RainIntensity,
            WindIntensity = preset.WindIntensity,
            Lighting = {
                Ambient = preset.Ambient,
                OutdoorAmbient = preset.OutdoorAmbient,
            },
            Atmosphere = {
                Density = preset.AtmosphereDensity,
                Haze = preset.Haze,
                Color = preset.FogColor or Color3.fromRGB(175, 217, 255),
            }
        })
    end
end

return Environment
