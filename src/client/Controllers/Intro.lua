-- Title screen shown for a few seconds when the game loads (UI art: loading_background + logo).

local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)

local Intro = {}

function Intro:Start()
	local background, logo = UI.Art("loading_background"), UI.Art("logo")
	if not background or not logo then
		return
	end
	local gui = UI.Screen("Intro", 100)
	gui.IgnoreGuiInset = true
	local bg = UI.New("ImageLabel", {
		BackgroundColor3 = Color3.fromRGB(10, 12, 24),
		Image = background,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	local title = UI.New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.6, 0.45),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		Parent = bg,
	})
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ bg, title })
		end)
		task.wait(2.5)
		local info = TweenInfo.new(0.8)
		TweenService:Create(bg, info, { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, info, { ImageTransparency = 1 }):Play()
		task.wait(0.9)
		gui:Destroy()
	end)
end

return Intro
