-- Builds the whole map from code (see Game.World for the layout, drawn from the owner's sketch):
--   Central Island with the Meteor Field in the middle (meteors fall here),
--   behind it one plot per player: a Comet Islet (meteors float on pedestals) and a higher House Island,
--   at the front sides the Shop island and the Leaderboard island, each with a mountain,
--   in front the Bifrost: 3 glitching lanes (one per planet tier) joining the Launch Platform.
-- Islands are Roblox Terrain; bridges, pedestals, houses and pads are Parts, so Blender models can
-- replace them later (Assets/Map/Citadel, see docs/ASSET_PIPELINE.md).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Planets = require(Shared.Config.Planets)
local Evolutions = require(Shared.Config.Evolutions)
local TerrainConfig = require(Shared.Config.Terrain)
local AssetLibrary = require(Shared.AssetLibrary)

local WorldService = {}

-- One per player plot: { index, model, center (house CFrame), display (comet islet CFrame),
--   pedestals = {CFrame}, owner, sign, signGui, signPost, placeholder, house, houseTier, slots }
WorldService.Altars = {}
WorldService.LaunchPads = {} -- { {part, returnCFrame, tier} }
-- Where meteors fall: a ring (inner/outer radius) around `center`.
WorldService.Field = {
	center = Game.World.FieldCenter,
	inner = Game.World.FieldInner,
	outer = Game.World.FieldRadius,
}

local W = Game.World
local worldFolder
local terrain = workspace.Terrain
local trng = Random.new(7)

-- Theme "Sky Ruins" (same as the UI art): weathered sandstone, teal copper, glowing cyan runes.
-- (The old names stay: MARBLE = stone, GOLD = copper, GOLD_LIGHT = rune glow.)
local MARBLE = Color3.fromRGB(205, 178, 138)
local GOLD = Color3.fromRGB(79, 163, 160)
local GOLD_LIGHT = Color3.fromRGB(111, 216, 255)
local STONE_DARK = Color3.fromRGB(140, 115, 96)
local GLITCH_COLORS = {
	Color3.fromRGB(80, 220, 255),
	Color3.fromRGB(255, 80, 200),
	Color3.fromRGB(255, 200, 90),
	Color3.fromRGB(150, 100, 255),
	Color3.fromRGB(235, 245, 255),
}

-- Parts -------------------------------------------------------------------------------

local buildHouseLectern -- defined with the plots
local prepareHouse -- defined with the houses

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	-- Shape first: changing Shape after Size can resize the part.
	if props.Shape then
		p.Shape = props.Shape
	end
	for k, v in pairs(props) do
		if k ~= "Parent" and k ~= "Shape" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or worldFolder
	return p
end

-- Flat disc (cylinder lying on its side) centered at `pos`.
local function disc(pos, radius, height, props)
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, radius * 2, radius * 2)
	props.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	return part(props)
end

