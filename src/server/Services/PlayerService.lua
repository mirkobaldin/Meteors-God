-- Divine Power (+1/s), currencies, evolutions, ascension, upgrades, passes and character looks.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Evolutions = require(Shared.Config.Evolutions)
local Monetization = require(Shared.Config.Monetization)
local MeteorMath = require(Shared.Util.MeteorMath)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)
local RateLimit = require(Server.RateLimit)
local EvolutionVisuals = require(Server.EvolutionVisuals)

local PlayerService = {}

local services
local passOwned = {} -- [player] = {[passKey] = true}
local loaded = {} -- [player] = true

function PlayerService:HasPass(player, key)
	return passOwned[player] ~= nil and passOwned[player][key] == true
end

function PlayerService:GrantPass(player, key)
	passOwned[player] = passOwned[player] or {}
	passOwned[player][key] = true
	player:SetAttribute("Pass_" .. key, true)
	if key == "VIP" then
		PlayerService:RefreshCharacter(player)
	elseif key == "ExtraAltar" then
		services.MeteorService:PushSnapshot(player)
		services.MeteorService:RefreshAltar(player)
	end
	PlayerService:Sync(player)
end

function PlayerService:PowerRate(player)
	local data = services.DataService:Get(player)
	if not data then
		return 0
	end
	local evo = Evolutions.Get(data.evolution)
	local rate = Game.Economy.BasePowerPerSecond * evo.mult
	rate *= 1 + Game.Economy.AscensionPowerBonus * data.ascensions
	rate *= 1 + MeteorMath.AltarPowerBonus(data.meteors, os.time())
	if PlayerService:HasPass(player, "Power2x") then
		rate *= 2
	end
	if PlayerService:HasPass(player, "VIP") then
		rate *= Game.Economy.VIPPowerMultiplier
	end
	if (data.boosts.power2xUntil or 0) > os.time() then
		rate *= 2
	end
	return rate
end

-- Adds shards (doubled by the pass when applyPass is true). Returns the amount added.
function PlayerService:AddShards(player, amount, applyPass)
	local data = services.DataService:Get(player)
	if not data then
		return 0
	end
	if applyPass and PlayerService:HasPass(player, "Shards2x") then
		amount *= 2
	end
	amount = math.floor(amount)
	data.shards += amount
	PlayerService:Sync(player)
	return amount
end

function PlayerService:AddPower(player, amount)
	local data = services.DataService:Get(player)
	if data then
		data.power += amount
		PlayerService:Sync(player)
	end
end

function PlayerService:AddBoost(player, seconds)
	local data = services.DataService:Get(player)
	if data then
		data.boosts.power2xUntil = math.max(data.boosts.power2xUntil or 0, os.time()) + seconds
		PlayerService:Sync(player)
	end
end

function PlayerService:Sync(player)
	local data = services.DataService:Get(player)
	if not data then
		return
	end
	player:SetAttribute("Power", data.power)
	player:SetAttribute("PowerRate", PlayerService:PowerRate(player))
	player:SetAttribute("Shards", data.shards)
	player:SetAttribute("Evolution", data.evolution)
	player:SetAttribute("Ascensions", data.ascensions)
	player:SetAttribute("Planets", data.planetsDestroyed)
	player:SetAttribute("TotalDamage", data.totalDamage)
	player:SetAttribute("Boost2xUntil", data.boosts.power2xUntil or 0)
	player:SetAttribute("StarterPackBought", data.starterPackBought)
	for _, u in ipairs(Game.Upgrades) do
		player:SetAttribute("Upgrade_" .. u.id, data.upgrades[u.id] or 0)
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Potere.Value = Format.Number(data.power)
		ls.Pianeti.Value = data.planetsDestroyed
	end
end

function PlayerService:RefreshCharacter(player)
	local data = services.DataService:Get(player)
	local character = player.Character
	if not data or not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16 + 2 * (data.upgrades.speed or 0)
	end
	EvolutionVisuals.Apply(character, data.evolution, PlayerService:HasPass(player, "VIP"))
end

