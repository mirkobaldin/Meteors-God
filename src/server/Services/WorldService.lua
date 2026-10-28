-- Builds the whole map from code, laid out like Asgard (a keyhole shape along the planet axis):
--   1) back:   the Houses district with golden towers,
--   2) middle: the Meteor Field (raised disc with the Sky Altar) where meteors fall,
--   3) front:  the Bifrost of cosmic glitching glass to the Launch Platform facing the planet.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local AssetLibrary = require(Shared.AssetLibrary)

local WorldService = {}

WorldService.Altars = {} -- { {index, model, center: CFrame, owner: Player?, sign: TextLabel} }
WorldService.LaunchPads = {} -- { {part, returnCFrame} }
WorldService.PlanetPosition = Game.World.PlanetPosition
-- Where meteors fall: a ring (inner/outer radius) around `center`.
WorldService.Field = {
	center = Game.World.FieldCenter,
	inner = Game.World.FieldInner,
	outer = Game.World.FieldRadius,
}

local W = Game.World
local worldFolder

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

local function setupLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 2.5
	Lighting.ExposureCompensation = 0.2
	Lighting.Ambient = Color3.fromRGB(90, 80, 140)
	Lighting.OutdoorAmbient = Color3.fromRGB(125, 115, 175)
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.StarCount = 5000
	sky.CelestialBodiesShown = false
	sky.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.8
	bloom.Size = 30
	bloom.Threshold = 0.9
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.15
	cc.Contrast = 0.08
	cc.TintColor = Color3.fromRGB(235, 225, 255)
	cc.Parent = Lighting
end

-- Procedural plinth + name sign for each house spot. A custom house model (Assets/Houses)
-- is placed on top of it later by UpdateHouse, hiding the plinth.
local function buildAltars(centers)
	local folder = Instance.new("Folder")
	folder.Name = "Altars"
	folder.Parent = worldFolder

	for i, center in ipairs(centers) do
		local pos = center.Position
		local model = Instance.new("Model")
		model.Name = "Altar" .. i

		disc(pos + Vector3.new(0, 1, 0), 10, 2, {
			Name = "Base",
			Material = Enum.Material.Marble,
			Color = Color3.fromRGB(230, 220, 240),
			Parent = model,
		})
		disc(pos + Vector3.new(0, 2.1, 0), 8, 0.3, {
			Name = "Glow",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(120, 90, 200),
			CanCollide = false,
			Parent = model,
		})
		local signPost = part({
			Name = "Sign",
			Size = Vector3.new(1, 1, 1),
			Transparency = 1,
			CanCollide = false,
			CFrame = CFrame.new(pos + Vector3.new(0, 14, 0)),
			Parent = model,
		})
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(16, 0, 4, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 250
		bb.Parent = signPost
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextStrokeTransparency = 0.3
		text.Text = "Free altar"
		text.Parent = bb

		model.Parent = folder
		table.insert(WorldService.Altars, {
			index = i,
			model = model,
			center = center,
			owner = nil,
			sign = text,
			signGui = bb,
			signPost = signPost,
			house = nil,
			houseTier = nil,
			slots = nil,
		})
	end
end

local function makePad(index, position, returnCFrame, padsFolder)
	local pad = disc(position, 7, 0.4, {
		Name = "LaunchPad" .. index,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 230, 120),
		CanCollide = false,
		Parent = padsFolder,
	})
	local label = Instance.new("BillboardGui")
	label.Size = UDim2.new(14, 0, 3, 0)
	label.StudsOffset = Vector3.new(0, 6, 0)
	label.LightInfluence = 0
	label.MaxDistance = 200
	label.Parent = pad
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 240, 180)
	t.TextStrokeTransparency = 0.3
	t.Text = "LAUNCH"
	t.Parent = label
	pad:SetAttribute("ReturnCFrame", returnCFrame)
	table.insert(WorldService.LaunchPads, { part = pad, returnCFrame = returnCFrame })
end

-- Ramp between two points (a tilted slab).
local function ramp(from, to, width, props)
	local length = (to - from).Magnitude
	props.Size = Vector3.new(width, 1.2, length)
	props.CFrame = CFrame.lookAt((from + to) / 2, to)
	return part(props)
end

-- Floating rock underside: stacked shrinking discs give a cone of rock under an island.
local function underside(pos, radius, depth, color)
	local steps = 4
	for i = 1, steps do
		local t = i / steps
		disc(pos - Vector3.new(0, depth * t, 0), radius * (1 - t * 0.75), depth / steps + 1, {
			Name = "Underside",
			Material = Enum.Material.Rock,
			Color = color:Lerp(Color3.fromRGB(20, 15, 30), t * 0.6),
			CanCollide = false,
		})
	end
