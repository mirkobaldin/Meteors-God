-- Meteor collection panel: altar management, growth, cooldowns, selling and collection index.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Meteors = require(Shared.Config.Meteors)
local MeteorMath = require(Shared.Util.MeteorMath)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)
local State = require(script.Parent.State)

local Inventory = {}

local panel
local header
local list

local function sortedMeteors(snapshot)
	local arr = {}
	for uid, m in pairs(snapshot.meteors) do
		table.insert(arr, { uid = uid, m = m })
	end
	table.sort(arr, function(a, b)
		if (a.m.altar ~= nil) ~= (b.m.altar ~= nil) then
			return a.m.altar ~= nil
		end
		local ra = Meteors.RarityByID[Meteors.ByID[a.m.t] and Meteors.ByID[a.m.t].rarity or "Comune"]
		local rb = Meteors.RarityByID[Meteors.ByID[b.m.t] and Meteors.ByID[b.m.t].rarity or "Comune"]
		if ra.order ~= rb.order then
			return ra.order > rb.order
		end
		return a.uid < b.uid
	end)
	return arr
end

local function row(entry, now)
	local m = entry.m
	local def = Meteors.ByID[m.t]
	if not def then
		return
	end
	local rarity = Meteors.RarityByID[def.rarity]
	local growth = MeteorMath.Growth(m, now)
	local cd = State.CooldownLeft(entry.uid)

	local item = UI.New("Frame", {
		Size = UDim2.new(1, -8, 0, 58),
		BackgroundColor3 = UI.Colors.PanelLight,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = list,
	})
	UI.Corner(UDim.new(0, 10)).Parent = item
	UI.Stroke(rarity.color, 2, 0.3).Parent = item

	local swatch = UI.New("Frame", {
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.fromOffset(8, 8),
		BackgroundColor3 = def.body,
		BorderSizePixel = 0,
		Parent = item,
	})
	UI.Corner(UDim.new(1, 0)).Parent = swatch
	UI.Stroke(def.fire[1], 3, 0).Parent = swatch

	UI.Text({
		Size = UDim2.new(0.45, -60, 0, 26),
		Position = UDim2.fromOffset(58, 4),
		Text = (m.m and (m.m .. " ") or "") .. def.id,
		TextColor3 = m.m and Meteors.MutationByID[m.m].color or UI.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 20,
		Parent = item,
	})
	local status
	if cd > 0 then
		status = "😵 Ricarica " .. math.ceil(cd) .. "s"
	elseif m.altar then
		status = "Sull'altare"
	else
		status = "Deposito"
	end
	UI.Text({
		Size = UDim2.new(0.45, -60, 0, 20),
		Position = UDim2.fromOffset(58, 32),
		Text = def.rarity
			.. "  ·  Crescita "
			.. math.floor(growth * 100)
			.. "%  ·  "
			.. status
			.. (m.paid and "  ·  Esclusivo" or ""),
		TextColor3 = rarity.color,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 14,
		Parent = item,
	})
	UI.Text({
		Size = UDim2.new(0.2, 0, 0, 20),
		Position = UDim2.new(0.45, 0, 0, 18),
		Text = "💥 " .. Format.Number(MeteorMath.MeteorDamage(m, now)),
		TextColor3 = Color3.fromRGB(255, 160, 100),
		MaxTextSize = 18,
		Parent = item,
	})

	if m.altar then
		UI.Button({
			Size = UDim2.new(0.16, 0, 0, 38),
			Position = UDim2.new(0.66, 0, 0, 10),
			Text = "Togli",
			BackgroundColor3 = UI.Colors.Blue,
			Parent = item,
		}, function()
			Remotes.Get("RemoveFromAltar"):FireServer(entry.uid)
		end)
	else
		UI.Button({
			Size = UDim2.new(0.16, 0, 0, 38),
			Position = UDim2.new(0.66, 0, 0, 10),
			Text = "Altare",
			Parent = item,
		}, function()
			Remotes.Get("PlaceOnAltar"):FireServer(entry.uid)
		end)
		if not m.paid then
			local price = math.floor(def.sellPrice * Meteors.GetMutationMult(m.m))
			UI.Button({
				Size = UDim2.new(0.16, 0, 0, 38),
				Position = UDim2.new(0.83, 0, 0, 10),
				Text = "Vendi " .. Format.Number(price),
				BackgroundColor3 = UI.Colors.Bad,
				MaxTextSize = 16,
				Parent = item,
			}, function()
				Remotes.Get("SellMeteor"):FireServer(entry.uid)
			end)
		end
	end
end

function Inventory:Refresh()
	local snap = State.Snapshot
	if not panel.Visible or not snap then
		return
	end
	local now = State.Now()
	local total, onAltar = 0, 0
	for _, m in pairs(snap.meteors) do
		total += 1
		if m.altar then
			onAltar += 1
		end
	end
	local indexed = 0
	for _ in pairs(snap.index) do
		indexed += 1
	end
	header.Text = string.format(
		"Meteoriti %d/%d   ·   Altare %d/%d   ·   Indice %d/%d",
		total,
		snap.inventoryCap,
		onAltar,
		snap.altarSlots,
		math.min(indexed, snap.indexSize),
		snap.indexSize
	)
	local scroll = list.CanvasPosition
	UI.Clear(list)
	for _, entry in ipairs(sortedMeteors(snap)) do
		row(entry, now)
	end
	list.CanvasPosition = scroll
end

function Inventory:Init()
	local gui = UI.Screen("Inventory", 10)
	local content
	panel, content = UI.Window(gui, {
		Title = "I tuoi Meteoriti",
		Emoji = "☄️",
		Icon = Assets.Icons.Meteors,
		HeaderColor = Color3.fromRGB(150, 80, 50),
	})
	header = UI.Text({
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		TextColor3 = UI.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 20,
		Parent = content,
	})
	list = UI.List({
		Size = UDim2.new(1, 0, 1, -30),
		Position = UDim2.fromOffset(0, 30),
		Parent = content,
	})
	Panels.Register("Inventory", panel, function()
		Inventory:Refresh()
	end)
end

function Inventory:Start()
	State.Changed:Connect(function()
		Inventory:Refresh()
	end)
	task.spawn(function()
		while true do
			task.wait(2)
			Inventory:Refresh()
		end
	end)
end

return Inventory
