-- Keeps only one big window open at a time.

local Panels = {}

local registry = {} -- [name] = {frame, onOpen}

function Panels.Register(name, frame, onOpen)
	registry[name] = { frame = frame, onOpen = onOpen }
end

function Panels.Close(name)
	local p = registry[name]
	if p then
		p.frame.Visible = false
	end
end

function Panels.CloseAll()
	for _, p in pairs(registry) do
		p.frame.Visible = false
	end
end

function Panels.IsOpen(name)
	local p = registry[name]
	return p ~= nil and p.frame.Visible
end

function Panels.Open(name)
	local p = registry[name]
	if not p then
		return
	end
	Panels.CloseAll()
	p.frame.Visible = true
	if p.onOpen then
		task.spawn(p.onOpen)
	end
end

function Panels.Toggle(name)
	if Panels.IsOpen(name) then
		Panels.Close(name)
	else
		Panels.Open(name)
	end
end

return Panels