function PlayerService:Evolve(player, force)
	local data = services.DataService:Get(player)
	if not data or data.evolution >= Evolutions.Max() then
		return false
	end
	local nextEvo = Evolutions.Get(data.evolution + 1)
	if not force and (data.power < nextEvo.power or data.planetsDestroyed < nextEvo.planets) then
		Notify.Toast(player, "Non hai ancora i requisiti per evolverti", "bad")
		return false
	end
	data.evolution += 1
	PlayerService:RefreshCharacter(player)
	PlayerService:Sync(player)
	Notify.Toast(player, "Ti sei evoluto in " .. nextEvo.name .. "!", "good")
	if data.evolution >= 4 then
		Notify.Announce(player.DisplayName .. " è diventato " .. nextEvo.name .. "!", nextEvo.aura)
	end
	return true
end

function PlayerService:Ascend(player)
	local data = services.DataService:Get(player)
	if not data then
		return false
	end
	if data.evolution < Evolutions.AscensionMinEvolution then
		Notify.Toast(player, "Serve almeno l'Evoluzione " .. Evolutions.AscensionMinEvolution, "bad")
		return false
	end
	data.power = 0
	data.evolution = 1
	data.ascensions += 1
	PlayerService:RefreshCharacter(player)
	PlayerService:Sync(player)
	Notify.Announce(
		player.DisplayName .. " è ASCESO! (Ascensione " .. data.ascensions .. ")",
		Color3.fromRGB(255, 120, 220)
	)
	return true
end

function PlayerService:BuyUpgrade(player, upgradeId)
	local data = services.DataService:Get(player)
	if not data or not Game.UpgradeByID[upgradeId] then
		return false
	end
	local level = data.upgrades[upgradeId] or 0
	local cost = Game.UpgradeCost(upgradeId, level)
	if not cost then
		Notify.Toast(player, "Livello massimo raggiunto", "info")
		return false
	end
	if data.shards < cost then
		Notify.Toast(player, "Frammenti insufficienti", "bad")
		return false
	end
	data.shards -= cost
	data.upgrades[upgradeId] = level + 1
	if upgradeId == "speed" then
		PlayerService:RefreshCharacter(player)
	end
	PlayerService:Sync(player)
	return true
end

local function checkPasses(player)
	passOwned[player] = passOwned[player] or {}
	for key, pass in pairs(Monetization.GamePasses) do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns then
				passOwned[player][key] = true
				player:SetAttribute("Pass_" .. key, true)
			end
		end
	end
end

local function onLoaded(player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local power = Instance.new("StringValue")
	power.Name = "Potere"
	power.Parent = ls
	local planets = Instance.new("IntValue")
	planets.Name = "Pianeti"
	planets.Parent = ls
	ls.Parent = player

	checkPasses(player)
	loaded[player] = true

	-- Offline growth: meteors on the altar keep growing via timestamps (see MeteorMath).
	data.lastSeen = os.time()
	PlayerService:Sync(player)

	local function onCharacter(character)
		local start = os.clock()
		while not player:HasAppearanceLoaded() and os.clock() - start < 5 do
			task.wait(0.1)
		end
		character:WaitForChild("HumanoidRootPart", 5)
		if player.Character == character then
			PlayerService:RefreshCharacter(player)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player:SetAttribute("DataLoaded", true)
end

function PlayerService:Init(s)
	services = s
end

function PlayerService:Start()
	services.DataService.PlayerLoaded:Connect(onLoaded)

	Players.PlayerRemoving:Connect(function(player)
		passOwned[player] = nil
		loaded[player] = nil
	end)

	-- The +1 heartbeat.
	task.spawn(function()
		while true do
			task.wait(1)
			for player in pairs(loaded) do
				local data = services.DataService:Get(player)
				if data then
					data.power += PlayerService:PowerRate(player)
					PlayerService:Sync(player)
				end
			end
		end
	end)

	Remotes.Get("Evolve").OnServerEvent:Connect(function(player)
		if RateLimit.Allow(player, "Evolve", 0.5) then
			PlayerService:Evolve(player, false)
		end
	end)
	Remotes.Get("Ascend").OnServerEvent:Connect(function(player)
		if RateLimit.Allow(player, "Ascend", 2) then
			PlayerService:Ascend(player)
		end
	end)
	Remotes.Get("BuyUpgrade").OnServerEvent:Connect(function(player, upgradeId)
		if typeof(upgradeId) == "string" and RateLimit.Allow(player, "BuyUpgrade", 0.2) then
			PlayerService:BuyUpgrade(player, upgradeId)
		end
	end)
end

return PlayerService
