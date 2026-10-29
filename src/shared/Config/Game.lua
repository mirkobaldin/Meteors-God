-- General tuning values: cycle, world layout, launch, economy, upgrades, trading.

local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local Game = {}

-- Shown in the corner of the screen and printed in Output: check it to be sure Studio has the latest code.
Game.Version = "0.9.0"

Game.Cycle = {
	-- Shortened in Studio so the whole loop can be tested quickly.
	ShowerDuration = IS_STUDIO and 20 or 60,
	CalmDuration = IS_STUDIO and 60 or 240, -- between showers (planets can be hit at any time)
	ShowerCountdown = 4, -- players wait on their Comet Islet, then everybody runs
	ShowerSpawnInterval = 0.8, -- seconds between meteors during a shower
	MaxMeteorsOnGround = 50,
	GroundMeteorLifetime = 90,
	PlanetDestroyedBonusMeteors = 12,
	PlanetDestroyedBonusLuck = 3,
	NextPlanetDelay = 8,
}

-- Map layout (top view, the planets are towards +Z), following the owner's sketch, 3x scale:
--   center: the big Central Island, meteors fall on the Meteor Field in its middle;
--   behind: one plot per player = a Comet Islet (meteors on pedestals) + a higher House Island,
--           linked by bridges and fanned out in an arc;
--   front: three separate Bifrost bridges (one per planet tier, angles in Config/Planets) ending at a
--          hub with 4 short bridges to 4 separate pad islets; the Shop and Leaderboard islands (each
--          with a big mountain) sit between the bridges.
-- Heights: houses 88 > comet islets 40 > everything else 0 (multiples of 4 = terrain voxels).
Game.World = {
	CenterRadius = 480,
	FieldCenter = Vector3.new(0, 0, 0),
	FieldRadius = 220,
	FieldInner = 0,
	SpawnPosition = Vector3.new(0, 0, -360),

	HouseCount = 12, -- set the server's Max Players to the same number
	PlotArc = 200, -- degrees covered by the plots behind the central island
	CometIsletDistance = 760,
	CometIsletRadius = 75,
	CometIsletHeight = 40,
	HouseIslandDistance = 1100,
	HouseIslandRadius = 120,
	HouseIslandHeight = 88,
	AltarSlotsBase = 3,

	ShopIsland = { center = Vector3.new(-359, 0, 770), radius = 180 },
	LeaderboardIsland = { center = Vector3.new(359, 0, 770), radius = 180 },
	MountainHeight = 420,

	LaneWidth = 44,
	PlatformDistance = 1300, -- from the map center to the hub at the end of each bridge
	HubRadius = 55,
	PadIsletDistance = 135, -- from the hub to each of its 4 pad islets
	PadIsletRadius = 26,
	PadArc = 84, -- degrees covered by the 4 pad islets
	LaunchPadRadius = 11,

	-- The big map is crossed fast: base walk speed and the boost while on a Bifrost bridge.
	WalkSpeed = 30,
	BridgeSpeedMultiplier = 2.2,

	-- false = the place has its own hand-made terrain (Studio Terrain Editor): no islands are
	-- generated, only the parts (bridges, pedestals, houses, pads). Planets are always terrain.
	GenerateTerrain = true,
	-- Floating islets of terrain around the map (decoration).
	IsletCount = 26,
}

Game.Launch = {
	HoverHeight = 18,
	RiseTime = 0.3, -- seconds to lift off the pad (instant feel)
	MinChargeTime = 0.35,
	MaxHoldTime = 8,
	ChargePeriod = 0.75, -- seconds for the ring to go 0 -> 1 (then back)
	-- Critical: a narrow golden zone placed at random between CritZoneMin and CritZoneMax each throw.
	CritWindow = 0.07,
	CritZoneMin = 0.5,
	CritZoneMax = 0.98,
	CritMultiplier = 2,
	MeteorSpeed = 1500, -- studs per second
	FlightMin = 0.9,
	FlightMax = 1.8,
	ArcHeight = 0.08, -- arc apex as a fraction of the distance
	BaseCooldown = 10,
	WrathMultiplier = 3,
}

