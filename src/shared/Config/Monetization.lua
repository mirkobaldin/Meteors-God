-- Game Pass and Developer Product IDs.
-- Create them in the Creator Hub (Monetization tab of your experience), then paste the IDs here.
-- An ID of 0 means "not configured": the shop shows it as unavailable and nothing breaks.

local Monetization = {}

Monetization.GamePasses = {
	VIP = { id = 0, name = "VIP", desc = "+20% Power per second and VIP tag" },
	Power2x = { id = 0, name = "2x Power", desc = "Power per second doubled forever" },
	Shards2x = { id = 0, name = "2x Shards", desc = "Stellar Shards doubled forever" },
	ExtraAltar = { id = 0, name = "Extra Altar", desc = "+1 altar slot" },
}

Monetization.Products = {
	StarterPack = {
		id = 0,
		name = "Starter Pack",
		desc = "Exclusive Blue Comet + 5,000 Shards + 2x Power for 1 hour",
	},
	PowerS = { id = 0, name = "Power S", desc = "10 minutes of instant Power" },
	PowerM = { id = 0, name = "Power M", desc = "1 hour of instant Power" },
	PowerL = { id = 0, name = "Power L", desc = "6 hours of instant Power" },
	Boost2x = { id = 0, name = "2x Power Boost", desc = "x2 Power for 30 minutes" },
	DivineWrath = { id = 0, name = "Divine Wrath", desc = "The whole server deals x3 damage for 3 minutes" },
	LegendaryPlanet = { id = 0, name = "Summon Legendary Planet", desc = "A legendary planet arrives right now" },
	InstantRecharge = { id = 0, name = "Instant Recharge", desc = "All your meteors are ready again" },
	EvolveNow = { id = 0, name = "Evolve Now", desc = "Jump to the next Evolution right now" },
}

Monetization.StarterPack = {
	meteor = "Blue Comet",
	shards = 5000,
	boostSeconds = 3600,
}

Monetization.PowerPackSeconds = {
	PowerS = 600,
	PowerM = 3600,
	PowerL = 21600,
}

Monetization.Boost2xSeconds = 1800
Monetization.DivineWrathSeconds = 180

function Monetization.ProductKeyById(productId)
	for key, p in pairs(Monetization.Products) do
		if p.id ~= 0 and p.id == productId then
			return key
		end
	end
	return nil
end

function Monetization.PassKeyById(passId)
	for key, p in pairs(Monetization.GamePasses) do
		if p.id ~= 0 and p.id == passId then
			return key
		end
	end
	return nil
end

return Monetization
