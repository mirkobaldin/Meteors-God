-- Client-side visual effects: meteor flights, planet impacts, crust plates flying into space,
-- mantle shatter, supernova and planet arrival. Everything is local (smooth, no replication cost).

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
	p.Size = Vector3.new(diameter, diameter, diameter)
	p.CFrame = CFrame.new(position)
	p.Parent = folder
	return p
end

local function expandAndFade(part, size, time, style)
	local t = TweenService:Create(part, TweenInfo.new(time, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = size,
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
	p.Size = Vector3.new(0.6, fromSize, fromSize)
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

-- Copies of removed crust plates flying into space.
local function flingPlates(tiles, center, speed)
	for _, data in ipairs(tiles or {}) do
		local p = Instance.new(data.wedge and "WedgePart" or "Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = data.size
		p.CFrame = data.cf
		p.Color = data.color
		p.Material = data.mat
		p.Parent = folder
		local out = (data.cf.Position - center)
		out = out.Magnitude > 0 and out.Unit or Vector3.new(0, 1, 0)
		local lateral = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) * 0.35
		local dist = rng:NextNumber(0.6, 1.4) * speed
		local spin = CFrame.Angles(rng:NextNumber(-4, 4), rng:NextNumber(-4, 4), rng:NextNumber(-4, 4))
		local time = rng:NextNumber(2.8, 4.5)
		local t = TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(data.cf.Position + (out + lateral).Unit * dist) * data.cf.Rotation * spin,
		})
		t:Play()
		TweenService:Create(p, TweenInfo.new(time * 0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, time * 0.6), {
			Transparency = 1,
		}):Play()
		t.Completed:Connect(function()
			p:Destroy()
		end)
	end
end

local function rocks(position, normal, count, size, color, speed)
	for _ = 1, count do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Slate
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

-- Meteor impact on the planet.
function FX.Impact(p)
	local point, normal, color = p.point, p.normal, p.color or Color3.fromRGB(255, 150, 60)
	local s = math.clamp(18 + math.log10(math.max(p.damage, 10)) * 16, 30, 160)
	if p.crit then
		s *= 1.35
	end
	local center = workspace:GetAttribute("PlanetCenter") or point - normal * 400

	-- 1) blinding flash
	expandAndFade(neonBall(point, s * 0.3, Color3.new(1, 1, 1), 0), Vector3.one * s * 2.2, 0.35)
	expandAndFade(neonBall(point, s * 0.5, color, 0.1), Vector3.one * s * 3, 0.7)
	light(point + normal * 20, color, 60, 1)
	-- 2) shockwaves along the surface
	ring(point + normal * 2, normal, s * 0.2, s * 5, Color3.fromRGB(255, 245, 220), 0.6, 0.1)
	ring(point + normal * 2, normal, s * 0.4, s * 8, color, 1.2, 0.35)
	-- 3) fire, smoke, sparks
	burst(point + normal * 6, {
		Texture = tex("Fire"),
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), color),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s * 0.35), NumberSequenceKeypoint.new(1, s * 0.05) }),
		Transparency = NumberSequence.new(0, 1),
		Lifetime = NumberRange.new(0.6, 1.3),
		Speed = NumberRange.new(s * 0.8, s * 2.2),
		SpreadAngle = Vector2.new(70, 70),
		EmissionDirection = Enum.NormalId.Top,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-90, 90),
		Drag = 3,
	}, 45, 2)
	burst(point + normal * 10, {
		Texture = tex("Smoke"),
		Color = ColorSequence.new(Color3.fromRGB(90, 80, 80), Color3.fromRGB(40, 35, 40)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s * 0.3), NumberSequenceKeypoint.new(1, s * 0.8) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(2, 3.5),
		Speed = NumberRange.new(s * 0.3, s * 0.9),
		SpreadAngle = Vector2.new(80, 80),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-30, 30),
		Drag = 1.5,
	}, 25, 4)
	burst(point + normal * 4, {
		Texture = tex("Spark"),
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 220), color),
		LightEmission = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.8, 1.8),
		Speed = NumberRange.new(s * 2, s * 4),
		SpreadAngle = Vector2.new(85, 85),
		Drag = 2,
	}, 70, 2.5)
	-- 4) the crust plates of the new crater + rocks
	flingPlates(p.tiles, center, 520)
	rocks(point, normal, p.crit and 22 or 14, s * 0.12, Color3.fromRGB(60, 50, 50), s * 3)
	damageNumber(point + normal * s * 0.6, p.damage, p.crit, color)

	local isMine = p.thrower == player.UserId
	FX.Shake(isMine and (p.crit and 6 or 3.5) or 0.6, isMine and 0.9 or 0.3)
	if isMine and p.crit then
		FX.ScreenFlash(Color3.fromRGB(255, 240, 200), 0.45)
	end
	Sfx.Play(p.crit and "Crit" or "Impact", isMine and 0.9 or 0.35)
end

function FX.Mantle(p)
	local r = p.radius
	expandAndFade(neonBall(p.center, r * 2, p.color, 0.1), Vector3.one * r * 3.2, 1.6)
	ring(p.center, Vector3.new(0, 1, 0), r, r * 6, p.color, 2)
	ring(p.center, Vector3.new(1, 0.3, 0).Unit, r, r * 5, Color3.new(1, 1, 1), 1.6, 0.4)
	local shards = {}
	for _ = 1, 40 do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
		table.insert(shards, {
			cf = CFrame.new(p.center + dir * r * 0.9) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
			size = Vector3.new(r * 0.3, r * 0.08, r * 0.25),
			color = p.color,
			mat = Enum.Material.Neon,
			wedge = true,
		})
	end
	flingPlates(shards, p.center, 700)
	FX.Shake(2, 0.8)
	FX.ScreenFlash(p.color, 0.25)
end

function FX.Supernova(p)
	local r = p.radius
	expandAndFade(neonBall(p.center, r * 0.6, Color3.new(1, 1, 1), 0), Vector3.one * r * 7, 2.5, Enum.EasingStyle.Quint)
	expandAndFade(neonBall(p.center, r * 0.8, p.color, 0.2), Vector3.one * r * 5, 3.5, Enum.EasingStyle.Quint)
	ring(p.center, Vector3.new(0, 1, 0), r, r * 12, p.color, 3)
	ring(p.center, Vector3.new(1, 0.2, 0.3).Unit, r, r * 10, Color3.new(1, 1, 1), 2.5, 0.3)
	ring(p.center, Vector3.new(-0.4, 0.3, 1).Unit, r, r * 9, p.mantleColor or p.color, 3, 0.4)
	flingPlates(p.tiles, p.center, 1400)
	FX.Shake(5, 1.6)
	FX.ScreenFlash(Color3.new(1, 1, 1), 0.85)
	Sfx.Play("PlanetExplode", 1)
end

function FX.Arrival(p)
	ring(p.center, Vector3.new(0, 1, 0), p.radius * 0.2, p.radius * 4, p.color, 1.5, 0.2)
	expandAndFade(neonBall(p.center, p.radius * 0.3, Color3.new(1, 1, 1), 0), Vector3.one * p.radius * 2.4, 1.2)
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
		elseif p.kind == "mantle" then
			FX.Mantle(p)
		elseif p.kind == "supernova" then
			FX.Supernova(p)
		elseif p.kind == "arrival" then
			FX.Arrival(p)
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
