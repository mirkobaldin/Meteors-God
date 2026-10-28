-- Central list of remotes. The server creates them, clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	-- server -> client
	"InventoryUpdate", -- (snapshot)
	"Announce", -- (text, color)
	"Toast", -- (text, kind)
	"MeteorPickedUp", -- ({type, mutation, upgraded})
	"LaunchResult", -- ({model, flightTime, damage, crit})
	"PlanetDestroyed", -- ({name, shards, share})
	"TradeIncoming", -- (fromUserId, fromName)
	"TradeState", -- (state | nil)
	"PlanetFX", -- (payload) impacts, mantle shatter, supernova, arrival
	"LaunchFX", -- (payload) another player's meteor flight
	-- client -> server
	"FireLaunch", -- (charge)
	"CancelLaunch", -- ()
	"PlaceOnAltar", -- (uid)
	"RemoveFromAltar", -- (uid)
	"SellMeteor", -- (uid)
	"Evolve", -- ()
	"Ascend", -- ()
	"BuyUpgrade", -- (upgradeId, count 1..100)
	"TradeRequest", -- (targetUserId)
	"TradeRespond", -- (fromUserId, accepted)
	"TradeSetOffer", -- ({uid})
	"TradeConfirm", -- ()
	"TradeCancel", -- ()
	"ClaimDaily", -- ()
	"ClaimGift", -- ()
	"RedeemCode", -- (code)
}

local FUNCTIONS = {
	"BeginLaunch", -- () -> {ok, reason, meteorType}
	"RequestSnapshot", -- () -> snapshot
}

local Remotes = {}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in ipairs(EVENTS) do
		if not folder:FindFirstChild(name) then
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
	end
	for _, name in ipairs(FUNCTIONS) do
		if not folder:FindFirstChild(name) then
			local r = Instance.new("RemoteFunction")
			r.Name = name
			r.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

function Remotes.Get(name)
	local r = folder:WaitForChild(name, 10)
	assert(r, "Remote not found: " .. tostring(name))
	return r
end

return Remotes
