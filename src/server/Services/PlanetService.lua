-- The target planets, one per tier (= one per Bifrost lane), all made of Roblox Terrain:
-- crust with surface features, a CrackedLava mantle, a hollow center with a neon core.
-- Each hit carves a real crater (size from the damage share) and leaves a mark of the meteor's
-- element (ice spikes, lava, toxic goo...). Planets arrive through a space-time rift.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Planets = require(Shared.Config.Planets)
local Meteors = require(Shared.Config.Meteors)
local TerrainConfig = require(Shared.Config.Terrain)
local PlanetMath = require(Shared.Util.PlanetMath)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)

local PlanetService = {}

local services
local rng = Random.new()
local terrain = workspace.Terrain
local destroyedRemote
local fxRemote
local rootFolder

local tiers = {} -- [tier] = state (see spawnPlanet)
local indices = {} -- [tier] = position in the tier sequence
local legendaryQueued = false

local RIFT_OPEN = 2.4 -- seconds before the planet appears (crack, shatter, tear open)
local RIFT_CLOSE = 2.6 -- seconds the rift stays open after the planet appears
local PAINT_MAX = 48 -- studs: max radius of crater painting (ReadVoxels cost)

-- Geometry helpers ------------------------------------------------------------------------

local function randomDir()
	return rng:NextUnitVector()
end

-- CFrame at `pos` whose Y axis points along `up` (for FillCylinder / FillBlock).
local function upFrame(pos, up)
	local ref = math.abs(up.Y) < 0.9 and Vector3.new(0, 1, 0) or Vector3.new(1, 0, 0)
	local right = ref:Cross(up).Unit
	return CFrame.fromMatrix(pos, right, up)
end

local function crustColor(def)
	return TerrainConfig.Colors[def.crust.material.Name] or Color3.fromRGB(120, 110, 100)
end

-- Repaints the solid voxels within `radius` of `center` (outside the mantle) with `material`.
local function paint(center, radius, material, s)
	radius = math.min(radius, PAINT_MAX)
	local region = Region3.new(center - Vector3.one * radius, center + Vector3.one * radius):ExpandToGrid(4)
	local ok, mats, occs = pcall(terrain.ReadVoxels, terrain, region, 4)
	if not ok then
		return
	end
	local size = mats.Size
	local corner = region.CFrame.Position - region.Size / 2
	local minR = s.R * Planets.MantleRadius + 4
	for x = 1, size.X do
		for y = 1, size.Y do
			for z = 1, size.Z do
				if occs[x][y][z] > 0 then
					local p = corner + Vector3.new(x - 0.5, y - 0.5, z - 0.5) * 4
					if (p - center).Magnitude <= radius and (p - s.center).Magnitude > minR then
						mats[x][y][z] = material
					end
				end
			end
		end
	end
	terrain:WriteVoxels(region, 4, mats, occs)
end

-- Tapered crystal / spike growing from `base` along `dir`.
local function spike(base, dir, length, width, material)
	local steps = 3
	for i = 0, steps - 1 do
		local t = i / steps
		local w = width * (1 - t * 0.7)
		local segment = length / steps
		local cf = upFrame(base + dir * (segment * (i + 0.5)), dir) * CFrame.Angles(0, math.rad(45), 0)
		terrain:FillBlock(cf, Vector3.new(w, segment + 2, w), material)
	end
end

-- Cone (mountain / volcano) standing on the surface at `dir`.
local function cone(s, dir, height, radius, material)
	local base = s.center + dir * (s.R - 6)
	local steps = 6
	for i = 0, steps - 1 do
		local t = i / steps
		terrain:FillCylinder(upFrame(base + dir * (height * t + height / steps / 2), dir), height / steps + 4,
			radius * (1 - t * 0.82), material)
	end
	return base + dir * height
end

