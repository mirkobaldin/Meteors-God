-- Pet meteors: every player's best meteor floats next to them (attributes PetType/PetMutation,
-- set by the server). Rendered locally for every player, always turning its face to your camera.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MeteorVisual = require(Shared.MeteorVisual)

local Pets = {}

local camera = workspace.CurrentCamera
local folder
local pets = {} -- [player] = {model, type, mutation, pos}

local PET_SIZE = 2.4

local function remove(player)
	local p = pets[player]
	if p then
		p.model:Destroy()
		pets[player] = nil
	end
end

local function refresh(player)
	local typeId = player:GetAttribute("PetType")
	local mutation = player:GetAttribute("PetMutation")
	local p = pets[player]
	if p and p.type == typeId and p.mutation == mutation and p.level == player:GetAttribute("PetLevel") then
		return
	end
	remove(player)
	if not typeId then
		return
	end
	local level = player:GetAttribute("PetLevel") or 0
	local model = MeteorVisual.Build(typeId, { size = PET_SIZE * (1 + level * 0.06), expression = "happy", mutation = mutation })
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
		end
	end
	model.Parent = folder
	pets[player] = { model = model, type = typeId, mutation = mutation, level = level }
end

local function watch(player)
	player:GetAttributeChangedSignal("PetType"):Connect(function()
		refresh(player)
	end)
	player:GetAttributeChangedSignal("PetMutation"):Connect(function()
		refresh(player)
	end)
	player:GetAttributeChangedSignal("PetLevel"):Connect(function()
		refresh(player)
	end)
	refresh(player)
end

local hiddenUntil = {} -- [player] = os.clock(): the pet was just thrown (Cosmic Hunt)

-- Hides a player's pet for a moment (it's flying at a planet), then it pops back.
function Pets.Hide(player, seconds)
	hiddenUntil[player] = os.clock() + seconds
end

function Pets:Init()
	folder = Instance.new("Folder")
	folder.Name = "Pets"
	folder.Parent = workspace
end

function Pets:Start()
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(remove)
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		for player, p in pairs(pets) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local core = p.model.PrimaryPart
			local hand = player.Character and (player.Character:FindFirstChild("RightHand") or player.Character:FindFirstChild("Right Arm"))
			if root and core and (hiddenUntil[player] or 0) > t then
				p.pos = nil
				core.CFrame = CFrame.new(0, -1e4, 0)
			elseif root and core and hand and player:GetAttribute("Hunting") then
				-- Cosmic Hunt: held just past the fist, ready to be thrown.
				local target = hand.Position + root.CFrame.UpVector * 3
				p.pos = p.pos and p.pos:Lerp(target, math.min(1, dt * 25)) or target
				local camPos = camera.CFrame.Position
				core.CFrame = CFrame.lookAt(p.pos, camPos) * CFrame.Angles(0, 0, math.sin(t * 3) * 0.2)
			elseif root and core then
				-- Behind the right shoulder, bobbing; follows smoothly.
				local target = (root.CFrame * CFrame.new(3.2, 2.2 + math.sin(t * 2.4 + player.UserId % 7) * 0.5, 2.2)).Position
				p.pos = p.pos and p.pos:Lerp(target, math.min(1, dt * 6)) or target
				local camPos = camera.CFrame.Position
				core.CFrame = CFrame.lookAt(p.pos, Vector3.new(camPos.X, p.pos.Y, camPos.Z))
			elseif core then
				p.pos = nil
				core.CFrame = CFrame.new(0, -1e4, 0)
			end
		end
	end)
end

return Pets
