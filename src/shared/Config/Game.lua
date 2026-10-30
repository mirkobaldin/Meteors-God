-- General tuning values: cycle, world layout, launch, economy, upgrades, trading.

local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local Game = {}

-- Shown in the corner of the screen and printed in Output: check it to be sure Studio has the latest code.
Game.Version = "0.10.0"

Game.Cycle = {
	-- One shower every 5 minutes (Calm + countdown + Shower), also in Studio.
	-- FastInStudio = true shortens the loop in Studio to test it quickly.
	FastInStudio = false,
	ShowerDuration = 40,
	CalmDuration = 256, -- between showers (planets can be hit at any time)
	ShowerCountdown = 4, -- players wait on their Comet Islet, then everybody runs
	ShowerSpawnInterval = 3.2, -- seconds between meteors during a shower (about 12 per shower)
	MaxMeteorsOnGround = 20,
	GroundMeteorLifetime = 90,
	PlanetDestroyedBonusMeteors = 4,
	PlanetDestroyedBonusLuck = 3,
	NextPlanetDelay = 8,
}
if IS_STUDIO and Game.Cycle.FastInStudio then
	Game.Cycle.ShowerDuration = 20
	Game.Cycle.CalmDuration = 60
	Game.Cycle.ShowerSpawnInterval = 1.5
end

