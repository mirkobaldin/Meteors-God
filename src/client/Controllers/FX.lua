-- Client-side visual effects: meteor flights, planet impacts with an effect per meteor element,
-- layer breaks, supernova and the space-time rift planets arrive from. Everything is local (smooth, no replication cost).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Format = require(Shared.Util.Format)
local PlanetMath = require(Shared.Util.PlanetMath)
local MeteorVisual = require(Shared.MeteorVisual)
local Meteors = require(Shared.Config.Meteors)
local Remotes = require(Shared.Remotes)

local Sfx = require(script.Parent.Sfx)

local FX = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local folder
local rng = Random.new()
local shakeUntil, shakeStrength = 0, 0
local screenFlash

local TEX = {
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Spark = "rbxasset://textures/particles/sparkles_main.dds",
	Glow = "rbxasset://textures/particles/sparkles_main.dds",
}

local function tex(name)
	return Assets.Image(Assets.Particles[name]) or TEX[name] or TEX.Spark
end

-- Roblox parts can't be bigger than 2048 studs on any axis.
local function clampSize(v)
	return Vector3.new(math.min(v.X, 2048), math.min(v.Y, 2048), math.min(v.Z, 2048))
end

local function anchorPart(position)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(position)
	p.Parent = folder
	return p
end

local function burst(position, props, count, life)
	local holder = anchorPart(position)
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.LightInfluence = 0
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = holder
	e:Emit(count)
	task.delay(life or 4, function()
		holder:Destroy()
	end)
end

local function neonBall(position, diameter, color, transparency)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency or 0
	p.Size = clampSize(Vector3.new(diameter, diameter, diameter))
	p.CFrame = CFrame.new(position)
	p.Parent = folder
	return p
end

local function expandAndFade(part, size, time, style)
	local t = TweenService:Create(part, TweenInfo.new(time, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = clampSize(size),
		Transparency = 1,
	})
	t:Play()
	t.Completed:Connect(function()
		part:Destroy()
	end)
end

-- Flat ring lying on the surface (its axis along `normal`).
local function ring(position, normal, fromSize, toSize, color, time, transparency)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency or 0.15
	p.Size = clampSize(Vector3.new(0.6, fromSize, fromSize))
	p.CFrame = CFrame.lookAt(position, position + normal) * CFrame.Angles(0, math.rad(90), 0)
	p.Parent = folder
	expandAndFade(p, Vector3.new(0.6, toSize, toSize), time)
end

local function light(position, color, range, time)
	local holder = anchorPart(position)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = math.min(range, 60)
	l.Brightness = 12
	l.Parent = holder
	local t = TweenService:Create(l, TweenInfo.new(time, Enum.EasingStyle.Quad), { Brightness = 0 })
	t:Play()
	t.Completed:Connect(function()
		holder:Destroy()
	end)
end

function FX.Shake(strength, duration)
	if require(script.Parent.Menu).Get("CameraShake") == false then
		return
	end
	shakeStrength = math.max(shakeStrength, strength)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
end

-- Camera offset to apply this frame (used by the Launch controller and by FX itself).
function FX.ShakeOffset()
	if os.clock() > shakeUntil then
		shakeStrength = 0
		return CFrame.identity
	end
	local s = shakeStrength * math.clamp((shakeUntil - os.clock()) / 0.6, 0, 1)
	return CFrame.Angles(rng:NextNumber(-s, s) * 0.02, rng:NextNumber(-s, s) * 0.02, 0)
end

function FX.ScreenFlash(color, strength)
	screenFlash.BackgroundColor3 = color or Color3.new(1, 1, 1)
	screenFlash.BackgroundTransparency = 1 - (strength or 0.6)
	TweenService:Create(screenFlash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
end

local function rocks(position, normal, count, size, color, speed, material)
	for _ = 1, count do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = material or Enum.Material.Slate
		p.Color = color
		local s = rng:NextNumber(0.4, 1) * size
		p.Size = Vector3.new(s, s * rng:NextNumber(0.5, 1), s * rng:NextNumber(0.5, 1))
		p.CFrame = CFrame.new(position) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0)
		p.Parent = folder
		local dir = (normal + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) * 0.8).Unit
		local time = rng:NextNumber(1.5, 3)
		local t = TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(position + dir * speed * rng:NextNumber(0.5, 1.2))
				* CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
			Transparency = 1,
		})
		t:Play()
		t.Completed:Connect(function()
			p:Destroy()
		end)
	end
