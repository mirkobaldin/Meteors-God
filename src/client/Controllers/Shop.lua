-- Shop: Shard upgrades, Game Passes and Developer Products, plus the Starter Pack offer.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Monetization = require(Shared.Config.Monetization)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)

local Shop = {}

local player = Players.LocalPlayer
local panel
local list
local controllers
local priceCache = {}
local starterOffered = false

local PASS_ORDER = { "VIP", "Power2x", "Shards2x", "ExtraAltar" }
local PRODUCT_ORDER = {
	"StarterPack",
	"DivineWrath",
	"LegendaryPlanet",
	"Boost2x",
	"PowerS",
	"PowerM",
	"PowerL",
	"InstantRecharge",
	"EvolveNow",
}

local function price(id, infoType)
	if id == 0 then
		return nil
	end
	if priceCache[id] then
		return priceCache[id]
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(id, infoType)
	end)
	if ok and info and info.PriceInRobux then
		priceCache[id] = info.PriceInRobux
		return info.PriceInRobux
	end
	return nil
end

local function section(title, order)
	UI.Text({
		Size = UDim2.new(1, -8, 0, 30),
		Text = title,
		TextColor3 = UI.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
		MaxTextSize = 24,
		Parent = list,
	})
end

local function item(order, title, desc, buttonText, buttonColor, enabled, onClick)
	local f = UI.New("Frame", {
		Size = UDim2.new(1, -8, 0, 62),
		BackgroundColor3 = UI.Colors.PanelLight,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = list,
	})
	UI.Corner(UDim.new(0, 10)).Parent = f
	UI.Text({
		Size = UDim2.new(0.7, -16, 0, 26),
		Position = UDim2.fromOffset(12, 6),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 20,
		Parent = f,
	})
	UI.Text({
		Size = UDim2.new(0.7, -16, 0, 20),
		Position = UDim2.fromOffset(12, 34),
		Text = desc,
		TextColor3 = UI.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 15,
		Parent = f,
	})
	local b = UI.Button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0.28, 0, 0, 42),
		Text = buttonText,
		BackgroundColor3 = enabled and buttonColor or Color3.fromRGB(80, 75, 95),
		MaxTextSize = 18,
		Parent = f,
	}, function()
		if enabled then
			onClick()
		end
	end)
	return b
end

function Shop:Refresh()
	if not panel.Visible then
		return
	end
	local scroll = list.CanvasPosition
	UI.Clear(list)
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	section("⬆️ POTENZIAMENTI (Frammenti)", nextOrder())
	local shards = player:GetAttribute("Shards") or 0
	for _, u in ipairs(Game.Upgrades) do
		local level = player:GetAttribute("Upgrade_" .. u.id) or 0
		local cost = Game.UpgradeCost(u.id, level)
		local text = cost and ("💎 " .. Format.Number(cost)) or "MAX"
		item(
			nextOrder(),
			u.name .. "  (Lv " .. level .. "/" .. u.max .. ")",
			u.desc,
			text,
			UI.Colors.Blue,
			cost ~= nil and shards >= cost,
			function()
				Remotes.Get("BuyUpgrade"):FireServer(u.id)
				task.delay(0.3, function()
					Shop:Refresh()
				end)
			end
		)
	end

	section("🎟️ GAME PASS (permanenti)", nextOrder())
	for _, key in ipairs(PASS_ORDER) do
		local pass = Monetization.GamePasses[key]
		local owned = player:GetAttribute("Pass_" .. key) == true
		local p = price(pass.id, Enum.InfoType.GamePass)
		local text = owned and "Posseduto" or (pass.id == 0 and "Presto" or ("R$ " .. (p or "?")))
		item(nextOrder(), pass.name, pass.desc, text, UI.Colors.Good, not owned and pass.id ~= 0, function()
			MarketplaceService:PromptGamePassPurchase(player, pass.id)
		end)
	end

	section("🛍️ OFFERTE", nextOrder())
	for _, key in ipairs(PRODUCT_ORDER) do
		local product = Monetization.Products[key]
		local hidden = key == "StarterPack" and player:GetAttribute("StarterPackBought") == true
		if not hidden then
			local p = price(product.id, Enum.InfoType.Product)
			local text = product.id == 0 and "Presto" or ("R$ " .. (p or "?"))
			item(nextOrder(), product.name, product.desc, text, UI.Colors.Gold, product.id ~= 0, function()
				MarketplaceService:PromptProductPurchase(player, product.id)
			end)
		end
	end
	list.CanvasPosition = scroll
