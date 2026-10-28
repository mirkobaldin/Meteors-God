-- Builds the living meteor model: a glowing rocky ball with fire and a cartoon face sculpted
-- from parts (eyes, mouth, brows... are part of the body). The face looks along the model's -Z,
-- so callers orient the model towards whoever should see it.
-- No assets required: everything is Parts, Fire and lights.

local Shared = script.Parent
local Meteors = require(Shared.Config.Meteors)
local AssetLibrary = require(Shared.AssetLibrary)
local MeteorMeshes = require(Shared.Config.MeteorMeshes)

local MeteorVisual = {}

local BLACK = Color3.fromRGB(20, 15, 25)
local WHITE = Color3.fromRGB(255, 255, 255)
local GOLD = Color3.fromRGB(255, 205, 40)

-- The face is made of real parts welded to the body (eyes, pupils, brows, mouth, cheeks,
-- accessories), sculpted on the front of the sphere (-Z). Positions and sizes are in units of
-- the meteor's diameter, so the face scales with it.

-- Z of the sphere surface (diameter 1) at x, y on the front side, pushed in a little.
local function surface(x, y, inset)
	return -math.sqrt(math.max(0.25 - x * x - y * y, 0)) + (inset or 0.02)
end

local function piece(list, shape, color, pos, size, rot, props)
	table.insert(list, { shape = shape, color = color, pos = pos, size = size, rot = rot or Vector3.zero, props = props })
end

