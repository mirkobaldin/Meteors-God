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
-- look / expression: body and face of the meteor (used by the concept-art prompts in docs/). Every meteor
-- has its own face: never reuse an expression.
Meteors.Types = {
	{
		id = "Grumble",
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
		look = "a lumpy grey moon-rock ball pocked with little craters, one bigger crater on its forehead like a bump",
		expression = "heavy half-closed grumpy eyes with tiny pupils; a flat wide frown with one chipped front tooth sticking up; a grumpy old rock",
	},
	{
		id = "Cinder",
		ability = { kind = "burn", value = 0.25, name = "Scorch", desc = "Burns the planet: +25% damage over 3s" },
		impact = "magma",
		rarity = "Common",
		body = Color3.fromRGB(60, 40, 35),
		fire = { Color3.fromRGB(255, 120, 30), Color3.fromRGB(200, 30, 10) },
		face = { eyes = "normal" },
		baseDamage = 44,
		growTime = 120,
		powerBonus = 0.05,
		sellPrice = 12,
		look = "a coal-black ball speckled with glowing orange embers, a short curl of solid smoke on top like a cowlick",
		expression = "huge round excited eyes glowing orange; a wide open laughing mouth with one single tooth; a hyperactive kid",
	},
	{
		id = "Flurry",
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
		look = "a packed snowball with a messy hairdo of icicle spikes on top, frosty blue shadows",
		expression = "squinting mischievous eyes; a cheeky grin with two big buck teeth of ice; a prankster",
	},
	{
		id = "Zap",
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
		look = "a round ball of bright yellow static fur standing on end, two lightning-bolt shaped ear spikes",
		expression = "wide shocked eyes with tiny dot pupils; a zigzag mouth; always startled",
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
		look = "a mossy green rock ball with a leafy sprout and tiny glowing mushrooms on its head",
		expression = "eyes closed in happy upside-down U curves; a small content smile and moss-pink cheeks; gentle and calm",
	},
	{
		id = "Magmaw",
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
		look = "a cracked black basalt shell over a molten core, two stubby horns, lava drooling from the jaw",
		expression = "angry slanted eyes glowing yellow; a huge underbite jaw with two tusks pointing up; a bully",
	},
	{
		id = "Gloop",
		ability = { kind = "burn", value = 0.4, name = "Toxic Goo", desc = "Toxic goo melts the planet: +40% damage over 3s" },
		impact = "venom",
		rarity = "Rare",
		body = Color3.fromRGB(120, 220, 70),
		fire = { Color3.fromRGB(180, 255, 80), Color3.fromRGB(40, 160, 20) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 80,
		growTime = 300,
		powerBonus = 0.12,
		sellPrice = 35,
		look = "a bubbling toxic-green slime ball with a crusty purple rock crust grown over its top, bubbles rising inside",
		expression = "mismatched crazy eyes, one big and one small; a wide wobbly grin with the tongue lolling out; completely unhinged",
	},
	{
		id = "Geode",
		ability = { kind = "critBoost", value = 0.5, name = "Shatter", desc = "Critical hits deal +50% more" },
		impact = "crystal",
		rarity = "Rare",
		body = Color3.fromRGB(130, 95, 70),
		fire = { Color3.fromRGB(220, 150, 255), Color3.fromRGB(140, 60, 230) },
		face = { eyes = "normal" },
		baseDamage = 80,
		growTime = 300,
		powerBonus = 0.12,
		sellPrice = 35,
		look = "a plain brown rock ball split open horizontally: the split is its mouth, lined with purple amethyst crystals that glow inside",
		expression = "two small faceted amethyst eyes, narrowed and cunning; the mouth is the geode crack with crystal teeth; sly",
	},
	{
		id = "Puffer",
		ability = { kind = "mark", value = 0.18, name = "Needle Burst", desc = "Spines stick in the planet: it takes +18% damage from everyone for 8s" },
		impact = "frost",
		rarity = "Rare",
		body = Color3.fromRGB(40, 150, 170),
		fire = { Color3.fromRGB(140, 255, 240), Color3.fromRGB(30, 140, 200) },
		face = { eyes = "normal", extra = "fins" },
		baseDamage = 80,
		growTime = 300,
		powerBonus = 0.12,
		sellPrice = 35,
		look = "a deep-space pufferfish puffed into a ball, covered in short spines, teal with glowing bioluminescent spots, small fins",
		expression = "big round watery fish eyes; a tiny puckered O-shaped mouth; nervous",
	},
	{
		id = "Scarab",
		ability = { kind = "recharge", value = 0.2, name = "Rolling Rush", desc = "Recharges 20% faster" },
		impact = "aurora",
		rarity = "Rare",
		body = Color3.fromRGB(40, 120, 90),
		fire = { Color3.fromRGB(150, 255, 200), Color3.fromRGB(40, 160, 120) },
		face = { eyes = "normal", extra = "fins" },
		baseDamage = 80,
		growTime = 300,
		powerBonus = 0.12,
		sellPrice = 35,
		look = "a space beetle rolled up into an armored ball: glossy metallic green-blue shell plates, two short antennae",
		expression = "two big glossy black bug eyes with a white highlight; small clicking mandibles; busy and fast",
	},
	{
		id = "Aurowl",
		ability = { kind = "shards", value = 0.6, name = "Aurora Blessing", desc = "+60% Shards from its hits" },
		impact = "aurora",
		rarity = "Epic",
		body = Color3.fromRGB(30, 40, 90),
		fire = { Color3.fromRGB(120, 255, 200), Color3.fromRGB(140, 80, 255) },
		face = { eyes = "normal", extra = "crest" },
		baseDamage = 150,
		growTime = 600,
		powerBonus = 0.25,
		sellPrice = 110,
		look = "a round night-sky owl: feathers like dark blue crystal plates, green-violet northern lights flowing across its chest, two crystal ear tufts",
		expression = "huge calm round owl eyes with green-violet aurora irises; a small closed hooked beak; wise",
	},
	{
		id = "Bastion",
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
		look = "an armored knight ball of black volcanic glass with sharp faceted plates and a visor ridge across the face",
		expression = "two eyes glowing red through the narrow visor slit; the mouth hidden behind a grille of glass plates; stoic and silent",
	},
	{
		id = "Stormram",
		ability = { kind = "chain", value = 0.45, name = "Thunderclap", desc = "A second strike for +45% damage" },
		impact = "spark",
		rarity = "Epic",
		body = Color3.fromRGB(70, 75, 100),
		fire = { Color3.fromRGB(200, 230, 255), Color3.fromRGB(80, 120, 255) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 150,
		growTime = 600,
		powerBonus = 0.25,
		sellPrice = 110,
		look = "a thundercloud ram: a body of dark sculpted storm-cloud wool with lightning glowing inside, two big curled ram horns of rock",
		expression = "fierce narrowed eyes glowing white-blue; gritted teeth with sparks between them; aggressive",
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
		look = "a faceted clear gem ball that splits light into rainbows",
		expression = "diamond-shaped eyes; a smug one-sided smirk; arrogant",
	},
	{
		id = "Specter",
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
		look = "a translucent violet ghost orb with a soft wavy bottom edge (no wisps) and a dark rock skull-core visible inside",
		expression = "hollow round eye sockets with tiny white pinpoint pupils; a wide stitched creepy grin; unsettling",
	},
	{
		id = "Solaris",
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
		look = "a miniature sun of boiling plasma with a crown of solar-flare loops arching over the top (attached loops, nothing trailing)",
		expression = "confident narrowed eyes, white-hot; a proud closed-mouth smile; a king",
	},
	{
		id = "Leviathan",
		ability = { kind = "shards", value = 1.0, name = "Star Feast", desc = "x2 Shards from its hits" },
		impact = "frost",
		rarity = "Legendary",
		body = Color3.fromRGB(25, 40, 90),
		fire = { Color3.fromRGB(140, 220, 255), Color3.fromRGB(60, 120, 255) },
		face = { eyes = "normal", extra = "fins" },
		baseDamage = 320,
		growTime = 1500,
		powerBonus = 0.6,
		sellPrice = 600,
		look = "a round deep-space whale creature, navy blue with glowing constellation spots, small fins, ancient and majestic",
		expression = "small wise ancient eyes; a huge wide gentle mouth with baleen plates; serene",
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
		look = "a round fire bird with its wings folded tight around its body like a cloak and a crest of flame feathers (nothing trailing behind)",
		expression = "sharp golden hawk eyes; a hooked beak open in a battle cry; proud and fierce",
	},
	{
		id = "Frostfang",
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
		look = "a compact ice dragon head shaped like a ball: curled ice horns and a ridge of frost spikes along the back",
		expression = "icy blue reptile eyes with slit pupils; a fanged jaw with cold mist; predatory",
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
		look = "a solid polished gold ball studded with cut gems",
		expression = "round coin-like eyes with ruby pupils; a greedy grin full of gold teeth; greedy",
	},
	{
		id = "Singularity",
		ability = { kind = "damage", value = 0.6, name = "Event Horizon", desc = "+60% damage" },
		impact = "void",
		rarity = "Mythic",
		body = Color3.fromRGB(20, 10, 35),
		fire = { Color3.fromRGB(170, 80, 255), Color3.fromRGB(30, 0, 60) },
		face = { eyes = "normal" },
		baseDamage = 850,
		growTime = 3600,
		powerBonus = 1.4,
		sellPrice = 4000,
		look = "a pitch-black sphere with a glowing violet accretion ring orbiting around its middle like a planet ring, light bending at its edges",
		expression = "two glowing violet ring eyes with black centers; a mouth that is a swirling vortex; ominous",
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
		look = "a star bursting through cracked dark armor plates, white-gold light blasting out of every crack",
		expression = "furious blazing eyes; a roaring wide-open mouth pouring light; pure rage",
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
		look = "a sphere of dark glass with a whole spiral galaxy swirling inside, tiny planets orbiting close around it",
		expression = "eyes with star-shaped pupils; a serene knowing smile; all-knowing",
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
		look = "a bronze clockwork sphere with two thin crossed rings orbiting it and gears visible through glass panels",
		expression = "eyes that are two little clock dials with moving hands; a small precise smile with square cog teeth; calculating",
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
		look = "a sphere split down the middle: one half a blazing golden sun, the other half a cold silver moon",
		expression = "the face is split too: one eye golden fire, the other pale silver; the mouth half grin, half frown; two-faced",
	},
	{
		id = "Visitor",
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
		look = "a smooth silver biomechanical orb with glowing green seams and a thin saucer ring around its middle",
		expression = "huge black almond-shaped alien eyes; a tiny thin slit mouth, no nose; eerily calm",
	},
	{
		id = "Xenobloom",
		ability = { kind = "chain", value = 1.2, name = "Devour", desc = "A second strike for +120% damage" },
		impact = "venom",
		rarity = "Extraterrestrial",
		body = Color3.fromRGB(60, 40, 70),
		fire = { Color3.fromRGB(150, 255, 90), Color3.fromRGB(80, 200, 40) },
		face = { eyes = "normal", extra = "horns" },
		baseDamage = 1500,
		growTime = 5400,
		powerBonus = 2.5,
		sellPrice = 10000,
		look = "an alien carnivorous seed-pod: dark purple chitin petals clamped shut around a glowing green core",
		expression = "two glowing green slit eyes between the petals; the petals part like a mouth showing rows of glowing green needle teeth; predatory",
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
		look = "a sleek blue ice-glass ball with short swept-back fin spikes on its head, built for speed (no trail)",
		expression = "determined narrowed racer eyes; a confident grin; a speed demon",
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