end

local function damageNumber(position, damage, crit, color)
	local Menu = require(script.Parent.Menu)
	if not Menu.Get("ShowDamageNumbers") then
		return
	end
	local holder = anchorPart(position)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(crit and 420 or 300, crit and 120 or 80)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 1e5
	bb.Parent = holder
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = crit and Color3.fromRGB(255, 215, 60) or Color3.fromRGB(255, 255, 255)
	t.TextStrokeColor3 = crit and Color3.fromRGB(150, 40, 0) or color:Lerp(Color3.new(0, 0, 0), 0.5)
	t.TextStrokeTransparency = 0
	t.Text = (crit and "CRITICAL!\n" or "") .. Format.Number(damage)
	t.Parent = bb
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = t
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(bb, TweenInfo.new(1.8, Enum.EasingStyle.Quad), { StudsOffsetWorldSpace = Vector3.new(0, 90, 0) })
		:Play()
	task.delay(1.1, function()
		TweenService:Create(t, TweenInfo.new(0.7), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	task.delay(2, function()
		holder:Destroy()
	end)
end

-- Random direction on the plane perpendicular to `normal`.
local function tangent(normal)
	local v = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
	v = v - normal * v:Dot(normal)
	return v.Magnitude > 0.01 and v.Unit or normal:Cross(Vector3.new(0, 1, 0)).Unit
end

local function basePart(props)
	local p = Instance.new(props.ClassName or "Part")
	props.ClassName = nil
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	if props.Shape then
		p.Shape = props.Shape
		props.Shape = nil
	end
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = folder
	return p
end

local function fadeAndDestroy(part, delay, time)
	task.delay(delay, function()
		local t = TweenService:Create(part, TweenInfo.new(time), { Transparency = 1 })
		t:Play()
		t.Completed:Connect(function()
			part:Destroy()
		end)
	end)
end

-- Jagged lightning bolt from `a` to `b` made of neon segments; flashes and disappears.
local function bolt(a, b, color, width, life)
	local points = { a }
	local n = 7
	local dir = b - a
	local side = tangent(dir.Unit)
	for i = 1, n - 1 do
		local off = side * rng:NextNumber(-1, 1) * dir.Magnitude * 0.08 + tangent(dir.Unit) * rng:NextNumber(-1, 1) * dir.Magnitude * 0.05
		table.insert(points, a + dir * (i / n) + off)
	end
	table.insert(points, b)
	for i = 1, #points - 1 do
		local p0, p1 = points[i], points[i + 1]
		local seg = basePart({
			Material = Enum.Material.Neon,
			Color = color,
			Size = Vector3.new(width, width, (p1 - p0).Magnitude),
			CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
		})
		fadeAndDestroy(seg, life * 0.5, life * 0.5)
	end
end

-- Element effects, scaled by the crater radius `s`.
local ELEMENT = {}

function ELEMENT.frost(point, normal, s)
	-- Ice crystals shooting out of the crater.
	for _ = 1, 9 do
		local dir = (normal + tangent(normal) * rng:NextNumber(0, 0.6)).Unit
		local length = s * rng:NextNumber(0.6, 1.3)
		local w = length * 0.18
		local base = point - normal * s * 0.3 + tangent(normal) * rng:NextNumber(0, s * 0.5)
		local shard = basePart({
			Material = Enum.Material.Glass,
			Color = Color3.fromRGB(170, 235, 255),
			Transparency = 0.15,
			Reflectance = 0.2,
			Size = Vector3.new(w, 0.5, w),
			CFrame = CFrame.lookAt(base, base + dir) * CFrame.Angles(math.rad(-90), math.rad(45), 0),
		})
		local grown = CFrame.lookAt(base + dir * length / 2, base + dir * length) * CFrame.Angles(math.rad(-90), math.rad(45), 0)
		TweenService:Create(shard, TweenInfo.new(rng:NextNumber(0.25, 0.5), Enum.EasingStyle.Back), {
			Size = Vector3.new(w, length, w),
			CFrame = grown,
		}):Play()
		fadeAndDestroy(shard, 3.5, 1.2)
	end
	burst(point + normal * 8, {
		Texture = tex("Spark"),
		Color = ColorSequence.new(Color3.fromRGB(230, 250, 255)),
		LightEmission = 0.8,
		Size = NumberSequence.new(s * 0.05, 0),
		Lifetime = NumberRange.new(1.5, 3),
		Speed = NumberRange.new(s * 0.5, s * 1.5),
		SpreadAngle = Vector2.new(90, 90),
		Acceleration = -normal * s * 0.3,
	}, 80, 4)
end

function ELEMENT.magma(point, normal, s)
	-- Lava blobs thrown out in arcs, landing around the crater.
	for _ = 1, 16 do
		local blob = basePart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, rng:NextInteger(80, 160), 20), Size = Vector3.one * s * rng:NextNumber(0.06, 0.14), CFrame = CFrame.new(point) })
		local side = tangent(normal) * s * rng:NextNumber(0.8, 2)
		local up = normal * s * rng:NextNumber(0.8, 1.8)
		local start, time = os.clock(), rng:NextNumber(1, 1.6)
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local k = math.min(1, (os.clock() - start) / time)
			blob.CFrame = CFrame.new(point + side * k + up * 4 * k * (1 - k))
			if k >= 1 then
				conn:Disconnect()
				fadeAndDestroy(blob, 0.4, 1)
			end
		end)
	end
	expandAndFade(neonBall(point, s * 0.8, Color3.fromRGB(255, 120, 20), 0.3), Vector3.one * s * 2.4, 2.5)
