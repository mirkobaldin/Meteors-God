-- The loop: Meteor Shower -> Calm -> repeat. Planets can be hit at any time (no timed bombardment).
-- When a shower starts, every player is teleported to their own Comet Islet and held for a
-- countdown, so everybody races to the meteors from the same distance.
-- State is replicated through workspace attributes so clients can show the timer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)

local Players = game:GetService("Players")

local CycleService = {}
local services

local phaseEvent = Instance.new("BindableEvent")
CycleService.PhaseChanged = phaseEvent.Event

CycleService.Phase = "Shower"

local rng = Random.new()

local function setPhase(phase, duration)
	CycleService.Phase = phase
	workspace:SetAttribute("CyclePhase", phase)
	workspace:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + duration)
	phaseEvent:Fire(phase, duration)
end

-- Kept for the callers: throwing at planets is allowed in every phase now.
function CycleService:IsBombard()
	return true
end

-- Everybody to their Comet Islet, frozen for the countdown (not who is throwing, hunting or trading).
local function gatherPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local altar = services.WorldService:GetAltar(player)
		local busy = services.LaunchService:Current(player) or services.HuntService:IsHunting(player)
			or services.TradeService:IsTrading(player)
		if character and humanoid and altar and not busy then
			character:PivotTo(altar.display * CFrame.new(0, 6, 0))
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			task.delay(Game.Cycle.ShowerCountdown, function()
				if humanoid.Parent then
					humanoid.JumpPower = 50
					services.PlayerService:RefreshCharacter(player)
				end
			end)
		end
	end
end

function CycleService:Init(s)
	services = s
	workspace:SetAttribute("CyclePhase", "Shower")
	workspace:SetAttribute("PhaseEndsAt", 0)
	workspace:SetAttribute("WrathUntil", 0)
	workspace:SetAttribute("CosmicEvent", "")
end

function CycleService:Start()
	task.spawn(function()
		task.wait(3) -- let the world settle on server start
		while true do
			local event = rng:NextNumber() < Game.Events.Chance and Game.Events.List[rng:NextInteger(1, #Game.Events.List)] or nil
			workspace:SetAttribute("CosmicEvent", event and event.id or "")
			gatherPlayers()
			workspace:SetAttribute("ShowerGoAt", workspace:GetServerTimeNow() + Game.Cycle.ShowerCountdown)
			if event then
				Notify.Announce("🌌 COSMIC EVENT: " .. event.name .. " — " .. event.desc, event.color)
			else
				Notify.Announce("☄️ METEOR SHOWER! Get ready on your islet...", Color3.fromRGB(255, 170, 80))
			end
			task.wait(Game.Cycle.ShowerCountdown)
			setPhase("Shower", Game.Cycle.ShowerDuration)
			Notify.Announce("☄️ GO! Grab the meteors!", Color3.fromRGB(255, 200, 90))
			task.wait(Game.Cycle.ShowerDuration)

			workspace:SetAttribute("CosmicEvent", "")
			setPhase("Calm", Game.Cycle.CalmDuration)
			task.wait(Game.Cycle.CalmDuration)
		end
	end)
end

return CycleService
