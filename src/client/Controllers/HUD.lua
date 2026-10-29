-- Main HUD ("celestial" style):
-- currency pills top-left, orbit dock of round buttons on the left, cycle + planet bar top-center,
-- Shop/Menu orbs top-right, one rotating "Celestial Offer" card on the right,
-- Divine Power counter with a slim evolution line at the bottom.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Evolutions = require(Shared.Config.Evolutions)
local Game = require(Shared.Config.Game)
local Monetization = require(Shared.Config.Monetization)
local Format = require(Shared.Util.Format)
local PlanetInfo = require(Shared.Util.PlanetInfo)
local Planets = require(Shared.Config.Planets)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)
local Prices = require(script.Parent.Prices)

local HUD = {}

local player = Players.LocalPlayer
local Icons = Assets.Icons
local refs = {}
local gui

local OFFERS = {
	{ key = "StarterPack", kind = "product", title = "Starter Pack", emoji = "🎁", icon = Icons.StarterPack },
	{ key = "Power2x", kind = "pass", title = "2x Power forever", emoji = "⚡", icon = Icons.Power },
	{ key = "DivineWrath", kind = "product", title = "Divine Wrath x3", emoji = "🔥", icon = Icons.Wrath },
	{ key = "LegendaryPlanet", kind = "product", title = "Legendary Planet", emoji = "⭐", icon = Icons.Planets },
}

local function pill(parent, order, iconId, emoji, color)
	local f = UI.New("Frame", {
		Size = UDim2.fromOffset(176, 42),
		BackgroundColor3 = UI.Colors.Panel,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = parent,
	})
	UI.Corner(UDim.new(1, 0)).Parent = f
	UI.Stroke(color, 1.5, 0.3).Parent = f
	local bubble = UI.New("Frame", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = f,
	})
	UI.Corner(UDim.new(1, 0)).Parent = bubble
	UI.Icon(bubble, iconId, emoji, { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), MaxTextSize = 22 })
	return UI.Text({
		Size = UDim2.new(1, -54, 1, -8),
		Position = UDim2.fromOffset(46, 4),
		Text = "0",
		Font = UI.TitleFont,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 24,
		Parent = f,
	})
end

local function thinBar(parent, props)
	local back = UI.New("Frame", {
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = Color3.fromRGB(8, 8, 20),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = parent,
	})
	UI.Corner(UDim.new(1, 0)).Parent = back
	UI.Stroke(props.Color, 1, 0.4).Parent = back
	local fill = UI.New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = props.Color,
		BorderSizePixel = 0,
		Parent = back,
	})
	UI.Corner(UDim.new(1, 0)).Parent = fill
	UI.New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 220)),
		Parent = fill,
	})
	return back, fill
end

local function buildTopLeft()
	local f = UI.New("Frame", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.fromOffset(180, 140),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.topLeft = f
	UI.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f })
	refs.planets = pill(f, 1, Icons.Planets, "🪐", Color3.fromRGB(255, 205, 110))
	refs.shards = pill(f, 2, Icons.Shards, "💎", Color3.fromRGB(90, 220, 255))
	refs.stardust = pill(f, 3, Icons.Stardust, "✨", Color3.fromRGB(200, 160, 255))
end

