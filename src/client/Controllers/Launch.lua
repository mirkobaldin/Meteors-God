-- The launch, client side.
-- Step on a LAUNCH pad of a lane -> you rise above the void facing that lane's planet. A 3D target
-- marker shows exactly where the meteor will land and a dotted arc shows its path. HOLD to charge:
-- the needle runs back and forth on the ring, RELEASE inside the small golden zone for a critical
-- (the zone moves every throw). The camera chases the meteor and holds on the crater it leaves.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Planets = require(Shared.Config.Planets)
local Evolutions = require(Shared.Config.Evolutions)
local Remotes = require(Shared.Remotes)
local MeteorVisual = require(Shared.MeteorVisual)
local PlanetMath = require(Shared.Util.PlanetMath)
local PlanetInfo = require(Shared.Util.PlanetInfo)

local UI = require(script.Parent.UI)
local Anim = require(script.Parent.Anim)
local Sfx = require(script.Parent.Sfx)
local FX = require(script.Parent.FX)
local State = require(script.Parent.State)

local Launch = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controllers

local L = Game.Launch
local SEGMENTS = 36
local DOTS = 22

-- idle | aiming | flying | cinematic
local state = "idle"
local nextTryAt = 0
local launchData -- server answer to BeginLaunch
local serverReady = false
local pendingRelease = false
local constraints = {}
local ap, ao -- AlignPosition / AlignOrientation
local holding = false
local chargeT, charge = 0, 0
local aimStart = 0
local liftFrom, liftTo
local reticlePos = Vector2.zero
local aimPoint, predicted, predictedNormal
local tier = 1
local flight -- FX.Flight handle
local cinematic = {}
local refs = {}
local marker, markerDot
local dots = {}
local baseFov = 70

-- Helpers ------------------------------------------------------------------------

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end

local function planet()
	return PlanetInfo.Get(tier)
end

local function planetCenter()
	local info = planet()
	return info and info.center or Planets.Tiers[tier].position
end

local function planetRadius()
	local info = planet()
	return info and info.radius or Planets.Tiers[tier].radius
end

local function padAt(position)
	local world = workspace:FindFirstChild("World")
	local pads = world and world:FindFirstChild("LaunchPads")
	if not pads then
		return nil
	end
	for _, pad in ipairs(pads:GetChildren()) do
		if pad:GetAttribute("Tier") then
			local p = pad.Position
			local flat = Vector3.new(position.X - p.X, 0, position.Z - p.Z)
			if flat.Magnitude <= Game.World.LaunchPadRadius and math.abs(position.Y - p.Y) < 10 then
				return pad
			end
		end
	end
	return nil
end

-- True when at least one altar meteor is off cooldown (avoids pointless lift-offs).
local function hasReadyMeteor()
	local snap = State.Snapshot
	if not snap then
		return true
	end
	for uid, m in pairs(snap.meteors) do
		if m.altar and State.CooldownLeft(uid) <= 0 then
			return true
		end
	end
	return false
end

local function heldMeteor()
	return workspace:FindFirstChild("Launch_" .. player.Name)
end

local function throwOrigin()
	local model = heldMeteor()
	if model and model.PrimaryPart then
		return model.PrimaryPart.Position
	end
	local root = getRoot()
	return root and (root.Position + Vector3.new(0, 7, 0)) or Vector3.zero
end

local function chargeHeld()
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		or UserInputService:IsKeyDown(Enum.KeyCode.Space)
		or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR2)
end

-- Where the meteor will land: follows the real terrain (craters included), like the server.
local function predictImpact(origin, aim)
	local center, radius = planetCenter(), planetRadius()
	local folder = PlanetInfo.Folder(tier)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain, folder and folder:FindFirstChild("Core") or workspace.Terrain }
	local function cast(dir)
		local r = workspace:Raycast(origin, dir * ((center - origin).Magnitude + radius * 1.5), params)
		if r and (r.Position - center).Magnitude <= radius * 1.5 then
			return r.Position
		end
		return nil
	end
	local delta = aim - origin
	local dir = delta.Magnitude > 1e-3 and delta.Unit or (center - origin).Unit
	local hit = cast(dir)
	if not hit then
		local snapped = PlanetMath.ImpactFromAim(origin, aim, center, radius)
		hit = cast((snapped - origin).Unit) or snapped
	end
	return hit, (hit - center).Unit
