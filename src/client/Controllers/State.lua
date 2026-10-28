-- Client-side store for the latest inventory snapshot pushed by the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local State = {}

State.Snapshot = nil
State.ReceivedAt = 0 -- os.clock() when the snapshot arrived

local changed = Instance.new("BindableEvent")
State.Changed = changed.Event

-- Server time (os.time based) adjusted for the time passed since the snapshot.
function State.Now()
	if not State.Snapshot then
		return os.time()
	end
	return State.Snapshot.now + (os.clock() - State.ReceivedAt)
end

function State.CooldownLeft(uid)
	local s = State.Snapshot
	local cd = s and s.cooldowns and s.cooldowns[uid]
	if not cd then
		return 0
	end
	return math.max(0, cd - (os.clock() - State.ReceivedAt))
end

local function set(snapshot)
	if snapshot then
		State.Snapshot = snapshot
		State.ReceivedAt = os.clock()
		changed:Fire(snapshot)
	end
end

function State:Init() end

function State:Start()
	Remotes.Get("InventoryUpdate").OnClientEvent:Connect(set)
	task.spawn(function()
		local ok, snap = pcall(function()
			return Remotes.Get("RequestSnapshot"):InvokeServer()
		end)
		if ok and snap and not State.Snapshot then
			set(snap)
		end
	end)
end

return State
