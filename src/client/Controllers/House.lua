-- House window: opened from the lectern in front of your house. Shows the 6 house levels, their
-- bonus (+Shards and +Power per second), what the next one needs, and buys it.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Evolutions = require(Shared.Config.Evolutions)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)

local House = {}

local player = Players.LocalPlayer
local window, list, controllers

local function pct(v)
	return math.floor(v * 100 + 0.5) .. "%"
end

function House:Refresh()
	if not window.Visible then
		return
	end
	UI.Clear(list)
	local level = player:GetAttribute("HouseLevel") or 1
	local shards = player:GetAttribute("Shards") or 0
	local evolution = player:GetAttribute("Evolution") or 1
	for i, def in ipairs(Game.House.Levels) do
		local owned = i <= level
		local isNext = i == level + 1
		local row = UI.New("Frame", {
			Size = UDim2.new(1, -8, 0, 70),
			BackgroundColor3 = UI.Colors.PanelLight,
			BackgroundTransparency = owned and 0.05 or 0.35,
			BorderSizePixel = 0,
			LayoutOrder = i,
			Parent = list,
		})
		UI.Corner(UDim.new(0, 10)).Parent = row
		UI.Stroke(i == level and UI.Colors.Gold or UI.Colors.Purple, i == level and 3 or 1.5, 0.2).Parent = row
		UI.Text({
			Size = UDim2.new(0.6, -12, 0, 32),
			Position = UDim2.fromOffset(12, 6),
			Text = string.format("%d. %s%s", i, def.name, i == level and "  (your house)" or ""),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = owned and UI.Colors.Gold or UI.Colors.Text,
			MaxTextSize = 22,
			Parent = row,
		})
		UI.Text({
			Size = UDim2.new(0.6, -12, 0, 24),
			Position = UDim2.fromOffset(12, 38),
			Text = def.bonus > 0 and string.format("+%s Shards · +%s Power/s", pct(def.bonus), pct(def.bonus)) or "Your first home among the stars",
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 17,
			Parent = row,
		})
		if owned then
			UI.Text({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.fromOffset(140, 36),
				Text = "✔ Owned",
				TextColor3 = UI.Colors.Good,
				MaxTextSize = 22,
				Parent = row,
			})
		elseif isNext then
			local evoOk = evolution >= def.evolution
			local canPay = shards >= def.cost
			UI.Button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(190, 48),
				Text = evoOk and ("Upgrade · " .. Format.Number(def.cost) .. " 💎") or ("Needs " .. Evolutions.Get(def.evolution).name),
				BackgroundColor3 = (evoOk and canPay) and UI.Colors.Good or UI.Colors.PanelLight,
				Parent = row,
			}, function()
				if not evoOk then
					controllers.Notifications.Toast("Evolve to " .. Evolutions.Get(def.evolution).name .. " first", "bad")
				elseif not canPay then
					controllers.Notifications.Toast("Not enough Shards", "bad")
				else
					Remotes.Get("UpgradeHouse"):FireServer()
				end
			end)
		else
			UI.Text({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.fromOffset(190, 36),
				Text = "🔒 " .. Evolutions.Get(def.evolution).name,
				MaxTextSize = 18,
				Parent = row,
			})
		end
	end
end

function House:Init(c)
	controllers = c
	local gui = UI.Screen("House", 10)
	local content
	window, content = UI.Window(gui, {
		Title = "Your House",
		Emoji = "🏠",
		HeaderColor = Color3.fromRGB(190, 140, 70),
	})
	list = UI.List({ Size = UDim2.fromScale(1, 1), Parent = content }, 8)
	Panels.Register("House", window, function()
		House:Refresh()
	end)
end

function House:Start()
	for _, attr in ipairs({ "HouseLevel", "Shards", "Evolution" }) do
		player:GetAttributeChangedSignal(attr):Connect(function()
			House:Refresh()
		end)
	end
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name ~= "OpenHouse" then
			return
		end
		-- The lectern is a model inside the plot model, which carries OwnerUserId.
		local plot = prompt:FindFirstAncestorWhichIsA("Model")
		while plot and plot:GetAttribute("OwnerUserId") == nil do
			plot = plot:FindFirstAncestorWhichIsA("Model")
		end
		if not plot or plot:GetAttribute("OwnerUserId") ~= player.UserId then
			controllers.Notifications.Toast("This is not your house", "bad")
			return
		end
		Panels.Open("House")
	end)
end

return House
