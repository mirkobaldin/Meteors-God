-- Daily rewards calendar (7 days, big reward on day 7).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Rewards = require(Shared.Config.Rewards)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)

local Daily = {}

local player = Players.LocalPlayer
local window
local cells = {}

local function buildCell(parent, day, reward, big)
	local c = UI.New("Frame", {
		BackgroundColor3 = day % 2 == 0 and Color3.fromRGB(110, 70, 170) or Color3.fromRGB(70, 140, 190),
		BorderSizePixel = 0,
		LayoutOrder = day,
		Parent = parent,
	})
	UI.Corner().Parent = c
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = c
	UI.New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 170, 220)),
		Rotation = 90,
		Parent = c,
	})
	UI.Text({
		Size = UDim2.new(1, -10, big and 0.1 or 0.2, 0),
		Position = UDim2.new(0, 5, 0.02, 0),
		Text = "Giorno " .. day,
		TextStrokeTransparency = 0,
		MaxTextSize = 30,
		Parent = c,
	})
	UI.Text({
		Size = UDim2.new(1, 0, big and 0.42 or 0.34, 0),
		Position = UDim2.new(0, 0, big and 0.16 or 0.2, 0),
		Text = reward.emoji or "🎁",
		MaxTextSize = big and 120 or 56,
		Parent = c,
	})
	UI.Text({
		Size = UDim2.new(1, -10, big and 0.12 or 0.14, 0),
		Position = UDim2.new(0, 5, big and 0.6 or 0.54, 0),
		Text = reward.label,
		TextStrokeTransparency = 0,
		MaxTextSize = big and 34 or 22,
		Parent = c,
	})
	UI.Text({
		Size = UDim2.new(1, -10, 0.1, 0),
		Position = UDim2.new(0, 5, big and 0.72 or 0.67, 0),
		Text = reward.sub or "",
		TextColor3 = Color3.fromRGB(255, 240, 180),
		TextStrokeTransparency = 0,
		TextWrapped = true,
		MaxTextSize = 16,
		Parent = c,
	})
	local button = UI.Button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, -12, big and 0.1 or 0.17, 0),
		Text = "Non pronto",
		BackgroundColor3 = Color3.fromRGB(35, 35, 55),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		MaxTextSize = 22,
		Parent = c,
	}, function()
		Remotes.Get("ClaimDaily"):FireServer()
	end)
	cells[day] = { frame = c, button = button }
	return c
end

function Daily:Refresh()
	if not window.Visible then
		return
	end
	local streak = player:GetAttribute("DailyStreak") or 0
	local available = player:GetAttribute("DailyAvailable") == true
	local n = #Rewards.Daily
	local pos = streak % n -- rewards already claimed in this cycle
	if pos == 0 and streak > 0 and not available then
		pos = n -- cycle just completed today
	end
	for day, cell in pairs(cells) do
		local b = cell.button
		if day <= pos then
			b.Text = "Riscattato ✓"
			b.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		elseif day == pos + 1 and available then
			b.Text = "Riscatta!"
			b.BackgroundColor3 = UI.Colors.Good
		elseif day == pos + 1 then
			b.Text = "Domani"
			b.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		else
			b.Text = "Non pronto"
			b.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		end
	end
end

function Daily:Init()
	local gui = UI.Screen("Daily", 10)
	local content
	window, content = UI.Window(gui, {
		Title = "Premi giornalieri",
		Emoji = "📅",
		Icon = Assets.Icons.Daily,
		Size = UDim2.new(0.72, 0, 0.74, 0),
		MaxSize = Vector2.new(1000, 640),
	})
	local left = UI.New("Frame", { Size = UDim2.new(0.74, 0, 1, 0), BackgroundTransparency = 1, Parent = content })
	UI.New("UIGridLayout", {
		CellSize = UDim2.new(0.333, -8, 0.5, -8),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = left,
	})
	local n = #Rewards.Daily
	for day = 1, n - 1 do
		buildCell(left, day, Rewards.Daily[day], false)
	end
	local big = buildCell(content, n, Rewards.Daily[n], true)
	big.Position = UDim2.new(0.76, 0, 0, 0)
	big.Size = UDim2.new(0.24, 0, 1, -4)
	UI.Text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 4),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "Se salti un giorno non perdi i progressi: riprendi da dove eri.",
		TextColor3 = UI.Colors.Muted,
		MaxTextSize = 16,
		Parent = window,
	})
	Panels.Register("Daily", window, function()
		Daily:Refresh()
	end)
end

function Daily:Start()
	player:GetAttributeChangedSignal("DailyStreak"):Connect(function()
		Daily:Refresh()
	end)
	player:GetAttributeChangedSignal("DailyAvailable"):Connect(function()
		Daily:Refresh()
	end)
	-- Open the calendar automatically when a reward is waiting.
	task.spawn(function()
		local start = os.clock()
		while player:GetAttribute("DailyAvailable") == nil and os.clock() - start < 30 do
			task.wait(0.5)
		end
		task.wait(2)
		if player:GetAttribute("DailyAvailable") == true then
			Panels.Open("Daily")
		end
	end)
end

return Daily