end

function ELEMENT.spark(point, normal, s)
	for k = 0, 2 do
		task.delay(k * 0.15, function()
			for _ = 1, 4 do
				local from = point + normal * s * rng:NextNumber(1.5, 3) + tangent(normal) * s * rng:NextNumber(0, 1.5)
				bolt(from, point + tangent(normal) * rng:NextNumber(0, s * 0.6), Color3.fromRGB(255, 250, 150), math.max(1, s * 0.035), 0.35)
			end
			FX.ScreenFlash(Color3.fromRGB(255, 255, 200), 0.12)
		end)
	end
	for _ = 1, 6 do
		local dir = tangent(normal)
		bolt(point, point + dir * s * rng:NextNumber(1, 2), Color3.fromRGB(200, 240, 255), math.max(0.8, s * 0.025), 0.5)
	end
end

function ELEMENT.venom(point, normal, s)
	burst(point + normal * s * 0.2, {
		Texture = tex("Smoke"),
		Color = ColorSequence.new(Color3.fromRGB(160, 255, 80), Color3.fromRGB(40, 120, 20)),
		LightEmission = 0.3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s * 0.4), NumberSequenceKeypoint.new(1, s * 1.2) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(3, 5),
		Speed = NumberRange.new(s * 0.2, s * 0.6),
		SpreadAngle = Vector2.new(80, 80),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-20, 20),
	}, 30, 6)
	for _ = 1, 14 do
		local base = point + tangent(normal) * rng:NextNumber(0, s * 0.8)
		local b = basePart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(140, 255, 60), Transparency = 0.3, Size = Vector3.one * 0.5, CFrame = CFrame.new(base) })
		local size = s * rng:NextNumber(0.08, 0.2)
		task.delay(rng:NextNumber(0, 1.5), function()
			local t = TweenService:Create(b, TweenInfo.new(0.8, Enum.EasingStyle.Back), { Size = Vector3.one * size, CFrame = CFrame.new(base + normal * size) })
			t:Play()
			t.Completed:Connect(function()
				expandAndFade(b, Vector3.one * size * 1.8, 0.2)
			end)
		end)
	end
