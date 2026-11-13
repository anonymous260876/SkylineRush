local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local VFXService = {}
local rainParts = {}
local fogEffect = nil
local thunderSound = nil
local lastRainIntensity = 0

-- Particle texture IDs (Roblox built-in rain textures)
local RAIN_TEXTURE = "rbxassetid://73603683628019"
local LIGHTNING_TEXTURE = "rbxassetid://3263281004"

function VFXService:Initialize()
    self:SetupWeatherEffects()
    self:SetupEnvironmentListeners()
end

function VFXService:SetupWeatherEffects()
    local rainFolder = Instance.new("Folder")
    rainFolder.Name = "WeatherVFX"
    rainFolder.Parent = Workspace

    -- Rain streaks - positioned high in the sky
    local rainEmitter = Instance.new("ParticleEmitter")
    rainEmitter.Name = "RainStreaks"
    rainEmitter.Texture = RAIN_TEXTURE
    rainEmitter.LightEmission = 0
    rainEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1.5)
    })
    rainEmitter.Speed = NumberRange.new(-50, -10)
    rainEmitter.SpreadAngle = Vector2.new(0, 360)
    rainEmitter.Rate = 0
    rainEmitter.EmissionDirection = Enum.NormalId.Bottom
    rainEmitter.Lifetime = NumberRange.new(5, 8)
    rainEmitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
    rainEmitter.Transparency = NumberSequence.new(0, 0.5)
    rainEmitter.Enabled = false
    rainEmitter.ZOffset = 1

    local rainAttachment = Instance.new("Attachment")
    rainAttachment.Name = "RainAttachment"
    rainAttachment.Position = Vector3.new(0, 1000, 0)
    rainAttachment.Parent = rainFolder
    rainEmitter.Parent = rainAttachment

    -- Distant rain curtain effect
    local curtainEmitter = Instance.new("ParticleEmitter")
    curtainEmitter.Name = "RainCurtain"
    curtainEmitter.Texture = RAIN_TEXTURE
    curtainEmitter.LightEmission = 0
    curtainEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2.0),
        NumberSequenceKeypoint.new(1, 4.0)
    })
    curtainEmitter.Speed = NumberRange.new(-60, -30)
    curtainEmitter.SpreadAngle = Vector2.new(0, 360)
    curtainEmitter.Rate = 0
    curtainEmitter.EmissionDirection = Enum.NormalId.Bottom
    curtainEmitter.Lifetime = NumberRange.new(8, 12)
    curtainEmitter.Color = ColorSequence.new(Color3.new(0.8, 0.8, 0.9))
    curtainEmitter.Transparency = NumberSequence.new(0, 0.7)
    curtainEmitter.Enabled = false

    local curtainAttachment = Instance.new("Attachment")
    curtainAttachment.Name = "CurtainAttachment"
    curtainAttachment.Position = Vector3.new(0, 50, 0)
    curtainAttachment.Parent = rainFolder
    curtainEmitter.Parent = curtainAttachment

    -- Lightning flash effect
    local lightningModel = Instance.new("Model")
    lightningModel.Name = "LightningEffect"
    lightningModel.Parent = rainFolder

    local flashPart = Instance.new("Part")
    flashPart.Name = "Flash"
    flashPart.Size = Vector3.new(20, 20, 20)
    flashPart.Position = Vector3.new(0, 0, 0)
    flashPart.Transparency = 1
    flashPart.Anchored = true
    flashPart.CanCollide = false
    flashPart.Parent = lightningModel

    -- Lightning beam
    local lightningBeam = Instance.new("Beam")
    lightningBeam.Name = "LightningBeam"
    lightningBeam.Texture = LIGHTNING_TEXTURE
    lightningBeam.TextureMode = Enum.BeamTextureMode.Stretch
    lightningBeam.Transparency = NumberSequence.new(0, 0.5)
    lightningBeam.Color = ColorSequence.new(Color3.new(0.8, 0.9, 1.0))
    lightningBeam.FaceCamera = true
    lightningBeam.Parent = lightningModel

    -- Thunder sound
    -- IMPORTANT: SoundId uses "rbxasset://sounds/PLACEHOLDER" — NOT a valid Roblox audio.
    -- Replace with verified Roblox asset ID before production release.
    thunderSound = Instance.new("Sound")
    thunderSound.Name = "ThunderSound"
    thunderSound.SoundId = "rbxasset://sounds/PLACEHOLDER"
    thunderSound.Volume = 0
    thunderSound.Parent = rainFolder

    rainParts.RainStreaks = rainEmitter
    rainParts.RainCurtain = curtainEmitter
    rainParts.LightningEffect = lightningModel
end

function VFXService:SetupEnvironmentListeners()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local weatherSync = remotes:WaitForChild("WeatherSync")
    weatherSync.OnClientEvent:Connect(function(data)
        self:OnWeatherSync(data)
    end)
end

function VFXService:OnWeatherSync(data)
    local rainIntensity = data.RainIntensity or 0
    local windIntensity = data.WindIntensity or 0

    -- Update rain effects based on intensity
    rainParts.RainStreaks.Enabled = rainIntensity > 0.5
    rainParts.RainCurtain.Enabled = rainIntensity > 0.8

    -- Update atmosphere effects
    self:UpdateFog(data.Atmosphere.Density)

    -- Handle lightning/thunder for storms
    if rainIntensity > 0.8 then
        self:ActivateLightning()
    else
        self:DeactivateLightning()
    end

    -- Update rain density based on intensity
    rainParts.RainStreaks.Rate = math.clamp(rainIntensity * 100, 10, 200)
    rainParts.RainCurtain.Rate = math.clamp(rainIntensity * 60, 10, 100)

    lastRainIntensity = rainIntensity
end

function VFXService:UpdateFog(density)
    if fogEffect == nil then
        fogEffect = Instance.new("Atmosphere")
        fogEffect.Parent = Lighting
    end

    TweenService:Create(fogEffect, TweenInfo.new(2), {
        Density = density,
    }):Play()
end

function VFXService:ActivateLightning()
    if not rainParts.LightningEffect then return end

    -- Flash the lightning
    local flashPart = rainParts.LightningEffect:FindFirstChild("Flash")
    if flashPart then
        TweenService:Create(flashPart, TweenInfo.new(0.1), {
            Transparency = 0.5,
        }):Play()
        task.delay(0.3, function()
            TweenService:Create(flashPart, TweenInfo.new(0.5), {
                Transparency = 1,
            }):Play()
        end)
    end

    -- Play thunder sound
    if thunderSound then
        thunderSound:Play()
    end

    -- Update rain effects for storms
    rainParts.RainStreaks.Rate = 150
    rainParts.RainCurtain.Rate = 80
end

function VFXService:DeactivateLightning()
    if thunderSound then
        thunderSound:Stop()
        thunderSound.Volume = 0
    end

    local flashPart = rainParts.LightningEffect and rainParts.LightningEffect:FindFirstChild("Flash")
    if flashPart then
        flashPart.Transparency = 1
    end
end

return VFXService