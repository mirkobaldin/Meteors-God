-- General tuning values: cycle, world layout, launch, economy, upgrades, trading.

local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local Game = {}

-- Shown in the corner of the screen and printed in Output: check it to be sure Studio has the latest code.
Game.Version = "0.6.0"

Game.Cycle = {
	-- Shortened in Studio so the whole loop can be tested quickly.
	ShowerDuration = IS_STUDIO and 20 or 60,
	BombardDuration = IS_STUDIO and 60 or 240,
	ShowerSpawnInterval = 1.2, -- seconds between meteors during a shower
	MaxMeteorsOnGround = 30,
	GroundMeteorLifetime = 90,
	PlanetDestroyedBonusMeteors = 12,
	PlanetDestroyedBonusLuck = 3,
	NextPlanetDelay = 8,
}

-- Map layout (top view, the planets are towards +Z), following the owner's sketch:
--   center: the big Central Island, meteors fall on the Meteor Field in its middle;
--   behind: one plot per player = a Comet Islet (meteors on pedestals) + a higher House Island,
--           linked by bridges and fanned out in an arc;
--   front sides: Shop island and Leaderboard island, each with a mountain;
--   front: the Bifrost with 3 lanes (one per planet tier) joining the Launch Platform.
-- Heights: houses 32 > comet islets 16 > everything else 0 (multiples of 4 = terrain voxels).
Game.World = {
	CenterRadius = 170,
	FieldCenter = Vector3.new(0, 0, 0),
	FieldRadius = 85,
	FieldInner = 0,
	SpawnPosition = Vector3.new(0, 0, -125),

	HouseCount = 6, -- set the server's Max Players to the same number
	PlotArc = 150, -- degrees covered by the plots behind the central island
	CometIsletDistance = 255,
	CometIsletRadius = 30,
	CometIsletHeight = 16,
	HouseIslandDistance = 390,
	HouseIslandRadius = 46,
	HouseIslandHeight = 32,
	AltarSlotsBase = 3,

	ShopIsland = { center = Vector3.new(-240, 0, 140), radius = 80 },
	LeaderboardIsland = { center = Vector3.new(240, 0, 140), radius = 80 },

	BridgeStartZ = 160,
	LaneOffset = 26, -- x distance between the 3 lanes
	LaneWidth = 17,
	PlatformCenter = Vector3.new(0, 0, 470),
	PlatformRadius = 80,
	PadRingRadius = 60,
	LaunchPadRadius = 8,

	-- false = the place has its own hand-made terrain (Studio Terrain Editor): no islands are
	-- generated, only the parts (bridges, pedestals, houses, pads). Planets are always terrain.
	GenerateTerrain = true,
	-- Floating islets of terrain around the map (decoration).
	IsletCount = 22,
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
	Position = Vector3.new(225, 17, 115), -- on the Leaderboard island
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

Game.Trade = {
	MinEvolution = 2,
	MaxItemsPerSide = 8,
	ConfirmCountdown = 3,
	RequestCooldown = 8,
	HistorySize = 20,
}

Game.IsStudio = IS_STUDIO

return Game
