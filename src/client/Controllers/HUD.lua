-- Main HUD, laid out like the most successful simulators:
-- currencies top-left, big square buttons left, cycle/planet top-center, Shop + Menu top-right,
-- offers on the right, Power + evolution bar with quick-buy buttons at the bottom.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Evolutions = require(Shared.Config.Evolutions)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)
local Prices = require(script.Parent.Prices)

local HUD = {}

local player = Players.LocalPlayer
local Icons = Assets.Icons
local refs = {}
local gui

local function stroke(t)
	t.TextStrokeTransparency = 0
	t.TextStrokeColor3 = Color3.fromRGB(10, 5, 20)
	return t
end

local function counter(parent, order, iconId, emoji, color)
	local f = UI.New("Frame", {
		Size = UDim2.fromOffset(170, 48),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})
	UI.Icon(f, iconId, emoji, { Size = UDim2.fromOffset(46, 46), MaxTextSize = 36 })
	local t = stroke(UI.Text({
		Size = UDim2.new(1, -52, 1, 0),
		Position = UDim2.fromOffset(52, 0),
		Text = "0",
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 40,
		Parent = f,
	}))
	return t
end

local function bar(parent, props)
	local back = UI.New("Frame", {
		Size = props.Size,
		Position = props.Position,
		BackgroundColor3 = Color3.fromRGB(15, 10, 25),
		BorderSizePixel = 0,
		Parent = parent,
	})
	UI.Corner(UDim.new(0, 10)).Parent = back
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = back
	local fill = UI.New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = props.Color,
		BorderSizePixel = 0,
		Parent = back,
	})
	UI.Corner(UDim.new(0, 10)).Parent = fill
	UI.New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 210)),
		Rotation = 90,
		Parent = fill,
	})
	return back, fill
end

local function buildTop()
	local top = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(420, 78),
		Parent = gui,
	})
	refs.top = top
	refs.phase = stroke(UI.Text({
		Size = UDim2.new(1, -20, 0, 28),
		Position = UDim2.fromOffset(10, 4),
		Text = "",
		MaxTextSize = 26,
		Parent = top,
	}))
	local _, fill = bar(top, {
		Size = UDim2.new(1, -20, 0, 34),
		Position = UDim2.fromOffset(10, 36),
		Color = Color3.fromRGB(255, 90, 70),
	})
	refs.planetFill = fill
	refs.planetLabel = stroke(UI.Text({
		Size = UDim2.new(1, -20, 0, 34),
		Position = UDim2.fromOffset(10, 36),
		Text = "",
		ZIndex = 3,
		MaxTextSize = 20,
		Parent = top,
	}))
	refs.wrath = stroke(UI.Text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 88),
		Size = UDim2.fromOffset(460, 28),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 90, 90),
		MaxTextSize = 26,
		Parent = gui,
	}))
end

