-- Evolution window: current form -> next form, requirements, Evolve / Skip (Robux) / Ascend.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Evolutions = require(Shared.Config.Evolutions)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)
local Prices = require(script.Parent.Prices)

local Evolution = {}

local player = Players.LocalPlayer
local window
local refs = {}

local VISUAL_NAMES = {
	halo = "Aureola",
	wings = "Ali di luce",
	crown = "Corona",
	rings = "Anelli planetari",
	galaxy = "Aura galattica",
}

local function card(parent, x, title)
	local c = UI.New("Frame", {
		Position = UDim2.new(x, 0, 0, 0),
		Size = UDim2.new(0.42, 0, 0.62, 0),
		BackgroundColor3 = Color3.fromRGB(60, 70, 130),
		BorderSizePixel = 0,
		Parent = parent,
	})
	UI.Corner().Parent = c
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = c
	local header = UI.Text({
		Size = UDim2.new(1, -16, 0.14, 0),
		Position = UDim2.new(0, 8, 0.02, 0),
		Text = title,
		TextColor3 = UI.Colors.Muted,
		TextStrokeTransparency = 0,
		MaxTextSize = 24,
		Parent = c,
	})
	local orb = UI.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.18, 0),
		Size = UDim2.fromScale(0.36, 0.36),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = c,
	})
	UI.New("UIAspectRatioConstraint", { Parent = orb })
	UI.Corner(UDim.new(1, 0)).Parent = orb
	UI.Stroke(Color3.fromRGB(255, 255, 255), 4, 0.2).Parent = orb
	UI.Icon(orb, Assets.Icons.Evolution, "🌟", { MaxTextSize = 50 })
	local name = UI.Text({
		Size = UDim2.new(1, -16, 0.14, 0),
		Position = UDim2.new(0, 8, 0.56, 0),
		Text = "",
		TextStrokeTransparency = 0,
		MaxTextSize = 34,
		Parent = c,
	})
	local mult = UI.Text({
		Size = UDim2.new(1, -16, 0.11, 0),
		Position = UDim2.new(0, 8, 0.71, 0),
		Text = "",
		TextColor3 = UI.Colors.Good,
		TextStrokeTransparency = 0,
		MaxTextSize = 26,
		Parent = c,
	})
	local looks = UI.Text({
		Size = UDim2.new(1, -16, 0.14, 0),
		Position = UDim2.new(0, 8, 0.83, 0),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 170, 90),
		TextStrokeTransparency = 0,
		MaxTextSize = 18,
		Parent = c,
	})
	return { frame = c, header = header, orb = orb, name = name, mult = mult, looks = looks }
end

local function fillCard(c, evo, index)
	c.orb.BackgroundColor3 = evo.aura
	c.name.Text = evo.name
	c.mult.Text = "x" .. evo.mult .. " Potere  ·  x" .. evo.mult .. " Danno"
	local looks = {}
	for _, v in ipairs(evo.visuals) do
		table.insert(looks, VISUAL_NAMES[v] or v)
	end
	if evo.scale and evo.scale > 1 then
		table.insert(looks, "Taglia x" .. evo.scale)
	end
	c.looks.Text = #looks > 0 and table.concat(looks, " · ") or "Aura stellare"
	c.header.Text = c.header.Text:gsub("%d+$", tostring(index))
end

local function chip(parent, x, emoji)
	local f = UI.New("Frame", {
		Position = UDim2.new(x, 0, 0.66, 0),
		Size = UDim2.new(0.44, 0, 0.13, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 60),
		BorderSizePixel = 0,
		Parent = parent,
	})
	UI.Corner(UDim.new(0, 10)).Parent = f
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = f
	UI.Text({ Size = UDim2.fromScale(0.18, 1), Text = emoji, MaxTextSize = 32, Parent = f })
	local t = UI.Text({
		Size = UDim2.new(0.8, 0, 1, -6),
		Position = UDim2.new(0.18, 0, 0, 3),
		Text = "",
		TextStrokeTransparency = 0,
		MaxTextSize = 28,
		Parent = f,
	})
	return t
end

