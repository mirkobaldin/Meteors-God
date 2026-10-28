-- Builds the whole map from code, divided in zones like Asgard:
--   1) the City of the Gods (raised central island) with the players' houses,
--   2) the Impact Field (a ring of dark rock around it) where meteors fall,
--   3) the Bifrost, a great rainbow bridge to the Launch Platform facing the planet.

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
	center = Vector3.new(0, Game.World.FieldY, 0),
	inner = Game.World.FieldInner,
	outer = Game.World.FieldOuter,
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
		text.Text = "Altare libero"
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
	t.Text = "LANCIO"
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

-- ZONE 1: the City of the Gods (raised central island with the 8 houses).
local function buildCity()
	local y = W.CityY
	local r = W.CityRadius
	disc(Vector3.new(0, y - 2, 0), r, 4, {
		Name = "City",
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(240, 234, 248),
	})
	disc(Vector3.new(0, y - 2.3, 0), r + 1.5, 3.4, {
		Name = "CityRim",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 205, 110),
		CanCollide = false,
	})
	underside(Vector3.new(0, y - 4, 0), r, 60, Color3.fromRGB(120, 100, 150))
	-- Gold inlay rings on the plaza.
	for _, rr in ipairs({ 30, 62 }) do
		disc(Vector3.new(0, y + 0.05, 0), rr, 0.1, {
			Name = "Inlay",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 210, 120),
			Transparency = 0.4,
			CanCollide = false,
		})
		disc(Vector3.new(0, y + 0.1, 0), rr - 1, 0.1, {
			Name = "InlayInner",
			Material = Enum.Material.Marble,
			Color = Color3.fromRGB(240, 234, 248),
			CanCollide = false,
		})
	end
	-- Central palace: spire with a floating divine orb (the city's landmark).
	disc(Vector3.new(0, y + 1, 0), 16, 2, {
		Name = "PalaceBase",
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(230, 222, 240),
	})
	part({
		Name = "Spire",
		Size = Vector3.new(6, 46, 6),
		CFrame = CFrame.new(0, y + 25, 0) * CFrame.Angles(0, math.rad(45), 0),
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(245, 240, 252),
	})
	part({
		Name = "SpireGold",
		Size = Vector3.new(7, 4, 7),
		CFrame = CFrame.new(0, y + 47, 0) * CFrame.Angles(0, math.rad(45), 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 205, 110),
	})
	local orb = part({
		Name = "DivineOrb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(12, 12, 12),
		CFrame = CFrame.new(0, y + 58, 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(190, 140, 255),
		CanCollide = false,
	})
	local light = Instance.new("PointLight")
	light.Color = orb.Color
	light.Range = 60
	light.Brightness = 3
	light.Parent = orb

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, y + 2.5, 22)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(255, 240, 200)
	spawn.Transparency = 0.5
	spawn.Duration = 0
	spawn.Parent = worldFolder
end

-- ZONE 2: the Impact Field, a lower ring of dark rock around the city where meteors fall.
local function buildField()
	local y = W.FieldY
	local inner, outer = W.FieldInner, W.FieldOuter
	local segments = 56
	local mid = (inner + outer) / 2
	local depth = outer - inner
	for i = 1, segments do
		local a = (i - 0.5) / segments * math.pi * 2
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		part({
			Name = "Field",
			Size = Vector3.new(2 * math.pi * outer / segments + 1.5, 3, depth),
			CFrame = CFrame.lookAt(dir * mid + Vector3.new(0, y - 1.5, 0), Vector3.new(0, y - 1.5, 0)),
			Material = Enum.Material.Basalt,
			Color = Color3.fromRGB(70, 58, 72):Lerp(Color3.fromRGB(110, 90, 100), (i % 3) * 0.12),
		})
	end
	-- Glowing edges so the ring reads clearly from the city.
	for _, rr in ipairs({ inner, outer }) do
		for i = 1, segments do
			local a = (i - 0.5) / segments * math.pi * 2
			local dir = Vector3.new(math.sin(a), 0, math.cos(a))
			part({
				Name = "FieldEdge",
				Size = Vector3.new(2 * math.pi * rr / segments + 0.5, 0.6, 1.2),
				CFrame = CFrame.lookAt(dir * rr + Vector3.new(0, y + 0.1, 0), Vector3.new(0, y + 0.1, 0)),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 120, 60),
				Transparency = 0.3,
				CanCollide = false,
			})
		end
	end
	underside(Vector3.new(0, y - 3, 0), outer * 0.9, 90, Color3.fromRGB(80, 60, 80))
	-- Old craters as decoration.
	local rng = Random.new(7)
	for _ = 1, 26 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(inner + 10, outer - 10)
		local cr = rng:NextNumber(4, 10)
		local pos = Vector3.new(math.sin(a) * d, y, math.cos(a) * d)
		disc(pos + Vector3.new(0, 0.02, 0), cr, 0.1, {
			Name = "Crater",
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(35, 28, 38),
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
	-- 4 ramps from the city down to the field, across the energy moat.
	for i = 0, 3 do
		local a = math.pi / 4 + i * math.pi / 2
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		ramp(
			dir * (W.CityRadius - 3) + Vector3.new(0, W.CityY - 0.6, 0),
			dir * (inner + 6) + Vector3.new(0, y - 0.6, 0),
			16,
			{ Name = "Ramp", Material = Enum.Material.Marble, Color = Color3.fromRGB(230, 222, 240) }
		)
	end
	-- The moat between city and field: soft violet energy far below.
	disc(Vector3.new(0, y - 12, 0), inner, 1, {
		Name = "Moat",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(120, 70, 220),
		Transparency = 0.55,
		CanCollide = false,
	})
end

local function makePadInFolder(padsFolder, index, position, returnCFrame)
	makePad(index, position, returnCFrame, padsFolder)
end

-- ZONE 3: the Bifrost. One great rainbow bridge from the field to the Launch Platform.
local function buildBifrost()
	local y = W.FieldY
	local startZ = W.FieldOuter - 6
	local length = W.BifrostLength
	local width = W.BifrostWidth
	local segments = 16
	local segLen = length / segments
	for s = 1, segments do
		local z = startZ + (s - 0.5) * segLen
		for lane = 1, 6 do
			local hue = ((lane - 1) / 6 + s * 0.015) % 1
			local laneW = width / 6
			part({
				Name = "Bifrost",
				Size = Vector3.new(laneW + 0.05, 1, segLen + 0.05),
				CFrame = CFrame.new(-width / 2 + (lane - 0.5) * laneW, y - 0.5, z),
				Material = Enum.Material.Neon,
				Color = Color3.fromHSV(hue, 0.6, 1),
				Transparency = 0.1,
			})
		end
		for _, side in ipairs({ -1, 1 }) do
			part({
				Name = "BifrostRail",
				Size = Vector3.new(0.8, 2.4, segLen),
				CFrame = CFrame.new(side * (width / 2 + 0.4), y + 1.2, z),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 230, 170),
				Transparency = 0.35,
			})
		end
	end
	-- Arch at the entrance of the bridge.
	for _, side in ipairs({ -1, 1 }) do
		part({
			Name = "ArchPillar",
			Size = Vector3.new(4, 30, 4),
			CFrame = CFrame.new(side * (width / 2 + 3), y + 15, startZ + 4),
			Material = Enum.Material.Marble,
			Color = Color3.fromRGB(245, 240, 252),
		})
	end
	part({
		Name = "ArchTop",
		Size = Vector3.new(width + 12, 4, 5),
		CFrame = CFrame.new(0, y + 31, startZ + 4),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 205, 110),
	})

	-- Launch Platform at the end, with the pads facing the planet.
	local platformZ = startZ + length + W.PlatformRadius - 6
	disc(Vector3.new(0, y - 1, platformZ), W.PlatformRadius, 2, {
		Name = "LaunchPlatform",
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(235, 228, 245),
	})
	disc(Vector3.new(0, y - 1.2, platformZ), W.PlatformRadius + 1.2, 1.6, {
		Name = "LaunchPlatformRim",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(120, 200, 255),
		CanCollide = false,
	})
	underside(Vector3.new(0, y - 2, platformZ), W.PlatformRadius, 40, Color3.fromRGB(120, 100, 150))

	local padsFolder = Instance.new("Folder")
	padsFolder.Name = "LaunchPads"
	padsFolder.Parent = worldFolder
	local returnCFrame = CFrame.lookAt(Vector3.new(0, y + 4, startZ + 12), Vector3.new(0, y + 4, startZ + 60))
	local n = W.LaunchPadCount
	for i = 1, n do
		local x = (i - (n + 1) / 2) * 17
		local z = platformZ + W.PlatformRadius * 0.45 - math.abs(x) * 0.25
		makePadInFolder(padsFolder, i, Vector3.new(x, y + 0.1, z), returnCFrame)
	end
end

local function defaultAltarCenters()
	local centers = {}
	for i = 1, W.AltarCount do
		local a = (i - 0.5) / W.AltarCount * math.pi * 2
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		local pos = dir * W.AltarRingRadius + Vector3.new(0, W.CityY, 0)
		centers[i] = CFrame.lookAt(pos, Vector3.new(0, W.CityY, 0))
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

	local spawnCF = AssetLibrary.MarkerCFrame(map, "Markers/Spawn") or CFrame.new(0, W.CityY + 1, 0)
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
			outer = fieldMarker:GetAttribute("OuterRadius") or W.FieldOuter,
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
			altar.sign.Text = "Altare libero"
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
		buildCity()
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
