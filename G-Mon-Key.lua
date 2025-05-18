-- SETTINGS
local VALID_KEY = "GMONFREE2024"
local rgbSpeed = 0.5

-- UI Setup
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local player =
game.Players.LocalPlayer

local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "GMon_KeyUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0, 400, 0, 200)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.ClipsDescendants = true
frame.Name = "MainFrame"

-- UICorner
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 15)

-- RGB Border
local border = Instance.new("UIStroke", frame)
border.Thickness = 2
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
border.Color = Color3.fromRGB(255, 0, 0)

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "G-MON KEY SYSTEM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true

-- Close Button
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", closeBtn)

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- TextBox for Key
local input = Instance.new("TextBox", frame)
input.PlaceholderText = "Enter Your Key..."
input.Size = UDim2.new(0.8, 0, 0, 30)
 -- Sebelumnya 40
input.TextSize = 14 
-- Tambahkan jika ingin kontrol manual
input.Position = UDim2.new(0.1, 0, 0.35, 0)
input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.Font = Enum.Font.Gotham
input.TextScaled = true
input.ClearTextOnFocus = false
Instance.new("UICorner", input)

-- Check Button
local checkBtn = Instance.new("TextButton", frame)
checkBtn.Size = UDim2.new(0.35, 0, 0, 30)
-- dari 35 ke 30
checkBtn.Position = UDim2.new(0.1, 0, 0.7, 0)
checkBtn.Text = "Check Key"
checkBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
checkBtn.Font = Enum.Font.GothamBold
checkBtn.TextScaled = true
checkBtn.TextSize = 14
Instance.new("UICorner", checkBtn)

-- Get Key Button
local getKeyBtn = Instance.new("TextButton", frame)
getKeyBtn.Size = UDim2.new(0.35, 0, 0, 30)
getKeyBtn.Position = UDim2.new(0.55, 0, 0.7, 0)
getKeyBtn.Text = "Get Key"
getKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
getKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
getKeyBtn.Font = Enum.Font.GothamBold
getKeyBtn.TextScaled = true
getKeyBtn.TextSize = 14
Instance.new("UICorner", getKeyBtn)

getKeyBtn.MouseButton1Click:Connect(function()
	setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
	StarterGui:SetCore("SendNotification", {
		Title = "G-Mon Hub",
		Text = "Key copied to clipboard!",
		Duration = 4
	})
end)

local validKey = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"

checkBtn.MouseButton1Click:Connect(function()
	if input.Text == validKey then
		StarterGui:SetCore("SendNotification", {
			Title = "Key Valid!",
			Text = "Welcome to G-Mon Hub",
			Duration = 3
		})
		wait(0.5)
		screenGui:Destroy()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/main.lua"))()
	else
		StarterGui:SetCore("SendNotification", {
			Title = "Invalid Key!",
			Text = "Please get a valid key.",
			Duration = 3
		})
	end
end)

-- RGB Border Animation
spawn(function()
	while task.wait(rgbSpeed) do
		local t = tick() * 2
		border.Color = Color3.fromHSV(t % 1, 1, 1)
	end
end)

-- Drag system
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)