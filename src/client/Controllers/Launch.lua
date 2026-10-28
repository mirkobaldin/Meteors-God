-- The launch, client side.
-- Step on a LAUNCH pad -> you instantly rise above the void, the camera frames the planet and a
-- crosshair appears. Aim with the mouse (or your finger), HOLD to charge the ring (gold = critical),
-- RELEASE to throw. The camera chases the meteor and gives a cinematic shot of the impact.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)
local MeteorVisual = require(Shared.MeteorVisual)
local PlanetMath = require(Shared.Util.PlanetMath)

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
local SEGMENTS = 28
local DOTS = 14

-- idle | aiming | flying | cinematic
local state = "idle"
local nextTryAt = 0
local launchData -- server answer to BeginLaunch
local serverReady = false
local pendingRelease = false
local constraints = {}
local ap -- AlignPosition
local holding = false
local chargeT, charge = 0, 0
local aimStart = 0
local liftFrom, liftTo
local reticlePos = Vector2.zero
local aimPoint
local flight -- FX.Flight handle
local cinematic = {}
local refs = {}
local baseFov = 70

-- Helpers ------------------------------------------------------------------------

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end

local function planetCenter()
	return workspace:GetAttribute("PlanetCenter") or Game.World.PlanetPosition
end

local function planetRadius()
	return workspace:GetAttribute("PlanetTargetRadius") or Game.World.PlanetRadius
end

local function onPad(position)
	local world = workspace:FindFirstChild("World")
	local pads = world and world:FindFirstChild("LaunchPads")
	if not pads then
		return false
	end
	for _, pad in ipairs(pads:GetChildren()) do
		local p = pad.Position
		local flat = Vector3.new(position.X - p.X, 0, position.Z - p.Z)
		if flat.Magnitude <= Game.World.LaunchPadRadius and math.abs(position.Y - p.Y) < 10 then
			return true
		end
	end
	return false
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

local function clearConstraints()
	for _, c in ipairs(constraints) do
		if c.Parent then
			c:Destroy()
		end
	end
	constraints = {}
	ap = nil
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
	for _, d in ipairs(refs.dots) do
		d.Visible = visible
	end
	UserInputService.MouseIconEnabled = not visible
end

