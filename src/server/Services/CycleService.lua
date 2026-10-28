-- The 5-minute loop: Meteor Shower -> Bombardment -> repeat.
-- State is replicated through workspace attributes so clients can show the timer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)

local CycleService = {}

local phaseEvent = Instance.new("BindableEvent")
CycleService.PhaseChanged = phaseEvent.Event

CycleService.Phase = "Shower"

local function setPhase(phase, duration)
	CycleService.Phase = phase
	workspace:SetAttribute("CyclePhase", phase)
	workspace:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + duration)
	phaseEvent:Fire(phase, duration)
end

function CycleService:IsBombard()
	return CycleService.Phase == "Bombard"
end

function CycleService:Init()
	workspace:SetAttribute("CyclePhase", "Shower")
	workspace:SetAttribute("PhaseEndsAt", 0)
	workspace:SetAttribute("WrathUntil", 0)
end

function CycleService:Start()
	task.spawn(function()
		task.wait(3) -- let the world settle on server start
		while true do
			setPhase("Shower", Game.Cycle.ShowerDuration)
			Notify.Announce("☄️ PIOGGIA DI METEORITI! Raccoglili!", Color3.fromRGB(255, 170, 80))
			task.wait(Game.Cycle.ShowerDuration)

			setPhase("Bombard", Game.Cycle.BombardDuration)
			Notify.Announce("🪐 BOMBARDAMENTO! Corri sui Ponti Stellari e lancia!", Color3.fromRGB(150, 200, 255))
			task.wait(Game.Cycle.BombardDuration)
		end
	end)
end

return CycleService
