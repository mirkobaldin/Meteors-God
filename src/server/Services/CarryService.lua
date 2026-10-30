-- Carrying meteors home: a meteor grabbed from the field is not yours yet. It floats above your head
-- and becomes yours only when you bring it back to your own plot (Comet Islet or House Island).
-- A weapon hit knocks one out (WeaponService), dying drops them all, leaving the game loses them.
-- Replicated to the client through player attributes: Carrying, CarryCap, PlotPosition.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local MeteorVisual = require(Shared.MeteorVisual)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)

local CarryService = {}

local services
local rng = Random.new()
local carried = {} -- [player] = { {t, m, upgraded, model} }
local pickedRemote

local C = Game.Carry
local CARRY_SIZE = 2.2

function CarryService:Capacity(player)
	local cap = C.Base
	if services.PlayerService:HasPass(player, "BigBag") then
		cap += C.BigBagBonus
	end
	return cap
end

function CarryService:Count(player)
	return carried[player] and #carried[player] or 0
end

function CarryService:IsFull(player)
	return CarryService:Count(player) >= CarryService:Capacity(player)
end

-- Walk speed multiplier (PlayerService:RefreshCharacter).
function CarryService:SpeedMult(player)
	return math.max(C.MinSpeedMult, 1 - C.SpeedPenalty * CarryService:Count(player))
end

local function sync(player)
	player:SetAttribute("Carrying", CarryService:Count(player))
	player:SetAttribute("CarryCap", CarryService:Capacity(player))
	services.PlayerService:UpdateSpeed(player)
end

-- The carried meteors float in a stack above the head.
local function attach(player, entry, index)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local model = MeteorVisual.Build(entry.t, { size = CARRY_SIZE, expression = "happy", mutation = entry.m, anchored = false })
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = true
		end
	end
	model.Name = "Carried"
	model:PivotTo(head.CFrame * CFrame.new(0, 2.6 + (index - 1) * (CARRY_SIZE + 0.4), 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	model.Parent = character
	entry.model = model
end

local function relayout(player)
	for i, entry in ipairs(carried[player] or {}) do
		if entry.model then
			entry.model:Destroy()
			entry.model = nil
		end
		attach(player, entry, i)
	end
end

-- Called by ShowerService when a meteor is collected. Returns false if the hands are full.
function CarryService:Add(player, typeId, mutation, upgraded)
	if not Meteors.ByID[typeId] then
		return false
	end
	carried[player] = carried[player] or {}
	if CarryService:IsFull(player) then
		return false
	end
	local entry = { t = typeId, m = mutation, upgraded = upgraded }
	table.insert(carried[player], entry)
	attach(player, entry, #carried[player])
	sync(player)
	return true
end

-- Takes one carried meteor (random) out of the player and drops it at `position`. Returns its type.
function CarryService:DropOne(player, position)
	local list = carried[player]
	if not list or #list == 0 then
		return nil
	end
	local entry = table.remove(list, rng:NextInteger(1, #list))
	if entry.model then
		entry.model:Destroy()
	end
	services.ShowerService:Drop(entry.t, entry.m, position)
	relayout(player)
	sync(player)
	return entry.t
end

function CarryService:DropAll(player, position)
	while CarryService:Count(player) > 0 do
		CarryService:DropOne(player, position + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4)))
	end
end

-- Is `position` on the player's own plot?
local function atHome(player, position)
	local altar = services.WorldService:GetAltar(player)
	if not altar then
		return false
	end
	local function inside(center, radius)
		local flat = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
		return flat.Magnitude <= radius + C.BankMargin and position.Y > center.Y - 30
	end
	return inside(altar.display.Position, Game.World.CometIsletRadius)
		or inside(altar.center.Position, altar.islandRadius or Game.World.HouseIslandRadius)
end

-- Home: every carried meteor becomes yours.
local lastFullToast = {}
local function bank(player)
	local data = services.DataService:Get(player)
	if not data or services.MeteorService:Count(player) >= Game.InventoryCap(data) then
		-- Storage full: they stay in your hands (warn now and then, not every tick).
		if os.clock() - (lastFullToast[player] or 0) > 8 then
			lastFullToast[player] = os.clock()
			Notify.Toast(player, "Storage full! Sell some meteors to keep the ones you carry.", "bad")
		end
		return
	end
	local list = carried[player]
	carried[player] = {}
	for _, entry in ipairs(list) do
		if entry.model then
			entry.model:Destroy()
		end
		local uid = services.MeteorService:AddMeteor(player, entry.t, entry.m)
		if uid then
			pickedRemote:FireClient(player, { type = entry.t, mutation = entry.m, upgraded = entry.upgraded })
			local def = Meteors.ByID[entry.t]
			local rarity = Meteors.RarityByID[def.rarity]
			if rarity.order >= 4 or entry.m == "Eclipsed" then
				local name = (entry.m and (entry.m .. " ") or "") .. def.id
				Notify.Chat(player.DisplayName .. " brought home a " .. name .. " (" .. def.rarity .. ")!", rarity.color)
			end
		else
			-- Storage full: it stays in your hands.
			entry.model = nil
			table.insert(carried[player], entry)
		end
	end
	relayout(player)
	sync(player)
end

function CarryService:Init(s)
	services = s
	pickedRemote = Remotes.Get("MeteorPickedUp")
end

function CarryService:Start()
	services.DataService.PlayerLoaded:Connect(function(player)
		carried[player] = {}
		sync(player)
		local function hook(character)
			-- Dying drops everything you carried where you fell (into the void: lost).
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid then
				humanoid.Died:Connect(function()
					local root = character:FindFirstChild("HumanoidRootPart")
					if root and root.Position.Y > -200 then
						CarryService:DropAll(player, root.Position)
					else
						carried[player] = {}
						sync(player)
					end
				end)
			end
			task.wait(0.5)
			relayout(player)
			sync(player)
		end
		player.CharacterAdded:Connect(hook)
		if player.Character then
			task.spawn(hook, player.Character)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		carried[player] = nil
		lastFullToast[player] = nil
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		for player, list in pairs(carried) do
			if #list > 0 then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and atHome(player, root.Position) then
					bank(player)
				end
			end
		end
	end)
end

return CarryService