local function buildDock()
	-- Starts below the currency pills so it never covers them.
	local dock = UI.Panel({
		Position = UDim2.fromOffset(14, 160),
		Size = UDim2.fromOffset(88, 476),
		BackgroundTransparency = 0.35,
		Parent = gui,
	})
	refs.dock = dock
	UI.Padding(8).Parent = dock
	UI.New("UIListLayout", {
		Padding = UDim.new(0, 2),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = dock,
	})
	local giftButton, giftCaption = UI.Orb(dock, { Text = "", Emoji = "🎁", Icon = Icons.Daily, LayoutOrder = 1, Ring = UI.Colors.Cyan, Size = 54 }, function()
		local readyAt = player:GetAttribute("GiftReadyAt") or math.huge
		if workspace:GetServerTimeNow() >= readyAt then
			Remotes.Get("ClaimGift"):FireServer()
		end
	end)
	refs.giftButton, refs.giftCaption = giftButton, giftCaption
	UI.Orb(dock, { Text = "Meteors", Emoji = "☄️", Icon = Icons.Meteors, LayoutOrder = 2, Size = 54 }, function()
		Panels.Toggle("Inventory")
	end)
	local evo = UI.Orb(dock, { Text = "Evolution", Emoji = "🌟", Icon = Icons.Evolution, LayoutOrder = 3, Size = 54 }, function()
		Panels.Toggle("Evolution")
	end)
	refs.evoBadge = UI.Badge(evo)
	UI.Orb(dock, { Text = "Upgrade", Emoji = "⬆️", Icon = Icons.Upgrades, LayoutOrder = 4, Size = 54 }, function()
		Panels.Toggle("Upgrades")
	end)
	UI.Orb(dock, { Text = "Index", Emoji = "📖", Icon = Icons.Index, LayoutOrder = 5, Size = 54 }, function()
		Panels.Toggle("Index")
	end)
	UI.Orb(dock, { Text = "Trade", Emoji = "🤝", Icon = Icons.Trade, LayoutOrder = 6, Size = 54 }, function()
		Panels.Toggle("TradeList")
	end)
end

local function buildTop()
	local top = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(440, 80),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.top = top
	local phasePill = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(300, 32),
		BackgroundColor3 = UI.Colors.Panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = top,
	})
	UI.Corner(UDim.new(1, 0)).Parent = phasePill
	refs.phaseStroke = UI.Stroke(UI.Colors.Gold, 1.5, 0.2)
	refs.phaseStroke.Parent = phasePill
	refs.phase = UI.Text({
		Size = UDim2.new(1, -16, 1, -6),
		Position = UDim2.fromOffset(8, 3),
		Text = "",
		Font = UI.TitleFont,
		MaxTextSize = 18,
		Parent = phasePill,
	})
	refs.planetName = UI.Text({
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "",
		TextColor3 = UI.Colors.Muted,
		TextStrokeTransparency = 0.4,
		MaxTextSize = 15,
		Parent = top,
	})
	local _, fill = thinBar(top, {
		Position = UDim2.fromOffset(20, 60),
		Size = UDim2.new(1, -40, 0, 12),
		Color = Color3.fromRGB(255, 110, 80),
	})
	refs.planetFill = fill
	refs.wrath = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 94),
		Size = UDim2.fromOffset(460, 26),
		Text = "",
		Font = UI.TitleFont,
		TextColor3 = Color3.fromRGB(255, 100, 90),
		TextStrokeTransparency = 0.2,
		MaxTextSize = 22,
		Parent = gui,
	})
end

local function menuItem(parent, order, text, emoji, iconId, onClick)
	local b = UI.New("TextButton", {
		Size = UDim2.new(1, 0, 0, 46),
		LayoutOrder = order,
		BackgroundColor3 = UI.Colors.PanelLight,
		BackgroundTransparency = 0.1,
		AutoButtonColor = true,
		Text = "",
		BorderSizePixel = 0,
		Parent = parent,
	})
	UI.Corner(UDim.new(0, 12)).Parent = b
	UI.Icon(b, iconId, emoji, { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(10, 8), MaxTextSize = 22 })
	UI.Text({
		Size = UDim2.new(1, -56, 1, -12),
		Position = UDim2.fromOffset(48, 6),
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 18,
		Parent = b,
	})
	b.Activated:Connect(onClick)
	return b
end