local function buildLeft()
	local left = UI.New("Frame", {
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.fromOffset(200, 420),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.left = left
	local counters = UI.New("Frame", {
		Size = UDim2.new(1, 0, 0, 100),
		BackgroundTransparency = 1,
		Parent = left,
	})
	UI.New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = counters })
	refs.planets = counter(counters, 1, Icons.Planets, "🏆", Color3.fromRGB(255, 220, 90))
	refs.shards = counter(counters, 2, Icons.Shards, "💎", Color3.fromRGB(140, 220, 255))

	local grid = UI.New("Frame", {
		Position = UDim2.fromOffset(0, 108),
		Size = UDim2.fromOffset(196, 300),
		BackgroundTransparency = 1,
		Parent = left,
	})
	UI.New("UIGridLayout", {
		CellSize = UDim2.fromOffset(92, 92),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	UI.SquareButton(grid, { Text = "Meteoriti", Emoji = "☄️", Icon = Icons.Meteors, LayoutOrder = 1 }, function()
		Panels.Toggle("Inventory")
	end)
	local evoButton = UI.SquareButton(
		grid,
		{ Text = "Evoluzione", Emoji = "🌟", Icon = Icons.Evolution, LayoutOrder = 2 },
		function()
			Panels.Toggle("Evolution")
		end
	)
	refs.evoBadge = UI.Badge(evoButton)
	UI.SquareButton(grid, { Text = "Potenzia", Emoji = "⬆️", Icon = Icons.Upgrades, LayoutOrder = 3 }, function()
		Panels.Toggle("Upgrades")
	end)
	local giftButton, giftCaption = UI.SquareButton(
		grid,
		{ Text = "", Emoji = "🎁", Icon = Icons.Daily, LayoutOrder = 4 },
		function()
			local readyAt = player:GetAttribute("GiftReadyAt") or math.huge
			if workspace:GetServerTimeNow() >= readyAt then
				Remotes.Get("ClaimGift"):FireServer()
			end
		end
	)
	refs.giftButton = giftButton
	refs.giftCaption = giftCaption
	UI.SquareButton(grid, { Text = "Indice", Emoji = "📖", Icon = Icons.Index, LayoutOrder = 5 }, function()
		Panels.Toggle("Index")
	end)
	UI.SquareButton(grid, { Text = "Scambi", Emoji = "🤝", Icon = Icons.Trade, LayoutOrder = 6 }, function()
		Panels.Toggle("TradeList")
	end)
end

local function menuItem(parent, order, text, emoji, iconId, onClick)
	local b = UI.New("TextButton", {
		Size = UDim2.new(1, 0, 0, 52),
		LayoutOrder = order,
		BackgroundColor3 = Color3.fromRGB(80, 70, 150),
		AutoButtonColor = true,
		Text = "",
		BorderSizePixel = 0,
		Parent = parent,
	})
	UI.Corner(UDim.new(0, 10)).Parent = b
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = b
	UI.Icon(b, iconId, emoji, { Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(8, 6), MaxTextSize = 30 })
	stroke(UI.Text({
		Size = UDim2.new(1, -60, 1, -10),
		Position = UDim2.fromOffset(54, 5),
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 22,
		Parent = b,
	}))
	b.Activated:Connect(onClick)
	return b
end

local function buildTopRight()
	local bar = UI.New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.fromOffset(200, 92),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.topRight = bar
	UI.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = bar,
	})
	UI.SquareButton(bar, { Text = "Negozio", Emoji = "🛒", Icon = Icons.Shop, LayoutOrder = 1, Size = UDim2.fromOffset(84, 84) }, function()
		Panels.Toggle("Shop")
	end)
	local menuButton, menuCaption = UI.SquareButton(
		bar,
		{ Text = "Menu", Emoji = "☰", Icon = Icons.Menu, LayoutOrder = 2, Size = UDim2.fromOffset(84, 84) },
		function()
			refs.dropdown.Visible = not refs.dropdown.Visible
		end
	)
	refs.menuBadge = UI.Badge(menuButton)
	refs.menuCaption = menuCaption

	local dropdown = UI.New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 100),
		Size = UDim2.fromOffset(240, 240),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	})
	refs.dropdown = dropdown
	UI.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = dropdown })
	local daily = menuItem(dropdown, 1, "Giornaliero", "📅", Icons.Daily, function()
		dropdown.Visible = false
		Panels.Toggle("Daily")
	end)
	refs.dailyBadge = UI.Badge(daily)
	menuItem(dropdown, 2, "Codici", "🔑", Icons.Codes, function()
		dropdown.Visible = false
		Panels.Toggle("Codes")
	end)
	menuItem(dropdown, 3, "Impostazioni", "⚙️", Icons.Settings, function()
		dropdown.Visible = false
		Panels.Toggle("Settings")
	end)
	menuItem(dropdown, 4, "Nascondi HUD", "👁️", nil, function()
		dropdown.Visible = false
		HUD.SetHidden(true)
	end)
end

local function offerCard(parent, order, title, emoji, iconId, rainbow, onClick)
	local holder = UI.New("Frame", {
		Size = UDim2.new(1, 0, 0, 96),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})
	local b = UI.New("TextButton", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutoButtonColor = true,
		Text = "",
		BorderSizePixel = 0,
		Parent = holder,
	})
	UI.Corner(UDim.new(0, 12)).Parent = b
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = b
	local gradient = UI.New("UIGradient", {
		Color = rainbow and ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 160)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 200, 60)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(70, 230, 140)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 140, 255)),
		}) or ColorSequence.new(Color3.fromRGB(120, 200, 255), Color3.fromRGB(70, 90, 200)),
		Parent = b,
	})
	if rainbow then
		task.spawn(function()
			while b.Parent do
				gradient.Offset = Vector2.new(math.sin(os.clock() * 1.5) * 0.3, 0)
				task.wait(0.05)
			end
		end)
	end
	UI.Icon(b, iconId, emoji, { Size = UDim2.fromOffset(54, 54), Position = UDim2.fromOffset(6, 5), MaxTextSize = 40 })
	stroke(UI.Text({
		Size = UDim2.new(1, -70, 1, -8),
		Position = UDim2.fromOffset(64, 4),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 26,
		Parent = b,
	}))
	local price = stroke(UI.Text({
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 66),
		Text = "",
		TextColor3 = Color3.fromRGB(120, 255, 120),
		MaxTextSize = 26,
		Parent = holder,
	}))
	b.Activated:Connect(onClick)
	return holder, price
end