-- Fills (or empties, with Air) a sphere as a stack of thin discs spread over several frames.
-- One giant FillBall freezes the server and every client for a moment; slices don't.
local SLICE = 4
local SLICES_PER_FRAME = 8 -- spread over more frames: smaller spikes
local function sphereSlices(center, radius, material)
	local count = 0
	local y = -radius
	while y < radius do
		local mid = y + SLICE / 2
		local r = math.sqrt(math.max(radius * radius - mid * mid, 0))
		if r > 1 then
			terrain:FillCylinder(CFrame.new(center + Vector3.new(0, mid, 0)), SLICE, r, material)
		end
		y += SLICE
		count += 1
		if count % SLICES_PER_FRAME == 0 then
			task.wait()
		end
	end
end

-- Planet building --------------------------------------------------------------------------

local function addFeatures(s)
	local def = s.def
	local R = s.R
	for _, patch in ipairs(def.crust.patches or {}) do
		local material, count, size = patch[1], patch[2], patch[3]
		for _ = 1, count do
			local r = R * size * rng:NextNumber(0.7, 1.2)
			terrain:FillBall(s.center + randomDir() * (R - r * 0.6), r, material)
		end
	end
	if def.crust.poles then
		for _, sign in ipairs({ 1, -1 }) do
			terrain:FillBall(s.center + Vector3.new(0, sign * R * 0.78, 0), R * 0.32, def.crust.poles)
		end
	end
	for _, feature in ipairs(def.features or {}) do
		for _ = 1, feature.count do
			local dir = randomDir()
			if feature.kind == "mountains" then
				local h = R * rng:NextNumber(0.1, 0.2)
				local top = cone(s, dir, h, h * 1.1, feature.material)
				if feature.material == Enum.Material.Rock then
					terrain:FillBall(top - dir * h * 0.1, h * 0.3, Enum.Material.Snow)
				end
			elseif feature.kind == "volcano" then
				local h = R * rng:NextNumber(0.12, 0.2) * (feature.scale or 1)
				local top = cone(s, dir, h, h * 1.3, feature.material)
				terrain:FillBall(top - dir * h * 0.15, h * 0.32, Enum.Material.CrackedLava)
				terrain:FillBall(top + dir * h * 0.05, h * 0.22, Enum.Material.Air)
				-- Smoke plume from the crater.
				local vent = Instance.new("Part")
				vent.Name = "Vent"
				vent.Anchored = true
				vent.CanCollide = false
				vent.CanQuery = false
				vent.CanTouch = false
				vent.Transparency = 1
				vent.Size = Vector3.one
				vent.CFrame = upFrame(top, dir)
				vent.Parent = s.folder
				local smoke = Instance.new("ParticleEmitter")
				smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
				smoke.Color = ColorSequence.new(Color3.fromRGB(255, 140, 60), Color3.fromRGB(60, 50, 50))
				smoke.LightEmission = 0.3
				smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, h * 0.25), NumberSequenceKeypoint.new(1, h * 0.8) })
				smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
				smoke.Lifetime = NumberRange.new(4, 6)
				smoke.Speed = NumberRange.new(h * 0.25, h * 0.4)
				smoke.Rate = 4
				smoke.SpreadAngle = Vector2.new(12, 12)
				smoke.Rotation = NumberRange.new(0, 360)
				smoke.RotSpeed = NumberRange.new(-20, 20)
				smoke.Parent = vent
			elseif feature.kind == "spikes" then
				for _ = 1, rng:NextInteger(2, 4) do
					local d = (dir + randomDir() * 0.08).Unit
					local length = R * rng:NextNumber(0.1, 0.24) * (feature.scale or 1)
					local tilt = (d + randomDir() * 0.25).Unit
					spike(s.center + d * (R - 10), tilt, length, length * 0.22, feature.material)
				end
			elseif feature.kind == "craters" then
				local cr = R * rng:NextNumber(0.05, 0.11)
				terrain:FillBall(s.center + dir * (R + cr * 0.35), cr, Enum.Material.Air)
			end
		end
	end
end

