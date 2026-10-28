-- Planets are made of Roblox Terrain: a crust of the planet's materials with surface features
-- (volcanoes, ice spikes, crystals...), a glowing CrackedLava mantle and a neon core floating in
-- a cavity in the middle. Every hit carves a real crater, so the damage stays visible.
-- Material colors are in Config/Terrain.lua.
--
-- Three TIERS = three lanes of the Bifrost = three planets in the sky at the same time.
-- Adding a planet = adding one entry to Planets.Defs and its name to a tier's sequence.

local Planets = {}

--[[
	crust.material   main material
	crust.patches    { {material, count, size} } bumps of other materials (continents, hills); size = fraction of R
	crust.poles      material of the polar caps (optional)
	features         { {kind, count, material?, scale?} }  kind = "volcano" | "spikes" | "mountains" | "craters"
	bands            materials of stripes around the planet (optional)
	ring             { color, material, inner, outer (x R), tilt (degrees) } planetary ring (optional)
	moons            number of small moons (optional)
	core             core color (neon ball in the cavity)
	atmosphere       glow around the planet
]]
Planets.Defs = {
	["Rocky Planet"] = {
		hp = 4000,
		reward = 400,
		crust = {
			material = Enum.Material.Ground,
			patches = { { Enum.Material.Cobblestone, 10, 0.22 }, { Enum.Material.Rock, 6, 0.15 } },
			poles = Enum.Material.Snow,
		},
		features = { { kind = "mountains", count = 9, material = Enum.Material.Rock }, { kind = "craters", count = 10 } },
		ring = { color = Color3.fromRGB(190, 150, 110), material = Enum.Material.Slate, inner = 1.45, outer = 1.9, tilt = 18 },
		moons = 1,
		core = Color3.fromRGB(255, 200, 90),
		atmosphere = Color3.fromRGB(255, 190, 130),
	},
	["Ice Planet"] = {
		hp = 9000,
		reward = 900,
		crust = {
			material = Enum.Material.Ice,
			patches = { { Enum.Material.Snow, 12, 0.2 } },
			poles = Enum.Material.Snow,
		},
		features = { { kind = "spikes", count = 34, material = Enum.Material.Glacier, scale = 1.6 } },
		moons = 2,
		core = Color3.fromRGB(160, 240, 255),
		atmosphere = Color3.fromRGB(150, 220, 255),
	},
	["Candy Planet"] = {
		hp = 20000,
		reward = 2000,
		crust = {
			material = Enum.Material.Sand,
			patches = { { Enum.Material.Limestone, 10, 0.2 }, { Enum.Material.Pavement, 10, 0.16 } },
		},
		features = { { kind = "mountains", count = 8, material = Enum.Material.Limestone } },
		bands = { Enum.Material.Limestone, Enum.Material.Pavement, Enum.Material.Limestone, Enum.Material.Pavement },
		ring = { color = Color3.fromRGB(255, 150, 210), material = Enum.Material.SmoothPlastic, inner = 1.4, outer = 1.75, tilt = -24 },
		core = Color3.fromRGB(255, 255, 255),
		atmosphere = Color3.fromRGB(255, 170, 220),
	},
	["Lava Planet"] = {
		hp = 60000,
		reward = 6000,
		crust = {
			material = Enum.Material.Basalt,
			patches = { { Enum.Material.CrackedLava, 10, 0.14 } },
		},
		features = { { kind = "volcano", count = 9, material = Enum.Material.Basalt, scale = 1.4 } },
		core = Color3.fromRGB(255, 240, 150),
		atmosphere = Color3.fromRGB(255, 110, 50),
	},
	["Crystal Planet"] = {
		hp = 120000,
		reward = 12000,
		crust = {
			material = Enum.Material.Salt,
			patches = { { Enum.Material.Glacier, 6, 0.12 } },
		},
		features = { { kind = "spikes", count = 30, material = Enum.Material.Salt, scale = 2 }, { kind = "spikes", count = 10, material = Enum.Material.Glacier, scale = 1.5 } },
		ring = { color = Color3.fromRGB(230, 150, 255), material = Enum.Material.Glass, inner = 1.5, outer = 2.1, tilt = 30 },
		core = Color3.fromRGB(255, 120, 255),
		atmosphere = Color3.fromRGB(220, 130, 255),
	},
	["Shadow Planet"] = {
		hp = 400000,
		reward = 40000,
		crust = {
			material = Enum.Material.Asphalt,
			patches = { { Enum.Material.Slate, 10, 0.2 } },
		},
		features = { { kind = "spikes", count = 24, material = Enum.Material.Slate, scale = 1.3 }, { kind = "craters", count = 14 } },
		ring = { color = Color3.fromRGB(90, 40, 140), material = Enum.Material.Slate, inner = 1.35, outer = 1.8, tilt = -12 },
		moons = 3,
		core = Color3.fromRGB(190, 70, 255),
		atmosphere = Color3.fromRGB(140, 60, 220),
	},
	["LEGENDARY PLANET"] = {
		hp = 60000,
		reward = 15000,
		crust = {
			material = Enum.Material.Sandstone,
			patches = { { Enum.Material.Pavement, 8, 0.18 } },
		},
		features = { { kind = "spikes", count = 18, material = Enum.Material.Glacier } },
		ring = { color = Color3.fromRGB(255, 210, 80), material = Enum.Material.Foil, inner = 1.4, outer = 2, tilt = 20 },
		core = Color3.fromRGB(255, 140, 40),
		atmosphere = Color3.fromRGB(255, 210, 90),
		legendary = true,
	},
}

