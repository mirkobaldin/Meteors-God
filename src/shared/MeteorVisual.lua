-- Builds the living meteor model: a glowing ball with fire and a cartoon face.
-- The face is a BillboardGui, so it always looks at whoever is watching.
-- No assets required: everything is Parts, Fire, lights and GUI frames.

local Shared = script.Parent
local Meteors = require(Shared.Config.Meteors)
local AssetLibrary = require(Shared.AssetLibrary)

local MeteorVisual = {}

local BLACK = Color3.fromRGB(20, 15, 25)
local WHITE = Color3.fromRGB(255, 255, 255)

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	for k, v in pairs(props) do
		f[k] = v
	end
	f.Parent = parent
	return f
end

local function round(f, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(1, 0)
	c.Parent = f
	return f
end

local function label(parent, text, pos, size, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = pos
	t.Size = size
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color or BLACK
	t.Parent = parent
	return t
end

local function drawEye(gui, x, y, size, expression)
	if expression == "dizzy" then
		label(gui, "X", UDim2.fromScale(x, y), UDim2.fromScale(size * 1.1, size * 1.1))
		return
	end
	if expression == "sleepy" then
		round(frame(gui, {
			Position = UDim2.fromScale(x, y + 0.02),
			Size = UDim2.fromScale(size, size * 0.18),
			BackgroundColor3 = BLACK,
		}))
		return
	end
	local white = round(frame(gui, {
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(size, size),
		BackgroundColor3 = expression == "furious" and Color3.fromRGB(255, 200, 200) or WHITE,
	}))
	local pupilScale = expression == "furious" and 0.38 or 0.52
	round(frame(white, {
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.fromScale(pupilScale, pupilScale),
		BackgroundColor3 = BLACK,
	}))
	round(frame(white, {
		Position = UDim2.fromScale(0.62, 0.42),
		Size = UDim2.fromScale(0.18, 0.18),
		BackgroundColor3 = WHITE,
		ZIndex = 3,
	}))
end

local function drawBrow(gui, x, y, width, angle)
	round(
		frame(gui, {
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(width, width * 0.22),
			BackgroundColor3 = BLACK,
			Rotation = angle,
			ZIndex = 4,
		}),
		UDim.new(0.5, 0)
	)
end

local function drawMouth(gui, expression)
	if expression == "happy" then
		local m = round(frame(gui, {
			Position = UDim2.fromScale(0.5, 0.7),
			Size = UDim2.fromScale(0.34, 0.16),
			BackgroundColor3 = BLACK,
		}), UDim.new(0.5, 0))
		round(frame(m, {
			Position = UDim2.fromScale(0.5, 0.72),
			Size = UDim2.fromScale(0.5, 0.45),
			BackgroundColor3 = Color3.fromRGB(255, 110, 140),
		}))
	elseif expression == "sleepy" then
		round(frame(gui, {
			Position = UDim2.fromScale(0.5, 0.7),
			Size = UDim2.fromScale(0.1, 0.1),
			BackgroundColor3 = BLACK,
		}))
		label(gui, "z", UDim2.fromScale(0.86, 0.14), UDim2.fromScale(0.18, 0.18), WHITE)
	elseif expression == "dizzy" then
		label(gui, "~", UDim2.fromScale(0.5, 0.72), UDim2.fromScale(0.36, 0.26))
	else -- angry / furious
		local m = round(frame(gui, {
			Position = UDim2.fromScale(0.5, 0.71),
			Size = UDim2.fromScale(expression == "furious" and 0.42 or 0.32, 0.12),
			BackgroundColor3 = BLACK,
		}), UDim.new(0.3, 0))
		frame(m, {
			Position = UDim2.fromScale(0.5, 0.3),
			Size = UDim2.fromScale(0.8, 0.3),
			BackgroundColor3 = WHITE,
		})
	end
end

local function drawExtra(gui, extra)
	if extra == "crown" then
		local gold = Color3.fromRGB(255, 205, 40)
		frame(gui, {
			Position = UDim2.fromScale(0.5, 0.1),
			Size = UDim2.fromScale(0.42, 0.1),
			BackgroundColor3 = gold,
			ZIndex = 5,
		})
		for i = -1, 1 do
			frame(gui, {
				Position = UDim2.fromScale(0.5 + i * 0.15, 0.04),
				Size = UDim2.fromScale(0.09, 0.09),
				BackgroundColor3 = gold,
				Rotation = 45,
				ZIndex = 5,
			})
		end
	elseif extra == "sunglasses" then
		for _, x in ipairs({ 0.32, 0.68 }) do
			round(
				frame(gui, {
					Position = UDim2.fromScale(x, 0.42),
					Size = UDim2.fromScale(0.3, 0.2),
					BackgroundColor3 = BLACK,
					ZIndex = 6,
				}),
				UDim.new(0.35, 0)
			)
		end
		frame(gui, {
			Position = UDim2.fromScale(0.5, 0.38),
			Size = UDim2.fromScale(0.14, 0.04),
			BackgroundColor3 = BLACK,
			ZIndex = 6,
		})
	elseif extra == "horns" then
		local red = Color3.fromRGB(200, 30, 40)
		for _, side in ipairs({ -1, 1 }) do
			frame(gui, {
				Position = UDim2.fromScale(0.5 + side * 0.3, 0.1),
				Size = UDim2.fromScale(0.1, 0.2),
				BackgroundColor3 = red,
				Rotation = side * 25,
				ZIndex = 5,
			})
		end
	end
end

-- Clears and redraws the face for the given expression.
function MeteorVisual.DrawFace(gui, typeDef, expression)
	gui:ClearAllChildren()
	local face = typeDef.face or {}
	local sunglasses = face.extra == "sunglasses"
	if face.eyes == "cyclops" then
		drawEye(gui, 0.5, 0.42, 0.36, expression)
	elseif not sunglasses or expression == "dizzy" then
		drawEye(gui, 0.32, 0.42, 0.24, expression)
		drawEye(gui, 0.68, 0.42, 0.24, expression)
	end
	if expression == "angry" or expression == "furious" then
		local tilt = expression == "furious" and 28 or 18
		if face.eyes == "cyclops" then
			drawBrow(gui, 0.5, 0.2, 0.4, 0)
		else
			drawBrow(gui, 0.32, 0.25, 0.26, tilt)
			drawBrow(gui, 0.68, 0.25, 0.26, -tilt)
		end
	end
	if expression ~= "angry" and expression ~= "furious" then
		local blush = Color3.fromRGB(255, 120, 150)
		for _, x in ipairs({ 0.18, 0.82 }) do
			round(frame(gui, {
				Position = UDim2.fromScale(x, 0.6),
				Size = UDim2.fromScale(0.12, 0.07),
				BackgroundColor3 = blush,
				BackgroundTransparency = 0.3,
			}))
		end
	end
	drawMouth(gui, expression)
	if not (sunglasses and expression == "dizzy") then
		drawExtra(gui, face.extra)
	end
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
		local s = body.Size
		local maxDim = math.max(s.X, s.Y, s.Z, 0.01)
		body.Name = "Body"
		body:SetAttribute("Unit", s / maxDim)
		body.Size = (s / maxDim) * size * 1.1
		body.Anchored = false
		body.Massless = true
		body.CanCollide = false
		body.CanQuery = false
		body.CanTouch = false
		body.CFrame = core.CFrame
		body.Parent = model
		local bodyWeld = Instance.new("WeldConstraint")
		bodyWeld.Part0 = core
		bodyWeld.Part1 = body
		bodyWeld.Parent = core
		core.Transparency = 1
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

	local gui = Instance.new("BillboardGui")
	gui.Name = "Face"
	gui.Size = UDim2.new(size * 0.95, 0, size * 0.95, 0)
	-- Camera-space offset: positive Z pulls the face towards the viewer, in front of the ball.
	gui.StudsOffset = Vector3.new(0, 0, size * 0.6)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.MaxDistance = 600
	gui.ResetOnSpawn = false
	gui.Adornee = core
	gui.Parent = core
	MeteorVisual.DrawFace(gui, def, opts.expression or "happy")

	model:SetAttribute("MeteorType", def.id)
	model:SetAttribute("Expression", opts.expression or "happy")
	return model
end

function MeteorVisual.SetExpression(model, expression)
	if model:GetAttribute("Expression") == expression then
		return
	end
	local core = model.PrimaryPart
	local gui = core and core:FindFirstChild("Face")
	local def = Meteors.ByID[model:GetAttribute("MeteorType")]
	if gui and def then
		MeteorVisual.DrawFace(gui, def, expression)
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
		body.Size = body:GetAttribute("Unit") * size * 1.1
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
	local gui = core:FindFirstChild("Face")
	if gui then
		gui.Size = UDim2.new(size * 0.95, 0, size * 0.95, 0)
		gui.StudsOffset = Vector3.new(0, 0, size * 0.6)
	end
end

return MeteorVisual
