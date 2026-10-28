-- Player-to-player meteor trading. Fully server-authoritative:
-- request -> accept -> both set offers -> both confirm -> countdown -> re-validate -> atomic swap -> save.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)
local RateLimit = require(Server.RateLimit)

local TradeService = {}

local T = Game.Trade
local REQUEST_EXPIRE = 30

local services
local sessions = {} -- [player] = session (both players point to the same table)
local pending = {} -- [target] = {[fromUserId] = os.clock()}
local stateRemote
local incomingRemote

function TradeService:IsTrading(player)
	return sessions[player] ~= nil
end

local function other(session, player)
	return session.a == player and session.b or session.a
end

local function recordView(data, uid)
	local m = data and data.meteors[uid]
	if not m then
		return nil
	end
	return { uid = uid, t = m.t, m = m.m, g = m.g }
end

local function pushState(session)
	for _, player in ipairs({ session.a, session.b }) do
		local partner = other(session, player)
		local myData = services.DataService:Get(player)
		local theirData = services.DataService:Get(partner)
		local mine, theirs = {}, {}
		for _, uid in ipairs(session.offers[player]) do
			table.insert(mine, recordView(myData, uid))
		end
		for _, uid in ipairs(session.offers[partner]) do
			table.insert(theirs, recordView(theirData, uid))
		end
		stateRemote:FireClient(player, {
			partnerName = partner.DisplayName,
			partnerUserId = partner.UserId,
			myOffer = mine,
			theirOffer = theirs,
			myConfirmed = session.confirmed[player],
			theirConfirmed = session.confirmed[partner],
			status = session.status,
			countdownEndsAt = session.countdownEndsAt,
		})
	end
end

local function close(session, reason)
	if sessions[session.a] ~= session then
		return
	end
	session.status = "closed"
	sessions[session.a] = nil
	sessions[session.b] = nil
	for _, player in ipairs({ session.a, session.b }) do
		if player.Parent then
			stateRemote:FireClient(player, nil)
			if reason then
				Notify.Toast(player, reason, "info")
			end
		end
	end
end

-- Checks that every uid can be traded by this player right now.
local function validOffer(player, uids)
	local data = services.DataService:Get(player)
	if not data then
		return false
	end
	for _, uid in ipairs(uids) do
		local m = data.meteors[uid]
		if not m or m.altar or m.paid then
			return false
		end
		if services.MeteorService:IsLaunching(player, uid) then
			return false
		end
	end
	return true
end

local function countMeteors(data)
	local n = 0
	for _ in pairs(data.meteors) do
		n += 1
	end
	return n
end

local function execute(session)
	local a, b = session.a, session.b
	local offerA, offerB = session.offers[a], session.offers[b]
	local dataA, dataB = services.DataService:Get(a), services.DataService:Get(b)
	if not dataA or not dataB or not validOffer(a, offerA) or not validOffer(b, offerB) then
		close(session, "Trade cancelled: the items changed")
		return
	end
	if countMeteors(dataA) - #offerA + #offerB > Game.InventoryCap(dataA) or countMeteors(dataB) - #offerB + #offerA > Game.InventoryCap(dataB) then
		close(session, "Trade cancelled: storage full")
		return
	end

	-- Atomic swap (no yields between take and give).
	local fromA, fromB = {}, {}
	for _, uid in ipairs(offerA) do
		table.insert(fromA, services.MeteorService:TakeMeteor(a, uid))
	end
	for _, uid in ipairs(offerB) do
		table.insert(fromB, services.MeteorService:TakeMeteor(b, uid))
	end
	local summaryA, summaryB = {}, {}
	for _, record in ipairs(fromA) do
		services.MeteorService:GiveRecord(b, record)
		table.insert(summaryA, (record.m and (record.m .. " ") or "") .. record.t)
	end
	for _, record in ipairs(fromB) do
		services.MeteorService:GiveRecord(a, record)
		table.insert(summaryB, (record.m and (record.m .. " ") or "") .. record.t)
	end

	local now = os.time()
	local function log(data, partner, gave, got)
		table.insert(data.tradeHistory, 1, { with = partner.DisplayName, gave = gave, got = got, at = now })
		while #data.tradeHistory > T.HistorySize do
			table.remove(data.tradeHistory)
		end
	end
	log(dataA, b, summaryA, summaryB)
	log(dataB, a, summaryB, summaryA)

	session.status = "done"
	close(session, "Trade completed!")
	for _, player in ipairs({ a, b }) do
		services.MeteorService:PushSnapshot(player)
		task.spawn(function()
			services.DataService:Save(player, false)
		end)
	end
end

