-- Tiny UI toolkit used by every controller (consistent style, less boilerplate).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage:WaitForChild("Shared").Config.Assets)

local UI = {}

UI.Font = Enum.Font.GothamBold
UI.TitleFont = Enum.Font.GothamBlack
-- Theme A "Sky Ruins" (art/ui/A): weathered sandstone, teal copper, glowing cyan runes.
UI.Colors = {
	Panel = Color3.fromRGB(20, 26, 42),
	PanelLight = Color3.fromRGB(34, 46, 68),
	Gold = Color3.fromRGB(236, 200, 140), -- sandstone: titles and highlights
	Cyan = Color3.fromRGB(111, 216, 255),
	Copper = Color3.fromRGB(79, 163, 160),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(170, 175, 215),
	Good = Color3.fromRGB(80, 210, 140),
	Bad = Color3.fromRGB(240, 85, 95),
	Blue = Color3.fromRGB(80, 150, 255),
	Purple = Color3.fromRGB(150, 110, 255),
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

-- UI art (Config/Assets.UI.Images, uploaded from art/ui/A). Without it the code falls back to the
-- plain colored frames. 9-slice rectangles come from art/ui/validation.json.
local IMAGES = Assets.UI and Assets.UI.Images or {}
local SLICE = {
	frame_window = Rect.new(64, 64, 448, 448),
	frame_panel = Rect.new(64, 64, 448, 448),
	frame_tooltip = Rect.new(64, 64, 192, 192),
	frame_banner = Rect.new(64, 64, 960, 192),
	button = Rect.new(48, 48, 464, 112),
	button_pressed = Rect.new(48, 50, 464, 114),
	button_tab = Rect.new(47, 47, 209, 49),
	pill = Rect.new(128, 48, 448, 80),
	bar_back = Rect.new(32, 24, 480, 40),
}

function UI.Art(key)
	return Assets.Image(IMAGES[key])
end

-- Puts a 9-slice image behind the children of `gui` (which turns transparent). Returns the image.
function UI.Skin(gui, key, sliceKey, sliceScale)
	local img = UI.Art(key)
	if not img then
		return nil
	end
	gui.BackgroundTransparency = 1
	local skin = UI.New("ImageLabel", {
		Name = "Skin",
		BackgroundTransparency = 1,
		Image = img,
		ScaleType = SLICE[sliceKey or key] and Enum.ScaleType.Slice or Enum.ScaleType.Stretch,
		SliceCenter = SLICE[sliceKey or key] or Rect.new(0, 0, 0, 0),
		SliceScale = sliceScale or 0.5,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = gui,
	})
	return skin
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

-- Stone panel with a copper frame (frame_panel), or a dark glass panel with a thin edge.
-- With the art the panel itself is an ImageLabel (not a Frame with an image child), so list and
-- grid layouts inside it keep working.
function UI.Panel(props)
	local art = UI.Art("frame_panel")
	if art then
		props.BackgroundTransparency = 1
		props.BorderSizePixel = 0
		props.Image = art
		props.ScaleType = Enum.ScaleType.Slice
		props.SliceCenter = SLICE.frame_panel
		props.SliceScale = props.SliceScale or 0.25
		return UI.New("ImageLabel", props)
	end
	props.BackgroundColor3 = props.BackgroundColor3 or UI.Colors.Panel
	props.BackgroundTransparency = props.BackgroundTransparency or 0.12
	props.BorderSizePixel = 0
	local f = UI.New("Frame", props)
	UI.Corner(UDim.new(0, 16)).Parent = f
	UI.Stroke(UI.Colors.Gold, 1.5, 0.35).Parent = f
	UI.New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 160, 210)),
		Rotation = 90,
		Parent = f,
	})
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

-- Which button art fits a background color: bright warm/green/cyan = main, red = red,
-- blue/purple = blue, dark (disabled, not affordable) = the "off" tab.
local function buttonStyle(color)
	local h, sat, v = color:ToHSV()
	if v < 0.5 then
		return "off"
	elseif sat > 0.4 and (h < 0.04 or h > 0.92) then
		return "red"
	elseif h >= 0.04 and h < 0.56 then
		return "main"
	end
	return "blue"
end

