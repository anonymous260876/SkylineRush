local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local syncEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerSync")
local notifyEvent = ReplicatedStorage.Remotes:WaitForChild("Notify")

local screen = Instance.new("ScreenGui")
screen.Name = "SkylineHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
pcall(function()
	screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)
screen.Parent = player:WaitForChild("PlayerGui")

local function rounded(frame, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or Config.UI.CornerRadius)
	corner.Parent = frame
end

local function applyStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Config.UI.Colors.Accent
	stroke.Thickness = thickness or 1.5
	stroke.Transparency = transparency or 0.4
	stroke.Parent = parent
	return stroke
end

-- Vitals (Top Center - Vertical layout containing pills row and progress bar)
local vitals = Instance.new("Frame")
vitals.Name = "Vitals"
vitals.Size = UDim2.new(0.9, 0, 0, 58)
vitals.Position = UDim2.new(0.5, 0, 0, 8)
vitals.AnchorPoint = Vector2.new(0.5, 0)
vitals.BackgroundTransparency = 1
vitals.Parent = screen

local vitalsConstraint = Instance.new("UISizeConstraint")
vitalsConstraint.MaxSize = Vector2.new(360, 58)
vitalsConstraint.Parent = vitals

local vitalsStack = Instance.new("UIListLayout")
vitalsStack.FillDirection = Enum.FillDirection.Vertical
vitalsStack.HorizontalAlignment = Enum.HorizontalAlignment.Center
vitalsStack.Padding = UDim.new(0, 6)
vitalsStack.Parent = vitals

local pillsRow = Instance.new("Frame")
pillsRow.Name = "PillsRow"
pillsRow.Size = UDim2.new(1, 0, 0, 40)
pillsRow.BackgroundTransparency = 1
pillsRow.Parent = vitals

local pillsLayout = Instance.new("UIListLayout")
pillsLayout.FillDirection = Enum.FillDirection.Horizontal
pillsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
pillsLayout.Padding = UDim.new(0, 10)
pillsLayout.Parent = pillsRow

local function createPill(name, icon, color)
	local pill = Instance.new("Frame")
	pill.Name = name
	-- 45% width each allows for 10px spacing without overflow on narrow screens
	pill.Size = UDim2.new(0.45, 0, 1, 0)
	pill.BackgroundColor3 = Config.UI.Colors.Background
	pill.BackgroundTransparency = 0.1
	pill.Parent = pillsRow
	rounded(pill)
	applyStroke(pill, color)

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -12, 1, 0)
	text.Position = UDim2.fromScale(0.5, 0.5)
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = 15
	text.TextColor3 = color or Config.UI.Colors.Text
	text.Text = icon .. " ---"
	text.Parent = pill

	return text
end

local coinsLabel = createPill("Coins", "🪙", Config.UI.Colors.Coin)
local bagLabel = createPill("Bag", "📦", Config.UI.Colors.Accent)

-- Bag Progress Bar (below pills inside vitals vertical stack)
local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.Size = UDim2.new(1, 0, 0, 6)
progressContainer.BackgroundColor3 = Config.UI.Colors.Background
progressContainer.BackgroundTransparency = 0.5
progressContainer.BorderSizePixel = 0
progressContainer.Parent = vitals
rounded(progressContainer, 3)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = Config.UI.Colors.Accent
progressFill.BorderSizePixel = 0
progressFill.Parent = progressContainer
rounded(progressFill, 3)

-- Action Button (Bottom Right - positioned safely above mobile jump button zone)
local actionContainer = Instance.new("Frame")
actionContainer.Name = "ActionContainer"
actionContainer.Size = UDim2.fromOffset(70, 70)
actionContainer.Position = UDim2.new(1, -16, 0.65, 0)
actionContainer.AnchorPoint = Vector2.new(1, 0.5)
actionContainer.BackgroundTransparency = 1
actionContainer.Parent = screen

local menuButton = Instance.new("TextButton")
menuButton.Name = "MenuButton"
menuButton.Size = UDim2.fromOffset(Config.UI.ButtonSize, Config.UI.ButtonSize)
menuButton.Position = UDim2.fromScale(0.5, 0.5)
menuButton.AnchorPoint = Vector2.new(0.5, 0.5)
menuButton.BackgroundColor3 = Config.UI.Colors.Accent
menuButton.Text = "⚡"
menuButton.TextSize = 30
menuButton.TextColor3 = Config.UI.Colors.Background
menuButton.Font = Enum.Font.GothamBlack
menuButton.Parent = actionContainer
rounded(menuButton, Config.UI.ButtonSize / 2)
applyStroke(menuButton, Color3.new(1, 1, 1), 2, 0.2)

