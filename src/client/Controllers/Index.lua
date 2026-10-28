-- Collection index: every meteor type, discovered ones in color, the rest as "???".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Meteors = require(Shared.Config.Meteors)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)
local State = require(script.Parent.State)

local Index = {}

local window
local grid
local header

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
			UI.Corner().Parent = c
			UI.Stroke(rarity.color, 3, discovered and 0 or 0.6).Parent = c
			local orb = UI.New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0.08, 0),
				Size = UDim2.fromScale(0.55, 0.55),
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
				Size = UDim2.new(1, -8, 0.16, 0),
				Position = UDim2.new(0, 4, 0.66, 0),
				Text = discovered and def.id or "???",
				TextStrokeTransparency = 0,
				MaxTextSize = 20,
				Parent = c,
			})
			UI.Text({
				Size = UDim2.new(1, -8, 0.13, 0),
				Position = UDim2.new(0, 4, 0.83, 0),
				Text = def.rarity,
				TextColor3 = rarity.color,
				MaxTextSize = 16,
				Parent = c,
			})
		end
	end
	header.Text = "Scoperti " .. count .. " / " .. total
end

function Index:Init()
	local gui = UI.Screen("Index", 10)
	local content
	window, content = UI.Window(gui, {
		Title = "Indice",
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
	grid = UI.New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 1, -34),
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
