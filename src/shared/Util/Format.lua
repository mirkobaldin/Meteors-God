local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }

-- 1234 -> "1.23K", 5600000 -> "5.6M"
function Format.Number(n)
	n = tonumber(n) or 0
	if math.abs(n) < 1000 then
		return tostring(math.floor(n))
	end
	local i = 1
	while math.abs(n) >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	local s
	if math.abs(n) >= 100 then
		s = string.format("%d", math.floor(n))
	elseif math.abs(n) >= 10 then
		s = string.format("%.1f", math.floor(n * 10) / 10)
	else
		s = string.format("%.2f", math.floor(n * 100) / 100)
	end
	if s:find("%.") then
		s = s:gsub("0+$", ""):gsub("%.$", "")
	end
	return s .. SUFFIXES[i]
end

-- 125 -> "2:05"
function Format.Time(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

return Format
