-- The target planet: built from code in 3 layers (crust chunks, mantle, core), damaged by
-- launched meteors, destroyed in a supernova that rains loot on the whole server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Planets = require(Shared.Config.Planets)
local AssetLibrary = require(Shared.AssetLibrary)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)

local PlanetService = {}

local services
local rng = Random.new()
local fxFolder
local destroyedRemote

local currentIndex = 1
local legendaryQueued = false
local state -- current planet state (see spawnPlanet)

local CENTER = Game.World.PlanetPosition
local R = Game.World.PlanetRadius
local CRATER_LIMIT = 14

local function basePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	-- Shape first: changing Shape after Size can resize the part.
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
	return basePart(props)
end

local function layerShares()
	local crust = Planets.Layers[1].share
	local mantle = Planets.Layers[2].share
	return crust, mantle
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

local function updateAttributes()
	if state then
		workspace:SetAttribute("PlanetName", state.def.name)
		workspace:SetAttribute("PlanetHP", state.hp)
		workspace:SetAttribute("PlanetMaxHP", state.maxHP)
		workspace:SetAttribute("PlanetLayer", Planets.Layers[math.max(1, currentLayer())].id)
		workspace:SetAttribute("PlanetLegendary", state.def.legendary == true)
	else
		workspace:SetAttribute("PlanetHP", 0)
		workspace:SetAttribute("PlanetLayer", "")
	end
end

-- Pieces that fly away from the planet and fade out.
local function flingAway(part, distance, duration)
	part.Anchored = true
	local dir = (part.Position - state.center)
	dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 1, 0)
	local spin = CFrame.Angles(rng:NextNumber(-3, 3), rng:NextNumber(-3, 3), rng:NextNumber(-3, 3))
	local goal = CFrame.new(part.Position + dir * distance + Vector3.new(0, rng:NextNumber(-40, 80), 0)) * spin
	local t = TweenService:Create(
		part,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = goal, Transparency = 1 }
	)
	t:Play()
	t.Completed:Connect(function()
		part:Destroy()
	end)
end

