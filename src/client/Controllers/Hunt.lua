-- Cosmic Hunt, client side: free flight through deep space with a chase camera over the shoulder.
-- Mouse turns the camera (locked to the center), WASD flies where you look, Space up, Ctrl down,
-- Shift boost; click throws your meteor at the crosshair. On mobile: thumbstick to fly, drag to
-- look, tap to throw at that point. Gamepad: sticks, R2 to throw.
--
-- The character takes a superhero pose (fist forward when flying fast, floating when still) and
-- swings its arm on every throw; the pose is set on the local joints (R15).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Format = require(Shared.Util.Format)
local Meteors = require(Shared.Config.Meteors)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local FX = require(script.Parent.FX)
local Sfx = require(script.Parent.Sfx)

local Hunt = {}

local H = Game.Hunt
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controllers
local active = false
local endsAt = 0
local constraints = {}
local lv, ao
local refs = {}
local lastFire = 0
local yaw, pitch = 0, 0
local stick2 = Vector2.zero
local touches = {} -- [input] = {start, at, moved}
local throwAt = -10
local fly = 0 -- 0 floating .. 1 full speed (drives the pose)
local bars = {} -- [marker] = BillboardGui

local MOUSE_SENS = math.rad(0.25)
local TOUCH_SENS = math.rad(0.35)

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end

-- Pose ------------------------------------------------------------------------------------------

local JOINTS = {
	Waist = "UpperTorso",
	Neck = "Head",
	RightShoulder = "RightUpperArm",
	LeftShoulder = "LeftUpperArm",
	RightElbow = "RightLowerArm",
	LeftElbow = "LeftLowerArm",
	RightHip = "RightUpperLeg",
	LeftHip = "LeftUpperLeg",
	RightKnee = "RightLowerLeg",
	LeftKnee = "LeftLowerLeg",
}
local joints = {} -- [name] = {motor, c0}

local function A(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y or 0), math.rad(z or 0))
end

-- Floating still: arms a little open, legs hanging.
local HOVER = {
	Waist = A(0),
	Neck = A(0),
	RightShoulder = A(10, 0, 22),
	LeftShoulder = A(10, 0, -22),
	RightElbow = A(25),
	LeftElbow = A(25),
	RightHip = A(10, 0, 4),
	LeftHip = A(-6, 0, -4),
	RightKnee = A(-25),
	LeftKnee = A(-10),
}
-- Flying fast: right fist forward (over the head, the body is horizontal), left arm along the
-- side, one knee bent, head up looking where you go.
local FLY = {
	Waist = A(8),
	Neck = A(55),
	RightShoulder = A(172, 0, -6),
	LeftShoulder = A(-18, 0, -14),
	RightElbow = A(0),
	LeftElbow = A(15),
	RightHip = A(-4, 0, 3),
	LeftHip = A(22, 0, -3),
	RightKnee = A(-5),
	LeftKnee = A(-55),
}

local function grabJoints()
	joints = {}
	local character = player.Character
	if not character then
		return
	end
	for name, partName in pairs(JOINTS) do
		local part = character:FindFirstChild(partName)
		local motor = part and part:FindFirstChild(name)
		if motor and motor:IsA("Motor6D") then
			joints[name] = { motor = motor, c0 = motor.C0 }
		end
	end
end

local function restoreJoints()
	for _, j in pairs(joints) do
		if j.motor.Parent then
			j.motor.C0 = j.c0
		end
	end
	joints = {}
end

-- Throw swing on top of the pose: wind up behind the head, snap forward, recover.
local function throwOffset(name, t)
	if t < 0 or t > 0.5 then
		return nil
	end
	local w
	if t < 0.1 then
		w = t / 0.1 -- wind-up
		if name == "RightShoulder" then
			return A(200, 0, 25), w
		elseif name == "Waist" then
			return A(-10, 25, 0), w
		end
	elseif t < 0.2 then
		w = 1 -- strike
		if name == "RightShoulder" then
			return A(75, 0, 0), w
		elseif name == "RightElbow" then
			return A(0), w
		elseif name == "Waist" then
			return A(15, -30, 0), w
		end
	else
		w = 1 - (t - 0.2) / 0.3 -- recover
		if name == "RightShoulder" then
			return A(75, 0, 0), w
		elseif name == "Waist" then
			return A(15, -30, 0), w
		end
	end
	return nil
end

local function updatePose()
	local t = os.clock()
	local bob = math.sin(t * 2.2)
	for name, j in pairs(joints) do
		if j.motor.Parent then
			local pose = HOVER[name]:Lerp(FLY[name], fly)
			if name == "RightHip" or name == "LeftHip" then
				pose = pose * A(bob * (name == "RightHip" and 5 or -5))
			end
			local offset, w = throwOffset(name, t - throwAt)
			if offset then
				pose = pose:Lerp(offset, w)
			end
			j.motor.C0 = j.c0 * pose
		end
	end
