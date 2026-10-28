-- General tuning values: cycle, world layout, launch, economy, upgrades, trading.

local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local Game = {}

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
	CitadelRadius = 120,
	CitadelY = 0,
	AltarCount = 8,
	AltarRingRadius = 78,
	AltarSlotsBase = 3,
	BridgeCount = 4,
	BridgeSpacing = 32,
	BridgeLength = 220,
	BridgeWidth = 12,
	PlanetPosition = Vector3.new(0, 170, 760),
	PlanetRadius = 140,
	LaunchPadRadius = 14,
}

Game.Launch = {
	HoverHeight = 28,
	MinChargeTime = 0.25,
	MaxHoldTime = 8,
	ChargePeriod = 1.1, -- seconds for the bar to go 0 -> 1
	CritThreshold = 0.88,
	CritMultiplier = 2,
	FlightTime = 1.2,
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
	{ id = "speed", name = "Velocità", desc = "+2 velocità di corsa", max = 10, baseCost = 50, growth = 1.8 },
	{ id = "power", name = "Potenza", desc = "+10% danno", max = 10, baseCost = 80, growth = 1.9 },
	{ id = "recharge", name = "Ricarica", desc = "-8% tempo di ricarica", max = 10, baseCost = 60, growth = 1.85 },
	{ id = "luck", name = "Fortuna", desc = "+2% rarità superiore alla raccolta", max = 10, baseCost = 120, growth = 2 },
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
