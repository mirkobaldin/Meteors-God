-- Cosmic Hunt: step into the portal, fly through deep space (far above the map) and smash as
-- many small planets as you can before the time runs out. Every planet gives Stardust, the
-- currency used to feed meteors. The hunt planets are shared by every hunter on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local TerrainConfig = require(Shared.Config.Terrain)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)
local RateLimit = require(Server.RateLimit)

local HuntService = {}

local H = Game.Hunt
local services
local rng = Random.new()
local folder
local stateRemote, fxRemote
local sessions = {} -- [player] = {endsAt, score, stardust, lastShot}

local LOOKS = {
	{ Enum.Material.Slate, Color3.fromRGB(120, 100, 90) },
	{ Enum.Material.Ice, TerrainConfig.Colors.Ice },
	{ Enum.Material.Basalt, Color3.fromRGB(60, 45, 45) },
	{ Enum.Material.Sand, TerrainConfig.Colors.Sand },
	{ Enum.Material.Rock, Color3.fromRGB(150, 120, 190) },
	{ Enum.Material.Cobblestone, Color3.fromRGB(110, 140, 120) },
}

local function randomPoint()
	local dir = rng:NextUnitVector()
	dir = Vector3.new(dir.X, dir.Y * 0.35, dir.Z)
	return H.Center + dir * rng:NextNumber(H.Radius * 0.2, H.Radius)
end

local function spawnHuntPlanet()
	local r = rng:NextNumber(H.PlanetRadius[1], H.PlanetRadius[2])
	local look = LOOKS[rng:NextInteger(1, #LOOKS)]
	local p = Instance.new("Part")
	p.Name = "HuntPlanet"
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Size = Vector3.one * r * 2
	p.CFrame = CFrame.new(randomPoint())
	p.Material = look[1]
	p.Color = look[2]
	local hp = math.floor(r ^ 1.5 * 8)
	p:SetAttribute("HP", hp)
	p:SetAttribute("MaxHP", hp)
	p:SetAttribute("Reward", math.max(1, math.floor(H.StardustPerPlanet * r / H.PlanetRadius[1])))
	-- Thin atmosphere so they read against the sky.
	local atmo = Instance.new("Part")
	atmo.Name = "Atmosphere"
	atmo.Shape = Enum.PartType.Ball
	atmo.Anchored = true
	atmo.CanCollide = false
	atmo.CanQuery = false
	atmo.CastShadow = false
	atmo.Material = Enum.Material.ForceField
	atmo.Color = look[2]:Lerp(Color3.new(1, 1, 1), 0.4)
	atmo.Transparency = 0.6
	atmo.Size = p.Size * 1.15
	atmo.CFrame = p.CFrame
	atmo.Parent = p
	p.Parent = folder
	return p
end

local function sync(player)
	local s = sessions[player]
	stateRemote:FireClient(player, s and { active = true, endsAt = s.endsAt, score = s.score, stardust = s.stardust } or { active = false })
end

local function endHunt(player, reason)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	player:SetAttribute("Hunting", false)
	local data = services.DataService:Get(player)
	if data and s.score > (data.bestHunt or 0) then
		data.bestHunt = s.score
	end
	stateRemote:FireClient(player, { active = false, score = s.score, stardust = s.stardust, reason = reason })
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		character:PivotTo(CFrame.new(Game.World.SpawnPosition + Vector3.new(0, 5, 0)))
	end
	Notify.Toast(player, string.format("Cosmic Hunt over: %d planets smashed, +%d Stardust", s.score, s.stardust), "good")
end

local function startHunt(player)
	if sessions[player] or not RateLimit.Allow(player, "HuntStart", 1) then
		return
	end
	local data = services.DataService:Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	if (root.Position - H.PortalPosition).Magnitude > 60 then
		return
	end
	if services.TradeService:IsTrading(player) or services.LaunchService:Current(player) then
		Notify.Toast(player, "Finish what you're doing first", "bad")
		return
	end
	sessions[player] = { endsAt = workspace:GetServerTimeNow() + H.Duration, score = 0, stardust = 0, lastShot = 0 }
	player:SetAttribute("Hunting", true)
	character:PivotTo(CFrame.new(H.Center + Vector3.new(rng:NextNumber(-200, 200), 0, -H.Radius * 0.9), H.Center))
	sync(player)
	local mine = sessions[player]
	task.delay(H.Duration, function()
		if sessions[player] == mine then
			endHunt(player, "time")
		end
	end)
end

-- The meteor thrown in the hunt: the equipped one, otherwise the strongest owned.
local function huntMeteor(data)
	if data.equipped ~= "" and data.meteors[data.equipped] then
		return data.meteors[data.equipped]
	end
	local best, bestDmg
	for _, m in pairs(data.meteors) do
		local def = Meteors.ByID[m.t]
		local dmg = def and def.baseDamage or 0
		if not bestDmg or dmg > bestDmg then
			best, bestDmg = m, dmg
		end
	end
	return best
end

local function fire(player, aim)
	local s = sessions[player]
	if not s or typeof(aim) ~= "Vector3" or aim ~= aim then
		return
	end
	local now = os.clock()
	if now - s.lastShot < H.FireCooldown then
		return
	end
	s.lastShot = now
	local data = services.DataService:Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local meteor = data and huntMeteor(data)
	if not root or not meteor then
		return
	end
	local origin = root.Position + Vector3.new(0, 4, 0)
	local dir = (aim - origin)
	if dir.Magnitude < 1 then
		return
	end
	dir = dir.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local result = workspace:Raycast(origin, dir * H.Range, params)
	local target = result and result.Instance
	if target and target.Name == "Atmosphere" then
		target = target.Parent
	end
	local to = result and result.Position or origin + dir * H.Range
	local payload = { from = origin, to = to, meteorType = meteor.t, thrower = player.UserId }
	if target and target:IsA("BasePart") and target.Name == "HuntPlanet" and target.Parent == folder then
		local damage = services.LaunchService:Damage(player, meteor, 0.75, false)
		local hp = (target:GetAttribute("HP") or 0) - damage
		payload.damage = damage
		if hp <= 0 then
			local reward = target:GetAttribute("Reward") or 1
			s.score += 1
			s.stardust += services.PlayerService:AddStardust(player, reward)
			payload.explode = { center = target.Position, radius = target.Size.X / 2, color = target.Color, reward = reward }
			target:Destroy()
			task.delay(3, spawnHuntPlanet)
			sync(player)
		else
			target:SetAttribute("HP", hp)
		end
	end
	for other in pairs(sessions) do
		fxRemote:FireClient(other, payload)
	end
end

function HuntService:Init(s)
	services = s
	stateRemote = Remotes.Get("HuntState")
	fxRemote = Remotes.Get("HuntFX")
	folder = Instance.new("Folder")
	folder.Name = "HuntPlanets"
	folder.Parent = workspace
end

function HuntService:IsHunting(player)
	return sessions[player] ~= nil
end

function HuntService:Start()
	for _ = 1, H.PlanetCount do
		spawnHuntPlanet()
	end
	Remotes.Get("HuntStart").OnServerEvent:Connect(startHunt)
	Remotes.Get("HuntFire").OnServerEvent:Connect(fire)
	Remotes.Get("HuntLeave").OnServerEvent:Connect(function(player)
		endHunt(player, "left")
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
	local function watch(player)
		player.CharacterRemoving:Connect(function()
			if sessions[player] then
				sessions[player] = nil
				player:SetAttribute("Hunting", false)
				stateRemote:FireClient(player, { active = false, reason = "died" })
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do
		watch(p)
	end
end

return HuntService