end

-- Flight ------------------------------------------------------------------------------------------

local function stopFlight()
	for _, c in ipairs(constraints) do
		if c.Parent then
			c:Destroy()
		end
	end
	constraints = {}
	lv, ao = nil, nil
	restoreJoints()
	local _, humanoid = getRoot()
	if humanoid then
		humanoid.PlatformStand = false
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

local function startFlight()
	stopFlight()
	local root, humanoid = getRoot()
	if not root or not humanoid then
		return
	end
	humanoid.PlatformStand = true
	local att = Instance.new("Attachment")
	att.Name = "HuntAttachment"
	att.Parent = root
	lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = 1e9
	lv.VectorVelocity = Vector3.zero
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = root
	ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = 1e9
	ao.Responsiveness = 25
	ao.Parent = root
	-- A streak of light behind the god.
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(-1.2, 0, 0.5)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(1.2, 0, 0.5)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255), Color3.fromRGB(150, 110, 255))
	trail.LightEmission = 1
	trail.Lifetime = 0.5
	trail.Transparency = NumberSequence.new(0.4, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Parent = root
	constraints = { att, lv, ao, a0, a1, trail }
	grabJoints()
	local _, y = root.CFrame:ToOrientation()
	yaw, pitch = y, 0
	camera.CameraType = Enum.CameraType.Scriptable
end

local function setUI(visible)
	refs.frame.Visible = visible
	refs.crosshair.Visible = visible
	for _, bar in pairs(bars) do
		bar.Enabled = visible
	end
end

-- Where a screen point aims in the world (the planet's surface, or far away).
local function aimPoint(screenPos)
	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * (H.Range + 100), params)
	return hit and hit.Position or ray.Origin + ray.Direction * H.Range
end

local function tryFire(screenPos)
	if not active or os.clock() - lastFire < H.FireCooldown then
		return
	end
	lastFire = os.clock()
	throwAt = os.clock()
	Sfx.Play("Throw", 0.8)
	Remotes.Get("HuntFire"):FireServer(aimPoint(screenPos or camera.ViewportSize / 2))
end

-- Planet HP bars --------------------------------------------------------------------------------

local function addBar(marker)
	if bars[marker] or not marker:IsA("BasePart") then
		return
	end
	local r = marker:GetAttribute("Radius") or 40
	local bb = Instance.new("BillboardGui")
	bb.Name = "HuntBar"
	bb.Adornee = marker
	bb.Size = UDim2.fromOffset(180, 42)
	bb.StudsOffsetWorldSpace = Vector3.new(0, r * 1.25 + 8, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 1400
	bb.LightInfluence = 0
	bb.Enabled = active
	local title = UI.Text({
		Size = UDim2.new(1, 0, 0, 20),
		Text = marker:GetAttribute("Title") or "Moon",
		TextColor3 = marker:GetAttribute("Color") or Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.2,
		MaxTextSize = 18,
		Parent = bb,
	})
	title.BackgroundTransparency = 1
	local back = UI.New("Frame", {
		Position = UDim2.fromOffset(10, 24),
		Size = UDim2.new(1, -20, 0, 12),
		BackgroundColor3 = Color3.fromRGB(20, 15, 35),
		BorderSizePixel = 0,
		Parent = bb,
	})
	UI.Corner(UDim.new(1, 0)).Parent = back
	local fill = UI.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 120, 90),
		BorderSizePixel = 0,
		Parent = back,
	})
	UI.Corner(UDim.new(1, 0)).Parent = fill
	local function update()
		local hp, max = marker:GetAttribute("HP") or 0, marker:GetAttribute("MaxHP") or 1
		TweenService:Create(fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(math.clamp(hp / max, 0, 1), 1) }):Play()
	end
	marker:GetAttributeChangedSignal("HP"):Connect(update)
	update()
	bb.Parent = marker
	bars[marker] = bb
	marker.AncestryChanged:Connect(function()
		if not marker.Parent then
			bars[marker] = nil
		end
	end)
end

-- Effects ----------------------------------------------------------------------------------------

local function handPosition()
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	local root = getRoot()
	return hand and root and hand.Position + root.CFrame.UpVector * 3 or nil
end

