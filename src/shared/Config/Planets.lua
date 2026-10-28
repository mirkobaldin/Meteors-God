-- Planet sequence. Adding a planet = adding one entry here.

local Planets = {}

Planets.Sequence = {
	{
		name = "Pianeta Roccioso",
		hp = 4000,
		reward = 400,
		crust = { color = Color3.fromRGB(130, 110, 95), material = Enum.Material.Slate },
		mantle = Color3.fromRGB(200, 90, 40),
		core = Color3.fromRGB(255, 220, 120),
	},
	{
		name = "Pianeta di Ghiaccio",
		hp = 9000,
		reward = 900,
		crust = { color = Color3.fromRGB(190, 230, 255), material = Enum.Material.Ice },
		mantle = Color3.fromRGB(70, 140, 220),
		core = Color3.fromRGB(200, 255, 255),
	},
	{
		name = "Pianeta di Lava",
		hp = 20000,
		reward = 2000,
		crust = { color = Color3.fromRGB(45, 30, 30), material = Enum.Material.Basalt },
		mantle = Color3.fromRGB(255, 80, 0),
		core = Color3.fromRGB(255, 240, 150),
	},
	{
		name = "Pianeta Caramella",
		hp = 45000,
		reward = 4500,
		crust = { color = Color3.fromRGB(255, 160, 210), material = Enum.Material.SmoothPlastic },
		mantle = Color3.fromRGB(140, 255, 220),
		core = Color3.fromRGB(255, 255, 255),
	},
	{
		name = "Pianeta Cristallo",
		hp = 100000,
		reward = 10000,
		crust = { color = Color3.fromRGB(170, 120, 255), material = Enum.Material.Glass },
		mantle = Color3.fromRGB(255, 120, 255),
		core = Color3.fromRGB(255, 255, 200),
	},
	{
		name = "Pianeta Ombra",
		hp = 220000,
		reward = 22000,
		crust = { color = Color3.fromRGB(30, 25, 45), material = Enum.Material.Slate },
		mantle = Color3.fromRGB(120, 0, 200),
		core = Color3.fromRGB(255, 80, 255),
	},
}

-- After the last planet the sequence loops with HP and rewards multiplied by this per loop.
Planets.LoopMultiplier = 2.5

Planets.Legendary = {
	name = "PIANETA LEGGENDARIO",
	hp = 60000,
	reward = 15000,
	crust = { color = Color3.fromRGB(255, 200, 50), material = Enum.Material.Foil },
	mantle = Color3.fromRGB(255, 255, 255),
	core = Color3.fromRGB(255, 120, 40),
	legendary = true,
}

-- Layer split of total HP (must sum to 1).
Planets.Layers = {
	{ id = "Crosta", share = 0.55 },
	{ id = "Mantello", share = 0.35 },
	{ id = "Nucleo", share = 0.10 },
}

Planets.CrustChunks = 42

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