end

function ELEMENT.crystal(point, normal, s)
	for _ = 1, 18 do
		local shard = basePart({
			ClassName = "WedgePart",
			Material = Enum.Material.Glass,
			Color = Color3.fromRGB(255, rng:NextInteger(120, 200), 255),
			Transparency = 0.1,
			Reflectance = 0.3,
			Size = Vector3.new(s * 0.04, s * rng:NextNumber(0.15, 0.3), s * 0.1),
			CFrame = CFrame.new(point) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
		})
		local dir = (normal + tangent(normal) * rng:NextNumber(0.3, 1.2)).Unit
		local t = TweenService:Create(shard, TweenInfo.new(rng:NextNumber(1.5, 2.5), Enum.EasingStyle.Quint), {
			CFrame = CFrame.new(point + dir * s * rng:NextNumber(1, 2.2)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
		})
		t:Play()
		fadeAndDestroy(shard, 1.6, 0.8)
	end
	ELEMENT.frost(point, normal, s * 0.7)
end

function ELEMENT.aurora(point, normal, s)
	local colors = { Color3.fromRGB(100, 255, 190), Color3.fromRGB(140, 90, 255), Color3.fromRGB(80, 200, 255) }
	for i = 1, 6 do
		local a0 = basePart({ Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(point) })
		local top = point + normal * s * rng:NextNumber(2, 3.5) + tangent(normal) * s * rng:NextNumber(0.5, 1.5)
		local a1 = basePart({ Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(top) })
		local at0, at1 = Instance.new("Attachment"), Instance.new("Attachment")
		at0.Parent, at1.Parent = a0, a1
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = at0, at1
		beam.Color = ColorSequence.new(colors[i % 3 + 1], colors[(i + 1) % 3 + 1])
		beam.LightEmission = 1
		beam.Width0, beam.Width1 = s * 0.3, s * 0.05
		beam.CurveSize0, beam.CurveSize1 = s * rng:NextNumber(-1, 1), s * rng:NextNumber(-1, 1)
		beam.FaceCamera = true
		beam.Transparency = NumberSequence.new(0.2, 1)
		beam.Parent = a0
		task.delay(2.5, function()
			a0:Destroy()
			a1:Destroy()
		end)
	end
end

function ELEMENT.solar(point, normal, s)
	expandAndFade(neonBall(point, s, Color3.fromRGB(255, 250, 220), 0), Vector3.one * s * 5, 0.8)
	for _ = 1, 12 do
		local dir = (normal * rng:NextNumber(0, 0.5) + tangent(normal)).Unit
		local ray = basePart({
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 220, 90),
			Size = Vector3.new(s * 0.05, s * 0.05, s * 0.2),
			CFrame = CFrame.lookAt(point, point + dir),
		})
		TweenService:Create(ray, TweenInfo.new(0.7, Enum.EasingStyle.Quart), {
			Size = Vector3.new(s * 0.03, s * 0.03, s * 4),
			CFrame = CFrame.lookAt(point + dir * s * 2, point + dir * s * 4),
			Transparency = 1,
		}):Play()
		task.delay(0.8, function()
			ray:Destroy()
		end)
	end
	FX.ScreenFlash(Color3.fromRGB(255, 240, 180), 0.35)
end

