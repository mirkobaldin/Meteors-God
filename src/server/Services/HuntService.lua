-- Cosmic Hunt: step into the portal, fly through deep space (far above the map) and smash as
-- many small planets as you can before the time runs out. Every planet gives Stardust, the
-- currency used to feed meteors. The hunt planets are shared by every hunter on the server.
--
-- Hunt planets are small Terrain balls (crust, patches, a lava core): every hit carves a crater
-- when the thrown meteor lands, and a broken planet cracks, glows and explodes into pieces.
-- Each planet has an invisible marker Part in workspace.HuntPlanets with its HP for the clients.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local Planets = require(Shared.Config.Planets)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)
local RateLimit = require(Server.RateLimit)

local HuntService = {}

local H = Game.Hunt
local services
local rng = Random.new()
local terrain = workspace.Terrain
local folder
local stateRemote, fxRemote
local sessions = {} -- [player] = {endsAt, score, stardust, lastShot}
local planets = {} -- [marker] = {center, r, hp, maxHP, reward, look, dead}

-- Looks borrowed from the big planets (their terrain materials and colors).
local LOOKS = {}
for name, def in pairs(Planets.Defs) do
	if not def.legendary then
		table.insert(LOOKS, {
			name = (name:gsub(" Planet", "")) .. " Moon",
			crust = def.crust.material,
			patch = def.crust.patches and def.crust.patches[1] and def.crust.patches[1][1],
			core = def.core,
			atmosphere = def.atmosphere,
		})
	end
end
table.sort(LOOKS, function(a, b)
	return a.name < b.name
end)

-- Fills or empties a ball as a stack of discs over a few frames (no hitch).
local function ballSlices(center, radius, material)
	local slice, count, y = 4, 0, -radius
	while y < radius do
		local mid = y + slice / 2
		local r = math.sqrt(math.max(radius * radius - mid * mid, 0))
		if r > 1 then
			terrain:FillCylinder(CFrame.new(center + Vector3.new(0, mid, 0)), slice, r, material)
		end
		y += slice
		count += 1
		if count % 10 == 0 then
			task.wait()
		end
	end
end

local function hunters()
	local list = {}
	for player in pairs(sessions) do
		table.insert(list, player)
	end
	return list
end

local function broadcast(payload)
	for _, player in ipairs(hunters()) do
		fxRemote:FireClient(player, payload)
	end
end

local function freePoint(r)
	local best
	for _ = 1, 20 do
		local dir = rng:NextUnitVector()
		dir = Vector3.new(dir.X, dir.Y * 0.35, dir.Z)
		local point = H.Center + dir * rng:NextNumber(H.Radius * 0.2, H.Radius)
		local ok = true
		for _, other in pairs(planets) do
			if (other.center - point).Magnitude < other.r + r + 80 then
				ok = false
				break
			end
		end
		best = point
		if ok then
			break
		end
	end
	return best
end

