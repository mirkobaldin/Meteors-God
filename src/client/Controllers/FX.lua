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
	shakeStrength = math.max(shakeStrength, math.min(strength, 2.5) * 0.45) -- gentle: big shakes made people sick
	shakeUntil = math.max(shakeUntil, os.clock() + math.min(duration, 1))
end

-- Camera offset to apply this frame (used by the Launch controller and by FX itself).
function FX.ShakeOffset()
	if os.clock() > shakeUntil then
		shakeStrength = 0
		return CFrame.identity
	end
	-- Smooth (noise, not random jumps every frame) and fading out.
	local s = shakeStrength * math.clamp((shakeUntil - os.clock()) / 0.6, 0, 1)
	local t = os.clock() * 9
	return CFrame.Angles(math.noise(t, 0.3) * s * 0.012, math.noise(0.7, t) * s * 0.012, 0)
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

local function damageNumber(position, damage, crit, color, label)
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
	t.Text = (crit and "CRITICAL!\n" or "") .. (label and (label .. "\n") or "") .. Format.Number(damage)
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
	local isMine = p.thrower == player.UserId
	if isMine then -- only your own numbers: 12 players' numbers flood the screen
		damageNumber(point + normal * s * 1.2, p.damage, p.crit, color)
	end
	FX.Shake(isMine and (p.crit and 6 or 3.5) or 0.6, isMine and 0.9 or 0.3)
	if isMine and p.crit then
		FX.ScreenFlash(Color3.fromRGB(255, 240, 200), 0.45)
	end
	Sfx.Play(p.crit and "Crit" or "Impact", isMine and 0.9 or 0.35)
end

-- Ability bonus damage (chain strike, burn, poison): small blast + labelled number.
function FX.Bonus(p)
	local s = 18
	expandAndFade(neonBall(p.point, s * 0.5, p.color or Color3.new(1, 1, 1), 0.2), Vector3.one * s * 3, 0.5)
	if p.label == "Chain Lightning" or p.label == "Nova Blast" then
		for _ = 1, 4 do
			bolt(p.point + p.normal * s * rng:NextNumber(3, 6) + tangent(p.normal) * s * 2, p.point, Color3.fromRGB(255, 250, 170), 2, 0.3)
		end
	end
	if p.thrower == player.UserId then
		damageNumber(p.point + p.normal * 40 + tangent(p.normal) * 30, p.damage, false, p.color or Color3.new(1, 1, 1), p.label)
	end
end

-- Planet marked by an ability (Deep Freeze / Solar Flare): rings sweep across it.
function FX.Mark(p)
	local color = p.label == "Solar Flare" and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(150, 220, 255)
	for k = 0, 2 do
		task.delay(k * 0.25, function()
			ring(p.center, Vector3.new(0, 1, 0), p.radius * 2, p.radius * 2.6, color, 1.2, 0.5)
		end)
	end
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

