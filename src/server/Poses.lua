-- Simple procedural poses for R15 characters, done by tweening Motor6D.C0 on the server so
-- every player sees them (works without uploaded animations).

local TweenService = game:GetService("TweenService")

local Poses = {}

-- Original C0 captured when a pose starts and forgotten after Reset, so character scaling
-- (evolutions) between poses is respected.
local originals = setmetatable({}, { __mode = "k" }) -- [Motor6D] = original C0

local JOINTS = {
	RightShoulder = { part = "RightUpperArm", name = "RightShoulder" },
	LeftShoulder = { part = "LeftUpperArm", name = "LeftShoulder" },
	Waist = { part = "UpperTorso", name = "Waist" },
	Neck = { part = "Head", name = "Neck" },
}

-- Rotation offsets (radians) per pose and joint.
local POSES = {
	charge = {
		RightShoulder = CFrame.Angles(math.rad(165), 0, math.rad(-12)),
		LeftShoulder = CFrame.Angles(math.rad(165), 0, math.rad(12)),
		Waist = CFrame.Angles(math.rad(-12), 0, 0),
		Neck = CFrame.Angles(math.rad(12), 0, 0),
	},
	throw = {
		RightShoulder = CFrame.Angles(math.rad(55), 0, math.rad(-8)),
		LeftShoulder = CFrame.Angles(math.rad(40), 0, math.rad(8)),
		Waist = CFrame.Angles(math.rad(18), 0, 0),
		Neck = CFrame.Angles(math.rad(-6), 0, 0),
	},
}

local function motor(character, key)
	local j = JOINTS[key]
	local part = character:FindFirstChild(j.part)
	local m = part and part:FindFirstChild(j.name)
	if m and m:IsA("Motor6D") then
		if not originals[m] then
			originals[m] = m.C0
		end
		return m
	end
	return nil
end

function Poses.Set(character, poseName, duration)
	local pose = POSES[poseName]
	if not character or not pose then
		return
	end
	for key, offset in pairs(pose) do
		local m = motor(character, key)
		if m then
			TweenService:Create(
				m,
				TweenInfo.new(duration or 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ C0 = originals[m] * offset }
			):Play()
		end
	end
end

function Poses.Reset(character, duration)
	if not character then
		return
	end
	for key in pairs(JOINTS) do
		local m = motor(character, key)
		if m then
			local original = originals[m]
			local t = TweenService:Create(m, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad), { C0 = original })
			t:Play()
			t.Completed:Connect(function(status)
				if status == Enum.PlaybackState.Completed and originals[m] == original then
					originals[m] = nil
				end
			end)
		end
	end
end

return Poses
