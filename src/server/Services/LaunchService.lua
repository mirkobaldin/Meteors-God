-- Server side of the launch: validates the pad, picks the meteor, holds it above the player's
-- head (visible to everyone), then on release resolves where the aimed throw lands, tells the
-- other clients to animate the flight and applies the hit when the meteor arrives.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local Planets = require(Shared.Config.Planets)
local Evolutions = require(Shared.Config.Evolutions)
local MeteorMath = require(Shared.Util.MeteorMath)
local PlanetMath = require(Shared.Util.PlanetMath)
local MeteorVisual = require(Shared.MeteorVisual)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local RateLimit = require(Server.RateLimit)
local Poses = require(Server.Poses)

local LaunchService = {}

local services
local active = {} -- [player] = {uid, startedAt, model, fired}
local resultRemote
local launchFxRemote

local L = Game.Launch
local rng = Random.new()

local function setAuraBoost(player, boosted)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local att = root and root:FindFirstChild("AuraAttachment")
	local aura = att and att:FindFirstChild("Aura")
	if aura then
		if boosted then
			aura:SetAttribute("BaseRate", aura:GetAttribute("BaseRate") or aura.Rate)
			aura.Rate = (aura:GetAttribute("BaseRate") or 10) * 6
			aura.Speed = NumberRange.new(4, 9)
		else
			aura.Rate = aura:GetAttribute("BaseRate") or aura.Rate
			aura.Speed = NumberRange.new(1, 3)
		end
	end
end

local function cleanup(player, cooldownSeconds)
	local a = active[player]
	if not a then
		return
	end
	active[player] = nil
	if a.model and a.model.Parent then
		a.model:Destroy()
	end
	setAuraBoost(player, false)
	Poses.Reset(player.Character)
	if cooldownSeconds then
		services.MeteorService:SetCooldown(player, a.uid, cooldownSeconds)
	end
end

function LaunchService:Current(player)
	return active[player]
end

local function wrathActive()
	return (workspace:GetAttribute("WrathUntil") or 0) > workspace:GetServerTimeNow()
end

local function computeDamage(player, meteor, charge, crit)
	local data = services.DataService:Get(player)
	local evo = Evolutions.Get(data.evolution)
	local dmg = MeteorMath.MeteorDamage(meteor, os.time())
	dmg *= 0.5 + charge
	if crit then
		local def = Meteors.ByID[meteor.t]
		local boost = def and def.ability and def.ability.kind == "critBoost" and def.ability.value or 0
		dmg *= L.CritMultiplier + Game.UpgradeEffect(data, "crit") + boost
	end
	dmg *= MeteorMath.PowerMultiplier(data.power)
	dmg *= 1 + Game.UpgradeEffect(data, "power")
	dmg *= evo.mult
	if wrathActive() then
		dmg *= L.WrathMultiplier
	end
	return math.floor(dmg)
end

-- Damage of a meteor thrown by this player (used by the Cosmic Hunt too).
function LaunchService:Damage(player, meteor, charge, crit)
	return computeDamage(player, meteor, charge, crit)
end