end

local function inCritZone(value)
	return launchData ~= nil and value >= launchData.critFrom and value <= launchData.critTo
end

local function clearConstraints()
	for _, c in ipairs(constraints) do
		if c.Parent then
			c:Destroy()
		end
	end
	constraints = {}
	ap, ao = nil, nil
	local _, humanoid = getRoot()
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
	end
end

local function setAimUI(visible)
	refs.reticle.Visible = visible
	refs.hint.Visible = visible
	refs.cancel.Visible = visible
	marker.Parent = visible and camera or nil
	for _, d in ipairs(dots) do
		d.Parent = visible and camera or nil
	end
	UserInputService.MouseIconEnabled = not visible
end

local GOLD = Color3.fromRGB(255, 210, 60)

local function paintRing()
	local lit = math.floor(charge * SEGMENTS + 0.5)
	for i, seg in ipairs(refs.segments) do
		local v = (i - 0.5) / SEGMENTS
		local crit = inCritZone(v)
		local isNeedle = i == math.max(1, lit)
		if isNeedle and holding then
			seg.BackgroundColor3 = Color3.new(1, 1, 1)
			seg.BackgroundTransparency = 0
			seg.Size = UDim2.fromOffset(9, 22)
		else
			seg.Size = UDim2.fromOffset(6, 13)
			if i <= lit then
				seg.BackgroundColor3 = crit and GOLD or Color3.fromRGB(120, 220, 255)
				seg.BackgroundTransparency = 0
			else
				seg.BackgroundColor3 = crit and GOLD or Color3.fromRGB(255, 255, 255)
				seg.BackgroundTransparency = crit and 0.15 or 0.8
			end
		end
	end
	local ready = holding and inCritZone(charge)
	refs.center.BackgroundColor3 = ready and GOLD or Color3.new(1, 1, 1)
	marker.Color = ready and GOLD or Color3.fromRGB(255, 90, 70)
end

-- Leaving the launch ------------------------------------------------------------

local function finish()
	local root = getRoot()
	clearConstraints()
	Anim.Stop("Hover")
	Anim.Stop("Charge")
	Sfx.Stop("ChargeLoop")
	setAimUI(false)
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = baseFov
	if root and launchData and launchData.returnCFrame then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = launchData.returnCFrame
	end
	launchData = nil
	flight = nil
	holding = false
	pendingRelease = false
	serverReady = false
	state = "idle"
	nextTryAt = os.clock() + 1
end

local function cancel(reason)
	if state ~= "aiming" then
		return
	end
	Remotes.Get("CancelLaunch"):FireServer()
	if reason then
		controllers.Notifications.Toast(reason, "bad")
	end
	finish()
end

-- Throw ------------------------------------------------------------------------

