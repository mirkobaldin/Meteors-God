-- Family weapons (Config/Meteors.Families): complete a family and its rarest meteor becomes a
-- weapon (a Tool whose head is the meteor itself). A swing hits the players in front of you:
-- they are knocked back and drop one meteor they picked up during the current shower (the
-- dropped meteor falls next to them and anyone can grab it). Like stealing eggs, with meteors.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local MeteorVisual = require(Shared.MeteorVisual)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)

local WeaponService = {}

local W = Game.Weapons
local services
local hitRemote
local lastSwing = {} -- [player] = os.clock()
local immuneUntil = {} -- [player] = os.clock()
local owned = {} -- [player] = { [familyId] = true } families already announced this session
local rng = Random.new()

local function part(props)
	local p = Instance.new("Part")
	p.CanCollide = false
	p.Massless = true
	p.CastShadow = false
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

local function makeTool(family)
	local headType = Meteors.FamilyHead(family)
	local tool = Instance.new("Tool")
	tool.Name = family.weapon.name
	tool.ToolTip = family.name .. " family weapon: knock meteors out of other players during a shower"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("Family", family.id)
	local kind = family.weapon.kind
	local length = kind == "lance" and 7 or 5
	local handle = part({
		Name = "Handle",
		Size = Vector3.new(0.45, length, 0.45),
		Material = Enum.Material.Foil,
		Color = Color3.fromRGB(70, 60, 80),
	})
	handle.Parent = tool
	tool.Grip = CFrame.new(0, -length * 0.3, 0)
	local top = handle.CFrame * CFrame.new(0, length / 2, 0)
	-- Gold collar under the head.
	local collar = part({ Size = Vector3.new(1.1, 0.5, 1.1), Material = Enum.Material.Foil, Color = Color3.fromRGB(214, 168, 96), CFrame = top })
	collar.Parent = tool
	weld(handle, collar)
	-- The meteor head (the family's rarest meteor, angry).
	local head = MeteorVisual.Build(headType, { size = kind == "hammer" and 3 or 2.2, expression = "furious", anchored = false })
	for _, d in ipairs(head:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
		end
	end
	head:PivotTo(top * CFrame.new(0, kind == "hammer" and 1.4 or 1.1, 0))
	head.Parent = tool
	weld(handle, head.PrimaryPart)
	if kind == "lance" then
		local tip = part({ Size = Vector3.new(0.6, 2.4, 0.6), Material = Enum.Material.Glass, Color = family.color, Transparency = 0.2 })
		tip.CFrame = top * CFrame.new(0, 3.2, 0)
		tip.Parent = tool
		weld(handle, tip)
	elseif kind == "scythe" then
		local blade = Instance.new("WedgePart")
		blade.CanCollide = false
		blade.Massless = true
		blade.Material = Enum.Material.Neon
		blade.Color = family.color
		blade.Size = Vector3.new(0.2, 1.2, 4)
		blade.CFrame = top * CFrame.new(0, 0.3, -2) * CFrame.Angles(0, 0, 0)
		blade.Parent = tool
		weld(handle, blade)
	end
	-- Swing trail.
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, length / 2 + 1.5, 0)
	a0.Parent = handle
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, length / 2 - 0.5, 0)
	a1.Parent = handle
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(family.color)
	trail.LightEmission = 1
	trail.Lifetime = 0.2
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = handle
	return tool
end

-- One meteor picked up in the current shower (not on the altar, not equipped, not exclusive).
local function freshMeteor(player)
	local data = services.DataService:Get(player)
	if not data then
		return nil
	end
	local list = {}
	for uid, m in pairs(data.meteors) do
		if m.fresh and m.fresh == services.CycleService.ShowerId and not m.altar and not m.paid and uid ~= data.equipped then
			table.insert(list, uid)
		end
	end
	return #list > 0 and list[rng:NextInteger(1, #list)] or nil
end

local function swing(player, tool)
	local now = os.clock()
	if now - (lastSwing[player] or 0) < W.Cooldown then
		return
	end
	lastSwing[player] = now
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or services.LaunchService:Current(player) or services.HuntService:IsHunting(player) then
		return
	end
	local look = root.CFrame.LookVector
	for _, other in ipairs(Players:GetPlayers()) do
		local oroot = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = oroot and other.Character:FindFirstChildOfClass("Humanoid")
		if oroot and humanoid and humanoid.Health > 0 then
			local offset = oroot.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if offset.Magnitude <= W.Range and flat.Magnitude > 0.1 and flat.Unit:Dot(look) > 0.25
				and (immuneUntil[other] or 0) < now
				and not services.LaunchService:Current(other) and not services.HuntService:IsHunting(other) then
				immuneUntil[other] = now + W.Immunity
				local dropped
				local uid = freshMeteor(other)
				if uid then
					local m = services.MeteorService:TakeMeteor(other, uid)
					if m then
						dropped = m.t
						services.ShowerService:Drop(m.t, m.m, oroot.Position + flat.Unit * 6)
						services.MeteorService:PushSnapshot(other)
						Notify.Toast(other, player.DisplayName .. " knocked your " .. m.t .. " out!", "bad")
						Notify.Toast(player, "You knocked a " .. m.t .. " out of " .. other.DisplayName .. "!", "good")
					end
				end
				hitRemote:FireAllClients({
					attacker = player.UserId,
					victim = other.UserId,
					position = oroot.Position,
					direction = flat.Unit,
					dropped = dropped,
					family = tool:GetAttribute("Family"),
				})
			end
		end
	end
end

-- Gives the player the weapons of every family they completed (once per character).
function WeaponService:Refresh(player, announce)
	local data = services.DataService:Get(player)
	if not data then
		return
	end
	owned[player] = owned[player] or {}
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, family in ipairs(Meteors.Families) do
		if Meteors.FamilyComplete(family, data.index) then
			local name = family.weapon.name
			local has = (backpack and backpack:FindFirstChild(name)) or (player.Character and player.Character:FindFirstChild(name))
			if not has and backpack then
				local tool = makeTool(family)
				tool.Activated:Connect(function()
					swing(player, tool)
				end)
				tool.Parent = backpack
			end
			if announce and not owned[player][family.id] then
				Notify.Toast(player, "⚔ " .. family.name .. " family complete! You got the " .. name .. "!", "good")
				Notify.Chat(player.DisplayName .. " completed the " .. family.name .. " family and wields the " .. name .. "!", family.color)
			end
			owned[player][family.id] = true
		end
	end
end

function WeaponService:Init(s)
	services = s
	hitRemote = Remotes.Get("WeaponHit")
end

function WeaponService:Start()
	services.DataService.PlayerLoaded:Connect(function(player, data)
		-- Meteors carried from an old session are safe.
		for _, m in pairs(data.meteors) do
			m.fresh = nil
		end
		owned[player] = {}
		WeaponService:Refresh(player, false)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			WeaponService:Refresh(player, false)
		end)
	end)
	-- The shower is over: what you carried is yours for good.
	services.CycleService.PhaseChanged:Connect(function(phase)
		if phase ~= "Shower" then
			for _, player in ipairs(Players:GetPlayers()) do
				local data = services.DataService:Get(player)
				if data then
					for _, m in pairs(data.meteors) do
						m.fresh = nil
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		immuneUntil[player] = nil
		owned[player] = nil
	end)
end

return WeaponService