-- Player house: 6 levels (the 6 house models, Assets/Houses/House1..6), bought with Shards at the
-- lectern in front of the house. Each level needs an Evolution and gives a bonus to the Shards
-- earned and to Power per second.
Game.House = {
	Levels = {
		{ name = "Star Pavilion", cost = 0, evolution = 1, bonus = 0 },
		{ name = "Celestial Villa", cost = 2500, evolution = 2, bonus = 0.1 },
		{ name = "Demigod Residence", cost = 15000, evolution = 3, bonus = 0.2 },
		{ name = "Titan Cliff Villa", cost = 90000, evolution = 4, bonus = 0.35 },
		{ name = "Cosmic Sky Mansion", cost = 500000, evolution = 5, bonus = 0.5 },
		{ name = "Supreme Palace", cost = 3000000, evolution = 6, bonus = 0.75 },
	},
	-- The house models are built at human scale in Blender (1 unit = 1 stud); in game they are
	-- scaled up by Scale (gods' houses, and the map is big). The importer may change the scale, so
	-- the code resizes each model to its Blender size x Scale (bounds from art/export/houses/*_manifest.json,
	-- Blender axes: x right, y back, z up; floor at z = 0, front towards -y).
	Scale = 2,
	Yaw = 0, -- extra turn in degrees if a facade still looks the wrong way (the code finds it from the Sign)
	Models = {
		{ min = Vector3.new(-14.5, -14.045, -1.0), max = Vector3.new(14.5, 13.0, 10.5), radius = 19.47 }, -- House1
		{ min = Vector3.new(-20.5, -18.045, -1.0), max = Vector3.new(20.5, 18.0, 20.8), radius = 27.28 }, -- House2
		{ min = Vector3.new(-28.0, -21.545, -1.0), max = Vector3.new(28.0, 21.5, 23.794), radius = 35.3 }, -- House3
		{ min = Vector3.new(-32.5, -24.5, -12.833), max = Vector3.new(32.5, 24.5, 38.839), radius = 40.7 }, -- House4
		{ min = Vector3.new(-40.149, -37.236, -1.0), max = Vector3.new(40.154, 43.24, 40.062), radius = 59.01 }, -- House5
		{ min = Vector3.new(-52.5, -38.5, -4.667), max = Vector3.new(52.5, 38.5, 50.094), radius = 65.1 }, -- House6
	},
	IslandMargin = 24, -- free ground around the house (the island grows for the big houses)
	-- Roblox look of the Blender materials (the FBX meshes are named after them, e.g. House3_Warm_Oak_01).
	Materials = {
		Brushed_Gold = { Enum.Material.Foil, Color3.fromRGB(214, 168, 96) },
		Clear_Glass = { Enum.Material.Glass, Color3.fromRGB(205, 232, 255), 0.6, true },
		Cushion_Blue = { Enum.Material.Fabric, Color3.fromRGB(86, 116, 176) },
		Cyan_Starlight = { Enum.Material.Neon, Color3.fromRGB(90, 230, 255), 0, true },
		Lawn = { Enum.Material.Grass, Color3.fromRGB(96, 168, 84) },
		Leaf_Light = { Enum.Material.Grass, Color3.fromRGB(130, 196, 104) },
		Leaf_Violet = { Enum.Material.SmoothPlastic, Color3.fromRGB(176, 120, 236) },
		Leaves = { Enum.Material.Grass, Color3.fromRGB(70, 140, 72) },
		Light_Beam = { Enum.Material.Neon, Color3.fromRGB(255, 240, 205), 0.55, true },
		Linen_Ivory = { Enum.Material.Fabric, Color3.fromRGB(242, 234, 216) },
		Meteor_Stone = { Enum.Material.Basalt, Color3.fromRGB(64, 52, 76) },
		Pale_Cliff = { Enum.Material.Limestone, Color3.fromRGB(216, 206, 190) },
		Pale_Marble = { Enum.Material.Marble, Color3.fromRGB(236, 233, 228) },
		Pool_Water = { Enum.Material.Glass, Color3.fromRGB(70, 172, 232), 0.35, true },
		Rug_Sand = { Enum.Material.Fabric, Color3.fromRGB(212, 192, 152) },
		Trunk = { Enum.Material.Wood, Color3.fromRGB(122, 92, 70) },
		Violet_Starlight = { Enum.Material.Neon, Color3.fromRGB(182, 122, 255), 0, true },
		Warm_Light = { Enum.Material.Neon, Color3.fromRGB(255, 212, 142), 0, true },
		Warm_Oak = { Enum.Material.WoodPlanks, Color3.fromRGB(192, 142, 92) },
		Waterfall = { Enum.Material.Glass, Color3.fromRGB(150, 212, 255), 0.3, true },
		White_Roof = { Enum.Material.SmoothPlastic, Color3.fromRGB(246, 246, 246) },
		White_Travertine = { Enum.Material.Limestone, Color3.fromRGB(236, 229, 216) },
	}, -- { material, color, transparency?, noCollide? }
}

function Game.HouseLevel(data)
	return math.clamp(data.houseLevel or 1, 1, #Game.House.Levels)
end

function Game.HouseBonus(data)
	return Game.House.Levels[Game.HouseLevel(data)].bonus
end

Game.Weapons = {
	Cooldown = 1.1, -- seconds between swings
	Range = 11, -- studs in front of you
	Knockback = 70,
	Immunity = 2.5, -- a player can't be hit again for this long
}

Game.Economy = {
	BasePowerPerSecond = 1,
	AscensionPowerBonus = 0.5,
	VIPPowerMultiplier = 1.2,
	ShardsPerDamage = 0.1,
	InventoryCap = 60,
	MinContributionShare = 0.01, -- needed to count a planet as destroyed
}

-- Upgrades have no level cap (except Storage): costs grow smoothly, effects keep stacking.
-- effect(level) returns the total bonus at that level; fmt turns it into text for the UI.
local function pct(v)
	return string.format("%d%%", math.floor(v * 100 + 0.5))
end

Game.Upgrades = {
	{
		id = "speed", name = "Swiftness", desc = "Running speed",
		baseCost = 40, growth = 1.13,
		effect = function(l) return 30 * (1 - 0.95 ^ l) end, -- walk speed bonus, approaches +30
		fmt = function(v) return string.format("+%.1f speed", v) end,
	},
	{
		id = "power", name = "Might", desc = "Damage to planets",
		baseCost = 60, growth = 1.14,
		effect = function(l) return 0.08 * l end, -- linear, never stops
		fmt = function(v) return "+" .. pct(v) .. " damage" end,
	},
	{
		id = "crit", name = "Precision", desc = "Critical hit damage",
		baseCost = 90, growth = 1.15,
		effect = function(l) return 0.1 * l end, -- added to Launch.CritMultiplier
		fmt = function(v) return string.format("Crit x%.1f", 2 + v) end,
	},
	{
		id = "recharge", name = "Recharge", desc = "Meteor recharge time",
		baseCost = 50, growth = 1.14,
		effect = function(l) return 1 - 0.75 * (1 - 0.96 ^ l) end, -- cooldown multiplier, down to 25%
		fmt = function(v) return "-" .. pct(1 - v) .. " recharge" end,
	},
	{
		id = "luck", name = "Luck", desc = "Chance of a rarer meteor on pickup",
		baseCost = 100, growth = 1.16,
		effect = function(l) return 0.5 * (1 - 0.97 ^ l) end, -- approaches 50%
		fmt = function(v) return pct(v) .. " rarer" end,
	},
	{
		id = "greed", name = "Greed", desc = "Stellar Shards earned",
		baseCost = 80, growth = 1.15,
		effect = function(l) return 0.06 * l end,
		fmt = function(v) return "+" .. pct(v) .. " shards" end,
	},
	{
		id = "altar", name = "Altar Energy", desc = "Power per second",
		baseCost = 120, growth = 1.16,
		effect = function(l) return 0.05 * l end,
		fmt = function(v) return "+" .. pct(v) .. " power/s" end,
	},
	{
		id = "storage", name = "Storage", desc = "Meteor storage space",
		baseCost = 150, growth = 1.25, max = 40,
		effect = function(l) return 5 * l end,
		fmt = function(v) return "+" .. v .. " slots" end,
	},
}

Game.UpgradeByID = {}
for _, u in ipairs(Game.Upgrades) do
	Game.UpgradeByID[u.id] = u
end

function Game.UpgradeCost(upgradeId, level)
	local u = Game.UpgradeByID[upgradeId]
	if not u or (u.max and level >= u.max) then
		return nil
	end
	return math.floor(u.baseCost * u.growth ^ level)
end

-- Total bonus of an upgrade for a player's data (0 / neutral at level 0).
function Game.UpgradeEffect(data, upgradeId)
	local u = Game.UpgradeByID[upgradeId]
	return u.effect(data and data.upgrades and data.upgrades[upgradeId] or 0)
end

function Game.InventoryCap(data)
	return Game.Economy.InventoryCap + Game.UpgradeEffect(data, "storage")
end

Game.Leaderboard = {
	StoreName = "MeteorGods_Planets_v1",
	Size = 10,
	RefreshInterval = 120, -- seconds (OrderedDataStore limits)
	-- Beside the spawn in the Houses district, facing the players.
	Position = Vector3.new(330, 34, 690), -- on the Leaderboard island
	LookAt = Vector3.new(0, 0, 0),
	Scale = 2,
}

-- Cosmic events: rolled at the start of a Meteor Shower, they last for that shower.
Game.Events = {
	Chance = 0.35,
	List = {
		{ id = "Eclipse", name = "ECLIPSE", desc = "Mutations x5!", mutationMult = 5, color = Color3.fromRGB(170, 80, 255), tint = Color3.fromRGB(200, 170, 255) },
		{ id = "GoldenRain", name = "GOLDEN RAIN", desc = "Golden meteors everywhere!", forceMutation = "Golden", forceChance = 0.4, color = Color3.fromRGB(255, 205, 60), tint = Color3.fromRGB(255, 235, 190) },
		{ id = "Frenzy", name = "METEOR FRENZY", desc = "Twice as many meteors!", spawnRateMult = 2, color = Color3.fromRGB(255, 130, 50), tint = Color3.fromRGB(255, 215, 200) },
		{ id = "LuckyStars", name = "LUCKY STARS", desc = "Rare meteors x3!", luckMult = 3, color = Color3.fromRGB(90, 220, 255), tint = Color3.fromRGB(200, 240, 255) },
	},
}
Game.EventByID = {}
for _, e in ipairs(Game.Events.List) do
	Game.EventByID[e.id] = e
end

-- Titles over the head, by planets destroyed. Stars: one per 25 levels of any upgrade.
Game.Titles = {
	{ planets = 1, name = "Planet Cracker", color = Color3.fromRGB(200, 200, 215) },
	{ planets = 10, name = "Planet Breaker", color = Color3.fromRGB(110, 220, 130) },
	{ planets = 50, name = "Star Breaker", color = Color3.fromRGB(90, 170, 255) },
	{ planets = 200, name = "Planet Eater", color = Color3.fromRGB(190, 100, 255) },
	{ planets = 1000, name = "World Ender", color = Color3.fromRGB(255, 190, 50) },
}
Game.UpgradeStarEvery = 25

function Game.TitleFor(planets)
	local best
	for _, t in ipairs(Game.Titles) do
		if planets >= t.planets then
			best = t
		end
	end
	return best
end

-- Feeding: Stardust (earned in the Cosmic Hunt) levels a meteor up: more damage, bigger body.
Game.Feeding = {
	MaxLevel = 10,
	BaseCost = 40, -- x rarity order^1.5 x Growth^level
	Growth = 1.55,
	DamagePerLevel = 0.15,
	SizePerLevel = 0.06,
	Stages = { [5] = "Awakened", [10] = "Ascended" },
}

function Game.FeedCost(rarityOrder, level)
	local f = Game.Feeding
	if level >= f.MaxLevel then
		return nil
	end
	return math.floor(f.BaseCost * rarityOrder ^ 1.5 * f.Growth ^ level)
end

-- Fusion Reactor (on the central island): 3 meteors of a type -> 1 of the next rarity.
Game.Fusion = {
	RequiredPlanets = 3, -- planets destroyed to unlock it
	Position = Vector3.new(-330, 0, -150),
}

-- Cosmic Hunt: fly through deep space and smash as many small planets as you can.
Game.Hunt = {
	Duration = 120,
	Center = Vector3.new(0, 6000, 0), -- far above the map
	Radius = 1600,
	PlanetCount = 26,
	PlanetRadius = { 30, 110 },
	FireCooldown = 0.45,
	Range = 1400,
	FlySpeed = 120,
	BoostSpeed = 260,
	StardustPerPlanet = 6, -- x planet size factor
	PlanetHits = { 2, 6 }, -- hits to break the smallest / biggest planet (fed and rarer meteors hit harder)
	ProjectileSpeed = 900, -- studs/s of a thrown meteor (the crater appears when it lands)
	ShatterDelay = 0.9, -- seconds a broken planet glows and cracks before it explodes
	RespawnDelay = 4,
	PortalPosition = Vector3.new(330, 0, -150),
}

Game.Trade = {
	MinEvolution = 2,
	MaxItemsPerSide = 8,
	ConfirmCountdown = 3,
	RequestCooldown = 8,
	HistorySize = 20,
}

Game.IsStudio = IS_STUDIO

return Game
