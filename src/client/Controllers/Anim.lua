-- Plays the R15 animations configured in Config.Assets.Animations (does nothing while IDs are 0).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage:WaitForChild("Shared").Config.Assets)

local Anim = {}

local player = Players.LocalPlayer
local tracks = {} -- [name] = AnimationTrack (for the current character)
local trackOwner

local function animator()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	if trackOwner ~= humanoid then
		tracks = {}
		trackOwner = humanoid
	end
	return humanoid:FindFirstChildOfClass("Animator") or humanoid
end

function Anim.Play(name, looped, fade)
	local id = Assets.Animations[name]
	if not id or id == 0 then
		return nil
	end
	local a = animator()
	if not a then
		return nil
	end
	local track = tracks[name]
	if not track then
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. id
		local ok, loaded = pcall(function()
			return a:LoadAnimation(animation)
		end)
		if not ok then
			return nil
		end
		track = loaded
		track.Priority = Enum.AnimationPriority.Action
		tracks[name] = track
	end
	track.Looped = looped == true
	track:Play(fade or 0.15)
	return track
end

function Anim.Stop(name, fade)
	local track = tracks[name]
	if track and track.IsPlaying then
		track:Stop(fade or 0.15)
	end
end

return Anim
