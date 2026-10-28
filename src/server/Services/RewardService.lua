-- Daily calendar, playtime gift and codes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rewards = require(Shared.Config.Rewards)
local Meteors = require(Shared.Config.Meteors)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)
local RateLimit = require(Server.RateLimit)

local RewardService = {}

local services
local rng = Random.new()

local function sync(player)
	local data = services.DataService:Get(player)
	if not data then
		return
	end
	player:SetAttribute("DailyStreak", data.daily.streak)
	player:SetAttribute("DailyAvailable", Rewards.Today() > data.daily.lastDay)
end

-- Applies one reward table. Returns a short description.
local function grant(player, reward)
	local data = services.DataService:Get(player)
	local parts = {}
	if reward.kind == "shards" or reward.amount then
		local n = services.PlayerService:AddShards(player, reward.amount or 0, false)
		table.insert(parts, "+" .. Format.Number(n) .. " Shards")
	end
	if reward.shards then
		local n = services.PlayerService:AddShards(player, reward.shards, false)
		table.insert(parts, "+" .. Format.Number(n) .. " Shards")
	end
	local powerSeconds = reward.kind == "power" and reward.seconds or reward.powerSeconds
	if powerSeconds then
		local amount = math.max(100, services.PlayerService:PowerRate(player) * powerSeconds)
		services.PlayerService:AddPower(player, amount)
		table.insert(parts, "+" .. Format.Number(amount) .. " Power")
	end
	local boostSeconds = reward.kind == "boost" and reward.seconds or reward.boostSeconds
	if boostSeconds then
		services.PlayerService:AddBoost(player, boostSeconds)
		table.insert(parts, "2x Power Boost")
	end
	local rarity = reward.kind == "meteor" and reward.rarity or reward.meteorRarity
	if rarity and data then
		local typeId = Meteors.RandomTypeOfRarity(rng, rarity)
		if services.MeteorService:AddMeteor(player, typeId, nil) then
			table.insert(parts, typeId .. " (" .. rarity .. ")")
		end
	end
	return table.concat(parts, ", ")
end

local function claimDaily(player)
	local data = services.DataService:Get(player)
	if not data then
		return
	end
	local today = Rewards.Today()
	if today <= data.daily.lastDay then
		Notify.Toast(player, "You already claimed today's reward. Come back tomorrow!", "info")
		return
	end
	local index = (data.daily.streak % #Rewards.Daily) + 1
	local text = grant(player, Rewards.Daily[index])
	data.daily.streak += 1
	data.daily.lastDay = today
	sync(player)
	Notify.Toast(player, "Day " .. index .. ": " .. text, "good")
end

local giftReadyAt = {} -- [player] = server time

local function resetGift(player)
	giftReadyAt[player] = workspace:GetServerTimeNow() + Rewards.GiftInterval
	player:SetAttribute("GiftReadyAt", giftReadyAt[player])
end

local function claimGift(player)
	local data = services.DataService:Get(player)
	if not data or not giftReadyAt[player] then
		return
	end
	if workspace:GetServerTimeNow() < giftReadyAt[player] then
		return
	end
	local shards = Rewards.GiftShards(data.evolution, data.ascensions)
	local n = services.PlayerService:AddShards(player, shards, true)
	resetGift(player)
	Notify.Toast(player, "Gift: +" .. Format.Number(n) .. " Shards!", "good")
end

local function redeemCode(player, code)
	local data = services.DataService:Get(player)
	if not data or typeof(code) ~= "string" or #code > 40 then
		return
	end
	code = string.upper((code:gsub("%s+", "")))
	local reward = Rewards.Codes[code]
	if not reward then
		Notify.Toast(player, "Invalid code", "bad")
		return
	end
	if data.codes[code] then
		Notify.Toast(player, "You already used this code", "info")
		return
	end
	data.codes[code] = true
	local text = grant(player, reward)
	Notify.Toast(player, "Code redeemed: " .. text, "good")
end

function RewardService:Init(s)
	services = s
end

function RewardService:Start()
	services.DataService.PlayerLoaded:Connect(function(player)
		sync(player)
		resetGift(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		giftReadyAt[player] = nil
	end)

	-- Day rollover for players who stay online past midnight UTC.
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in ipairs(Players:GetPlayers()) do
				sync(player)
			end
		end
	end)

	Remotes.Get("ClaimDaily").OnServerEvent:Connect(function(player)
		if RateLimit.Allow(player, "ClaimDaily", 1) then
			claimDaily(player)
		end
	end)
	Remotes.Get("ClaimGift").OnServerEvent:Connect(function(player)
		if RateLimit.Allow(player, "ClaimGift", 1) then
			claimGift(player)
		end
	end)
	Remotes.Get("RedeemCode").OnServerEvent:Connect(function(player, code)
		if RateLimit.Allow(player, "RedeemCode", 2) then
			redeemCode(player, code)
		end
	end)
end

return RewardService
