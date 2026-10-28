-- Planet sequence. Adding a planet = adding one entry here.
--
-- The crust is an icosphere of tectonic plates. Each plate gets a color from `crust.colors`
-- chosen by noise (low -> high). Plates where the noise passes `accent.threshold` use the accent
-- (lava rivers, glowing veins...). `poles` tints plates near the poles (ice caps).

local Planets = {}

Planets.Sequence = {
	{
		name = "Rocky Planet",
		hp = 4000,
		reward = 400,
		crust = {
			material = Enum.Material.Slate,
			colors = {
				Color3.fromRGB(120, 80, 55),
				Color3.fromRGB(165, 115, 70),
				Color3.fromRGB(200, 155, 100),
				Color3.fromRGB(140, 130, 120),
			},
			poles = Color3.fromRGB(225, 215, 200),
		},
		mantle = Color3.fromRGB(255, 110, 40),
		core = Color3.fromRGB(255, 230, 140),
		atmosphere = Color3.fromRGB(255, 190, 130),
	},
	{
		name = "Ice Planet",
		hp = 9000,
		reward = 900,
		crust = {
			material = Enum.Material.Glacier,
			colors = {
				Color3.fromRGB(120, 170, 220),
				Color3.fromRGB(180, 220, 245),
				Color3.fromRGB(230, 245, 255),
				Color3.fromRGB(250, 252, 255),
			},
			accent = { color = Color3.fromRGB(60, 140, 255), material = Enum.Material.Neon, threshold = 0.8 },
		},
		mantle = Color3.fromRGB(80, 170, 255),
		core = Color3.fromRGB(210, 255, 255),
		atmosphere = Color3.fromRGB(150, 220, 255),
	},
	{
		name = "Lava Planet",
		hp = 20000,
		reward = 2000,
		crust = {
			material = Enum.Material.Basalt,
			colors = {
				Color3.fromRGB(25, 20, 20),
				Color3.fromRGB(45, 32, 30),
				Color3.fromRGB(65, 45, 38),
			},
			accent = { color = Color3.fromRGB(255, 110, 20), material = Enum.Material.Neon, threshold = 0.62 },
		},
		mantle = Color3.fromRGB(255, 80, 0),
		core = Color3.fromRGB(255, 240, 150),
		atmosphere = Color3.fromRGB(255, 110, 50),
	},
	{
		name = "Candy Planet",
		hp = 45000,
		reward = 4500,
		crust = {
			material = Enum.Material.SmoothPlastic,
			colors = {
				Color3.fromRGB(255, 150, 200),
				Color3.fromRGB(255, 200, 225),
				Color3.fromRGB(150, 240, 210),
				Color3.fromRGB(255, 240, 170),
			},
			poles = Color3.fromRGB(255, 255, 255),
		},
		mantle = Color3.fromRGB(140, 255, 220),
		core = Color3.fromRGB(255, 255, 255),
		atmosphere = Color3.fromRGB(255, 170, 220),
	},
	{
		name = "Crystal Planet",
		hp = 100000,
		reward = 10000,
		crust = {
			material = Enum.Material.Glass,
			colors = {
				Color3.fromRGB(90, 50, 160),
				Color3.fromRGB(140, 90, 230),
				Color3.fromRGB(200, 150, 255),
			},
			accent = { color = Color3.fromRGB(255, 120, 255), material = Enum.Material.Neon, threshold = 0.72 },
		},
		mantle = Color3.fromRGB(255, 120, 255),
		core = Color3.fromRGB(255, 255, 210),
		atmosphere = Color3.fromRGB(220, 130, 255),
	},
	{
		name = "Shadow Planet",
		hp = 220000,
		reward = 22000,
		crust = {
			material = Enum.Material.Slate,
			colors = {
				Color3.fromRGB(14, 12, 22),
				Color3.fromRGB(28, 24, 40),
				Color3.fromRGB(45, 38, 60),
			},
			accent = { color = Color3.fromRGB(160, 60, 255), material = Enum.Material.Neon, threshold = 0.68 },
		},
		mantle = Color3.fromRGB(130, 0, 220),
		core = Color3.fromRGB(255, 90, 255),
		atmosphere = Color3.fromRGB(140, 60, 220),
	},
}

-- After the last planet the sequence loops with HP and rewards multiplied by this per loop.
Planets.LoopMultiplier = 2.5

Planets.Legendary = {
	name = "LEGENDARY PLANET",
	hp = 60000,
	reward = 15000,
	crust = {
		material = Enum.Material.Foil,
		colors = {
			Color3.fromRGB(200, 140, 30),
			Color3.fromRGB(255, 190, 50),
			Color3.fromRGB(255, 225, 120),
		},
		accent = { color = Color3.fromRGB(255, 255, 230), material = Enum.Material.Neon, threshold = 0.75 },
	},
	mantle = Color3.fromRGB(255, 255, 255),
	core = Color3.fromRGB(255, 140, 40),
	atmosphere = Color3.fromRGB(255, 210, 90),
	ring = Color3.fromRGB(255, 220, 90),
	legendary = true,
}

-- Layer split of total HP (must sum to 1).
Planets.Layers = {
	{ id = "Crust", share = 0.55 },
	{ id = "Mantle", share = 0.35 },
	{ id = "Core", share = 0.10 },
}

-- Icosphere subdivisions for the crust: 2 = 320 plates (640 parts). 3 would be 1280 plates.
Planets.CrustSubdivisions = 2
Planets.CrustThickness = 0.09 -- fraction of the radius
Planets.MantleRadius = 0.9 -- fraction of the radius
Planets.CoreRadius = 0.38 -- fraction of the radius

function Planets.Get(index)
	local n = #Planets.Sequence
	local loop = math.floor((index - 1) / n)
	local base = Planets.Sequence[((index - 1) % n) + 1]
	local mult = Planets.LoopMultiplier ^ loop
	local def = table.clone(base)
	def.hp = math.floor(base.hp * mult)
	def.reward = math.floor(base.reward * mult)
	if loop > 0 then
		def.name = base.name .. " +" .. loop
	end
	return def
end

return Planets
