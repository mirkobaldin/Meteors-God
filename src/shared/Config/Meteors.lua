-- Meteor types, rarities and mutations.
-- Adding a new meteor = adding one entry to Types (no models needed: visuals are generated).

local Meteors = {}

Meteors.Rarities = {
	{ id = "Comune", weight = 60, color = Color3.fromRGB(190, 190, 200), order = 1 },
	{ id = "Non comune", weight = 25, color = Color3.fromRGB(90, 220, 110), order = 2 },
	{ id = "Raro", weight = 10, color = Color3.fromRGB(70, 150, 255), order = 3 },
	{ id = "Epico", weight = 4, color = Color3.fromRGB(180, 90, 255), order = 4 },
	{ id = "Leggendario", weight = 0.9, color = Color3.fromRGB(255, 200, 40), order = 5 },
	{ id = "Mitico", weight = 0.1, color = Color3.fromRGB(255, 60, 140), order = 6 },
}

-- face.eyes: "normal" | "cyclops"
-- face.extra: nil | "crown" | "sunglasses" | "horns"
Meteors.Types = {
	{
		id = "Sassolino",
		rarity = "Comune",
		body = Color3.fromRGB(120, 110, 105),
		fire = { Color3.fromRGB(255, 140, 40), Color3.fromRGB(255, 60, 20) },
		face = { eyes = "normal" },
		baseDamage = 40,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 10,
	},
	{
		id = "Brace",
		rarity = "Comune",
		body = Color3.fromRGB(200, 70, 40),
		fire = { Color3.fromRGB(255, 120, 30), Color3.fromRGB(200, 30, 10) },
		face = { eyes = "normal" },
		baseDamage = 45,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 12,
	},
	{
		id = "Gelo",
		rarity = "Non comune",
		body = Color3.fromRGB(150, 220, 255),
		fire = { Color3.fromRGB(180, 240, 255), Color3.fromRGB(60, 140, 255) },
		face = { eyes = "normal" },
		baseDamage = 70,
		growTime = 240,
		powerBonus = 0.1,
		sellPrice = 30,
	},
	{
		id = "Scintilla",
		rarity = "Non comune",
		body = Color3.fromRGB(255, 230, 80),
		fire = { Color3.fromRGB(255, 255, 150), Color3.fromRGB(255, 200, 0) },
		face = { eyes = "normal" },
		baseDamage = 75,
		growTime = 240,
		powerBonus = 0.1,
		sellPrice = 32,
	},
	{
		id = "Veleno",
		rarity = "Raro",
		body = Color3.fromRGB(110, 220, 60),
		fire = { Color3.fromRGB(180, 255, 80), Color3.fromRGB(40, 160, 20) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 120,
		growTime = 480,
		powerBonus = 0.2,
		sellPrice = 90,
	},
	{
		id = "Cristallo",
		rarity = "Raro",
		body = Color3.fromRGB(255, 140, 230),
		fire = { Color3.fromRGB(255, 200, 255), Color3.fromRGB(200, 80, 255) },
		face = { eyes = "normal" },
		baseDamage = 130,
		growTime = 480,
		powerBonus = 0.2,
		sellPrice = 95,
	},
	{
		id = "Magma",
		rarity = "Epico",
		body = Color3.fromRGB(90, 20, 15),
		fire = { Color3.fromRGB(255, 90, 0), Color3.fromRGB(150, 0, 0) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 220,
		growTime = 900,
		powerBonus = 0.4,
		sellPrice = 300,
	},
	{
		id = "Aurora",
		rarity = "Epico",
		body = Color3.fromRGB(60, 230, 200),
		fire = { Color3.fromRGB(120, 255, 200), Color3.fromRGB(140, 80, 255) },
		face = { eyes = "normal" },
		baseDamage = 240,
		growTime = 900,
		powerBonus = 0.4,
		sellPrice = 320,
	},
	{
		id = "Solare",
		rarity = "Leggendario",
		body = Color3.fromRGB(255, 190, 40),
		fire = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 120, 0) },
		face = { eyes = "normal", extra = "crown" },
		baseDamage = 450,
		growTime = 1800,
		powerBonus = 0.8,
		sellPrice = 1200,
	},
	{
		id = "Cometa Regale",
		rarity = "Leggendario",
		body = Color3.fromRGB(220, 240, 255),
		fire = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(80, 160, 255) },
		face = { eyes = "normal", extra = "crown" },
		baseDamage = 500,
		growTime = 1800,
		powerBonus = 0.8,
		sellPrice = 1300,
	},
	{
		id = "Vuoto",
		rarity = "Mitico",
		body = Color3.fromRGB(20, 10, 35),
		fire = { Color3.fromRGB(170, 80, 255), Color3.fromRGB(30, 0, 60) },
		face = { eyes = "cyclops" },
		baseDamage = 1000,
		growTime = 3600,
		powerBonus = 1.6,
		sellPrice = 6000,
	},
	{
		id = "Supernova",
		rarity = "Mitico",
		body = Color3.fromRGB(255, 255, 240),
		fire = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 80, 200) },
		face = { eyes = "normal", extra = "sunglasses" },
		baseDamage = 1100,
		growTime = 3600,
		powerBonus = 1.6,
		sellPrice = 6500,
	},
	{
		id = "Cometa Blu",
		rarity = "Epico",
		body = Color3.fromRGB(40, 90, 255),
		fire = { Color3.fromRGB(120, 200, 255), Color3.fromRGB(20, 40, 200) },
		face = { eyes = "normal", extra = "sunglasses" },
		baseDamage = 260,
		growTime = 900,
		powerBonus = 0.45,
		sellPrice = 0,
		exclusive = true, -- never drops from showers (Starter Pack only)
	},
}

