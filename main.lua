-- GMON Hub Final Version [Visual Fix & Draggable Smooth]

local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "GMON_Hub"

local toggle = false

-- Main button (pojok kiri atas)
local openButton = Instance.new("TextButton")
openButton.Parent = screenGui
openButton.Size = UDim2.new(0, 40, 0, 40)
openButton.Position = UDim2.new(0, 10, 0, 10)
openButton.Text = ""
openButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
openButton.BorderSizePixel = 0
openButton.BackgroundTransparency = 0.2
openButton.Name = "ToggleButton"

-- Circle style
local uicorner = Instance.new("UICorner", openButton)
uicorner.CornerRadius = UDim.new(1, 0)

-- Main UI frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 350)
mainFrame.Position = UDim2.new(0, 60, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)

-- Title Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "GMON Hub - Blox Fruits"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = mainFrame

-- Layout container
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = mainFrame

-- Padding
local padding = Instance.new("UIPadding", mainFrame)
padding.PaddingTop = UDim.new(0, 40)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)

-- Function to create toggle row
local function createToggle(text)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 30)
	holder.BackgroundTransparency = 1

	local label = Instance.new("TextLabel")
	label.Parent = holder
	label.Text = text
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.SourceSans
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Left

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Parent = holder
	toggleBtn.Text = "OFF"
	toggleBtn.Size = UDim2.new(0.25, 0, 1, 0)
	toggleBtn.Position = UDim2.new(0.75, 0, 0, 0)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
	toggleBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleBtn.Font = Enum.Font.SourceSansBold
	toggleBtn.TextSize = 16
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

	local state = false
	toggleBtn.MouseButton1Click:Connect(function()
		state = not state
		toggleBtn.Text = state and "ON" or "OFF"
		toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(100, 0, 0)
	end)

	holder.Parent = mainFrame
end

-- Create toggle features
createToggle("Auto Farm")
createToggle("Farm Boss")
createToggle("Fast Attack")
createToggle("Farm Chest")
createToggle("Auto Buso")
createToggle("Auto Ken")
createToggle("Bring Mob")

-- Info box
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 40)
infoLabel.BackgroundTransparency = 1
infoLabel.TextWrapped = true
infoLabel.Text = "Made by GMON. UI Final Build. No bugs reported."
infoLabel.TextColor3 = Color3.new(1,1,1)
infoLabel.Font = Enum.Font.SourceSansItalic
infoLabel.TextSize = 16
infoLabel.TextYAlignment = Enum.TextYAlignment.Center
infoLabel.Parent = mainFrame

-- Button toggle logic
openButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)