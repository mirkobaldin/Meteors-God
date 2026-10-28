-- Daily login calendar, playtime gift and codes.

local RunService = game:GetService("RunService")

local Rewards = {}

-- 7-day calendar. Missing a day does NOT reset the streak: you continue from where you were.
-- kind: "shards" (amount) | "power" (seconds of current Power/s) | "boost" (seconds of 2x Power)
--       | "meteor" (guaranteed rarity, optional bonus shards)
Rewards.Daily = {
	{ kind = "shards", amount = 500, label = "+500", sub = "Shards", emoji = "💎" },
	{ kind = "power", seconds = 600, label = "+10 min", sub = "Power", emoji = "⚡" },
	{ kind = "boost", seconds = 1800, label = "2x Power", sub = "30 min", emoji = "🧪" },
	{ kind = "shards", amount = 2500, label = "+2.500", sub = "Shards", emoji = "💎" },
	{ kind = "meteor", rarity = "Rare", label = "Meteor", sub = "Guaranteed Rare", emoji = "☄️" },
	{ kind = "power", seconds = 3600, label = "+1 hour", sub = "Power", emoji = "⚡" },
	{
		kind = "meteor",
		rarity = "Epic",
		shards = 10000,
		label = "Grand reward",
		sub = "Epic Meteor + 10,000 Shards",
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
