-- Daily login calendar, playtime gift and codes.

local RunService = game:GetService("RunService")

local Rewards = {}

-- 7-day calendar. Missing a day does NOT reset the streak: you continue from where you were.
-- kind: "shards" (amount) | "power" (seconds of current Power/s) | "boost" (seconds of 2x Power)
--       | "meteor" (guaranteed rarity, optional bonus shards)
Rewards.Daily = {
	{ kind = "shards", amount = 500, label = "+500", sub = "Frammenti", emoji = "💎" },
	{ kind = "power", seconds = 600, label = "+10 min", sub = "Potere", emoji = "⚡" },
	{ kind = "boost", seconds = 1800, label = "2x Potere", sub = "30 min", emoji = "🧪" },
	{ kind = "shards", amount = 2500, label = "+2.500", sub = "Frammenti", emoji = "💎" },
	{ kind = "meteor", rarity = "Raro", label = "Meteorite", sub = "Raro garantito", emoji = "☄️" },
	{ kind = "power", seconds = 3600, label = "+1 ora", sub = "Potere", emoji = "⚡" },
	{
		kind = "meteor",
		rarity = "Epico",
		shards = 10000,
		label = "Grande ricompensa",
		sub = "Meteorite Epico + 10.000 Frammenti",
		emoji = "🎁",
	},
}

-- Free gift every N seconds of playtime (in the current session).
Rewards.GiftInterval = RunService:IsStudio() and 45 or 600
function Rewards.GiftShards(evolution, ascensions)
	return math.floor(150 * evolution * (1 + 0.5 * ascensions))
end

-- Codes are case-insensitive. Each player can redeem a code once.
-- reward fields: shards, powerSeconds, boostSeconds, meteorRarity
Rewards.Codes = {
	RELEASE = { shards = 1000 },
	METEORGODS = { shards = 500, boostSeconds = 900 },
}

-- Whole days since the Unix epoch (UTC), used for the daily calendar.
function Rewards.Today()
	return math.floor(os.time() / 86400)
end

return Rewards
