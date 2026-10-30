-- Carrying meteors home (server: CarryService): a banner at the top of the screen and a glowing beam
-- from your character to your Comet Islet while you have meteors in your hands.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UI = require(script.Parent.UI)

local Carry = {}

local player = Players.LocalPlayer
local banner, label
local beam, a0, a1, anchor

local function ensureBeam()
	if beam and beam.Parent then
		return
	end
	anchor = Instance.new("Part")
	anchor.Name = "CarryTarget"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Parent = workspace.CurrentCamera
	a1 = Instance.new("Attachment")
	a1.Parent = anchor
	beam = Instance.new("Beam")
	beam.Color = ColorSequence.new(Color3.fromRGB(120, 230, 255))
	beam.LightEmission = 1
	beam.Transparency = NumberSequence.new(0.2, 0.85)
	beam.Width0 = 1.2
	beam.Width1 = 0.4
	beam.FaceCamera = true
	beam.TextureSpeed = 2
	beam.Attachment1 = a1
	beam.Parent = anchor
end

local function update()
	local count = player:GetAttribute("Carrying") or 0
	local cap = player:GetAttribute("CarryCap") or 1
	local home = player:GetAttribute("PlotPosition")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	banner.Visible = count > 0
	label.Text = string.format("☄ Carrying %d/%d — bring it home to keep it!", count, cap)
	if count > 0 and home and root then
		ensureBeam()
		if not a0 or a0.Parent ~= root then
			if a0 then
				a0:Destroy()
			end
			a0 = Instance.new("Attachment")
			a0.Name = "CarryBeam"
			a0.Parent = root
		end
		anchor.Position = home + Vector3.new(0, 8, 0)
		beam.Attachment0 = a0
		beam.Enabled = true
	elseif beam then
		beam.Enabled = false
	end
end

function Carry:Init()
	local gui = UI.Screen("Carry", 5)
	banner = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 96),
		Size = UDim2.fromOffset(460, 52),
		Visible = false,
		Parent = gui,
	})
	label = UI.Text({
		Size = UDim2.new(1, -24, 1, -12),
		Position = UDim2.fromOffset(12, 6),
		TextColor3 = UI.Colors.Cyan,
		MaxTextSize = 24,
		ZIndex = 2,
		Parent = banner,
	})
end

function Carry:Start()
	for _, attr in ipairs({ "Carrying", "CarryCap", "PlotPosition" }) do
		player:GetAttributeChangedSignal(attr):Connect(update)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		update()
	end)
	-- The beam's start follows the character; only the target needs refreshing now and then.
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc > 1 and (player:GetAttribute("Carrying") or 0) > 0 then
			acc = 0
			update()
		end
	end)
	update()
end

return Carry