local function beginLaunch(player, padName)
	if not RateLimit.Allow(player, "BeginLaunch", 0.3) then
		return { ok = false }
	end
	if active[player] then
		return { ok = false, reason = "You're already throwing!" }
	end
	local data = services.DataService:Get(player)
	if not data then
		return { ok = false, reason = "Loading data..." }
	end
	if not services.CycleService:IsBombard() then
		return { ok = false, reason = "Wait for the Bombardment to throw!" }
	end
	if services.TradeService:IsTrading(player) then
		return { ok = false, reason = "Close the trade before throwing" }
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return { ok = false }
	end
	-- The client says which pad it lifted off from; accept it if the player is near it (the
	-- position the server sees can lag behind the client's).
	local pad = typeof(padName) == "string" and services.WorldService:PadNamed(padName, root.Position)
		or services.WorldService:PadAt(root.Position)
	if not pad then
		return { ok = false, reason = "Go to a LAUNCH pad at the end of the bridge" }
	end
	local tierDef = Planets.Tiers[pad.tier]
	if data.evolution < tierDef.requiredEvolution then
		return { ok = false, reason = tierDef.name .. " requires " .. Evolutions.Get(tierDef.requiredEvolution).name .. "!" }
	end
	if not services.PlanetService:IsTargetable(pad.tier) then
		return { ok = false, reason = "The planet is coming through the rift..." }
	end
	local uid = services.MeteorService:BestReady(player)
	if not uid then
		return { ok = false, reason = "No meteor ready! Wait for the recharge or collect more." }
	end
	local meteor = data.meteors[uid]
	local size = MeteorMath.LaunchSize(meteor, os.time())

	local model = MeteorVisual.Build(meteor.t, {
		size = size,
		expression = "furious",
		mutation = meteor.m,
		anchored = false,
	})
	local core = model.PrimaryPart
	core.Massless = true
	-- Facing backwards: the camera is behind the player, so the meteor looks at you.
	core.CFrame = root.CFrame * CFrame.new(0, 4 + size / 2, 0) * CFrame.Angles(0, math.pi, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "HoldWeld"
	weld.Part0 = root
	weld.Part1 = core
	weld.Parent = core
	model.Name = "Launch_" .. player.Name
	model.Parent = workspace

	-- The golden (critical) zone of the charge ring moves every throw and is narrow.
	local critFrom = rng:NextNumber(L.CritZoneMin, L.CritZoneMax - L.CritWindow)
	active[player] = {
		uid = uid,
		startedAt = os.clock(),
		model = model,
		fired = false,
		size = size,
		tier = pad.tier,
		critFrom = critFrom,
		critTo = critFrom + L.CritWindow,
	}
	services.MeteorService:SetCooldown(player, uid, L.MaxHoldTime + L.FlightMax + 5)
	setAuraBoost(player, true)
	Poses.Set(character, "charge", 0.25)

	local myLaunch = active[player]
	task.delay(L.MaxHoldTime + 1, function()
		if active[player] == myLaunch and not myLaunch.fired then
			cleanup(player, 1)
		end
	end)

	return {
		ok = true,
		meteorType = meteor.t,
		mutation = meteor.m,
		size = size,
		returnCFrame = pad.returnCFrame,
		tier = pad.tier,
		critFrom = critFrom,
		critTo = critFrom + L.CritWindow,
	}
end

local function isFiniteVector(v)
	return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z and v.Magnitude < 1e6
end

local function fireLaunch(player, charge, aim)
	local a = active[player]
	if not a or a.fired then
		return
	end
	if typeof(charge) ~= "number" or charge ~= charge then
		charge = 0.5
	end
	charge = math.clamp(charge, 0, 1)
	if os.clock() - a.startedAt < L.MinChargeTime then
		charge = math.min(charge, 0.3)
	end
	local data = services.DataService:Get(player)
	local meteor = data and data.meteors[a.uid]
	local core = a.model and a.model.PrimaryPart
	if not meteor or not core then
		cleanup(player, nil)
		return
	end
	a.fired = true

	local origin = core.Position
	if not isFiniteVector(aim) then
		aim = Planets.Tiers[a.tier].position
	end
	local crit = charge >= a.critFrom - 0.01 and charge <= a.critTo + 0.01 and os.clock() - a.startedAt >= L.MinChargeTime
	local damage = computeDamage(player, meteor, charge, crit)
	local def = Meteors.ByID[meteor.t]
	local color = def and def.fire[1] or Color3.new(1, 1, 1)
	local impact, normal = services.PlanetService:ResolveImpact(a.tier, origin, aim)
	local flightTime = PlanetMath.FlightTime((impact - origin).Magnitude)

	-- The flight itself is animated by each client; the server only keeps time.
	a.model:Destroy()
	setAuraBoost(player, false)
	Poses.Set(player.Character, "throw", 0.08)
	task.delay(0.35, function()
		Poses.Reset(player.Character, 0.3)
	end)

	resultRemote:FireClient(player, {
		impact = impact,
		normal = normal,
		flightTime = flightTime,
		damage = damage,
		crit = crit,
	})
	local fx = {
		thrower = player.UserId,
		from = origin,
		to = impact,
		flightTime = flightTime,
		meteorType = meteor.t,
		mutation = meteor.m,
		size = a.size,
		tier = a.tier,
	}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			launchFxRemote:FireClient(other, fx)
		end
	end
	local ability = def and def.ability
	local function abilityValue(kind)
		return ability and ability.kind == kind and ability.value or 0
	end
	services.MeteorService:SetCooldown(player, a.uid, flightTime + MeteorMath.Cooldown(data) * (1 - abilityValue("recharge")))

	local function reward(dealt)
		local d = services.DataService:Get(player)
		if d and dealt > 0 then
			d.totalDamage += dealt
			local mult = (1 + Game.UpgradeEffect(d, "greed")) * (1 + abilityValue("shards"))
			services.PlayerService:AddShards(player, dealt * Game.Economy.ShardsPerDamage * mult, true)
		end
	end

	task.delay(flightTime, function()
		local planet = services.PlanetService
		local dealt = planet:ApplyHit(a.tier, player, damage, impact, normal, crit, color, meteor.t)
		if active[player] == a then
			active[player] = nil
		end
		reward(dealt)
		if dealt <= 0 or not ability then
			return
		end
		-- The meteor's special ability.
		if ability.kind == "mark" then
			planet:Mark(a.tier, ability.value, 8, ability.name)
		elseif ability.kind == "chain" then
			task.delay(0.35, function()
				reward(planet:ApplyBonus(a.tier, player, damage * ability.value, impact, normal, ability.name, color))
			end)
		elseif ability.kind == "burn" then
			for k = 1, 5 do
				task.delay(k * 0.6, function()
					reward(planet:ApplyBonus(a.tier, player, damage * ability.value / 5, impact, normal, ability.name, color))
				end)
			end
		end
	end)
end

function LaunchService:Init(s)
	services = s
	resultRemote = Remotes.Get("LaunchResult")
	launchFxRemote = Remotes.Get("LaunchFX")
end

function LaunchService:Start()
	Remotes.Get("BeginLaunch").OnServerInvoke = beginLaunch
	Remotes.Get("FireLaunch").OnServerEvent:Connect(fireLaunch)
	Remotes.Get("CancelLaunch").OnServerEvent:Connect(function(player)
		local a = active[player]
		if a and not a.fired then
			cleanup(player, 1)
		end
	end)

	local function watch(player)
		player.CharacterRemoving:Connect(function()
			local a = active[player]
			if a and not a.fired then
				cleanup(player, 1)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		local a = active[player]
		if a and a.model and a.model.Parent then
			a.model:Destroy()
		end
		active[player] = nil
	end)
end

return LaunchService
