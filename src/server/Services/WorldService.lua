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

local MARBLE = Color3.fromRGB(232, 224, 240)
local GOLD = Color3.fromRGB(205, 145, 70)
local GOLD_LIGHT = Color3.fromRGB(255, 195, 100)
local GLITCH_COLORS = {
	Color3.fromRGB(80, 220, 255),
	Color3.fromRGB(255, 80, 200),
	Color3.fromRGB(255, 200, 90),
	Color3.fromRGB(150, 100, 255),
	Color3.fromRGB(235, 245, 255),
}

-- Parts -------------------------------------------------------------------------------

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

-- Walkable bridge between two points: marble deck with golden rails.
local function bridge(from, to, width, props)
	props = props or {}
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local length = (to - from).Magnitude
	local cf = CFrame.lookAt((from + to) / 2, to)
	part({
		Name = props.Name or "Bridge",
		Size = Vector3.new(width, 1.2, length + 2),
		CFrame = cf * CFrame.new(0, -0.6, 0),
		Material = props.Material or Enum.Material.Marble,
		Color = props.Color or MARBLE,
	})
	if props.rails ~= false then
		for _, side in ipairs({ -1, 1 }) do
			part({
				Name = "BridgeRail",
				Size = Vector3.new(0.8, 1.6, length + 2),
				CFrame = cf * CFrame.new(side * (width / 2 - 0.4), 0.8, 0),
				Material = Enum.Material.Neon,
				Color = GOLD_LIGHT,
				Transparency = 0.15,
			})
		end
	end
	return flat
end

-- Asgard-style golden tower: stacked tapering blocks, glowing trims and a sharp spike.
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

-- Launch pad: big glowing disc in the tier color with a column of light, visible from far away.
local function makePad(index, position, lookAt, returnCFrame, tier, padsFolder)
	local tierDef = Planets.Tiers[tier]
	local R = W.LaunchPadRadius
	disc(position - Vector3.new(0, 0.6, 0), R + 2.5, 1.2, {
		Name = "PadBase",
		Material = Enum.Material.Marble,
		Color = MARBLE,
		Parent = padsFolder,
	})
	local pad = disc(position, R, 0.6, {
		Name = "LaunchPad" .. index,
		Material = Enum.Material.Neon,
		Color = tierDef.color,
		CanCollide = false,
		Parent = padsFolder,
	})
	pad.CFrame = CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)) * CFrame.Angles(0, 0, math.rad(90))
	part({
		Name = "PadBeam",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(70, R * 1.6, R * 1.6),
		CFrame = CFrame.new(position + Vector3.new(0, 35, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Neon,
		Color = tierDef.color,
		Transparency = 0.82,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Parent = padsFolder,
	})
	local text, bb = label(pad, "LAUNCH · " .. tierDef.name, UDim2.new(22, 0, 4, 0), Vector3.new(0, 10, 0),
		tierDef.color:Lerp(Color3.new(1, 1, 1), 0.4))
	bb.MaxDistance = 600
	text.TextStrokeTransparency = 0
	pad:SetAttribute("Tier", tier)
	pad:SetAttribute("RequiredEvolution", tierDef.requiredEvolution)
	pad:SetAttribute("ReturnCFrame", returnCFrame)
	table.insert(WorldService.LaunchPads, { part = pad, returnCFrame = returnCFrame, tier = tier })
end

-- Central island and Meteor Field -------------------------------------------------------

local function buildCenter()
	island(Vector3.zero, W.CenterRadius, W.CenterRadius * 0.7)
	-- Meteor Field: dark scorched rock with small craters, a glowing rim.
	local f = W.FieldCenter
	if W.GenerateTerrain then
		terrain:FillCylinder(CFrame.new(f - Vector3.new(0, 4, 0)), 8, W.FieldRadius, Enum.Material.Basalt)
		for _ = 1, 40 do
			local a = trng:NextNumber(0, math.pi * 2)
			local d = trng:NextNumber(12, W.FieldRadius - 14)
			local cr = trng:NextNumber(5, 10)
			terrain:FillBall(f + Vector3.new(math.cos(a) * d, cr * 0.75, math.sin(a) * d), cr, Enum.Material.Air)
		end
	end
	disc(f + Vector3.new(0, 0.1, 0), W.FieldRadius + 3, 0.3, {
		Name = "FieldRim",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 120, 60),
		Transparency = 0.35,
		CanCollide = false,
		CanQuery = false,
	})
	-- The vortex meteors pour out of, high above the field.
	disc(f + Vector3.new(0, 420, 0), W.FieldRadius * 0.8, 3, {
		Name = "SkyVortex",
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(170, 110, 255),
		CanCollide = false,
		CanQuery = false,
	})
	-- Golden towers around the island edge, between the bridges.
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

-- Placeholder temple shown until a house model (Assets/Houses) exists.
local function placeholderHouse(cf, parent)
	local s = 2.2
	local model = Instance.new("Model")
	model.Name = "Placeholder"
	local pos = cf.Position
	disc(pos + Vector3.new(0, 0.75 * s, 0), 14 * s, 1.5 * s, { Name = "Base", Material = Enum.Material.Marble, Color = MARBLE, Parent = model })
	for k = 0, 5 do
		local a = math.rad(30 + k * 60)
		part({
			Name = "Column",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(16 * s, 2.6 * s, 2.6 * s),
			CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 10 * s, 9.5 * s, math.sin(a) * 10 * s)) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.Marble,
			Color = MARBLE,
			Parent = model,
		})
	end
	disc(pos + Vector3.new(0, 18.2 * s, 0), 13 * s, 1.4 * s, { Name = "Roof", Material = Enum.Material.Marble, Color = MARBLE, Parent = model })
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
		Material = Enum.Material.Marble,
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
			slots = nil,
		})
	end