local function buildTopRight()
	local bar = UI.New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(190, 90),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.topRight = bar
	UI.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = bar,
	})
	UI.Orb(bar, { Text = "Shop", Emoji = "🛒", Icon = Icons.Shop, LayoutOrder = 1, Color = Color3.fromRGB(60, 120, 90) }, function()
		Panels.Toggle("Shop")
	end)
	local menuButton = UI.Orb(bar, { Text = "Menu", Emoji = "☰", Icon = Icons.Menu, LayoutOrder = 2 }, function()
		refs.dropdown.Visible = not refs.dropdown.Visible
	end)
	refs.menuBadge = UI.Badge(menuButton)

	local dropdown = UI.Panel({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 100),
		Size = UDim2.fromOffset(230, 222),
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	})
	refs.dropdown = dropdown
	UI.Padding(8).Parent = dropdown
	UI.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = dropdown })
	local daily = menuItem(dropdown, 1, "Daily rewards", "📅", Icons.Daily, function()
		dropdown.Visible = false
		Panels.Toggle("Daily")
	end)
	refs.dailyBadge = UI.Badge(daily)
	menuItem(dropdown, 2, "Codes", "🔑", Icons.Codes, function()
		dropdown.Visible = false
		Panels.Toggle("Codes")
	end)
	menuItem(dropdown, 3, "Settings", "⚙️", Icons.Settings, function()
		dropdown.Visible = false
		Panels.Toggle("Settings")
	end)
	menuItem(dropdown, 4, "Hide interface", "👁️", nil, function()
		dropdown.Visible = false
		HUD.SetHidden(true)
	end)
end

-- One card that cycles through the offers (instead of a wall of ads).
local function buildOffer()
	local card = UI.Panel({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(190, 196),
		Parent = gui,
	})
	refs.offer = card
	UI.Text({
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "CELESTIAL OFFER",
		Font = UI.TitleFont,
		TextColor3 = UI.Colors.Gold,
		MaxTextSize = 13,
		Parent = card,
	})
	local iconHolder = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 28),
		Size = UDim2.fromOffset(70, 70),
		BackgroundTransparency = 1,
		Parent = card,
	})
	refs.offerIconHolder = iconHolder
	refs.offerTitle = UI.Text({
		Position = UDim2.fromOffset(8, 102),
		Size = UDim2.new(1, -16, 0, 36),
		Text = "",
		Font = UI.TitleFont,
		TextWrapped = true,
		MaxTextSize = 17,
		Parent = card,
	})
	refs.offerButton = UI.Button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 142),
		Size = UDim2.new(1, -24, 0, 34),
		Text = "",
		MaxTextSize = 18,
		Parent = card,
	}, function()
		local o = refs.currentOffer
		if not o then
			return
		end
		if o.kind == "pass" then
			Prices.BuyPass(o.key)
		else
			Prices.BuyProduct(o.key)
		end
	end)
	refs.offerDots = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.fromOffset(80, 8),
		BackgroundTransparency = 1,
		Parent = card,
	})
	UI.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 5),
		Parent = refs.offerDots,
	})
end

local offerIndex = 0
local function availableOffers()
	local list = {}
	for _, o in ipairs(OFFERS) do
		local hidden = (o.key == "StarterPack" and player:GetAttribute("StarterPackBought"))
			or (o.kind == "pass" and player:GetAttribute("Pass_" .. o.key))
		if not hidden then
			table.insert(list, o)
		end
	end
	return list
end