end

local CollectionService = game:GetService("CollectionService")

local GOLD = Color3.fromRGB(205, 145, 70)
local GOLD_LIGHT = Color3.fromRGB(255, 195, 100)
local GLITCH_COLORS = {
	Color3.fromRGB(80, 220, 255),
	Color3.fromRGB(255, 80, 200),
	Color3.fromRGB(255, 200, 90),
	Color3.fromRGB(150, 100, 255),
	Color3.fromRGB(235, 245, 255),
}

-- Asgard-style golden tower: stacked tapering blocks, glowing trims and a sharp spike.
local function tower(base, height, width)
	local steps = 5
	local y = base.Y
	for i = 1, steps do
		local t = (i - 1) / steps
		local w = width * (1 - t * 0.55)
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
		Size = Vector3.new(width * 0.18, height * 0.35, width * 0.18),
		CFrame = CFrame.new(base.X, y + height * 0.175, base.Z) * CFrame.Angles(0, math.rad(45), 0),
		Material = Enum.Material.Neon,
		Color = GOLD_LIGHT,
		CanCollide = false,
	})
end

-- ZONE 1 (back): the Houses district, a large disc behind the meteor field.
local function buildHouses()
	local c = W.HousesCenter
	disc(c - Vector3.new(0, 2, 0), W.HousesRadius, 4, {
		Name = "HousesGround",
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(225, 215, 235),
	})
	disc(c - Vector3.new(0, 2.3, 0), W.HousesRadius + 1.5, 3.4, {
		Name = "HousesRim",
		Material = Enum.Material.Neon,
		Color = GOLD_LIGHT,
		CanCollide = false,
	})
	underside(c - Vector3.new(0, 4, 0), W.HousesRadius, 90, Color3.fromRGB(110, 90, 130))
	-- Golden towers along the back rim, between the houses.
	for i = 0, 8 do
		local a = math.rad(-120 + i * 30)
		local pos = c + Vector3.new(math.sin(a), 0, -math.cos(a)) * (W.HousesRadius - 10)
		tower(pos, 40 + (i % 3) * 18, 9)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(c + Vector3.new(0, 0.5, -55))
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(255, 225, 160)
	spawn.Transparency = 0.5
	spawn.Duration = 0
	spawn.Parent = worldFolder
end