-- A small planet breaks (Cosmic Hunt): glowing cracks race across it and its core swells for
-- `delay` seconds, then it blows apart into chunks of crust and lava.
function FX.Shatter(p)
	local center, r = p.center, p.radius
	local core = p.core or Color3.fromRGB(255, 200, 120)
	local delay = p.delay or 0.9
	local beams = {}
	for _ = 1, 14 do
		local dir = rng:NextUnitVector()
		local beam = basePart({
			Material = Enum.Material.Neon,
			Color = core,
			Size = Vector3.new(r * 0.05, r * 0.05, 0.1),
			CFrame = CFrame.lookAt(center, center + dir),
		})
		TweenService:Create(beam, TweenInfo.new(delay * rng:NextNumber(0.5, 0.9), Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = Vector3.new(r * 0.07, r * 0.07, r * 2.25),
			CFrame = CFrame.lookAt(center + dir * r * 1.1, center + dir * r * 3),
		}):Play()
		table.insert(beams, beam)
	end
	local glow = neonBall(center, r * 0.3, core, 0.3)
	TweenService:Create(glow, TweenInfo.new(delay, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.one * r * 1.6, Transparency = 0.1 }):Play()
	local near = (camera.CFrame.Position - center).Magnitude < r * 8
	if near then
		FX.Shake(1, delay)
	end
	task.delay(delay, function()
		for _, beam in ipairs(beams) do
			beam:Destroy()
		end
		glow:Destroy()
		expandAndFade(neonBall(center, r * 0.8, Color3.new(1, 1, 1), 0), Vector3.one * r * 3.2, 0.7)
		expandAndFade(neonBall(center, r * 1.4, core, 0.2), Vector3.one * r * 3.6, 1.4)
		ring(center, Vector3.new(0, 1, 0), r, r * 6, p.color or core, 1.4, 0.2)
		ring(center, rng:NextUnitVector(), r, r * 5, Color3.new(1, 1, 1), 1.1, 0.4)
		for _ = 1, 36 do
			local dir = rng:NextUnitVector()
			local lava = rng:NextNumber() < 0.3
			rocks(center + dir * r * rng:NextNumber(0.4, 0.9), dir, 1, r * rng:NextNumber(0.1, 0.24),
				lava and Color3.fromRGB(255, 120, 40) or (p.color or Color3.fromRGB(120, 100, 90)):Lerp(Color3.new(0, 0, 0), 0.35),
				r * rng:NextNumber(2, 4), lava and Enum.Material.Neon or Enum.Material.Rock)
		end
		burst(center, {
			Texture = tex("Smoke"),
			Color = ColorSequence.new(p.color or core),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, r * 0.5), NumberSequenceKeypoint.new(1, r * 1.3) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(1.5, 2.5),
			Speed = NumberRange.new(r * 0.8, r * 1.8),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 2,
		}, 30, 3)
		if near then
			FX.Shake(3, 0.8)
			FX.ScreenFlash(Color3.new(1, 1, 1), 0.35)
		end
		Sfx.Play("PlanetExplode", near and 0.8 or 0.3)
	end)
end

-- A new small planet materializes out of a blue flash (Cosmic Hunt).
function FX.Materialize(p)
	local center, r = p.center, p.radius
	expandAndFade(neonBall(center, r * 0.2, Color3.new(1, 1, 1), 0), Vector3.one * r * 2.4, 0.8)
	expandAndFade(neonBall(center, r * 2.6, Color3.fromRGB(60, 150, 255), 0.3), Vector3.one * r * 2.1, 1.2)
	ring(center, Vector3.new(0, 1, 0), r * 0.5, r * 4, Color3.fromRGB(200, 240, 255), 1, 0.3)
end

-- Space-time rift (vortex): a swirling vortex of clouds opens where the planet will be, with
-- spinning rings of violet light; rays and shards burst from its eye and the planet pushes out of
-- it, growing (a stand-in ball while the server builds the terrain), then the vortex fades.
local VORTEX = Color3.fromRGB(190, 120, 255)
local VORTEX_LIGHT = Color3.fromRGB(240, 220, 255)

local function vortexRing(holder, radius, color, width, count)
	local atts = {}
	for i = 1, count do
		local a = i / count * math.pi * 2
		local att = Instance.new("Attachment")
		att.Position = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
		att.Parent = holder
		table.insert(atts, att)
	end
	local beams = {}
	for i = 1, count do
		local beam = Instance.new("Beam")
		beam.Attachment0 = atts[i]
		beam.Attachment1 = atts[i % count + 1]
		beam.Color = ColorSequence.new(color)
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Width0 = width
		beam.Width1 = width
		beam.Transparency = NumberSequence.new(1)
		beam.FaceCamera = true
		beam.Segments = 1
		beam.Parent = holder
		table.insert(beams, beam)
	end
	return beams
end

local function fadeBeams(beams, to, time)
	local start = os.clock()
	task.spawn(function()
		local from = beams[1] and beams[1].Transparency.Keypoints[1].Value or 1
		while os.clock() - start < time do
			local k = (os.clock() - start) / time
			local v = from + (to - from) * k
			for _, b in ipairs(beams) do
				if b.Parent then
					b.Transparency = NumberSequence.new(v)
				end
			end
			task.wait()
		end
		for _, b in ipairs(beams) do
			if b.Parent then
				b.Transparency = NumberSequence.new(to)
			end
		end
	end)
end