local function showNextOffer()
	local list = availableOffers()
	refs.offer.Visible = #list > 0
	if #list == 0 then
		return
	end
	offerIndex = offerIndex % #list + 1
	local o = list[offerIndex]
	refs.currentOffer = o
	UI.Clear(refs.offerIconHolder)
	UI.Icon(refs.offerIconHolder, o.icon, o.emoji, { MaxTextSize = 54 })
	refs.offerTitle.Text = o.title
	local cfg = o.kind == "pass" and Monetization.GamePasses[o.key] or Monetization.Products[o.key]
	refs.offerButton.Text = cfg and cfg.id ~= 0 and (o.kind == "pass" and Prices.PassText(o.key) or Prices.ProductText(o.key))
		or "Soon"
	UI.Clear(refs.offerDots)
	for i = 1, #list do
		local dot = UI.New("Frame", {
			Size = UDim2.fromOffset(i == offerIndex and 16 or 6, 6),
			BackgroundColor3 = i == offerIndex and UI.Colors.Gold or UI.Colors.Muted,
			BorderSizePixel = 0,
			Parent = refs.offerDots,
		})
		UI.Corner(UDim.new(1, 0)).Parent = dot
	end
	local scale = refs.offer:FindFirstChildOfClass("UIScale") or UI.New("UIScale", { Parent = refs.offer })
	scale.Scale = 0.94
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function buildBottom()
	local bottom = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(520, 104),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.bottom = bottom
	refs.power = UI.Text({
		Size = UDim2.new(1, 0, 0, 46),
		Text = "",
		Font = UI.TitleFont,
		TextColor3 = UI.Colors.Gold,
		TextStrokeTransparency = 0.1,
		TextStrokeColor3 = Color3.fromRGB(60, 30, 0),
		MaxTextSize = 44,
		Parent = bottom,
	})
	refs.rate = UI.Text({
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "",
		TextColor3 = UI.Colors.Cyan,
		TextStrokeTransparency = 0.3,
		MaxTextSize = 16,
		Parent = bottom,
	})
	refs.evoText = UI.Text({
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "",
		Font = UI.TitleFont,
		TextStrokeTransparency = 0.3,
		MaxTextSize = 14,
		Parent = bottom,
	})
	local _, fill = thinBar(bottom, {
		Position = UDim2.fromOffset(40, 88),
		Size = UDim2.new(1, -80, 0, 10),
		Color = UI.Colors.Purple,
	})
	refs.evoFill = fill
	local plus = UI.Button({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, -30, 0, 23),
		Size = UDim2.fromOffset(36, 36),
		Text = "+",
		MaxTextSize = 26,
		Parent = bottom,
	}, function()
		Panels.Toggle("Shop")
	end)
	UI.Corner(UDim.new(1, 0)).Parent = plus
end

local function buildShowButton()
	refs.show = UI.Button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(170, 40),
		Text = "Show interface",
		BackgroundColor3 = UI.Colors.PanelLight,
		TextColor3 = Color3.new(1, 1, 1),
		MaxTextSize = 16,
		Visible = false,
		Parent = gui,
	}, function()
		HUD.SetHidden(false)
	end)
end

function HUD.SetHidden(hidden)
	for _, key in ipairs({ "top", "topLeft", "dock", "topRight", "offer", "bottom", "wrath" }) do
		refs[key].Visible = not hidden
	end
	refs.dropdown.Visible = false
	refs.show.Visible = hidden
	if hidden then
		Panels.CloseAll()
	elseif #availableOffers() == 0 then
		refs.offer.Visible = false
	end
end