-- Stardust sparks flying from the broken planet into you.
local function stardustStream(from, reward)
	local root = getRoot()
	if not root then
		return
	end
	for i = 1, 14 do
		local spark = Instance.new("Part")
		spark.Shape = Enum.PartType.Ball
		spark.Anchored = true
		spark.CanCollide = false
		spark.CanQuery = false
		spark.CanTouch = false
		spark.CastShadow = false
		spark.Material = Enum.Material.Neon
		spark.Color = Color3.fromRGB(200, 160, 255):Lerp(Color3.new(1, 1, 1), math.random() * 0.5)
		spark.Size = Vector3.one * 2.5
		spark.CFrame = CFrame.new(from + Random.new():NextUnitVector() * 20)
		spark.Parent = workspace
		local start, delay = spark.Position, i * 0.03
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local k = math.clamp((os.clock() - t0 - delay) / 0.7, 0, 1)
			local target = root.Position
			local mid = (start + target) / 2 + Vector3.new(0, 40, 0)
			local a = start:Lerp(mid, k)
			spark.Position = a:Lerp(mid:Lerp(target, k), k)
			if k >= 1 then
				conn:Disconnect()
				spark:Destroy()
			end
		end)
	end
	task.delay(0.9, function()
		refs.popup.Text = "+" .. reward .. " ✨"
		refs.popup.TextTransparency = 0
		refs.popup.TextStrokeTransparency = 0.3
		TweenService:Create(refs.popup, TweenInfo.new(1.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		Sfx.Play("RarePickup", 0.6)
	end)
end

local function onFX(p)
	if p.kind == "throw" then
		local mine = p.thrower == player.UserId
		local from = mine and handPosition() or p.from
		local thrower = Players:GetPlayerByUserId(p.thrower)
		if thrower and controllers.Pets.Hide then
			controllers.Pets.Hide(thrower, math.max(H.FireCooldown, p.travel * 0.5))
		end
		FX.Flight({
			meteorType = p.meteorType,
			mutation = p.mutation,
			size = 8,
			from = from,
			to = p.to,
			flightTime = p.travel,
		})
	elseif p.kind == "hit" then
		local def = Meteors.ByID[p.meteorType]
		FX.Impact({
			point = p.point,
			normal = p.normal,
			crater = p.crater,
			damage = p.damage,
			crit = false,
			color = def and def.fire[1],
			thrower = p.thrower,
			impact = def and def.impact,
			crustColor = p.crustColor,
		})
	elseif p.kind == "shatter" then
		FX.Shatter(p)
		if p.killer == player.UserId then
			task.delay(p.delay, stardustStream, p.center, p.reward)
		end
	elseif p.kind == "spawn" then
		FX.Materialize(p)
	end
end

-- UI ----------------------------------------------------------------------------------------------

local function buildUI()
	local gui = UI.Screen("Hunt", 9)
	gui.IgnoreGuiInset = true
	refs.frame = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(420, 70),
		Visible = false,
		Parent = gui,
	})
	refs.status = UI.Text({
		Size = UDim2.new(1, -150, 1, -10),
		Position = UDim2.fromOffset(12, 5),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 24,
		Parent = refs.frame,
	})
	UI.Button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(120, 46),
		Text = "Leave",
		BackgroundColor3 = UI.Colors.Bad,
		Parent = refs.frame,
	}, function()
		Remotes.Get("HuntLeave"):FireServer()
	end)
	refs.crosshair = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	UI.Corner(UDim.new(1, 0)).Parent = refs.crosshair
	UI.New("UIStroke", { Thickness = 2, Color = Color3.fromRGB(255, 120, 90), Parent = refs.crosshair })
	refs.dot = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Color3.fromRGB(255, 120, 90),
		BorderSizePixel = 0,
		Parent = refs.crosshair,
	})
	UI.Corner(UDim.new(1, 0)).Parent = refs.dot
	refs.popup = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.fromOffset(300, 60),
		Text = "",
		TextColor3 = Color3.fromRGB(210, 170, 255),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		MaxTextSize = 48,
		Parent = gui,
	})
	refs.help = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 8),
		Size = UDim2.fromOffset(640, 26),
		Text = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
				and "Stick to fly · drag to look · TAP a planet to throw"
			or "MOUSE look · WASD fly · SPACE/CTRL up/down · SHIFT boost · CLICK throw · ALT cursor",
		TextStrokeTransparency = 0.2,
		MaxTextSize = 20,
		Parent = refs.frame,
	})
end

function Hunt:Init(c)
	controllers = c
	buildUI()
end

