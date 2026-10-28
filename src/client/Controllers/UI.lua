-- Tiny UI toolkit used by every controller (consistent style, less boilerplate).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage:WaitForChild("Shared").Config.Assets)

local UI = {}

UI.Font = Enum.Font.FredokaOne
UI.Colors = {
	Panel = Color3.fromRGB(22, 16, 40),
	PanelLight = Color3.fromRGB(40, 30, 70),
	Gold = Color3.fromRGB(255, 205, 80),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(180, 170, 210),
	Good = Color3.fromRGB(90, 220, 120),
	Bad = Color3.fromRGB(255, 90, 90),
	Blue = Color3.fromRGB(90, 160, 255),
	Purple = Color3.fromRGB(170, 100, 255),
}

function UI.New(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function UI.Corner(radius)
	return UI.New("UICorner", { CornerRadius = radius or UDim.new(0, 12) })
end

function UI.Stroke(color, thickness, transparency)
	return UI.New("UIStroke", {
		Color = color or Color3.fromRGB(255, 255, 255),
		Thickness = thickness or 2,
		Transparency = transparency or 0.6,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.Padding(px)
	local u = UDim.new(0, px)
	return UI.New("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u })
end

function UI.Panel(props)
	props.BackgroundColor3 = props.BackgroundColor3 or UI.Colors.Panel
	props.BackgroundTransparency = props.BackgroundTransparency or 0.15
	props.BorderSizePixel = 0
	local f = UI.New("Frame", props)
	UI.Corner().Parent = f
	UI.Stroke(UI.Colors.Purple, 2, 0.5).Parent = f
	return f
end

function UI.Text(props)
	local maxSize = props.MaxTextSize or 28
	props.MaxTextSize = nil
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or UI.Font
	props.TextColor3 = props.TextColor3 or UI.Colors.Text
	props.TextScaled = props.TextScaled ~= false
	props.BorderSizePixel = 0
	local t = UI.New("TextLabel", props)
	if props.TextScaled ~= false then
		UI.New("UITextSizeConstraint", { MaxTextSize = maxSize, Parent = t })
	end
	return t
end

function UI.Button(props, onClick)
	local maxSize = props.MaxTextSize or 24
	props.MaxTextSize = nil
	props.BackgroundColor3 = props.BackgroundColor3 or UI.Colors.Gold
	props.Font = props.Font or UI.Font
	props.TextColor3 = props.TextColor3 or Color3.fromRGB(40, 25, 10)
	props.TextScaled = true
	props.AutoButtonColor = true
	props.BorderSizePixel = 0
	local b = UI.New("TextButton", props)
	UI.Corner(UDim.new(0, 10)).Parent = b
	UI.New("UITextSizeConstraint", { MaxTextSize = maxSize, Parent = b })
	UI.Padding(4).Parent = b
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

function UI.Screen(name, order)
	local gui = UI.New("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order or 0,
	})
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

-- Scrolling list with automatic vertical layout.
function UI.List(props, padding)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.BorderSizePixel = 0
	props.ScrollBarThickness = props.ScrollBarThickness or 6
	props.AutomaticCanvasSize = Enum.AutomaticSize.Y
	props.CanvasSize = UDim2.new(0, 0, 0, 0)
	local s = UI.New("ScrollingFrame", props)
	UI.New("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = s,
	})
	return s
end

function UI.Clear(container)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

-- Image icon from Config.Assets if uploaded, otherwise an emoji label. Fills its parent.
function UI.Icon(parent, imageId, emoji, props)
	props = props or {}
	local img = Assets.Image(imageId)
	if img then
		return UI.New("ImageLabel", {
			BackgroundTransparency = 1,
			Image = img,
			ScaleType = Enum.ScaleType.Fit,
			Size = props.Size or UDim2.fromScale(1, 1),
			Position = props.Position or UDim2.fromScale(0, 0),
			AnchorPoint = props.AnchorPoint or Vector2.zero,
			ZIndex = props.ZIndex or 2,
			Parent = parent,
		})
	end
	return UI.Text({
		Text = emoji or "?",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.fromScale(0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 2,
		MaxTextSize = props.MaxTextSize or 60,
		Parent = parent,
	})
end

-- Big square HUD button (icon + caption), like the left grid of popular simulators.
function UI.SquareButton(parent, props, onClick)
	local b = UI.New("TextButton", {
		Size = props.Size or UDim2.fromOffset(92, 92),
		LayoutOrder = props.LayoutOrder or 0,
		BackgroundColor3 = props.Color or UI.Colors.PanelLight,
		AutoButtonColor = true,
		Text = "",
		BorderSizePixel = 0,
		Parent = parent,
	})
	UI.Corner(UDim.new(0, 14)).Parent = b
	UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = b
	UI.New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 160, 200)),
		Rotation = 90,
		Parent = b,
	})
	UI.Icon(b, props.Icon, props.Emoji, {
		Size = UDim2.new(0.8, 0, 0.62, 0),
		Position = UDim2.new(0.1, 0, 0.04, 0),
	})
	local caption = UI.Text({
		Text = props.Text or "",
		Size = UDim2.new(1, -6, 0.3, 0),
		Position = UDim2.new(0, 3, 0.68, 0),
		TextStrokeTransparency = 0,
		ZIndex = 3,
		MaxTextSize = 20,
		Parent = b,
	})
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b, caption
end

-- Small red "!" notification dot in the top-right corner of a button.
function UI.Badge(parent)
	local dot = UI.New("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.92, 0.08),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = UI.Colors.Bad,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 10,
		Parent = parent,
	})
	UI.Corner(UDim.new(1, 0)).Parent = dot
	UI.Stroke(Color3.fromRGB(255, 255, 255), 2, 0).Parent = dot
	UI.Text({ Text = "!", Size = UDim2.fromScale(1, 1), ZIndex = 11, MaxTextSize = 18, Parent = dot })
	return dot
end

-- Standard window: header bar with icon + big title + red X, and a content frame.
-- Returns window, content, header.
function UI.Window(gui, props)
	local window = UI.Panel({
		Name = props.Name or "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.new(0.62, 0, 0.66, 0),
		BackgroundColor3 = Color3.fromRGB(18, 14, 34),
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = gui,
	})
	UI.New("UISizeConstraint", {
		MaxSize = props.MaxSize or Vector2.new(900, 620),
		MinSize = props.MinSize or Vector2.new(420, 300),
		Parent = window,
	})
	local header = UI.New("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = props.HeaderColor or Color3.fromRGB(70, 60, 130),
		BorderSizePixel = 0,
		Parent = window,
	})
	UI.Corner().Parent = header
	UI.New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 140, 190)),
		Rotation = 90,
		Parent = header,
	})
	UI.Icon(header, props.Icon, props.Emoji, {
		Size = UDim2.fromOffset(52, 52),
		Position = UDim2.fromOffset(10, 6),
		MaxTextSize = 40,
	})
	UI.Text({
		Text = props.Title or "",
		Size = UDim2.new(1, -150, 1, -12),
		Position = UDim2.fromOffset(72, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 0,
		MaxTextSize = 42,
		Parent = header,
	})
	local close = UI.Button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(52, 48),
		Text = "X",
		BackgroundColor3 = UI.Colors.Bad,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		MaxTextSize = 32,
		Parent = header,
	}, function()
		window.Visible = false
	end)
	local content = UI.New("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -24, 1, -84),
		Position = UDim2.fromOffset(12, 74),
		BackgroundTransparency = 1,
		Parent = window,
	})
	return window, content, header, close
end

return UI