function FX.Rift(p)
	local center, r = p.center, p.radius
	local toMap = Vector3.new(-center.X, 0, -center.Z).Unit
	local open = p.open or 2.4
	local close = p.close or open + 2.6
	-- The vortex lies in the plane facing the map; its local Y axis points at the players.
	local frame = CFrame.lookAt(center, center + toMap) * CFrame.Angles(math.rad(-90), 0, 0)
	local holder = basePart({ Transparency = 1, Size = Vector3.new(1, 1, 1), CFrame = frame })
	local clouds = basePart({ Transparency = 1, Size = Vector3.new(r * 3.2, 1, r * 3.2), CFrame = frame })
	-- Swirling clouds (locked to the part, which spins).
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = tex("Smoke")
	smoke.Shape = Enum.ParticleEmitterShape.Disc
	smoke.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	smoke.LockedToPart = true
	smoke.Color = ColorSequence.new(VORTEX_LIGHT, VORTEX)
	smoke.LightEmission = 0.4
	smoke.LightInfluence = 0
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 30), NumberSequenceKeypoint.new(1, math.min(r * 0.35, 100)) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.45), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(2, 3)
	smoke.Speed = NumberRange.new(0)
	smoke.Rotation = NumberRange.new(0, 360)
	smoke.RotSpeed = NumberRange.new(-40, 40)
	smoke.Rate = 40
	smoke.Parent = clouds
	-- Rings of light at three sizes, spinning at different speeds.
	local rings = {
		vortexRing(holder, r * 0.55, VORTEX_LIGHT, r * 0.03, 20),
		vortexRing(holder, r * 1.0, VORTEX, r * 0.045, 28),
		vortexRing(holder, r * 1.45, VORTEX, r * 0.03, 36),
	}
	for i, beams in ipairs(rings) do
		task.delay((i - 1) * 0.25, function()
			fadeBeams(beams, 0.15, 0.6)
		end)
	end
	-- The eye of the vortex.
	local eye = neonBall(center, r * 0.1, VORTEX_LIGHT, 0.2)
	TweenService:Create(eye, TweenInfo.new(open, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.one * r * 0.5, Transparency = 0.5 }):Play()
	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		holder.CFrame = frame * CFrame.Angles(0, t * 0.9, 0)
		clouds.CFrame = frame * CFrame.Angles(0, t * 0.5, 0)
	end)
	FX.Shake(0.6, 0.6)

	-- Rays and shards burst out of the eye, the planet pushes out of the vortex.
	task.delay(open * 0.55, function()
		for i = 1, 16 do
			local a = i / 16 * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
			local dir = frame:VectorToWorldSpace(Vector3.new(math.cos(a), 0, math.sin(a)))
			local ray = basePart({
				Material = Enum.Material.Neon,
				Color = i % 2 == 0 and VORTEX_LIGHT or VORTEX,
				Transparency = 0.2,
				Size = Vector3.new(r * 0.025, r * 0.025, 1),
				CFrame = CFrame.lookAt(center, center + dir),
			})
			local length = r * rng:NextNumber(1.6, 2.6)
			local tw = TweenService:Create(ray, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(r * 0.012, r * 0.012, length),
				CFrame = CFrame.lookAt(center + dir * length / 2, center + dir * length),
				Transparency = 1,
			})
			tw:Play()
			tw.Completed:Connect(function()
				ray:Destroy()
			end)
		end
		for _ = 1, 22 do
			local dir = (frame:VectorToWorldSpace(Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0, 0.8), rng:NextNumber(-1, 1)))).Unit
			local shard = basePart({
				Material = Enum.Material.Neon,
				Color = rng:NextNumber() < 0.5 and VORTEX or Color3.fromRGB(120, 200, 255),
				Size = Vector3.one * r * rng:NextNumber(0.03, 0.06),
				CFrame = CFrame.new(center) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
			})
			local tw = TweenService:Create(shard, TweenInfo.new(rng:NextNumber(1, 1.8), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = CFrame.new(center + dir * r * rng:NextNumber(1.2, 2.2)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
				Transparency = 1,
			})
			tw:Play()
			tw.Completed:Connect(function()
				shard:Destroy()
			end)
		end
		ring(center, toMap, r * 0.4, r * 2.6, VORTEX, 1.2, 0.5)
		-- Stand-in planet growing out of the eye (the terrain appears behind it).
		local ok, material = pcall(function()
			return Enum.Material[p.material]
		end)
		local proxy = basePart({
			Shape = Enum.PartType.Ball,
			Material = ok and material or Enum.Material.Rock,
			Color = p.crust or Color3.fromRGB(120, 110, 100),
			Size = Vector3.one * r * 0.2,
			CFrame = CFrame.new(center - toMap * r * 0.6),
		})
		TweenService:Create(proxy, TweenInfo.new(open * 0.45 + 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = clampSize(Vector3.one * r * 2.02),
			CFrame = CFrame.new(center),
		}):Play()
		task.delay(close - open * 0.55, function()
			fadeAndDestroy(proxy, 0, 1.2)
		end)
		FX.Shake(1, 0.5)
		Sfx.Play("PlanetExplode", 0.35)
	end)

	-- The vortex fades away.
	task.delay(close, function()
		smoke.Enabled = false
		for _, beams in ipairs(rings) do
			fadeBeams(beams, 1, 1)
		end
		fadeAndDestroy(eye, 0, 0.8)
		task.delay(3, function()
			conn:Disconnect()
			holder:Destroy()
			clouds:Destroy()
		end)
	end)