local function updateCamera(dt, root)
	-- Look: mouse (locked to the center), right gamepad stick, touch drags (in the input handlers).
	-- Hold ALT to free the cursor (e.g. to click Leave).
	local freeCursor = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
	if UserInputService.MouseEnabled and freeCursor then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	elseif UserInputService.MouseEnabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		local delta = UserInputService:GetMouseDelta()
		yaw -= delta.X * MOUSE_SENS
		pitch -= delta.Y * MOUSE_SENS
	end
	if stick2.Magnitude > 0.15 then
		yaw -= stick2.X * dt * 2.6
		pitch += stick2.Y * dt * 2
	end
	pitch = math.clamp(pitch, math.rad(-80), math.rad(80))
	local orient = CFrame.fromOrientation(pitch, yaw, 0)
	local boosting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	local back = 18 + fly * 6
	local target = CFrame.new(root.Position) * orient * CFrame.new(3.5, 3, back)
	camera.CFrame = camera.CFrame:Lerp(target, math.min(1, dt * 12)) * FX.ShakeOffset()
	camera.FieldOfView += ((boosting and 88 or 72 + fly * 6) - camera.FieldOfView) * math.min(1, dt * 5)
	return orient
end

function Hunt:Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "OpenHunt" then
			Remotes.Get("HuntStart"):FireServer()
		end
	end)
	Remotes.Get("HuntState").OnClientEvent:Connect(function(s)
		if s.active then
			if not active then
				active = true
				task.delay(0.2, startFlight)
			end
			endsAt = s.endsAt
			refs.score = s.score
			refs.stardust = s.stardust
			setUI(true)
		else
			active = false
			stopFlight()
			setUI(false)
		end
	end)
	Remotes.Get("HuntFX").OnClientEvent:Connect(onFX)
	player.CharacterAdded:Connect(function()
		if active then
			active = false
			constraints = {}
			joints = {}
			stopFlight()
		end
		setUI(false)
	end)

	local huntFolder = workspace:WaitForChild("HuntPlanets", 30)
	if huntFolder then
		huntFolder.ChildAdded:Connect(addBar)
		for _, m in ipairs(huntFolder:GetChildren()) do
			addBar(m)
		end
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not active or processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch then
			touches[input] = { start = Vector2.new(input.Position.X, input.Position.Y), at = os.clock(), moved = 0 }
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
				tryFire(nil)
			end
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
			tryFire(nil)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not active then
			return
		end
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			stick2 = Vector2.new(input.Position.X, input.Position.Y)
		elseif input.UserInputType == Enum.UserInputType.Touch and touches[input] then
			local t = touches[input]
			t.moved += input.Delta.Magnitude
			yaw -= input.Delta.X * TOUCH_SENS
			pitch -= input.Delta.Y * TOUCH_SENS
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local t = touches[input]
		touches[input] = nil
		if active and t and t.moved < 14 and os.clock() - t.at < 0.35 then
			tryFire(Vector2.new(input.Position.X, input.Position.Y)) -- tap: throw there
		end
	end)

	RunService:BindToRenderStep("MeteorGodsHunt", Enum.RenderPriority.Camera.Value + 2, function(dt)
		if not active then
			return
		end
		local left = math.max(0, endsAt - workspace:GetServerTimeNow())
		refs.status.Text = string.format("🌌 %s   💥 %d planets   ✨ +%s", Format.Time(left), refs.score or 0, Format.Number(refs.stardust or 0))
		local ready = os.clock() - lastFire >= H.FireCooldown
		refs.dot.BackgroundTransparency = ready and 0 or 0.7
		local root, humanoid = getRoot()
		if not root or not lv then
			return
		end
		local orient = updateCamera(dt, root)
		local look = orient.LookVector
		local right = orient.RightVector
		local move = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			move += look
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			move -= look
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			move += right
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			move -= right
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			move += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			move -= Vector3.new(0, 1, 0)
		end
		if move.Magnitude < 0.01 and humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
			-- Mobile / gamepad thumbstick: fly where the camera looks.
			local md = humanoid.MoveDirection
			local flatLook = Vector3.new(look.X, 0, look.Z).Unit
			local flatRight = Vector3.new(right.X, 0, right.Z).Unit
			move = look * md:Dot(flatLook) + right * md:Dot(flatRight)
		end
		local speed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and H.BoostSpeed or H.FlySpeed
		local target = move.Magnitude > 0.01 and move.Unit * speed or Vector3.zero
		lv.VectorVelocity = lv.VectorVelocity:Lerp(target, math.min(1, dt * 6))
		-- Body: lies along the flight when going forward fast, upright when floating.
		local forward = math.max(0, lv.VectorVelocity:Dot(look)) / H.FlySpeed
		fly += (math.clamp(forward, 0, 1) - fly) * math.min(1, dt * 5)
		ao.CFrame = CFrame.fromOrientation(0, yaw, 0) * CFrame.Angles(pitch * (1 - fly) * 0.3 - math.rad(82) * fly + pitch * fly, 0, 0)
		updatePose()
	end)
end

return Hunt