local function label(parent, text, size, offset, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = size
	bb.StudsOffset = offset or Vector3.zero
	bb.LightInfluence = 0
	bb.MaxDistance = 300
	bb.Parent = parent
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Text = text
	t.Parent = bb
	return t, bb
end

-- Walkable bridge between two points: a path of big weathered stone slabs (slightly irregular), low
-- copper curbs and a pair of rune lanterns every ~30 studs.
local function bridge(from, to, width, props)
	props = props or {}
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local length = (to - from).Magnitude
	local cf = CFrame.lookAt(from, to)
	local brng = Random.new(math.floor(from.X * 7 + from.Z * 13))
	local z = 0
	while z < length do
		local slab = math.min(brng:NextNumber(7, 11), length - z + 1)
		part({
			Name = props.Name or "Bridge",
			Size = Vector3.new(width * brng:NextNumber(0.9, 1), 2.4, slab + 0.8),
			CFrame = cf * CFrame.new(brng:NextNumber(-0.5, 0.5), -1.2, -(z + slab / 2)) * CFrame.Angles(0, math.rad(brng:NextNumber(-2.5, 2.5)), 0),
			Material = props.Material or Enum.Material.Sandstone,
			Color = props.Color or MARBLE:Lerp(STONE_DARK, brng:NextNumber(0, 0.6)),
		})
		z += slab
	end
	if props.rails ~= false then
		for _, side in ipairs({ -1, 1 }) do
			part({
				Name = "BridgeRail",
				Size = Vector3.new(0.9, 1.2, length),
				CFrame = cf * CFrame.new(side * (width / 2 + 0.2), 0.4, -length / 2),
				Material = Enum.Material.Metal,
				Color = GOLD,
			})
		end
		local lanterns = math.max(1, math.floor(length / 30))
		for i = 0, lanterns do
			local at = cf * CFrame.new(0, 0, -length * i / lanterns)
			for _, side in ipairs({ -1, 1 }) do
				local post = at * CFrame.new(side * (width / 2 + 1), 0, 0)
				part({ Name = "LanternPost", Size = Vector3.new(1.6, 5, 1.6), CFrame = post * CFrame.new(0, 2.5, 0), Material = Enum.Material.Sandstone, Color = STONE_DARK })
				part({ Name = "LanternCap", Size = Vector3.new(2.2, 0.6, 2.2), CFrame = post * CFrame.new(0, 5.3, 0), Material = Enum.Material.Metal, Color = GOLD })
				local rune = part({
					Name = "LanternRune",
					Size = Vector3.new(1, 1, 1),
					CFrame = post * CFrame.new(0, 6.3, 0) * CFrame.Angles(0, math.rad(45), math.rad(45)),
					Material = Enum.Material.Neon,
					Color = GOLD_LIGHT,
					CanCollide = false,
					CanQuery = false,
				})
				if i % 2 == 0 then
					local light = Instance.new("PointLight")
					light.Color = GOLD_LIGHT
					light.Range = 14
					light.Brightness = 1.2
					light.Parent = rune
				end
			end
		end
	end
	return flat
end

-- Tower: stacked tapering copper blocks, glowing rune trims and a sharp spike.
local function tower(base, height, width)
	local steps = 4
	local y = base.Y
	for i = 1, steps do
		local t = (i - 1) / steps
		local w = width * (1 - t * 0.5)
		local h = height / steps
		part({
			Name = "Tower",
			Size = Vector3.new(w, h, w),
			CFrame = CFrame.new(base.X, y + h / 2, base.Z) * CFrame.Angles(0, math.rad(45), 0),
			Material = Enum.Material.Foil,
			Color = GOLD:Lerp(Color3.fromRGB(120, 80, 40), t * 0.4),
			Reflectance = 0.15,
		})
		part({
			Name = "TowerTrim",
			Size = Vector3.new(w + 0.6, 0.5, w + 0.6),
			CFrame = CFrame.new(base.X, y + h, base.Z) * CFrame.Angles(0, math.rad(45), 0),
			Material = Enum.Material.Neon,
			Color = GOLD_LIGHT,
			CanCollide = false,
		})
		y += h
	end
	part({
		Name = "TowerSpike",
		Size = Vector3.new(width * 0.2, height * 0.3, width * 0.2),
		CFrame = CFrame.new(base.X, y + height * 0.15, base.Z) * CFrame.Angles(0, math.rad(45), 0),
		Material = Enum.Material.Neon,
		Color = GOLD_LIGHT,
		CanCollide = false,
	})
end

-- Terrain -------------------------------------------------------------------------------

-- Floating island: a flat walkable top at `top.Y`, a wavy grass coastline and a cone of rock
-- below with boulders and a hanging tip.
local function island(top, radius, depth, topMaterial)
	if not W.GenerateTerrain then
		return -- the place has its own hand-made terrain
	end
	topMaterial = topMaterial or Enum.Material.Grass
	terrain:FillCylinder(CFrame.new(top - Vector3.new(0, 4, 0)), 8, radius, topMaterial)
	-- Wavy coastline: lobes around the edge.
	local lobes = math.max(6, math.floor(radius / 12))
	for i = 1, lobes do
		local a = (i + trng:NextNumber(-0.3, 0.3)) / lobes * math.pi * 2
		local lr = radius * trng:NextNumber(0.18, 0.3)
		local pos = top + Vector3.new(math.cos(a), 0, math.sin(a)) * (radius - lr * 0.4)
		terrain:FillCylinder(CFrame.new(pos - Vector3.new(0, 4, 0)), 8, lr, topMaterial)
	end
	local steps = 6
	local h = depth / steps + 4
	for i = 0, steps - 1 do
		local t = i / steps
		local r = radius * (1 - t * 0.8) * trng:NextNumber(0.94, 1.02)
		terrain:FillCylinder(CFrame.new(top - Vector3.new(0, 8 + depth * t + h / 2, 0)), h, r,
			t < 0.5 and Enum.Material.Rock or Enum.Material.Slate)
	end
	for _ = 1, math.floor(radius / 5) do
		local a = trng:NextNumber(0, math.pi * 2)
		local size = radius * trng:NextNumber(0.08, 0.16)
		local t = trng:NextNumber(0.15, 0.75)
		local r = radius * (1 - t * 0.8) * 0.85
		terrain:FillBall(top + Vector3.new(math.cos(a) * r, -10 - depth * t - size, math.sin(a) * r), size, Enum.Material.Rock)
	end
	terrain:FillBall(top - Vector3.new(0, 8 + depth * 1.02, 0), radius * 0.16, Enum.Material.Slate)
end

-- Big rocky mountain: a tapering stack with a few side peaks and a snowy cap.
local function mountain(base, radius, height)
	if not W.GenerateTerrain then
		return
	end
	local function peak(at, r, h)
		local steps = 12
		for i = 0, steps - 1 do
			local t = i / steps
			local center = at + Vector3.new(trng:NextNumber(-1, 1) * r * 0.04, h * t + h / steps / 2, trng:NextNumber(-1, 1) * r * 0.04)
			terrain:FillCylinder(CFrame.new(center), h / steps + 4, r * (1 - t * 0.9), Enum.Material.Rock)
		end
		terrain:FillBall(at + Vector3.new(0, h * 0.86, 0), r * 0.2, Enum.Material.Snow)
	end
	peak(base, radius, height)
	for _ = 1, 3 do
		local a = trng:NextNumber(0, math.pi * 2)
		peak(base + Vector3.new(math.cos(a), 0, math.sin(a)) * radius * 0.55, radius * 0.55, height * trng:NextNumber(0.45, 0.65))
	end
end

local function islets()
	local placed = 0
	while placed < W.IsletCount do
		local a = trng:NextNumber(0, math.pi * 2)
		local d = trng:NextNumber(W.HouseIslandDistance + 300, W.HouseIslandDistance + 1300)
		local pos = Vector3.new(math.sin(a) * d, trng:NextNumber(-350, 150), math.cos(a) * d)
		-- Keep the sky in front (towards the planets) clear.
		if pos.Z < 400 then
			local r = trng:NextNumber(30, 90)
			island(pos, r, r * 1.6, trng:NextNumber() < 0.25 and Enum.Material.Snow or Enum.Material.Grass)
			placed += 1
		end
	end
end

-- Lighting --------------------------------------------------------------------------

-- Finds the owner's skybox (e.g. "Purple Nebula" from the Toolbox) wherever it was inserted
-- (Lighting, Workspace, inside a model...) and makes it the active Sky directly under Lighting.
local function findOwnerSky()
	local best
	for _, service in ipairs({ Lighting, workspace, ReplicatedStorage, game:GetService("ServerStorage") }) do
		for _, d in ipairs(service:GetDescendants()) do
			if d:IsA("Sky") then
				local isNebula = string.find(string.lower(d.Name), "nebula") ~= nil
				if not best or (isNebula and not string.find(string.lower(best.Name), "nebula")) then
					best = d
				end
			end
		end
	end
	return best
end

-- Bright, readable lighting (daytime light with the sun hidden) under the owner's skybox.
-- Effects created by the game are prefixed with MG_.
local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.GeographicLatitude = 30
	Lighting.Brightness = 3
	Lighting.ExposureCompensation = 0.35
	Lighting.Ambient = Color3.fromRGB(135, 125, 165)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 160, 200)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 100000

	local sky = findOwnerSky()
	if sky then
		sky.Parent = Lighting
		sky.CelestialBodiesShown = false
		for _, other in ipairs(Lighting:GetChildren()) do
			if other:IsA("Sky") and other ~= sky then
				other:Destroy()
			end
		end
		print("[MeteorGods] using skybox: " .. sky.Name)
	else
		warn("[MeteorGods] No Sky found. Insert the 'Purple Nebula' skybox (it can be anywhere in Lighting or Workspace).")
		sky = Instance.new("Sky")
		sky.StarCount = 5000
		sky.CelestialBodiesShown = false
		sky.Parent = Lighting
	end
	for _, child in ipairs(Lighting:GetChildren()) do
		if string.sub(child.Name, 1, 3) == "MG_" then
			child:Destroy()
		end
	end
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "MG_Bloom"
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.2
	bloom.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "MG_Color"
	cc.Brightness = 0.05
	cc.Saturation = 0.1
	cc.Contrast = 0.05
	cc.Parent = Lighting
end

local function setupTerrainColors()
	for name, color in pairs(TerrainConfig.Colors) do
		terrain:SetMaterialColor(Enum.Material[name], color)
	end
end

-- Pads -------------------------------------------------------------------------------

