-- Robux shop window: tabs for permanent Game Passes and repeatable Offers.
-- Also shows the Starter Pack offer once per session right after a planet explodes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Monetization = require(Shared.Config.Monetization)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)
local Prices = require(script.Parent.Prices)

local Shop = {}

local player = Players.LocalPlayer
local gui
local window
local grid
local tabButtons = {}
local currentTab = "Offers"
local starterOffered = false

local PASS_ORDER = {
	{ key = "VIP", emoji = "👑" },
	{ key = "Power2x", emoji = "⚡" },
	{ key = "Shards2x", emoji = "💎" },
	{ key = "ExtraAltar", emoji = "🏛️" },
}
local PRODUCT_ORDER = {
	{ key = "StarterPack", emoji = "🎁" },
	{ key = "DivineWrath", emoji = "🔥" },
	{ key = "LegendaryPlanet", emoji = "⭐" },
	{ key = "Boost2x", emoji = "🧪" },
	{ key = "PowerS", emoji = "⚡" },
	{ key = "PowerM", emoji = "⚡" },
	{ key = "PowerL", emoji = "⚡" },
	{ key = "InstantRecharge", emoji = "⏱️" },
	{ key = "EvolveNow", emoji = "🌟" },
}

local function card(order, emoji, title, desc, priceText, enabled, onClick)
	local c = UI.New("Frame", {
		BackgroundColor3 = Color3.fromRGB(55, 50, 110),
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = grid,
	})
	UI.Corner().Parent = c
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = c
	UI.New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 160, 210)),
		Rotation = 90,
		Parent = c,
	})
	UI.Text({ Size = UDim2.new(1, 0, 0.36, 0), Position = UDim2.fromScale(0, 0.03), Text = emoji, MaxTextSize = 56, Parent = c })
	UI.Text({
		Size = UDim2.new(1, -12, 0.16, 0),
		Position = UDim2.new(0, 6, 0.38, 0),
		Text = title,
		TextStrokeTransparency = 0,
		MaxTextSize = 24,
		Parent = c,
	})
	UI.Text({
		Size = UDim2.new(1, -12, 0.2, 0),
		Position = UDim2.new(0, 6, 0.54, 0),
		Text = desc,
		TextColor3 = Color3.fromRGB(230, 225, 255),
		TextWrapped = true,
		MaxTextSize = 15,
		Parent = c,
	})
	UI.Button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -16, 0.18, 0),
		Text = priceText,
		BackgroundColor3 = enabled and UI.Colors.Good or Color3.fromRGB(90, 80, 110),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		MaxTextSize = 24,
		Parent = c,
	}, function()
		if enabled then
			onClick()
		end
	end)
end

function Shop:Refresh()
	if not window.Visible then
		return
	end
	UI.Clear(grid)
	for name, b in pairs(tabButtons) do
		b.BackgroundColor3 = name == currentTab and UI.Colors.Gold or UI.Colors.PanelLight
		b.TextColor3 = name == currentTab and Color3.fromRGB(40, 25, 10) or Color3.fromRGB(255, 255, 255)
	end
	if currentTab == "Passes" then
		for i, entry in ipairs(PASS_ORDER) do
			local pass = Monetization.GamePasses[entry.key]
			local owned = player:GetAttribute("Pass_" .. entry.key) == true
			card(i, entry.emoji, pass.name, pass.desc, Prices.PassText(entry.key), pass.id ~= 0 and not owned, function()
				Prices.BuyPass(entry.key)
			end)
		end
	else
		local order = 0
		for _, entry in ipairs(PRODUCT_ORDER) do
			local product = Monetization.Products[entry.key]
			local hidden = entry.key == "StarterPack" and player:GetAttribute("StarterPackBought") == true
			if not hidden then
				order += 1
				card(order, entry.emoji, product.name, product.desc, Prices.ProductText(entry.key), product.id ~= 0, function()
					Prices.BuyProduct(entry.key)
				end)
			end
		end
	end
end

local function offerStarterPack()
	local product = Monetization.Products.StarterPack
	if starterOffered or product.id == 0 or player:GetAttribute("StarterPackBought") then
		return
	end
	starterOffered = true
	local offer = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 240),
		ZIndex = 20,
		Parent = gui,
	})
	UI.Text({
		Size = UDim2.new(1, -20, 0, 44),
		Position = UDim2.fromOffset(10, 10),
		Text = "⭐ PACCHETTO INIZIALE ⭐",
		TextColor3 = UI.Colors.Gold,
		TextStrokeTransparency = 0,
		MaxTextSize = 32,
		Parent = offer,
	})
	UI.Text({
		Size = UDim2.new(1, -30, 0, 80),
		Position = UDim2.fromOffset(15, 60),
		Text = product.desc,
		TextWrapped = true,
		MaxTextSize = 22,
		Parent = offer,
	})
	UI.Button({
		Position = UDim2.new(0, 20, 1, -66),
		Size = UDim2.new(0.5, -30, 0, 50),
		Text = Prices.ProductText("StarterPack"),
		BackgroundColor3 = UI.Colors.Good,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Parent = offer,
	}, function()
		Prices.BuyProduct("StarterPack")
		offer:Destroy()
	end)
	UI.Button({
		Position = UDim2.new(0.5, 10, 1, -66),
		Size = UDim2.new(0.5, -30, 0, 50),
		Text = "Later",
		BackgroundColor3 = UI.Colors.PanelLight,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Parent = offer,
	}, function()
		offer:Destroy()
	end)
end

function Shop:Init()
	gui = UI.Screen("Shop", 10)
	local content
	window, content = UI.Window(gui, {
		Title = "Shop",
		Emoji = "🛒",
		Icon = Assets.Icons.Shop,
		HeaderColor = Color3.fromRGB(60, 140, 80),
	})
	local tabs = UI.New("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = content })
	UI.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabs,
	})
	for i, tab in ipairs({ { "Offers", "🛍️ Offers" }, { "Passes", "🎟️ Game Pass" } }) do
		tabButtons[tab[1]] = UI.Button({
			Size = UDim2.fromOffset(180, 40),
			Text = tab[2],
			LayoutOrder = i,
			Parent = tabs,
		}, function()
			currentTab = tab[1]
			Shop:Refresh()
		end)
	end
	local scroll = UI.New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 1, -52),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = content,
	})
	grid = scroll
	UI.New("UIGridLayout", {
		CellSize = UDim2.new(0.32, -6, 0, 230),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})
	Panels.Register("Shop", window, function()
		Shop:Refresh()
	end)
end

function Shop:Start()
	Remotes.Get("PlanetDestroyed").OnClientEvent:Connect(function()
		task.delay(3, offerStarterPack)
	end)
	-- The stall on the Shop island.
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
		if prompt.Name == "OpenShop" then
			Panels.Open("Shop")
		end
	end)
end

return Shop