local function eyeSpec(list, x, y, w, expression, faceColor, glow)
	local z = surface(x, y)
	if expression == "dizzy" then
		for _, a in ipairs({ math.rad(45), math.rad(-45) }) do
			piece(list, "Block", BLACK, Vector3.new(x, y, z - 0.03), Vector3.new(w * 0.85, w * 0.16, 0.05), Vector3.new(0, 0, a))
		end
		return
	end
	if expression == "sleepy" then
		piece(list, "Block", BLACK, Vector3.new(x, y - 0.02, z - 0.02), Vector3.new(w * 0.9, w * 0.13, 0.05))
		return
	end
	-- Fierce look: a dark socket with a glowing slanted slit (the meteor's own fire color), a thin
	-- black pupil and a heavy rock brow pressing down on it. Inner corners lower = angry.
	local side = x > 0 and 1 or (x < 0 and -1 or 0)
	local slant = side * math.rad(18)
	local open = expression == "furious" and 0.36 or 0.3
	piece(list, "Ball", faceColor, Vector3.new(x, y, z + 0.015), Vector3.new(w * 1.15, w * 0.6, w * 0.3), Vector3.new(0, 0, slant))
	piece(list, "Ball", glow, Vector3.new(x, y, z - 0.012), Vector3.new(w * 0.95, w * open, w * 0.3), Vector3.new(0, 0, slant), { Material = Enum.Material.Neon })
	piece(list, "Block", BLACK, Vector3.new(x + side * w * 0.05, y, z - 0.04), Vector3.new(w * 0.09, w * open * 0.9, 0.03))
	local angle = math.rad(expression == "furious" and 36 or 28)
	local by = y + w * 0.5
	piece(list, "Block", faceColor, Vector3.new(x - side * w * 0.05, by, surface(x, by) - 0.045),
		Vector3.new(w * 1.35, w * 0.45, 0.09), Vector3.new(0, 0, side * angle), { Material = Enum.Material.Slate })
end

-- Row of pointed teeth (diamonds) along a mouth edge.
local function teeth(list, y, count, spacing, size)
	for i = 1, count do
		local tx = (i - (count + 1) / 2) * spacing
		piece(list, "Block", Color3.fromRGB(240, 235, 220), Vector3.new(tx, y, surface(tx, y) - 0.03),
			Vector3.new(size, size, 0.035), Vector3.new(0, 0, math.rad(45)))
	end
end

local function mouthSpec(list, expression, body)
	local y = -0.15
	local z = surface(0, y)
	if expression == "happy" then
		-- Wide cocky grin full of pointed teeth.
		piece(list, "Ball", BLACK, Vector3.new(0, y - 0.02, z + 0.01), Vector3.new(0.36, 0.1, 0.12))
		teeth(list, y + 0.025, 6, 0.06, 0.04)
		teeth(list, y - 0.06, 5, 0.06, 0.035)
	elseif expression == "sleepy" then
		piece(list, "Ball", BLACK, Vector3.new(0, y, z), Vector3.new(0.06, 0.06, 0.05))
	elseif expression == "dizzy" then
		for i = -1, 1 do
			piece(list, "Block", BLACK, Vector3.new(i * 0.055, y + (i == 0 and 0.012 or -0.008), z - 0.01),
				Vector3.new(0.065, 0.025, 0.05), Vector3.new(0, 0, i == 0 and 0 or i * math.rad(25)))
		end
	elseif expression == "furious" then
		-- Roaring: wide open, fangs top and bottom.
		piece(list, "Ball", BLACK, Vector3.new(0, y - 0.02, z + 0.01), Vector3.new(0.32, 0.18, 0.12))
		piece(list, "Ball", Color3.fromRGB(170, 30, 40), Vector3.new(0, y - 0.07, z - 0.02), Vector3.new(0.16, 0.06, 0.05))
		teeth(list, y + 0.055, 5, 0.06, 0.045)
		teeth(list, y - 0.1, 4, 0.065, 0.04)
	else -- angry: teeth clenched
		piece(list, "Ball", BLACK, Vector3.new(0, y - 0.01, z + 0.01), Vector3.new(0.3, 0.08, 0.12))
		teeth(list, y + 0.012, 5, 0.055, 0.035)
		teeth(list, y - 0.03, 5, 0.055, 0.035)
	end
end

-- Extras are part of the rock itself (no accessories): same material and color as the body.
local function extraSpec(list, extra, rock)
	if extra == "crest" then
		-- A crown of rock spikes growing out of the top.
		for k = 0, 6 do
			local a = k / 7 * math.pi * 2
			local tall = k % 2 == 0 and 0.22 or 0.15
			piece(list, "Block", rock, Vector3.new(math.sin(a) * 0.2, 0.44 + tall / 2, math.cos(a) * 0.2), Vector3.new(0.08, tall, 0.08),
				Vector3.new(math.cos(a) * math.rad(18), a, -math.sin(a) * math.rad(18)))
		end
	elseif extra == "fins" then
		-- Swept-back spikes like a helmet, shaped for speed.
		for _, side in ipairs({ -1, 0, 1 }) do
			piece(list, "Block", rock, Vector3.new(side * 0.22, 0.38, 0.12), Vector3.new(0.07, 0.07, 0.4),
				Vector3.new(math.rad(30), 0, side * math.rad(-25)))
		end
	elseif extra == "horns" then
		for _, side in ipairs({ -1, 1 }) do
			piece(list, "Block", rock, Vector3.new(side * 0.2, 0.42, -0.04), Vector3.new(0.09, 0.2, 0.09), Vector3.new(0, 0, -side * math.rad(22)))
			piece(list, "Block", rock, Vector3.new(side * 0.25, 0.54, -0.04), Vector3.new(0.05, 0.1, 0.05), Vector3.new(0, 0, -side * math.rad(35)))
		end
	end
end

local function faceSpec(def, expression, hasBody)
	local list = {}
	local face = def.face or {}
	local skin = def.body:Lerp(Color3.new(0, 0, 0), 0.35)
	eyeSpec(list, -0.15, 0.07, 0.19, expression, skin, def.fire[1])
	eyeSpec(list, 0.15, 0.07, 0.19, expression, skin, def.fire[1])
	mouthSpec(list, expression, def.body)
	if not hasBody then -- the Blender mesh already has its horns, crests and fins
		extraSpec(list, face.extra, def.body:Lerp(Color3.new(0, 0, 0), 0.25))
	end
	return list
end

local function placeFacePart(core, p, size)
	p.Size = p:GetAttribute("U_Size") * size
	local weld = p:FindFirstChild("FaceWeld")
	local rot = p:GetAttribute("U_Rot")
	weld.C0 = CFrame.new(p:GetAttribute("U_Pos") * size) * CFrame.Angles(rot.X, rot.Y, rot.Z)
end

local function buildFace(model, core, def, expression)
	local old = model:FindFirstChild("Face")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Face"
	folder.Parent = model
	if model:FindFirstChild("Body") then
		return -- the Blender mesh has the face carved in the rock (it glows from the InnerGlow ball)
	end
	local size = core.Size.X
	for _, spec in ipairs(faceSpec(def, expression, model:FindFirstChild("Body") ~= nil)) do
		local p = Instance.new("Part")
		p.Name = "FacePart"
		p.Shape = Enum.PartType[spec.shape]
		p.Material = Enum.Material.SmoothPlastic
		p.Color = spec.color
		p.Anchored = false
		p.Massless = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		for k, v in pairs(spec.props or {}) do
			p[k] = v
		end
		p:SetAttribute("U_Size", spec.size)
		p:SetAttribute("U_Pos", spec.pos)
		p:SetAttribute("U_Rot", spec.rot)
		local weld = Instance.new("Weld")
		weld.Name = "FaceWeld"
		weld.Part0 = core
		weld.Part1 = p
		weld.Parent = p
		placeFacePart(core, p, size)
		p.Parent = folder
	end
	folder.Parent = model
end

local function applyMutation(core, fire, light, mutationId)
	if mutationId == "Golden" then
		core.Color = core.Color:Lerp(Color3.fromRGB(255, 210, 60), 0.6)
		local s = Instance.new("Sparkles")
		s.SparkleColor = Color3.fromRGB(255, 220, 90)
		s.Parent = core
	elseif mutationId == "Rainbow" then
		local p = Instance.new("ParticleEmitter")
		p.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 255, 120)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 160, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 80, 255)),
		})
		p.LightEmission = 1
		p.Rate = 25
		p.Lifetime = NumberRange.new(0.6, 1)
		p.Speed = NumberRange.new(2, 4)
		p.SpreadAngle = Vector2.new(180, 180)
		p.Size = NumberSequence.new(0.4, 0)
		p.Parent = core
	elseif mutationId == "Eclipsed" then
		core.Color = Color3.fromRGB(15, 5, 25)
		fire.Color = Color3.fromRGB(160, 60, 255)
		fire.SecondaryColor = Color3.fromRGB(10, 0, 20)
		light.Color = Color3.fromRGB(160, 60, 255)
	end