-- Upgrade Drawer (Right Side)
local drawer = Instance.new("CanvasGroup")
drawer.Name = "UpgradeDrawer"
drawer.Size = UDim2.new(0.9, 0, 0.8, 0)
drawer.Position = UDim2.new(1.5, 0, 0.5, 0) -- Hidden by default
drawer.AnchorPoint = Vector2.new(1, 0.5)
drawer.BackgroundColor3 = Config.UI.Colors.Background
drawer.GroupTransparency = 0
drawer.Parent = screen
rounded(drawer)
applyStroke(drawer)

-- Drawer Max Width Constraint
local drawerConstraint = Instance.new("UISizeConstraint")
drawerConstraint.MaxSize = Vector2.new(Config.UI.DrawerMaxWidth, 1000)
drawerConstraint.Parent = drawer

local drawerPadding = Instance.new("UIPadding")
drawerPadding.PaddingTop = UDim.new(0, 20)
drawerPadding.PaddingBottom = UDim.new(0, 20)
drawerPadding.PaddingLeft = UDim.new(0, 20)
drawerPadding.PaddingRight = UDim.new(0, 20)
drawerPadding.Parent = drawer

local drawerTitle = Instance.new("TextLabel")
drawerTitle.Size = UDim2.new(1, 0, 0, 40)
drawerTitle.BackgroundTransparency = 1
drawerTitle.Font = Enum.Font.GothamBlack
drawerTitle.TextSize = 24
drawerTitle.TextColor3 = Config.UI.Colors.Accent
drawerTitle.Text = "UPGRADES"
drawerTitle.TextXAlignment = Enum.TextXAlignment.Left
drawerTitle.Parent = drawer

-- Logic & Animations (declared before CloseButton connection)
local drawerOpen = false
local function toggleDrawer()
	drawerOpen = not drawerOpen
	local targetPos = drawerOpen and UDim2.new(1, -20, 0.5, 0) or UDim2.new(1.5, 0, 0.5, 0)
	TweenService:Create(drawer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = targetPos,
	}):Play()
	menuButton.Text = drawerOpen and "✕" or "⚡"
	menuButton.BackgroundColor3 = drawerOpen and Config.UI.Colors.Danger or Config.UI.Colors.Accent
end

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, 0, 0, 0)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextSize = 22
closeBtn.TextColor3 = Config.UI.Colors.Text
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = drawerTitle
closeBtn.MouseButton1Click:Connect(toggleDrawer)

menuButton.MouseButton1Click:Connect(toggleDrawer)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -50)
scroll.Position = UDim2.new(0, 0, 0, 50)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Config.UI.Colors.Accent
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = drawer

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 10)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = scroll

local function createUpgradeCard(name, icon, order)
	local card = Instance.new("Frame")
	card.Name = name
	card.LayoutOrder = order
	card.Size = UDim2.new(1, 0, 0, 70)
	card.BackgroundColor3 = Color3.fromRGB(30, 45, 75)
	card.Parent = scroll
	rounded(card)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.6, 0, 0.5, 0)
	title.Position = UDim2.fromOffset(12, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Config.UI.Colors.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = icon .. " " .. name
	title.Parent = card

	local detail = Instance.new("TextLabel")
	detail.Name = "Detail"
	detail.Size = UDim2.new(0.6, 0, 0.4, 0)
	detail.Position = UDim2.new(0, 12, 0.5, 0)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.GothamMedium
	detail.TextSize = 14
	detail.TextColor3 = Config.UI.Colors.Accent
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.Text = "Level 0"
	detail.Parent = card

	local cost = Instance.new("TextLabel")
	cost.Name = "Cost"
	cost.Size = UDim2.new(0.35, 0, 0.6, 0)
	cost.Position = UDim2.new(1, -12, 0.5, 0)
	cost.AnchorPoint = Vector2.new(1, 0.5)
	cost.BackgroundColor3 = Config.UI.Colors.Background
	cost.Font = Enum.Font.GothamBold
	cost.TextSize = 16
	cost.TextColor3 = Config.UI.Colors.Coin
	cost.Text = "$0"
	cost.Parent = card
	rounded(cost, 8)
	applyStroke(cost, Config.UI.Colors.Coin, 1, 0.6)

	return { card = card, detail = detail, cost = cost }
end

local cards = {
	Speed = createUpgradeCard("Speed", "⚡", 1),
	Capacity = createUpgradeCard("Bag", "▣", 2),
	Generator = createUpgradeCard("Generator", "✦", 3),
	Zone = createUpgradeCard("Zone", "◈", 4),
}

-- Stats Overlay (Bottom Left)
local statsOverlay = Instance.new("Frame")
statsOverlay.Name = "StatsOverlay"
statsOverlay.Size = UDim2.new(0, 240, 0, 60)
statsOverlay.Position = UDim2.new(0, 20, 1, -20)
statsOverlay.AnchorPoint = Vector2.new(0, 1)
statsOverlay.BackgroundTransparency = 1
statsOverlay.Parent = screen

local statsLayout = Instance.new("UIListLayout")
statsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
statsLayout.Padding = UDim.new(0, 4)
statsLayout.Parent = statsOverlay

local function createSmallLabel(name, color)
	local lbl = Instance.new("TextLabel")
	lbl.Name = name
	lbl.Size = UDim2.new(1, 0, 0, 20)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 14
	lbl.TextColor3 = color or Config.UI.Colors.Text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = ""
	lbl.Parent = statsOverlay
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 0.5
	stroke.Parent = lbl
	return lbl
end

local incomeLabel = createSmallLabel("Income", Config.UI.Colors.Income)
local totalLabel = createSmallLabel("Total", Config.UI.Colors.Text)
local demoLabel = createSmallLabel("Demo", Config.UI.Colors.Danger)

-- Toasts (Top Center)
local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.Size = UDim2.new(0.8, 0, 0, 50)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0.15, 0)
toast.BackgroundColor3 = Config.UI.Colors.Background
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.TextColor3 = Color3.new(1, 1, 1)
toast.TextSize = 18
toast.Font = Enum.Font.GothamBold
toast.Parent = screen
rounded(toast)
applyStroke(toast)