local function startTrade(a, b)
	local session = {
		a = a,
		b = b,
		offers = { [a] = {}, [b] = {} },
		confirmed = { [a] = false, [b] = false },
		status = "open",
		countdownEndsAt = 0,
		token = 0,
	}
	sessions[a] = session
	sessions[b] = session
	pushState(session)
end

local function canTrade(player)
	local data = services.DataService:Get(player)
	return data ~= nil and data.evolution >= T.MinEvolution
end

local function onRequest(player, targetUserId)
	if typeof(targetUserId) ~= "number" or not RateLimit.Allow(player, "TradeRequest", T.RequestCooldown) then
		Notify.Toast(player, "Wait a few seconds before another request", "info")
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		return
	end
	if not canTrade(player) then
		Notify.Toast(player, "Trading requires Evolution " .. T.MinEvolution, "bad")
		return
	end
	if not canTrade(target) then
		Notify.Toast(player, target.DisplayName .. " can't trade yet", "bad")
		return
	end
	if sessions[player] or sessions[target] then
		Notify.Toast(player, "One of you is already trading", "bad")
		return
	end
	pending[target] = pending[target] or {}
	pending[target][player.UserId] = os.clock()
	incomingRemote:FireClient(target, player.UserId, player.DisplayName)
	Notify.Toast(player, "Trade request sent to " .. target.DisplayName, "info")
end

local function onRespond(player, fromUserId, accepted)
	if typeof(fromUserId) ~= "number" then
		return
	end
	local list = pending[player]
	local at = list and list[fromUserId]
	if not at then
		return
	end
	list[fromUserId] = nil
	local from = Players:GetPlayerByUserId(fromUserId)
	if not from then
		return
	end
	if not accepted then
		Notify.Toast(from, player.DisplayName .. " declined the trade", "info")
		return
	end
	if os.clock() - at > REQUEST_EXPIRE then
		Notify.Toast(player, "Request expired", "info")
		return
	end
	if sessions[player] or sessions[from] then
		Notify.Toast(player, "One of you is already trading", "bad")
		return
	end
	startTrade(from, player)
end

local function onSetOffer(player, uids)
	local session = sessions[player]
	if not session or session.status == "done" or session.status == "closed" then
		return
	end
	if typeof(uids) ~= "table" or not RateLimit.Allow(player, "TradeSetOffer", 0.15) then
		return
	end
	local clean, seen = {}, {}
	for _, uid in ipairs(uids) do
		if typeof(uid) == "string" and not seen[uid] then
			seen[uid] = true
			table.insert(clean, uid)
		end
		if #clean >= T.MaxItemsPerSide then
			break
		end
	end
	if not validOffer(player, clean) then
		Notify.Toast(player, "You can only offer meteors from Storage (not on the altar, not exclusive)", "bad")
		return
	end
	session.offers[player] = clean
	-- Any change invalidates both confirmations (anti-scam).
	session.confirmed[session.a] = false
	session.confirmed[session.b] = false
	session.status = "open"
	session.token += 1
	pushState(session)
end

local function onConfirm(player)
	local session = sessions[player]
	if not session or session.status ~= "open" then
		return
	end
	if #session.offers[session.a] == 0 and #session.offers[session.b] == 0 then
		Notify.Toast(player, "The trade is empty", "info")
		return
	end
	session.confirmed[player] = true
	if session.confirmed[session.a] and session.confirmed[session.b] then
		session.status = "countdown"
		session.token += 1
		session.countdownEndsAt = workspace:GetServerTimeNow() + T.ConfirmCountdown
		local token = session.token
		task.delay(T.ConfirmCountdown, function()
			if sessions[session.a] == session and session.token == token and session.status == "countdown" then
				execute(session)
			end
		end)
	end
	pushState(session)
end

function TradeService:Init(s)
	services = s
	stateRemote = Remotes.Get("TradeState")
	incomingRemote = Remotes.Get("TradeIncoming")
end

function TradeService:Start()
	Remotes.Get("TradeRequest").OnServerEvent:Connect(onRequest)
	Remotes.Get("TradeRespond").OnServerEvent:Connect(onRespond)
	Remotes.Get("TradeSetOffer").OnServerEvent:Connect(onSetOffer)
	Remotes.Get("TradeConfirm").OnServerEvent:Connect(onConfirm)
	Remotes.Get("TradeCancel").OnServerEvent:Connect(function(player)
		local session = sessions[player]
		if session then
			close(session, player.DisplayName .. " cancelled the trade")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
		local session = sessions[player]
		if session then
			close(session, "Trade cancelled: " .. player.DisplayName .. " left")
		end
	end)
end

return TradeService
