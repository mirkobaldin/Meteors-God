-- Divine evolutions. Visual keys are interpreted by the server EvolutionService.

local Evolutions = {}

Evolutions.List = {
	{
		name = "Spirito Stellare",
		power = 0,
		planets = 0,
		mult = 1,
		aura = Color3.fromRGB(230, 230, 255),
		scale = 1,
		visuals = {},
	},
	{
		name = "Divinità Minore",
		power = 500,
		planets = 1,
		mult = 1.5,
		aura = Color3.fromRGB(120, 200, 255),
		scale = 1,
		visuals = { "halo" },
	},
	{
		name = "Semidio",
		power = 5000,
		planets = 5,
		mult = 2.5,
		aura = Color3.fromRGB(120, 255, 170),
		scale = 1.1,
		visuals = { "halo", "wings" },
	},
	{
		name = "Titano",
		power = 50000,
		planets = 15,
		mult = 4,
		aura = Color3.fromRGB(255, 170, 60),
		scale = 1.2,
		visuals = { "crown", "wings" },
	},
	{
		name = "Dio Cosmico",
		power = 500000,
		planets = 40,
		mult = 7,
		aura = Color3.fromRGB(200, 100, 255),
		scale = 1.3,
		visuals = { "crown", "wings", "rings" },
	},
	{
		name = "Divinità Suprema",
		power = 5000000,
		planets = 100,
		mult = 12,
		aura = Color3.fromRGB(255, 80, 160),
		scale = 1.4,
		visuals = { "crown", "wings", "rings", "galaxy" },
	},
}

Evolutions.AscensionMinEvolution = 4

function Evolutions.Get(index)
	return Evolutions.List[math.clamp(index, 1, #Evolutions.List)]
end

function Evolutions.Max()
	return #Evolutions.List
end

return Evolutions
