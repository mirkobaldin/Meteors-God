-- Server entry point: requires every service, then runs Init (setup) and Start (connections, loops).

local Services = script.Parent:WaitForChild("Services")

local ORDER = {
	"DataService",
	"WorldService",
	"PlayerService",
	"MeteorService",
	"CycleService",
	"ShowerService",
	"PlanetService",
	"LaunchService",
	"ShopService",
	"TradeService",
}

local services = {}
for _, name in ipairs(ORDER) do
	services[name] = require(Services:WaitForChild(name))
end

for _, name in ipairs(ORDER) do
	local service = services[name]
	if service.Init then
		service:Init(services)
	end
end

for _, name in ipairs(ORDER) do
	local service = services[name]
	if service.Start then
		task.spawn(function()
			service:Start()
		end)
	end
end

print("[MeteorGods] server started")