-- Launch altar: a round stone platform with a copper ring, a rune circle in the tier color and four
-- small obelisks with glowing tips. The glowing center is the pad you stand on.
local function makePad(index, position, lookAt, returnCFrame, tier, padsFolder)
	local tierDef = Planets.Tiers[tier]
	local R = W.LaunchPadRadius
	disc(position - Vector3.new(0, 1, 0), R + 4, 2, {
		Name = "PadBase",
		Material = Enum.Material.Sandstone,
		Color = MARBLE,
		Parent = padsFolder,
	})
	disc(position - Vector3.new(0, 0.3, 0), R + 4.6, 0.8, {
		Name = "PadCopper",
		Material = Enum.Material.Metal,
		Color = GOLD,
		CanCollide = false,
		Parent = padsFolder,
	})
	local pad = disc(position, R, 0.6, {
		Name = "LaunchPad" .. index,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(46, 52, 66),
		CanCollide = false,
		Parent = padsFolder,
	})
	pad.CFrame = CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)) * CFrame.Angles(0, 0, math.rad(90))
	-- Rune circle and core glow in the tier color (low, never in the way of the camera).
	disc(position + Vector3.new(0, 0.35, 0), R - 1, 0.2, {
		Name = "PadRune",
		Material = Enum.Material.Neon,
		Color = tierDef.color,
		Transparency = 0.45,
		CanCollide = false,
		CanQuery = false,
		Parent = padsFolder,
	})
	disc(position + Vector3.new(0, 0.45, 0), R - 2.2, 0.2, {
		Name = "PadInner",
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(46, 52, 66),
		CanCollide = false,
		CanQuery = false,
		Parent = padsFolder,
	})
	disc(position + Vector3.new(0, 0.55, 0), R * 0.35, 0.2, {
		Name = "PadCore",
		Material = Enum.Material.Neon,
		Color = tierDef.color,
		CanCollide = false,
		CanQuery = false,
		Parent = padsFolder,
	})
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local at = position + Vector3.new(math.cos(a), 0, math.sin(a)) * (R + 2.6)
		part({ Name = "PadObelisk", Size = Vector3.new(1.8, 7, 1.8), CFrame = CFrame.new(at + Vector3.new(0, 3.5, 0)), Material = Enum.Material.Sandstone, Color = STONE_DARK, Parent = padsFolder })
		part({
			Name = "PadObeliskTip",
			Size = Vector3.new(1.2, 1.2, 1.2),
			CFrame = CFrame.new(at + Vector3.new(0, 7.8, 0)) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
			Material = Enum.Material.Neon,
			Color = tierDef.color,
			CanCollide = false,
			CanQuery = false,
			Parent = padsFolder,
		})
	end
	local text, bb = label(pad, "LAUNCH · " .. tierDef.name, UDim2.new(22, 0, 4, 0), Vector3.new(0, 14, 0),
		tierDef.color:Lerp(Color3.new(1, 1, 1), 0.4))
	bb.MaxDistance = 600
	text.TextStrokeTransparency = 0
	pad:SetAttribute("Tier", tier)
	pad:SetAttribute("RequiredEvolution", tierDef.requiredEvolution)
	pad:SetAttribute("ReturnCFrame", returnCFrame)
	table.insert(WorldService.LaunchPads, { part = pad, returnCFrame = returnCFrame, tier = tier })
end

-- Central island and Meteor Field -------------------------------------------------------

local craterFolder

-- Rebuilds the magma field: basalt crust with lava cracks from the middle and a lava ring around it.
function WorldService:ResetField()
	if craterFolder then
		craterFolder:ClearAllChildren()
	end
	if not W.GenerateTerrain then
		return
	end
	local f = W.FieldCenter
	local frng = Random.new(11) -- same cracks every time
	terrain:FillCylinder(CFrame.new(f - Vector3.new(0, 6, 0)), 12, W.FieldRadius + 8, Enum.Material.CrackedLava)
	terrain:FillCylinder(CFrame.new(f - Vector3.new(0, 6, 0)), 12, W.FieldRadius, Enum.Material.Basalt)
	terrain:FillCylinder(CFrame.new(f - Vector3.new(0, 4, 0)), 8, 26, Enum.Material.CrackedLava)
	for k = 1, 11 do
		local a = (k + frng:NextNumber(-0.3, 0.3)) / 11 * math.pi * 2
		local d = 22
		while d < W.FieldRadius - 6 do
			a += frng:NextNumber(-0.12, 0.12)
			terrain:FillBall(f + Vector3.new(math.cos(a) * d, -3.5, math.sin(a) * d), frng:NextNumber(3.5, 5), Enum.Material.CrackedLava)
			d += 7
		end
	end
end

-- A meteor landed at `ground`: digs a crater lined with lava, with a molten glow at the bottom that
-- cools down. Returns the bottom of the crater (where the meteor rests), or nil off the field.
function WorldService:Crater(ground, radius)
	local f = W.FieldCenter
	local flat = Vector3.new(ground.X - f.X, 0, ground.Z - f.Z)
	if not W.GenerateTerrain or flat.Magnitude > W.FieldRadius - radius then
		return nil
	end
	local surface = Vector3.new(ground.X, f.Y, ground.Z)
	terrain:FillBall(surface - Vector3.new(0, radius * 0.2, 0), radius * 0.75, Enum.Material.CrackedLava)
	terrain:FillBall(surface + Vector3.new(0, radius * 0.6, 0), radius, Enum.Material.Air)
	local bottom = surface - Vector3.new(0, radius * 0.4, 0)
	local glow = part({
		Name = "Molten",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, radius * 1.1, radius * 1.1),
		CFrame = CFrame.new(bottom + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 140, 40),
		Transparency = 0.15,
		CanCollide = false,
		CanQuery = false,
		Parent = craterFolder,
	})
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 40)
	light.Range = radius * 2.5
	light.Brightness = 3
	light.Parent = glow
	local embers = Instance.new("ParticleEmitter")
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 70, 20))
	embers.LightEmission = 1
	embers.Size = NumberSequence.new(0.5, 0)
	embers.Lifetime = NumberRange.new(1, 2)
	embers.Rate = 12
	embers.Speed = NumberRange.new(4, 9)
	embers.SpreadAngle = Vector2.new(25, 25)
	embers.EmissionDirection = Enum.NormalId.Right -- the cylinder's axis points up
	embers.Parent = glow
	-- Cools down in 40 s, then only the crater stays.
	TweenService:Create(glow, TweenInfo.new(40), { Color = Color3.fromRGB(90, 20, 10), Transparency = 0.7 }):Play()
	TweenService:Create(light, TweenInfo.new(40), { Brightness = 0 }):Play()
	task.delay(25, function()
		embers.Enabled = false
	end)
	task.delay(41, function()
		glow:Destroy()
	end)
	return bottom
end

local function buildCenter()
	island(Vector3.zero, W.CenterRadius, W.CenterRadius * 0.7)
	-- Meteor Field: a magma field (dark crust, glowing cracks, a lava ring around it). Every meteor
	-- that lands digs a molten crater (WorldService:Crater); the field heals at every new shower.
	WorldService:ResetField()
	-- The vortex meteors pour out of, high above the field.
	disc(W.FieldCenter + Vector3.new(0, 420, 0), W.FieldRadius * 0.8, 3, {
		Name = "SkyVortex",
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(170, 110, 255),
		CanCollide = false,
		CanQuery = false,
	})
	-- Copper towers around the island edge, between the bridges.
	for _, deg in ipairs({ 95, 125, 235, 265 }) do
		local a = math.rad(deg)
		tower(Vector3.new(math.sin(a), 0, math.cos(a)) * (W.CenterRadius - 40), 130, 24)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.lookAt(W.SpawnPosition + Vector3.new(0, 0.5, 0), Vector3.new(0, 0.5, 500))
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(255, 225, 160)
	spawn.Transparency = 0.5
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = worldFolder
end

