-- Client entry point: builds every controller (Init) then starts them (Start).

local Controllers = script.Parent:WaitForChild("Controllers")

local ORDER = {
	"State",
	"Notifications",
	"FX",
	"Pets",
	"MeteorAnim",
	"HUD",
	"Inventory",
	"Evolution",
	"Upgrades",
	"Shop",
	"Fusion",
	"House",
	"Daily",
	"Menu",
	"Index",
	"Trade",
	"Launch",
	"Hunt",
}

local controllers = {}
for _, name in ipairs(ORDER) do
	controllers[name] = require(Controllers:WaitForChild(name))
end

for _, name in ipairs(ORDER) do
	local c = controllers[name]
	if c.Init then
		c:Init(controllers)
	end
end

for _, name in ipairs(ORDER) do
	local c = controllers[name]
	if c.Start then
		task.spawn(function()
			c:Start()
		end)
	end
end