-- Rolled once per fallen meteor. Checked in order, first success wins.
Meteors.Mutations = {
	{ id = "Eclissato", chance = 0.002, mult = 5, color = Color3.fromRGB(120, 40, 200) },
	{ id = "Arcobaleno", chance = 0.008, mult = 3, color = Color3.fromRGB(255, 120, 200) },
	{ id = "Dorato", chance = 0.04, mult = 2, color = Color3.fromRGB(255, 210, 60) },
}

Meteors.ByID = {}
for _, def in ipairs(Meteors.Types) do
	Meteors.ByID[def.id] = def
end

Meteors.RarityByID = {}
for _, r in ipairs(Meteors.Rarities) do
	Meteors.RarityByID[r.id] = r
end

Meteors.MutationByID = {}
for _, m in ipairs(Meteors.Mutations) do
	Meteors.MutationByID[m.id] = m
end

function Meteors.GetMutationMult(mutationId)
	local m = mutationId and Meteors.MutationByID[mutationId]
	return m and m.mult or 1
end

-- Rolls a rarity, optionally shifting weight towards rarer tiers (luck >= 1).
function Meteors.RollRarity(rng, luck)
	luck = luck or 1
	local total = 0
	local weights = {}
	for i, r in ipairs(Meteors.Rarities) do
		local w = r.weight
		if r.order >= 3 then
			w *= luck
		end
		weights[i] = w
		total += w
	end
	local roll = rng:NextNumber() * total
	for i, r in ipairs(Meteors.Rarities) do
		roll -= weights[i]
		if roll <= 0 then
			return r.id
		end
	end
	return Meteors.Rarities[1].id
end

function Meteors.RandomTypeOfRarity(rng, rarityId)
	local pool = {}
	for _, def in ipairs(Meteors.Types) do
		if def.rarity == rarityId and not def.exclusive then
			table.insert(pool, def.id)
		end
	end
	if #pool == 0 then
		return Meteors.Types[1].id
	end
	return pool[rng:NextInteger(1, #pool)]
end

function Meteors.NextRarity(rarityId)
	local r = Meteors.RarityByID[rarityId]
	if not r then
		return nil
	end
	for _, other in ipairs(Meteors.Rarities) do
		if other.order == r.order + 1 then
			return other.id
		end
	end
	return nil
end

function Meteors.RollMutation(rng, mult)
	mult = mult or 1
	for _, m in ipairs(Meteors.Mutations) do
		if rng:NextNumber() < m.chance * mult then
			return m.id
		end
	end
	return nil
end

-- Number of non-exclusive meteor types (for the collection index).
function Meteors.IndexSize()
	local n = 0
	for _, def in ipairs(Meteors.Types) do
		if not def.exclusive then
			n += 1
		end
	end
	return n
end

return Meteors