local function buttonImages(style)
	if style == "off" then
		return { normal = "button_tab_off", hover = "button_tab_off", pressed = "button_tab_off", slice = "button_tab" }
	end
	local p = "button_" .. style .. "_"
	return { normal = p .. "normal", hover = p .. "hover", pressed = p .. "pressed", slice = "button" }
end

-- Skins a TextButton with the button art; follows later BackgroundColor3 changes (state colors).
-- Children are drawn over their parent, so the button's own text would be hidden by the art: it is
-- shown by a child label that mirrors Text / TextColor3. Returns that label (nil without art).
local function skinButton(b, autoText)
	if not UI.Art("button_main_normal") then
		return nil
	end
	local skin = UI.Skin(b, "button_main_normal", "button", 0.3)
	-- UI.Button adds a 4 px UIPadding: the art still covers the whole button.
	skin.Position = UDim2.fromOffset(-4, -4)
	skin.Size = UDim2.new(1, 8, 1, 8)
	local label = UI.New("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = b.Font,
		Text = b.Text,
		RichText = b.RichText,
		TextColor3 = b.TextColor3,
		TextStrokeTransparency = b.TextStrokeTransparency,
		TextScaled = true,
		ZIndex = 2,
		Parent = b,
	})
	b.TextTransparency = 1
	b:GetPropertyChangedSignal("Text"):Connect(function()
		label.Text = b.Text
	end)
	if not autoText then
		b:GetPropertyChangedSignal("TextColor3"):Connect(function()
			label.TextColor3 = b.TextColor3
		end)
	end
	local hovered, held = false, false
	local function apply()
		local style = buttonStyle(b.BackgroundColor3)
		local set = buttonImages(style)
		local key = held and set.pressed or hovered and set.hover or set.normal
		skin.Image = UI.Art(key) or skin.Image
		skin.SliceCenter = SLICE[(held and set.slice == "button") and "button_pressed" or set.slice]
		label.Position = UDim2.fromOffset(0, held and 2 or 0)
		b.BackgroundTransparency = 1
		if autoText then
			label.TextColor3 = style == "main" and Color3.fromRGB(16, 30, 48) or UI.Colors.Text
			label.TextStrokeTransparency = style == "main" and 1 or 0.4
		end
	end
	b.AutoButtonColor = false
	b.MouseEnter:Connect(function()
		hovered = true
		apply()
	end)
	b.MouseLeave:Connect(function()
		hovered, held = false, false
		apply()
	end)
	b.MouseButton1Down:Connect(function()
		held = true
		apply()
	end)
	b.MouseButton1Up:Connect(function()
		held = false
		apply()
	end)
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(apply)
	apply()
	return label
end

function UI.Button(props, onClick)
	local maxSize = props.MaxTextSize or 24
	props.MaxTextSize = nil
	local autoText = props.TextColor3 == nil
	props.BackgroundColor3 = props.BackgroundColor3 or UI.Colors.Gold
	props.Font = props.Font or UI.TitleFont
	props.TextColor3 = props.TextColor3 or Color3.fromRGB(35, 22, 8)
	props.TextScaled = true
	props.AutoButtonColor = true
	props.BorderSizePixel = 0
	local b = UI.New("TextButton", props)
	local label = skinButton(b, autoText)
	if label then
		UI.New("UITextSizeConstraint", { MaxTextSize = maxSize, Parent = label })
	else
		UI.Corner(UDim.new(0, 12)).Parent = b
		UI.New("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 210)),
			Rotation = 90,
			Parent = b,
		})
	end
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
	if not UI.Skin(b, "frame_tooltip", nil, 0.3) then
		UI.Corner(UDim.new(0, 14)).Parent = b
		UI.Stroke(Color3.fromRGB(10, 5, 20), 3, 0).Parent = b
		UI.New("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 160, 200)),
			Rotation = 90,
			Parent = b,
		})
	end
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