-- Stripes of other materials around the planet (Candy).
local function addBands(s)
	local bands = s.def.bands
	if not bands then
		return
	end
	for i, material in ipairs(bands) do
		local y = s.R * (-0.75 + (i - 1) * 1.5 / math.max(1, #bands - 1))
		local thick = s.R * 0.09
		local r = math.sqrt(math.max(s.R * s.R - y * y, 0)) + 3
		terrain:FillCylinder(CFrame.new(s.center + Vector3.new(0, y, 0)), thick, r, material)
	end
end

local function decoPart(s, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	if props.Shape then
		p.Shape = props.Shape
	end
	for k, v in pairs(props) do
		if k ~= "Shape" then
			p[k] = v
		end
	end
	p.Parent = s.folder
	return p
end

-- Planetary ring made of flat segments, and small rocky moons around the planet.
local function addRingAndMoons(s)
	local ring = s.def.ring
	if ring then
		local frame = CFrame.new(s.center) * CFrame.Angles(math.rad(ring.tilt), 0, math.rad(ring.tilt * 0.4))
		local inner, outer = s.R * ring.inner, s.R * ring.outer
		local mid, width = (inner + outer) / 2, outer - inner
		local count = 48
		local segLen = 2 * math.pi * mid / count + 2
		for i = 1, count do
			local a = i / count * math.pi * 2
			decoPart(s, {
				Name = "Ring",
				Size = Vector3.new(math.min(width, 2048), 3, math.min(segLen, 2048)),
				CFrame = frame * CFrame.Angles(0, a, 0) * CFrame.new(mid, 0, 0),
				Material = ring.material,
				Color = ring.color:Lerp(Color3.new(1, 1, 1), (i % 3) * 0.06),
				Transparency = 0.15,
			})
		end
	end
	for i = 1, s.def.moons or 0 do
		local dir = randomDir()
		local size = s.R * rng:NextNumber(0.1, 0.16) * 2
		decoPart(s, {
			Name = "Moon",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * math.min(size, 2048),
			CFrame = CFrame.new(s.center + dir * s.R * (1.9 + i * 0.25)),
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(150, 140, 160):Lerp(s.def.atmosphere, 0.25),
		})
	end
end

local function buildPlanet(s)
	local R = s.R
	sphereSlices(s.center, R, s.def.crust.material)
	addBands(s)
	addFeatures(s)
	addRingAndMoons(s)
	sphereSlices(s.center, R * Planets.MantleRadius, Enum.Material.CrackedLava)
	sphereSlices(s.center, R * Planets.CavityRadius, Enum.Material.Air)

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Anchored = true
	core.CanCollide = false
	core.CanTouch = false
	core.CastShadow = false
	core.Material = Enum.Material.Neon
	core.Color = s.def.core
	core.Size = Vector3.one * R * Planets.CoreRadius * 2
	core.CFrame = CFrame.new(s.center)
	core.Parent = s.folder
	local light = Instance.new("PointLight")
	light.Color = s.def.core
	light.Range = 60
	light.Brightness = 3
	light.Parent = core
	TweenService:Create(core, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Size = core.Size * 1.08,
	}):Play()
	s.core = core

	local atmosphere = Instance.new("Part")
	atmosphere.Name = "Atmosphere"
	atmosphere.Shape = Enum.PartType.Ball
	atmosphere.Anchored = true
	atmosphere.CanCollide = false
	atmosphere.CanQuery = false
	atmosphere.CanTouch = false
	atmosphere.CastShadow = false
	atmosphere.Material = Enum.Material.ForceField
	atmosphere.Color = s.def.atmosphere
	atmosphere.Transparency = 0.6
	atmosphere.Size = Vector3.one * math.min(R * 2.12, 2048)
	atmosphere.CFrame = CFrame.new(s.center)
	atmosphere.Parent = s.folder
end

local function clearPlanet(s)
	s.folder:ClearAllChildren()
	sphereSlices(s.center, s.R * 1.35, Enum.Material.Air) -- surface features reach ~1.3R
end

-- State --------------------------------------------------------------------------------------

local function currentLayer(s)
	local lost = s.maxHP - s.hp
	local crust, mantle = Planets.Layers[1].share, Planets.Layers[2].share
	if lost < s.maxHP * crust then
		return 1
	elseif lost < s.maxHP * (crust + mantle) then
		return 2
	end
	return 3
end

local function updateAttributes(s)
	local f = s.folder
	f:SetAttribute("Tier", s.tier)
	f:SetAttribute("PlanetName", s.def.name)
	f:SetAttribute("HP", s.hp)
	f:SetAttribute("MaxHP", s.maxHP)
	f:SetAttribute("Layer", Planets.Layers[currentLayer(s)].id)
	f:SetAttribute("Legendary", s.def.legendary == true)
	f:SetAttribute("Center", s.center)
	f:SetAttribute("Radius", s.R)
	f:SetAttribute("Ready", not s.arriving and not s.destroyed)
end

function PlanetService:IsTargetable(tier)
	local s = tiers[tier]
	return s ~= nil and not s.destroyed and not s.arriving
end

function PlanetService:Get(tier)
	return tiers[tier]
end

local spawnPlanet

local function nextPlanet(tier)
	if tier == Planets.LegendaryTier and legendaryQueued then
		legendaryQueued = false
		spawnPlanet(tier, Planets.Legendary())
	else
		spawnPlanet(tier, Planets.Get(tier, indices[tier]))
	end
end

function spawnPlanet(tier, def)
	local tierDef = Planets.Tiers[tier]
	local playerCount = math.max(1, #Players:GetPlayers())
	local maxHP = math.floor(def.hp * (0.6 + 0.4 * playerCount))
	local folder = rootFolder:FindFirstChild("Tier" .. tier)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Tier" .. tier
		folder.Parent = rootFolder
	end
	local s = {
		tier = tier,
		def = def,
		maxHP = maxHP,
		hp = maxHP,
		folder = folder,
		center = tierDef.position,
		R = Planets.RadiusFor(tier, def.hp),
		contributions = {},
		arriving = true,
		destroyed = false,
		layer = 1,
	}
	tiers[tier] = s
	updateAttributes(s)

	fxRemote:FireAllClients({
		kind = "rift",
		tier = tier,
		center = s.center,
		radius = s.R,
		color = def.atmosphere,
		crust = crustColor(def),
		material = def.crust.material.Name,
		open = RIFT_OPEN,
		close = RIFT_OPEN + RIFT_CLOSE,
	})
	if def.legendary then
		Notify.Announce("⭐ A " .. def.name .. " TORE THROUGH SPACE! x3 rewards!", Color3.fromRGB(255, 210, 60))
	else
		Notify.Chat("🌀 " .. tierDef.name .. ": " .. def.name .. " is coming through a rift!", tierDef.color)
	end

	task.wait(RIFT_OPEN)
	if tiers[tier] ~= s then
		return
	end
	buildPlanet(s)
	s.arriving = false
	updateAttributes(s)
end

-- Aiming ----------------------------------------------------------------------------------------

local function surfaceAlong(origin, dir, s)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { terrain, s.core }
	local result = workspace:Raycast(origin, dir * ((s.center - origin).Magnitude + s.R * 1.5), params)
	if result and (result.Position - s.center).Magnitude <= s.R * 1.5 then
		return result.Position
	end
	return nil
end

-- Impact point for a throw from `origin` aimed at `aim`. Rays follow the real terrain, so
-- meteors fly into existing craters and can reach the mantle and the core.
function PlanetService:ResolveImpact(tier, origin, aim)
	local s = tiers[tier]
	if not s then
		return aim, Vector3.new(0, 1, 0)
	end
	local delta = aim - origin
	local dir = delta.Magnitude > 1e-3 and delta.Unit or (s.center - origin).Unit
	local hit = surfaceAlong(origin, dir, s)
	if not hit then
		-- Missed: snap to the closest point of the planet (the edge you were aiming near).
		local snapped = PlanetMath.ImpactFromAim(origin, aim, s.center, s.R)
		hit = surfaceAlong(origin, (snapped - origin).Unit, s) or snapped
	end
	local normal = (hit - s.center)
	normal = normal.Magnitude > 1e-3 and normal.Unit or -dir
	return hit, normal
end

-- Hits ----------------------------------------------------------------------------------------

-- Leaves the meteor's element in the crater (persistent terrain).
local function decorateCrater(s, impactKind, floor, n, cr)
	local lining = {
		magma = Enum.Material.CrackedLava,
		nova = Enum.Material.CrackedLava,
		venom = Enum.Material.Mud,
		solar = Enum.Material.Sandstone,
		void = Enum.Material.Asphalt,
		frost = Enum.Material.Ice,
		crystal = Enum.Material.Salt,
	}
	paint(floor + n * cr * 0.3, cr * 1.25, lining[impactKind] or Enum.Material.Basalt, s)
	if impactKind == "frost" or impactKind == "crystal" then
		local material = impactKind == "frost" and Enum.Material.Glacier or Enum.Material.Salt
		for _ = 1, rng:NextInteger(4, 7) do
			local offset = randomDir() * cr * 0.45
			local base = floor + offset - n * 4
			local dir = (n + randomDir() * 0.35).Unit
			local length = cr * rng:NextNumber(0.6, 1.1)
			spike(base, dir, length, length * 0.22, material)
		end
	end
end

local function supernova(s)
	s.destroyed = true
	updateAttributes(s)
	fxRemote:FireAllClients({
		kind = "supernova",
		tier = s.tier,
		center = s.center,
		radius = s.R,
		color = s.def.core,
		crustColor = crustColor(s.def),
	})
	task.spawn(clearPlanet, s)

	local total = 0
	for _, dmg in pairs(s.contributions) do
		total += dmg
	end
	local mvp, mvpDamage, finisher = nil, 0, s.finisher
	for userId, dmg in pairs(s.contributions) do
		local player = Players:GetPlayerByUserId(userId)
		local data = player and services.DataService:Get(player)
		if data and total > 0 then
			local share = dmg / total
			if share >= Game.Economy.MinContributionShare then
				data.planetsDestroyed += 1
			end
			local shards = services.PlayerService:AddShards(player, s.def.reward * share, true)
			destroyedRemote:FireClient(player, { name = s.def.name, shards = shards, share = share })
			services.PlayerService:Sync(player)
			if dmg > mvpDamage then
				mvp, mvpDamage = player, dmg
			end
		end
	end
	Notify.Announce(
		"💥 The " .. s.def.name .. " was DESTROYED!"
			.. (finisher and (" Final blow: " .. finisher.DisplayName) or "")
			.. (mvp and (" · MVP: " .. mvp.DisplayName) or ""),
		Color3.fromRGB(255, 140, 60)
	)
	services.ShowerService:SpawnBurst(Game.Cycle.PlanetDestroyedBonusMeteors, Game.Cycle.PlanetDestroyedBonusLuck)

	local wasLegendary = s.def.legendary
	task.delay(Game.Cycle.NextPlanetDelay, function()
		if tiers[s.tier] ~= s then
			return
		end
		if not wasLegendary then
			indices[s.tier] += 1
		end
		nextPlanet(s.tier)
	end)
end

local finishIfDead

-- Extra damage from a meteor ability (no crater): chain strikes, burns, poison.
function PlanetService:ApplyBonus(tier, player, amount, point, normal, label, color)
	local s = tiers[tier]
	if not s or s.destroyed or s.arriving then
		return 0
	end
	amount = math.floor(amount * PlanetService:MarkMult(s))
	local dealt = math.min(amount, s.hp)
	if dealt <= 0 then
		return 0
	end
	s.hp -= dealt
	s.contributions[player.UserId] = (s.contributions[player.UserId] or 0) + dealt
	fxRemote:FireAllClients({ kind = "bonus", tier = tier, point = point, normal = normal, damage = dealt, label = label, color = color, thrower = player.UserId })
	updateAttributes(s)
	finishIfDead(s, player)
	return dealt
end

-- Abilities like Deep Freeze: the planet takes +value damage from everyone for `duration` seconds.
function PlanetService:Mark(tier, value, duration, label)
	local s = tiers[tier]
	if not s or s.destroyed then
		return
	end
	s.markValue = math.max(s.markUntil and s.markUntil > os.clock() and s.markValue or 0, value)
	s.markUntil = os.clock() + duration
	fxRemote:FireAllClients({ kind = "mark", tier = tier, center = s.center, radius = s.R, label = label, duration = duration })
end

function PlanetService:MarkMult(s)
	return (s.markUntil and s.markUntil > os.clock()) and (1 + s.markValue) or 1
end

-- Applies damage from a meteor impact. Returns the damage actually dealt.
function PlanetService:ApplyHit(tier, player, damage, impact, normal, crit, color, meteorType)
	local s = tiers[tier]
	if not s or s.destroyed or s.arriving then
		return 0
	end
	damage = math.floor(damage * PlanetService:MarkMult(s))
	local dealt = math.min(damage, s.hp)
	s.hp -= dealt
	s.contributions[player.UserId] = (s.contributions[player.UserId] or 0) + dealt

	local def = Meteors.ByID[meteorType]
	local impactKind = def and def.impact or "rock"
	local share = dealt / s.maxHP
	local cr = s.R * math.clamp((share * Planets.CraterScale) ^ (1 / 3), Planets.CraterMin, Planets.CraterMax)
	if impactKind == "void" or impactKind == "nova" then
		cr = math.min(cr * 1.3, s.R * Planets.CraterMax)
	end
	local n = (impact - s.center).Magnitude > 1 and (impact - s.center).Unit or normal

	fxRemote:FireAllClients({
		kind = "impact",
		tier = tier,
		point = impact,
		normal = n,
		crater = cr,
		damage = damage,
		crit = crit,
		color = color,
		thrower = player.UserId,
		meteorType = meteorType,
		impact = impactKind,
		crustColor = crustColor(s.def),
	})

	-- Carve the crater: a ball of air centered just above the impact point.
	terrain:FillBall(impact + n * cr * 0.2, cr, Enum.Material.Air)
	decorateCrater(s, impactKind, impact - n * cr * 0.75, n, cr)

	local layer = currentLayer(s)
	if layer > s.layer then
		s.layer = layer
		local text = layer == 2 and ("The crust of " .. s.def.name .. " is shattered! The MANTLE is exposed!")
			or ("The CORE of " .. s.def.name .. " is exposed! Finish it!")
		Notify.Chat(text, layer == 2 and Color3.fromRGB(255, 130, 40) or s.def.core)
		fxRemote:FireAllClients({ kind = "layer", tier = tier, center = s.center, radius = s.R, layer = layer, color = s.def.core })
	end
	updateAttributes(s)
	finishIfDead(s, player)
	return dealt
end

function finishIfDead(s, player)
	if s.hp <= 0 and not s.destroyed then
		s.finisher = player
		supernova(s)
	end
end

-- Developer Product: the Legendary planet replaces the planet of Planets.LegendaryTier
-- (or is queued if a legendary planet is already up).
function PlanetService:SummonLegendary()
	local tier = Planets.LegendaryTier
	local s = tiers[tier]
	if s and s.def.legendary and not s.destroyed then
		legendaryQueued = true
		return
	end
	if s and not s.destroyed then
		s.destroyed = true
		fxRemote:FireAllClients({ kind = "supernova", tier = tier, center = s.center, radius = s.R, color = s.def.core, crustColor = crustColor(s.def) })
		clearPlanet(s)
	end
	task.spawn(spawnPlanet, tier, Planets.Legendary())
end

function PlanetService:Init(s)
	services = s
	destroyedRemote = Remotes.Get("PlanetDestroyed")
	fxRemote = Remotes.Get("PlanetFX")
	rootFolder = Instance.new("Folder")
	rootFolder.Name = "Planets"
	rootFolder.Parent = workspace
end

function PlanetService:Start()
	for tier in ipairs(Planets.Tiers) do
		indices[tier] = 1
		task.delay(2 + tier, nextPlanet, tier)
	end
end

return PlanetService
