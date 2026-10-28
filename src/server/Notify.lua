-- Small helpers to send toasts and server-wide announcements.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local toastRemote = Remotes.Get("Toast")
local announceRemote = Remotes.Get("Announce")

local Notify = {}

-- kind: "info" | "good" | "bad"
function Notify.Toast(player, text, kind)
	toastRemote:FireClient(player, text, kind or "info")
end

-- Big banner for everyone: keep it for the moments that matter (phases, events, planets destroyed).
function Notify.Announce(text, color)
	announceRemote:FireAllClients(text, color or Color3.fromRGB(255, 220, 120))
end

-- Chat line only (no banner): other players' achievements, planet layers...
function Notify.Chat(text, color)
	announceRemote:FireAllClients(text, color or Color3.fromRGB(255, 220, 120), true)
end

return Notify
