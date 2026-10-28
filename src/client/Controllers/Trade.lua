-- Trading UI: player list, incoming requests and the two-sided trade window.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Meteors = require(Shared.Config.Meteors)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local Trade = {}

local player = Players.LocalPlayer
local gui
local playerList
local playerListPanel
local window
local refs = {}
local current -- latest TradeState from the server

local function meteorLabel(view)
	local def = Meteors.ByID[view.t]
	local rarity = def and Meteors.RarityByID[def.rarity]
	return (view.m and (view.m .. " ") or "") .. view.t, rarity and rarity.color or UI.Colors.Text
end

local function chip(parent, view, onClick)
	local text, color = meteorLabel(view)
	local def = Meteors.ByID[view.t]
	local b = UI.Button({
		Size = UDim2.new(1, -8, 0, 34),
		Text = text .. (def and ("  (" .. def.rarity .. ")") or ""),
		BackgroundColor3 = UI.Colors.PanelLight,
		TextColor3 = color,
		MaxTextSize = 16,
		Parent = parent,
	}, onClick)
	return b
end

local function myOfferUids()
	local uids = {}
	if current then
		for _, v in ipairs(current.myOffer) do
			table.insert(uids, v.uid)
		end
	end
	return uids
end

local function toggleOffer(uid)
	local uids = myOfferUids()
	local found = table.find(uids, uid)
	if found then
		table.remove(uids, found)
	elseif #uids < Game.Trade.MaxItemsPerSide then
		table.insert(uids, uid)
	end
	Remotes.Get("TradeSetOffer"):FireServer(uids)
end

local function renderWindow()
	if not current then
		window.Visible = false
		return
	end
	window.Visible = true
	refs.title.Text = "🤝 Scambio con " .. current.partnerName

	UI.Clear(refs.mine)
	for _, v in ipairs(current.myOffer) do
		chip(refs.mine, v, function()
			toggleOffer(v.uid)
		end)
	end
	UI.Clear(refs.theirs)
	for _, v in ipairs(current.theirOffer) do
		chip(refs.theirs, v)
	end

	-- Tradable meteors: in storage (not on the altar) and not exclusive.
	UI.Clear(refs.storage)
	local offered = {}
	for _, uid in ipairs(myOfferUids()) do
		offered[uid] = true
	end
	local snap = State.Snapshot
	if snap then
		for uid, m in pairs(snap.meteors) do
			if not m.altar and not m.paid and not offered[uid] then
				chip(refs.storage, { uid = uid, t = m.t, m = m.m }, function()
					toggleOffer(uid)
				end)
			end
		end
	end

	local status
	if current.status == "countdown" then
		local left = math.max(0, math.ceil((current.countdownEndsAt or 0) - workspace:GetServerTimeNow()))
		status = "Scambio tra " .. left .. "..."
	elseif current.myConfirmed then
		status = "Hai confermato. In attesa di " .. current.partnerName .. "..."
	elseif current.theirConfirmed then
		status = current.partnerName .. " ha confermato!"
	else
		status = "Scegli i meteoriti dal Deposito e conferma"
	end
	refs.status.Text = status
	refs.confirm.Text = current.myConfirmed and "Confermato ✓" or "CONFERMA"
	refs.confirm.BackgroundColor3 = current.myConfirmed and UI.Colors.Good or UI.Colors.Gold
end

local function buildWindow()
	window = UI.Panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.7, 0, 0.7, 0),
		Visible = false,
		Parent = gui,
	})
	UI.New("UISizeConstraint", { MaxSize = Vector2.new(900, 620), MinSize = Vector2.new(480, 360), Parent = window })
	refs.title = UI.Text({
		Size = UDim2.new(1, -20, 0, 34),
		Position = UDim2.fromOffset(10, 8),
		Text = "",
		TextColor3 = UI.Colors.Gold,
		MaxTextSize = 28,
		Parent = window,
	})
	local function column(x, title)
		UI.Text({
			Size = UDim2.new(0.32, -10, 0, 24),
			Position = UDim2.new(x, 8, 0, 48),
			Text = title,
			TextColor3 = UI.Colors.Muted,
			MaxTextSize = 18,
			Parent = window,
		})
		local l = UI.List({
			Size = UDim2.new(0.32, -10, 1, -150),
			Position = UDim2.new(x, 8, 0, 76),
			BackgroundTransparency = 0.6,
			BackgroundColor3 = Color3.fromRGB(10, 8, 20),
			Parent = window,
		}, 4)
		return l
	end
	refs.storage = column(0, "Il tuo Deposito (clicca per offrire)")
	refs.mine = column(0.34, "La tua offerta")
	refs.theirs = column(0.68, "La sua offerta")
	refs.status = UI.Text({
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.new(0, 10, 1, -70),
		Text = "",
		MaxTextSize = 18,
		Parent = window,
	})
	refs.confirm = UI.Button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(0.5, -8, 1, -10),
		Size = UDim2.fromOffset(180, 42),
		Text = "CONFERMA",
		Parent = window,
	}, function()
		Remotes.Get("TradeConfirm"):FireServer()
	end)
	UI.Button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0.5, 8, 1, -10),
		Size = UDim2.fromOffset(180, 42),
		Text = "ANNULLA",
		BackgroundColor3 = UI.Colors.Bad,
		Parent = window,
	}, function()
		Remotes.Get("TradeCancel"):FireServer()
	end)
