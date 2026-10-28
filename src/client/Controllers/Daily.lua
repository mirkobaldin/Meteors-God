-- Daily rewards as a "constellation path": 7 stars joined by a line, day 7 is the big one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Rewards = require(Shared.Config.Rewards)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)

local Daily = {}

local player = Players.LocalPlayer
local window
local nodes = {}
local claimButton
local detail

local function state()
	local streak = player:GetAttribute("DailyStreak") or 0
	local available = player:GetAttribute("DailyAvailable") == true
	local n = #Rewards.Daily
	local pos = streak % n
	if pos == 0 and streak > 0 and not available then
		pos = n
	end
	return pos, available
end

function Daily:Refresh()
	if not window.Visible then
		return
	end
	local pos, available = state()
	for day, node in ipairs(nodes) do
		local claimed = day <= pos
		local current = day == pos + 1
		node.star.BackgroundColor3 = claimed and UI.Colors.Gold
			or current and (available and UI.Colors.Cyan or UI.Colors.PanelLight)
			or Color3.fromRGB(25, 28, 55)
		node.stroke.Color = current and available and UI.Colors.Cyan or UI.Colors.Gold
		node.stroke.Transparency = (claimed or current) and 0 or 0.6
		node.check.Visible = claimed
		node.emoji.TextTransparency = claimed and 0.5 or 0
		if node.line then
			node.line.BackgroundColor3 = day <= pos + 1 and UI.Colors.Gold or Color3.fromRGB(60, 60, 90)
		end
	end
	local nextDay = math.min(pos + 1, #Rewards.Daily)
	local reward = Rewards.Daily[nextDay]
	if available then
		detail.Text = "Today: Day " .. nextDay .. "  ·  " .. reward.label .. " " .. (reward.sub or "")
		claimButton.Text = "CLAIM"
		claimButton.BackgroundColor3 = UI.Colors.Gold
	else
		detail.Text = "Come back tomorrow for Day " .. (pos % #Rewards.Daily + 1)
		claimButton.Text = "ALREADY CLAIMED"
		claimButton.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
	end
end

function Daily:Init()
	local gui = UI.Screen("Daily", 10)
	local content
	window, content = UI.Window(gui, {
		Title = "Daily rewards",
		Emoji = "📅",
		Icon = Assets.Icons.Daily,
		HeaderColor = Color3.fromRGB(60, 120, 200),
		Size = UDim2.new(0.7, 0, 0.56, 0),
		MaxSize = Vector2.new(980, 460),
		MinSize = Vector2.new(560, 340),
	})
	local n = #Rewards.Daily
	local path = UI.New("Frame", { Size = UDim2.new(1, 0, 0.62, 0), BackgroundTransparency = 1, Parent = content })
	for day = 1, n do
		local reward = Rewards.Daily[day]
		local big = day == n
		local x = (day - 0.5) / n
		local y = (day % 2 == 0) and 0.36 or 0.5
		if big then
			y = 0.42
		end
		local size = big and 104 or 74
		if day > 1 then
			local prev = nodes[day - 1]
			local p1 = Vector2.new(prev.x, prev.y)
			local p2 = Vector2.new(x, y)
			local line = UI.New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale((p1.X + p2.X) / 2, (p1.Y + p2.Y) / 2),
				Size = UDim2.new((p2 - p1).Magnitude * 1.02, 0, 0, 3),
				Rotation = math.deg(math.atan2((p2.Y - p1.Y) * 0.35, p2.X - p1.X)),
				BorderSizePixel = 0,
				ZIndex = 1,
				Parent = path,
			})
			prev.line = line
		end
		local star = UI.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromOffset(size, size),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = path,
		})
		UI.Corner(UDim.new(1, 0)).Parent = star
		local stroke = UI.Stroke(UI.Colors.Gold, big and 3 or 2, 0.3)
		stroke.Parent = star
		local emoji = UI.Text({
			Size = UDim2.fromScale(0.7, 0.7),
			Position = UDim2.fromScale(0.15, 0.15),
			Text = reward.emoji or "⭐",
			ZIndex = 3,
			MaxTextSize = big and 56 or 36,
			Parent = star,
		})
		local check = UI.Text({
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1.05, 1.05),
			Size = UDim2.fromOffset(26, 26),
			Text = "✓",
			Font = UI.TitleFont,
			TextColor3 = UI.Colors.Good,
			TextStrokeTransparency = 0,
			ZIndex = 4,
			Visible = false,
			MaxTextSize = 24,
			Parent = star,
		})
		UI.Text({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(x, 0, y, size / 2 + 6),
			Size = UDim2.fromOffset(120, 16),
			Text = "DAY " .. day,
			Font = UI.TitleFont,
			TextColor3 = big and UI.Colors.Gold or UI.Colors.Muted,
			MaxTextSize = 13,
			Parent = path,
		})
		UI.Text({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(x, 0, y, size / 2 + 22),
			Size = UDim2.fromOffset(130, 16),
			Text = reward.label,
			MaxTextSize = 13,
			Parent = path,
		})
		nodes[day] = { star = star, stroke = stroke, emoji = emoji, check = check, x = x, y = y }
	end
	detail = UI.Text({
		Position = UDim2.new(0, 0, 0.7, 0),
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		MaxTextSize = 20,
		Parent = content,
	})
	claimButton = UI.Button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.8, 0),
		Size = UDim2.fromOffset(260, 46),
		Text = "CLAIM",
		MaxTextSize = 22,
		Parent = content,
	}, function()
		Remotes.Get("ClaimDaily"):FireServer()
	end)
	UI.Text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "Missing a day doesn't reset your constellation: you continue where you left off.",
		TextColor3 = UI.Colors.Muted,
		MaxTextSize = 14,
		Parent = content,
	})
	Panels.Register("Daily", window, function()
		Daily:Refresh()
		local scale = window:FindFirstChildOfClass("UIScale") or UI.New("UIScale", { Parent = window })
		scale.Scale = 0.9
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
end

function Daily:Start()
	player:GetAttributeChangedSignal("DailyStreak"):Connect(function()
		Daily:Refresh()
	end)
	player:GetAttributeChangedSignal("DailyAvailable"):Connect(function()
		Daily:Refresh()
	end)
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
