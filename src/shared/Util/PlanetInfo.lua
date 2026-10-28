-- Reads the live state of the planets (attributes on workspace.Planets.Tier<n>, written by the
-- server PlanetService). Works on server and client.

local Shared = script.Parent.Parent
local Planets = require(Shared.Config.Planets)

local PlanetInfo = {}

function PlanetInfo.Folder(tier)
	local root = workspace:FindFirstChild("Planets")
	return root and root:FindFirstChild("Tier" .. tostring(tier)) or nil
end

-- { name, hp, maxHP, layer, center, radius, ready, legendary } or nil before the first spawn.
function PlanetInfo.Get(tier)
	local f = PlanetInfo.Folder(tier)
	if not f or not f:GetAttribute("PlanetName") then
		return nil
	end
	local def = Planets.Tiers[tier]
	return {
		tier = tier,
		name = f:GetAttribute("PlanetName"),
		hp = f:GetAttribute("HP") or 0,
		maxHP = math.max(1, f:GetAttribute("MaxHP") or 1),
		layer = f:GetAttribute("Layer") or "",
		center = f:GetAttribute("Center") or def.position,
		radius = f:GetAttribute("Radius") or def.radius,
		ready = f:GetAttribute("Ready") == true,
		legendary = f:GetAttribute("Legendary") == true,
	}
end

-- Highest tier unlocked at this evolution.
function PlanetInfo.TierForEvolution(evolution)
	local best = 1
	for i, t in ipairs(Planets.Tiers) do
		if (evolution or 1) >= t.requiredEvolution then
			best = i
		end
	end
	return best
end

return PlanetInfo