local function update()
	local now = workspace:GetServerTimeNow()

	local phase = workspace:GetAttribute("CyclePhase")
	local left = math.max(0, (workspace:GetAttribute("PhaseEndsAt") or 0) - now)
	local goAt = workspace:GetAttribute("ShowerGoAt") or 0
	if goAt > now then
		refs.phase.Text = "SHOWER IN  " .. math.ceil(goAt - now)
		refs.phase.TextColor3 = Color3.fromRGB(255, 200, 120)
		refs.phaseStroke.Color = UI.Colors.Gold
	elseif phase ~= "Shower" then
		refs.phase.Text = "NEXT SHOWER  " .. Format.Time(left)
		refs.phase.TextColor3 = Color3.fromRGB(150, 210, 255)
		refs.phaseStroke.Color = Color3.fromRGB(110, 180, 255)
	else
		local event = Game.EventByID[workspace:GetAttribute("CosmicEvent") or ""]
		refs.phase.Text = (event and (event.name .. "  ") or "METEOR SHOWER  ") .. Format.Time(left)
		refs.phase.TextColor3 = Color3.fromRGB(255, 200, 120)
		refs.phaseStroke.Color = UI.Colors.Gold
	end
	-- Planet of the lane you're on, otherwise the highest tier you unlocked.
	local tier = player:GetAttribute("FocusTier") or PlanetInfo.TierForEvolution(player:GetAttribute("Evolution"))
	local info = PlanetInfo.Get(tier)
	if info then
		refs.planetFill.Size = UDim2.fromScale(math.clamp(info.hp / info.maxHP, 0, 1), 1)
		refs.planetName.Text = Planets.Tiers[tier].name .. " · " .. info.name .. "  ·  "
			.. (info.ready and (info.layer .. "  ·  " .. Format.Number(info.hp) .. " / " .. Format.Number(info.maxHP)) or "coming through the rift...")
	end
	local wrathLeft = (workspace:GetAttribute("WrathUntil") or 0) - now
	refs.wrath.Text = wrathLeft > 0 and ("DIVINE WRATH · x3 DAMAGE · " .. Format.Time(wrathLeft)) or ""

	local power = player:GetAttribute("Power") or 0
	local planets = player:GetAttribute("Planets") or 0
	refs.planets.Text = Format.Number(planets)
	refs.shards.Text = Format.Number(player:GetAttribute("Shards") or 0)
	refs.stardust.Text = Format.Number(player:GetAttribute("Stardust") or 0)
	refs.power.Text = "⚡ " .. Format.Number(power)
	local boostLeft = (player:GetAttribute("Boost2xUntil") or 0) - os.time()
	refs.rate.Text = "+"
		.. Format.Number(player:GetAttribute("PowerRate") or 0)
		.. " Power/s"
		.. (boostLeft > 0 and ("   ·   Boost x2 " .. Format.Time(boostLeft)) or "")

	local evoIndex = player:GetAttribute("Evolution") or 1
	local evo = Evolutions.Get(evoIndex)
	local asc = player:GetAttribute("Ascensions") or 0
	refs.evoFill.BackgroundColor3 = evo.aura
	local ready = false
	if evoIndex >= Evolutions.Max() then
		refs.evoFill.Size = UDim2.fromScale(1, 1)
		refs.evoText.Text = string.upper(evo.name) .. (asc > 0 and ("  ·  ASCENSION " .. asc) or "") .. "  ·  MAX"
	else
		local nextEvo = Evolutions.Get(evoIndex + 1)
		local pPower = nextEvo.power > 0 and math.clamp(power / nextEvo.power, 0, 1) or 1
		local pPlanets = nextEvo.planets > 0 and math.clamp(planets / nextEvo.planets, 0, 1) or 1
		local progress = (pPower + pPlanets) / 2
		ready = pPower >= 1 and pPlanets >= 1
		refs.evoFill.Size = UDim2.fromScale(math.max(progress, 0.02), 1)
		refs.evoText.Text = string.upper(evo.name)
			.. "  →  "
			.. string.upper(nextEvo.name)
			.. "   "
			.. (ready and "READY!" or (math.floor(progress * 100) .. "%"))
	end
	refs.evoText.TextColor3 = ready and UI.Colors.Gold or Color3.new(1, 1, 1)
	refs.evoBadge.Visible = ready

	local giftLeft = (player:GetAttribute("GiftReadyAt") or now + 1) - now
	refs.giftCaption.Text = giftLeft <= 0 and "CLAIM!" or Format.Time(giftLeft)
	refs.giftCaption.TextColor3 = giftLeft <= 0 and UI.Colors.Gold or Color3.new(1, 1, 1)

	local dailyAvailable = player:GetAttribute("DailyAvailable") == true
	refs.dailyBadge.Visible = dailyAvailable
	refs.menuBadge.Visible = dailyAvailable
end

function HUD:Init()
	gui = UI.Screen("HUD", 5)
	buildTopLeft()
	buildDock()
	buildTop()
	buildTopRight()
	buildOffer()
	buildBottom()
	buildShowButton()
	UI.Text({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -8, 1, -4),
		Size = UDim2.fromOffset(120, 14),
		Text = "v" .. require(Shared.Config.Game).Version,
		TextColor3 = UI.Colors.Muted,
		TextTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Right,
		MaxTextSize = 12,
		Parent = gui,
	})
end

function HUD:Start()
	task.spawn(function()
		while true do
			update()
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		while true do
			if refs.dock.Visible then
				showNextOffer()
			end
			task.wait(6)
		end
	end)
	task.spawn(function()
		local scale = UI.New("UIScale", { Parent = refs.giftButton })
		while true do
			local readyAt = player:GetAttribute("GiftReadyAt") or math.huge
			if workspace:GetServerTimeNow() >= readyAt then
				TweenService:Create(scale, TweenInfo.new(0.3), { Scale = 1.1 }):Play()
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
