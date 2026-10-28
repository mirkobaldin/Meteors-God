-- "Ladder of Divinity": every evolution as a step. Past steps are lit, the current one glows,
-- the next one shows its requirements with Evolve / Skip (Robux), future ones are locked.

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
local rows = {}
local refs = {}

local VISUAL_NAMES = {
	halo = "Aureola",
	wings = "Ali di luce",
	crown = "Corona",
	rings = "Anelli planetari",
	galaxy = "Aura galattica",
}

local function looks(evo)
	local list = {}
	for _, v in ipairs(evo.visuals) do
		table.insert(list, VISUAL_NAMES[v] or v)
	end
	if evo.scale and evo.scale > 1 then
		table.insert(list, "Taglia x" .. evo.scale)
	end
	return #list > 0 and table.concat(list, " · ") or "Aura stellare"
end

local function buildRow(parent, index, evo)
	local row = UI.New("Frame", {
		Size = UDim2.new(1, -10, 0, 64),
		BackgroundColor3 = UI.Colors.PanelLight,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		LayoutOrder = -index, -- highest form on top
		Parent = parent,
	})
	UI.Corner(UDim.new(0, 14)).Parent = row
	local stroke = UI.Stroke(evo.aura, 1.5, 0.6)
	stroke.Parent = row
	local orb = UI.New("Frame", {
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = evo.aura,
		BorderSizePixel = 0,
		Parent = row,
	})
	UI.Corner(UDim.new(1, 0)).Parent = orb
	UI.Stroke(Color3.new(1, 1, 1), 2, 0.4).Parent = orb
	UI.Text({ Size = UDim2.fromScale(1, 1), Text = tostring(index), Font = UI.TitleFont, TextColor3 = Color3.fromRGB(20, 20, 40), MaxTextSize = 24, Parent = orb })
	UI.Text({
		Position = UDim2.fromOffset(70, 8),
		Size = UDim2.new(0.45, -70, 0, 26),
		Text = string.upper(evo.name),
		Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 20,
		Parent = row,
	})
	UI.Text({
		Position = UDim2.fromOffset(70, 36),
		Size = UDim2.new(0.45, -70, 0, 18),
		Text = "x" .. evo.mult .. " Potere e Danno  ·  " .. looks(evo),
		TextColor3 = UI.Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 14,
		Parent = row,
	})
	local status = UI.Text({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0.5, -20, 0, 26),
		Text = "",
		Font = UI.TitleFont,
		TextXAlignment = Enum.TextXAlignment.Right,
		MaxTextSize = 16,
		Parent = row,
	})
	rows[index] = { row = row, stroke = stroke, status = status }
end

function Evolution:Refresh()
	if not window.Visible then
		return
	end
	local index = player:GetAttribute("Evolution") or 1
	local power = player:GetAttribute("Power") or 0
	local planets = player:GetAttribute("Planets") or 0
	for i, r in ipairs(rows) do
		local evo = Evolutions.Get(i)
		if i < index then
			r.status.Text = "✓ RAGGIUNTA"
			r.status.TextColor3 = UI.Colors.Good
			r.row.BackgroundTransparency = 0.5
			r.stroke.Transparency = 0.7
		elseif i == index then
			r.status.Text = "★ FORMA ATTUALE"
			r.status.TextColor3 = UI.Colors.Gold
			r.row.BackgroundTransparency = 0.05
			r.stroke.Transparency = 0
		elseif i == index + 1 then
			r.status.Text = "Potere " .. Format.Number(power) .. "/" .. Format.Number(evo.power) .. "  ·  Pianeti " .. planets .. "/" .. evo.planets
			r.status.TextColor3 = Color3.new(1, 1, 1)
			r.row.BackgroundTransparency = 0.2
			r.stroke.Transparency = 0.2
		else
			r.status.Text = "🔒"
			r.status.TextColor3 = UI.Colors.Muted
			r.row.BackgroundTransparency = 0.6
			r.stroke.Transparency = 0.8
		end
	end

	refs.ascend.Visible = index >= Evolutions.AscensionMinEvolution
	if index >= Evolutions.Max() then
		refs.evolve.Visible = false
		refs.skip.Visible = false
		refs.info.Text = "Hai raggiunto la forma suprema. Ascendi per crescere ancora!"
		return
	end
	local nextEvo = Evolutions.Get(index + 1)
	local ready = power >= nextEvo.power and planets >= nextEvo.planets
	refs.evolve.Visible = true
	refs.skip.Visible = true
	refs.skip.Text = "SALTA  " .. Prices.ProductText("EvolveNow")
	if ready then
		refs.evolve.Text = "EVOLVI IN " .. string.upper(nextEvo.name)
		refs.evolve.BackgroundColor3 = UI.Colors.Gold
		refs.info.Text = "Sei pronto!"
	else
		refs.evolve.Text = "NON ANCORA PRONTO"
		refs.evolve.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
		local missing = {}
		if power < nextEvo.power then
			table.insert(missing, Format.Number(nextEvo.power - power) .. " Potere")
		end
		if planets < nextEvo.planets then
			table.insert(missing, (nextEvo.planets - planets) .. " pianeti distrutti")
		end
		refs.info.Text = "Ti mancano: " .. table.concat(missing, " e ")
	end
end

function Evolution:Init()
	local gui = UI.Screen("Evolution", 10)
	local content
	window, content = UI.Window(gui, {
		Title = "Scala della Divinità",
		Emoji = "🌟",
		Icon = Assets.Icons.Evolution,
		HeaderColor = Color3.fromRGB(150, 90, 220),
		Size = UDim2.new(0.56, 0, 0.74, 0),
		MaxSize = Vector2.new(780, 640),
	})
	local list = UI.List({ Size = UDim2.new(1, 0, 1, -110), Parent = content }, 6)
	for i = 1, Evolutions.Max() do
		buildRow(list, i, Evolutions.Get(i))
	end
	refs.info = UI.Text({
		Position = UDim2.new(0, 0, 1, -104),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		TextColor3 = UI.Colors.Muted,
		MaxTextSize = 17,
		Parent = content,
	})
	refs.evolve = UI.Button({
		Position = UDim2.new(0, 0, 1, -74),
		Size = UDim2.new(0.62, -6, 0, 48),
		Text = "",
		MaxTextSize = 20,
		Parent = content,
	}, function()
		Remotes.Get("Evolve"):FireServer()
		task.delay(0.4, function()
			Evolution:Refresh()
		end)
	end)
	refs.skip = UI.Button({
		Position = UDim2.new(0.62, 6, 1, -74),
		Size = UDim2.new(0.38, -6, 0, 48),
		Text = "SALTA",
		BackgroundColor3 = UI.Colors.Cyan,
		MaxTextSize = 18,
		Parent = content,
	}, function()
		Prices.BuyProduct("EvolveNow")
	end)
	refs.ascend = UI.Button({
		Position = UDim2.new(0, 0, 1, -20),
		Size = UDim2.new(1, 0, 0, 20),
		Text = "✨ ASCENDI: +50% Potere per sempre (azzera Potere ed Evoluzione)",
		BackgroundColor3 = Color3.fromRGB(255, 130, 220),
		MaxTextSize = 13,
		Visible = false,
		Parent = content,
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
