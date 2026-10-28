-- Uploaded asset IDs (images, animations, sounds). 0 = not configured: the game falls back to
-- generated visuals / no sound. See docs/ASSET_PIPELINE.md. 3D models live in ReplicatedStorage.Assets.

local Assets = {}

-- 512x512 transparent PNG icons uploaded as images ("rbxassetid://" is added by the code).
Assets.Icons = {
	Meteors = 0,
	Evolution = 0,
	Shop = 0,
	Daily = 0,
	Trade = 0,
	Upgrades = 0,
	Index = 0,
	Codes = 0,
	Settings = 0,
	Menu = 0,
	Power = 0,
	Shards = 0,
	Planets = 0,
	StarterPack = 0,
	Wrath = 0,
	Boost = 0,
}

-- R15 animations published by the game owner.
Assets.Animations = {
	Charge = 0, -- looped: levitating, arms raised while charging
	Throw = 0, -- one shot: overhead throw towards the planet
	Hover = 0, -- looped: floating pose above the void
	Celebrate = 0, -- one shot: after a critical hit / planet destroyed
	Pickup = 0, -- one shot: grabbing a meteor
}

Assets.Sounds = {
	Shower = 0,
	MeteorLand = 0,
	Pickup = 0,
	RarePickup = 0,
	ChargeLoop = 0,
	Throw = 0,
	Impact = 0,
	Crit = 0,
	PlanetExplode = 0,
	Evolve = 0,
	Purchase = 0,
	Click = 0,
	Music = 0,
}

function Assets.Image(id)
	return (id and id ~= 0) and ("rbxassetid://" .. id) or nil
end

return Assets
