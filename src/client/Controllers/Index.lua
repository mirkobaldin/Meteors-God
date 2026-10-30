-- Collection index: every meteor type, discovered ones in color, the rest as "???".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Meteors = require(Shared.Config.Meteors)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)
local State = require(script.Parent.State)

local Index = {}

local window
local grid
local header
local familiesText

function Index:Refresh()
	if not window.Visible then
		return
	end
	local snap = State.Snapshot
	local found = snap and snap.index or {}
	UI.Clear(grid)
	local count, total = 0, 0
	for i, def in ipairs(Meteors.Types) do
		local discovered = found[def.id] == true
		if not def.exclusive or discovered then
			if not def.exclusive then
				total += 1
				if discovered then
					count += 1
				end
			end
			local rarity = Meteors.RarityByID[def.rarity]
			local c = UI.New("Frame", {
				BackgroundColor3 = Color3.fromRGB(40, 35, 75),
				BorderSizePixel = 0,
				LayoutOrder = rarity.order * 100 + i,
				Parent = grid,
			})
			-- Rarity card art (UI art card_<rarity>): the frame goes over the content, inside its opening.
			local cardArt = UI.Art("card_" .. string.lower(rarity.id))
			if cardArt then
				c.BackgroundTransparency = 1
				local inner = UI.New("Frame", {
					Position = UDim2.fromScale(0.08, 0.07),
					Size = UDim2.fromScale(0.84, 0.86),
					BackgroundColor3 = Color3.fromRGB(24, 30, 48),
					BorderSizePixel = 0,
					Parent = c,
				})
				UI.Corner(UDim.new(0, 8)).Parent = inner
				UI.New("ImageLabel", {
					BackgroundTransparency = 1,
					Image = cardArt,
					ImageTransparency = discovered and 0 or 0.45,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 4,
					Parent = c,
				})
			else
				UI.Corner().Parent = c
				UI.Stroke(rarity.color, 3, discovered and 0 or 0.6).Parent = c
			end
			local orb = UI.New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0.13, 0),
				Size = UDim2.fromScale(0.48, 0.48),
				BackgroundColor3 = discovered and def.body or Color3.fromRGB(20, 18, 30),
				BorderSizePixel = 0,
				Parent = c,
			})
			UI.New("UIAspectRatioConstraint", { Parent = orb })
			UI.Corner(UDim.new(1, 0)).Parent = orb
			UI.Stroke(discovered and def.fire[1] or Color3.fromRGB(60, 55, 80), 4, 0).Parent = orb
			if not discovered then
				UI.Text({ Size = UDim2.fromScale(1, 1), Text = "?", TextColor3 = UI.Colors.Muted, MaxTextSize = 40, Parent = orb })
			end
			UI.Text({
				Size = UDim2.new(0.8, 0, 0.13, 0),
				Position = UDim2.new(0.1, 0, 0.62, 0),
				Text = discovered and def.id or "???",
				TextStrokeTransparency = 0,
				MaxTextSize = 20,
				Parent = c,
			})
			UI.Text({
				Size = UDim2.new(0.8, 0, 0.1, 0),
				Position = UDim2.new(0.1, 0, 0.76, 0),
				Text = def.rarity,
				TextColor3 = rarity.color,
				MaxTextSize = 16,
				Parent = c,
			})
			-- Completed rarity: click a meteor to make it that rarity's weapon (⚔ = current pick).
			if discovered and not def.exclusive and Meteors.Weapons[def.rarity] and Meteors.SetComplete(def.rarity, found) then
				local picks = snap and snap.weaponPicks or {}
				local isPick = picks[def.rarity] == def.id
				if isPick then
					UI.Text({
						Size = UDim2.fromOffset(30, 30),
						Position = UDim2.fromOffset(14, 14),
						Text = "⚔",
						ZIndex = 5,
						MaxTextSize = 28,
						Parent = c,
					})
				end
				local button = UI.New("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 5,
					Parent = c,
				})
				button.Activated:Connect(function()
					Remotes.Get("PickWeapon"):FireServer(def.rarity, def.id)
				end)
			end
		end
	end
	header.Text = "Discovered " .. count .. " / " .. total
	-- Rarity sets: find all the meteors of a rarity to forge its weapon, then click one to use it.
	local parts = {}
	for _, rarity in ipairs(Meteors.Rarities) do
		local members = Meteors.SetMembers(rarity.id)
		local n = 0
		for _, id in ipairs(members) do
			if found[id] then
				n += 1
			end
		end
		table.insert(parts, (n == #members and "⚔ " or "") .. rarity.id .. " " .. n .. "/" .. #members)
	end
	familiesText.Text = "Weapons: find a whole rarity, then click one of its meteors  ·  " .. table.concat(parts, "  ·  ")
end

function Index:Init()
	local gui = UI.Screen("Index", 10)
	local content
	window, content = UI.Window(gui, {
		Title = "Index",
		Emoji = "📖",
		Icon = Assets.Icons.Index,
		HeaderColor = Color3.fromRGB(150, 90, 60),
	})
	header = UI.Text({
		Size = UDim2.new(1, 0, 0, 28),
		Text = "",
		TextColor3 = UI.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 24,
		Parent = content,
	})
	familiesText = UI.Text({
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 18,
		Parent = content,
	})
	grid = UI.New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 1, -60),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = content,
	})
	UI.New("UIGridLayout", {
		CellSize = UDim2.fromOffset(130, 160),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	Panels.Register("Index", window, function()
		Index:Refresh()
	end)
end

function Index:Start()
	State.Changed:Connect(function()
		Index:Refresh()
	end)
end

return Index
