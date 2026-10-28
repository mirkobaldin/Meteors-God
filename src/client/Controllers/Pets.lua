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
	if p and p.type == typeId and p.mutation == mutation then
		return
	end
	remove(player)
	if not typeId then
		return
	end
	local model = MeteorVisual.Build(typeId, { size = PET_SIZE, expression = "happy", mutation = mutation })
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
		end
	end
	model.Parent = folder
	pets[player] = { model = model, type = typeId, mutation = mutation }
end

local function watch(player)
	player:GetAttributeChangedSignal("PetType"):Connect(function()
		refresh(player)
	end)
	player:GetAttributeChangedSignal("PetMutation"):Connect(function()
		refresh(player)
	end)
	refresh(player)
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
			if root and core then
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