-- Player plots ----------------------------------------------------------------------------

local function plotDirection(i)
	local n = W.HouseCount
	local deg = n > 1 and (-W.PlotArc / 2 + (i - 1) * W.PlotArc / (n - 1)) or 0
	local a = math.rad(deg)
	return Vector3.new(math.sin(a), 0, -math.cos(a))
end

-- Lectern in front of each house: the owner upgrades the house here (Controllers/House).
buildHouseLectern = function(center, parent)
	local model = Instance.new("Model")
	model.Name = "HouseLectern"
	local base = center * CFrame.new(26, 0, -100)
	local root = part({ Name = "LecternBase", Size = Vector3.new(7, 1, 7), CFrame = base * CFrame.new(0, 0.5, 0), Material = Enum.Material.Sandstone, Color = MARBLE, Parent = model })
	part({ Name = "LecternPillar", Size = Vector3.new(2.6, 5, 2.6), CFrame = base * CFrame.new(0, 3.5, 0), Material = Enum.Material.Sandstone, Color = MARBLE, Parent = model })
	local top = part({
		Name = "LecternTop",
		Size = Vector3.new(5, 0.6, 3.6),
		CFrame = base * CFrame.new(0, 6.3, 0) * CFrame.Angles(math.rad(-20), 0, 0),
		Material = Enum.Material.Foil,
		Color = GOLD,
		Parent = model,
	})
	local _, bb = label(top, "🏠 UPGRADE HOUSE", UDim2.new(16, 0, 3, 0), Vector3.new(0, 4, 0), GOLD_LIGHT)
	bb.MaxDistance = 220
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenHouse"
	prompt.ActionText = "Upgrade House"
	prompt.ObjectText = "Your House"
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = top
	model.PrimaryPart = root
	model.WorldPivot = base
	model.Parent = parent
	return model
end

-- Placeholder temple shown until a house model (Assets/Houses) exists.
local function placeholderHouse(cf, parent)
	local s = 2.2
	local model = Instance.new("Model")
	model.Name = "Placeholder"
	local pos = cf.Position
	disc(pos + Vector3.new(0, 0.75 * s, 0), 14 * s, 1.5 * s, { Name = "Base", Material = Enum.Material.Sandstone, Color = MARBLE, Parent = model })
	for k = 0, 5 do
		local a = math.rad(30 + k * 60)
		part({
			Name = "Column",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(16 * s, 2.6 * s, 2.6 * s),
			CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 10 * s, 9.5 * s, math.sin(a) * 10 * s)) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.Sandstone,
			Color = MARBLE,
			Parent = model,
		})
	end
	disc(pos + Vector3.new(0, 18.2 * s, 0), 13 * s, 1.4 * s, { Name = "Roof", Material = Enum.Material.Sandstone, Color = MARBLE, Parent = model })
	part({
		Name = "Dome",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 16 * s,
		CFrame = CFrame.new(pos + Vector3.new(0, 19 * s, 0)),
		Material = Enum.Material.Foil,
		Color = GOLD,
		Reflectance = 0.2,
		Parent = model,
	})
	part({
		Name = "Spire",
		Size = Vector3.new(1.4 * s, 10 * s, 1.4 * s),
		CFrame = CFrame.new(pos + Vector3.new(0, 31 * s, 0)) * CFrame.Angles(0, math.rad(45), 0),
		Material = Enum.Material.Foil,
		Color = GOLD_LIGHT,
		CanCollide = false,
		Parent = model,
	})
	model.Parent = parent
	return model
end

