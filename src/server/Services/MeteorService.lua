-- Meteor inventory, altar placement, growth display, cooldowns and selling.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local MeteorMath = require(Shared.Util.MeteorMath)
local MeteorVisual = require(Shared.MeteorVisual)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)
local RateLimit = require(Server.RateLimit)

local MeteorService = {}

local services
local cooldowns = {} -- [player] = {[uid] = os.clock() when ready}
local displays = {} -- [player] = {[uid] = model}
local displayFolder
local inventoryRemote

function MeteorService:AltarSlots(player)
	local slots = Game.World.AltarSlotsBase
	if services.PlayerService:HasPass(player, "ExtraAltar") then
		slots += 1
	end
	return slots
end

function MeteorService:Count(player)
	local data = services.DataService:Get(player)
	local n = 0
	if data then
		for _ in pairs(data.meteors) do
			n += 1
		end
	end
	return n
end

-- opts: { paid = bool, silent = bool }
function MeteorService:AddMeteor(player, typeId, mutation, opts)
	opts = opts or {}
	local data = services.DataService:Get(player)
	if not data or not Meteors.ByID[typeId] then
		return nil
	end
	if MeteorService:Count(player) >= Game.Economy.InventoryCap then
		Notify.Toast(player, "Deposito pieno! Vendi qualche meteorite.", "bad")
		return nil
	end
	local uid = tostring(player.UserId) .. "-" .. tostring(data.nextUid)
	data.nextUid += 1
	data.meteors[uid] = {
		t = typeId,
		m = mutation,
		g = 0,
		paid = opts.paid or nil,
		found = os.time(),
	}
	data.index[typeId] = true

	-- Auto-place on a free altar slot so new players see their meteor right away.
	MeteorService:PlaceOnAltar(player, uid, true)
	if not opts.silent then
		MeteorService:PushSnapshot(player)
	end
	return uid
end

-- Removes a meteor from the inventory and returns its record.
function MeteorService:TakeMeteor(player, uid)
	local data = services.DataService:Get(player)
	local m = data and data.meteors[uid]
	if not m then
		return nil
	end
	if m.altar then
		m.g = MeteorMath.GrowthSeconds(m, os.time())
		m.altar = nil
		m.placedAt = nil
	end
	data.meteors[uid] = nil
	if cooldowns[player] then
		cooldowns[player][uid] = nil
	end
	return m
end

-- Inserts an existing record (used by trading). Returns the new uid.
function MeteorService:GiveRecord(player, record)
	local data = services.DataService:Get(player)
	if not data then
		return nil
	end
	local uid = tostring(player.UserId) .. "-" .. tostring(data.nextUid)
	data.nextUid += 1
	record.altar = nil
	record.placedAt = nil
	data.meteors[uid] = record
	data.index[record.t] = true
	return uid
end

local function usedSlots(data)
	local used = {}
	for _, m in pairs(data.meteors) do
		if m.altar then
			used[m.altar] = true
		end
	end
	return used
end

function MeteorService:PlaceOnAltar(player, uid, silent)
	local data = services.DataService:Get(player)
	local m = data and data.meteors[uid]
	if not m or m.altar then
		return false
	end
	local used = usedSlots(data)
	for slot = 1, MeteorService:AltarSlots(player) do
		if not used[slot] then
			m.altar = slot
			m.placedAt = os.time()
			MeteorService:RefreshAltar(player)
			if not silent then
				MeteorService:PushSnapshot(player)
			end
			return true
		end
	end
	if not silent then
		Notify.Toast(player, "Altare pieno! Togli un meteorite o sblocca uno slot.", "bad")
	end
	return false
end

function MeteorService:RemoveFromAltar(player, uid)
	local data = services.DataService:Get(player)
	local m = data and data.meteors[uid]
	if not m or not m.altar then
		return false
	end
	if MeteorService:IsLaunching(player, uid) then
		return false
	end
	m.g = MeteorMath.GrowthSeconds(m, os.time())
	m.altar = nil
	m.placedAt = nil
	MeteorService:RefreshAltar(player)
	MeteorService:PushSnapshot(player)
	return true
end