function Evolution:Refresh()
	if not window.Visible then
		return
	end
	local index = player:GetAttribute("Evolution") or 1
	local power = player:GetAttribute("Power") or 0
	local planets = player:GetAttribute("Planets") or 0
	local current = Evolutions.Get(index)
	fillCard(refs.current, current, index)
	refs.ascend.Visible = index >= Evolutions.AscensionMinEvolution

	if index >= Evolutions.Max() then
		refs.next.frame.Visible = false
		refs.arrow.Text = "MAX"
		refs.powerChip.Text = "Forma suprema raggiunta"
		refs.planetChip.Text = "Ascendi per crescere ancora"
		refs.skip.Visible = false
		refs.evolve.Visible = false
		return
	end
	refs.next.frame.Visible = true
	refs.arrow.Text = "➜"
	local nextEvo = Evolutions.Get(index + 1)
	fillCard(refs.next, nextEvo, index + 1)

	local powerOk = power >= nextEvo.power
	local planetsOk = planets >= nextEvo.planets
	refs.powerChip.Text = "Potere " .. Format.Number(power) .. " / " .. Format.Number(nextEvo.power)
	refs.powerChip.TextColor3 = powerOk and UI.Colors.Good or Color3.fromRGB(255, 255, 255)
	refs.planetChip.Text = "Pianeti " .. planets .. " / " .. nextEvo.planets
	refs.planetChip.TextColor3 = planetsOk and UI.Colors.Good or Color3.fromRGB(255, 255, 255)

	refs.skip.Visible = true
	refs.skip.Text = "Salta Evoluzione  " .. Prices.ProductText("EvolveNow")
	refs.evolve.Visible = true
	if powerOk and planetsOk then
		refs.evolve.Text = "EVOLVI!"
		refs.evolve.BackgroundColor3 = UI.Colors.Good
	elseif not planetsOk then
		refs.evolve.Text = "Servono altri " .. (nextEvo.planets - planets) .. " pianeti"
		refs.evolve.BackgroundColor3 = Color3.fromRGB(60, 120, 50)
	else
		refs.evolve.Text = "Serve più Potere"
		refs.evolve.BackgroundColor3 = Color3.fromRGB(60, 120, 50)
	end
end

function Evolution:Init()
	local gui = UI.Screen("Evolution", 10)
	local content
	window, content = UI.Window(gui, { Title = "Evoluzione", Emoji = "🌟", Icon = Assets.Icons.Evolution })
	refs.current = card(content, 0.03, "Attuale · Evoluzione 1")
	refs.next = card(content, 0.55, "Prossima · Evoluzione 2")
	refs.next.frame.BackgroundColor3 = Color3.fromRGB(90, 60, 140)
	refs.arrow = UI.Text({
		Position = UDim2.new(0.45, 0, 0.22, 0),
		Size = UDim2.new(0.1, 0, 0.16, 0),
		Text = "➜",
		TextStrokeTransparency = 0,
		MaxTextSize = 60,
		Parent = content,
	})
	refs.powerChip = chip(content, 0.04, "⚡")
	refs.planetChip = chip(content, 0.52, "🏆")
	refs.skip = UI.Button({
		Position = UDim2.new(0.04, 0, 0.83, 0),
		Size = UDim2.new(0.44, 0, 0.15, 0),
		Text = "Salta Evoluzione",
		BackgroundColor3 = Color3.fromRGB(255, 110, 200),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		MaxTextSize = 28,
		Parent = content,
	}, function()
		Prices.BuyProduct("EvolveNow")
	end)
	UI.New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 120, 255)),
		}),
		Parent = refs.skip,
	})
	refs.evolve = UI.Button({
		Position = UDim2.new(0.52, 0, 0.83, 0),
		Size = UDim2.new(0.44, 0, 0.15, 0),
		Text = "EVOLVI!",
		BackgroundColor3 = UI.Colors.Good,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		MaxTextSize = 28,
		Parent = content,
	}, function()
		Remotes.Get("Evolve"):FireServer()
		task.delay(0.4, function()
			Evolution:Refresh()
		end)
	end)
	refs.ascend = UI.Button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -50),
		Size = UDim2.fromOffset(360, 40),
		Text = "✨ ASCENDI: +50% Potere permanente (azzera Potere ed Evoluzione)",
		BackgroundColor3 = Color3.fromRGB(255, 120, 220),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		MaxTextSize = 16,
		Visible = false,
		Parent = window,
	}, function()
		Remotes.Get("Ascend"):FireServer()
	end)
	Panels.Register("Evolution", window, function()
		Evolution:Refresh()
	end)
end

function Evolution:Start()
	task.spawn(function()
		while true do
			task.wait(0.5)
			Evolution:Refresh()
		end
	end)
end

return Evolution
