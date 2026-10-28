-- Divine looks attached to the character: aura, halo, wings, crown, rings, galaxy, size.
-- Everything is welded neon parts and particles, no assets needed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Evolutions = require(ReplicatedStorage:WaitForChild("Shared").Config.Evolutions)

local EvolutionVisuals = {}

local function fxPart(props)
	local p = Instance.new("Part")
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	-- Shape first: changing Shape after Size can resize the part.
	if props.Shape then
		p.Shape = props.Shape
	end
	for k, v in pairs(props) do
		if k ~= "Shape" then
			p[k] = v
		end
	end
	return p
end

local function weldTo(part, target, offset, folder)
	part.CFrame = target.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = target
	w.Part1 = part
	w.Parent = part
	part.Parent = folder
end

local function addAura(root, color, folder, strength)
	local att = Instance.new("Attachment")
	att.Name = "AuraAttachment"
	att.Parent = root
	local p = Instance.new("ParticleEmitter")
	p.Name = "Aura"
	p.Color = ColorSequence.new(color)
	p.LightEmission = 1
	p.LightInfluence = 0
	p.Rate = 8 + strength * 6
	p.Lifetime = NumberRange.new(0.8, 1.4)
	p.Speed = NumberRange.new(1, 3)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4 + strength * 0.15),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Transparency = NumberSequence.new(0.2, 1)
	p.Parent = att
	-- Track for cleanup together with the parts.
	local tag = Instance.new("ObjectValue")
	tag.Name = "AuraRef"
	tag.Value = att
	tag.Parent = folder
end

function EvolutionVisuals.Apply(character, evolutionIndex, isVIP)
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not root or not head then
		return
	end

	local old = character:FindFirstChild("DivineFX")
	if old then
		for _, ref in ipairs(old:GetChildren()) do
			if ref:IsA("ObjectValue") and ref.Value then
				ref.Value:Destroy()
			end
		end
		old:Destroy()
	end

	-- Build the effects at base scale, then scale the whole character (effects included).
	pcall(function()
		if math.abs(character:GetScale() - 1) > 0.001 then
			character:ScaleTo(1)
		end
	end)

	local evo = Evolutions.Get(evolutionIndex)
	local folder = Instance.new("Folder")
	folder.Name = "DivineFX"
	folder.Parent = character

	addAura(root, evo.aura, folder, evolutionIndex)

	local has = {}
	for _, v in ipairs(evo.visuals) do
		has[v] = true
	end

	if has.halo then
		local halo = fxPart({
			Name = "Halo",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.2, 2.6, 2.6),
			Color = Color3.fromRGB(255, 240, 150),
		})
		weldTo(halo, head, CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90)), folder)
	end

	if has.crown then
		local gold = Color3.fromRGB(255, 200, 40)
		local band = fxPart({ Name = "Crown", Size = Vector3.new(1.4, 0.35, 1.4), Color = gold })
		weldTo(band, head, CFrame.new(0, 0.85, 0), folder)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			local spike = fxPart({ Name = "CrownSpike", Size = Vector3.new(0.25, 0.6, 0.25), Color = gold })
			weldTo(spike, head, CFrame.new(math.sin(a) * 0.6, 1.25, math.cos(a) * 0.6), folder)
		end
	end

	if has.wings then
		for _, side in ipairs({ -1, 1 }) do
			local wing = fxPart({
				Name = "Wing",
				Size = Vector3.new(0.2, 3.2, 1.6),
				Color = evo.aura,
				Transparency = 0.25,
			})
			weldTo(
				wing,
				root,
				CFrame.new(side * 1.3, 0.8, 0.9) * CFrame.Angles(0, math.rad(side * 35), math.rad(side * -20)),
				folder
			)
			local tip = fxPart({
				Name = "WingTip",
				Size = Vector3.new(0.2, 2.2, 1.2),
				Color = evo.aura,
				Transparency = 0.35,
			})
			weldTo(
				tip,
				root,
				CFrame.new(side * 2.4, 1.9, 1.3) * CFrame.Angles(0, math.rad(side * 35), math.rad(side * -45)),
				folder
			)
		end
	end

	if has.rings then
		for i, tilt in ipairs({ 20, -25 }) do
			local ring = fxPart({
				Name = "Ring" .. i,
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.15, 6 + i, 6 + i),
				Color = i == 1 and Color3.fromRGB(255, 220, 120) or evo.aura,
				Transparency = 0.5,
			})
			weldTo(ring, root, CFrame.Angles(math.rad(tilt), 0, math.rad(90)), folder)
		end
	end

	if has.galaxy then
		local att = Instance.new("Attachment")
		att.Name = "GalaxyAttachment"
		att.Parent = root
		local p = Instance.new("ParticleEmitter")
		p.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 200)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 80, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 220, 255)),
		})
		p.LightEmission = 1
		p.Rate = 40
		p.Lifetime = NumberRange.new(1.5, 2.5)
		p.Speed = NumberRange.new(0.5, 1.5)
		p.SpreadAngle = Vector2.new(180, 180)
		p.Size = NumberSequence.new(0.6, 0)
		p.Parent = att
		local tag = Instance.new("ObjectValue")
		tag.Name = "GalaxyRef"
		tag.Value = att
		tag.Parent = folder
	end

	if isVIP then
		local bb = Instance.new("BillboardGui")
		bb.Name = "VIPTag"
		bb.Size = UDim2.new(4, 0, 1, 0)
		bb.StudsOffset = Vector3.new(0, 3.2, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 120
		bb.Adornee = head
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = "VIP"
		t.TextColor3 = Color3.fromRGB(255, 210, 60)
		t.TextStrokeTransparency = 0.2
		t.Parent = bb
		bb.Parent = folder
	end

	if evo.scale and math.abs(evo.scale - 1) > 0.001 then
		pcall(function()
			character:ScaleTo(evo.scale)
		end)
	end
end

return EvolutionVisuals