local function spawnHuntPlanet(announce)
	local r = math.floor(rng:NextNumber(H.PlanetRadius[1], H.PlanetRadius[2]))
	local look = LOOKS[rng:NextInteger(1, #LOOKS)]
	local center = freePoint(r)
	local k = (r - H.PlanetRadius[1]) / (H.PlanetRadius[2] - H.PlanetRadius[1])
	local hits = H.PlanetHits[1] + (H.PlanetHits[2] - H.PlanetHits[1]) * k

	local marker = Instance.new("Part")
	marker.Name = "HuntPlanet"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.Transparency = 1
	marker.Size = Vector3.one
	marker.CFrame = CFrame.new(center)
	marker:SetAttribute("Title", look.name)
	marker:SetAttribute("Radius", r)
	marker:SetAttribute("HP", hits)
	marker:SetAttribute("MaxHP", hits)
	marker:SetAttribute("Color", look.atmosphere)
	local planet = {
		marker = marker,
		center = center,
		r = r,
		hp = hits,
		maxHP = hits,
		reward = math.max(1, math.floor(H.StardustPerPlanet * r / H.PlanetRadius[1])),
		look = look,
	}
	planets[marker] = planet

	if announce then
		broadcast({ kind = "spawn", center = center, radius = r, color = look.atmosphere })
		task.wait(0.4)
	end
	terrain:FillBall(center, r, look.crust)
	if look.patch then
		for _ = 1, 5 do
			local pr = r * rng:NextNumber(0.2, 0.32)
			terrain:FillBall(center + rng:NextUnitVector() * (r - pr * 0.5), pr, look.patch)
		end
	end
	terrain:FillBall(center, r * 0.42, Enum.Material.CrackedLava) -- exposed by deep craters

	-- Thin atmosphere so they read against the sky (not hit by raycasts).
	local atmo = Instance.new("Part")
	atmo.Name = "Atmosphere"
	atmo.Shape = Enum.PartType.Ball
	atmo.Anchored = true
	atmo.CanCollide = false
	atmo.CanQuery = false
	atmo.CanTouch = false
	atmo.CastShadow = false
	atmo.Material = Enum.Material.ForceField
	atmo.Color = look.atmosphere
	atmo.Transparency = 0.55
	atmo.Size = Vector3.one * r * 2.35
	atmo.CFrame = CFrame.new(center)
	atmo.Parent = marker
	marker.Parent = folder
	return planet
end

local function planetAt(point)
	local best, bestD
	for _, planet in pairs(planets) do
		local d = (planet.center - point).Magnitude
		if d <= planet.r * 1.3 and (not bestD or d < bestD) then
			best, bestD = planet, d
		end
	end
	return best
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
	character:PivotTo(CFrame.new(H.Center + Vector3.new(rng:NextNumber(-200, 200), 0, -H.Radius * 1.05), H.Center))
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

-- How much of a planet's HP one throw takes: 1 hit, more for rarer and fed meteors.
local function hitValue(meteor)
	local def = Meteors.ByID[meteor.t]
	local rarity = def and Meteors.RarityByID[def.rarity]
	return 1 + (rarity and (rarity.order - 1) * 0.15 or 0) + (meteor.lv or 0) * 0.1
end

local function shatter(planet, player)
	planet.dead = true
	planet.marker:SetAttribute("HP", 0)
	local s = sessions[player]
	local reward = 0
	if s then
		s.score += 1
		reward = services.PlayerService:AddStardust(player, planet.reward)
		s.stardust += reward
		sync(player)
	end
	broadcast({
		kind = "shatter",
		center = planet.center,
		radius = planet.r,
		color = planet.look.atmosphere,
		core = planet.look.core,
		delay = H.ShatterDelay,
		killer = player.UserId,
		reward = reward,
	})
	task.delay(H.ShatterDelay, function()
		planet.marker:Destroy()
		ballSlices(planet.center, planet.r * 1.3, Enum.Material.Air)
		planets[planet.marker] = nil
		task.wait(H.RespawnDelay)
		spawnHuntPlanet(true)
	end)
end

local function land(player, planet, point, normal, meteor, damage)
	if planet.dead or planets[planet.marker] ~= planet then
		return
	end
	local value = hitValue(meteor)
	planet.hp -= value
	local cr = planet.r * math.clamp(0.14 + 0.3 * value / planet.maxHP, 0.14, 0.4)
	terrain:FillBall(point + normal * cr * 0.25, cr, Enum.Material.Air)
	broadcast({
		kind = "hit",
		point = point,
		normal = normal,
		crater = cr,
		damage = damage,
		meteorType = meteor.t,
		thrower = player.UserId,
		crustColor = planet.look.atmosphere,
	})
	if planet.hp <= 0.001 then
		shatter(planet, player)
	else
		planet.marker:SetAttribute("HP", planet.hp)
	end
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
	local origin = root.Position + Vector3.new(0, 3, 0)
	local dir = aim - origin
	if dir.Magnitude < 1 then
		return
	end
	dir = dir.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { terrain }
	local result = workspace:Raycast(origin, dir * H.Range, params)
	local planet = result and planetAt(result.Position)
	local to = result and result.Position or origin + dir * H.Range
	local travel = math.clamp((to - origin).Magnitude / H.ProjectileSpeed, 0.25, 1.8)
	local damage = services.LaunchService:Damage(player, meteor, 0.75, false)
	broadcast({
		kind = "throw",
		from = origin,
		to = to,
		travel = travel,
		meteorType = meteor.t,
		mutation = meteor.m,
		thrower = player.UserId,
	})
	if planet and not planet.dead then
		local normal = result.Normal
		task.delay(travel, land, player, planet, to, normal, meteor, damage)
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
	task.spawn(function()
		for _ = 1, H.PlanetCount do
			spawnHuntPlanet(false)
			task.wait(0.1)
		end
	end)
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
