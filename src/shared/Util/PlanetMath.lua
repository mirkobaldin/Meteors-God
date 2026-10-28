-- Shared launch geometry so client prediction and server results match.

local Shared = script.Parent.Parent
local Game = require(Shared.Config.Game)

local L = Game.Launch

local PlanetMath = {}

-- First intersection of a ray (origin + dir * t, t >= 0) with a sphere, or nil.
function PlanetMath.Intersect(origin, dir, center, radius)
	local oc = origin - center
	local b = oc:Dot(dir)
	local c = oc:Dot(oc) - radius * radius
	local disc = b * b - c
	if disc < 0 then
		return nil
	end
	local t = -b - math.sqrt(disc)
	if t < 0 then
		t = -b + math.sqrt(disc)
	end
	if t < 0 then
		return nil
	end
	return origin + dir * t
end

-- Where a meteor thrown from `origin` towards `aim` lands on a sphere.
-- A miss is snapped to the closest point of the sphere (the edge you were aiming near).
function PlanetMath.ImpactFromAim(origin, aim, center, radius)
	local delta = aim - origin
	local dir = delta.Magnitude > 1e-3 and delta.Unit or (center - origin).Unit
	local hit = PlanetMath.Intersect(origin, dir, center, radius)
	if hit then
		return hit, (hit - center).Unit
	end
	local t = math.max(0, (center - origin):Dot(dir))
	local closest = origin + dir * t
	local n = closest - center
	n = n.Magnitude > 1e-3 and n.Unit or -dir
	return center + n * radius, n
end

function PlanetMath.FlightTime(distance)
	return math.clamp(distance / L.MeteorSpeed, L.FlightMin, L.FlightMax)
end

-- Position along the throw arc at t in [0, 1].
function PlanetMath.ArcPoint(from, to, t)
	local dist = (to - from).Magnitude
	local p = from:Lerp(to, t)
	return p + Vector3.new(0, math.sin(math.pi * t) * dist * L.ArcHeight, 0)
end

return PlanetMath