local function release()
	if state ~= "aiming" then
		return
	end
	if not serverReady then
		pendingRelease = true -- fire as soon as the server confirms
		holding = false
		return
	end
	state = "flying"
	holding = false
	setAimUI(false)
	Anim.Stop("Charge", 0.05)
	Anim.Stop("Hover", 0.05)
	Anim.Play("Throw", false, 0.05)
	Sfx.Stop("ChargeLoop")
	Sfx.Play("Throw")

	local origin = throwOrigin()
	local aim = aimPoint or planetCenter()
	Remotes.Get("FireLaunch"):FireServer(charge, aim)

	-- Hide the held meteor locally: our own flight replaces it right away.
	local held = heldMeteor()
	if held then
		for _, d in ipairs(held:GetDescendants()) do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = 1
			elseif d:IsA("BillboardGui") or d:IsA("Fire") or d:IsA("PointLight") or d:IsA("ParticleEmitter") then
				d.Enabled = false
			end
		end
	end

	local target = predicted or PlanetMath.ImpactFromAim(origin, aim, planetCenter(), planetRadius())
	flight = FX.Flight({
		meteorType = launchData.meteorType,
		mutation = launchData.mutation,
		size = math.max(launchData.size * 1.6, 9),
		from = origin,
		to = target,
		flightTime = PlanetMath.FlightTime((target - origin).Magnitude),
	})
	cinematic = { start = os.clock(), crit = inCritZone(charge) }
	if cinematic.crit then
		refs.critText.TextTransparency = 0
		refs.critText.TextStrokeTransparency = 0
		TweenService:Create(refs.critText, TweenInfo.new(1.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end
	TweenService:Create(camera, TweenInfo.new(0.15), { FieldOfView = baseFov + 10 }):Play()

	flight.Done:Connect(function(impact)
		if state ~= "flying" then
			return
		end
		state = "cinematic"
		cinematic.impact = impact
		cinematic.impactAt = os.clock()
		if cinematic.crit then
			Anim.Play("Celebrate")
		end
	end)
	-- Safety net.
	local myFlight = flight
	task.delay(L.FlightMax + 5, function()
		if flight == myFlight and state ~= "idle" then
			finish()
		end
	end)
end

local function beginHold()
	if state ~= "aiming" or holding then
		return
	end
	holding = true
	chargeT = 0
	Anim.Play("Charge", true)
	Sfx.Play("ChargeLoop", 0.4)
end

-- Entering the launch -------------------------------------------------------------

local function enterAim(pad)
	local root, humanoid = getRoot()
	if not root or not humanoid then
		return
	end
	tier = pad:GetAttribute("Tier") or 1
	player:SetAttribute("FocusTier", tier)
	state = "aiming"
	serverReady = false
	pendingRelease = false
	holding = false
	charge, chargeT = 0, 0
	aimStart = os.clock()
	baseFov = camera.FieldOfView
	launchData = nil

	-- Fast, rigid lift-off (tweened target for a smooth but quick rise).
	local att = Instance.new("Attachment")
	att.Name = "LaunchAttachment"
	att.Parent = root
	ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.RigidityEnabled = true
	ap.Position = root.Position
	ap.Parent = root
	ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = math.huge
	ao.Responsiveness = 25
	local center = planetCenter()
	local flatDir = Vector3.new(center.X - root.Position.X, 0, center.Z - root.Position.Z).Unit
	ao.CFrame = CFrame.lookAt(Vector3.zero, flatDir)
	ao.Parent = root
	constraints = { att, ap, ao }
	liftFrom = root.Position
	liftTo = root.Position + Vector3.new(0, L.HoverHeight, 0)
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	local viewport = camera.ViewportSize
	reticlePos = Vector2.new(viewport.X / 2, viewport.Y * 0.42)
	camera.CameraType = Enum.CameraType.Scriptable
	setAimUI(true)
	paintRing()
	Anim.Play("Hover", true)
	-- Already holding the button when stepping on the pad: start charging right away.
	if chargeHeld() then
		beginHold()
	end

	task.spawn(function()
		local ok, result = pcall(function()
			return Remotes.Get("BeginLaunch"):InvokeServer()
		end)
		if state ~= "aiming" then
			return
		end
		if not ok or not result or not result.ok then
			cancel(ok and result and result.reason or nil)
			nextTryAt = os.clock() + 2.5
			return
		end
		launchData = result
		serverReady = true
		refs.meteorName.Text = (result.mutation and (result.mutation .. " ") or "") .. result.meteorType
		if pendingRelease then
			release()
		end
	end)
end

-- Per-frame update ---------------------------------------------------------------

local function updateAiming(dt)
	local root = getRoot()
	if not root or not ap then
		return
	end
	local t = os.clock()
	-- Rise, then float with a gentle sway.
	local rise = math.clamp((t - aimStart) / L.RiseTime, 0, 1)
	local eased = 1 - (1 - rise) ^ 3
	ap.Position = liftFrom:Lerp(liftTo, eased)
		+ Vector3.new(math.sin(t * 1.3) * 0.8 * rise, math.sin(t * 2) * 0.8 * rise, 0)

	local center = planetCenter()
	local radius = planetRadius()
	local viewport = camera.ViewportSize
	local offset = (reticlePos - viewport / 2) / viewport

	-- Crosshair -> aim point (on the planet sphere, or in space beside it).
	local ray = camera:ViewportPointToRay(reticlePos.X, reticlePos.Y)
	local hit = PlanetMath.Intersect(ray.Origin, ray.Direction, center, radius)
	aimPoint = hit or (ray.Origin + ray.Direction * (center - ray.Origin).Magnitude)
	refs.reticleStroke.Color = hit and Color3.fromRGB(255, 120, 90) or Color3.fromRGB(255, 255, 255)
	refs.reticle.Position = UDim2.fromOffset(reticlePos.X, reticlePos.Y)

	-- The god turns towards the target and leans back while charging.
	local aimDir = (aimPoint - root.Position).Unit
	local flat = Vector3.new(aimDir.X, 0, aimDir.Z)
	if flat.Magnitude > 0.01 then
		ao.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit) * CFrame.Angles(math.rad(10 * charge), 0, 0)
	end

	-- Camera: pulled back over the shoulder, the god in the lower-left of the screen,
	-- drifting towards the crosshair so you can aim across the whole planet.
	local toPlanet = (center - root.Position).Unit
	local right = toPlanet:Cross(Vector3.new(0, 1, 0)).Unit
	local camPos = root.Position - toPlanet * 34 + Vector3.new(0, 11, 0) + right * 11
	local lookAt = center + right * offset.X * radius * 2.2 - Vector3.new(0, 1, 0) * offset.Y * radius * 1.8
	camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camPos, lookAt), math.min(1, dt * 10)) * FX.ShakeOffset()
	camera.FieldOfView = baseFov - 6 * charge

	-- 3D target marker on the surface + dotted arc to it.
	local origin = throwOrigin()
	predicted, predictedNormal = predictImpact(origin, aimPoint)
	local markerSize = radius * 0.16 * (1 + math.sin(t * 6) * 0.06)
	marker.Size = Vector3.new(1.5, markerSize, markerSize)
	marker.CFrame = CFrame.lookAt(predicted + predictedNormal * 3, predicted + predictedNormal * 10) * CFrame.Angles(0, math.rad(90), 0)
	markerDot.Size = Vector3.new(2, markerSize * 0.25, markerSize * 0.25)
	markerDot.CFrame = marker.CFrame * CFrame.new(0.3, 0, 0)
	for i, dot in ipairs(dots) do
		local k = i / (DOTS + 1)
		local world = PlanetMath.ArcPoint(origin, predicted, k)
		local d = (world - camera.CFrame.Position).Magnitude
		local s = math.clamp(d * 0.006, 0.6, 18)
		dot.Size = Vector3.new(s, s, s)
		dot.CFrame = CFrame.new(world)
		dot.Transparency = 0.15 + 0.5 * k
	end

	-- Charge: the needle runs 0 -> 1 -> 0 so timing matters.
	if holding then
		chargeT += dt
		local phase = (chargeT / L.ChargePeriod) % 2
		charge = phase <= 1 and phase or 2 - phase
		local model = heldMeteor()
		if model and model.PrimaryPart and launchData then
			MeteorVisual.SetSize(model, launchData.size * (1 + 0.7 * charge))
		end
		FX.Shake(0.3 + charge * 1, 0.1)
	end
	paintRing()

	if t - aimStart > L.MaxHoldTime - 0.5 then
		if charge == 0 then
			charge = 0.5
		end
		release()
	end
