-- Meteor types, rarities and mutations.
-- Adding a new meteor = adding one entry to Types (no models needed: visuals are generated).

local Meteors = {}

Meteors.Rarities = {
	{ id = "Common", weight = 60, color = Color3.fromRGB(190, 190, 200), order = 1 },
	{ id = "Uncommon", weight = 25, color = Color3.fromRGB(90, 220, 110), order = 2 },
	{ id = "Rare", weight = 10, color = Color3.fromRGB(70, 150, 255), order = 3 },
	{ id = "Epic", weight = 4, color = Color3.fromRGB(180, 90, 255), order = 4 },
	{ id = "Legendary", weight = 0.9, color = Color3.fromRGB(255, 200, 40), order = 5 },
	{ id = "Mythic", weight = 0.1, color = Color3.fromRGB(255, 60, 140), order = 6 },
}

-- impact: crater effect and the mark left on the planet
--   rock | magma | frost | spark | venom | crystal | aurora | solar | void | nova
-- ability: special power when thrown
--   damage (+x damage) | burn (+x damage over 3s) | mark (planet takes +x from everyone, 8s)
--   chain (second strike +x) | critBoost (+x crit multiplier) | shards (+x shards) | recharge (-x recharge)
-- face.eyes: "normal" (every meteor has two eyes)
-- Optional, for the Blender meshes (Assets/Meteors/<id>):
--   rockMaterial = Enum.Material.Basalt  -- material of the rock shell and jaw (e.g. Basalt, Slate, Rock,
--                                          Granite, Marble, Glacier, CrackedLava, Foil); nil = only the texture
--   glowColor = Color3.fromRGB(...)      -- color of the glowing core seen through cracks, eyes and mouth
--                                          (nil = fire[1])
-- face.extra: nil | "crest" | "fins" | "horns" (rock features of the body, never accessories)
Meteors.Types = {
	{
		id = "Pebble",
		ability = { kind = "damage", value = 0.1, name = "Rock Solid", desc = "+10% damage" },
		impact = "rock",
		rarity = "Common",
		body = Color3.fromRGB(120, 110, 105),
		fire = { Color3.fromRGB(255, 140, 40), Color3.fromRGB(255, 60, 20) },
		face = { eyes = "normal" },
		baseDamage = 40,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 10,
	},
	{
		id = "Ember",
		ability = { kind = "burn", value = 0.25, name = "Burn", desc = "Burns the planet: +25% damage over 3s" },
		impact = "magma",
		rarity = "Common",
		body = Color3.fromRGB(200, 70, 40),
		fire = { Color3.fromRGB(255, 120, 30), Color3.fromRGB(200, 30, 10) },
		face = { eyes = "normal" },
		baseDamage = 45,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 12,
	},
	{
		id = "Frost",
		ability = { kind = "mark", value = 0.15, name = "Deep Freeze", desc = "The planet takes +15% damage from everyone for 8s" },
		impact = "frost",
		rarity = "Uncommon",
		body = Color3.fromRGB(150, 220, 255),
		fire = { Color3.fromRGB(180, 240, 255), Color3.fromRGB(60, 140, 255) },
		face = { eyes = "normal" },
		baseDamage = 70,
		growTime = 240,
		powerBonus = 0.1,
		sellPrice = 30,
	},
	{
		id = "Spark",
		ability = { kind = "chain", value = 0.3, name = "Chain Lightning", desc = "A second strike for +30% damage" },
		impact = "spark",
		rarity = "Uncommon",
		body = Color3.fromRGB(255, 230, 80),
		fire = { Color3.fromRGB(255, 255, 150), Color3.fromRGB(255, 200, 0) },
		face = { eyes = "normal" },
		baseDamage = 75,
		growTime = 240,
		powerBonus = 0.1,
		sellPrice = 32,
	},
	{
		id = "Venom",
		ability = { kind = "burn", value = 0.45, name = "Poison", desc = "Poisons the planet: +45% damage over 3s" },
		impact = "venom",
		rarity = "Rare",
		body = Color3.fromRGB(110, 220, 60),
		fire = { Color3.fromRGB(180, 255, 80), Color3.fromRGB(40, 160, 20) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 120,
		growTime = 480,
		powerBonus = 0.2,
		sellPrice = 90,
	},
	{
		id = "Crystal",
		ability = { kind = "critBoost", value = 0.6, name = "Shatter", desc = "Critical hits deal +60% more" },
		impact = "crystal",
		rarity = "Rare",
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
		ability = { kind = "burn", value = 0.5, name = "Eruption", desc = "Lava burns the planet: +50% damage over 3s" },
		impact = "magma",
		rarity = "Epic",
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
		ability = { kind = "shards", value = 0.6, name = "Aurora Blessing", desc = "+60% Shards from its hits" },
		impact = "aurora",
		rarity = "Epic",
		body = Color3.fromRGB(60, 230, 200),
		fire = { Color3.fromRGB(120, 255, 200), Color3.fromRGB(140, 80, 255) },
		face = { eyes = "normal" },
		baseDamage = 240,
		growTime = 900,
		powerBonus = 0.4,
		sellPrice = 320,
	},
	{
		id = "Solar",
		ability = { kind = "mark", value = 0.25, name = "Solar Flare", desc = "The planet takes +25% damage from everyone for 8s" },
		impact = "solar",
		rarity = "Legendary",
		body = Color3.fromRGB(255, 190, 40),
		fire = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 120, 0) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 450,
		growTime = 1800,
		powerBonus = 0.8,
		sellPrice = 1200,
	},
	{
		id = "Royal Comet",
		ability = { kind = "shards", value = 1, name = "Royal Tribute", desc = "x2 Shards from its hits" },
		impact = "frost",
		rarity = "Legendary",
		body = Color3.fromRGB(220, 240, 255),
		fire = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(80, 160, 255) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 500,
		growTime = 1800,
		powerBonus = 0.8,
		sellPrice = 1300,
	},
	{
		id = "Void",
		ability = { kind = "damage", value = 0.6, name = "Void Rift", desc = "+60% damage" },
		impact = "void",
		rarity = "Mythic",
		body = Color3.fromRGB(20, 10, 35),
		fire = { Color3.fromRGB(170, 80, 255), Color3.fromRGB(30, 0, 60) },
		face = { eyes = "normal" },
		baseDamage = 1000,
		growTime = 3600,
		powerBonus = 1.6,
		sellPrice = 6000,
	},
	{
		id = "Supernova",
		ability = { kind = "chain", value = 0.7, name = "Nova Blast", desc = "A second blast for +70% damage" },
		impact = "nova",
		rarity = "Mythic",
		body = Color3.fromRGB(255, 255, 240),
		fire = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 80, 200) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 1100,
		growTime = 3600,
		powerBonus = 1.6,
		sellPrice = 6500,
	},
	{
		id = "Blue Comet",
		ability = { kind = "recharge", value = 0.5, name = "Hyperspeed", desc = "Recharges twice as fast" },
		impact = "frost",
		rarity = "Epic",
		body = Color3.fromRGB(40, 90, 255),
		fire = { Color3.fromRGB(120, 200, 255), Color3.fromRGB(20, 40, 200) },
		face = { eyes = "normal", extra = "fins" },
		baseDamage = 260,
		growTime = 900,
		powerBonus = 0.45,
		sellPrice = 0,
		exclusive = true, -- never drops from showers (Starter Pack only)
	},
}

-- Rolled once per fallen meteor. Checked in order, first success wins.
Meteors.Mutations = {
	{ id = "Eclipsed", chance = 0.002, mult = 5, color = Color3.fromRGB(120, 40, 200) },
	{ id = "Rainbow", chance = 0.008, mult = 3, color = Color3.fromRGB(255, 120, 200) },
	{ id = "Golden", chance = 0.04, mult = 2, color = Color3.fromRGB(255, 210, 60) },
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
