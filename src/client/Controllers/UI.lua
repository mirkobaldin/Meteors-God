-- Tiny UI toolkit used by every controller (consistent style, less boilerplate).

local Players = game:GetService("Players")

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

return UI
