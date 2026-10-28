-- Game Passes and Developer Products (ProcessReceipt with purchase de-duplication).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monetization = require(Shared.Config.Monetization)
local Evolutions = require(Shared.Config.Evolutions)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)

local ShopService = {}

local services
local RECEIPT_HISTORY = 50

-- Each handler grants the product to the player. Return false to retry later.
local handlers = {}

handlers.StarterPack = function(player, data)
	local cfg = Monetization.StarterPack
	if data.starterPackBought then
		-- Bought twice (e.g. two prompts at once): give the shard value instead.
		services.PlayerService:AddShards(player, cfg.shards * 2, false)
		return true
	end
	data.starterPackBought = true
	services.MeteorService:AddMeteor(player, cfg.meteor, nil, { paid = true })
	services.PlayerService:AddShards(player, cfg.shards, false)
	services.PlayerService:AddBoost(player, cfg.boostSeconds)
	Notify.Toast(player, "Starter Pack ricevuto! Benvenuto tra gli dei.", "good")
	return true
end

local function powerPack(key)
	return function(player)
		local seconds = Monetization.PowerPackSeconds[key]
		local amount = math.max(100, services.PlayerService:PowerRate(player) * seconds)
		services.PlayerService:AddPower(player, amount)
		Notify.Toast(player, "Potere aggiunto!", "good")
		return true
	end
end
handlers.PowerS = powerPack("PowerS")
handlers.PowerM = powerPack("PowerM")
handlers.PowerL = powerPack("PowerL")

handlers.Boost2x = function(player)
	services.PlayerService:AddBoost(player, Monetization.Boost2xSeconds)
	Notify.Toast(player, "Boost 2x Potere attivo!", "good")
	return true
end

handlers.DivineWrath = function(player)
	local now = workspace:GetServerTimeNow()
	local current = math.max(workspace:GetAttribute("WrathUntil") or 0, now)
	workspace:SetAttribute("WrathUntil", current + Monetization.DivineWrathSeconds)
	Notify.Announce("⚡ " .. player.DisplayName .. " ha scatenato l'IRA DIVINA! Danno x3 per tutti!", Color3.fromRGB(255, 80, 80))
	return true
end

handlers.LegendaryPlanet = function(player)
	Notify.Announce("⭐ " .. player.DisplayName .. " ha evocato un PIANETA LEGGENDARIO!", Color3.fromRGB(255, 210, 60))
	services.PlanetService:SummonLegendary()
	return true
end

handlers.InstantRecharge = function(player)
	services.MeteorService:ClearCooldowns(player)
	Notify.Toast(player, "Meteoriti ricaricati!", "good")
	return true
end

handlers.EvolveNow = function(player, data)
	if data.evolution >= Evolutions.Max() then
		services.PlayerService:AddPower(player, services.PlayerService:PowerRate(player) * 3600)
		Notify.Toast(player, "Sei già al massimo: ricevi 1 ora di Potere", "good")
		return true
	end
	return services.PlayerService:Evolve(player, true)
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = services.DataService:Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	for _, id in ipairs(data.receipts) do
		if id == receipt.PurchaseId then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	local key = Monetization.ProductKeyById(receipt.ProductId)
	local handler = key and handlers[key]
	if not handler then
		warn("[ShopService] unknown product", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, granted = pcall(handler, player, data)
	if not ok or granted == false then
		warn("[ShopService] grant failed", key, granted)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	table.insert(data.receipts, receipt.PurchaseId)
	while #data.receipts > RECEIPT_HISTORY do
		table.remove(data.receipts, 1)
	end
	services.DataService:Save(player, false)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ShopService:Init(s)
	services = s
end

function ShopService:Start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local key = Monetization.PassKeyById(passId)
		if key then
			services.PlayerService:GrantPass(player, key)
			Notify.Toast(player, "Grazie! " .. Monetization.GamePasses[key].name .. " attivo.", "good")
		end
	end)
end

return ShopService
