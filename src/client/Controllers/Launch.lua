-- The launch: step on a LAUNCH pad -> rise above the void -> hold to charge (golden zone = crit)
-- -> release -> the camera follows the meteor into the planet -> back to the bridge.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)

local Launch = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controllers

local L = Game.Launch
local state = "idle" -- idle | requesting | hover | flying
local nextRequestAt = 0
local launchData -- result of BeginLaunch
local constraints = {}
local holding = false
local chargeT = 0
local charge = 0
local hoverStart = 0
local refs = {}

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
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
		if flat.Magnitude <= Game.World.LaunchPadRadius - 2 and math.abs(position.Y - p.Y) < 10 then
			return true
		end
	end
	return false
end

local function clearConstraints()
	for _, c in ipairs(constraints) do
		if c.Parent then
			c:Destroy()
		end
	end
	constraints = {}
	local _, humanoid = getRoot()
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		humanoid.CameraOffset = Vector3.zero
	end
end

local function showChargeUI(visible)
	refs.root.Visible = visible
	refs.mobileButton.Visible = visible and UserInputService.TouchEnabled
end

local function endLaunch()
	local root = getRoot()
	clearConstraints()
	camera.CameraType = Enum.CameraType.Custom
	if root and launchData and launchData.returnCFrame then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = launchData.returnCFrame
	end
	showChargeUI(false)
	launchData = nil
	holding = false
	state = "idle"
	nextRequestAt = os.clock() + 0.8
end

local function startHover(result)
	local root, humanoid = getRoot()
	if not root or not humanoid then
		Remotes.Get("CancelLaunch"):FireServer()
		state = "idle"
		return
	end
	launchData = result
	state = "hover"
	holding = false
	chargeT = 0
	charge = 0
	hoverStart = os.clock()

	local target = root.Position + Vector3.new(0, L.HoverHeight, 0)
	local att = Instance.new("Attachment")
	att.Name = "LaunchAttachment"
	att.Parent = root
	local ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.Position = target
	ap.MaxForce = 1e7
	ap.Responsiveness = 18
	ap.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.CFrame = CFrame.lookAt(target, result.planetPosition)
	ao.MaxTorque = 1e7
	ao.Responsiveness = 20
	ao.Parent = root
	constraints = { att, ap, ao }

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	refs.meteorName.Text = (result.mutation and (result.mutation .. " ") or "") .. result.meteorType
	showChargeUI(true)
end

local function requestLaunch()
	state = "requesting"
	local ok, result = pcall(function()
		return Remotes.Get("BeginLaunch"):InvokeServer()
	end)
	if not ok or not result or not result.ok then
		state = "idle"
		nextRequestAt = os.clock() + 2.5
		if ok and result and result.reason then
			controllers.Notifications.Toast(result.reason, "bad")
		end
		return
	end
	startHover(result)
end

local function release()
	if state ~= "hover" then
		return
	end
	state = "flying"
	holding = false
	showChargeUI(false)
	local _, humanoid = getRoot()
	if humanoid then
		humanoid.CameraOffset = Vector3.zero
	end
	Remotes.Get("FireLaunch"):FireServer(charge)
	-- Safety net in case the result never arrives.
	local myData = launchData
	task.delay(L.FlightTime + 4, function()
		if state == "flying" and launchData == myData then
			endLaunch()
		end
	end)
end

local function followMeteor(result)
	local model = result.model
	local core = model and model.PrimaryPart
	local impact = result.impact
	camera.CameraType = Enum.CameraType.Scriptable
	local start = os.clock()
	local total = result.flightTime + 1.1
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		local focus
		if core and core.Parent and t < result.flightTime then
			focus = core.Position
		else
			focus = impact
		end
		local back = (camera.CFrame.Position - focus)
		local dist = math.max(back.Magnitude, 1)
		local desiredDist = t < result.flightTime and 34 or 90
		local desired = focus + back.Unit * math.min(dist, desiredDist) + Vector3.new(0, 6, 0)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(desired, focus), 0.25)
		if t >= total then
			conn:Disconnect()
			endLaunch()
		end
	end)

	if result.crit then
		refs.critFlash.TextTransparency = 0
		refs.critFlash.TextStrokeTransparency = 0
		TweenService:Create(refs.critFlash, TweenInfo.new(1.2), { TextTransparency = 1, TextStrokeTransparency = 1 })
			:Play()
	end
	task.delay(result.flightTime, function()
		refs.damage.Text = "💥 " .. Format.Number(result.damage)
		refs.damage.TextTransparency = 0
		refs.damage.TextStrokeTransparency = 0
		TweenService:Create(refs.damage, TweenInfo.new(1.4), { TextTransparency = 1, TextStrokeTransparency = 1 })
			:Play()
	end)