end

-- Side islands --------------------------------------------------------------------------

local function sideIsland(cfg, outward)
	local c = cfg.center
	island(c, cfg.radius, cfg.radius * 0.9)
	-- A real mountain on the outer back corner of the island.
	mountain(c + Vector3.new(outward * cfg.radius * 0.45, 0, cfg.radius * 0.3), cfg.radius * 0.6, W.MountainHeight)
	local dir = (Vector3.zero - c).Unit
	bridge(c + dir * (cfg.radius - 12), c + dir * (c.Magnitude - W.CenterRadius + 12), 22)
	return CFrame.lookAt(c + dir * cfg.radius * 0.35, c + dir * cfg.radius)
end

local function buildShop()
	local front = sideIsland(W.ShopIsland, -1)
	local s = 2
	-- Shop stall: marble counter, golden canopy, a prompt that opens the shop.
	local stall = Instance.new("Model")
	stall.Name = "ShopStall"
	part({ Name = "Counter", Size = Vector3.new(22 * s, 4 * s, 5 * s), CFrame = front * CFrame.new(0, 2 * s, 0), Material = Enum.Material.Marble, Color = MARBLE, Parent = stall })
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

-- Bifrost: three separate bridges, each to its own Launch Platform ------------------------------

local function buildLane(lane, padsFolder)
	local rng = Random.new(3 + lane)
	local tier = Planets.Tiers[lane]
	local dir = Vector3.new(math.sin(math.rad(tier.laneAngle)), 0, math.cos(math.rad(tier.laneAngle)))
	local right = Vector3.new(dir.Z, 0, -dir.X)
	local platform = dir * W.PlatformDistance
	local startDist = W.CenterRadius - 15
	local endDist = W.PlatformDistance - W.PlatformRadius + 10
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

	-- The lane's own Launch Platform with 4 pads facing its planet.
	island(platform, W.PlatformRadius - 8, W.PlatformRadius * 0.9, Enum.Material.Basalt)
	disc(platform + Vector3.new(0, 0.7, 0), W.PlatformRadius, 1.4, {
		Name = "LaunchPlatform",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(26, 28, 52),
		Reflectance = 0.3,
	})
	disc(platform + Vector3.new(0, 0.5, 0), W.PlatformRadius + 2, 1, {
		Name = "LaunchPlatformRim",
		Material = Enum.Material.Neon,
		Color = tier.color,
		CanCollide = false,
	})
	local toPlanet = Vector3.new(tier.position.X - platform.X, 0, tier.position.Z - platform.Z).Unit
	local face = CFrame.lookAt(platform, platform + toPlanet)
	local returnCFrame = face * CFrame.new(0, 4, W.PlatformRadius * 0.35)
	for k = 1, 4 do
		local a = math.rad(-36 + (k - 1) * 24)
		local pos = (face * CFrame.new(math.sin(a) * W.PadRingRadius, 1.7, -math.cos(a) * W.PadRingRadius)).Position
		makePad((lane - 1) * 4 + k, pos, tier.position, returnCFrame, lane, padsFolder)
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

-- Places the custom house model for this evolution tier on the player's house island.
-- Returns true when the house changed. No-op when there are no house assets.
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
	for _, d in ipairs(house:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	house:PivotTo(altar.center)
	house.Name = "House_" .. player.Name
	house.Parent = altar.model
	altar.house = house
	altar.houseTier = tier
	altar.placeholder.Parent = nil
	local sign = house:FindFirstChild("Sign")
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
end

function WorldService:Start()
	Players.PlayerRemoving:Connect(function(player)
		WorldService:ReleaseAltar(player)
	end)
end

return WorldService