end

local function updateFlight(dt)
	if not flight then
		return
	end
	local pos = flight:GetPosition()
	local center = planetCenter()
	local radius = planetRadius()
	if state == "flying" then
		-- Chase cam close behind the meteor, then a wide shot of the impact area.
		local p = flight:Progress()
		local travel = (center - pos).Unit
		local shot = CFrame.lookAt(pos - travel * 26 + Vector3.new(0, 7, 0), pos + travel * 80)
		local target = cinematic.target or (predicted or pos)
		if p > 0.65 then
			local normal = (target - center).Unit
			local side = normal:Cross(Vector3.new(0, 1, 0))
			side = side.Magnitude > 0.1 and side.Unit or Vector3.new(1, 0, 0)
			local shotPos = target + normal * radius * 0.55 + side * radius * 0.35 + Vector3.new(0, radius * 0.1, 0)
			shot = CFrame.lookAt(shotPos, pos:Lerp(target, 0.5))
		end
		camera.CFrame = camera.CFrame:Lerp(shot, math.min(1, dt * 7)) * FX.ShakeOffset()
	elseif state == "cinematic" then
		-- Hold on the crater: slow orbit and push-in so you see the damage you did.
		local impact = cinematic.impact or pos
		local normal = (impact - center).Unit
		local side = normal:Cross(Vector3.new(0, 1, 0))
		side = side.Magnitude > 0.1 and side.Unit or Vector3.new(1, 0, 0)
		local age = os.clock() - (cinematic.impactAt or os.clock())
		local orbit = CFrame.fromAxisAngle(normal, age * 0.3)
		local dist = radius * (0.5 - math.min(age, 2) * 0.06)
		local shotPos = impact + normal * dist + orbit:VectorToWorldSpace(side) * dist * 0.6
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(shotPos, impact), math.min(1, dt * 4)) * FX.ShakeOffset()
		if age > 2.6 then
			finish()
		end
	end
