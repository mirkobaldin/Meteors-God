-- General tuning values: cycle, world layout, launch, economy, upgrades, trading.

local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local Game = {}

-- Shown in the corner of the screen and printed in Output: check it to be sure Studio has the latest code.
Game.Version = "0.5.0"

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

Game.World = {
	-- Zone 1 (back): Houses district
	HousesCenter = Vector3.new(0, 0, -95),
	HousesRadius = 170,
	HouseRingRadius = 140,
	AltarCount = 8,
	AltarSlotsBase = 3,
	-- Zone 2 (middle): Meteor Field, meteors fall between FieldInner and FieldRadius
	FieldCenter = Vector3.new(0, 6, 0),
	FieldRadius = 115,
	FieldInner = 26,
	-- Zone 3 (front): Bifrost + Launch Platform
	BifrostLength = 300,
	BifrostWidth = 26,
	PlatformRadius = 38,
	LaunchPadCount = 4,
	LaunchPadRadius = 8,
	PlanetPosition = Vector3.new(0, 380, 2750),
	PlanetRadius = 420,
	-- Island rock bodies and floating islets made of Terrain (skipped if the place has its own terrain).
	GenerateTerrain = true,
	IsletCount = 22,
}

Game.Launch = {
	HoverHeight = 18,
	RiseTime = 0.3, -- seconds to lift off the pad (instant feel)
	MinChargeTime = 0.2,
	MaxHoldTime = 10,
	ChargePeriod = 1.0, -- seconds for the ring to go 0 -> 1
	CritThreshold = 0.88,
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

-- Space backdrop (client): distances from the map center, in studs. The target planet is ~2750 away.
Game.Sky = {
	PlanetDistance = 4200,
	NebulaDistance = 6000,
	GalaxyDistance = 6500,
}

Game.Leaderboard = {
	StoreName = "MeteorGods_Planets_v1",
	Size = 10,
	RefreshInterval = 120, -- seconds (OrderedDataStore limits)
	-- Beside the spawn in the Houses district, facing the players.
	Position = Vector3.new(-30, 17, -165),
	LookAt = Vector3.new(0, 0, -120),
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
