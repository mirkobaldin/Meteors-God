-- Access to the 3D models in ReplicatedStorage.Assets (see docs/ASSET_PIPELINE.md).
-- Every getter returns nil when the asset is missing, so callers fall back to generated visuals.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetLibrary = {}

local function root()
	return ReplicatedStorage:FindFirstChild("Assets")
end

-- Returns the template (not a clone) or nil.
function AssetLibrary.Get(category, name)
	local r = root()
	local folder = r and r:FindFirstChild(category)
	return folder and name and folder:FindFirstChild(name) or nil
end

-- Every template in a category (Models and Parts), sorted by name.
function AssetLibrary.All(category)
	local r = root()
	local folder = r and r:FindFirstChild(category)
	local list = {}
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Model") or child:IsA("BasePart") then
				table.insert(list, child)
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Name < b.Name
	end)
	return list
end

function AssetLibrary.Clone(category, name)
	local template = AssetLibrary.Get(category, name)
	return template and template:Clone() or nil
end

-- Body mesh for a meteor type (falls back to Meteors/Default).
function AssetLibrary.MeteorBody(typeId)
	local t = AssetLibrary.Get("Meteors", typeId) or AssetLibrary.Get("Meteors", "Default")
	if t and t:IsA("BasePart") then
		return t:Clone()
	end
	return nil
end

-- Meteor mesh parts: Assets/Meteors/<id> is a Model with MeshParts "Body" and "Jaw" (from the
-- Blender script), or a single MeshPart (body only). Returns body, jaw (clones) or nil.
function AssetLibrary.MeteorParts(typeId)
	local t = AssetLibrary.Get("Meteors", typeId) or AssetLibrary.Get("Meteors", "Default")
	if not t then
		return nil
	end
	if t:IsA("BasePart") then
		return t:Clone(), nil
	end
	local body = t:FindFirstChild("Body", true)
	if not body then
		for _, d in ipairs(t:GetDescendants()) do
			if d:IsA("MeshPart") and d.Name ~= "Jaw" then
				body = d
				break
			end
		end
	end
	local jaw = t:FindFirstChild("Jaw", true)
	return body and body:Clone() or nil, jaw and jaw:IsA("BasePart") and jaw:Clone() or nil
end

-- House for an evolution tier: exact tier, otherwise the closest lower one, otherwise any.
function AssetLibrary.House(tier)
	for t = tier, 1, -1 do
		local h = AssetLibrary.Get("Houses", "House" .. t)
		if h then
			return h:Clone()
		end
	end
	for t = tier + 1, 10 do
		local h = AssetLibrary.Get("Houses", "House" .. t)
		if h then
			return h:Clone()
		end
	end
	return nil
end

-- World CFrame of a marker inside a model (BasePart or Attachment), or nil.
function AssetLibrary.MarkerCFrame(model, path)
	local node = model
	for part in string.gmatch(path, "[^/]+") do
		node = node and node:FindFirstChild(part)
	end
	if not node then
		return nil
	end
	if node:IsA("BasePart") then
		return node.CFrame
	elseif node:IsA("Attachment") then
		return node.WorldCFrame
	end
	return nil
end

return AssetLibrary