local function buildRight()
	local right = UI.New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.52, 0),
		Size = UDim2.fromOffset(230, 320),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.right = right
	UI.New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right })
	refs.starterCard, refs.starterPrice = offerCard(right, 1, "Pacchetto Iniziale", "🎁", Icons.StarterPack, false, function()
		Prices.BuyProduct("StarterPack")
	end)
	refs.powerCard, refs.powerPrice = offerCard(right, 2, "2x Potere", "⚡", Icons.Power, true, function()
		Prices.BuyPass("Power2x")
	end)
	refs.wrathCard, refs.wrathPrice = offerCard(right, 3, "Ira Divina x3", "🔥", Icons.Wrath, false, function()
		Prices.BuyProduct("DivineWrath")
	end)
end

local function quickBuy(parent, order, text, key)
	local holder = UI.New("Frame", {
		Size = UDim2.fromOffset(150, 74),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})
	local price = stroke(UI.Text({
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		TextColor3 = Color3.fromRGB(120, 255, 120),
		MaxTextSize = 20,
		Parent = holder,
	}))
	local b = UI.Button({
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 48),
		Text = text,
		BackgroundColor3 = Color3.fromRGB(110, 80, 200),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		MaxTextSize = 22,
		Parent = holder,
	}, function()
		Prices.BuyProduct(key)
	end)
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = b
	return price, key
end

local function buildBottom()
	local bottom = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.fromOffset(640, 176),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.bottom = bottom
	refs.totalPower = stroke(UI.Text({
		Size = UDim2.new(1, 0, 0, 34),
		Text = "",
		MaxTextSize = 32,
		Parent = bottom,
	}))
	refs.boost = stroke(UI.Text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 34),
		Size = UDim2.fromOffset(260, 18),
		Text = "",
		TextColor3 = UI.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Right,
		MaxTextSize = 16,
		Parent = bottom,
	}))
	local back, fill = bar(bottom, {
		Size = UDim2.new(1, 0, 0, 46),
		Position = UDim2.fromOffset(0, 52),
		Color = Color3.fromRGB(150, 110, 255),
	})
	refs.evoFill = fill
	refs.evoLeft = stroke(UI.Text({
		Size = UDim2.new(0.7, -14, 1, -6),
		Position = UDim2.fromOffset(14, 3),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		MaxTextSize = 30,
		Parent = back,
	}))
	refs.evoRight = stroke(UI.Text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 3),
		Size = UDim2.new(0.3, -14, 1, -6),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
		MaxTextSize = 30,
		Parent = back,
	}))
	local quick = UI.New("Frame", {
		Position = UDim2.fromOffset(0, 102),
		Size = UDim2.new(1, 0, 0, 74),
		BackgroundTransparency = 1,
		Parent = bottom,
	})
	UI.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = quick,
	})
	refs.quick = {
		{ quickBuy(quick, 1, "+10 min Potere", "PowerS") },
		{ quickBuy(quick, 2, "+1 ora Potere", "PowerM") },
		{ quickBuy(quick, 3, "+6 ore Potere", "PowerL") },
		{ quickBuy(quick, 4, "2x Potere 30m", "Boost2x") },
	}
end

local function buildShowButton()
	refs.show = UI.Button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.fromOffset(150, 44),
		Text = "👁️ Mostra HUD",
		BackgroundColor3 = UI.Colors.PanelLight,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
		Parent = gui,
	}, function()
		HUD.SetHidden(false)
	end)
end

function HUD.SetHidden(hidden)
	for _, key in ipairs({ "top", "left", "topRight", "right", "bottom", "wrath" }) do
		refs[key].Visible = not hidden
	end
	refs.dropdown.Visible = false
	refs.show.Visible = hidden
	if hidden then
		Panels.CloseAll()
	end
end

local lastPriceRefresh = 0
local function refreshPrices()
	refs.starterPrice.Text = "SOLO " .. Prices.ProductText("StarterPack")
	refs.powerPrice.Text = "SOLO " .. Prices.PassText("Power2x")
	refs.wrathPrice.Text = "SOLO " .. Prices.ProductText("DivineWrath")
	for _, q in ipairs(refs.quick) do
		q[1].Text = Prices.ProductText(q[2])
	end
end