local toastConstraint = Instance.new("UISizeConstraint")
toastConstraint.MaxSize = Vector2.new(400, 50)
toastConstraint.Parent = toast

local nonce = 0
notifyEvent.OnClientEvent:Connect(function(message)
	nonce += 1
	local current = nonce
	toast.Text = tostring(message)
	TweenService:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0.1, TextTransparency = 0 }):Play()
	task.delay(2.5, function()
		if nonce ~= current then return end
		TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
	end)
end)

-- Audio controls for environment (local-only mute toggle)
local function setupAudioControls()
	local audioButton = Instance.new("TextButton")
	audioButton.Name = "AudioButton"
	audioButton.Size = UDim2.fromOffset(70, 70)
	audioButton.Position = UDim2.new(1, -96, 0.65, 0)
	audioButton.AnchorPoint = Vector2.new(1, 0.5)
	audioButton.BackgroundTransparency = 1
	audioButton.Text = "🔊"
	audioButton.TextSize = 30
	audioButton.Font = Enum.Font.GothamBold
	audioButton.Parent = screen

	audioButton.MouseButton1Click:Connect(function()
		-- Local-only mute toggle: does NOT broadcast to other players
		if AudioService and AudioService.ToggleMute then
			AudioService:ToggleMute()
			audioButton.Text = AudioService:Icon()
		end
	end)
end

setupAudioControls()

local function formatCost(value)
	if value == "MAX" then return "MAX" end
	return type(value) == "number" and ("$" .. tostring(value)) or tostring(value)
end

syncEvent.OnClientEvent:Connect(function(data)
	coinsLabel.Text = string.format("🪙 %d", data.Coins)
	bagLabel.Text = string.format("📦 %d / %d", data.Crystals, data.Capacity)

	local fillScale = math.clamp(data.Crystals / math.max(1, data.Capacity), 0, 1)
	TweenService:Create(progressFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(fillScale, 1) }):Play()

	-- Update Drawer Cards
	cards.Speed.detail.Text = string.format("Level %d", data.SpeedLevel)
	cards.Speed.cost.Text = formatCost(data.NextCosts.Speed)

	cards.Capacity.detail.Text = string.format("Level %d", data.CapacityLevel)
	cards.Capacity.cost.Text = formatCost(data.NextCosts.Cost or data.NextCosts.Capacity) -- fallback check

	cards.Generator.detail.Text = string.format("Level %d", data.GeneratorLevel)
	cards.Generator.cost.Text = formatCost(data.NextCosts.Generator)

	cards.Zone.detail.Text = string.format("Zone %d / 3", data.ZoneLevel + 1)
	cards.Zone.cost.Text = formatCost(data.NextCosts.Zone)

	-- Update Stats
	incomeLabel.Text = string.format("Income: +%d / %ds", data.IncomePerTick, data.IncomeInterval)
	totalLabel.Text = string.format("Lifetime: %d", data.TotalCollected)
	demoLabel.Text = data.IsGuest and "STUDIO DEMO - NO SAVE" or ""
end)

-- Initial Sync
ReplicatedStorage.Remotes:WaitForChild("RequestSync"):FireServer()
