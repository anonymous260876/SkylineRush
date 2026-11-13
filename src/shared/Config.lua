local Config = {}

-- Preserve the existing v2 save key: do not reset existing player progress.
Config.SaveKey = "SkylineRush_PlayerData_v2"
Config.AllowStudioGuestMode = true -- Studio-only if live DataStore is inaccessible.
Config.Defaults = {
    Coins = 0,
    Crystals = 0,
    CapacityLevel = 0,
    SpeedLevel = 0,
    GeneratorLevel = 0,
    ZoneLevel = 0,
    TotalCollected = 0,
    BagValue = 0,
}

Config.BaseCapacity = 10
Config.CapacityPerLevel = 5
Config.MaxCapacityLevel = 12
Config.MaxSpeedLevel = 10
Config.MaxGeneratorLevel = 10
Config.MaxZoneLevel = 2
Config.BaseWalkSpeed = 16
Config.SpeedPerLevel = 2
Config.CrystalRespawnSeconds = 7
Config.IncomeInterval = 5
Config.AutoSaveSeconds = 90
Config.CrystalCountPerZone = {28, 18, 14}
Config.CrystalValuePerZone = {5, 12, 26}
Config.GeneratorIncomePerLevel = 8
Config.MaxCoins = 2000000000
Config.MaxTotalCollected = 2000000000

Config.Costs = {
    Speed = {base = 50, factor = 1.55},
    Capacity = {base = 60, factor = 1.65},
    Generator = {base = 100, factor = 1.8},
    Zone = {300, 1500},
}

Config.ZoneNames = {"SKY MEADOW", "AZURE RIDGE", "NEON SUMMIT"}
Config.World = {
    GroundY = 5,
    MainSize = Vector3.new(250, 12, 240),
    ZoneCenters = {Vector3.new(0, 0, -23), Vector3.new(-85, 0, -78), Vector3.new(85, 0, -78)},
    Spawn = Vector3.new(0, 12, 85),
    Environment = {
        Ambient = Color3.fromRGB(80, 126, 165),
        OutdoorAmbient = Color3.fromRGB(90, 140, 180),
        FogColor = Color3.fromRGB(175, 217, 255),
        FogEnd = 1000,
        SkyboxBrightness = 1,
        CycleDuration = 600, -- 10 mins per cycle
        AdminIds = {}, -- Add UserIds here
        Audio = {
            MasterVolume = 1.0,
            MusicVolume = 0.7,
            AmbientVolume = 0.5,
        },
    },
    WeatherPresets = {
        Clear = {
            AtmosphereDensity = 0.25,
            Haze = 1.0,
            Ambient = Color3.fromRGB(80, 126, 165),
            OutdoorAmbient = Color3.fromRGB(90, 140, 180),
            FogColor = Color3.fromRGB(175, 217, 255),
            RainIntensity = 0,
            WindIntensity = 0.1,
        },
        Cloudy = {
            AtmosphereDensity = 0.4,
            Haze = 2.0,
            Ambient = Color3.fromRGB(60, 90, 120),
            OutdoorAmbient = Color3.fromRGB(70, 100, 130),
            FogColor = Color3.fromRGB(140, 160, 180),
            RainIntensity = 0.2,
            WindIntensity = 0.3,
        },
        Rain = {
            AtmosphereDensity = 0.55,
            Haze = 3.5,
            Ambient = Color3.fromRGB(45, 65, 85),
            OutdoorAmbient = Color3.fromRGB(50, 70, 90),
            FogColor = Color3.fromRGB(100, 120, 140),
            RainIntensity = 0.8,
            WindIntensity = 0.6,
        },
        Storm = {
            AtmosphereDensity = 0.75,
            Haze = 5.0,
            Ambient = Color3.fromRGB(25, 35, 50),
            OutdoorAmbient = Color3.fromRGB(30, 40, 60),
            FogColor = Color3.fromRGB(60, 70, 90),
            RainIntensity = 1.0,
            WindIntensity = 0.9,
        },
    },
}

Config.UI = {
    Colors = {
        Background = Color3.fromRGB(18, 29, 52),
        Accent = Color3.fromRGB(56, 210, 235),
        Text = Color3.fromRGB(231, 245, 255),
        Coin = Color3.fromRGB(255, 214, 107),
        Income = Color3.fromRGB(133, 226, 179),
        Danger = Color3.fromRGB(255, 95, 95),
    },
    ButtonSize = 64,
    CornerRadius = 12,
    DrawerMaxWidth = 420,
    DrawerPadding = 16,
}

return Config