function MeteorService:Sell(player, uid)
	local data = services.DataService:Get(player)
	local m = data and data.meteors[uid]
	if not m then
		return false
	end
	if m.paid then
		Notify.Toast(player, "Questo meteorite esclusivo non si può vendere", "bad")
		return false
	end
	if m.altar then
		Notify.Toast(player, "Togli prima il meteorite dall'altare", "bad")
		return false
	end
	local def = Meteors.ByID[m.t]
	local price = math.floor((def and def.sellPrice or 0) * Meteors.GetMutationMult(m.m))
	MeteorService:TakeMeteor(player, uid)
	services.PlayerService:AddShards(player, price, false)
	MeteorService:PushSnapshot(player)
	Notify.Toast(player, "Venduto per " .. price .. " Frammenti", "good")
	return true
end

-- Cooldowns ---------------------------------------------------------------

function MeteorService:IsReady(player, uid)
	local t = cooldowns[player]
	return not t or not t[uid] or os.clock() >= t[uid]
end

function MeteorService:SetCooldown(player, uid, seconds)
	cooldowns[player] = cooldowns[player] or {}
	cooldowns[player][uid] = os.clock() + seconds
	MeteorService:RefreshAltar(player)
	MeteorService:PushSnapshot(player)
	task.delay(seconds + 0.1, function()
		if player.Parent then
			MeteorService:RefreshAltar(player)
			MeteorService:PushSnapshot(player)
		end
	end)
end

function MeteorService:ClearCooldowns(player)
	cooldowns[player] = {}
	MeteorService:RefreshAltar(player)
	MeteorService:PushSnapshot(player)
end

function MeteorService:IsLaunching(player, uid)
	local launch = services.LaunchService and services.LaunchService:Current(player)
	return launch ~= nil and launch.uid == uid
end

-- Best meteor on the altar that is ready to be launched.
function MeteorService:BestReady(player)
	local data = services.DataService:Get(player)
	if not data then
		return nil
	end
	local now = os.time()
	local bestUid, bestDmg
	for uid, m in pairs(data.meteors) do
		if m.altar and MeteorService:IsReady(player, uid) then
			local dmg = MeteorMath.MeteorDamage(m, now)
			if not bestDmg or dmg > bestDmg then
				bestUid, bestDmg = uid, dmg
			end
		end
	end
	return bestUid
end

-- Client sync -------------------------------------------------------------

function MeteorService:Snapshot(player)
	local data = services.DataService:Get(player)
	if not data then
		return nil
	end
	local now = os.clock()
	local cd = {}
	for uid, readyAt in pairs(cooldowns[player] or {}) do
		if readyAt > now then
			cd[uid] = readyAt - now
		end
	end
	return {
		meteors = data.meteors,
		now = os.time(),
		altarSlots = MeteorService:AltarSlots(player),
		cooldowns = cd,
		index = data.index,
		indexSize = Meteors.IndexSize(),
		inventoryCap = Game.Economy.InventoryCap,
		tradeHistory = data.tradeHistory,
	}
end

function MeteorService:PushSnapshot(player)
	local snap = MeteorService:Snapshot(player)
	if snap then
		inventoryRemote:FireClient(player, snap)
	end
end

-- Altar display -----------------------------------------------------------

local function slotCFrame(altar, slot, slots)
	if altar.slots and altar.slots[slot] then
		return CFrame.new(altar.slots[slot].Position)
	end
	local a = (slot - 1) / slots * math.pi * 2
	local offset = Vector3.new(math.sin(a) * 5.5, 7, math.cos(a) * 5.5)
	return CFrame.new(altar.center.Position + offset)
end

local function bob(model, base)
	local core = model.PrimaryPart
	core.CFrame = base
	local tween = TweenService:Create(
		core,
		TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = base + Vector3.new(0, 1.2, 0) }
	)
	tween:Play()
end

local function expressionFor(player, uid, m, now)
	if not MeteorService:IsReady(player, uid) then
		return "dizzy"
	end
	return MeteorMath.Expression(m, now)
end

