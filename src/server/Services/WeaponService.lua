-- Rarity weapons (Config/Meteors.Weapons): find all the meteors of a rarity and pick one of them
-- (Index window) to become a weapon (a Tool whose head is that meteor). A swing hits the players in
-- front of you: they are knocked back and drop one meteor they are carrying home (CarryService;
-- it falls next to them and anyone can grab it). Everybody also has the basic Star Slap.

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
local owned = {} -- [player] = { [rarityId] = true } weapons already announced this session

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

local function toolName(rarityId, headType)
	return headType .. " " .. Meteors.Weapons[rarityId].name
end

local function makeTool(rarityId, headType)
	local weapon = Meteors.Weapons[rarityId]
	local color = Meteors.RarityByID[rarityId].color
	local tool = Instance.new("Tool")
	tool.Name = toolName(rarityId, headType)
	tool.ToolTip = rarityId .. " weapon: knock meteors out of players carrying them home"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("Rarity", rarityId)
	local kind = weapon.kind
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
	-- The meteor head (the meteor the player picked for this rarity, angry).
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
		local tip = part({ Size = Vector3.new(0.6, 2.4, 0.6), Material = Enum.Material.Glass, Color = color, Transparency = 0.2 })
		tip.CFrame = top * CFrame.new(0, 3.2, 0)
		tip.Parent = tool
		weld(handle, tip)
	elseif kind == "scythe" then
		local blade = Instance.new("WedgePart")
		blade.CanCollide = false
		blade.Massless = true
		blade.Material = Enum.Material.Neon
		blade.Color = color
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
	trail.Color = ColorSequence.new(color)
	trail.LightEmission = 1
	trail.Lifetime = 0.2
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = handle
	return tool
end

local function swing(player, tool)
	local now = os.clock()
	-- The Star Slap (no rarity) is slower and shorter than the rarity weapons.
	local isSlap = tool:GetAttribute("Rarity") == nil
	local range = isSlap and W.Range * 0.7 or W.Range
	if now - (lastSwing[player] or 0) < (isSlap and W.Cooldown * 1.6 or W.Cooldown) then
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
			if offset.Magnitude <= range and flat.Magnitude > 0.1 and flat.Unit:Dot(look) > 0.25
				and (immuneUntil[other] or 0) < now
				and not services.LaunchService:Current(other) and not services.HuntService:IsHunting(other) then
				immuneUntil[other] = now + W.Immunity
				-- Knocks one meteor they are carrying home out of their hands.
				local dropped = services.CarryService:DropOne(other, oroot.Position + flat.Unit * 6)
				if dropped then
					Notify.Toast(other, player.DisplayName .. " knocked your " .. dropped .. " out!", "bad")
					Notify.Toast(player, "You knocked a " .. dropped .. " out of " .. other.DisplayName .. "!", "good")
				end
				hitRemote:FireAllClients({
					attacker = player.UserId,
					victim = other.UserId,
					position = oroot.Position,
					direction = flat.Unit,
					dropped = dropped,
					rarity = tool:GetAttribute("Rarity"),
				})
			end
		end
	end
end

-- Everybody has the Star Slap from the start, so anyone can knock a meteor out of a carrier.
local SLAP = "Star Slap"
local function makeSlap(player)
	local tool = Instance.new("Tool")
	tool.Name = SLAP
	tool.ToolTip = "Slap players carrying meteors home to make them drop one"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	local handle = part({
		Name = "Handle",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.4, 1.4, 1.4),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(120, 220, 255),
	})
	handle.Parent = tool
	local light = Instance.new("PointLight")
	light.Color = handle.Color
	light.Range = 8
	light.Parent = handle
	tool.Activated:Connect(function()
		swing(player, tool)
	end)
	return tool
end

-- The meteor chosen as the weapon of a completed rarity (default: the strongest of the set).
local function pickFor(data, rarityId)
	local pick = data.weaponPicks and data.weaponPicks[rarityId]
	local members = Meteors.SetMembers(rarityId)
	if pick and table.find(members, pick) then
		return pick
	end
	local best, bestDmg
	for _, id in ipairs(members) do
		local def = Meteors.ByID[id]
		if not bestDmg or def.baseDamage > bestDmg then
			best, bestDmg = id, def.baseDamage
		end
	end
	return best
end

-- Gives the player one weapon per completed rarity, with the head they picked; replaces a weapon
-- whose head changed.
function WeaponService:Refresh(player, announce)
	local data = services.DataService:Get(player)
	if not data then
		return
	end
	owned[player] = owned[player] or {}
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	if not backpack:FindFirstChild(SLAP) and not (player.Character and player.Character:FindFirstChild(SLAP)) then
		makeSlap(player).Parent = backpack
	end
	for _, rarity in ipairs(Meteors.Rarities) do
		local r = rarity.id
		if Meteors.Weapons[r] and Meteors.SetComplete(r, data.index) then
			local head = pickFor(data, r)
			local name = toolName(r, head)
			for _, container in ipairs({ backpack, player.Character }) do
				if container then
					for _, t in ipairs(container:GetChildren()) do
						if t:IsA("Tool") and t:GetAttribute("Rarity") == r and t.Name ~= name then
							t:Destroy() -- the player picked another head
						end
					end
				end
			end
			local has = backpack:FindFirstChild(name) or (player.Character and player.Character:FindFirstChild(name))
			if not has then
				local tool = makeTool(r, head)
				tool.Activated:Connect(function()
					swing(player, tool)
				end)
				tool.Parent = backpack
			end
			if announce and not owned[player][r] then
				Notify.Toast(player, "⚔ All " .. r .. " meteors found! Your " .. name .. " is ready (pick its meteor in the Index)", "good")
				Notify.Chat(player.DisplayName .. " found every " .. r .. " meteor and forged a " .. name .. "!", rarity.color)
			end
			owned[player][r] = true
		end
	end
end

-- Index window: choose which meteor of a completed rarity is the weapon's head.
local function pickWeapon(player, rarityId, typeId)
	local data = services.DataService:Get(player)
	local def = typeof(typeId) == "string" and Meteors.ByID[typeId]
	if not data or typeof(rarityId) ~= "string" or not def or def.rarity ~= rarityId or def.exclusive then
		return
	end
	if not Meteors.SetComplete(rarityId, data.index) then
		Notify.Toast(player, "Find every " .. rarityId .. " meteor first", "bad")
		return
	end
	data.weaponPicks = data.weaponPicks or {}
	data.weaponPicks[rarityId] = typeId
	WeaponService:Refresh(player, false)
	services.MeteorService:PushSnapshot(player)
	Notify.Toast(player, "⚔ Your " .. rarityId .. " weapon is now the " .. toolName(rarityId, typeId), "good")
end

function WeaponService:Init(s)
	services = s
	hitRemote = Remotes.Get("WeaponHit")
end

function WeaponService:Start()
	Remotes.Get("PickWeapon").OnServerEvent:Connect(function(player, rarityId, typeId)
		if require(Server.RateLimit).Allow(player, "PickWeapon", 0.5) then
			pickWeapon(player, rarityId, typeId)
		end
	end)
	services.DataService.PlayerLoaded:Connect(function(player)
		owned[player] = {}
		WeaponService:Refresh(player, false)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			WeaponService:Refresh(player, false)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		immuneUntil[player] = nil
		owned[player] = nil
	end)
end

return WeaponService
