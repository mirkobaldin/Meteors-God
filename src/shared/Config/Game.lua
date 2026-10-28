-- General tuning values: cycle, world layout, launch, economy, upgrades, trading.

local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local Game = {}

-- Shown in the corner of the screen and printed in Output: check it to be sure Studio has the latest code.
Game.Version = "0.4.0"

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

Game.Upgrades = {
	{ id = "speed", name = "Speed", desc = "+2 running speed", max = 10, baseCost = 50, growth = 1.8 },
	{ id = "power", name = "Power", desc = "+10% damage", max = 10, baseCost = 80, growth = 1.9 },
	{ id = "recharge", name = "Recharge", desc = "-8% recharge time", max = 10, baseCost = 60, growth = 1.85 },
	{ id = "luck", name = "Luck", desc = "+2% chance of a rarer meteor on pickup", max = 10, baseCost = 120, growth = 2 },
}

Game.UpgradeByID = {}
for _, u in ipairs(Game.Upgrades) do
	Game.UpgradeByID[u.id] = u
end

function Game.UpgradeCost(upgradeId, level)
	local u = Game.UpgradeByID[upgradeId]
	if not u or level >= u.max then
		return nil
	end
	return math.floor(u.baseCost * u.growth ^ level)
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
