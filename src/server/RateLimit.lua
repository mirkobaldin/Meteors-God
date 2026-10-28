-- Per-player, per-key throttle for remote handlers.

local Players = game:GetService("Players")

local RateLimit = {}

local last = {} -- [player] = {[key] = clock}

function RateLimit.Allow(player, key, interval)
	local t = last[player]
	if not t then
		t = {}
		last[player] = t
	end
	local now = os.clock()
	if t[key] and now - t[key] < interval then
		return false
	end
	t[key] = now
	return true
end

Players.PlayerRemoving:Connect(function(player)
	last[player] = nil
end)

return RateLimit
