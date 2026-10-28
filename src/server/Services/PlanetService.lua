-- The target planet. Built from code as a big icosphere of tectonic plates (crust) over a glowing
-- mantle and core, with an atmosphere glow. Meteors carve craters: the plates nearest to the
-- impact are removed and every client animates them flying into space (see client FX).
-- Optionally uses a hand-made model from Assets/Planets/<name> (see docs/ASSET_PIPELINE.md).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Planets = require(Shared.Config.Planets)
local AssetLibrary = require(Shared.AssetLibrary)
local PlanetMath = require(Shared.Util.PlanetMath)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)

local PlanetService = {}

local services
local rng = Random.new()
local destroyedRemote
local fxRemote

local currentIndex = 1
local legendaryQueued = false
local state -- current planet (see spawnPlanet)

local CENTER = Game.World.PlanetPosition
local R = Game.World.PlanetRadius
local MAX_FX_TILES = 70

-- Geometry -----------------------------------------------------------------

local function icosphere(subdivisions)
	local t = (1 + math.sqrt(5)) / 2
	local verts = {
		Vector3.new(-1, t, 0), Vector3.new(1, t, 0), Vector3.new(-1, -t, 0), Vector3.new(1, -t, 0),
		Vector3.new(0, -1, t), Vector3.new(0, 1, t), Vector3.new(0, -1, -t), Vector3.new(0, 1, -t),
		Vector3.new(t, 0, -1), Vector3.new(t, 0, 1), Vector3.new(-t, 0, -1), Vector3.new(-t, 0, 1),
	}
	for i, v in ipairs(verts) do
		verts[i] = v.Unit
	end
	local faces = {
		{ 1, 12, 6 }, { 1, 6, 2 }, { 1, 2, 8 }, { 1, 8, 11 }, { 1, 11, 12 },
		{ 2, 6, 10 }, { 6, 12, 5 }, { 12, 11, 3 }, { 11, 8, 7 }, { 8, 2, 9 },
		{ 4, 10, 5 }, { 4, 5, 3 }, { 4, 3, 7 }, { 4, 7, 9 }, { 4, 9, 10 },
		{ 5, 10, 6 }, { 3, 5, 12 }, { 7, 3, 11 }, { 9, 7, 8 }, { 10, 9, 2 },
	}
	for _ = 1, subdivisions do
		local cache = {}
		local function midpoint(a, b)
			local key = a < b and (a .. "_" .. b) or (b .. "_" .. a)
			if cache[key] then
				return cache[key]
			end
			table.insert(verts, ((verts[a] + verts[b]) / 2).Unit)
			cache[key] = #verts
			return #verts
		end
		local nextFaces = {}
		for _, f in ipairs(faces) do
			local a, b, c = f[1], f[2], f[3]
			local ab, bc, ca = midpoint(a, b), midpoint(b, c), midpoint(c, a)
			table.insert(nextFaces, { a, ab, ca })
			table.insert(nextFaces, { b, bc, ab })
			table.insert(nextFaces, { c, ca, bc })
			table.insert(nextFaces, { ab, bc, ca })
		end
		faces = nextFaces
	end
	return verts, faces
end

local function newPart(className, props)
	local p = Instance.new(className)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
	end
	for k, v in pairs(props) do
		if k ~= "Shape" then
			p[k] = v
		end
	end
	return p
end

local function ball(diameter, props)
	props.Shape = Enum.PartType.Ball
	props.Size = Vector3.new(diameter, diameter, diameter)
	return newPart("Part", props)
end

-- Draws a thick triangle (slab) with two WedgeParts. The outer face lies on the triangle,
-- the thickness goes towards `inward`.
local function triangle(a, b, c, thickness, inward, props, parent)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local offset = inward * (thickness / 2)

	local w1 = newPart("WedgePart", props)
	w1.Size = Vector3.new(thickness, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2 + offset, right, up, back)
	w1.Parent = parent

	local w2 = newPart("WedgePart", props)
	w2.Size = Vector3.new(thickness, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2 + offset, -right, up, -back)
	w2.Parent = parent
	return { w1, w2 }
end