local function paintRing()
	local lit = math.floor(charge * SEGMENTS + 0.5)
	for i, seg in ipairs(refs.segments) do
		local inCrit = (i / SEGMENTS) >= L.CritThreshold
		if i <= lit then
			seg.BackgroundColor3 = inCrit and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(120, 220, 255)
			seg.BackgroundTransparency = 0
		else
			seg.BackgroundColor3 = inCrit and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(255, 255, 255)
			seg.BackgroundTransparency = inCrit and 0.55 or 0.8
		end
	end
	refs.center.BackgroundColor3 = charge >= L.CritThreshold and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(255, 255, 255)
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
			elseif d:IsA("BillboardGui") or d:IsA("Fire") or d:IsA("PointLight") then
				d.Enabled = false
			end
		end
	end

	local predicted = PlanetMath.ImpactFromAim(origin, aim, planetCenter(), planetRadius())
	flight = FX.Flight({
		meteorType = launchData.meteorType,
		mutation = launchData.mutation,
		size = launchData.size,
		from = origin,
		to = predicted,
		flightTime = PlanetMath.FlightTime((predicted - origin).Magnitude),
	})
	cinematic = { start = os.clock(), crit = charge >= L.CritThreshold }
	if cinematic.crit then
		refs.critText.TextTransparency = 0
		refs.critText.TextStrokeTransparency = 0
		TweenService:Create(refs.critText, TweenInfo.new(1.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end
	TweenService:Create(camera, TweenInfo.new(0.15), { FieldOfView = baseFov + 8 }):Play()

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
	task.delay(L.FlightMax + 4, function()
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

local function enterAim()
	local root, humanoid = getRoot()
	if not root or not humanoid then
		return
	end
	state = "aiming"
	serverReady = false
	pendingRelease = false
	holding = false
	charge, chargeT = 0, 0
	aimStart = os.clock()
	baseFov = camera.FieldOfView
	launchData = nil

	-- Instant, rigid lift-off (tweened target for a smooth but fast rise).
	local att = Instance.new("Attachment")
	att.Name = "LaunchAttachment"
	att.Parent = root
	ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.RigidityEnabled = true
	ap.Position = root.Position
	ap.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.RigidityEnabled = true
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
	reticlePos = Vector2.new(viewport.X / 2, viewport.Y * 0.45)
	camera.CameraType = Enum.CameraType.Scriptable
	setAimUI(true)
	paintRing()
	Anim.Play("Hover", true)

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
	-- Rise, then gently bob above the void.
	local rise = math.clamp((os.clock() - aimStart) / L.RiseTime, 0, 1)
	local eased = 1 - (1 - rise) ^ 3
	ap.Position = liftFrom:Lerp(liftTo, eased) + Vector3.new(0, math.sin(os.clock() * 2) * 0.6 * rise, 0)

	-- Camera: over the shoulder, framing the planet, drifting towards the crosshair.
	local center = planetCenter()
	local viewport = camera.ViewportSize
	local offset = (reticlePos - viewport / 2) / viewport
	local toPlanet = (center - root.Position).Unit
	local right = toPlanet:Cross(Vector3.new(0, 1, 0)).Unit
	local camPos = root.Position - toPlanet * 20 + Vector3.new(0, 7, 0) + right * 5
	local lookAt = center + right * offset.X * 900 - Vector3.new(0, 1, 0) * offset.Y * 700
	local target = CFrame.lookAt(camPos, lookAt)
	camera.CFrame = camera.CFrame:Lerp(target, math.min(1, dt * 10)) * FX.ShakeOffset()
	camera.FieldOfView = baseFov - 8 * charge

	-- Crosshair -> aim point on the planet.
	local ray = camera:ViewportPointToRay(reticlePos.X, reticlePos.Y)
	local hit = PlanetMath.Intersect(ray.Origin, ray.Direction, center, planetRadius())
	if hit then
		aimPoint = hit
		refs.reticleStroke.Color = Color3.fromRGB(255, 120, 90)
	else
		aimPoint = ray.Origin + ray.Direction * (center - ray.Origin).Magnitude
		refs.reticleStroke.Color = Color3.fromRGB(255, 255, 255)
	end
	refs.reticle.Position = UDim2.fromOffset(reticlePos.X, reticlePos.Y)

	-- Trajectory preview dots.
	local origin = throwOrigin()
	local impact = PlanetMath.ImpactFromAim(origin, aimPoint, center, planetRadius())
	for i, dot in ipairs(refs.dots) do
		local t = i / (DOTS + 1)
		local world = PlanetMath.ArcPoint(origin, impact, t * 0.35)
		local screen, onScreen = camera:WorldToViewportPoint(world)
		dot.Visible = onScreen
		dot.Position = UDim2.fromOffset(screen.X, screen.Y)
		dot.BackgroundTransparency = 0.2 + t
	end

	-- Charge (ping-pong so timing matters).
	if holding then
		chargeT += dt
		local phase = (chargeT / L.ChargePeriod) % 2
		charge = phase <= 1 and phase or 2 - phase
		local model = heldMeteor()
		if model and model.PrimaryPart and launchData then
			MeteorVisual.SetSize(model, launchData.size * (1 + 0.7 * charge))
		end
		FX.Shake(0.4 + charge * 1.2, 0.1)
	end
	paintRing()

	if os.clock() - aimStart > L.MaxHoldTime - 0.5 then
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
	local travel = (center - pos).Unit
	if state == "flying" then
		-- Chase cam behind the meteor, then swing to a side shot just before impact.
		local p = flight:Progress()
		local chase = CFrame.lookAt(pos - travel * 30 + Vector3.new(0, 9, 0), pos + travel * 60)
		if p > 0.72 then
			local normal = (pos - center).Unit
			local side = normal:Cross(Vector3.new(0, 1, 0))
			side = side.Magnitude > 0.1 and side.Unit or Vector3.new(1, 0, 0)
			local shotPos = pos + normal * 120 + side * 160 + Vector3.new(0, 40, 0)
			chase = CFrame.lookAt(shotPos, pos)
		end
		camera.CFrame = camera.CFrame:Lerp(chase, math.min(1, dt * 8)) * FX.ShakeOffset()
	elseif state == "cinematic" then
		local impact = cinematic.impact or pos
		local normal = (impact - center).Unit
		local side = normal:Cross(Vector3.new(0, 1, 0))
		side = side.Magnitude > 0.1 and side.Unit or Vector3.new(1, 0, 0)
		local age = os.clock() - (cinematic.impactAt or os.clock())
		local orbit = CFrame.fromAxisAngle(normal, age * 0.25)
		local shotPos = impact + normal * (220 + age * 60) + orbit:VectorToWorldSpace(side) * 260
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(shotPos, impact), math.min(1, dt * 4)) * FX.ShakeOffset()
		if age > 1.8 then
			finish()
		end
	end
end

-- UI ----------------------------------------------------------------------------------

local function buildUI()
	local gui = UI.Screen("Launch", 8)
	gui.IgnoreGuiInset = true

	local reticle = UI.New("Frame", {
		Name = "Reticle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(150, 150),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	refs.reticle = reticle
	local circle = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(64, 64),
		BackgroundTransparency = 1,
		Parent = reticle,
	})
	UI.Corner(UDim.new(1, 0)).Parent = circle
	refs.reticleStroke = UI.New("UIStroke", { Thickness = 2.5, Color = Color3.new(1, 1, 1), Parent = circle })
	refs.center = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = reticle,
	})
	UI.Corner(UDim.new(1, 0)).Parent = refs.center
	for i = 0, 3 do
		local a = i * math.pi / 2
		UI.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(a) * 44, 0.5, math.sin(a) * 44),
			Size = UDim2.fromOffset(i % 2 == 0 and 14 or 3, i % 2 == 0 and 3 or 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = reticle,
		})
	end
	-- Charge ring: segments around the crosshair; the top ones (gold) are the critical zone.
	refs.segments = {}
	for i = 1, SEGMENTS do
		local a = -math.pi / 2 + (i - 0.5) / SEGMENTS * math.pi * 2
		local seg = UI.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(a) * 62, 0.5, math.sin(a) * 62),
			Size = UDim2.fromOffset(5, 12),
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

	refs.dots = {}
	for i = 1, DOTS do
		local d = UI.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(7, 7),
			BackgroundColor3 = Color3.fromRGB(255, 220, 150),
			BorderSizePixel = 0,
			Visible = false,
			Parent = gui,
		})
		UI.Corner(UDim.new(1, 0)).Parent = d
		refs.dots[i] = d
	end

	refs.hint = UI.Text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.fromOffset(620, 30),
		Text = "MIRA il pianeta  ·  TIENI PREMUTO per caricare  ·  RILASCIA nella zona dorata",
		TextStrokeTransparency = 0.2,
		MaxTextSize = 22,
		Visible = false,
		Parent = gui,
	})
	refs.cancel = UI.Button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -30),
		Size = UDim2.fromOffset(150, 44),
		Text = "Annulla (Q)",
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
		Text = "CRITICO!",
		TextColor3 = Color3.fromRGB(255, 210, 60),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		MaxTextSize = 80,
		Parent = gui,
	})
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
		end
	end)

	player.CharacterAdded:Connect(function()
		if state ~= "idle" then
			constraints = {}
			ap = nil
			setAimUI(false)
			camera.CameraType = Enum.CameraType.Custom
			launchData = nil
			flight = nil
			state = "idle"
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if state == "idle" then
			if os.clock() < nextTryAt then
				return
			end
			if workspace:GetAttribute("CyclePhase") ~= "Bombard" or not workspace:GetAttribute("PlanetReady") then
				return
			end
			local root = getRoot()
			if root and onPad(root.Position) then
				if hasReadyMeteor() then
					enterAim()
				else
					nextTryAt = os.clock() + 2.5
					controllers.Notifications.Toast("Nessun meteorite pronto: aspetta la ricarica!", "bad")
				end
			end
		elseif state == "aiming" then
			updateAiming(dt)
		else
			updateFlight(dt)
		end
	end)
end

return Launch
