-- Builds the whole map from code: the Citadel of the Gods floating at the edge of the
-- universe, the altars, the Star Bridges (Bifrost-like launch lanes) and the lighting.

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
	Lighting.Brightness = 1.5
	Lighting.Ambient = Color3.fromRGB(70, 50, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 70, 140)
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

local function buildCitadel()
	local y = W.CitadelY
	local r = W.CitadelRadius

	disc(Vector3.new(0, y - 2, 0), r, 4, {
		Name = "Citadel",
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(235, 228, 245),
	})
	disc(Vector3.new(0, y - 2.2, 0), r + 2, 3, {
		Name = "CitadelRim",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(150, 90, 255),
		CanCollide = false,
	})
	-- Glowing underside so the platform reads as floating in the void.
	disc(Vector3.new(0, y - 8, 0), r * 0.75, 8, {
		Name = "CitadelUnder",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(110, 70, 200),
		Transparency = 0.2,
		CanCollide = false,
	})
	disc(Vector3.new(0, y - 16, 0), r * 0.4, 10, {
		Name = "CitadelCore",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(200, 120, 255),
		CanCollide = false,
	})

	-- Central hub.
	disc(Vector3.new(0, y + 0.5, 0), 22, 1, {
		Name = "Hub",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 120),
	})
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, y + 1.5, 0)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(255, 240, 200)
	spawn.Transparency = 0.4
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = worldFolder

	-- Decorative pillars along the edge (skipping the bridge side).
	local pillars = 16
	for i = 1, pillars do
		local a = (i - 0.5) / pillars * math.pi * 2
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		if dir.Z < 0.75 then
			local pos = dir * (r - 6)
			part({
				Name = "Pillar",
				Size = Vector3.new(3, 26, 3),
				CFrame = CFrame.new(pos + Vector3.new(0, y + 13, 0)),
				Material = Enum.Material.Marble,
				Color = Color3.fromRGB(245, 240, 250),
			})
			part({
				Name = "PillarTip",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(4, 4, 4),
				CFrame = CFrame.new(pos + Vector3.new(0, y + 28, 0)),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(180, 120, 255),
				CanCollide = false,
			})
		end
	end
end

local function defaultAltarCenters()
	local centers = {}
	for i = 1, W.AltarCount do
		-- Spread altars on the back 3/4 of the ring so they never block the bridges.
		local a = math.pi * 0.25 + (i - 1) / (W.AltarCount - 1) * math.pi * 1.5
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		local pos = dir * W.AltarRingRadius + Vector3.new(0, W.CitadelY, 0)
		centers[i] = CFrame.lookAt(pos, Vector3.new(0, W.CitadelY, 0))
	end
	return centers
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

local function buildBridges()
	local padsFolder = Instance.new("Folder")
	padsFolder.Name = "LaunchPads"
	padsFolder.Parent = worldFolder

	local startZ = W.CitadelRadius - 4
	local segments = 11
	local segLen = W.BridgeLength / segments
	for b = 1, W.BridgeCount do
		local x = (b - (W.BridgeCount + 1) / 2) * W.BridgeSpacing
		for s = 1, segments do
			local hue = ((s - 1) / segments + b * 0.07) % 1
			local z = startZ + (s - 0.5) * segLen
			part({
				Name = "Bridge" .. b,
				Size = Vector3.new(W.BridgeWidth, 1, segLen),
				CFrame = CFrame.new(x, W.CitadelY - 0.5, z),
				Material = Enum.Material.Neon,
				Color = Color3.fromHSV(hue, 0.55, 1),
				Transparency = 0.15,
			})
			for _, side in ipairs({ -1, 1 }) do
				part({
					Name = "Rail",
					Size = Vector3.new(0.6, 2, segLen),
					CFrame = CFrame.new(x + side * (W.BridgeWidth / 2 - 0.3), W.CitadelY + 1, z),
					Material = Enum.Material.Neon,
					Color = Color3.fromHSV(hue, 0.3, 1),
					Transparency = 0.4,
				})
			end
		end

		local endZ = startZ + W.BridgeLength
		local returnCFrame = CFrame.lookAt(
			Vector3.new(x, W.CitadelY + 4, startZ + 4),
			Vector3.new(x, W.CitadelY + 4, startZ + 40)
		)
		makePad(b, Vector3.new(x, W.CitadelY + 0.1, endZ - 6), returnCFrame, padsFolder)
	end
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

	local spawnCF = AssetLibrary.MarkerCFrame(map, "Markers/Spawn") or CFrame.new(0, W.CitadelY + 1, 0)
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
		if flat.Magnitude <= W.LaunchPadRadius and math.abs(position.Y - p.Y) < 12 then
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
		buildCitadel()
		buildAltars(defaultAltarCenters())
		buildBridges()
	end
end

function WorldService:Start()
	Players.PlayerRemoving:Connect(function(player)
		WorldService:ReleaseAltar(player)
	end)
end

return WorldService