function ELEMENT.void(point, normal, s)
	local hole = basePart({ Shape = Enum.PartType.Ball, Material = Enum.Material.SmoothPlastic, Color = Color3.new(0, 0, 0), Size = Vector3.one, CFrame = CFrame.new(point + normal * s * 0.5) })
	local grow = TweenService:Create(hole, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Size = Vector3.one * s * 1.6 })
	grow:Play()
	grow.Completed:Connect(function()
		local shrink = TweenService:Create(hole, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = Vector3.one * 0.1 })
		shrink:Play()
		shrink.Completed:Connect(function()
			hole:Destroy()
			expandAndFade(neonBall(point, s * 0.3, Color3.fromRGB(190, 90, 255), 0), Vector3.one * s * 4, 0.8)
		end)
	end)
	-- Rings collapsing inwards.
	for k = 0, 2 do
		task.delay(k * 0.2, function()
			local p = basePart({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Color = Color3.fromRGB(170, 70, 255), Transparency = 0.2, Size = Vector3.new(0.8, s * 5, s * 5), CFrame = CFrame.lookAt(point, point + normal) * CFrame.Angles(0, math.rad(90), 0) })
			local t = TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.new(0.8, 1, 1), Transparency = 0.8 })
			t:Play()
			t.Completed:Connect(function()
				p:Destroy()
			end)
		end)
	end
end

function ELEMENT.nova(point, normal, s)
	local colors = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 230, 120) }
	for k = 1, 3 do
		task.delay((k - 1) * 0.18, function()
			ring(point + normal * 3, normal, s * 0.5, s * (5 + k * 2), colors[k], 1.2, 0.1)
		end)
	end
	ELEMENT.solar(point, normal, s * 0.8)
end

-- Meteor impact on a planet: flash, shockwave, debris of the planet's crust, dust, then the
-- element effect of the meteor. `p.crater` is the radius of the crater carved by the server.
function FX.Impact(p)
	local point, normal, color = p.point, p.normal, p.color or Color3.fromRGB(255, 150, 60)
	local s = p.crater or 40
	if p.crit then
		s *= 1.2
	end
	local crust = p.crustColor or Color3.fromRGB(110, 90, 80)

	-- 1) blinding flash
	expandAndFade(neonBall(point, s * 0.4, Color3.new(1, 1, 1), 0), Vector3.one * s * 2.6, 0.4)
	expandAndFade(neonBall(point, s * 0.6, color, 0.1), Vector3.one * s * 3.2, 0.9)
	light(point + normal * 20, color, 60, 1.2)
	-- 2) shockwaves along the surface
	ring(point + normal * 2, normal, s * 0.3, s * 4.5, Color3.fromRGB(255, 245, 220), 0.6, 0.1)
	ring(point + normal * 2, normal, s * 0.5, s * 7, color, 1.3, 0.4)
	-- 3) fire and a big dust cloud in the crust's color
	burst(point + normal * s * 0.2, {
		Texture = tex("Fire"),
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), color),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s * 0.45), NumberSequenceKeypoint.new(1, s * 0.05) }),
		Transparency = NumberSequence.new(0, 1),
		Lifetime = NumberRange.new(0.6, 1.3),
		Speed = NumberRange.new(s * 0.8, s * 2.2),
		SpreadAngle = Vector2.new(60, 60),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-90, 90),
		Drag = 3,
	}, 40, 2)
	burst(point + normal * s * 0.3, {
		Texture = tex("Smoke"),
		Color = ColorSequence.new(crust:Lerp(Color3.new(1, 1, 1), 0.2), crust:Lerp(Color3.new(0, 0, 0), 0.4)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s * 0.5), NumberSequenceKeypoint.new(1, s * 1.4) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(2.5, 4),
		Speed = NumberRange.new(s * 0.4, s * 1.1),
		SpreadAngle = Vector2.new(70, 70),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-30, 30),
		Drag = 1.2,
	}, 30, 5)
	-- 4) chunks of the planet flying out of the crater
	rocks(point, normal, p.crit and 30 or 20, s * 0.16, crust, s * 3.5, Enum.Material.Rock)
	rocks(point, normal, 8, s * 0.1, Color3.fromRGB(255, 120, 40), s * 2.5, Enum.Material.Neon)
	-- 5) the meteor's element
	local element = ELEMENT[p.impact]
	if element then
		element(point, normal, s)
	end
	damageNumber(point + normal * s * 1.2, p.damage, p.crit, color)

	local isMine = p.thrower == player.UserId
	FX.Shake(isMine and (p.crit and 6 or 3.5) or 0.6, isMine and 0.9 or 0.3)
	if isMine and p.crit then
		FX.ScreenFlash(Color3.fromRGB(255, 240, 200), 0.45)
	end
	Sfx.Play(p.crit and "Crit" or "Impact", isMine and 0.9 or 0.35)