Planets.Tiers = {
	{
		name = "Tier I",
		color = Color3.fromRGB(120, 220, 255),
		requiredEvolution = 1,
		laneAngle = -50, -- degrees from +Z of this tier's bridge
		position = Vector3.new(-2451, 450, 2057),
		radius = 520,
		sequence = { "Rocky Planet", "Ice Planet", "Candy Planet" },
	},
	{
		name = "Tier II",
		color = Color3.fromRGB(255, 150, 60),
		requiredEvolution = 3, -- Demigod
		laneAngle = 0,
		position = Vector3.new(0, 500, 3200),
		radius = 600,
		sequence = { "Lava Planet", "Crystal Planet" },
	},
	{
		name = "Tier III",
		color = Color3.fromRGB(200, 110, 255),
		requiredEvolution = 5, -- Cosmic God
		laneAngle = 50,
		position = Vector3.new(2451, 450, 2057),
		radius = 680,
		sequence = { "Shadow Planet" },
	},
}

-- The Legendary planet (Developer Product) replaces the planet of this tier.
Planets.LegendaryTier = 1

-- After the last planet of a tier the sequence loops with HP and rewards multiplied by this per loop.
Planets.LoopMultiplier = 2.5

-- Layers by HP lost (used for names and announcements; the geometry is the real terrain).
Planets.Layers = {
	{ id = "Crust", share = 0.55 },
	{ id = "Mantle", share = 0.35 },
	{ id = "Core", share = 0.10 },
}
Planets.MantleRadius = 0.62 -- fraction of the radius where the CrackedLava mantle starts
Planets.CavityRadius = 0.4 -- hollow center
Planets.CoreRadius = 0.28 -- neon core floating in the cavity

-- Crater size: radius = R * clamp((share * CraterScale)^(1/3), CraterMin, CraterMax)
-- where share = damage / planet max HP. The sum of the craters roughly empties the planet.
Planets.CraterScale = 1.3
Planets.CraterMin = 0.05
Planets.CraterMax = 0.16

-- Planets grow with their HP: radius = tier radius * clamp((hp / first planet hp)^GrowthExponent, 1, MaxGrowth).
Planets.GrowthExponent = 0.12
Planets.MaxGrowth = 1.45

function Planets.RadiusFor(tierIndex, hp)
	local tier = Planets.Tiers[tierIndex]
	local firstHP = Planets.Defs[tier.sequence[1]].hp
	return tier.radius * math.clamp((hp / firstHP) ^ Planets.GrowthExponent, 1, Planets.MaxGrowth)
end

function Planets.Get(tierIndex, index)
	local tier = Planets.Tiers[tierIndex]
	local n = #tier.sequence
	local loop = math.floor((index - 1) / n)
	local name = tier.sequence[((index - 1) % n) + 1]
	local base = Planets.Defs[name]
	local mult = Planets.LoopMultiplier ^ loop
	local def = table.clone(base)
	def.name = loop > 0 and (name .. " +" .. loop) or name
	def.hp = math.floor(base.hp * mult)
	def.reward = math.floor(base.reward * mult)
	return def
end

function Planets.Legendary()
	local def = table.clone(Planets.Defs["LEGENDARY PLANET"])
	def.name = "LEGENDARY PLANET"
	return def
end

return Planets