end

-- UI ----------------------------------------------------------------------------------

local function worldPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	if props.Shape then
		p.Shape = props.Shape
	end
	for k, v in pairs(props) do
		if k ~= "Shape" then
			p[k] = v
		end
	end
	return p
end

local function buildUI()
	local gui = UI.Screen("Launch", 8)
	gui.IgnoreGuiInset = true

	local reticle = UI.New("Frame", {
		Name = "Reticle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(170, 170),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	refs.reticle = reticle
	local circle = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 1,
		Parent = reticle,
	})
	UI.Corner(UDim.new(1, 0)).Parent = circle
	refs.reticleStroke = UI.New("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Parent = circle })
	refs.center = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = reticle,
	})
	UI.Corner(UDim.new(1, 0)).Parent = refs.center
	-- Charge ring around the crosshair: the golden segments are the critical zone.
	refs.segments = {}
	for i = 1, SEGMENTS do
		local a = -math.pi / 2 + (i - 0.5) / SEGMENTS * math.pi * 2
		local seg = UI.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(a) * 66, 0.5, math.sin(a) * 66),
			Size = UDim2.fromOffset(6, 13),
			Rotation = math.deg(a) + 90,
			BorderSizePixel = 0,
			Parent = reticle,
		})
		UI.Corner(UDim.new(1, 0)).Parent = seg
		refs.segments[i] = seg
	end
	refs.meteorName = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 4),
		Size = UDim2.fromOffset(260, 22),
		Text = "",
		TextColor3 = UI.Colors.Gold,
		TextStrokeTransparency = 0.2,
		MaxTextSize = 18,
		Parent = reticle,
	})

	refs.hint = UI.Text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.fromOffset(660, 30),
		Text = "AIM with the red marker  ·  HOLD to charge  ·  RELEASE on the GOLD zone for a critical",
		TextStrokeTransparency = 0.2,
		MaxTextSize = 22,
		Visible = false,
		Parent = gui,
	})
	refs.cancel = UI.Button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -30),
		Size = UDim2.fromOffset(150, 44),
		Text = "Cancel (Q)",
		BackgroundColor3 = UI.Colors.PanelLight,
		TextColor3 = Color3.new(1, 1, 1),
		Visible = false,
		Parent = gui,
	}, function()
		cancel(nil)
	end)
	refs.critText = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(600, 90),
		Text = "CRITICAL!",
		TextColor3 = GOLD,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		MaxTextSize = 80,
		Parent = gui,
	})

	-- 3D aim helpers (local parts, parented to the camera while aiming).
	marker = worldPart({ Name = "AimMarker", Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 90, 70), Transparency = 0.35 })
	markerDot = worldPart({ Name = "AimDot", Shape = Enum.PartType.Cylinder, Color = Color3.new(1, 1, 1), Transparency = 0.1, Parent = marker })
	for i = 1, DOTS do
		dots[i] = worldPart({ Name = "ArcDot", Shape = Enum.PartType.Ball, Color = Color3.fromRGB(255, 225, 150) })
	end