end

local function buildUI()
	local gui = UI.Screen("Launch", 8)
	local root = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(460, 110),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	refs.root = root
	refs.meteorName = UI.Text({
		Size = UDim2.new(1, 0, 0, 26),
		Text = "",
		TextColor3 = UI.Colors.Gold,
		TextStrokeTransparency = 0.3,
		MaxTextSize = 24,
		Parent = root,
	})
	UI.Text({
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(0, 28),
		Text = "TIENI PREMUTO e rilascia nella ZONA DORATA per un CRITICO!",
		TextStrokeTransparency = 0.3,
		MaxTextSize = 18,
		Parent = root,
	})
	local back = UI.New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 58),
		BackgroundColor3 = Color3.fromRGB(15, 10, 25),
		BorderSizePixel = 0,
		Parent = root,
	})
	UI.Corner(UDim.new(1, 0)).Parent = back
	UI.Stroke(UI.Colors.Purple, 2, 0.2).Parent = back
	local sweet = UI.New("Frame", {
		Position = UDim2.fromScale(L.CritThreshold, 0),
		Size = UDim2.fromScale(1 - L.CritThreshold, 1),
		BackgroundColor3 = UI.Colors.Gold,
		BorderSizePixel = 0,
		Parent = back,
	})
	UI.Corner(UDim.new(1, 0)).Parent = sweet
	refs.fill = UI.New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = back,
	})
	UI.Corner(UDim.new(1, 0)).Parent = refs.fill

	refs.mobileButton = UI.Button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -120),
		Size = UDim2.fromOffset(150, 150),
		Text = "CARICA",
		BackgroundColor3 = Color3.fromRGB(255, 120, 60),
		MaxTextSize = 32,
		Visible = false,
		Parent = gui,
	})
	refs.mobileButton.MouseButton1Down:Connect(function()
		if state == "hover" then
			holding = true
		end
	end)
	refs.mobileButton.MouseButton1Up:Connect(function()
		if holding then
			release()
		end
	end)

	refs.critFlash = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.35),
		Size = UDim2.fromOffset(500, 80),
		Text = "CRITICO!",
		TextColor3 = UI.Colors.Gold,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		MaxTextSize = 72,
		Parent = gui,
	})
	refs.damage = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(500, 70),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 150, 80),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		MaxTextSize = 60,
		Parent = gui,
	})
end

local CHARGE_INPUTS = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
}
local CHARGE_KEYS = {
	[Enum.KeyCode.Space] = true,
	[Enum.KeyCode.ButtonR2] = true,
	[Enum.KeyCode.ButtonA] = true,
}

local function isChargeInput(input)
	return CHARGE_INPUTS[input.UserInputType] or CHARGE_KEYS[input.KeyCode]
end

function Launch:Init(c)
	controllers = c
	buildUI()
end

function Launch:Start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if state == "hover" and not processed and isChargeInput(input) then
			holding = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if state == "hover" and holding and isChargeInput(input) then
			release()
		end
	end)

	Remotes.Get("LaunchResult").OnClientEvent:Connect(function(result)
		if state == "flying" then
			followMeteor(result)
		end
	end)

	player.CharacterAdded:Connect(function()
		if state ~= "idle" then
			constraints = {}
			camera.CameraType = Enum.CameraType.Custom
			showChargeUI(false)
			launchData = nil
			state = "idle"
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		if state == "idle" then
			if os.clock() < nextRequestAt or workspace:GetAttribute("CyclePhase") ~= "Bombard" then
				return
			end
			local root = getRoot()
			if root and onPad(root.Position) then
				task.spawn(requestLaunch)
			end
		elseif state == "hover" then
			if holding then
				chargeT += dt
				-- Ping-pong 0 -> 1 -> 0 so timing matters.
				local phase = (chargeT / L.ChargePeriod) % 2
				charge = phase <= 1 and phase or 2 - phase
				local _, humanoid = getRoot()
				if humanoid then
					local s = 0.15 + charge * 0.35
					humanoid.CameraOffset = Vector3.new(math.random() * s - s / 2, math.random() * s - s / 2, 0)
				end
			end
			refs.fill.Size = UDim2.fromScale(charge, 1)
			refs.fill.BackgroundColor3 = charge >= L.CritThreshold and UI.Colors.Gold or Color3.fromRGB(255, 255, 255)
			if os.clock() - hoverStart > L.MaxHoldTime - 0.5 then
				if charge == 0 then
					charge = 0.5
				end
				release()
			end
		end
	end)
end

return Launch
