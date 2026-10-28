-- Animates the rigged meteors (Blender meshes, tagged "LivingMeteor" by MeteorVisual): the jaw moves
-- with the expression (chomping, gnashing, roaring, snoring) and the pupils look at your camera with
-- small darting glances. Local only, and only for meteors near the camera.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MeteorVisual = require(ReplicatedStorage:WaitForChild("Shared").MeteorVisual)

local MeteorAnim = {}

local camera = workspace.CurrentCamera
local RANGE = 260
local LOOK = 0.035 -- how far the pupils move inside the eye holes (x diameter)
local glance = {} -- [model] = {offset, untilT}

local function jawFor(expression, t, seed)
	if expression == "furious" then
		return 0.42 + math.sin(t * 15 + seed) * 0.12 -- roaring
	elseif expression == "angry" then
		return 0.06 + math.abs(math.sin(t * 7 + seed)) * 0.06 -- gnashing
	elseif expression == "sleepy" then
		return 0.03 + (math.sin(t * 1.2 + seed) * 0.5 + 0.5) * 0.05 -- snoring
	elseif expression == "dizzy" then
		return 0.18 + math.sin(t * 3 + seed) * 0.1
	end
	-- happy: slow cocky chomps
	local chomp = math.max(0, math.sin(t * 2.4 + seed))
	return 0.05 + chomp * chomp * 0.16
end

local function lookFor(model, core, expression, t, seed)
	if expression == "sleepy" then
		return Vector3.new(0, -LOOK, 0)
	elseif expression == "dizzy" then
		return Vector3.new(math.cos(t * 6 + seed), math.sin(t * 6 + seed), 0) * LOOK
	end
	-- Towards the camera, in the meteor's own space (its face looks along -Z).
	local dir = core.CFrame:VectorToObjectSpace((camera.CFrame.Position - core.Position).Unit)
	local look = Vector3.new(dir.X, dir.Y, 0) * LOOK
	if look.Magnitude > LOOK then
		look = look.Unit * LOOK
	end
	local g = glance[model]
	if not g or t > g.untilT then
		g = { offset = Vector3.zero, untilT = t + math.random() * 2.5 + 0.8 }
		if math.random() < 0.35 then -- a quick look away
			g.offset = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, 0) * LOOK * 0.7
			g.untilT = t + 0.35
		end
		glance[model] = g
	end
	return look + g.offset
end

function MeteorAnim:Start()
	CollectionService:GetInstanceRemovedSignal("LivingMeteor"):Connect(function(model)
		glance[model] = nil
	end)
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local camPos = camera.CFrame.Position
		for _, model in ipairs(CollectionService:GetTagged("LivingMeteor")) do
			local core = model.PrimaryPart
			if core and (core.Position - camPos).Magnitude < RANGE then
				local expression = model:GetAttribute("Expression") or "happy"
				local seed = (model:GetAttribute("AnimSeed") or 0)
				if seed == 0 then
					seed = math.random() * 100
					model:SetAttribute("AnimSeed", seed)
				end
				local jaw = jawFor(expression, t, seed)
				model:SetAttribute("JawOpen", jaw)
				MeteorVisual.LayoutRig(model, jaw, lookFor(model, core, expression, t, seed), true)
			end
		end
	end)
end

return MeteorAnim