function MeteorService:RefreshAltar(player)
	local data = services.DataService:Get(player)
	local altar = services.WorldService:GetAltar(player)
	displays[player] = displays[player] or {}
	local shown = displays[player]
	if not data or not altar then
		return
	end
	local slots = MeteorService:AltarSlots(player)
	local now = os.time()

	-- Remove models for meteors no longer on the altar.
	for uid, model in pairs(shown) do
		local m = data.meteors[uid]
		if not m or not m.altar then
			model:Destroy()
			shown[uid] = nil
		end
	end

	for uid, m in pairs(data.meteors) do
		if m.altar then
			local model = shown[uid]
			local size = MeteorMath.DisplaySize(m, now)
			local expr = expressionFor(player, uid, m, now)
			if not model or model:GetAttribute("Slot") ~= m.altar or model:GetAttribute("Slots") ~= slots then
				if model then
					model:Destroy()
				end
				model = MeteorVisual.Build(m.t, { size = size, expression = expr, mutation = m.m })
				model:SetAttribute("Slot", m.altar)
				model:SetAttribute("Slots", slots)
				model:SetAttribute("OwnerUserId", player.UserId)
				model.Parent = displayFolder
				bob(model, slotCFrame(altar, m.altar, slots))
				shown[uid] = model
			else
				MeteorVisual.SetSize(model, size)
				MeteorVisual.SetExpression(model, expr)
			end
		end
	end
end

local function clearDisplays(player)
	for _, model in pairs(displays[player] or {}) do
		model:Destroy()
	end
	displays[player] = nil
end

-- Rebuilds the floating meteors (e.g. after the house model changed and slots moved).
function MeteorService:ResetAltarDisplay(player)
	clearDisplays(player)
	MeteorService:RefreshAltar(player)
end

function MeteorService:Init(s)
	services = s
	inventoryRemote = Remotes.Get("InventoryUpdate")
	displayFolder = Instance.new("Folder")
	displayFolder.Name = "AltarMeteors"
	displayFolder.Parent = workspace
end

function MeteorService:Start()
	services.DataService.PlayerLoaded:Connect(function(player, data)
		local altar = services.WorldService:AssignAltar(player)
		if not altar then
			Notify.Toast(player, "Nessun altare libero in questo server", "bad")
		else
			services.WorldService:UpdateHouse(player, data.evolution)
		end
		-- Every new god starts with one meteor so the first launch happens in minute one.
		if next(data.meteors) == nil then
			MeteorService:AddMeteor(player, "Sassolino", nil, { silent = true })
		end
		-- Meteors that were on slots no longer available (e.g. pass lost) go back to storage.
		local slots = MeteorService:AltarSlots(player)
		for _, m in pairs(data.meteors) do
			if m.altar and m.altar > slots then
				m.g = MeteorMath.GrowthSeconds(m, os.time())
				m.altar = nil
				m.placedAt = nil
			end
		end
		MeteorService:RefreshAltar(player)
		MeteorService:PushSnapshot(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		clearDisplays(player)
		cooldowns[player] = nil
	end)

	-- Grow the visible meteors over time.
	task.spawn(function()
		while true do
			task.wait(5)
			for player in pairs(displays) do
				if player.Parent then
					MeteorService:RefreshAltar(player)
				end
			end
		end
	end)

	Remotes.Get("PlaceOnAltar").OnServerEvent:Connect(function(player, uid)
		if typeof(uid) == "string" and RateLimit.Allow(player, "PlaceOnAltar", 0.15) then
			if services.TradeService:IsTrading(player) then
				Notify.Toast(player, "Non puoi spostare meteoriti durante uno scambio", "bad")
				return
			end
			MeteorService:PlaceOnAltar(player, uid, false)
		end
	end)
	Remotes.Get("RemoveFromAltar").OnServerEvent:Connect(function(player, uid)
		if typeof(uid) == "string" and RateLimit.Allow(player, "RemoveFromAltar", 0.15) then
			if services.TradeService:IsTrading(player) then
				return
			end
			MeteorService:RemoveFromAltar(player, uid)
		end
	end)
	Remotes.Get("SellMeteor").OnServerEvent:Connect(function(player, uid)
		if typeof(uid) == "string" and RateLimit.Allow(player, "SellMeteor", 0.15) then
			if services.TradeService:IsTrading(player) then
				Notify.Toast(player, "Non puoi vendere durante uno scambio", "bad")
				return
			end
			MeteorService:Sell(player, uid)
		end
	end)
	Remotes.Get("RequestSnapshot").OnServerInvoke = function(player)
		return MeteorService:Snapshot(player)
	end
end

return MeteorService
