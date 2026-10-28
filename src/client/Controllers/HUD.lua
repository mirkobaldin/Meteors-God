-- Main HUD: cycle timer, planet health, Power/Shards, evolution progress and menu buttons.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Evolutions = require(Shared.Config.Evolutions)
local Monetization = require(Shared.Config.Monetization)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)

local HUD = {}

local player = Players.LocalPlayer
local controllers
local refs = {}

local function bar(parent, props)
	local back = UI.New("Frame", {
		Size = props.Size,
		Position = props.Position,
		BackgroundColor3 = Color3.fromRGB(15, 10, 25),
		BorderSizePixel = 0,
		Parent = parent,
	})
	UI.Corner(UDim.new(1, 0)).Parent = back
	local fill = UI.New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = props.Color,
		BorderSizePixel = 0,
		Parent = back,
	})
	UI.Corner(UDim.new(1, 0)).Parent = fill
	local label = UI.Text({
		Size = UDim2.fromScale(1, 1),
		Text = "",
		MaxTextSize = props.TextSize or 18,
		ZIndex = 3,
		TextStrokeTransparency = 0.4,
		Parent = back,
	})
	return fill, label
end

local function build()
	local gui = UI.Screen("HUD", 5)

	-- Top: cycle + planet.
	local top = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(440, 92),
		Parent = gui,
	})
	refs.phase = UI.Text({
		Size = UDim2.new(1, -20, 0, 30),
		Position = UDim2.fromOffset(10, 6),
		Text = "",
		MaxTextSize = 26,
		Parent = top,
	})
	refs.planetName = UI.Text({
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.fromOffset(10, 38),
		Text = "",
		TextColor3 = UI.Colors.Muted,
		MaxTextSize = 18,
		Parent = top,
	})
	refs.planetFill, refs.planetLabel = bar(top, {
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.fromOffset(10, 62),
		Color = Color3.fromRGB(255, 90, 70),
	})
	refs.wrath = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 104),
		Size = UDim2.fromOffset(440, 26),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 90, 90),
		TextStrokeTransparency = 0.3,
		MaxTextSize = 24,
		Parent = gui,
	})

	-- Left: stats.
	local stats = UI.Panel({
		Position = UDim2.new(0, 10, 0.3, 0),
		Size = UDim2.fromOffset(230, 150),
		Parent = gui,
	})
	refs.power = UI.Text({
		Size = UDim2.new(1, -20, 0, 34),
		Position = UDim2.fromOffset(10, 8),
		Text = "",
		TextColor3 = UI.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 30,
		Parent = stats,
	})
	refs.rate = UI.Text({
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.fromOffset(10, 42),
		Text = "",
		TextColor3 = UI.Colors.Good,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 18,
		Parent = stats,
	})
	refs.shards = UI.Text({
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.fromOffset(10, 68),
		Text = "",
		TextColor3 = Color3.fromRGB(140, 220, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 22,
		Parent = stats,
	})
	refs.evoName = UI.Text({
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.fromOffset(10, 96),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 20,
		Parent = stats,
	})
	refs.boost = UI.Text({
		Size = UDim2.new(1, -20, 0, 18),
		Position = UDim2.fromOffset(10, 122),
		Text = "",
		TextColor3 = UI.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 16,
		Parent = stats,
	})

	-- Bottom: evolution progress.
	local evo = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(560, 84),
		Parent = gui,
	})
	refs.evoNext = UI.Text({
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.fromOffset(10, 6),
		Text = "",
		MaxTextSize = 20,
		Parent = evo,
	})
	refs.evoFill, refs.evoLabel = bar(evo, {
		Size = UDim2.new(1, -250, 0, 22),
		Position = UDim2.fromOffset(10, 34),
		Color = UI.Colors.Purple,
		TextSize = 16,
	})
	refs.evolveBtn = UI.Button({
		Position = UDim2.new(1, -232, 0, 30),
		Size = UDim2.fromOffset(105, 44),
		Text = "EVOLVI",
	}, function()
		Remotes.Get("Evolve"):FireServer()
	end)
	refs.evolveBtn.Parent = evo
	refs.evolveNowBtn = UI.Button({
		Position = UDim2.new(1, -118, 0, 30),
		Size = UDim2.fromOffset(108, 44),
		Text = "Evolvi Subito",
		BackgroundColor3 = UI.Colors.Good,
		MaxTextSize = 18,
	}, function()
		local id = Monetization.Products.EvolveNow.id
		if id ~= 0 then
			MarketplaceService:PromptProductPurchase(player, id)
		end
	end)
	refs.evolveNowBtn.Parent = evo
	refs.ascendBtn = UI.Button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.fromOffset(200, 36),
		Text = "✨ ASCENDI",
		BackgroundColor3 = Color3.fromRGB(255, 120, 220),
		Visible = false,
	}, function()
		Remotes.Get("Ascend"):FireServer()
	end)
	refs.ascendBtn.Parent = evo
	refs.evoHint = UI.Text({
		Size = UDim2.new(1, -250, 0, 18),
		Position = UDim2.fromOffset(10, 60),
		Text = "",
		TextColor3 = UI.Colors.Muted,
		MaxTextSize = 14,
		Parent = evo,
	})

	-- Right: menu buttons.
	local menu = UI.New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(130, 200),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	UI.New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	local function menuButton(text, color, order, onClick)
		local b = UI.Button({
			Size = UDim2.new(1, 0, 0, 56),
			Text = text,
			BackgroundColor3 = color,
			LayoutOrder = order,
			MaxTextSize = 22,
		}, onClick)
		b.Parent = menu
		return b
	end
	menuButton("☄️ Meteoriti", UI.Colors.Gold, 1, function()
		controllers.Inventory:Toggle()
	end)
	menuButton("🛒 Negozio", UI.Colors.Good, 2, function()
		controllers.Shop:Toggle()
	end)
	menuButton("🤝 Scambi", UI.Colors.Blue, 3, function()
		controllers.Trade:TogglePlayerList()
	end)
