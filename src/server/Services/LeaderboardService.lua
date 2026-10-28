-- Global leaderboard of planets destroyed (all servers, all time), shown on a big board
-- next to the spawn. Uses an OrderedDataStore; falls back to the players in this server
-- when DataStores are unavailable (Studio without API access).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Game = require(Shared.Config.Game)
local Format = require(Shared.Util.Format)

local LeaderboardService = {}

local services
local store
pcall(function()
	store = DataStoreService:GetOrderedDataStore(Game.Leaderboard.StoreName)
end)

local rows = {} -- { {rank, name, value} TextLabels }
local nameCache = {}

local RANK_COLORS = {
	Color3.fromRGB(255, 205, 70),
	Color3.fromRGB(215, 225, 240),
	Color3.fromRGB(225, 150, 90),
}

local function nameFor(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	local name = player and player.DisplayName
	if not name then
		local ok, result = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		name = ok and result or "???"
	end
	nameCache[userId] = name
	return name
end

local function buildBoard()
	local cfg = Game.Leaderboard
	local board = Instance.new("Part")
	board.Name = "Leaderboard"
	board.Anchored = true
	board.Size = Vector3.new(26, 34, 1.5)
	board.CFrame = CFrame.lookAt(cfg.Position, Vector3.new(cfg.LookAt.X, cfg.Position.Y, cfg.LookAt.Z))
	board.Material = Enum.Material.Glass
	board.Color = Color3.fromRGB(20, 16, 40)
	board.Parent = workspace:FindFirstChild("World") or workspace

	local frame = Instance.new("Part")
	frame.Name = "LeaderboardFrame"
	frame.Anchored = true
	frame.CanCollide = false
	frame.Size = board.Size + Vector3.new(1.6, 1.6, -0.6)
	frame.CFrame = board.CFrame * CFrame.new(0, 0, 0.4)
	frame.Material = Enum.Material.Neon
	frame.Color = Color3.fromRGB(255, 195, 100)
	frame.Parent = board

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.Brightness = 1.5
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.11, 0)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 220, 140)
	title.TextStrokeTransparency = 0
	title.Text = "🪐 TOP PLANET DESTROYERS"
	title.Parent = gui

	for i = 1, cfg.Size do
		local y = 0.13 + (i - 1) * (0.86 / cfg.Size)
		local h = 0.86 / cfg.Size
		local color = RANK_COLORS[i] or Color3.fromRGB(255, 255, 255)
		local function label(x, w, align)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Position = UDim2.fromScale(x, y)
			t.Size = UDim2.fromScale(w, h * 0.9)
			t.Font = Enum.Font.FredokaOne
			t.TextScaled = true
			t.TextColor3 = color
			t.TextStrokeTransparency = 0.2
			t.TextXAlignment = align
			t.Text = ""
			t.Parent = gui
			return t
		end
		rows[i] = {
			rank = label(0.03, 0.12, Enum.TextXAlignment.Left),
			name = label(0.16, 0.56, Enum.TextXAlignment.Left),
			value = label(0.72, 0.25, Enum.TextXAlignment.Right),
		}
		rows[i].rank.Text = "#" .. i
	end
end

local function show(entries)
	for i, row in ipairs(rows) do
		local e = entries[i]
		row.name.Text = e and e.name or "-"
		row.value.Text = e and Format.Number(e.value) or ""
	end
end

local function localEntries()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local data = services.DataService:Get(p)
		if data then
			table.insert(list, { name = p.DisplayName, value = data.planetsDestroyed })
		end
	end
	table.sort(list, function(a, b)
		return a.value > b.value
	end)
	return list
end

local function refresh()
	if not store then
		show(localEntries())
		return
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local data = services.DataService:Get(p)
		if data and data.planetsDestroyed > 0 then
			pcall(store.SetAsync, store, tostring(p.UserId), data.planetsDestroyed)
		end
	end
	local ok, pages = pcall(store.GetSortedAsync, store, false, Game.Leaderboard.Size)
	if not ok then
		show(localEntries())
		return
	end
	local entries = {}
	for _, item in ipairs(pages:GetCurrentPage()) do
		table.insert(entries, { name = nameFor(tonumber(item.key)), value = item.value })
	end
	show(entries)
end

function LeaderboardService:Init(s)
	services = s
	buildBoard()
end

function LeaderboardService:Start()
	task.wait(5) -- let the first players load
	while true do
		refresh()
		task.wait(Game.Leaderboard.RefreshInterval)
	end
end

return LeaderboardService