local function plateLook(def, dir, seed)
	local crust = def.crust
	local n = math.noise(dir.X * 2.2 + seed, dir.Y * 2.2, dir.Z * 2.2 - seed)
	n += 0.5 * math.noise(dir.X * 5 - seed, dir.Y * 5 + seed, dir.Z * 5)
	local v = math.clamp((n + 0.9) / 1.8, 0, 1)
	if crust.accent and v >= crust.accent.threshold then
		return crust.accent.color, crust.accent.material
	end
	if crust.poles and math.abs(dir.Y) > 0.82 then
		return crust.poles, crust.material
	end
	local colors = crust.colors
	local idx = math.clamp(math.floor(v * #colors) + 1, 1, #colors)
	local color = colors[idx]
	local h, s, val = color:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(val + rng:NextNumber(-0.04, 0.04), 0, 1)), crust.material
end

-- Builds the procedural planet. Plates are created a few at a time (the planet "forms" in the sky).
local function buildPlanet(def, center, model)
	local core = ball(R * Planets.CoreRadius * 2, {
		Name = "Core",
		Material = Enum.Material.Neon,
		Color = def.core,
		CFrame = CFrame.new(center),
	})
	core.Parent = model
	local light = Instance.new("PointLight")
	light.Color = def.core
	light.Range = 60
	light.Brightness = 4
	light.Parent = core

	local mantle = ball(R * Planets.MantleRadius * 2, {
		Name = "Mantle",
		Material = Enum.Material.Neon,
		Color = def.mantle,
		CFrame = CFrame.new(center),
	})
	mantle.Parent = model

	local atmosphere = ball(R * 2.16, {
		Name = "Atmosphere",
		Material = Enum.Material.ForceField,
		Color = def.atmosphere or def.mantle,
		CFrame = CFrame.new(center),
		CanQuery = false,
	})
	atmosphere.Parent = model

	if def.ring then
		local ring = newPart("Part", {
			Name = "Ring",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(4, R * 3.4, R * 3.4),
			Material = Enum.Material.Neon,
			Color = def.ring,
			Transparency = 0.5,
			CanQuery = false,
			CFrame = CFrame.new(center) * CFrame.Angles(math.rad(18), 0, math.rad(90)),
		})
		ring.Parent = model
	end

	local tiles = {}
	local verts, faces = icosphere(Planets.CrustSubdivisions)
	local thickness = R * Planets.CrustThickness
	local seed = rng:NextNumber(0, 100)
	-- Build from the top down so the planet visibly assembles.
	table.sort(faces, function(f1, f2)
		return (verts[f1[1]] + verts[f1[2]] + verts[f1[3]]).Y > (verts[f2[1]] + verts[f2[2]] + verts[f2[3]]).Y
	end)
	for i, f in ipairs(faces) do
		local dir = ((verts[f[1]] + verts[f[2]] + verts[f[3]]) / 3).Unit
		local color, material = plateLook(def, dir, seed)
		local parts = triangle(
			center + verts[f[1]] * R,
			center + verts[f[2]] * R,
			center + verts[f[3]] * R,
			thickness,
			-dir,
			{ Name = "Crust", Color = color, Material = material },
			model
		)
		table.insert(tiles, { parts = parts, center = center + dir * R, normal = dir })
		if i % 40 == 0 then
			task.wait()
		end
	end
	return core, mantle, tiles
end

-- Hand-made planet from Assets/Planets/<name>: Crust folder pieces become plates.
local function buildCustomPlanet(custom, def, center, model)
	for _, d in ipairs(custom:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
		end
	end
	custom:PivotTo(CFrame.new(center))
	local tiles = {}
	local crust = custom:FindFirstChild("Crust")
	if crust then
		for _, d in ipairs(crust:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Name = "Crust"
				d.Parent = model
				local dir = (d.Position - center)
				dir = dir.Magnitude > 0 and dir.Unit or Vector3.new(0, 1, 0)
				table.insert(tiles, { parts = { d }, center = d.Position, normal = dir })
			end
		end
	end
	for _, child in ipairs(custom:GetChildren()) do
		if child ~= crust then
			child.Parent = model
		end
	end
	custom:Destroy()
	local core = model:FindFirstChild("Core")
	if not (core and core:IsA("BasePart")) then
		core = ball(R * Planets.CoreRadius * 2, { Name = "Core", Material = Enum.Material.Neon, Color = def.core, CFrame = CFrame.new(center) })
		core.Parent = model
	end
	local mantle = model:FindFirstChild("Mantle")
	if not (mantle and mantle:IsA("BasePart")) then
		mantle = ball(R * Planets.MantleRadius * 2, { Name = "Mantle", Material = Enum.Material.Neon, Color = def.mantle, CFrame = CFrame.new(center) })
		mantle.Parent = model
	end
	return core, mantle, tiles
end

-- State helpers ----------------------------------------------------------------

local function layerShares()
	return Planets.Layers[1].share, Planets.Layers[2].share
end

local function currentLayer()
	if not state then
		return 0
	end
	local lost = state.maxHP - state.hp
	local crust, mantle = layerShares()
	if lost < state.maxHP * crust then
		return 1
	elseif lost < state.maxHP * (crust + mantle) then
		return 2
	end
	return 3
end

function PlanetService:TargetRadius()
	if not state then
		return R
	end
	local layer = currentLayer()
	if layer == 1 then
		return R
	elseif layer == 2 and state.mantle and state.mantle.Parent then
		return state.mantle.Size.X / 2
	end
	return state.core.Size.X / 2
end

local function updateAttributes()
	if state then
		workspace:SetAttribute("PlanetName", state.def.name)
		workspace:SetAttribute("PlanetHP", state.hp)
		workspace:SetAttribute("PlanetMaxHP", state.maxHP)
		workspace:SetAttribute("PlanetLayer", Planets.Layers[math.max(1, currentLayer())].id)
		workspace:SetAttribute("PlanetLegendary", state.def.legendary == true)
		workspace:SetAttribute("PlanetCenter", state.center)
		workspace:SetAttribute("PlanetTargetRadius", PlanetService:TargetRadius())
		workspace:SetAttribute("PlanetReady", not state.arriving and not state.destroyed)
	else
		workspace:SetAttribute("PlanetHP", 0)
		workspace:SetAttribute("PlanetReady", false)
	end
end

local function tileData(tile)
	local out = {}
	for _, p in ipairs(tile.parts) do
		if p.Parent then
			table.insert(out, { cf = p.CFrame, size = p.Size, color = p.Color, mat = p.Material, wedge = p:IsA("WedgePart") })
		end
	end
	return out
end

-- Removes the `count` plates closest to `point`. Returns their data for the client FX.
local function removePlates(point, count)
	local removed = {}
	for _ = 1, count do
		local bestIndex, bestDist
		for i, tile in ipairs(state.tiles) do
			if not tile.gone then
				local d = (tile.center - point).Magnitude
				if not bestDist or d < bestDist then
					bestIndex, bestDist = i, d
				end
			end
		end
		if not bestIndex then
			break
		end
		local tile = state.tiles[bestIndex]
		tile.gone = true
		state.platesRemoved += 1
		if #removed < MAX_FX_TILES then
			for _, data in ipairs(tileData(tile)) do
				table.insert(removed, data)
			end
		end
		for _, p in ipairs(tile.parts) do
			p:Destroy()
		end
	end
	return removed
end

local function nearestPlateDistance(point)
	local best = math.huge
	for _, tile in ipairs(state.tiles) do
		if not tile.gone then
			best = math.min(best, (tile.center - point).Magnitude)
		end
	end
	return best
end

-- Impact point for a throw from `origin` aimed at `aim`. Holes in the crust let meteors reach the mantle.
function PlanetService:ResolveImpact(origin, aim)
	if not state then
		return aim, Vector3.new(0, 1, 0)
	end
	local radius = PlanetService:TargetRadius()
	local point, normal = PlanetMath.ImpactFromAim(origin, aim, state.center, radius)
	if currentLayer() == 1 and state.mantle and state.mantle.Parent then
		local plateSize = R * 0.28
		if nearestPlateDistance(point) > plateSize then
			point, normal = PlanetMath.ImpactFromAim(origin, aim, state.center, state.mantle.Size.X / 2)
		end
	end
	return point, normal
end

-- Spawning ------------------------------------------------------------------------

local function spawnPlanet(def)
	local playerCount = math.max(1, #Players:GetPlayers())
	local maxHP = math.floor(def.hp * (0.6 + 0.4 * playerCount))
	local model = Instance.new("Model")
	model.Name = "Planet"
	model.Parent = workspace

	state = {
		def = def,
		maxHP = maxHP,
		hp = maxHP,
		model = model,
		tiles = {},
		platesRemoved = 0,
		contributions = {},
		center = CENTER,
		arriving = true,
		destroyed = false,
	}
	local myState = state
	updateAttributes()
	fxRemote:FireAllClients({ kind = "arrival", center = CENTER, radius = R, color = def.atmosphere or def.mantle })

	if def.legendary then
		Notify.Announce("⭐ THE " .. def.name .. " HAS ARRIVED! x3 rewards!", Color3.fromRGB(255, 210, 60))
	else
		Notify.Announce("Incoming: " .. def.name .. "!", Color3.fromRGB(200, 220, 255))
	end

	local custom = AssetLibrary.Clone("Planets", def.legendary and "Legendary" or def.name)
	local core, mantle, tiles
	if custom then
		core, mantle, tiles = buildCustomPlanet(custom, def, CENTER, model)
	else
		core, mantle, tiles = buildPlanet(def, CENTER, model)
	end
	if state ~= myState then
		model:Destroy()
		return
	end
	state.core = core
	state.mantle = mantle
	state.mantleBaseSize = mantle.Size
	state.tiles = tiles
	model.PrimaryPart = core
	TweenService:Create(
		core,
		TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Size = core.Size * 1.08 }
	):Play()
	state.arriving = false
	updateAttributes()
end

function PlanetService:IsTargetable()
	return state ~= nil and not state.destroyed and not state.arriving
end

local function updateMantle(impact)
	local crust, mantleShare = layerShares()
	local lost = state.maxHP - state.hp
	local f = math.clamp((lost - state.maxHP * crust) / (state.maxHP * mantleShare), 0, 1)
	local mantle = state.mantle
	if not (mantle and mantle.Parent) then
		return
	end
	if f >= 1 then
		fxRemote:FireAllClients({
			kind = "mantle",
			center = state.center,
			radius = mantle.Size.X / 2,
			color = state.def.mantle,
			point = impact,
		})
		mantle:Destroy()
		Notify.Announce("The mantle of " .. state.def.name .. " exploded! Hit the CORE!", state.def.core)
	elseif f > 0 then
		mantle.Size = state.mantleBaseSize * (1 - 0.25 * f)
		mantle.Color = state.def.mantle:Lerp(Color3.fromRGB(40, 15, 10), 0.55 * f)
	end
end

local function supernova()
	local s = state
	s.destroyed = true
	updateAttributes()

	local leftovers = {}
	for _, tile in ipairs(s.tiles) do
		if not tile.gone and #leftovers < MAX_FX_TILES * 2 then
			for _, data in ipairs(tileData(tile)) do
				table.insert(leftovers, data)
			end
		end
	end
	fxRemote:FireAllClients({
		kind = "supernova",
		center = s.center,
		radius = R,
		color = s.def.core,
		mantleColor = s.def.mantle,
		tiles = leftovers,
	})
	s.model:Destroy()

	-- Rewards by contribution.
	local total = 0
	for _, dmg in pairs(s.contributions) do
		total += dmg
	end
	local mvpName, mvpDamage = nil, 0
	for userId, dmg in pairs(s.contributions) do
		local player = Players:GetPlayerByUserId(userId)
		if player and total > 0 then
			local share = dmg / total
			local data = services.DataService:Get(player)
			if data then
				if share >= Game.Economy.MinContributionShare then
					data.planetsDestroyed += 1
				end
				local shards = services.PlayerService:AddShards(player, s.def.reward * share, true)
				destroyedRemote:FireClient(player, { name = s.def.name, shards = shards, share = share })
				if dmg > mvpDamage then
					mvpName, mvpDamage = player.DisplayName, dmg
				end
			end
		end
	end
	Notify.Announce(
		"💥 The " .. s.def.name .. " was DESTROYED!" .. (mvpName and (" MVP: " .. mvpName) or ""),
		Color3.fromRGB(255, 140, 60)
	)

	services.ShowerService:SpawnBurst(Game.Cycle.PlanetDestroyedBonusMeteors, Game.Cycle.PlanetDestroyedBonusLuck)

	local wasLegendary = s.def.legendary
	task.delay(Game.Cycle.NextPlanetDelay, function()
		if state ~= s then
			return
		end
		if not wasLegendary then
			currentIndex += 1
		end
		if legendaryQueued then
			legendaryQueued = false
			spawnPlanet(Planets.Legendary)
		else
			spawnPlanet(Planets.Get(currentIndex))
		end
	end)
end

-- Applies damage from a meteor impact. Returns the damage actually dealt.
function PlanetService:ApplyHit(player, damage, impact, normal, crit, color)
	if not state or state.destroyed or state.arriving then
		return 0
	end
	local dealt = math.min(damage, state.hp)
	state.hp -= dealt
	state.contributions[player.UserId] = (state.contributions[player.UserId] or 0) + dealt

	-- Crust: keep the number of removed plates proportional to the crust HP lost.
	local crustHP = state.maxHP * Planets.Layers[1].share
	local lostCrust = math.min(state.maxHP - state.hp, crustHP)
	local target = math.floor(lostCrust / crustHP * #state.tiles + 1e-6)
	local removed = {}
	if target > state.platesRemoved then
		removed = removePlates(impact, target - state.platesRemoved)
	end

	fxRemote:FireAllClients({
		kind = "impact",
		point = impact,
		normal = normal,
		damage = damage,
		crit = crit,
		color = color,
		thrower = player.UserId,
		tiles = removed,
	})

	updateMantle(impact)
	updateAttributes()

	if state.hp <= 0 then
		supernova()
	end
	return dealt
end

-- Developer Product: replaces the current planet with a legendary one right away
-- (or queues it if a legendary planet is already up).
function PlanetService:SummonLegendary()
	if state and state.def.legendary and not state.destroyed then
		legendaryQueued = true
		return
	end
	if state and not state.destroyed then
		state.destroyed = true
		state.model:Destroy()
	end
	spawnPlanet(Planets.Legendary)
end

function PlanetService:Init(s)
	services = s
	destroyedRemote = Remotes.Get("PlanetDestroyed")
	fxRemote = Remotes.Get("PlanetFX")
end

function PlanetService:Start()
	CENTER = services.WorldService.PlanetPosition -- may come from the custom map marker
	task.delay(2, function()
		spawnPlanet(Planets.Get(currentIndex))
	end)
end

return PlanetService
