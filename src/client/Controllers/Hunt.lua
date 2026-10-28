-- Cosmic Hunt, client side: free flight through deep space (WASD + camera direction, Space up,
-- Ctrl down, Shift boost; on mobile the thumbstick flies where the camera looks), click / tap to
-- throw your meteor at the planets. Timer, score and Stardust on screen.

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
local MeteorVisual = require(Shared.MeteorVisual)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local FX = require(script.Parent.FX)

local Hunt = {}

local H = Game.Hunt
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local active = false
local endsAt = 0
local constraints = {}
local lv, ao
local refs = {}
local lastFire = 0

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end

local function stopFlight()
	for _, c in ipairs(constraints) do
		if c.Parent then
			c:Destroy()
		end
	end
	constraints = {}
	lv, ao = nil, nil
	local _, humanoid = getRoot()
	if humanoid then
		humanoid.PlatformStand = false
	end
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
	lv.MaxForce = math.huge
	lv.VectorVelocity = Vector3.zero
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = root
	ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = math.huge
	ao.Responsiveness = 18
	ao.Parent = root
	constraints = { att, lv, ao }
end

local function setUI(visible)
	refs.frame.Visible = visible
	refs.crosshair.Visible = visible
end

-- Where the mouse / tap points in the world (a hunt planet, or far away).
local function aimPoint(screenPos)
	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace:FindFirstChild("HuntPlanets") }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * (H.Range + 100), params)
	return hit and hit.Position or ray.Origin + ray.Direction * H.Range
end

local function tryFire(screenPos)
	if not active or os.clock() - lastFire < H.FireCooldown then
		return
	end
	lastFire = os.clock()
	Remotes.Get("HuntFire"):FireServer(aimPoint(screenPos))
end

-- A thrown meteor streaking to its target; explosion when a planet breaks.
local function onFX(p)
	local model = MeteorVisual.Build(p.meteorType, { size = 4, expression = "furious" })
	model.Parent = workspace
	local core = model.PrimaryPart
	local def = Meteors.ByID[p.meteorType]
	local storm = FX.Storm(core, def and def.fire[1])
	storm:SetIntensity(1)
	local start, time = os.clock(), math.clamp((p.to - p.from).Magnitude / 2500, 0.15, 0.6)
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - start) / time)
		core.CFrame = CFrame.lookAt(p.from:Lerp(p.to, k), p.to) * CFrame.Angles(0, math.pi, 0)
		if k >= 1 then
			conn:Disconnect()
			storm:Destroy()
			model:Destroy()
			if p.damage then
				FX.Impact({
					point = p.to,
					normal = (p.from - p.to).Unit,
					crater = p.explode and p.explode.radius * 0.6 or 14,
					damage = p.damage,
					crit = false,
					color = def and def.fire[1],
					thrower = p.thrower,
					impact = def and def.impact,
					crustColor = p.explode and p.explode.color,
				})
			end
			if p.explode then
				FX.Layer({ center = p.explode.center, radius = p.explode.radius, layer = 3, color = p.explode.color })
				if p.thrower == player.UserId then
					refs.popup.Text = "+" .. p.explode.reward .. " ✨"
					refs.popup.TextTransparency = 0
					TweenService:Create(refs.popup, TweenInfo.new(1.2), { TextTransparency = 1 }):Play()
				end
			end
		end
	end)
end

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
		Size = UDim2.fromOffset(34, 34),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	UI.Corner(UDim.new(1, 0)).Parent = refs.crosshair
	UI.New("UIStroke", { Thickness = 2, Color = Color3.fromRGB(255, 120, 90), Parent = refs.crosshair })
	refs.popup = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.35),
		Size = UDim2.fromOffset(300, 60),
		Text = "",
		TextColor3 = Color3.fromRGB(210, 170, 255),
		TextTransparency = 1,
		MaxTextSize = 48,
		Parent = gui,
	})
	refs.help = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 8),
		Size = UDim2.fromOffset(640, 26),
		Text = "WASD fly · SPACE up · CTRL down · SHIFT boost · CLICK to throw",
		TextStrokeTransparency = 0.2,
		MaxTextSize = 20,
		Parent = refs.frame,
	})
end

function Hunt:Init()
	buildUI()
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
		active = false
		constraints = {}
		setUI(false)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not active or processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tryFire(Vector2.new(input.Position.X, input.Position.Y))
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
			tryFire(camera.ViewportSize / 2)
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not active then
			return
		end
		local mouse = UserInputService:GetMouseLocation()
		refs.crosshair.Position = UDim2.fromOffset(mouse.X, mouse.Y)
		local left = math.max(0, endsAt - workspace:GetServerTimeNow())
		refs.status.Text = string.format("🌌 %s   💥 %d planets   ✨ +%s", Format.Time(left), refs.score or 0, Format.Number(refs.stardust or 0))
		local root, humanoid = getRoot()
		if not root or not lv then
			return
		end
		-- Fly relative to the camera.
		local look = camera.CFrame.LookVector
		local right = camera.CFrame.RightVector
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
		lv.VectorVelocity = lv.VectorVelocity:Lerp(target, 0.15)
		ao.CFrame = CFrame.lookAt(Vector3.zero, look) * CFrame.Angles(math.rad(-20) * math.min(1, lv.VectorVelocity.Magnitude / H.FlySpeed), 0, 0)
	end)
end

return Hunt
