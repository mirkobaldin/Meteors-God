-- Server side of the launch: validates the pad, picks the meteor, spawns it above the
-- player's head, computes damage on release and flies it into the planet.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local Evolutions = require(Shared.Config.Evolutions)
local MeteorMath = require(Shared.Util.MeteorMath)
local MeteorVisual = require(Shared.MeteorVisual)
local Remotes = require(Shared.Remotes)

local Server = script.Parent.Parent
local RateLimit = require(Server.RateLimit)

local LaunchService = {}

local services
local active = {} -- [player] = {uid, startedAt, model, fired}
local resultRemote

local L = Game.Launch

local function setAuraBoost(player, boosted)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local att = root and root:FindFirstChild("AuraAttachment")
	local aura = att and att:FindFirstChild("Aura")
	if aura then
		if boosted then
			aura:SetAttribute("BaseRate", aura:GetAttribute("BaseRate") or aura.Rate)
			aura.Rate = (aura:GetAttribute("BaseRate") or 10) * 5
			aura.Speed = NumberRange.new(4, 8)
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
		dmg *= L.CritMultiplier
	end
	dmg *= MeteorMath.PowerMultiplier(data.power)
	dmg *= 1 + 0.1 * (data.upgrades.power or 0)
	dmg *= evo.mult
	if wrathActive() then
		dmg *= L.WrathMultiplier
	end
	return math.floor(dmg)
end

local function beginLaunch(player)
	if not RateLimit.Allow(player, "BeginLaunch", 0.4) then
		return { ok = false }
	end
	if active[player] then
		return { ok = false, reason = "Stai già lanciando!" }
	end
	local data = services.DataService:Get(player)
	if not data then
		return { ok = false, reason = "Caricamento dati..." }
	end
	if not services.CycleService:IsBombard() then
		return { ok = false, reason = "Aspetta il Bombardamento per lanciare!" }
	end
	if not services.PlanetService:IsTargetable() then
		return { ok = false, reason = "Il pianeta sta arrivando..." }
	end
	if services.TradeService:IsTrading(player) then
		return { ok = false, reason = "Chiudi lo scambio prima di lanciare" }
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return { ok = false }
	end
	local pad = services.WorldService:PadAt(root.Position)
	if not pad then
		return { ok = false, reason = "Vai sul pad di LANCIO in fondo al ponte" }
	end
	local uid = services.MeteorService:BestReady(player)
	if not uid then
		return { ok = false, reason = "Nessun meteorite pronto! Aspetta la ricarica o raccoglierne altri." }
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
	core.CFrame = root.CFrame * CFrame.new(0, 5 + size / 2, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "HoldWeld"
	weld.Part0 = root
	weld.Part1 = core
	weld.Parent = core
	model.Name = "Launch_" .. player.Name
	model.Parent = workspace

	active[player] = { uid = uid, startedAt = os.clock(), model = model, fired = false }
	services.MeteorService:SetCooldown(player, uid, L.MaxHoldTime + L.FlightTime + 5)
	setAuraBoost(player, true)

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
		planetPosition = Game.World.PlanetPosition,
	}
end

local function fireLaunch(player, charge)
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
	a.fired = true

	local data = services.DataService:Get(player)
	local meteor = data and data.meteors[a.uid]
	if not meteor then
		cleanup(player, nil)
		return
	end

	local crit = charge >= L.CritThreshold
	local damage = computeDamage(player, meteor, charge, crit)
	local def = Meteors.ByID[meteor.t]
	local color = def and def.fire[1] or Color3.new(1, 1, 1)
	local impact = services.PlanetService:GetImpactPoint()

	-- Release the meteor and send it flying.
	local model = a.model
	local core = model.PrimaryPart
	local weld = core:FindFirstChild("HoldWeld")
	if weld then
		weld:Destroy()
	end
	core.Anchored = true
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, core.Size.X * 0.4, 0)
	a0.Parent = core
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -core.Size.X * 0.4, 0)
	a1.Parent = core
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(def.fire[1], def.fire[2])
	trail.LightEmission = 1
	trail.Lifetime = 0.6
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Transparency = NumberSequence.new(0, 1)
	trail.FaceCamera = true
	trail.Parent = core

	local flight = TweenService:Create(core, TweenInfo.new(L.FlightTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = CFrame.lookAt(impact, impact + (impact - core.Position).Unit),
	})
	flight:Play()

	resultRemote:FireClient(player, {
		model = model,
		flightTime = L.FlightTime,
		damage = damage,
		crit = crit,
		impact = impact,
	})
	setAuraBoost(player, false)
	services.MeteorService:SetCooldown(player, a.uid, L.FlightTime + MeteorMath.Cooldown(data.upgrades.recharge))

	task.delay(L.FlightTime, function()
		local dealt = services.PlanetService:ApplyHit(player, damage, impact, crit, color)
		if model.Parent then
			model:Destroy()
		end
		if active[player] == a then
			active[player] = nil
		end
		local d = services.DataService:Get(player)
		if d and dealt > 0 then
			d.totalDamage += dealt
			services.PlayerService:AddShards(player, dealt * Game.Economy.ShardsPerDamage, true)
		end
	end)
end

function LaunchService:Init(s)
	services = s
	resultRemote = Remotes.Get("LaunchResult")
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

	local function onCharacter(player)
		player.CharacterRemoving:Connect(function()
			local a = active[player]
			if a and not a.fired then
				cleanup(player, 1)
			end
		end)
	end
	Players.PlayerAdded:Connect(onCharacter)
	for _, p in ipairs(Players:GetPlayers()) do
		onCharacter(p)
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