end

local function update()
	-- Cycle.
	local phase = workspace:GetAttribute("CyclePhase")
	local left = math.max(0, (workspace:GetAttribute("PhaseEndsAt") or 0) - workspace:GetServerTimeNow())
	if phase == "Bombard" then
		refs.phase.Text = "🪐 BOMBARDAMENTO  " .. Format.Time(left)
		refs.phase.TextColor3 = Color3.fromRGB(150, 200, 255)
	else
		refs.phase.Text = "☄️ PIOGGIA DI METEORITI  " .. Format.Time(left)
		refs.phase.TextColor3 = Color3.fromRGB(255, 180, 90)
	end

	-- Planet.
	local hp = workspace:GetAttribute("PlanetHP") or 0
	local maxHP = math.max(1, workspace:GetAttribute("PlanetMaxHP") or 1)
	local layer = workspace:GetAttribute("PlanetLayer") or ""
	refs.planetName.Text = (workspace:GetAttribute("PlanetName") or "") .. (layer ~= "" and ("  ·  " .. layer) or "")
	refs.planetFill.Size = UDim2.fromScale(math.clamp(hp / maxHP, 0, 1), 1)
	refs.planetLabel.Text = Format.Number(hp) .. " / " .. Format.Number(maxHP)

	local wrathLeft = (workspace:GetAttribute("WrathUntil") or 0) - workspace:GetServerTimeNow()
	refs.wrath.Text = wrathLeft > 0 and ("⚡ IRA DIVINA: DANNO x3  " .. Format.Time(wrathLeft)) or ""

	-- Stats.
	local power = player:GetAttribute("Power") or 0
	local evoIndex = player:GetAttribute("Evolution") or 1
	local planets = player:GetAttribute("Planets") or 0
	refs.power.Text = "⚡ " .. Format.Number(power)
	refs.rate.Text = "+" .. Format.Number(player:GetAttribute("PowerRate") or 0) .. " Potere/s"
	refs.shards.Text = "💎 " .. Format.Number(player:GetAttribute("Shards") or 0) .. " Frammenti"
	local evo = Evolutions.Get(evoIndex)
	local asc = player:GetAttribute("Ascensions") or 0
	refs.evoName.Text = evo.name .. (asc > 0 and ("  ✨" .. asc) or "")
	refs.evoName.TextColor3 = evo.aura
	local boostLeft = (player:GetAttribute("Boost2xUntil") or 0) - os.time()
	refs.boost.Text = boostLeft > 0 and ("Boost 2x Potere: " .. Format.Time(boostLeft)) or ""

	-- Evolution progress.
	refs.ascendBtn.Visible = evoIndex >= Evolutions.AscensionMinEvolution
	if evoIndex >= Evolutions.Max() then
		refs.evoNext.Text = "Hai raggiunto la forma divina suprema!"
		refs.evoFill.Size = UDim2.fromScale(1, 1)
		refs.evoLabel.Text = "MAX"
		refs.evolveBtn.Visible = false
		refs.evolveNowBtn.Visible = false
		refs.evoHint.Text = "Ascendi per un bonus permanente"
		return
	end
	local nextEvo = Evolutions.Get(evoIndex + 1)
	local pPower = nextEvo.power > 0 and math.clamp(power / nextEvo.power, 0, 1) or 1
	local pPlanets = nextEvo.planets > 0 and math.clamp(planets / nextEvo.planets, 0, 1) or 1
	local progress = (pPower + pPlanets) / 2
	refs.evoNext.Text = "Prossima evoluzione: " .. nextEvo.name
	refs.evoFill.Size = UDim2.fromScale(progress, 1)
	refs.evoLabel.Text = math.floor(progress * 100) .. "%"
	refs.evoHint.Text = "Potere "
		.. Format.Number(power)
		.. "/"
		.. Format.Number(nextEvo.power)
		.. "  ·  Pianeti "
		.. planets
		.. "/"
		.. nextEvo.planets
	local ready = pPower >= 1 and pPlanets >= 1
	refs.evolveBtn.Visible = true
	refs.evolveBtn.BackgroundColor3 = ready and UI.Colors.Gold or Color3.fromRGB(90, 80, 110)
	refs.evolveNowBtn.Visible = Monetization.Products.EvolveNow.id ~= 0
end

function HUD:Init(c)
	controllers = c
	build()
end

function HUD:Start()
	task.spawn(function()
		while true do
			update()
			task.wait(0.2)
		end
	end)
end

return HUD
