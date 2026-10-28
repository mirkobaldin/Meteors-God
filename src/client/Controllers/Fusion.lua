-- Fusion Reactor window: opened from the reactor on the central island. Lists the meteor types
-- with at least 3 copies in storage; Fuse turns 3 of them into 1 of the next rarity.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)
local State = require(script.Parent.State)

local Fusion = {}

local player = Players.LocalPlayer
local window, list, controllers

-- { type -> {uids} } of meteors that can be fused (storage, not exclusive, not equipped).
local function groups(snap)
	local out = {}
	for uid, m in pairs(snap.meteors) do
		if not m.altar and not m.paid and uid ~= snap.equipped then
			out[m.t] = out[m.t] or {}
			table.insert(out[m.t], uid)
		end
	end
	return out
end

function Fusion:Refresh()
	local snap = State.Snapshot
	if not window.Visible or not snap then
		return
	end
	UI.Clear(list)
	local any = false
	for typeId, uids in pairs(groups(snap)) do
		local def = Meteors.ByID[typeId]
		local nextRarity = def and Meteors.NextRarity(def.rarity)
		if #uids >= 3 and nextRarity then
			any = true
			local row = UI.New("Frame", {
				Size = UDim2.new(1, -8, 0, 64),
				BackgroundColor3 = UI.Colors.PanelLight,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Parent = list,
			})
			UI.Corner(UDim.new(0, 10)).Parent = row
			UI.Stroke(Meteors.RarityByID[nextRarity].color, 2, 0.3).Parent = row
			UI.Text({
				Size = UDim2.new(0.62, -12, 1, -12),
				Position = UDim2.fromOffset(12, 6),
				Text = string.format("3x %s (%d owned)  ➜  1 random %s meteor", typeId, #uids, nextRarity),
				TextXAlignment = Enum.TextXAlignment.Left,
				MaxTextSize = 20,
				Parent = row,
			})
			UI.Button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0.3, 0, 0, 46),
				Text = "⚛ FUSE",
				BackgroundColor3 = Color3.fromRGB(190, 110, 255),
				Parent = row,
			}, function()
				Remotes.Get("FuseMeteors"):FireServer(uids[1])
			end)
		end
	end
	if not any then
		UI.Text({
			Size = UDim2.new(1, -8, 0, 60),
			Text = "You need 3 meteors of the same type in storage (not on the altar).",
			TextColor3 = UI.Colors.Muted,
			MaxTextSize = 20,
			Parent = list,
		})
	end
end

function Fusion:Init(c)
	controllers = c
	local gui = UI.Screen("Fusion", 10)
	local content
	window, content = UI.Window(gui, {
		Title = "Fusion Reactor",
		Emoji = "⚛",
		HeaderColor = Color3.fromRGB(120, 70, 190),
	})
	list = UI.List({ Size = UDim2.fromScale(1, 1), Parent = content }, 8)
	Panels.Register("Fusion", window, function()
		Fusion:Refresh()
	end)
end

function Fusion:Start()
	State.Changed:Connect(function()
		Fusion:Refresh()
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name ~= "OpenFusion" then
			return
		end
		if (player:GetAttribute("Planets") or 0) < Game.Fusion.RequiredPlanets then
			controllers.Notifications.Toast("The Fusion Reactor unlocks after " .. Game.Fusion.RequiredPlanets .. " planets destroyed", "bad")
			return
		end
		Panels.Open("Fusion")
	end)
end

return Fusion
