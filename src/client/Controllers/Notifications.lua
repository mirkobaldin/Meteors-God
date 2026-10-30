-- Toasts, big announcements, "meteor found" popups and planet destroyed rewards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Meteors = require(Shared.Config.Meteors)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Anim = require(script.Parent.Anim)
local Sfx = require(script.Parent.Sfx)

local Notifications = {}

local gui
local toastList
local banner

local MAX_TOASTS = 2
local lastToast = {} -- [text] = os.clock(): the same toast isn't repeated within a few seconds

local function chat(text)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local system = channels and channels:FindFirstChild("RBXSystem")
		if system then
			system:DisplaySystemMessage(text)
		end
	end)
end

function Notifications.Toast(text, kind)
	local now = os.clock()
	if lastToast[text] and now - lastToast[text] < 4 then
		return
	end
	lastToast[text] = now
	-- Only a couple on screen: the oldest goes away.
	local items = {}
	for _, child in ipairs(toastList:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(items, child)
		end
	end
	table.sort(items, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #items - MAX_TOASTS + 1 do
		items[i]:Destroy()
	end
	local color = kind == "good" and UI.Colors.Good or kind == "bad" and UI.Colors.Bad or UI.Colors.Blue
	local item = UI.Panel({
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 0.25,
		LayoutOrder = math.floor(now * 1000) % 1e9,
		Parent = toastList,
	})
	UI.Text({
		Size = UDim2.new(1, -16, 1, -8),
		Position = UDim2.fromOffset(8, 4),
		Text = text,
		TextColor3 = color,
		MaxTextSize = 18,
		Parent = item,
	})
	task.delay(2.6, function()
		if not item.Parent then
			return
		end
		local t = TweenService:Create(item, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		t:Play()
		if item:IsA("ImageLabel") then
			TweenService:Create(item, TweenInfo.new(0.4), { ImageTransparency = 1 }):Play()
		end
		for _, d in ipairs(item:GetDescendants()) do
			if d:IsA("TextLabel") then
				TweenService:Create(d, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			elseif d:IsA("UIStroke") then
				TweenService:Create(d, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			end
		end
		t.Completed:Wait()
		item:Destroy()
	end)
end

-- Banners queue up (never on top of each other); if too many pile up, the old ones go to chat only.
local bannerQueue = {}
local bannerBusy = false

local function showNextBanner()
	local entry = table.remove(bannerQueue, 1)
	if not entry then
		bannerBusy = false
		return
	end
	bannerBusy = true
	banner.Text = entry.text
	banner.TextColor3 = entry.color or UI.Colors.Gold
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0.2
	banner.Position = UDim2.new(0.5, 0, 0.16, -20)
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0.16, 0) }):Play()
	task.delay(#bannerQueue > 0 and 2.2 or 3.2, function()
		local t = TweenService:Create(banner, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 })
		t:Play()
		t.Completed:Wait()
		showNextBanner()
	end)
end

function Notifications.Announce(text, color, chatOnly)
	chat(text)
	if chatOnly then
		return
	end
	table.insert(bannerQueue, { text = text, color = color })
	while #bannerQueue > 2 do
		table.remove(bannerQueue, 1)
	end
	if not bannerBusy then
		showNextBanner()
	end
end

-- Big centered popup used for discoveries and rewards.
function Notifications.Popup(title, subtitle, color)
	local frame = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(360, 120),
		Parent = gui,
	})
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
		stroke.Transparency = 0
		stroke.Thickness = 3
	end
	UI.Text({
		Size = UDim2.new(1, -20, 0, 50),
		Position = UDim2.fromOffset(10, 12),
		Text = title,
		TextColor3 = color,
		MaxTextSize = 40,
		Parent = frame,
	})
	UI.Text({
		Size = UDim2.new(1, -20, 0, 34),
		Position = UDim2.fromOffset(10, 70),
		Text = subtitle,
		TextColor3 = UI.Colors.Text,
		MaxTextSize = 22,
		Parent = frame,
	})
	local scale = UI.New("UIScale", { Scale = 0.3, Parent = frame })
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(2.6, function()
		local t = TweenService:Create(scale, TweenInfo.new(0.25), { Scale = 0 })
		t:Play()
		t.Completed:Wait()
		frame:Destroy()
	end)
end

function Notifications:Init()
	gui = UI.Screen("Notifications", 20)

	toastList = UI.New("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -200),
		Size = UDim2.fromOffset(420, 220),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	UI.New("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = toastList,
	})

	banner = UI.Text({
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.16),
		Size = UDim2.new(0.8, 0, 0, 48),
		Text = "",
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		MaxTextSize = 38,
		Parent = gui,
	})
end

function Notifications:Start()
	local Players = game:GetService("Players")
	local lastEvolution = Players.LocalPlayer:GetAttribute("Evolution")
	Players.LocalPlayer:GetAttributeChangedSignal("Evolution"):Connect(function()
		local evo = Players.LocalPlayer:GetAttribute("Evolution")
		if lastEvolution and evo > lastEvolution then
			Sfx.Play("Evolve", 0.8)
			Notifications.Popup("EVOLUTION!", "You became more divine", UI.Colors.Gold)
		end
		lastEvolution = evo
	end)
	Remotes.Get("Toast").OnClientEvent:Connect(Notifications.Toast)
	Remotes.Get("Announce").OnClientEvent:Connect(Notifications.Announce)

	Remotes.Get("MeteorPickedUp").OnClientEvent:Connect(function(info)
		local def = Meteors.ByID[info.type]
		if not def then
			return
		end
		local rarity = Meteors.RarityByID[def.rarity]
		local name = (info.mutation and (info.mutation .. " ") or "") .. def.id
		local subtitle = def.rarity .. (info.upgraded and "  ·  LUCKY! Rarity upgraded!" or "")
		Anim.Play("Pickup")
		Sfx.Play((rarity.order >= 2 or info.mutation) and "RarePickup" or "Pickup")
		-- Common pickups only make a sound; rare ones get a toast, epic+ a popup.
		if rarity.order >= 3 or info.mutation or info.upgraded then
			Notifications.Popup(name .. "!", subtitle, rarity.color)
		elseif rarity.order == 2 then
			Notifications.Toast("You picked up: " .. name, "good")
		end
	end)

	Remotes.Get("PlanetDestroyed").OnClientEvent:Connect(function(info)
		Notifications.Popup(
			"PLANET DESTROYED!",
			"+" .. Format.Number(info.shards) .. " Shards  ·  contribution " .. math.floor(info.share * 100) .. "%",
			UI.Colors.Gold
		)
	end)
end

return Notifications