end

-- A layer of the planet broke (mantle or core exposed).
function FX.Layer(p)
	local r = p.radius
	local color = p.layer == 2 and Color3.fromRGB(255, 120, 30) or p.color
	ring(p.center, Vector3.new(0, 1, 0), r, r * 3.5, color, 1.6, 0.3)
	ring(p.center, Vector3.new(1, 0.3, 0).Unit, r, r * 3, Color3.new(1, 1, 1), 1.4, 0.5)
	FX.Shake(1.5, 0.6)
end

function FX.Supernova(p)
	local r = p.radius
	expandAndFade(neonBall(p.center, r * 0.6, Color3.new(1, 1, 1), 0), Vector3.one * r * 4, 2.2, Enum.EasingStyle.Quint)
	expandAndFade(neonBall(p.center, r * 1.4, p.color, 0.2), Vector3.one * r * 3.4, 3.2, Enum.EasingStyle.Quint)
	ring(p.center, Vector3.new(0, 1, 0), r, r * 7, p.color, 3)
	ring(p.center, Vector3.new(1, 0.2, 0.3).Unit, r, r * 6, Color3.new(1, 1, 1), 2.5, 0.3)
	ring(p.center, Vector3.new(-0.4, 0.3, 1).Unit, r, r * 5.5, Color3.fromRGB(255, 120, 40), 3, 0.4)
	-- The planet shatters into chunks of crust and lava.
	for _ = 1, 90 do
		local dir = rng:NextUnitVector()
		local lava = rng:NextNumber() < 0.3
		rocks(p.center + dir * r * rng:NextNumber(0.6, 1), dir, 1, r * rng:NextNumber(0.06, 0.16),
			lava and Color3.fromRGB(255, 120, 40) or p.crustColor or Color3.fromRGB(110, 90, 80), r * rng:NextNumber(1.5, 3),
			lava and Enum.Material.Neon or Enum.Material.Rock)
	end
	FX.Shake(5, 1.6)
	FX.ScreenFlash(Color3.new(1, 1, 1), 0.85)
	Sfx.Play("PlanetExplode", 1)
end

