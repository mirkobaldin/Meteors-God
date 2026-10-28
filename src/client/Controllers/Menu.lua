-- Codes and Settings windows (opened from the Menu dropdown).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Panels = require(script.Parent.Panels)

local Menu = {}

local player = Players.LocalPlayer

-- Client-side preferences (stored as player attributes so other controllers can read them).
Menu.Settings = {
	{ key = "ShowDamageNumbers", label = "Show damage numbers", default = true },
	{ key = "CameraShake", label = "Camera shake", default = true },
}

function Menu.Get(key)
	local v = player:GetAttribute("Setting_" .. key)
	if v == nil then
		for _, s in ipairs(Menu.Settings) do
			if s.key == key then
				return s.default
			end
		end
	end
	return v
end

local function buildCodes(gui)
	local window, content = UI.Window(gui, {
		Title = "Codes",
		Emoji = "🔑",
		Icon = Assets.Icons.Codes,
		Size = UDim2.fromOffset(520, 300),
		MinSize = Vector2.new(360, 260),
	})
	UI.Text({
		Size = UDim2.new(1, 0, 0, 30),
		Text = "Enter a code to get free rewards",
		TextColor3 = UI.Colors.Muted,
		MaxTextSize = 20,
		Parent = content,
	})
	local box = UI.New("TextBox", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(30, 25, 55),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		PlaceholderText = "CODE",
		PlaceholderColor3 = Color3.fromRGB(140, 130, 170),
		Font = UI.Font,
		TextScaled = true,
		ClearTextOnFocus = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = content,
	})
	UI.Corner(UDim.new(0, 10)).Parent = box
	UI.Padding(8).Parent = box
	UI.Button({
		Position = UDim2.fromOffset(0, 112),
		Size = UDim2.new(1, 0, 0, 52),
		Text = "Redeem",
		BackgroundColor3 = UI.Colors.Good,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		MaxTextSize = 28,
		Parent = content,
	}, function()
		if box.Text ~= "" then
			Remotes.Get("RedeemCode"):FireServer(box.Text)
			box.Text = ""
		end
	end)
	Panels.Register("Codes", window)
end

local function buildSettings(gui)
	local window, content = UI.Window(gui, {
		Title = "Settings",
		Emoji = "⚙️",
		Icon = Assets.Icons.Settings,
		Size = UDim2.fromOffset(560, 360),
		MinSize = Vector2.new(380, 300),
	})
	local list = UI.List({ Size = UDim2.fromScale(1, 1), Parent = content }, 8)
	for i, s in ipairs(Menu.Settings) do
		local row = UI.New("Frame", {
			Size = UDim2.new(1, -8, 0, 56),
			BackgroundColor3 = Color3.fromRGB(45, 40, 85),
			BorderSizePixel = 0,
			LayoutOrder = i,
			Parent = list,
		})
		UI.Corner(UDim.new(0, 10)).Parent = row
		UI.Text({
			Size = UDim2.new(0.7, -12, 1, -10),
			Position = UDim2.fromOffset(12, 5),
			Text = s.label,
			TextXAlignment = Enum.TextXAlignment.Left,
			MaxTextSize = 22,
			Parent = row,
		})
		local toggle
		toggle = UI.Button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(110, 40),
			Text = "",
			Parent = row,
		}, function()
			player:SetAttribute("Setting_" .. s.key, not Menu.Get(s.key))
		end)
		local function paint()
			local on = Menu.Get(s.key)
			toggle.Text = on and "ON" or "OFF"
			toggle.BackgroundColor3 = on and UI.Colors.Good or Color3.fromRGB(90, 80, 110)
		end
		paint()
		player:GetAttributeChangedSignal("Setting_" .. s.key):Connect(paint)
	end
	Panels.Register("Settings", window)
end

-- Applies the local visual settings to replicated effects.
local function applyVisualSettings(inst)
	if inst:IsA("BillboardGui") and inst.Parent and inst.Parent.Name == "DamageNumber" then
		inst.Enabled = Menu.Get("ShowDamageNumbers")
	end
end

function Menu:Init()
	local gui = UI.Screen("Menu", 12)
	buildCodes(gui)
	buildSettings(gui)
end

function Menu:Start()
	workspace.DescendantAdded:Connect(applyVisualSettings)
end

return Menu
