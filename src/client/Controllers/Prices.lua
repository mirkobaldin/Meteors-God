-- Cached Robux prices and purchase prompts for passes and products (by config key).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage:WaitForChild("Shared").Config.Monetization)

local Prices = {}

local cache = {}

local function fetch(id, infoType)
	if id == 0 then
		return nil
	end
	if cache[id] ~= nil then
		return cache[id] or nil
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(id, infoType)
	end)
	cache[id] = (ok and info and info.PriceInRobux) or false
	return cache[id] or nil
end

function Prices.Product(key)
	local p = Monetization.Products[key]
	return p and fetch(p.id, Enum.InfoType.Product)
end

function Prices.Pass(key)
	local p = Monetization.GamePasses[key]
	return p and fetch(p.id, Enum.InfoType.GamePass)
end

-- "R$ 99", or "Presto" when the ID is not configured yet.
function Prices.ProductText(key)
	local p = Monetization.Products[key]
	if not p or p.id == 0 then
		return "Presto"
	end
	return "R$ " .. (Prices.Product(key) or "?")
end

function Prices.PassText(key)
	local p = Monetization.GamePasses[key]
	if not p or p.id == 0 then
		return "Presto"
	end
	if Players.LocalPlayer:GetAttribute("Pass_" .. key) then
		return "Posseduto"
	end
	return "R$ " .. (Prices.Pass(key) or "?")
end

function Prices.BuyProduct(key)
	local p = Monetization.Products[key]
	if p and p.id ~= 0 then
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, p.id)
	end
end

function Prices.BuyPass(key)
	local p = Monetization.GamePasses[key]
	if p and p.id ~= 0 and not Players.LocalPlayer:GetAttribute("Pass_" .. key) then
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, p.id)
	end
end

return Prices