-- Space-time rift: a jagged tear opens in space, a void disc spins behind it, the planet bursts
-- out of it in a flash of light, then the rift closes.
function FX.Rift(p)
	local center, r = p.center, p.radius
	local toMap = Vector3.new(-center.X, 0, -center.Z).Unit
	local frame = CFrame.lookAt(center + toMap * r * 1.1, center + toMap * r * 3)
	local color = p.color or Color3.fromRGB(200, 120, 255)
	local parts = {}

	local void = basePart({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.SmoothPlastic, Color = Color3.new(0, 0, 0), Size = Vector3.new(2, 1, 1), CFrame = frame * CFrame.Angles(0, math.rad(90), 0) })
	local rim = basePart({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Color = color, Transparency = 0.2, Size = Vector3.new(1, 1, 1), CFrame = frame * CFrame.new(0, 0, 1.5) * CFrame.Angles(0, math.rad(90), 0) })
	table.insert(parts, void)
	table.insert(parts, rim)
	-- The tear: a vertical zigzag of glowing cracks.
	local tear = {}
	local h = r * 2.6
	local x = 0
	for i = 1, 14 do
		local y0 = -h / 2 + (i - 1) * h / 14
		local nx = (i % 2 == 0 and 1 or -1) * rng:NextNumber(r * 0.05, r * 0.16)
		local a = Vector3.new(x, y0, -3)
		local b = Vector3.new(nx, y0 + h / 14, -3)
		x = nx
		local seg = basePart({
			Material = Enum.Material.Neon,
			Color = Color3.new(1, 1, 1):Lerp(color, 0.3),
			Size = Vector3.new(r * 0.035, r * 0.035, 0.1),
			CFrame = frame * CFrame.lookAt((a + b) / 2, b),
		})
		table.insert(tear, { part = seg, length = (b - a).Magnitude })
		table.insert(parts, seg)
	end
	for i, t in ipairs(tear) do
		task.delay(i * 0.04, function()
			TweenService:Create(t.part, TweenInfo.new(0.25), { Size = Vector3.new(r * 0.035, r * 0.035, t.length) }):Play()
		end)
	end
	TweenService:Create(void, TweenInfo.new(p.open, Enum.EasingStyle.Quart), { Size = Vector3.new(2, r * 1.6, r * 1.6) }):Play()
	TweenService:Create(rim, TweenInfo.new(p.open, Enum.EasingStyle.Quart), { Size = Vector3.new(1, r * 1.75, r * 1.75) }):Play()
	local spark = basePart({ Transparency = 1, Size = Vector3.new(r * 1.2, r * 2.4, 1), CFrame = frame })
	local e = Instance.new("ParticleEmitter")
	e.Texture = tex("Spark")
	e.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	e.LightEmission = 1
	e.Size = NumberSequence.new(r * 0.03, 0)
	e.Lifetime = NumberRange.new(1, 2)
	e.Speed = NumberRange.new(r * 0.1, r * 0.3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 80
	e.Parent = spark
	table.insert(parts, spark)
	FX.Shake(1, 0.8)

	-- The planet bursts out.
	task.delay(p.open, function()
		expandAndFade(neonBall(center, r * 0.4, Color3.new(1, 1, 1), 0), Vector3.one * r * 2.4, 1.2)
		expandAndFade(neonBall(center, r * 2, color, 0.3), Vector3.one * r * 2.8, 1.6)
		ring(center, toMap, r, r * 4, color, 1.5, 0.2)
		FX.Shake(2, 0.8)
		Sfx.Play("PlanetExplode", 0.4)
	end)
	-- The rift closes.
	task.delay(p.close, function()
		e.Enabled = false
		for _, part in ipairs(parts) do
			if part.Parent then
				local t = TweenService:Create(part, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Size = Vector3.new(part.Size.X, 0.1, 0.1), Transparency = 1 })
				t:Play()
				t.Completed:Connect(function()
					part:Destroy()
				end)
			end
		end
	end)
end

--[[
	Animated meteor flight. Returns a handle:
	  handle.model, handle:SetTarget(point), handle.Done (BindableEvent.Event), handle:GetPosition()
]]
function FX.Flight(opts)
	local model = MeteorVisual.Build(opts.meteorType, {
		size = opts.size or 5,
		expression = "furious",
		mutation = opts.mutation,
	})
	local core = model.PrimaryPart
	core.CFrame = CFrame.new(opts.from)
	local def = Meteors.ByID[opts.meteorType]
	local c1 = def and def.fire[1] or Color3.fromRGB(255, 160, 60)
	local c2 = def and def.fire[2] or Color3.fromRGB(255, 60, 20)
	local size = opts.size or 5

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, size * 0.45, 0)
	a0.Parent = core
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -size * 0.45, 0)
	a1.Parent = core
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 230), c2)
	trail.LightEmission = 1
	trail.Lifetime = 0.45
	trail.MinLength = 0
	trail.FaceCamera = true
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	trail.Parent = core
	local fireTrail = Instance.new("ParticleEmitter")
	fireTrail.Texture = tex("Fire")
	fireTrail.Color = ColorSequence.new(c1, c2)
	fireTrail.LightEmission = 1
	fireTrail.LightInfluence = 0
	fireTrail.Rate = 120
	fireTrail.Lifetime = NumberRange.new(0.3, 0.6)
	fireTrail.Speed = NumberRange.new(0, 4)
	fireTrail.SpreadAngle = Vector2.new(180, 180)
	fireTrail.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 1.2), NumberSequenceKeypoint.new(1, 0) })
	fireTrail.Transparency = NumberSequence.new(0.1, 1)
	fireTrail.Rotation = NumberRange.new(0, 360)
	fireTrail.Parent = core
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = tex("Spark")
	sparks.Color = ColorSequence.new(c1)
	sparks.LightEmission = 1
	sparks.Rate = 60
	sparks.Lifetime = NumberRange.new(0.4, 0.9)
	sparks.Speed = NumberRange.new(5, 15)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Size = NumberSequence.new(1.2, 0)
	sparks.Parent = core
	model.Parent = folder

	local done = Instance.new("BindableEvent")
	local handle = { model = model, Done = done.Event }
	local from, to = opts.from, opts.to
	local duration = opts.flightTime
	local start = os.clock()
	function handle:SetTarget(point)
		to = point
	end
	function handle:GetPosition()
		return core.Position
	end
	function handle:Progress()
		return math.clamp((os.clock() - start) / duration, 0, 1)
	end
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - start) / duration, 0, 1)
		local eased = t * t * (1.5 - 0.5 * t) -- accelerates into the planet
		local pos = PlanetMath.ArcPoint(from, to, eased)
		local ahead = PlanetMath.ArcPoint(from, to, math.min(1, eased + 0.02))
		local look = (ahead - pos).Magnitude > 0.01 and CFrame.lookAt(pos, ahead) or CFrame.new(pos)
		core.CFrame = look * CFrame.Angles(0, 0, os.clock() * 8)
		if t >= 1 then
			conn:Disconnect()
			handle.impact = to
			done:Fire(to)
			fireTrail.Enabled = false
			sparks.Enabled = false
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Transparency = 1
				elseif d:IsA("BillboardGui") or d:IsA("Fire") or d:IsA("PointLight") then
					d.Enabled = false
				end
			end
			task.delay(0.6, function()
				model:Destroy()
			end)
		end
	end)
	return handle