-- ZONE 2 (middle): the Meteor Field, a raised disc of dark rock in front of the houses,
-- with the Sky Altar in its center (the vortex meteors pour out of).
local function buildField()
	local c = W.FieldCenter
	local r = W.FieldRadius
	disc(c - Vector3.new(0, 2, 0), r, 4, {
		Name = "Field",
		Material = Enum.Material.Basalt,
		Color = Color3.fromRGB(62, 52, 68),
	})
	disc(c - Vector3.new(0, 2.2, 0), r + 1.2, 3.6, {
		Name = "FieldRim",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 120, 60),
		Transparency = 0.2,
		CanCollide = false,
	})
	underside(c - Vector3.new(0, 4, 0), r, 70, Color3.fromRGB(70, 55, 75))
	local rng = Random.new(11)
	for _ = 1, 30 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(W.FieldInner + 8, r - 8)
		local cr = rng:NextNumber(3, 9)
		local pos = c + Vector3.new(math.sin(a) * d, 0, math.cos(a) * d)
		disc(pos + Vector3.new(0, 0.02, 0), cr, 0.1, {
			Name = "Crater",
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(32, 26, 36),
			CanCollide = false,
		})
		disc(pos + Vector3.new(0, 0.04, 0), cr * 0.45, 0.1, {
			Name = "CraterGlow",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 110, 40),
			Transparency = 0.5,
			CanCollide = false,
		})
	end
	-- Sky Altar: a sunken ring with a light beam to the vortex above.
	disc(c + Vector3.new(0, 0.05, 0), W.FieldInner, 0.2, {
		Name = "SkyAltarRing",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(150, 100, 255),
		Transparency = 0.3,
		CanCollide = false,
	})
	disc(c + Vector3.new(0, 0.1, 0), W.FieldInner - 3, 0.2, {
		Name = "SkyAltar",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(20, 18, 40),
		Reflectance = 0.3,
	})
	part({
		Name = "SkyBeam",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(400, 10, 10),
		CFrame = CFrame.new(c + Vector3.new(0, 200, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(170, 120, 255),
		Transparency = 0.75,
		CanCollide = false,
		CanQuery = false,
	})
	disc(c + Vector3.new(0, 260, 0), 60, 2, {
		Name = "SkyVortex",
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(160, 110, 255),
		CanCollide = false,
		CanQuery = false,
	})
	-- Ramps down to the houses district (the field sits higher).
	for _, deg in ipairs({ 125, 160, 200, 235 }) do
		local a = math.rad(deg)
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		ramp(
			c + dir * (r - 4) - Vector3.new(0, 0.6, 0),
			c + dir * (r + 16) + Vector3.new(0, W.HousesCenter.Y - c.Y - 0.6, 0),
			18,
			{ Name = "Ramp", Material = Enum.Material.Marble, Color = Color3.fromRGB(225, 215, 235) }
		)
	end
end

local function makePadInFolder(padsFolder, index, position, returnCFrame)
	makePad(index, position, returnCFrame, padsFolder)
end

-- ZONE 3 (front): the Bifrost, a bridge of dark cosmic glass full of glitching light,
-- flanked by golden towers, ending at the observatory-style Launch Platform.
local function buildBifrost()
	local y = W.FieldCenter.Y
	local startZ = W.FieldCenter.Z + W.FieldRadius - 6
	local length = W.BifrostLength
	local width = W.BifrostWidth
	local rng = Random.new(3)

	local rows, cols = 24, 4
	local segLen, colW = length / rows, width / cols
	for r = 1, rows do
		for col = 1, cols do
			part({
				Name = "Bifrost",
				Size = Vector3.new(colW + 0.05, 1, segLen + 0.05),
				CFrame = CFrame.new(-width / 2 + (col - 0.5) * colW, y - 0.5, startZ + (r - 0.5) * segLen),
				Material = Enum.Material.Glass,
				Color = Color3.fromRGB(14, 16, 32):Lerp(Color3.fromRGB(30, 35, 60), rng:NextNumber()),
				Reflectance = 0.3,
			})
		end
	end
	-- Glitch pixels: small glowing fragments of every cosmic color (animated on the clients).
	for _ = 1, 320 do
		local w = rng:NextNumber(0.4, 1.8)
		local l = rng:NextNumber(0.4, 4.5)
		local glitch = part({
			Name = "BifrostGlitch",
			Size = Vector3.new(w, 0.12, l),
			CFrame = CFrame.new(rng:NextNumber(-width / 2 + 1, width / 2 - 1), y + 0.06, startZ + rng:NextNumber(2, length - 2)),
			Material = Enum.Material.Neon,
			Color = GLITCH_COLORS[rng:NextInteger(1, #GLITCH_COLORS)],
			Transparency = rng:NextNumber(0.15, 0.7),
			CanCollide = false,
			CanQuery = false,
		})
		CollectionService:AddTag(glitch, "BifrostGlitch")
	end
	-- Long light streaks running along the bridge.
	for i = 1, 6 do
		part({
			Name = "BifrostStreak",
			Size = Vector3.new(0.25, 0.1, length),
			CFrame = CFrame.new(-width / 2 + i * width / 7, y + 0.05, startZ + length / 2),
			Material = Enum.Material.Neon,
			Color = i % 2 == 0 and Color3.fromRGB(80, 220, 255) or Color3.fromRGB(255, 120, 220),
			Transparency = 0.6,
			CanCollide = false,
			CanQuery = false,
		})
	end
	for _, side in ipairs({ -1, 1 }) do
		part({
			Name = "BifrostEdge",
			Size = Vector3.new(0.8, 1.2, length),
			CFrame = CFrame.new(side * (width / 2 + 0.4), y + 0.3, startZ + length / 2),
			Material = Enum.Material.Neon,
			Color = GOLD_LIGHT,
			Transparency = 0.2,
		})
		-- Golden towers at the entrance of the bridge, like the Bifrost gate.
		tower(Vector3.new(side * (width / 2 + 9), y, startZ + 6), 70, 12)
	end

	-- Observatory Launch Platform with a golden dome and the pads facing the planet.
	local platformZ = startZ + length + W.PlatformRadius - 6
	disc(Vector3.new(0, y - 1, platformZ), W.PlatformRadius, 2, {
		Name = "LaunchPlatform",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(18, 20, 40),
		Reflectance = 0.3,
	})
	disc(Vector3.new(0, y - 1.2, platformZ), W.PlatformRadius + 1.2, 1.6, {
		Name = "LaunchPlatformRim",
		Material = Enum.Material.Neon,
		Color = GOLD_LIGHT,
		CanCollide = false,
	})
	underside(Vector3.new(0, y - 2, platformZ), W.PlatformRadius, 40, Color3.fromRGB(110, 90, 130))
	local domeCenter = Vector3.new(0, y, platformZ - W.PlatformRadius * 0.45)
	part({
		Name = "ObservatoryDome",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(22, 22, 22),
		CFrame = CFrame.new(domeCenter),
		Material = Enum.Material.Foil,
		Color = GOLD,
		Reflectance = 0.2,
	})
	part({
		Name = "ObservatorySpike",
		Size = Vector3.new(2.5, 26, 2.5),
		CFrame = CFrame.new(domeCenter + Vector3.new(0, 20, 0)) * CFrame.Angles(0, math.rad(45), 0),
		Material = Enum.Material.Neon,
		Color = GOLD_LIGHT,
		CanCollide = false,
	})

	local padsFolder = Instance.new("Folder")
	padsFolder.Name = "LaunchPads"
	padsFolder.Parent = worldFolder
	local returnCFrame = CFrame.lookAt(Vector3.new(0, y + 4, startZ + 14), Vector3.new(0, y + 4, startZ + 60))
	local n = W.LaunchPadCount
	for i = 1, n do
		local x = (i - (n + 1) / 2) * 15
		local z = platformZ + W.PlatformRadius * 0.5 - math.abs(x) * 0.3
		makePadInFolder(padsFolder, i, Vector3.new(x, y + 0.1, z), returnCFrame)
	end
end

-- Houses spread on the visible crescent of the houses district, facing the meteor field.
local function defaultAltarCenters()
	local centers = {}
	local c = W.HousesCenter
	local n = W.AltarCount
	for i = 1, n do
		local a = math.rad(-110 + (i - 1) * (220 / (n - 1)))
		local pos = c + Vector3.new(math.sin(a), 0, -math.cos(a)) * W.HouseRingRadius
		centers[i] = CFrame.lookAt(pos, Vector3.new(W.FieldCenter.X, pos.Y, W.FieldCenter.Z))
	end
	return centers
end

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

	local spawnCF = AssetLibrary.MarkerCFrame(map, "Markers/Spawn") or CFrame.new(W.HousesCenter + Vector3.new(0, 1, 0))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(spawnCF.Position)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = worldFolder

	local centers = {}
	for i = 1, W.AltarCount do
		local cf = AssetLibrary.MarkerCFrame(map, "Markers/House" .. i)
		if cf then
			table.insert(centers, CFrame.new(cf.Position) * cf.Rotation)
		end
	end
	buildAltars(#centers > 0 and centers or defaultAltarCenters())

	local padsFolder = Instance.new("Folder")
	padsFolder.Name = "LaunchPads"
	padsFolder.Parent = worldFolder
	for b = 1, 8 do
		local padCF = AssetLibrary.MarkerCFrame(map, "Markers/LaunchPad" .. b)
		if padCF then
			local returnCF = AssetLibrary.MarkerCFrame(map, "Markers/Return" .. b) or spawnCF
			makePad(b, padCF.Position, returnCF + Vector3.new(0, 3, 0), padsFolder)
		end
	end
	local markers2 = map:FindFirstChild("Markers")
	local fieldMarker = markers2 and markers2:FindFirstChild("Field")
	if fieldMarker and fieldMarker:IsA("BasePart") then
		WorldService.Field = {
			center = fieldMarker.Position,
			inner = fieldMarker:GetAttribute("InnerRadius") or 0,
			outer = fieldMarker:GetAttribute("OuterRadius") or W.FieldRadius,
		}
	end
	local planetCF = AssetLibrary.MarkerCFrame(map, "Markers/Planet")
	if planetCF then
		WorldService.PlanetPosition = planetCF.Position
	end
	return true
end

-- Places the custom house model for this evolution tier on the player's spot.
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

	for _, name in ipairs({ "Base", "Glow" }) do
		local p = altar.model:FindFirstChild(name)
		if p then
			p.Transparency = 1
			p.CanCollide = false
		end
	end
	altar.slots = {}
	for k = 1, 4 do
		local cf = AssetLibrary.MarkerCFrame(house, "Slot" .. k)
		if cf then
			altar.slots[k] = cf
			local slotPart = house:FindFirstChild("Slot" .. k)
			if slotPart and slotPart:IsA("BasePart") then
				slotPart.Transparency = 1
				slotPart.CanCollide = false
			end
		end
	end
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
	altar.slots = nil
	altar.signGui.Parent = altar.signPost
	for name, transparency in pairs({ Base = 0, Glow = 0 }) do
		local p = altar.model:FindFirstChild(name)
		if p then
			p.Transparency = transparency
			p.CanCollide = name == "Base"
		end
	end
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
			altar.sign.Text = "Free altar"
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
	if not buildCustomMap() then
		buildHouses()
		buildAltars(defaultAltarCenters())
		buildField()
		buildBifrost()
	end
end

function WorldService:Start()
	Players.PlayerRemoving:Connect(function(player)
		WorldService:ReleaseAltar(player)
	end)
end

return WorldService
