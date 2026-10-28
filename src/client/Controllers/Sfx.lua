-- Plays the sounds configured in Config.Assets.Sounds (silent while IDs are 0).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Assets = require(ReplicatedStorage:WaitForChild("Shared").Config.Assets)

local Sfx = {}

local cache = {}

function Sfx.Play(name, volume)
	local id = Assets.Sounds[name]
	if not id or id == 0 then
		return nil
	end
	local sound = cache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = "rbxassetid://" .. id
		sound.Parent = SoundService
		cache[name] = sound
	end
	sound.Volume = volume or 0.6
	sound.TimePosition = 0
	sound:Play()
	return sound
end

function Sfx.Stop(name)
	local sound = cache[name]
	if sound then
		sound:Stop()
	end
end

return Sfx
