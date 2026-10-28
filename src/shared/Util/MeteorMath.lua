-- Shared formulas so the client can display exactly what the server computes.

local Shared = script.Parent.Parent
local Meteors = require(Shared.Config.Meteors)
local Game = require(Shared.Config.Game)

local MeteorMath = {}

-- Growth seconds accumulated, including the time spent on the altar since placedAt.
function MeteorMath.GrowthSeconds(meteor, now)
	local g = meteor.g or 0
	if meteor.altar and meteor.placedAt then
		g += math.max(0, now - meteor.placedAt)
	end
	return g
end

-- 0..1
function MeteorMath.Growth(meteor, now)
	local def = Meteors.ByID[meteor.t]
	if not def then
		return 0
	end
	return math.clamp(MeteorMath.GrowthSeconds(meteor, now) / def.growTime, 0, 1)
end

function MeteorMath.DisplaySize(meteor, now)
	return 2.4 + MeteorMath.Growth(meteor, now) * 3.6
end

function MeteorMath.LaunchSize(meteor, now)
	return 4 + MeteorMath.Growth(meteor, now) * 7
end

function MeteorMath.Expression(meteor, now)
	local growth = MeteorMath.Growth(meteor, now)
	if growth < 0.3 then
		return "sleepy"
	elseif growth < 1 then
		return "happy"
	end
	return "angry"
end

-- Damage before charge/crit/global multipliers.
function MeteorMath.MeteorDamage(meteor, now)
	local def = Meteors.ByID[meteor.t]
	if not def then
		return 0
	end
	local growth = MeteorMath.Growth(meteor, now)
	return def.baseDamage * (0.4 + 0.6 * growth) * Meteors.GetMutationMult(meteor.m)
end

function MeteorMath.PowerMultiplier(power)
	return 1 + math.sqrt(math.max(0, power)) / 25
end

function MeteorMath.Cooldown(data)
	return Game.Launch.BaseCooldown * Game.UpgradeEffect(data, "recharge")
end

-- Sum of the power-rate bonus given by meteors on the altar.
function MeteorMath.AltarPowerBonus(meteors, now)
	local bonus = 0
	for _, m in pairs(meteors) do
		if m.altar then
			local def = Meteors.ByID[m.t]
			if def then
				bonus += def.powerBonus * (0.3 + 0.7 * MeteorMath.Growth(m, now)) * Meteors.GetMutationMult(m.m)
			end
		end
	end
	return bonus
end

return MeteorMath