local function update()
	local now = workspace:GetServerTimeNow()

	-- Cycle & planet.
	local phase = workspace:GetAttribute("CyclePhase")
	local left = math.max(0, (workspace:GetAttribute("PhaseEndsAt") or 0) - now)
	if phase == "Bombard" then
		refs.phase.Text = "🪐 BOMBARDAMENTO  " .. Format.Time(left)
		refs.phase.TextColor3 = Color3.fromRGB(160, 210, 255)
	else
		refs.phase.Text = "☄️ PIOGGIA DI METEORITI  " .. Format.Time(left)
		refs.phase.TextColor3 = Color3.fromRGB(255, 190, 100)
	end
	local hp = workspace:GetAttribute("PlanetHP") or 0
	local maxHP = math.max(1, workspace:GetAttribute("PlanetMaxHP") or 1)
	refs.planetFill.Size = UDim2.fromScale(math.clamp(hp / maxHP, 0, 1), 1)
	refs.planetLabel.Text = (workspace:GetAttribute("PlanetName") or "")
		.. "  ·  "
		.. Format.Number(hp)
		.. " / "
		.. Format.Number(maxHP)
	local wrathLeft = (workspace:GetAttribute("WrathUntil") or 0) - now
	refs.wrath.Text = wrathLeft > 0 and ("⚡ IRA DIVINA: DANNO x3  " .. Format.Time(wrathLeft)) or ""

	-- Currencies.
	local power = player:GetAttribute("Power") or 0
	local planets = player:GetAttribute("Planets") or 0
	refs.planets.Text = Format.Number(planets)
	refs.shards.Text = Format.Number(player:GetAttribute("Shards") or 0)
	refs.totalPower.Text = "Potere totale: "
		.. Format.Number(power)
		.. "   (+"
		.. Format.Number(player:GetAttribute("PowerRate") or 0)
		.. "/s)"
	local boostLeft = (player:GetAttribute("Boost2xUntil") or 0) - os.time()
	refs.boost.Text = boostLeft > 0 and ("🧪 Boost 2x Potere  " .. Format.Time(boostLeft)) or ""

	-- Evolution bar.
	local evoIndex = player:GetAttribute("Evolution") or 1
	local evo = Evolutions.Get(evoIndex)
	local asc = player:GetAttribute("Ascensions") or 0
	refs.evoLeft.Text = evo.name .. (asc > 0 and ("  ✨" .. asc) or "")
	refs.evoFill.BackgroundColor3 = evo.aura
	local ready = false
	if evoIndex >= Evolutions.Max() then
		refs.evoFill.Size = UDim2.fromScale(1, 1)
		refs.evoRight.Text = "MAX"
		refs.evoRight.TextColor3 = Color3.fromRGB(255, 80, 80)
	else
		local nextEvo = Evolutions.Get(evoIndex + 1)
		local pPower = nextEvo.power > 0 and math.clamp(power / nextEvo.power, 0, 1) or 1
		local pPlanets = nextEvo.planets > 0 and math.clamp(planets / nextEvo.planets, 0, 1) or 1
		local progress = (pPower + pPlanets) / 2
		ready = pPower >= 1 and pPlanets >= 1
		refs.evoFill.Size = UDim2.fromScale(math.max(progress, 0.02), 1)
		refs.evoRight.Text = ready and "EVOLVI!" or (math.floor(progress * 100) .. "%")
		refs.evoRight.TextColor3 = ready and UI.Colors.Gold or Color3.fromRGB(255, 255, 255)
	end
	refs.evoBadge.Visible = ready

	-- Gift timer.
	local giftLeft = (player:GetAttribute("GiftReadyAt") or now + 1) - now
	if giftLeft <= 0 then
		refs.giftCaption.Text = "RISCATTA!"
		refs.giftCaption.TextColor3 = UI.Colors.Gold
	else
		refs.giftCaption.Text = Format.Time(giftLeft)
		refs.giftCaption.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	-- Badges and offers.
	local dailyAvailable = player:GetAttribute("DailyAvailable") == true
	refs.dailyBadge.Visible = dailyAvailable
	refs.menuBadge.Visible = dailyAvailable
	refs.starterCard.Visible = player:GetAttribute("StarterPackBought") ~= true
	refs.powerCard.Visible = player:GetAttribute("Pass_Power2x") ~= true

	if os.clock() - lastPriceRefresh > 10 then
		lastPriceRefresh = os.clock()
		task.spawn(refreshPrices)
	end
end

function HUD:Init()
	gui = UI.Screen("HUD", 5)
	buildTop()
	buildLeft()
	buildTopRight()
	buildRight()
	buildBottom()
	buildShowButton()
end

function HUD:Start()
	-- Pulse the gift button when it's ready.
	task.spawn(function()
		while true do
			update()
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		local scale = UI.New("UIScale", { Parent = refs.giftButton })
		while true do
			local readyAt = player:GetAttribute("GiftReadyAt") or math.huge
			if workspace:GetServerTimeNow() >= readyAt then
				TweenService:Create(scale, TweenInfo.new(0.3), { Scale = 1.08 }):Play()
				task.wait(0.3)
				TweenService:Create(scale, TweenInfo.new(0.3), { Scale = 1 }):Play()
				task.wait(0.5)
			else
				scale.Scale = 1
				task.wait(0.5)
			end
		end
	end)
end

return HUD