end

function FX:Init()
	folder = Instance.new("Folder")
	folder.Name = "LocalFX"
	folder.Parent = workspace
	local gui = Instance.new("ScreenGui")
	gui.Name = "ScreenFlash"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.Parent = player:WaitForChild("PlayerGui")
	screenFlash = Instance.new("Frame")
	screenFlash.Size = UDim2.fromScale(1, 1)
	screenFlash.BackgroundTransparency = 1
	screenFlash.BorderSizePixel = 0
	screenFlash.Parent = gui
end

function FX:Start()
	Remotes.Get("PlanetFX").OnClientEvent:Connect(function(p)
		if p.kind == "impact" then
			FX.Impact(p)
		elseif p.kind == "layer" then
			FX.Layer(p)
		elseif p.kind == "supernova" then
			FX.Supernova(p)
		elseif p.kind == "rift" then
			FX.Rift(p)
		end
	end)
	Remotes.Get("LaunchFX").OnClientEvent:Connect(function(p)
		FX.Flight(p)
	end)
	-- The Bifrost's cosmic glitch: random glass fragments flicker and change color (local only).
	task.spawn(function()
		local CollectionService = game:GetService("CollectionService")
		local colors = {
			Color3.fromRGB(80, 220, 255),
			Color3.fromRGB(255, 80, 200),
			Color3.fromRGB(255, 200, 90),
			Color3.fromRGB(150, 100, 255),
			Color3.fromRGB(235, 245, 255),
		}
		while true do
			local list = CollectionService:GetTagged("BifrostGlitch")
			for _ = 1, math.min(24, #list) do
				local p = list[rng:NextInteger(1, #list)]
				p.Transparency = rng:NextNumber() < 0.3 and 1 or rng:NextNumber(0.05, 0.6)
				if rng:NextNumber() < 0.4 then
					p.Color = colors[rng:NextInteger(1, #colors)]
				end
			end
			task.wait(0.07)
		end
	end)
	-- Ambient shake for everyone (the Launch controller applies its own during cinematics).
	RunService:BindToRenderStep("MeteorGodsShake", Enum.RenderPriority.Camera.Value + 1, function()
		if camera.CameraType ~= Enum.CameraType.Scriptable and os.clock() < shakeUntil then
			camera.CFrame = camera.CFrame * FX.ShakeOffset()
		end
	end)
end

return FX