-- Carrying: a grabbed meteor is NOT yours yet. It floats above your head and you must bring it back
-- to your own plot (Comet Islet or House Island) to keep it. A weapon hit knocks one out, dying drops
-- them all. Each carried meteor slows you down.
Game.Carry = {
	Base = 1, -- meteors you can carry at once
	BigBagBonus = 2, -- + with the BigBag Game Pass
	SpeedPenalty = 0.1, -- -10% walk speed per carried meteor
	MinSpeedMult = 0.6,
	-- Seconds to hold the Collect prompt, by rarity order (Common .. Extraterrestrial).
	HoldTime = { 0.4, 0.8, 1.2, 1.8, 2.5, 3 },
	BankMargin = 10, -- studs beyond the island edge that still count as "home"
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
	FieldInner = 34, -- the lava pool with the meteor sculpture in the middle
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
	-- The house models (Assets/Houses/House1..6, imported from Codex's FBX) are turned upright
	-- automatically (the FBX import can lay them on their side: the code tries the 90 degree turns on X
	-- and keeps the one where the floor "Base" is flat and at the bottom), then resized so their width
	-- is Footprints[level] studs, floor on the ground, facade (next to the Sign) towards the central island.
	Footprints = { 56, 76, 96, 116, 140, 170 },
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

-- Props (any Model or Part in ReplicatedStorage.Assets.Props) scattered on the islands: turned upright
-- like the houses (or by Props.TiltX), resized to fit between MinSize and MaxSize studs, random turn.
-- Props (models in ReplicatedStorage.Assets/Map or Assets/Props, by name) placed by a fixed layout:
-- every entry puts one prop at `at` in the frame of an anchor, on the ground below (only on terrain).
-- Anchors (their -Z/LookVector is "forward"):
--   world   the map origin, forward = towards the spawn
--   spawn   the spawn point, forward = towards the magma field
--   islet   every player's Comet Islet, forward = towards the map center (the bridge arrives there)
--   house   every player's House Island, forward = towards the map center
--   shop / leaderboard  the side islands, forward = towards the map center
-- face: "forward" (same way as the anchor) | "back" | "center" (towards the anchor) | "out"
-- ring = {count, radius}: `count` copies evenly around the anchor (at = height offset only).
-- float = true: hangs in the air at `at` (no ground needed).
Game.Props = {
	TiltX = nil, -- nil = same turn the houses needed
	-- Size of each prop (its biggest side, studs).
	Size = {
		god_statue = 48, meteor_sculpture = 34, reflecting_pool = 30, water_fountain = 20,
		armillary_sphere = 18, telescope_deck = 24, star_lamp = 14, bridge_lamps = 11,
		name_pillar = 13, crystal_planter = 7, floating_stones = 18, cosmic_tree = 34,
		glass_gazebo = 26, pergola = 22, lounge_set = 14, fire_pit = 9,
	},
	-- Extra turn (degrees) for a model whose front is not its -Z side.
	Yaw = {},
	Layout = {
		-- Spawn plaza: the god statue behind the spawn, a fountain, lamps along the path to the field.
		{ prop = "god_statue", anchor = "spawn", at = Vector3.new(0, 0, 70), face = "forward" },
		{ prop = "water_fountain", anchor = "spawn", at = Vector3.new(0, 0, 36), face = "forward" },
		{ prop = "star_lamp", anchor = "spawn", at = Vector3.new(-22, 0, -30), face = "forward" },
		{ prop = "star_lamp", anchor = "spawn", at = Vector3.new(22, 0, -30), face = "forward" },
		{ prop = "star_lamp", anchor = "spawn", at = Vector3.new(-22, 0, -75), face = "forward" },
		{ prop = "star_lamp", anchor = "spawn", at = Vector3.new(22, 0, -75), face = "forward" },
		-- Two gardens beside the spawn plaza: a pool with a gazebo, a pergola with a lounge and fire pit.
		{ prop = "reflecting_pool", anchor = "spawn", at = Vector3.new(-120, 0, 10), face = "center" },
		{ prop = "glass_gazebo", anchor = "spawn", at = Vector3.new(-150, 0, 45), face = "center" },
		{ prop = "pergola", anchor = "spawn", at = Vector3.new(125, 0, 25), face = "center" },
		{ prop = "lounge_set", anchor = "spawn", at = Vector3.new(118, 0, -5), face = "center" },
		{ prop = "fire_pit", anchor = "spawn", at = Vector3.new(100, 0, 0), face = "center" },
		-- The magma field: the meteor sculpture rises from the lava pool in the middle, lamps around it.
		{ prop = "meteor_sculpture", anchor = "world", at = Vector3.new(0, 0, 0), face = "forward" },
		{ prop = "star_lamp", anchor = "world", at = Vector3.new(0, 0, 0), ring = { 12, 244 }, face = "center" },
		-- Front of the central island, looking at the planets.
		{ prop = "telescope_deck", anchor = "world", at = Vector3.new(-210, 0, 390), face = "back" },
		{ prop = "telescope_deck", anchor = "world", at = Vector3.new(210, 0, 390), face = "back" },
		-- Next to the Fusion Reactor and the Hunt portal.
		{ prop = "armillary_sphere", anchor = "world", at = Vector3.new(-330, 0, -80), face = "center" },
		{ prop = "armillary_sphere", anchor = "world", at = Vector3.new(330, 0, -80), face = "center" },
		-- Stones floating around the central island.
		{ prop = "floating_stones", anchor = "world", at = Vector3.new(-560, 40, 120), float = true },
		{ prop = "floating_stones", anchor = "world", at = Vector3.new(560, 55, 60), float = true },
		{ prop = "floating_stones", anchor = "world", at = Vector3.new(0, 70, 620), float = true },
		-- Side islands: a tree on each.
		{ prop = "cosmic_tree", anchor = "shop", at = Vector3.new(-85, 0, -30), face = "forward" },
		{ prop = "cosmic_tree", anchor = "leaderboard", at = Vector3.new(85, 0, -30), face = "forward" },
		-- Every Comet Islet: lamps where the bridge arrives, the name pillar, planters beside the pedestals.
		{ prop = "bridge_lamps", anchor = "islet", at = Vector3.new(-22, 0, -58), face = "forward" },
		{ prop = "bridge_lamps", anchor = "islet", at = Vector3.new(22, 0, -58), face = "forward" },
		{ prop = "name_pillar", anchor = "islet", at = Vector3.new(34, 0, -44), face = "forward" },
		{ prop = "crystal_planter", anchor = "islet", at = Vector3.new(-31, 0, 2), face = "forward" },
		{ prop = "crystal_planter", anchor = "islet", at = Vector3.new(31, 0, 2), face = "forward" },
		{ prop = "floating_stones", anchor = "islet", at = Vector3.new(60, 25, 80), float = true },
		-- Every House Island: lamps where the bridge arrives.
		{ prop = "bridge_lamps", anchor = "house", at = Vector3.new(-22, 0, -98), face = "forward" },
		{ prop = "bridge_lamps", anchor = "house", at = Vector3.new(22, 0, -98), face = "forward" },
	},
}

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
