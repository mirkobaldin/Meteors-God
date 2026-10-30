-- Uploaded asset IDs (images, animations, sounds). 0 = not configured: the game falls back to
-- generated visuals / no sound. See docs/ASSET_PIPELINE.md. 3D models live in ReplicatedStorage.Assets.

local Assets = {}

-- 512x512 transparent PNG icons uploaded as images ("rbxassetid://" is added by the code).
Assets.Icons = {
	Meteors = 108857441295016,
	Evolution = 111108946421448,
	Shop = 131616152941534,
	Daily = 130843197633785,
	Trade = 87109705858594,
	Upgrades = 97298069070256,
	Index = 126599753055581,
	Codes = 107693510932106,
	Settings = 75127665196662,
	Menu = 112186106317028,
	Power = 76359104502751,
	Shards = 72021841158782,
	Stardust = 115930337079245,
	Planets = 109064388589022,
	StarterPack = 116952101630051,
	Wrath = 110553508911924,
	Boost = 89153647586152,
	Hunt = 129489607126257,
	Fusion = 102994993038130,
	Weapons = 136173075724912,
	Collection = 72258192884306,
}

-- UI art: art/ui/<Theme>/*.png. Keys match file stems for bulk imports.
-- 9-slice rectangles and source dimensions are recorded in art/ui/validation.json.
Assets.UI = {
	Theme = "A",
	Images = {
		frame_window = 137095250502473,
		frame_panel = 91264627975335,
		frame_tooltip = 91319427626876,
		frame_banner = 118773490044172,
		button_main_normal = 82381661035444,
		button_main_hover = 130175477556979,
		button_main_pressed = 81018073204570,
		button_blue_normal = 73736410626836,
		button_blue_hover = 94775919714937,
		button_blue_pressed = 97184203015340,
		button_red_normal = 81106088271715,
		button_red_hover = 116754292592728,
		button_red_pressed = 110002398388133,
		button_close = 89823291203491,
		button_tab_on = 123845753172484,
		button_tab_off = 70667671767339,
		pill_shards = 118168616922056,
		pill_stardust = 85462358620496,
		pill_power = 72308075034062,
		bar_back = 72166755333531,
		bar_fill = 124949438265139,
		bar_fill_hp = 126121859324205,
		card_common = 125544911742974,
		card_rare = 89536975735166,
		card_epic = 129718017347166,
		card_legendary = 134675725560027,
		card_mythic = 89735259696903,
		card_extraterrestrial = 87889793584161,
		logo = 96147483041115,
		loading_background = 119734936688669,
	},
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

-- Particle textures (white on transparent PNG). 0 = Roblox built-in fallbacks.
Assets.Particles = {
	Glow = 0,
	Fire = 0,
	Smoke = 0,
	Spark = 0,
	Ring = 0,
	Debris = 0,
	Swirl = 0,
	Lightning = 0,
	Burst = 0,
	Trail = 0,
}

-- Equirectangular planet textures (future use on mantle/core spheres), keyed by planet name.
Assets.PlanetTextures = {}

function Assets.Image(id)
	return (id and id ~= 0) and ("rbxassetid://" .. id) or nil
end

return Assets