local function nameTag(model, def, position)
	local anchor = basePart({
		Name = "NameAnchor",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CFrame = CFrame.new(position),
	})
	anchor.Parent = model
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(160, 0, 26, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 2000
	bb.Parent = anchor
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = def.legendary and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0.2
	text.Text = def.name
	text.Parent = bb
end

-- Planet from Assets/Planets/<name> (pre-fractured Crust folder + Mantle + Core).
local function buildCustomPlanet(model, def, center)
	model.Name = "Planet"
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
		end
	end
	model:PivotTo(CFrame.new(center))
	local core = model:FindFirstChild("Core")
	if not (core and core:IsA("BasePart")) then
		core = ball(R * 0.7, { Name = "Core", Material = Enum.Material.Neon, Color = def.core, CFrame = CFrame.new(center) })
		core.Parent = model
	end
	local mantle = model:FindFirstChild("Mantle")
	if not (mantle and mantle:IsA("BasePart")) then
		mantle = ball(R * 1.6, { Name = "Mantle", Material = Enum.Material.Neon, Color = def.mantle, CFrame = CFrame.new(center) })
		mantle.Parent = model
	end
	local light = Instance.new("PointLight")
	light.Color = def.core
	light.Range = 60
	light.Brightness = 3
	light.Parent = core

	-- Crust pieces go to the model root so they fly away individually.
	local chunks = {}
	local crust = model:FindFirstChild("Crust")
	if crust then
		for _, d in ipairs(crust:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(chunks, d)
			end
		end
		for _, chunk in ipairs(chunks) do
			chunk.Name = "Crust"
			chunk.Parent = model
		end
		crust:Destroy()
	end
	nameTag(model, def, center + Vector3.new(0, model:GetExtentsSize().Y / 2 + 25, 0))
	model.PrimaryPart = core
	return model, core, mantle, chunks
end

local function buildPlanet(def, center)
	local custom = AssetLibrary.Clone("Planets", def.legendary and "Legendary" or def.name)
	if custom then
		return buildCustomPlanet(custom, def, center)
	end

	local model = Instance.new("Model")
	model.Name = "Planet"

	local core = ball(R * 0.7, {
		Name = "Core",
		Material = Enum.Material.Neon,
		Color = def.core,
		CFrame = CFrame.new(center),
	})
	core.Parent = model
	local light = Instance.new("PointLight")
	light.Color = def.core
	light.Range = 60
	light.Brightness = 3
	light.Parent = core

	local mantle = ball(R * 1.6, {
		Name = "Mantle",
		Material = Enum.Material.Neon,
		Color = def.mantle,
		CFrame = CFrame.new(center),
	})
	mantle.Parent = model

	-- Lumpy crust: overlapping balls distributed on a Fibonacci sphere.
	local chunks = {}
	local n = Planets.CrustChunks
	local golden = math.pi * (3 - math.sqrt(5))
	for i = 0, n - 1 do
		local y = 1 - (i / (n - 1)) * 2
		local radius = math.sqrt(1 - y * y)
		local theta = golden * i
		local dir = Vector3.new(math.cos(theta) * radius, y, math.sin(theta) * radius)
		local shade = rng:NextNumber(-0.08, 0.08)
		local h, s, v = def.crust.color:ToHSV()
		local chunk = ball(R * 0.78, {
			Name = "Crust",
			Material = def.crust.material,
			Color = Color3.fromHSV(h, s, math.clamp(v + shade, 0, 1)),
			CFrame = CFrame.new(center + dir * R * 0.76),
		})
		chunk.Parent = model
		table.insert(chunks, chunk)
	end

	if def.legendary then
		local ring = basePart({
			Name = "LegendaryRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2, R * 3.2, R * 3.2),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 220, 90),
			Transparency = 0.45,
			CFrame = CFrame.new(center) * CFrame.Angles(math.rad(15), 0, math.rad(90)),
		})
		ring.Parent = model
	end

	local anchor = basePart({
		Name = "NameAnchor",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CFrame = CFrame.new(center + Vector3.new(0, R * 1.35, 0)),
	})
	anchor.Parent = model
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(160, 0, 26, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 2000
	bb.Parent = anchor
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = def.legendary and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0.2
	text.Text = def.name
	text.Parent = bb

	model.PrimaryPart = core
	return model, core, mantle, chunks
end

local function pulseCore(core)
	local base = core.Size
	TweenService:Create(
		core,
		TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Size = base * 1.12 }
	):Play()
end

local function spawnPlanet(def)
	local playerCount = math.max(1, #Players:GetPlayers())
	local maxHP = math.floor(def.hp * (0.6 + 0.4 * playerCount))
	local startCenter = CENTER + Vector3.new(0, 300, 2500)
	local model, core, mantle, chunks = buildPlanet(def, startCenter)
	model.Parent = workspace

	state = {
		def = def,
		maxHP = maxHP,
		hp = maxHP,
		model = model,
		core = core,
		mantle = mantle,
		mantleBaseSize = mantle.Size,
		chunks = chunks,
		chunksRemoved = 0,
		contributions = {},
		craters = {},
		center = startCenter,
		arriving = true,
		destroyed = false,
	}
	local myState = state
	updateAttributes()

	-- Fly in from deep space.
	local value = Instance.new("CFrameValue")
	value.Value = CFrame.new(startCenter)
	value.Changed:Connect(function(cf)
		if model.Parent then
			model:PivotTo(cf)
		end
	end)
	local tween = TweenService:Create(
		value,
		TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Value = CFrame.new(CENTER) }
	)
	tween:Play()
	tween.Completed:Connect(function()
		value:Destroy()
		if state == myState then
			state.center = CENTER
			state.arriving = false
			pulseCore(core)
		end
	end)

	if def.legendary then
		Notify.Announce("⭐ È ARRIVATO IL " .. def.name .. "! Ricompense x3!", Color3.fromRGB(255, 210, 60))
	else
		Notify.Announce("Sta arrivando il " .. def.name .. "!", Color3.fromRGB(200, 220, 255))
	end
end

function PlanetService:IsTargetable()
	return state ~= nil and not state.destroyed and not state.arriving
end

-- Picks where the next meteor will hit, facing the Citadel.
function PlanetService:GetImpactPoint()
	if not state then
		return CENTER
	end
	local toCitadel = (Vector3.new(0, Game.World.CitadelY, 0) - state.center).Unit
	local layer = currentLayer()
	if layer == 1 then
		local candidates = {}
		for _, chunk in ipairs(state.chunks) do
			if chunk.Name == "Crust" and (chunk.Position - state.center).Unit:Dot(toCitadel) > 0.2 then
				table.insert(candidates, chunk)
			end
		end
		if #candidates == 0 then
			for _, chunk in ipairs(state.chunks) do
				if chunk.Name == "Crust" then
					table.insert(candidates, chunk)
				end
			end
		end
		if #candidates > 0 then
			local chunk = candidates[rng:NextInteger(1, #candidates)]
			local dir = (chunk.Position - state.center).Unit
			return chunk.Position + dir * chunk.Size.X * 0.4
		end
	end
	local spread = Vector3.new(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.4, 0.4), rng:NextNumber(-0.5, 0.5))
	local dir = (toCitadel + spread).Unit
	local radius = layer == 2 and state.mantle.Size.X / 2 or state.core.Size.X / 2
	return state.center + dir * radius
end

local function damageNumber(position, damage, crit, color)
	local anchor = basePart({
		Name = "DamageNumber",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CFrame = CFrame.new(position),
	})
	anchor.Parent = fxFolder
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(crit and 70 or 50, 0, crit and 22 or 15, 0)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = true
	bb.MaxDistance = 2000
	bb.Parent = anchor
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextStrokeTransparency = 0
	t.TextColor3 = crit and Color3.fromRGB(255, 220, 60) or color
	t.Text = (crit and "CRITICO! " or "") .. Format.Number(damage)
	t.Parent = bb
	local tween = TweenService:Create(anchor, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = anchor.CFrame + Vector3.new(0, 40, 0),
	})
	tween:Play()
	TweenService:Create(t, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	tween.Completed:Connect(function()
		anchor:Destroy()
	end)
end

local function impactFX(position, damage, color, ownerName)
	local scale = math.clamp(math.log10(math.max(damage, 10)) * 8, 10, 60)

	local e = Instance.new("Explosion")
	e.Position = position
	e.BlastRadius = scale
	e.BlastPressure = 0
	e.DestroyJointRadiusPercent = 0
	e.ExplosionType = Enum.ExplosionType.NoCraters
	e.Parent = workspace

	local shock = ball(4, {
		Name = "Shockwave",
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.2,
		CFrame = CFrame.new(position),
		CanQuery = false,
	})
	shock.Parent = fxFolder
	local t = TweenService:Create(shock, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(scale * 2.2, scale * 2.2, scale * 2.2),
		Transparency = 1,
	})
	t:Play()
	t.Completed:Connect(function()
		shock:Destroy()
	end)

	-- Crater with the thrower's name; stays until the planet dies.
	if state and state.model.Parent then
		local crater = ball(scale * 0.8, {
			Name = "Crater",
			Material = Enum.Material.Basalt,
			Color = Color3.fromRGB(25, 20, 25),
			CFrame = CFrame.new(position),
		})
		crater.Parent = state.model
		local glow = Instance.new("PointLight")
		glow.Color = color
		glow.Range = scale
		glow.Parent = crater
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(40, 0, 8, 0)
		bb.StudsOffset = Vector3.new(0, scale * 0.6, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 1500
		bb.Parent = crater
		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.fromScale(1, 1)
		name.Font = Enum.Font.FredokaOne
		name.TextScaled = true
		name.TextColor3 = color
		name.TextStrokeTransparency = 0.3
		name.Text = ownerName
		name.Parent = bb
		table.insert(state.craters, crater)
		if #state.craters > CRATER_LIMIT then
			local oldest = table.remove(state.craters, 1)
			if oldest.Parent then
				oldest:Destroy()
			end
		end
	end
end

local function updateCrust(impactPoint)
	local crustHP = state.maxHP * Planets.Layers[1].share
	local lost = math.min(state.maxHP - state.hp, crustHP)
	local target = math.floor(lost / crustHP * #state.chunks + 1e-6)
	while state.chunksRemoved < target do
		local best, bestDist
		for _, chunk in ipairs(state.chunks) do
			if chunk.Parent and chunk.Name == "Crust" then
				local d = (chunk.Position - impactPoint).Magnitude
				if not bestDist or d < bestDist then
					best, bestDist = chunk, d
				end
			end
		end
		if not best then
			break
		end
		best.Name = "CrustFalling"
		best.Parent = fxFolder
		flingAway(best, 350, 3)
		state.chunksRemoved += 1
	end
end

local function shatter(part, pieces, color)
	local center = part.Position
	local size = part.Size.X
	for _ = 1, pieces do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
		local frag = basePart({
			Name = "Fragment",
			Size = Vector3.new(size * 0.3, size * 0.22, size * 0.26),
			Material = part.Material,
			Color = color or part.Color,
			CFrame = CFrame.new(center + dir * size * 0.3),
		})
		frag.Parent = fxFolder
		flingAway(frag, 500, 3.5)
	end
	part:Destroy()
end

local function updateMantle()
	local crust, mantleShare = layerShares()
	local lost = state.maxHP - state.hp
	local f = math.clamp((lost - state.maxHP * crust) / (state.maxHP * mantleShare), 0, 1)
	if state.mantle and state.mantle.Parent then
		if f >= 1 then
			shatter(state.mantle, 16)
			Notify.Announce("Il mantello del " .. state.def.name .. " è esploso! Colpite il nucleo!", state.def.core)
		elseif f > 0 then
			local size = state.mantleBaseSize * (1 - 0.3 * f)
			state.mantle.Size = size
			state.mantle.Color = state.def.mantle:Lerp(Color3.fromRGB(30, 20, 20), 0.5 * f)
		end
	end
end

local function supernova()
	local s = state
	s.destroyed = true
	updateAttributes()

	local center = s.center
	local nova = ball(R * 0.7, {
		Name = "Supernova",
		Material = Enum.Material.Neon,
		Color = s.def.core,
		CFrame = CFrame.new(center),
	})
	nova.Parent = fxFolder
	local t = TweenService:Create(nova, TweenInfo.new(2.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = Vector3.new(R * 6, R * 6, R * 6),
		Transparency = 1,
	})
	t:Play()
	t.Completed:Connect(function()
		nova:Destroy()
	end)
	for i = 1, 5 do
		task.delay(i * 0.15, function()
			local e = Instance.new("Explosion")
			e.Position = center + Vector3.new(rng:NextNumber(-60, 60), rng:NextNumber(-60, 60), rng:NextNumber(-60, 60))
			e.BlastRadius = 80
			e.BlastPressure = 0
			e.DestroyJointRadiusPercent = 0
			e.ExplosionType = Enum.ExplosionType.NoCraters
			e.Parent = workspace
		end)
	end

	for _, child in ipairs(s.model:GetChildren()) do
		if child:IsA("BasePart") then
			if child.Name == "Core" then
				child:Destroy()
			elseif child.Name == "NameAnchor" then
				child:Destroy()
			else
				child.Parent = fxFolder
				flingAway(child, 700, 4)
			end
		end
	end
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
		"💥 Il " .. s.def.name .. " è stato DISTRUTTO!" .. (mvpName and (" MVP: " .. mvpName) or ""),
		Color3.fromRGB(255, 140, 60)
	)

	-- Loot rain on the Citadel.
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
function PlanetService:ApplyHit(player, damage, impactPoint, crit, color)
	if not state or state.destroyed then
		return 0
	end
	local dealt = math.min(damage, state.hp)
	state.hp -= dealt
	state.contributions[player.UserId] = (state.contributions[player.UserId] or 0) + dealt

	impactFX(impactPoint, damage, color, player.DisplayName)
	damageNumber(impactPoint, damage, crit, color)

	updateCrust(impactPoint)
	updateMantle()
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
		local old = state
		old.destroyed = true
		for _, child in ipairs(old.model:GetChildren()) do
			if child:IsA("BasePart") then
				child.Parent = fxFolder
				flingAway(child, 900, 3)
			end
		end
		old.model:Destroy()
	end
	spawnPlanet(Planets.Legendary)
end

function PlanetService:Init(s)
	services = s
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "PlanetFX"
	fxFolder.Parent = workspace
	destroyedRemote = Remotes.Get("PlanetDestroyed")
end

function PlanetService:Start()
	CENTER = services.WorldService.PlanetPosition -- may come from the custom map marker
	task.delay(2, function()
		spawnPlanet(Planets.Get(currentIndex))
	end)
end

return PlanetService
