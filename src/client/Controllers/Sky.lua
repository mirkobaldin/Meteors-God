-- Space backdrop around the map: distant planets with rings, a spiral galaxy, glowing nebulae
-- and an optional custom skybox (Config/Assets.Sky). Built locally on each client (nothing to
-- replicate) far beyond the play area, so it never gets in the way of meteors or planets.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Game = require(Shared.Config.Game)

local Sky = {}

local folder
local rng = Random.new(42)
local spinning = {} -- { {part, axis speed} }

local function ball(pos, size, props)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = Vector3.new(size, size, size)
	p.CFrame = CFrame.new(pos)
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = folder
	return p
end

local function ring(center, outer, tilt, color)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = Vector3.new(2, outer * 2, outer * 2)
	p.CFrame = CFrame.new(center) * tilt * CFrame.Angles(0, 0, math.rad(90))
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.6
	p.Parent = folder
	return p
end

-- Direction from the map center, avoiding the cone towards the target planet (+Z).
local function skyPoint(distance, minAngleFromPlanet)
	while true do
		local dir = rng:NextUnitVector()
		dir = Vector3.new(dir.X, dir.Y * 0.6, dir.Z).Unit
		local angle = math.deg(math.acos(math.clamp(dir.Z, -1, 1)))
		if angle > minAngleFromPlanet then
			return dir * distance
		end
	end
end

local PLANETS = {
	{ size = 900, material = Enum.Material.Sand, color = Color3.fromRGB(220, 150, 90), atmo = Color3.fromRGB(255, 170, 110), ring = Color3.fromRGB(255, 210, 160) },
	{ size = 520, material = Enum.Material.Glacier, color = Color3.fromRGB(120, 180, 255), atmo = Color3.fromRGB(110, 200, 255) },
	{ size = 380, material = Enum.Material.CrackedLava, color = Color3.fromRGB(200, 60, 40), atmo = Color3.fromRGB(255, 100, 60) },
	{ size = 650, material = Enum.Material.Slate, color = Color3.fromRGB(150, 90, 200), atmo = Color3.fromRGB(200, 120, 255), ring = Color3.fromRGB(140, 220, 255) },
	{ size = 240, material = Enum.Material.Rock, color = Color3.fromRGB(190, 190, 205), atmo = Color3.fromRGB(220, 220, 255) },
	{ size = 300, material = Enum.Material.Grass, color = Color3.fromRGB(60, 170, 140), atmo = Color3.fromRGB(120, 255, 200) },
}

local function buildPlanets(cfg)
	for _, def in ipairs(PLANETS) do
		local pos = skyPoint(cfg.PlanetDistance * rng:NextNumber(0.85, 1.15), 35)
		local p = ball(pos, def.size, { Material = def.material, Color = def.color })
		ball(pos, def.size * 1.06, { Material = Enum.Material.ForceField, Color = def.atmo, Transparency = 0.2 })
		if def.ring then
			local tilt = CFrame.Angles(math.rad(rng:NextNumber(-30, 30)), 0, math.rad(rng:NextNumber(-25, 25)))
			ring(pos, def.size * 1.15, tilt, def.ring)
		end
		table.insert(spinning, { part = p, speed = rng:NextNumber(0.01, 0.03) })
	end
end

-- Soft glowing cloud: many overlapping, very transparent neon balls.
local function buildNebula(center, size, colors)
	for _ = 1, 26 do
		local offset = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 0.4), rng:NextNumber(-1, 1)) * size
		local color = colors[rng:NextInteger(1, #colors)]:Lerp(colors[rng:NextInteger(1, #colors)], rng:NextNumber())
		ball(center + offset, size * rng:NextNumber(0.4, 1.0), {
			Material = Enum.Material.Neon,
			Color = color,
			Transparency = rng:NextNumber(0.93, 0.975),
		})
	end
end

-- Spiral galaxy: a bright core and two arms of glowing dots, tilted towards the map.
local function buildGalaxy(center, size)
	local tilt = CFrame.lookAt(center, Vector3.zero) * CFrame.Angles(math.rad(65), 0, 0)
	ball(center, size * 0.12, { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 235, 200), Transparency = 0.2 })
	ball(center, size * 0.3, { Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 180, 230), Transparency = 0.9 })
	for arm = 0, 1 do
		for i = 1, 70 do
			local t = i / 70
			local angle = arm * math.pi + t * math.pi * 3
			local r = size * 0.5 * t
			local local_ = Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
				+ Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.2, 0.2), rng:NextNumber(-1, 1)) * size * 0.04
			local color = Color3.fromRGB(150, 200, 255):Lerp(Color3.fromRGB(255, 120, 220), t)
			ball((tilt * CFrame.new(local_)).Position, size * rng:NextNumber(0.015, 0.04) * (1.4 - t), {
				Material = Enum.Material.Neon,
				Color = color,
				Transparency = 0.25 + t * 0.5,
			})
		end
	end
end

local function applySkybox()
	local ids = Assets.Sky
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky or not ids or not ids.Front or ids.Front == 0 then
		return
	end
	sky.SkyboxFt = Assets.Image(ids.Front)
	sky.SkyboxBk = Assets.Image(ids.Back)
	sky.SkyboxLf = Assets.Image(ids.Left)
	sky.SkyboxRt = Assets.Image(ids.Right)
	sky.SkyboxUp = Assets.Image(ids.Up)
	sky.SkyboxDn = Assets.Image(ids.Down)
end

function Sky:Init()
	local cfg = Game.Sky
	folder = Instance.new("Folder")
	folder.Name = "SkyBackdrop"
	folder.Parent = workspace

	buildPlanets(cfg)
	-- Big nebula behind the target planet, framing it, plus two more around the map.
	local planetDir = Game.World.PlanetPosition.Unit
	buildNebula(planetDir * cfg.NebulaDistance + Vector3.new(0, 600, 0), 1400,
		{ Color3.fromRGB(255, 70, 180), Color3.fromRGB(120, 60, 255), Color3.fromRGB(60, 200, 255) })
	buildNebula(skyPoint(cfg.NebulaDistance, 60), 1200,
		{ Color3.fromRGB(60, 220, 200), Color3.fromRGB(80, 100, 255) })
	buildNebula(skyPoint(cfg.NebulaDistance, 60), 1000,
		{ Color3.fromRGB(255, 140, 60), Color3.fromRGB(255, 60, 120) })
	buildGalaxy(skyPoint(cfg.GalaxyDistance, 50), 2400)

	task.defer(applySkybox) -- the server creates the Sky object
end

function Sky:Start()
	RunService.Heartbeat:Connect(function(dt)
		for _, s in ipairs(spinning) do
			s.part.CFrame *= CFrame.Angles(0, s.speed * dt, 0)
		end
	end)
	Lighting.ChildAdded:Connect(function(child)
		if child:IsA("Sky") then
			applySkybox()
		end
	end)
end

return Sky