end

local function renderPlayerList()
	UI.Clear(playerList)
	local any = false
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			any = true
			local rowFrame = UI.New("Frame", {
				Size = UDim2.new(1, -8, 0, 44),
				BackgroundColor3 = UI.Colors.PanelLight,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Parent = playerList,
			})
			UI.Corner(UDim.new(0, 8)).Parent = rowFrame
			UI.Text({
				Size = UDim2.new(0.6, -10, 1, 0),
				Position = UDim2.fromOffset(10, 0),
				Text = other.DisplayName,
				TextXAlignment = Enum.TextXAlignment.Left,
				MaxTextSize = 20,
				Parent = rowFrame,
			})
			UI.Button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.new(0.38, 0, 0, 34),
				Text = "Scambia",
				BackgroundColor3 = UI.Colors.Blue,
				Parent = rowFrame,
			}, function()
				Remotes.Get("TradeRequest"):FireServer(other.UserId)
				playerListPanel.Visible = false
			end)
		end
	end
	if not any then
		UI.Text({
			Size = UDim2.new(1, -8, 0, 40),
			Text = "Nessun altro giocatore nel server",
			TextColor3 = UI.Colors.Muted,
			MaxTextSize = 18,
			Parent = playerList,
		})
	end
end

function Trade:TogglePlayerList()
	playerListPanel.Visible = not playerListPanel.Visible
	if playerListPanel.Visible then
		renderPlayerList()
	end
end

local function showIncoming(fromUserId, fromName)
	local popup = UI.Panel({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -150, 0, 120),
		Size = UDim2.fromOffset(300, 110),
		Parent = gui,
	})
	UI.Text({
		Size = UDim2.new(1, -20, 0, 40),
		Position = UDim2.fromOffset(10, 8),
		Text = fromName .. " vuole scambiare con te!",
		MaxTextSize = 20,
		Parent = popup,
	})
	UI.Button({
		Position = UDim2.new(0, 10, 1, -50),
		Size = UDim2.new(0.5, -15, 0, 40),
		Text = "Accetta",
		BackgroundColor3 = UI.Colors.Good,
		Parent = popup,
	}, function()
		Remotes.Get("TradeRespond"):FireServer(fromUserId, true)
		popup:Destroy()
	end)
	UI.Button({
		Position = UDim2.new(0.5, 5, 1, -50),
		Size = UDim2.new(0.5, -15, 0, 40),
		Text = "Rifiuta",
		BackgroundColor3 = UI.Colors.Bad,
		Parent = popup,
	}, function()
		Remotes.Get("TradeRespond"):FireServer(fromUserId, false)
		popup:Destroy()
	end)
	task.delay(25, function()
		if popup.Parent then
			popup:Destroy()
		end
	end)
end

function Trade:Init()
	gui = UI.Screen("Trade", 15)
	playerListPanel = UI.Panel({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -150, 0.5, 0),
		Size = UDim2.fromOffset(300, 320),
		Visible = false,
		Parent = gui,
	})
	UI.Text({
		Size = UDim2.new(1, -20, 0, 30),
		Position = UDim2.fromOffset(10, 8),
		Text = "🤝 Scegli con chi scambiare",
		TextColor3 = UI.Colors.Gold,
		MaxTextSize = 22,
		Parent = playerListPanel,
	})
	UI.Text({
		Size = UDim2.new(1, -20, 0, 18),
		Position = UDim2.fromOffset(10, 38),
		Text = "Serve l'Evoluzione " .. Game.Trade.MinEvolution .. " per scambiare",
		TextColor3 = UI.Colors.Muted,
		MaxTextSize = 14,
		Parent = playerListPanel,
	})
	playerList = UI.List({
		Size = UDim2.new(1, -20, 1, -70),
		Position = UDim2.fromOffset(10, 62),
		Parent = playerListPanel,
	}, 6)
	buildWindow()
end

function Trade:Start()
	Remotes.Get("TradeIncoming").OnClientEvent:Connect(showIncoming)
	Remotes.Get("TradeState").OnClientEvent:Connect(function(state)
		current = state
		renderWindow()
	end)
	State.Changed:Connect(function()
		if current then
			renderWindow()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if current and current.status == "countdown" then
				renderWindow()
			end
		end
	end)
end

return Trade