end

--[[
	opts = {
		size = number (diameter, studs),
		expression = "sleepy" | "happy" | "angry" | "furious" | "dizzy",
		mutation = string?,
		anchored = bool (default true),
	}
]]
function MeteorVisual.Build(typeId, opts)
	opts = opts or {}
	local def = Meteors.ByID[typeId] or Meteors.Types[1]
	local size = opts.size or 3

	local model = Instance.new("Model")
	model.Name = "Meteor_" .. def.id

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(size, size, size)
	core.Material = Enum.Material.Neon
	core.Color = def.body
	core.Anchored = opts.anchored ~= false
	core.CanCollide = false
	core.CanQuery = true
	core.CanTouch = false
	core.CastShadow = false
	core.Parent = model
	model.PrimaryPart = core

	-- Slightly darker rocky shell so the ball reads as a rock, not just light.
	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(size * 1.04, size * 1.04, size * 1.04)
	shell.Material = Enum.Material.Basalt
	shell.Color = def.body:Lerp(Color3.new(0, 0, 0), 0.35)
	shell.Transparency = 0.55
	shell.Anchored = false
	shell.Massless = true
	shell.CanCollide = false
	shell.CanQuery = false
	shell.CanTouch = false
	shell.CastShadow = false
	shell.CFrame = core.CFrame
	shell.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = core
	weld.Part1 = shell
	weld.Parent = core

	-- Custom rock mesh from ReplicatedStorage.Assets.Meteors replaces the generated ball.
	local body = AssetLibrary.MeteorBody(def.id)
	if body then
		shell:Destroy()
		-- Config.MeteorMeshes (written by art/blender/meteors_build.py) has the mesh's bounding box
		-- in units of its sphere's diameter, so the sphere matches the core and the face sits on it.
		local info = MeteorMeshes[def.id]
		local s = body.Size
		local maxDim = math.max(s.X, s.Y, s.Z, 0.01)
		body.Name = "Body"
		body:SetAttribute("Unit", info and info.size or s / maxDim)
		body:SetAttribute("UnitScale", info and 1 or 1.1)
		body:SetAttribute("UnitOffset", info and info.center or Vector3.zero)
		body.Size = body:GetAttribute("Unit") * size * body:GetAttribute("UnitScale")
		body.Anchored = false
		body.Massless = true
		body.CanCollide = false
		body.CanQuery = false
		body.CanTouch = false
		body.CFrame = core.CFrame
		body.Parent = model
		local bodyWeld = Instance.new("Weld")
		bodyWeld.Name = "BodyWeld"
		bodyWeld.Part0 = core
		bodyWeld.Part1 = body
		bodyWeld.C0 = CFrame.new(body:GetAttribute("UnitOffset") * size)
		bodyWeld.Parent = core
		core.Transparency = 1
		-- Glowing ball inside the rock: it shows through the carved eyes, mouth and craters.
		local glow = Instance.new("Part")
		glow.Name = "InnerGlow"
		glow.Shape = Enum.PartType.Ball
		glow.Material = Enum.Material.Neon
		glow.Color = def.fire[1]
		glow.Size = Vector3.one * size * 0.62
		glow.Massless = true
		glow.CanCollide = false
		glow.CanQuery = false
		glow.CanTouch = false
		glow.CastShadow = false
		glow.CFrame = core.CFrame
		glow.Parent = model
		local glowWeld = Instance.new("WeldConstraint")
		glowWeld.Part0 = core
		glowWeld.Part1 = glow
		glowWeld.Parent = core
	end

	local fire = Instance.new("Fire")
	fire.Color = def.fire[1]
	fire.SecondaryColor = def.fire[2]
	fire.Size = math.clamp(size * 1.6, 2, 30)
	fire.Heat = math.clamp(size * 2, 5, 25)
	fire.Parent = core

	local light = Instance.new("PointLight")
	light.Color = def.fire[1]
	light.Range = math.clamp(size * 3, 6, 60)
	light.Brightness = 2
	light.Parent = core

	applyMutation(core, fire, light, opts.mutation)

	buildFace(model, core, def, opts.expression or "happy")

	model:SetAttribute("MeteorType", def.id)
	model:SetAttribute("Expression", opts.expression or "happy")
	return model
