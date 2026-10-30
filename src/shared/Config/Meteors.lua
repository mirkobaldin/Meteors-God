-- Meteor types, rarities and mutations.
-- Adding a new meteor = adding one entry to Types (no models needed: visuals are generated).

local Meteors = {}

-- 5 rarities with 5 meteors each, plus 2 Extraterrestrial meteors (the rarest).
Meteors.Rarities = {
	{ id = "Common", weight = 62, color = Color3.fromRGB(190, 190, 200), order = 1 },
	{ id = "Rare", weight = 26, color = Color3.fromRGB(70, 150, 255), order = 2 },
	{ id = "Epic", weight = 9, color = Color3.fromRGB(180, 90, 255), order = 3 },
	{ id = "Legendary", weight = 2.5, color = Color3.fromRGB(255, 200, 40), order = 4 },
	{ id = "Mythic", weight = 0.45, color = Color3.fromRGB(255, 60, 140), order = 5 },
	{ id = "Extraterrestrial", weight = 0.05, color = Color3.fromRGB(90, 255, 140), order = 6 },
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
-- look: what the meteor looks like (used by the concept-art prompts in docs/)
Meteors.Types = {
	{
		id = "Pebble",
		ability = { kind = "damage", value = 0.1, name = "Rock Solid", desc = "+10% damage" },
		impact = "rock",
		rarity = "Common",
		body = Color3.fromRGB(120, 110, 105),
		fire = { Color3.fromRGB(255, 140, 40), Color3.fromRGB(255, 60, 20) },
		face = { eyes = "normal" },
		baseDamage = 44,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 12,
		look = "a classic grey space boulder, chunky and stubborn, a scar across its brow",
	},
	{
		id = "Ember",
		ability = { kind = "burn", value = 0.25, name = "Burn", desc = "Burns the planet: +25% damage over 3s" },
		impact = "magma",
		rarity = "Common",
		body = Color3.fromRGB(200, 70, 40),
		fire = { Color3.fromRGB(255, 120, 30), Color3.fromRGB(200, 30, 10) },
		face = { eyes = "normal" },
		baseDamage = 44,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 12,
		look = "a charcoal rock split by glowing orange cracks, smoldering",
	},
	{
		id = "Frost",
		ability = { kind = "mark", value = 0.12, name = "Chill", desc = "The planet takes +12% damage from everyone for 8s" },
		impact = "frost",
		rarity = "Common",
		body = Color3.fromRGB(150, 220, 255),
		fire = { Color3.fromRGB(180, 240, 255), Color3.fromRGB(60, 140, 255) },
		face = { eyes = "normal" },
		baseDamage = 44,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 12,
		look = "a frosted blue rock with ice shards on top",
	},
	{
		id = "Spark",
		ability = { kind = "chain", value = 0.25, name = "Static Shock", desc = "A second strike for +25% damage" },
		impact = "spark",
		rarity = "Common",
		body = Color3.fromRGB(255, 230, 80),
		fire = { Color3.fromRGB(255, 255, 150), Color3.fromRGB(255, 200, 0) },
		face = { eyes = "normal" },
		baseDamage = 44,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 12,
		look = "a dark rock crackling with yellow electricity",
	},
	{
		id = "Sprout",
		ability = { kind = "shards", value = 0.2, name = "Overgrowth", desc = "+20% Shards from its hits" },
		impact = "rock",
		rarity = "Common",
		body = Color3.fromRGB(90, 150, 70),
		fire = { Color3.fromRGB(170, 255, 120), Color3.fromRGB(60, 180, 60) },
		face = { eyes = "normal" },
		baseDamage = 44,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 12,
		look = "a mossy green rock with a little alien plant and glowing mushrooms growing on its head",
	},
	{
		id = "Magma",
		ability = { kind = "burn", value = 0.45, name = "Eruption", desc = "Lava burns the planet: +45% damage over 3s" },
		impact = "magma",
		rarity = "Rare",
		body = Color3.fromRGB(90, 20, 15),
		fire = { Color3.fromRGB(255, 90, 0), Color3.fromRGB(150, 0, 0) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 80,
		growTime = 300,
		powerBonus = 0.12,
		sellPrice = 35,
		look = "black basalt with molten lava dripping from its mouth and two curved horns",
	},
	{
		id = "Venom",
		ability = { kind = "burn", value = 0.4, name = "Poison", desc = "Poisons the planet: +40% damage over 3s" },
		impact = "venom",
		rarity = "Rare",
		body = Color3.fromRGB(110, 220, 60),
		fire = { Color3.fromRGB(180, 255, 80), Color3.fromRGB(40, 160, 20) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 80,
		growTime = 300,
		powerBonus = 0.12,
		sellPrice = 35,
		look = "a toxic green-purple rock with dripping fangs",
	},
	{
		id = "Crystal",
		ability = { kind = "critBoost", value = 0.5, name = "Shatter", desc = "Critical hits deal +50% more" },
		impact = "crystal",
		rarity = "Rare",
		body = Color3.fromRGB(255, 140, 230),
		fire = { Color3.fromRGB(255, 200, 255), Color3.fromRGB(200, 80, 255) },
		face = { eyes = "normal" },
		baseDamage = 80,
		growTime = 300,
		powerBonus = 0.12,
		sellPrice = 35,
		look = "grey rock bursting with big pink crystals",
	},
	{
		id = "Tidal",
		ability = { kind = "mark", value = 0.18, name = "Soaked", desc = "The planet takes +18% damage from everyone for 8s" },
		impact = "frost",
		rarity = "Rare",
		body = Color3.fromRGB(40, 120, 200),
		fire = { Color3.fromRGB(120, 220, 255), Color3.fromRGB(20, 90, 200) },
		face = { eyes = "normal" },
		baseDamage = 80,
		growTime = 300,
		powerBonus = 0.12,
		sellPrice = 35,
		look = "an ocean comet: deep blue rock with coral, shells and a wave of water curling over its head",
	},
	{
		id = "Cyclone",
		ability = { kind = "recharge", value = 0.2, name = "Tailwind", desc = "Recharges 20% faster" },
		impact = "aurora",
		rarity = "Rare",
		body = Color3.fromRGB(190, 230, 230),
		fire = { Color3.fromRGB(230, 255, 255), Color3.fromRGB(120, 200, 220) },
		face = { eyes = "normal", extra = "fins" },
		baseDamage = 80,
		growTime = 300,
		powerBonus = 0.12,
		sellPrice = 35,
		look = "a pale rock wrapped in a spinning tornado of wind and dust",
	},
	{
		id = "Aurora",
		ability = { kind = "shards", value = 0.6, name = "Aurora Blessing", desc = "+60% Shards from its hits" },
		impact = "aurora",
		rarity = "Epic",
		body = Color3.fromRGB(60, 230, 200),
		fire = { Color3.fromRGB(120, 255, 200), Color3.fromRGB(140, 80, 255) },
		face = { eyes = "normal" },
		baseDamage = 150,
		growTime = 600,
		powerBonus = 0.25,
		sellPrice = 110,
		look = "dark blue rock with green-violet northern lights flowing through it",
	},
	{
		id = "Obsidian",
		ability = { kind = "damage", value = 0.35, name = "Black Glass", desc = "+35% damage" },
		impact = "rock",
		rarity = "Epic",
		body = Color3.fromRGB(30, 25, 40),
		fire = { Color3.fromRGB(200, 120, 255), Color3.fromRGB(90, 40, 160) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 150,
		growTime = 600,
		powerBonus = 0.25,
		sellPrice = 110,
		look = "an armored knight comet of black volcanic glass with sharp faceted plates and a visor-like brow",
	},
	{
		id = "Tempest",
		ability = { kind = "chain", value = 0.45, name = "Thunderclap", desc = "A second strike for +45% damage" },
		impact = "spark",
		rarity = "Epic",
		body = Color3.fromRGB(90, 100, 140),
		fire = { Color3.fromRGB(200, 230, 255), Color3.fromRGB(80, 120, 255) },
		face = { eyes = "normal" },
		baseDamage = 150,
		growTime = 600,
		powerBonus = 0.25,
		sellPrice = 110,
		look = "a storm-cloud comet: dark clouds swirling around it with lightning bolts striking out",
	},
	{
		id = "Prism",
		ability = { kind = "critBoost", value = 0.8, name = "Refraction", desc = "Critical hits deal +80% more" },
		impact = "crystal",
		rarity = "Epic",
		body = Color3.fromRGB(230, 240, 255),
		fire = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(160, 120, 255) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 150,
		growTime = 600,
		powerBonus = 0.25,
		sellPrice = 110,
		look = "a clear crystal comet that splits light into rainbows, faceted like a gem",
	},
	{
		id = "Phantom",
		ability = { kind = "mark", value = 0.22, name = "Haunt", desc = "The planet takes +22% damage from everyone for 8s" },
		impact = "void",
		rarity = "Epic",
		body = Color3.fromRGB(150, 110, 220),
		fire = { Color3.fromRGB(210, 180, 255), Color3.fromRGB(110, 60, 200) },
		face = { eyes = "normal" },
		baseDamage = 150,
		growTime = 600,
		powerBonus = 0.25,
		sellPrice = 110,
		look = "a ghostly translucent violet comet with a wispy spirit trail and hollow glowing eyes",
	},
	{
		id = "Solar",
		ability = { kind = "mark", value = 0.28, name = "Solar Flare", desc = "The planet takes +28% damage from everyone for 8s" },
		impact = "solar",
		rarity = "Legendary",
		body = Color3.fromRGB(255, 190, 40),
		fire = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 120, 0) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 320,
		growTime = 1500,
		powerBonus = 0.6,
		sellPrice = 600,
		look = "a small sun with a crown of solar flares",
	},
	{
		id = "Royal Comet",
		ability = { kind = "shards", value = 1.0, name = "Royal Tribute", desc = "x2 Shards from its hits" },
		impact = "frost",
		rarity = "Legendary",
		body = Color3.fromRGB(220, 240, 255),
		fire = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(80, 160, 255) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 320,
		growTime = 1500,
		powerBonus = 0.6,
		sellPrice = 600,
		look = "a noble ice-white comet with a natural crown of ice crystals and veins of gold ore",
	},
	{
		id = "Phoenix",
		ability = { kind = "burn", value = 0.9, name = "Rebirth Flames", desc = "Burns the planet: +90% damage over 3s" },
		impact = "magma",
		rarity = "Legendary",
		body = Color3.fromRGB(255, 110, 40),
		fire = { Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 60, 20) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 320,
		growTime = 1500,
		powerBonus = 0.6,
		sellPrice = 600,
		look = "a fire-bird comet with wings and a crest of flames, proud and fierce",
	},
	{
		id = "Frost Wyrm",
		ability = { kind = "mark", value = 0.32, name = "Absolute Cold", desc = "The planet takes +32% damage from everyone for 8s" },
		impact = "frost",
		rarity = "Legendary",
		body = Color3.fromRGB(170, 230, 255),
		fire = { Color3.fromRGB(220, 250, 255), Color3.fromRGB(80, 170, 255) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 320,
		growTime = 1500,
		powerBonus = 0.6,
		sellPrice = 600,
		look = "an ice dragon head comet with frozen horns and frost breath",
	},
	{
		id = "Midas",
		ability = { kind = "shards", value = 1.5, name = "Golden Touch", desc = "x2.5 Shards from its hits" },
		impact = "solar",
		rarity = "Legendary",
		body = Color3.fromRGB(255, 205, 60),
		fire = { Color3.fromRGB(255, 240, 150), Color3.fromRGB(230, 160, 20) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 320,
		growTime = 1500,
		powerBonus = 0.6,
		sellPrice = 600,
		look = "a solid gold comet, polished and gleaming, with jewel-like eyes",
	},
	{
		id = "Void",
		ability = { kind = "damage", value = 0.6, name = "Void Rift", desc = "+60% damage" },
		impact = "void",
		rarity = "Mythic",
		body = Color3.fromRGB(20, 10, 35),
		fire = { Color3.fromRGB(170, 80, 255), Color3.fromRGB(30, 0, 60) },
		face = { eyes = "normal" },
		baseDamage = 850,
		growTime = 3600,
		powerBonus = 1.4,
		sellPrice = 4000,
		look = "a black hole comet: pitch black, violet event horizon, reality bending around it",
	},
	{
		id = "Supernova",
		ability = { kind = "chain", value = 0.7, name = "Nova Blast", desc = "A second blast for +70% damage" },
		impact = "nova",
		rarity = "Mythic",
		body = Color3.fromRGB(255, 255, 240),
		fire = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 80, 200) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 850,
		growTime = 3600,
		powerBonus = 1.4,
		sellPrice = 4000,
		look = "an exploding star breaking through red and gold armor, light leaking from every crack",
	},
	{
		id = "Galaxy",
		ability = { kind = "mark", value = 0.4, name = "Cosmic Tide", desc = "The planet takes +40% damage from everyone for 8s" },
		impact = "nova",
		rarity = "Mythic",
		body = Color3.fromRGB(60, 20, 90),
		fire = { Color3.fromRGB(255, 120, 220), Color3.fromRGB(120, 60, 255) },
		face = { eyes = "normal" },
		baseDamage = 850,
		growTime = 3600,
		powerBonus = 1.4,
		sellPrice = 4000,
		look = "a whole spiral galaxy swirling inside a cracked rock shell, pink, violet and orange",
	},
	{
		id = "Chrono",
		ability = { kind = "recharge", value = 0.6, name = "Time Warp", desc = "Recharges 60% faster" },
		impact = "aurora",
		rarity = "Mythic",
		body = Color3.fromRGB(210, 180, 120),
		fire = { Color3.fromRGB(255, 230, 160), Color3.fromRGB(120, 200, 255) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 850,
		growTime = 3600,
		powerBonus = 1.4,
		sellPrice = 4000,
		look = "a time comet: bronze clockwork rings orbiting a glowing hourglass core",
	},
	{
		id = "Eclipse",
		ability = { kind = "critBoost", value = 1.5, name = "Totality", desc = "Critical hits deal +150% more" },
		impact = "void",
		rarity = "Mythic",
		body = Color3.fromRGB(15, 15, 20),
		fire = { Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 120, 40) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 850,
		growTime = 3600,
		powerBonus = 1.4,
		sellPrice = 4000,
		look = "a black sphere with a blazing golden corona: a living solar eclipse",
	},
	{
		id = "Grey Visitor",
		ability = { kind = "shards", value = 2.0, name = "Abduction", desc = "x3 Shards from its hits" },
		impact = "spark",
		rarity = "Extraterrestrial",
		body = Color3.fromRGB(170, 180, 190),
		fire = { Color3.fromRGB(160, 255, 160), Color3.fromRGB(60, 220, 120) },
		face = { eyes = "normal", extra = "fins" },
		baseDamage = 1500,
		growTime = 5400,
		powerBonus = 2.5,
		sellPrice = 10000,
		look = "an alien visitor comet: smooth grey metal with a ring like a flying saucer, green tractor-beam light underneath",
	},
	{
		id = "Xeno Hive",
		ability = { kind = "chain", value = 1.2, name = "Swarm", desc = "A second strike for +120% damage" },
		impact = "venom",
		rarity = "Extraterrestrial",
		body = Color3.fromRGB(60, 40, 70),
		fire = { Color3.fromRGB(150, 255, 90), Color3.fromRGB(80, 200, 40) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 1500,
		growTime = 5400,
		powerBonus = 2.5,
		sellPrice = 10000,
		look = "a biomechanical alien hive comet with ribbed chitin plates and glowing green pods",
	},
	{
		id = "Blue Comet",
		ability = { kind = "recharge", value = 0.5, name = "Hyperspeed", desc = "Recharges twice as fast" },
		impact = "frost",
		rarity = "Epic",
		body = Color3.fromRGB(40, 90, 255),
		fire = { Color3.fromRGB(120, 200, 255), Color3.fromRGB(20, 40, 200) },
		face = { eyes = "normal", extra = "fins" },
		baseDamage = 150,
		growTime = 600,
		powerBonus = 0.25,
		sellPrice = 0,
		exclusive = true, -- never drops from showers (Starter Pack only), not part of the rarity sets
		look = "a streamlined blue comet shaped for speed, swept-back spikes like a helmet",
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
		if r.order >= 2 then
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
	if not r or r.id == "Mythic" or r.id == "Extraterrestrial" then
		return nil -- Extraterrestrial meteors only fall from the sky (no fusion, no luck bump)
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

-- Rarity sets: find every (non-exclusive) meteor of a rarity (the index remembers what you ever owned)
-- and you can turn ONE of them, your choice, into a WEAPON (a Tool whose head is that meteor).
-- Hitting another player knocks them back and knocks one meteor they picked up in the current shower
-- out of them.
Meteors.Weapons = {
	Common = { name = "Club", kind = "hammer" },
	Rare = { name = "Hammer", kind = "hammer" },
	Epic = { name = "Lance", kind = "lance" },
	Legendary = { name = "Scythe", kind = "scythe" },
	Mythic = { name = "Mace", kind = "hammer" },
	Extraterrestrial = { name = "Ray Lance", kind = "lance" },
}

function Meteors.SetMembers(rarityId)
	local list = {}
	for _, def in ipairs(Meteors.Types) do
		if def.rarity == rarityId and not def.exclusive then
			table.insert(list, def.id)
		end
	end
	return list
end

function Meteors.SetComplete(rarityId, index)
	local members = Meteors.SetMembers(rarityId)
	for _, id in ipairs(members) do
		if not index[id] then
			return false
		end
	end
	return #members > 0
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
