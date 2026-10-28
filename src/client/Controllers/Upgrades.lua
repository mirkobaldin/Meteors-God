-- Upgrades window (paid with Stellar Shards, never Robux).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Game = require(Shared.Config.Game)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)

local Upgrades = {}

local player = Players.LocalPlayer
local window
local rows = {}

local EMOJI = { speed = "👟", power = "💥", crit = "🎯", recharge = "⏱️", luck = "🍀", greed = "💎", altar = "🔆", storage = "📦" }

local function buildRow(parent, u, order)
	local f = UI.New("Frame", {
		Size = UDim2.new(1, -8, 0, 84),
		BackgroundColor3 = Color3.fromRGB(50, 50, 100),
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = parent,
	})
	UI.Corner().Parent = f
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = f
	UI.Text({ Size = UDim2.fromOffset(70, 70), Position = UDim2.fromOffset(8, 7), Text = EMOJI[u.id] or "⬆️", MaxTextSize = 48, Parent = f })
	local title = UI.Text({
		Size = UDim2.new(0.6, -90, 0, 34),
		Position = UDim2.fromOffset(86, 8),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 0,
		Parent = f,
	})
	local effect = UI.Text({
		Size = UDim2.new(0.6, -90, 0, 24),
		Position = UDim2.fromOffset(86, 46),
		Text = u.desc,
		TextColor3 = UI.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = f,
	})
	local buy = UI.Button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -86, 0.5, 0),
		Size = UDim2.new(0.24, 0, 0, 56),
		Text = "",
		Parent = f,
	}, function()
		Remotes.Get("BuyUpgrade"):FireServer(u.id, 1)
	end)
	local max = UI.Button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(70, 56),
		Text = "MAX",
		BackgroundColor3 = UI.Colors.Blue,
		Parent = f,
	}, function()
		Remotes.Get("BuyUpgrade"):FireServer(u.id, 100)
	end)
	rows[u.id] = { title = title, effect = effect, buy = buy, max = max }
end

function Upgrades:Refresh()
	if not window.Visible then
		return
	end
	local shards = player:GetAttribute("Shards") or 0
	for _, u in ipairs(Game.Upgrades) do
		local r = rows[u.id]
		local level = player:GetAttribute("Upgrade_" .. u.id) or 0
		local cost = Game.UpgradeCost(u.id, level)
		r.title.Text = u.name .. "  Lv " .. level .. (u.max and ("/" .. u.max) or "")
		if cost then
			r.effect.Text = u.fmt(u.effect(level)) .. "  ➜  " .. u.fmt(u.effect(level + 1))
			r.buy.Text = "💎 " .. Format.Number(cost)
			r.buy.BackgroundColor3 = shards >= cost and UI.Colors.Gold or Color3.fromRGB(90, 80, 110)
			r.max.Visible = true
		else
			r.effect.Text = u.fmt(u.effect(level))
			r.buy.Text = "MAXED"
			r.buy.BackgroundColor3 = UI.Colors.Good
			r.max.Visible = false
		end
	end
end

function Upgrades:Init()
	local gui = UI.Screen("Upgrades", 10)
	local content
	window, content = UI.Window(gui, {
		Title = "Upgrades",
		Emoji = "⬆️",
		Icon = Assets.Icons.Upgrades,
		HeaderColor = Color3.fromRGB(60, 100, 160),
	})
	local list = UI.List({ Size = UDim2.fromScale(1, 1), Parent = content }, 8)
	for i, u in ipairs(Game.Upgrades) do
		buildRow(list, u, i)
	end
	Panels.Register("Upgrades", window, function()
		Upgrades:Refresh()
	end)
end

function Upgrades:Start()
	task.spawn(function()
		while true do
			task.wait(0.4)
			Upgrades:Refresh()
		end
	end)
end

return Upgrades