-- Round "orb" button with a glowing ring and a caption underneath.
function UI.Orb(parent, props, onClick)
	local size = props.Size or 64
	local holder = UI.New("Frame", {
		Size = UDim2.fromOffset(size + 24, size + 22),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = parent,
	})
	local b = UI.New("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = props.Color or UI.Colors.PanelLight,
		BackgroundTransparency = 0.05,
		AutoButtonColor = true,
		Text = "",
		BorderSizePixel = 0,
		Parent = holder,
	})
	UI.Corner(UDim.new(1, 0)).Parent = b
	UI.Stroke(props.Ring or UI.Colors.Copper, 3, 0.05).Parent = b
	UI.New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 130, 190)),
		Rotation = 120,
		Parent = b,
	})
	UI.Icon(b, props.Icon, props.Emoji, {
		Size = UDim2.fromScale(0.62, 0.62),
		Position = UDim2.fromScale(0.19, 0.19),
		MaxTextSize = math.floor(size * 0.5),
	})
	local caption = UI.Text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, size + 2),
		Size = UDim2.new(1, 8, 0, 18),
		Text = props.Text or "",
		Font = UI.TitleFont,
		TextStrokeTransparency = 0.2,
		MaxTextSize = 14,
		Parent = holder,
	})
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b, caption, holder
end

-- Standard window: title + gold divider + round close button, and a content frame.
-- Returns window, content, header, close.
function UI.Window(gui, props)
	local window = UI.Panel({
		Name = props.Name or "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.new(0.62, 0, 0.66, 0),
		BackgroundTransparency = 0.06,
		Visible = false,
		Parent = gui,
	})
	-- The window art has a thick stone frame: everything moves `pad` pixels inwards.
	local pad = 0
	if window:IsA("ImageLabel") and UI.Art("frame_window") then
		window.Image = UI.Art("frame_window")
		window.SliceScale = 0.5
		pad = 14
	end
	UI.New("UISizeConstraint", {
		MaxSize = props.MaxSize or Vector2.new(900, 620),
		MinSize = props.MinSize or Vector2.new(420, 300),
		Parent = window,
	})
	local header = UI.New("Frame", {
		Position = UDim2.fromOffset(pad, pad),
		Size = UDim2.new(1, -pad * 2, 0, 62),
		BackgroundTransparency = 1,
		Parent = window,
	})
	local badge = UI.New("Frame", {
		Position = UDim2.fromOffset(16, 9),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = props.HeaderColor or UI.Colors.Purple,
		BorderSizePixel = 0,
		Parent = header,
	})
	UI.Corner(UDim.new(1, 0)).Parent = badge
	UI.Stroke(UI.Colors.Copper, 2.5, 0).Parent = badge
	UI.Icon(badge, props.Icon, props.Emoji, {
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.15, 0.15),
		MaxTextSize = 26,
	})
	UI.Text({
		Text = string.upper(props.Title or ""),
		Size = UDim2.new(1, -150, 0, 34),
		Position = UDim2.fromOffset(72, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = UI.TitleFont,
		TextColor3 = UI.Colors.Gold,
		MaxTextSize = 30,
		Parent = header,
	})
	UI.New("Frame", {
		Position = UDim2.new(0, 24, 1, -1),
		Size = UDim2.new(1, -48, 0, 2),
		BackgroundColor3 = UI.Colors.Copper,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Parent = header,
	})
	local close = UI.New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = UI.Colors.PanelLight,
		Text = "✕",
		Font = UI.TitleFont,
		TextScaled = true,
		TextColor3 = UI.Colors.Gold,
		AutoButtonColor = true,
		BorderSizePixel = 0,
		Parent = header,
	})
	local closeArt = UI.Art("button_close")
	if closeArt then
		close.Text = ""
		close.BackgroundTransparency = 1
		close.Size = UDim2.fromOffset(46, 46)
		UI.New("ImageLabel", {
			BackgroundTransparency = 1,
			Image = closeArt,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
			Parent = close,
		})
	else
		UI.Corner(UDim.new(1, 0)).Parent = close
		UI.Stroke(UI.Colors.Gold, 1.5, 0.3).Parent = close
		UI.Padding(9).Parent = close
	end
	close.Activated:Connect(function()
		window.Visible = false
	end)
	local content = UI.New("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -32 - pad * 2, 1, -80 - pad * 2),
		Position = UDim2.fromOffset(16 + pad, 70 + pad),
		BackgroundTransparency = 1,
		Parent = window,
	})
	return window, content, header, close
end

return UI