end

function Shop:Toggle()
	panel.Visible = not panel.Visible
	if panel.Visible then
		controllers.Inventory:Close()
		task.spawn(function()
			Shop:Refresh()
		end)
	end
end

function Shop:Close()
	panel.Visible = false
end

-- Shown once per session, at a happy moment (right after a planet explodes).
local function offerStarterPack()
	local product = Monetization.Products.StarterPack
	if starterOffered or product.id == 0 or player:GetAttribute("StarterPackBought") then
		return
	end
	starterOffered = true
	local gui = panel.Parent
	local offer = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(380, 220),
		Parent = gui,
	})
	UI.Text({
		Size = UDim2.new(1, -20, 0, 40),
		Position = UDim2.fromOffset(10, 10),
		Text = "⭐ STARTER PACK ⭐",
		TextColor3 = UI.Colors.Gold,
		MaxTextSize = 32,
		Parent = offer,
	})
	UI.Text({
		Size = UDim2.new(1, -30, 0, 70),
		Position = UDim2.fromOffset(15, 56),
		Text = product.desc,
		MaxTextSize = 20,
		Parent = offer,
	})
	local p = price(product.id, Enum.InfoType.Product)
	UI.Button({
		Position = UDim2.new(0, 20, 1, -64),
		Size = UDim2.new(0.5, -30, 0, 48),
		Text = "R$ " .. (p or "?"),
		Parent = offer,
	}, function()
		MarketplaceService:PromptProductPurchase(player, product.id)
		offer:Destroy()
	end)
	UI.Button({
		Position = UDim2.new(0.5, 10, 1, -64),
		Size = UDim2.new(0.5, -30, 0, 48),
		Text = "Più tardi",
		BackgroundColor3 = UI.Colors.PanelLight,
		TextColor3 = UI.Colors.Text,
		Parent = offer,
	}, function()
		offer:Destroy()
	end)
end

function Shop:Init(c)
	controllers = c
	local gui = UI.Screen("Shop", 10)
	panel = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.55, 0, 0.66, 0),
		Visible = false,
		Parent = gui,
	})
	UI.New("UISizeConstraint", { MaxSize = Vector2.new(720, 600), MinSize = Vector2.new(400, 320), Parent = panel })
	UI.Text({
		Size = UDim2.new(1, -60, 0, 34),
		Position = UDim2.fromOffset(14, 8),
		Text = "🛒 NEGOZIO DIVINO",
		TextColor3 = UI.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 30,
		Parent = panel,
	})
	UI.Button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.fromOffset(36, 36),
		Text = "X",
		BackgroundColor3 = UI.Colors.Bad,
		Parent = panel,
	}, function()
		panel.Visible = false
	end)
	list = UI.List({
		Size = UDim2.new(1, -20, 1, -56),
		Position = UDim2.fromOffset(10, 48),
		Parent = panel,
	})
end

function Shop:Start()
	Remotes.Get("PlanetDestroyed").OnClientEvent:Connect(function()
		task.delay(3, offerStarterPack)
	end)
	player:GetAttributeChangedSignal("Shards"):Connect(function()
		-- Cheap: only rebuild when open.
		if panel.Visible then
			Shop:Refresh()
		end
	end)
end

return Shop