end

-- Storm around a meteor: rings of wind swirling around it and lightning arcs jumping off it.
-- Returns a handle: handle:SetIntensity(0..1), handle:Destroy(). Local only.
function FX.Storm(core, color)
	color = color or Color3.fromRGB(150, 220, 255)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Parent = folder
	local rings = {}
	for r = 1, 3 do
		local spin = Instance.new("Part")
		spin.Anchored = true
		spin.CanCollide = false
		spin.CanQuery = false
		spin.CanTouch = false
		spin.Transparency = 1
		spin.Size = Vector3.one
		spin.Parent = holder
		local atts = {}
		local n = 10
		for i = 1, n do
			local a = Instance.new("Attachment")
			a.Parent = spin
			atts[i] = a
		end
		-- A partial ring (swoosh): 7 of 10 segments, fading at both ends.
		for i = 1, 7 do
			local beam = Instance.new("Beam")
			beam.Attachment0 = atts[i]
			beam.Attachment1 = atts[i % n + 1]
			beam.FaceCamera = true
			beam.LightEmission = 0.7
			beam.Segments = 4
			beam.Color = ColorSequence.new(Color3.new(1, 1, 1):Lerp(color, 0.4))
			local k0, k1 = (i - 1) / 7, i / 7
			local function fade(k)
				return 0.15 + 0.85 * math.abs(k - 0.5) * 2
			end
			beam.Transparency = NumberSequence.new(fade(k0), fade(k1))
			beam.Parent = spin
		end
		rings[r] = { part = spin, atts = atts, tilt = CFrame.Angles(math.rad(25 + r * 40), math.rad(r * 70), 0), speed = 6 + r * 2.5 }
	end
	local intensity = 0.3
	local handle = {}
	local nextBolt = 0
	local conn = RunService.RenderStepped:Connect(function()
		if not core.Parent then
			return
		end
		local size = core.Size.X
		local pos = core.Position
		local t = os.clock()
		local radius = size * (0.75 + 0.35 * intensity)
		for _, ring in ipairs(rings) do
			ring.part.CFrame = CFrame.new(pos) * ring.tilt * CFrame.Angles(0, t * ring.speed * (0.5 + intensity), 0)
			for i, a in ipairs(ring.atts) do
				local ang = (i - 1) / #ring.atts * math.pi * 2
				a.Position = Vector3.new(math.cos(ang) * radius, 0, math.sin(ang) * radius)
			end
			for _, b in ipairs(ring.part:GetChildren()) do
				if b:IsA("Beam") then
					b.Width0 = size * (0.12 + 0.2 * intensity)
					b.Width1 = b.Width0
				end
			end
		end
		if t >= nextBolt then
			nextBolt = t + (0.35 - 0.27 * intensity) * rng:NextNumber(0.6, 1.4)
			local dir = rng:NextUnitVector()
			bolt(pos + dir * size * 0.45, pos + (dir + rng:NextUnitVector() * 0.6).Unit * size * rng:NextNumber(1.2, 2.2 + intensity),
				Color3.new(1, 1, 1):Lerp(color, 0.5), math.max(0.15, size * 0.05), 0.14)
		end
	end)
	function handle:SetIntensity(x)
		intensity = math.clamp(x, 0, 1)
	end
	function handle:Destroy()
		conn:Disconnect()
		holder:Destroy()
	end
	return handle
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
	local storm = FX.Storm(core, c1)
	storm:SetIntensity(1)
	local nextRing = 0
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - start) / duration, 0, 1)
		-- Shockwave rings of wind left behind the meteor.
		if os.clock() >= nextRing and t < 0.97 then
			nextRing = os.clock() + 0.07
			local p = core.Position
			local dirToTarget = (to - p).Magnitude > 1 and (to - p).Unit or Vector3.new(0, 0, 1)
			ring(p - dirToTarget * size, dirToTarget, size * 1.2, size * 5, Color3.new(1, 1, 1):Lerp(c1, 0.3), 0.45, 0.55)
		end
		local eased = t * t * (1.5 - 0.5 * t) -- accelerates into the planet
		local pos = PlanetMath.ArcPoint(from, to, eased)
		local ahead = PlanetMath.ArcPoint(from, to, math.min(1, eased + 0.02))
		local look = (ahead - pos).Magnitude > 0.01 and CFrame.lookAt(pos, ahead) or CFrame.new(pos)
		-- The face looks back at the chase camera, screaming, while the body rolls a little.
		core.CFrame = look * CFrame.Angles(0, math.pi, math.sin(os.clock() * 6) * 0.4)
		if t >= 1 then
			conn:Disconnect()
			storm:Destroy()
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
		elseif p.kind == "bonus" then
			FX.Bonus(p)
		elseif p.kind == "mark" then
			FX.Mark(p)
		elseif p.kind == "supernova" then
			FX.Supernova(p)
		elseif p.kind == "rift" then
			FX.Rift(p)
		end
	end)
	-- Family weapon hit: burst on the victim; the victim's own client applies the knockback.
	Remotes.Get("WeaponHit").OnClientEvent:Connect(function(p)
		local rarity = Meteors.RarityByID[p.rarity or ""]
		local color = rarity and rarity.color or Color3.fromRGB(255, 200, 120)
		expandAndFade(neonBall(p.position, 2, Color3.new(1, 1, 1), 0), Vector3.one * 12, 0.35)
		ring(p.position, Vector3.new(0, 1, 0), 2, 22, color, 0.5, 0.2)
		rocks(p.position, p.direction + Vector3.new(0, 0.6, 0), 8, 1.2, color, 18, Enum.Material.Neon)
		Sfx.Play("Impact", 0.6)
		if p.victim == player.UserId then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local Game_ = require(Shared.Config.Game)
				root.AssemblyLinearVelocity = p.direction * Game_.Weapons.Knockback + Vector3.new(0, 35, 0)
			end
			FX.Shake(2, 0.4)
			FX.ScreenFlash(Color3.fromRGB(255, 60, 60), 0.35)
		elseif p.attacker == player.UserId then
			FX.Shake(1, 0.25)
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
	-- Cosmic events tint the world a little (local ColorCorrection).
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "MG_EventTint"
	tint.Parent = game:GetService("Lighting")
	local function applyTint()
		local Game = require(Shared.Config.Game)
		local event = Game.EventByID[workspace:GetAttribute("CosmicEvent") or ""]
		TweenService:Create(tint, TweenInfo.new(2), { TintColor = event and event.tint or Color3.new(1, 1, 1) }):Play()
	end
	workspace:GetAttributeChangedSignal("CosmicEvent"):Connect(applyTint)
	applyTint()
	-- Ambient shake for everyone (the Launch controller applies its own during cinematics).
	RunService:BindToRenderStep("MeteorGodsShake", Enum.RenderPriority.Camera.Value + 1, function()
		if camera.CameraType ~= Enum.CameraType.Scriptable and os.clock() < shakeUntil then
			camera.CFrame = camera.CFrame * FX.ShakeOffset()
		end
	end)
end

return FX
