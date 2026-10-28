-- Meteor showers: baby meteors fall on the Citadel and the first player to grab them keeps them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local MeteorVisual = require(Shared.MeteorVisual)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local Notify = require(Server.Notify)

local ShowerService = {}

local services
local rng = Random.new()
local folder
local onGround = 0
local pickedRemote

local FALL_HEIGHT = 260
local FALL_TIME = 1.6

-- Random point on the Impact Field ring (uniform over the area).
local function randomGroundPoint()
	local field = services.WorldService.Field
	local inner, outer = field.inner + 6, field.outer - 6
	local dist = math.sqrt(rng:NextNumber() * (outer * outer - inner * inner) + inner * inner)
	local a = rng:NextNumber() * math.pi * 2
	return field.center + Vector3.new(math.sin(a) * dist, 2, math.cos(a) * dist)
end

local function impactFlash(position, color)
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Size = Vector3.new(0.3, 2, 2)
	ring.CFrame = CFrame.new(position - Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = folder
	local t = TweenService:Create(ring, TweenInfo.new(0.6), { Size = Vector3.new(0.3, 18, 18), Transparency = 1 })
	t:Play()
	t.Completed:Connect(function()
		ring:Destroy()
	end)
end

local function grab(player, model)
	if model:GetAttribute("Taken") then
		return
	end
	local data = services.DataService:Get(player)
	if not data then
		return
	end
	if services.MeteorService:Count(player) >= Game.InventoryCap(data) then
		Notify.Toast(player, "Storage full! Sell some meteors.", "bad")
		return
	end
	model:SetAttribute("Taken", true)

	local typeId = model:GetAttribute("MeteorType")
	local mutation = model:GetAttribute("Mutation")
	local upgraded = false

	-- Personal luck: chance to bump the meteor up one rarity.
	if rng:NextNumber() < Game.UpgradeEffect(data, "luck") then
		local def = Meteors.ByID[typeId]
		local nextRarity = def and Meteors.NextRarity(def.rarity)
		if nextRarity then
			typeId = Meteors.RandomTypeOfRarity(rng, nextRarity)
			upgraded = true
		end
	end

	model:Destroy()
	onGround -= 1

	local uid = services.MeteorService:AddMeteor(player, typeId, mutation)
	if not uid then
		return
	end
	pickedRemote:FireClient(player, { type = typeId, mutation = mutation, upgraded = upgraded })

	local def = Meteors.ByID[typeId]
	local rarity = Meteors.RarityByID[def.rarity]
	if rarity.order >= 5 or mutation == "Eclipsed" then
		local name = (mutation and (mutation .. " ") or "") .. def.id
		Notify.Announce(player.DisplayName .. " found a " .. name .. " (" .. def.rarity .. ")!", rarity.color)
	end
end

-- Spawns one falling meteor. luck >= 1 shifts the odds towards rarer meteors.
function ShowerService:SpawnOne(luck)
	if onGround >= Game.Cycle.MaxMeteorsOnGround then
		return
	end
	onGround += 1

	local rarityId = Meteors.RollRarity(rng, luck or 1)
	local typeId = Meteors.RandomTypeOfRarity(rng, rarityId)
	local mutation = Meteors.RollMutation(rng, luck or 1)
	local def = Meteors.ByID[typeId]
	local rarity = Meteors.RarityByID[rarityId]

	local ground = randomGroundPoint()
	local model = MeteorVisual.Build(typeId, { size = 3, expression = "sleepy", mutation = mutation })
	model:SetAttribute("Mutation", mutation)
	local core = model.PrimaryPart
	core.CFrame = CFrame.new(ground + Vector3.new(rng:NextNumber(-40, 40), FALL_HEIGHT, rng:NextNumber(-40, 40)))

	local trail = Instance.new("Trail")
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = core
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = core
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(def.fire[1], def.fire[2])
	trail.LightEmission = 1
	trail.Lifetime = 0.5
	trail.Transparency = NumberSequence.new(0, 1)
	trail.Parent = core

	model.Parent = folder

	-- Lands facing away from the field center, towards the players coming from the edges.
	local rest = ground + Vector3.new(0, 1.5, 0)
	local out = Vector3.new(rest.X - services.WorldService.Field.center.X, 0, rest.Z - services.WorldService.Field.center.Z)
	local landing = out.Magnitude > 1 and CFrame.lookAt(rest, rest + out) or CFrame.new(rest)
	local fall = TweenService:Create(core, TweenInfo.new(FALL_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = landing,
	})
	fall:Play()
	fall.Completed:Connect(function()
		if not model.Parent then
			return
		end
		impactFlash(ground, rarity.color)
		MeteorVisual.SetExpression(model, "happy")

		-- Rarity beacon so players can spot the good ones from far away.
		if rarity.order >= 3 then
			local beam = Instance.new("Part")
			beam.Name = "Beacon"
			beam.Anchored = true
			beam.CanCollide = false
			beam.CanQuery = false
			beam.CanTouch = false
			beam.Material = Enum.Material.Neon
			beam.Color = rarity.color
			beam.Transparency = 0.5
			beam.Size = Vector3.new(0.8, 60, 0.8)
			beam.CFrame = CFrame.new(ground + Vector3.new(0, 30, 0))
			beam.Parent = model
		end

		local tag = Instance.new("BillboardGui")
		tag.Size = UDim2.new(8, 0, 1.6, 0)
		tag.StudsOffset = Vector3.new(0, 3.2, 0)
		tag.LightInfluence = 0
		tag.MaxDistance = 90
		tag.Parent = core
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextStrokeTransparency = 0.3
		text.TextColor3 = rarity.color
		text.Text = (mutation and (mutation .. " ") or "") .. def.id
		text.Parent = tag

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Collect"
		prompt.ObjectText = def.id .. " (" .. def.rarity .. ")"
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = core
		prompt.Triggered:Connect(function(player)
			grab(player, model)
		end)

		task.delay(Game.Cycle.GroundMeteorLifetime, function()
			if model.Parent and not model:GetAttribute("Taken") then
				model:Destroy()
				onGround -= 1
			end
		end)
	end)
end

function ShowerService:SpawnBurst(count, luck)
	task.spawn(function()
		for _ = 1, count do
			ShowerService:SpawnOne(luck)
			task.wait(0.25)
		end
	end)
end

function ShowerService:Init(s)
	services = s
	folder = Instance.new("Folder")
	folder.Name = "ShowerMeteors"
	folder.Parent = workspace
	pickedRemote = Remotes.Get("MeteorPickedUp")
end

function ShowerService:Start()
	services.CycleService.PhaseChanged:Connect(function(phase, duration)
		if phase ~= "Shower" then
			return
		end
		task.spawn(function()
			local endsAt = os.clock() + duration
			while os.clock() < endsAt and services.CycleService.Phase == "Shower" do
				ShowerService:SpawnOne(1)
				task.wait(Game.Cycle.ShowerSpawnInterval)
			end
		end)
	end)
end

return ShowerService
