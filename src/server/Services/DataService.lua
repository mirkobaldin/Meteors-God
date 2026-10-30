-- Player data with a session lock (prevents item duplication when a player hops servers).
-- If DataStores are unavailable (e.g. Studio without API access) data lives in memory only.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local STORE_NAME = "MeteorGods_v1"
local LOCK_EXPIRE = 1800 -- seconds after which a lock from a dead server is ignored
local AUTOSAVE_INTERVAL = 60
local LOAD_RETRIES = 5

local DataService = {}

local profiles = {} -- [player] = data
local persistent = {} -- [player] = bool (false when running memory-only)
local loadedEvent = Instance.new("BindableEvent")
DataService.PlayerLoaded = loadedEvent.Event

local store
local storeOk = pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local function defaultData()
	return {
		version = 1,
		power = 0,
		shards = 0,
		stardust = 0,
		equipped = "", -- uid of the meteor that follows you and is thrown first
		bestHunt = 0,
		evolution = 1,
		houseLevel = 1, -- Game.House.Levels
		weaponPicks = {}, -- [rarity] = meteor type used as the head of that rarity's weapon
		ascensions = 0,
		planetsDestroyed = 0,
		totalDamage = 0,
		meteors = {},
		nextUid = 1,
		upgrades = { speed = 0, power = 0, crit = 0, recharge = 0, luck = 0, greed = 0, altar = 0, storage = 0 },
		index = {},
		starterPackBought = false,
		receipts = {},
		tradeHistory = {},
		boosts = { power2xUntil = 0 },
		daily = { streak = 0, lastDay = -1 },
		codes = {},
		firstJoin = os.time(),
		lastSeen = os.time(),
	}
end

-- Fills in fields added in later versions without touching existing values.
local function reconcile(data, template)
	for k, v in pairs(template) do
		if data[k] == nil then
			data[k] = type(v) == "table" and table.clone(v) or v
		elseif type(v) == "table" and type(data[k]) == "table" and next(v) ~= nil then
			reconcile(data[k], v)
		end
	end
	return data
end

-- Meteor and mutation ids were renamed to English; convert old saves.
local LEGACY_IDS = {
	Sassolino = "Pebble",
	Brace = "Ember",
	Gelo = "Frost",
	Scintilla = "Spark",
	Veleno = "Venom",
	Cristallo = "Crystal",
	Solare = "Solar",
	["Cometa Regale"] = "Royal Comet",
	Vuoto = "Void",
	["Cometa Blu"] = "Blue Comet",
	Dorato = "Golden",
	Arcobaleno = "Rainbow",
	Eclissato = "Eclipsed",
}

local function migrate(data)
	for _, m in pairs(data.meteors) do
		m.t = LEGACY_IDS[m.t] or m.t
		if m.m then
			m.m = LEGACY_IDS[m.m] or m.m
		end
	end
	local index = {}
	for id, v in pairs(data.index) do
		index[LEGACY_IDS[id] or id] = v
	end
	data.index = index
end

local function keyFor(player)
	return "p_" .. player.UserId
end

local function tryLoad(player)
	local result
	local locked = false
	local ok, err = pcall(function()
		result = store:UpdateAsync(keyFor(player), function(old)
			old = old or defaultData()
			local lock = old._lock
			if lock and lock.job ~= game.JobId and os.time() - (lock.t or 0) < LOCK_EXPIRE then
				locked = true
				return nil -- cancel: another server still owns this profile
			end
			old._lock = { job = game.JobId, t = os.time() }
			return old
		end)
	end)
	if not ok then
		return nil, "error", err
	end
	if locked then
		return nil, "locked"
	end
	return result, "ok"
end

local function loadPlayer(player)
	if not storeOk then
		return defaultData(), false
	end
	for attempt = 1, LOAD_RETRIES do
		local data, status, err = tryLoad(player)
		if status == "ok" and data then
			return data, true
		end
		if status == "error" then
			warn("[DataService] load error for", player.Name, err)
			if RunService:IsStudio() then
				warn("[DataService] Enable 'Studio Access to API Services' to save data. Using memory only.")
				return defaultData(), false
			end
		end
		if not player.Parent then
			return nil, false
		end
		task.wait(attempt < LOAD_RETRIES and 5 or 0)
	end
	-- Lock never released (crashed server): steal it on the last attempt.
	local data
	local ok = pcall(function()
		data = store:UpdateAsync(keyFor(player), function(old)
			old = old or defaultData()
			old._lock = { job = game.JobId, t = os.time() }
			return old
		end)
	end)
	if ok and data then
		return data, true
	end
	return defaultData(), false
end

function DataService:Get(player)
	return profiles[player]
end

-- Yields until the player's data is loaded (or the player leaves / timeout).
function DataService:Wait(player, timeout)
	local start = os.clock()
	while player.Parent and not profiles[player] and os.clock() - start < (timeout or 30) do
		task.wait(0.2)
	end
	return profiles[player]
end

function DataService:Save(player, release)
	local data = profiles[player]
	if not data or not persistent[player] then
		return data ~= nil
	end
	data.lastSeen = os.time()
	local lostLock = false
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function(old)
			if old and old._lock and old._lock.job ~= game.JobId then
				lostLock = true
				return nil
			end
			local copy = table.clone(data)
			copy._lock = (not release) and { job = game.JobId, t = os.time() } or nil
			return copy
		end)
	end)
	if not ok then
		warn("[DataService] save error for", player.Name, err)
		return false
	end
	if lostLock then
		warn("[DataService] lost session lock for", player.Name)
		return false
	end
	return true
end

function DataService:Init() end

function DataService:Start()
	local function onPlayerAdded(player)
		local data, isPersistent = loadPlayer(player)
		if not data or not player.Parent then
			return
		end
		data._lock = nil
		reconcile(data, defaultData())
		migrate(data)
		profiles[player] = data
		persistent[player] = isPersistent
		loadedEvent:Fire(player, data)
	end

	-- Deferred so every other service has connected to PlayerLoaded before the first load finishes.
	Players.PlayerAdded:Connect(function(player)
		task.defer(onPlayerAdded, player)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		task.defer(onPlayerAdded, p)
	end

	Players.PlayerRemoving:Connect(function(player)
		if profiles[player] then
			DataService:Save(player, true)
			profiles[player] = nil
			persistent[player] = nil
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in pairs(profiles) do
				task.spawn(function()
					DataService:Save(player, false)
				end)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				DataService:Save(player, true)
				pending -= 1
			end)
		end
		local start = os.clock()
		while pending > 0 and os.clock() - start < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