end

-- The map is big: running on a Bifrost bridge is much faster.
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Exclude
local function updateBridgeBoost()
	local root, humanoid = getRoot()
	local base = player:GetAttribute("BaseWalkSpeed")
	if not root or not humanoid or not base then
		return
	end
	floorParams.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), floorParams)
	local onBridge = hit and hit.Instance and hit.Instance.Name == "Bifrost"
	humanoid.WalkSpeed = onBridge and base * Game.World.BridgeSpeedMultiplier or base
end

-- Lifecycle -----------------------------------------------------------------------------

local CHARGE_KEYS = {
	[Enum.KeyCode.Space] = true,
	[Enum.KeyCode.ButtonR2] = true,
	[Enum.KeyCode.ButtonA] = true,
}

function Launch:Init(c)
	controllers = c
	buildUI()
end

function Launch:Start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if state == "cinematic" and input.UserInputType == Enum.UserInputType.MouseButton1 then
			finish() -- click to skip the replay
			return
		end
		if state ~= "aiming" then
			return
		end
		if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then
			cancel(nil)
			return
		end
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch then
			reticlePos = Vector2.new(input.Position.X, input.Position.Y)
			beginHold()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or CHARGE_KEYS[input.KeyCode] then
			beginHold()
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if state ~= "aiming" then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			reticlePos = Vector2.new(input.Position.X, input.Position.Y)
		elseif input.KeyCode == Enum.KeyCode.Thumbstick1 or input.KeyCode == Enum.KeyCode.Thumbstick2 then
			local v = Vector2.new(input.Position.X, -input.Position.Y)
			if v.Magnitude > 0.15 then
				local viewport = camera.ViewportSize
				reticlePos = Vector2.new(
					math.clamp(reticlePos.X + v.X * 18, 0, viewport.X),
					math.clamp(reticlePos.Y + v.Y * 18, 0, viewport.Y)
				)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if state == "aiming" and holding then
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
				or CHARGE_KEYS[input.KeyCode]
			then
				release()
			end
		end
	end)

	Remotes.Get("LaunchResult").OnClientEvent:Connect(function(result)
		-- Snap our predicted flight onto the server's authoritative impact point.
		if flight and result.impact then
			flight:SetTarget(result.impact)
			cinematic.target = result.impact
		end
	end)

	player.CharacterAdded:Connect(function()
		if state ~= "idle" then
			constraints = {}
			ap, ao = nil, nil
			setAimUI(false)
			camera.CameraType = Enum.CameraType.Custom
			launchData = nil
			flight = nil
			state = "idle"
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if state == "idle" then
			updateBridgeBoost()
			if os.clock() < nextTryAt then
				return
			end
			local root = getRoot()
			local pad = root and padAt(root.Position)
			if not pad then
				return
			end
			nextTryAt = os.clock() + 0.25
			local padTier = pad:GetAttribute("Tier") or 1
			player:SetAttribute("FocusTier", padTier)
			local required = pad:GetAttribute("RequiredEvolution") or 1
			if (player:GetAttribute("Evolution") or 1) < required then
				nextTryAt = os.clock() + 3
				controllers.Notifications.Toast(
					Planets.Tiers[padTier].name .. " requires " .. Evolutions.Get(required).name .. "!",
					"bad"
				)
				return
			end
			if workspace:GetAttribute("CyclePhase") ~= "Bombard" then
				return
			end
			local info = PlanetInfo.Get(padTier)
			if not info or not info.ready then
				return
			end
			if hasReadyMeteor() then
				enterAim(pad)
			else
				nextTryAt = os.clock() + 2.5
				controllers.Notifications.Toast("No meteor ready: wait for the recharge!", "bad")
			end
		elseif state == "aiming" then
			updateAiming(dt)
		else
			updateFlight(dt)
		end
	end)
end

return Launch