end

function MeteorVisual.SetExpression(model, expression)
	if model:GetAttribute("Expression") == expression then
		return
	end
	local core = model.PrimaryPart
	local def = Meteors.ByID[model:GetAttribute("MeteorType")]
	if core and def then
		buildFace(model, core, def, expression)
		model:SetAttribute("Expression", expression)
	end
end

-- Resizes ball, shell, fire, light and face together.
function MeteorVisual.SetSize(model, size)
	local core = model.PrimaryPart
	if not core then
		return
	end
	core.Size = Vector3.new(size, size, size)
	local shell = model:FindFirstChild("Shell")
	if shell then
		shell.Size = Vector3.new(size * 1.04, size * 1.04, size * 1.04)
	end
	local body = model:FindFirstChild("Body")
	if body and body:GetAttribute("Unit") then
		body.Size = body:GetAttribute("Unit") * size * (body:GetAttribute("UnitScale") or 1.1)
		local glow = model:FindFirstChild("InnerGlow")
		if glow then
			glow.Size = Vector3.one * size * 0.62
		end
		local bodyWeld = core:FindFirstChild("BodyWeld")
		if bodyWeld then
			bodyWeld.C0 = CFrame.new((body:GetAttribute("UnitOffset") or Vector3.zero) * size)
		end
	end
	local fire = core:FindFirstChildOfClass("Fire")
	if fire then
		fire.Size = math.clamp(size * 1.6, 2, 30)
		fire.Heat = math.clamp(size * 2, 5, 25)
	end
	local light = core:FindFirstChildOfClass("PointLight")
	if light then
		light.Range = math.clamp(size * 3, 6, 60)
	end
	local face = model:FindFirstChild("Face")
	if face then
		for _, p in ipairs(face:GetChildren()) do
			placeFacePart(core, p, size)
		end
	end
end

return MeteorVisual