local function pedestal(cf, index, parent)
	local base = cf.Position
	part({
		Name = "Pedestal" .. index,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(9, 7, 7),
		CFrame = CFrame.new(base + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Sandstone,
		Color = MARBLE,
		Parent = parent,
	})
	part({
		Name = "PedestalRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 9, 9),
		CFrame = CFrame.new(base + Vector3.new(0, 9.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Foil,
		Color = GOLD_LIGHT,
		CanCollide = false,
		Parent = parent,
	})
	-- Meteors hover above it, their faces turned towards the central island.
	local top = base + Vector3.new(0, 15, 0)
	return CFrame.lookAt(top, Vector3.new(0, top.Y, 0))
end

local function buildPlots()
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = worldFolder
	for i = 1, W.HouseCount do
		local dir = plotDirection(i)
		local up = Vector3.new(0, 1, 0)
		local cometPos = dir * W.CometIsletDistance + up * W.CometIsletHeight
		local housePos = dir * W.HouseIslandDistance + up * W.HouseIslandHeight
		island(cometPos, W.CometIsletRadius, W.CometIsletRadius * 1.4)
		island(housePos, W.HouseIslandRadius, W.HouseIslandRadius * 1.3)
		bridge(dir * (W.CenterRadius - 10), dir * (W.CometIsletDistance - W.CometIsletRadius + 10) + up * W.CometIsletHeight, 18)
		bridge(
			dir * (W.CometIsletDistance + W.CometIsletRadius - 10) + up * W.CometIsletHeight,
			dir * (W.HouseIslandDistance - W.HouseIslandRadius + 10) + up * W.HouseIslandHeight,
			18
		)

		local model = Instance.new("Model")
		model.Name = "Plot" .. i
		-- Pedestals in an arc on the comet islet, facing the central island.
		local display = CFrame.lookAt(cometPos, Vector3.new(0, cometPos.Y, 0))
		local pedestals = {}
		for k = 1, 4 do
			local a = math.rad(-54 + (k - 1) * 36)
			local local_ = Vector3.new(math.sin(a) * 24, 0, -math.cos(a) * 24 + 10)
			pedestals[k] = pedestal(display * CFrame.new(local_), k, model)
		end
		-- House facing the central island.
		local center = CFrame.lookAt(housePos, Vector3.new(0, housePos.Y, 0))
		local placeholder = placeholderHouse(center, model)
		local lectern = buildHouseLectern(center, model)
		local signPost = part({
			Name = "Sign",
			Size = Vector3.new(1, 1, 1),
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CFrame = CFrame.new(housePos + Vector3.new(0, 95, 0)),
			Parent = model,
		})
		local text, bb = label(signPost, "Free plot", UDim2.new(50, 0, 11, 0))
		bb.MaxDistance = 1500
		model.Parent = folder

		table.insert(WorldService.Altars, {
			index = i,
			model = model,
			center = center,
			display = display,
			pedestals = pedestals,
			owner = nil,
			sign = text,
			signGui = bb,
			signPost = signPost,
			placeholder = placeholder,
			house = nil,
			houseTier = nil,
			lectern = lectern,
			islandRadius = W.HouseIslandRadius,
			slots = nil,
		})
	end
end

-- Side islands --------------------------------------------------------------------------

local function sideIsland(cfg, outward)
	local c = cfg.center
	island(c, cfg.radius, cfg.radius * 0.9)
	-- A real mountain on the outer back corner of the island.
	local out = Vector3.new(c.X, 0, c.Z).Unit
	mountain(c + out * cfg.radius * 0.45 + Vector3.new(outward * cfg.radius * 0.15, 0, 0), cfg.radius * 0.55, W.MountainHeight)
	local dir = (Vector3.zero - c).Unit
	bridge(c + dir * (cfg.radius - 12), c + dir * (c.Magnitude - W.CenterRadius + 12), 30)
	return CFrame.lookAt(c + dir * cfg.radius * 0.35, c + dir * cfg.radius)
end

local function buildShop()
	local front = sideIsland(W.ShopIsland, -1)
	local s = 2
	-- Shop stall: marble counter, golden canopy, a prompt that opens the shop.
	local stall = Instance.new("Model")
	stall.Name = "ShopStall"
	part({ Name = "Counter", Size = Vector3.new(22 * s, 4 * s, 5 * s), CFrame = front * CFrame.new(0, 2 * s, 0), Material = Enum.Material.Sandstone, Color = MARBLE, Parent = stall })
	for _, x in ipairs({ -10, 10 }) do
		part({ Name = "Post", Size = Vector3.new(1.6 * s, 14 * s, 1.6 * s), CFrame = front * CFrame.new(x * s, 7 * s, 3 * s), Material = Enum.Material.Foil, Color = GOLD, Parent = stall })
	end
	local canopy = part({
		Name = "Canopy",
		Size = Vector3.new(26 * s, 1.2 * s, 12 * s),
		CFrame = front * CFrame.new(0, 14.5 * s, 1 * s) * CFrame.Angles(math.rad(-12), 0, 0),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(170, 80, 240),
		Parent = stall,
	})
	local _, bb = label(canopy, "🛒 SHOP", UDim2.new(36, 0, 10, 0), Vector3.new(0, 10, 0), GOLD_LIGHT)
	bb.MaxDistance = 1500
	local promptPart = part({ Name = "ShopPrompt", Size = Vector3.new(2, 2, 2), Transparency = 1, CanCollide = false, CFrame = front * CFrame.new(0, 4, -8), Parent = stall })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenShop"
	prompt.ActionText = "Open Shop"
	prompt.ObjectText = "Celestial Market"
	prompt.MaxActivationDistance = 22
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart
	stall.Parent = worldFolder
end

local function buildLeaderboardIsland()
	sideIsland(W.LeaderboardIsland, 1)
end

-- Fusion Reactor: a big machine on the central island where 3 meteors become 1 rarer one.
local function buildFusionReactor()
	local pos = Game.Fusion.Position
	local model = Instance.new("Model")
	model.Name = "FusionReactor"
	local front = CFrame.lookAt(pos, Vector3.new(0, 0, 0))
	disc(pos + Vector3.new(0, 1.5, 0), 42, 3, { Name = "Base", Material = Enum.Material.Sandstone, Color = MARBLE, Parent = model })
	disc(pos + Vector3.new(0, 3.2, 0), 34, 0.6, { Name = "BaseTrim", Material = Enum.Material.Foil, Color = GOLD, Parent = model })
	-- Four heavy pylons with glass tubes.
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local p = pos + Vector3.new(math.cos(a) * 28, 0, math.sin(a) * 28)
		part({ Name = "Pylon", Size = Vector3.new(8, 46, 8), CFrame = CFrame.new(p + Vector3.new(0, 26, 0)) * CFrame.Angles(0, -a, 0), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(70, 70, 90), Parent = model })
		part({ Name = "PylonCap", Size = Vector3.new(10, 4, 10), CFrame = CFrame.new(p + Vector3.new(0, 50, 0)) * CFrame.Angles(0, -a, 0), Material = Enum.Material.Foil, Color = GOLD, Parent = model })
		part({
			Name = "Tube",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(30, 3, 3),
			CFrame = CFrame.lookAt((p + pos) / 2 + Vector3.new(0, 34, 0), pos + Vector3.new(0, 30, 0)) * CFrame.Angles(0, math.rad(90), 0),
			Material = Enum.Material.Glass,
			Color = Color3.fromRGB(150, 200, 255),
			Transparency = 0.4,
			Parent = model,
		})
	end
	-- Containment sphere with the glowing fusion core and two tilted rings.
	part({ Name = "Containment", Shape = Enum.PartType.Ball, Size = Vector3.one * 30, CFrame = CFrame.new(pos + Vector3.new(0, 30, 0)), Material = Enum.Material.Glass, Color = Color3.fromRGB(120, 170, 255), Transparency = 0.55, CanCollide = false, Parent = model })
	local core = part({ Name = "FusionCore", Shape = Enum.PartType.Ball, Size = Vector3.one * 11, CFrame = CFrame.new(pos + Vector3.new(0, 30, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(190, 120, 255), CanCollide = false, Parent = model })
	local light = Instance.new("PointLight")
	light.Color = core.Color
	light.Range = 40
	light.Brightness = 2
	light.Parent = core
	for r, tilt in ipairs({ 25, -35 }) do
		for i = 1, 20 do
			local a = i / 20 * math.pi * 2
			part({
				Name = "ReactorRing" .. r,
				Size = Vector3.new(2.5, 2.5, 6.4),
				CFrame = CFrame.new(pos + Vector3.new(0, 30, 0)) * CFrame.Angles(math.rad(tilt), 0, 0) * CFrame.Angles(0, a, 0) * CFrame.new(21, 0, 0),
				Material = Enum.Material.Foil,
				Color = GOLD,
				CanCollide = false,
				Parent = model,
			})
		end
	end
	local _, bb = label(core, "⚛ FUSION REACTOR\n3 meteors → 1 rarer · unlocks at " .. Game.Fusion.RequiredPlanets .. " planets",
		UDim2.new(44, 0, 10, 0), Vector3.new(0, 34, 0), Color3.fromRGB(220, 190, 255))
	bb.MaxDistance = 900
	local promptPart = part({ Name = "FusionPrompt", Size = Vector3.new(2, 2, 2), Transparency = 1, CanCollide = false, CFrame = front * CFrame.new(0, 5, -44), Parent = model })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenFusion"
	prompt.ActionText = "Use Reactor"
	prompt.ObjectText = "Fusion Reactor"
	prompt.MaxActivationDistance = 24
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart
	model.Parent = worldFolder
end

-- Cosmic Hunt portal: a golden ring with a swirling rift inside.
local function buildHuntPortal()
	local pos = Game.Hunt.PortalPosition
	local model = Instance.new("Model")
	model.Name = "HuntPortal"
	local face = CFrame.lookAt(pos, Vector3.new(0, 0, 0))
	disc(pos + Vector3.new(0, 1.5, 0), 34, 3, { Name = "Base", Material = Enum.Material.Sandstone, Color = MARBLE, Parent = model })
	local center = face * CFrame.new(0, 34, 0)
	for i = 1, 28 do
		local a = i / 28 * math.pi * 2
		part({
			Name = "PortalRing",
			Size = Vector3.new(5, 7.5, 5),
			CFrame = center * CFrame.Angles(0, 0, a) * CFrame.new(0, 28, 0),
			Material = Enum.Material.Foil,
			Color = GOLD,
			Parent = model,
		})
	end
	local rift = part({
		Name = "PortalRift",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 52, 52),
		CFrame = center * CFrame.Angles(0, math.rad(90), 0),
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(120, 80, 255),
		CanCollide = false,
		Parent = model,
	})
	local _, bb = label(rift, "🌌 COSMIC HUNT\nFly through space · smash planets · earn Stardust",
		UDim2.new(44, 0, 10, 0), Vector3.new(0, 38, 0), Color3.fromRGB(200, 180, 255))
	bb.MaxDistance = 900
	local promptPart = part({ Name = "HuntPrompt", Size = Vector3.new(2, 2, 2), Transparency = 1, CanCollide = false, CFrame = face * CFrame.new(0, 5, -8), Parent = model })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenHunt"
	prompt.ActionText = "Enter the Hunt"
	prompt.ObjectText = "Cosmic Hunt (" .. Game.Hunt.Duration .. "s)"
	prompt.MaxActivationDistance = 24
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart
	model.Parent = worldFolder
end

-- Bifrost: three separate bridges, each to its own Launch Platform ------------------------------

local function buildLane(lane, padsFolder)
	local rng = Random.new(3 + lane)
	local tier = Planets.Tiers[lane]
	local dir = Vector3.new(math.sin(math.rad(tier.laneAngle)), 0, math.cos(math.rad(tier.laneAngle)))
	local right = Vector3.new(dir.Z, 0, -dir.X)
	local platform = dir * W.PlatformDistance
	local startDist = W.CenterRadius - 15
	local endDist = W.PlatformDistance - W.HubRadius + 10
	local length = endDist - startDist
	local width = W.LaneWidth
	local frame = CFrame.lookAt(dir * startDist, dir * endDist)

	local rows = 30
	local segLen = length / rows
	for r = 1, rows do
		part({
			Name = "Bifrost",
			Size = Vector3.new(width, 1.2, segLen + 0.05),
			CFrame = frame * CFrame.new(0, -0.6, -(r - 0.5) * segLen),
			Material = Enum.Material.Glass,
			Color = Color3.fromRGB(20, 22, 44):Lerp(Color3.fromRGB(40, 45, 80), rng:NextNumber()),
			Reflectance = 0.3,
		})
	end
	-- Glitch pixels (animated on the clients).
	for _ = 1, 220 do
		local glitch = part({
			Name = "BifrostGlitch",
			Size = Vector3.new(rng:NextNumber(0.6, 2.6), 0.12, rng:NextNumber(0.6, 6)),
			CFrame = frame * CFrame.new(rng:NextNumber(-width / 2 + 1.5, width / 2 - 1.5), 0.07, -rng:NextNumber(3, length - 3)),
			Material = Enum.Material.Neon,
			Color = GLITCH_COLORS[rng:NextInteger(1, #GLITCH_COLORS)],
			Transparency = rng:NextNumber(0.15, 0.7),
			CanCollide = false,
			CanQuery = false,
		})
		CollectionService:AddTag(glitch, "BifrostGlitch")
	end
	for _, side in ipairs({ -1, 1 }) do
		part({
			Name = "BifrostEdge",
			Size = Vector3.new(1.2, 2, length),
			CFrame = frame * CFrame.new(side * (width / 2 + 0.6), 0.5, -length / 2),
			Material = Enum.Material.Neon,
			Color = tier.color,
			Transparency = 0.15,
		})
	end
	-- Gate at the bridge entrance with the tier and its requirement.
	local gate = frame * CFrame.new(0, 0, -20)
	for _, side in ipairs({ -1, 1 }) do
		tower((gate * CFrame.new(side * (width / 2 + 10), 0, 0)).Position, 110, 14)
	end
	local beam = part({
		Name = "GateBeam",
		Size = Vector3.new(width + 26, 4, 4),
		CFrame = gate * CFrame.new(0, 60, 0),
		Material = Enum.Material.Foil,
		Color = GOLD,
	})
	local evoName = Evolutions.Get(tier.requiredEvolution).name
	local _, gateLabel = label(beam, tier.name .. (tier.requiredEvolution > 1 and ("\n" .. evoName .. "+") or ""),
		UDim2.new(40, 0, 14, 0), Vector3.new(0, 12, 0), tier.color:Lerp(Color3.new(1, 1, 1), 0.4))
	gateLabel.MaxDistance = 2000

	-- Hub at the end of the bridge, then 4 short bridges to 4 separate pad islets facing the planet.
	island(platform, W.HubRadius - 6, W.HubRadius * 1.2, Enum.Material.Basalt)
	disc(platform + Vector3.new(0, 0.7, 0), W.HubRadius, 1.4, {
		Name = "Bifrost",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(26, 28, 52),
		Reflectance = 0.3,
	})
	disc(platform + Vector3.new(0, 0.5, 0), W.HubRadius + 2, 1, {
		Name = "HubRim",
		Material = Enum.Material.Neon,
		Color = tier.color,
		CanCollide = false,
	})
	local toPlanet = Vector3.new(tier.position.X - platform.X, 0, tier.position.Z - platform.Z).Unit
	local face = CFrame.lookAt(platform, platform + toPlanet)
	local returnCFrame = face * CFrame.new(0, 4, W.HubRadius * 0.3)
	for k = 1, 4 do
		local a = math.rad(-W.PadArc / 2 + (k - 1) * W.PadArc / 3)
		local isletCF = face * CFrame.new(math.sin(a) * W.PadIsletDistance, 0, -math.cos(a) * W.PadIsletDistance)
		local isletPos = isletCF.Position
		island(isletPos, W.PadIsletRadius, W.PadIsletRadius * 1.8)
		disc(isletPos + Vector3.new(0, 0.6, 0), W.PadIsletRadius - 2, 1.2, {
			Name = "PadPlatform",
			Material = Enum.Material.Sandstone,
			Color = MARBLE,
		})
		local fromHub = (isletPos - platform).Unit
		bridge(platform + fromHub * (W.HubRadius - 6) + Vector3.new(0, 1.4, 0), isletPos - fromHub * (W.PadIsletRadius - 6) + Vector3.new(0, 1.2, 0), 16)
		makePad((lane - 1) * 4 + k, isletPos + Vector3.new(0, 1.6, 0), tier.position, returnCFrame, lane, padsFolder)
	end
end

local function buildBifrost()
	local padsFolder = Instance.new("Folder")
	padsFolder.Name = "LaunchPads"
	padsFolder.Parent = worldFolder
	for lane = 1, #Planets.Tiers do
		buildLane(lane, padsFolder)
	end
end

-- Custom map --------------------------------------------------------------------------------

-- Uses Assets/Map/Citadel and its markers (see docs/ASSET_PIPELINE.md). Returns false if absent.
local function buildCustomMap()
	local map = AssetLibrary.Clone("Map", "Citadel")
	if not map then
		return false
	end
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local markers = map:FindFirstChild("Markers")
	if markers then
		for _, m in ipairs(markers:GetDescendants()) do
			if m:IsA("BasePart") then
				m.Transparency = 1
				m.CanCollide = false
				m.CanQuery = false
				m.CanTouch = false
			end
		end
	end
	map.Parent = worldFolder
	return true
end

-- Houses ------------------------------------------------------------------------------------

-- Imported house models (Codex/Blender FBX, meshes grouped by material): glass you can see
-- through, glowing details, no collisions on small decorations. Names come from the materials.
-- World-aligned bounds of every part of a model: min, max (Vector3) or nil.
local function worldBounds(model)
	local minV, maxV
	local list = model:IsA("BasePart") and { model } or model:GetDescendants()
	for _, d in ipairs(list) do
		if d:IsA("BasePart") then
			local h = d.Size / 2
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local p = d.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
						minV = minV and minV:Min(p) or p
						maxV = maxV and maxV:Max(p) or p
					end
				end
			end
		end
	end
	return minV, maxV
end

local learnedTilt -- the turn on X the first house needed (props use the same one)

-- FBX imports can lay a model on its side. Tries the 90 degree turns on X and keeps the one where
-- `floor` (a flat part, e.g. the house "Base") is flat and at the bottom; without a floor, uses `forced`.
local function uprightModel(model, floor, forced)
	local pivot = model:GetPivot()
	local function turn(a)
		model:PivotTo(pivot * CFrame.Angles(math.rad(a), 0, 0))
	end
	if forced then
		turn(forced)
		return forced
	end
	if not floor then
		return 0
	end
	local best, bestScore = 0, math.huge
	for _, a in ipairs({ 0, 90, -90, 180 }) do
		turn(a)
		local minV, maxV = worldBounds(model)
		local fmin, fmax = worldBounds(floor)
		local fext = fmax - fmin
		local flatness = fext.Y / math.max(fext.X, fext.Z, 0.01)
		local lowness = ((fmin.Y + fmax.Y) / 2 - minV.Y) / math.max(maxV.Y - minV.Y, 0.01)
		local score = flatness + lowness
		if score < bestScore then
			best, bestScore = a, score
		end
	end
	turn(best)
	return best
end

prepareHouse = function(house)
	if not house.PrimaryPart then
		local base = house:FindFirstChild("Base", true)
		if base and base:IsA("BasePart") then
			house.PrimaryPart = base
		end
	end
	local looks = Game.House.Materials
	for _, d in ipairs(house:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			local n = string.lower(d.Name)
			local look
			for key, l in pairs(looks) do
				if n:find(string.lower(key), 1, true) then
					look = l
					break
				end
			end
			if not look and n == "base" then
				look = looks.White_Travertine -- the floor slab
			end
			if look then
				d.Material = look[1]
				d.Color = look[2]
				if look[3] then
					d.Transparency = look[3]
				end
				if look[4] then
					d.CanCollide = false
				end
			elseif d.Material == Enum.Material.Glass or n:find("glass") then
				d.Material = Enum.Material.Glass
				d.Transparency = math.max(d.Transparency, 0.5)
				d.CanCollide = false
			end
			if d.Material == Enum.Material.Neon then
				d.CastShadow = false
			end
			local size = d.Size
			if math.max(size.X, size.Y, size.Z) < 4 then
				d.CanCollide = false -- small furniture and decorations
			end
		end
	end
end

-- Places the house model on the player's house island: resized to its Blender size x Game.House.Scale,
-- floor on the ground, front towards the central island. The island grows if the house needs it,
-- and the upgrade lectern moves in front of the house.
function WorldService:UpdateHouse(player, tier)
	local altar = WorldService:GetAltar(player)
	if not altar or altar.houseTier == tier then
		return false
	end
	local house = AssetLibrary.House(tier)
	if not house then
		return false
	end
	if altar.house then
		altar.house:Destroy()
	end
	prepareHouse(house)
	-- Upright first (the import may lay it on its side), then the width of its level.
	local floorPart = house.PrimaryPart or house:FindFirstChild("Base", true)
	if floorPart and not floorPart:IsA("BasePart") then
		floorPart = nil
	end
	-- No floor part to check: assume the usual import turn (90 on X) unless TiltX says otherwise.
	local tilt = uprightModel(house, floorPart, Game.House.TiltX or (not floorPart and 90 or nil))
	learnedTilt = learnedTilt or tilt
	local width = Game.House.Footprints[math.clamp(tier, 1, #Game.House.Footprints)]
	local minV, maxV = worldBounds(house)
	if not minV then
		house:Destroy()
		return false
	end
	local current = math.max(maxV.X - minV.X, maxV.Z - minV.Z)
	if current > 0.01 then
		house:ScaleTo(house:GetScale() * width / current)
	end
	local radius = width / 2
	minV, maxV = worldBounds(house)
	local center = (minV + maxV) / 2
	local floorY = minV.Y -- the lowest point sits on the island
	-- Facade: the name plate (Sign) stands next to the entrance, so the facade is on its side of the
	-- model (snapped to the nearest axis). This works whatever rotation the importer applied.
	local front = Vector3.new(0, 0, -1)
	local sign = house:FindFirstChild("Sign", true)
	if sign and sign:IsA("BasePart") then
		local d = sign.Position - center
		if math.abs(d.X) > math.abs(d.Z) then
			front = Vector3.new(math.sign(d.X), 0, 0)
		elseif math.abs(d.Z) > 0.5 then
			front = Vector3.new(0, 0, math.sign(d.Z))
		end
	end
	local floor = Vector3.new(center.X, floorY, center.Z)
	house.WorldPivot = CFrame.lookAt(floor, floor + front)
	house:PivotTo(altar.center * CFrame.Angles(0, math.rad(Game.House.Yaw or 0), 0))
	-- Bigger house, bigger island (it never shrinks).
	local needed = radius + Game.House.IslandMargin
	if needed > altar.islandRadius then
		altar.islandRadius = needed
		island(altar.center.Position, needed, needed * 1.3)
	end
	if altar.lectern then
		local z = -math.min(radius + 14, altar.islandRadius - 8)
		altar.lectern:PivotTo(altar.center * CFrame.new(math.min(26, radius * 0.6), 0, z))
	end
	house.Name = "House_" .. player.Name
	house.Parent = altar.model
	altar.house = house
	altar.houseTier = tier
	altar.placeholder.Parent = nil
	local sign = house:FindFirstChild("Sign", true)
	if sign and sign:IsA("BasePart") then
		altar.signGui.Parent = sign
	end
	return true
end

local function removeHouse(altar)
	if altar.house then
		altar.house:Destroy()
	end
	altar.house = nil
	altar.houseTier = nil
	altar.signGui.Parent = altar.signPost
	altar.placeholder.Parent = altar.model
end

function WorldService:AssignAltar(player)
	for _, altar in ipairs(WorldService.Altars) do
		if altar.owner == player then
			return altar
		end
	end
	for _, altar in ipairs(WorldService.Altars) do
		if not altar.owner then
			altar.owner = player
			altar.sign.Text = player.DisplayName
			altar.model:SetAttribute("OwnerUserId", player.UserId)
			player:SetAttribute("PlotPosition", altar.display.Position) -- where carried meteors go (CarryService)
			return altar
		end
	end
	return nil
end

function WorldService:ReleaseAltar(player)
	for _, altar in ipairs(WorldService.Altars) do
		if altar.owner == player then
			altar.owner = nil
			altar.sign.Text = "Free plot"
			altar.model:SetAttribute("OwnerUserId", 0)
			removeHouse(altar)
		end
	end
end

function WorldService:GetAltar(player)
	for _, altar in ipairs(WorldService.Altars) do
		if altar.owner == player then
			return altar
		end
	end
	return nil
end

-- The pad with this name if `position` is reasonably close to it (lag tolerant), else nil.
function WorldService:PadNamed(name, position)
	for _, pad in ipairs(WorldService.LaunchPads) do
		if pad.part.Name == name then
			local p = pad.part.Position
			local flat = Vector3.new(position.X - p.X, 0, position.Z - p.Z)
			if flat.Magnitude <= W.LaunchPadRadius + 25 and math.abs(position.Y - p.Y) < 60 then
				return pad
			end
			return nil
		end
	end
	return nil
end

-- Returns the launch pad the position is standing on, if any.
function WorldService:PadAt(position)
	for _, pad in ipairs(WorldService.LaunchPads) do
		local p = pad.part.Position
		local flat = Vector3.new(position.X - p.X, 0, position.Z - p.Z)
		if flat.Magnitude <= W.LaunchPadRadius + 4 and position.Y - p.Y > -6 and position.Y - p.Y < 40 then
			return pad
		end
	end
	return nil
end

function WorldService:Init()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end
	worldFolder = Instance.new("Folder")
	worldFolder.Name = "World"
	worldFolder.Parent = workspace
	craterFolder = Instance.new("Folder")
	craterFolder.Name = "Craters"
	craterFolder.Parent = worldFolder

	setupLighting()
	setupTerrainColors()
	-- A custom Citadel model only adds its parts on top: the terrain layout and the gameplay
	-- objects (plots, pads) are always generated from Game.World.
	buildCustomMap()
	buildCenter()
	buildShop()
	buildLeaderboardIsland()
	if W.GenerateTerrain then
		islets()
	end
	buildPlots()
	buildBifrost()
	buildFusionReactor()
	buildHuntPortal()
end

-- Props ---------------------------------------------------------------------------------------

-- Places the props of ReplicatedStorage.Assets/Map (and Assets/Props) following Game.Props.Layout:
-- each entry is one prop at a spot relative to an anchor (spawn, islets, houses...), on the ground
-- below it (only on terrain, never on bridges or buildings), upright, at its configured size.
local function placeProps()
	local templates = {}
	for _, category in ipairs({ "Props", "Map" }) do
		for _, t in ipairs(AssetLibrary.All(category)) do
			if t.Name ~= "Citadel" then
				templates[string.lower(t.Name)] = t
			end
		end
	end
	local P = Game.Props
	local tilt = P.TiltX or learnedTilt or 90
	local folder = Instance.new("Folder")
	folder.Name = "Props"
	folder.Parent = worldFolder
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }
	local placed, skipped, missing = 0, 0, {}

	local function spawnProp(name, cf, float)
		local template = templates[string.lower(name)]
		if not template then
			missing[name] = true
			return
		end
		local spot = cf.Position
		if not float then
			local hit = workspace:Raycast(spot + Vector3.new(0, 300, 0), Vector3.new(0, -600, 0), params)
			if not hit or hit.Instance ~= terrain then
				skipped += 1
				return -- not on open ground (bridge, building, void)
			end
			spot = hit.Position
		end
		local prop = template:Clone()
		if prop:IsA("BasePart") then
			local m = Instance.new("Model")
			prop.Parent = m
			m.PrimaryPart = prop
			prop = m
		end
		for _, d in ipairs(prop:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		prepareHouse(prop) -- same material rules as the houses (glass, water, lights)
		uprightModel(prop, nil, tilt)
		local minV, maxV = worldBounds(prop)
		if not minV then
			prop:Destroy()
			return
		end
		local ext = maxV - minV
		local big = math.max(ext.X, ext.Y, ext.Z)
		local target = P.Size[string.lower(name)] or 12
		if big > 0.01 then
			prop:ScaleTo(prop:GetScale() * target / big)
			minV, maxV = worldBounds(prop)
		end
		local c = (minV + maxV) / 2
		prop.WorldPivot = CFrame.new(c.X, float and c.Y or minV.Y, c.Z)
		local turn = math.rad(P.Yaw[string.lower(name)] or 0)
		prop:PivotTo(CFrame.new(spot) * (cf - cf.Position) * CFrame.Angles(0, turn, 0))
		prop.Parent = folder
		placed += 1
	end

	-- Anchors: CFrames whose LookVector is "forward" (see Game.Props).
	local W = Game.World
	local function flatLook(from, to)
		return CFrame.lookAt(from, Vector3.new(to.X, from.Y, to.Z))
	end
	local anchors = {
		world = { CFrame.new(W.FieldCenter) },
		spawn = { flatLook(W.SpawnPosition, W.FieldCenter) },
		shop = { flatLook(W.ShopIsland.center, Vector3.zero) },
		leaderboard = { flatLook(W.LeaderboardIsland.center, Vector3.zero) },
		islet = {},
		house = {},
	}
	for _, altar in ipairs(WorldService.Altars) do
		table.insert(anchors.islet, altar.display)
		table.insert(anchors.house, altar.center)
	end

	-- The facing of a prop at `pos` (world) for an anchor `cf`.
	local function facing(cf, pos, face)
		local flat = Vector3.new(cf.Position.X - pos.X, 0, cf.Position.Z - pos.Z)
		if (face == "center" or face == "out") and flat.Magnitude > 0.5 then
			local dir = face == "center" and flat.Unit or -flat.Unit
			return CFrame.lookAt(pos, pos + dir)
		end
		local look = face == "back" and -cf.LookVector or cf.LookVector
		look = Vector3.new(look.X, 0, look.Z)
		return look.Magnitude > 0.01 and CFrame.lookAt(pos, pos + look.Unit) or CFrame.new(pos)
	end

	for _, entry in ipairs(P.Layout) do
		for _, cf in ipairs(anchors[entry.anchor] or {}) do
			if entry.ring then
				local count, radius = entry.ring[1], entry.ring[2]
				for i = 1, count do
					local a = (i - 0.5) / count * math.pi * 2
					local pos = cf.Position + Vector3.new(math.cos(a) * radius, entry.at.Y, math.sin(a) * radius)
					spawnProp(entry.prop, facing(cf, pos, entry.face), entry.float)
				end
			else
				local pos = cf:PointToWorldSpace(entry.at)
				spawnProp(entry.prop, facing(cf, pos, entry.face), entry.float)
			end
		end
	end
	local names = {}
	for name in pairs(missing) do
		table.insert(names, name)
	end
	print(string.format("[Props] placed %d props (%d spots skipped: not on terrain)%s", placed, skipped,
		#names > 0 and (", missing models: " .. table.concat(names, ", ")) or ""))
end

function WorldService:Start()
	Players.PlayerRemoving:Connect(function(player)
		WorldService:ReleaseAltar(player)
	end)
	-- After the first house (so props get the same import turn), or after a short wait.
	task.spawn(function()
		local t = os.clock()
		while not learnedTilt and os.clock() - t < 25 do
			task.wait(1)
		end
		placeProps()
	end)
end

return WorldService
