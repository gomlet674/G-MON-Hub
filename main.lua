local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- UI Container
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name = "GMON_UI"
screenGui.ResetOnSpawn = false

-- UI Main Frame
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 700, 0, 400)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -200)
mainFrame.BackgroundTransparency = 1
mainFrame.ClipsDescendants = true

-- RGB Outline Frame
local outline = Instance.new("Frame", mainFrame)
outline.Size = UDim2.new(1, 4, 1, 4)
outline.Position = UDim2.new(0, -2, 0, -2)
outline.BorderSizePixel = 0
outline.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

-- Create a UIStroke for animated RGB border
local stroke = Instance.new("UIStroke", outline)
stroke.Thickness = 4
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Color = Color3.fromRGB(255, 0, 0)

-- Color Animation (Rainbow Border)
task.spawn(function()
	local t = 0
	while true do
		t += 0.01
		local r = math.sin(t) * 127 + 128
		local g = math.sin(t + 2) * 127 + 128
		local b = math.sin(t + 4) * 127 + 128
		stroke.Color = Color3.fromRGB(r, g, b)
		wait(0.03)
	end
end)

-- Title Label (GMON)
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(0, 100, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.Text = "GMON"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold

-- Tab Buttons
local tabNames = {"Main", "Item", "Laut", "Prehistoric", "Kitsune"}
local tabs = {}

for i, name in ipairs(tabNames) do
	local tab = Instance.new("TextButton", mainFrame)
	tab.Size = UDim2.new(0, 100, 0, 30)
	tab.Position = UDim2.new(0, 120 + (i - 1) * 105, 0, 10)
	tab.Text = name
	tab.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	tab.TextColor3 = Color3.fromRGB(255, 255, 255)
	tab.Font = Enum.Font.Gotham
	tab.TextSize = 16
	tab.BorderSizePixel = 0
	tabs[name] = tab
end

-- Inner UI Panel
local panel = Instance.new("Frame", mainFrame)
panel.Position = UDim2.new(0, 10, 0, 50)
panel.Size = UDim2.new(1, -20, 1, -60)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
panel.BorderSizePixel = 0

-- Avatar Icon
local avatar = Instance.new("ImageLabel", panel)
avatar.Size = UDim2.new(0, 60, 0, 60)
avatar.Position = UDim2.new(0.5, -30, 0, 10)
avatar.BackgroundTransparency = 1
avatar.Image = "rbxassetid://7072718362" -- Ganti dengan avatar ID kamu

-- Boss Name
local bossLabel = Instance.new("TextLabel", panel)
bossLabel.Position = UDim2.new(0.5, -75, 0, 80)
bossLabel.Size = UDim2.new(0, 150, 0, 30)
bossLabel.Text = "Bobby"
bossLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
bossLabel.TextSize = 20
bossLabel.BackgroundTransparency = 1
bossLabel.Font = Enum.Font.GothamBold

-- Toggle Button
local toggle = Instance.new("TextButton", panel)
toggle.Size = UDim2.new(0, 100, 0, 30)
toggle.Position = UDim2.new(0.5, -50, 0, 120)
toggle.Text = "Auto Farm: OFF"
toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Font = Enum.Font.Gotham
toggle.TextSize = 14
toggle.BorderSizePixel = 0

local isOn = false
toggle.MouseButton1Click:Connect(function()
	isOn = not isOn
	toggle.Text = isOn and "Auto Farm: ON" or "Auto Farm: OFF"
	toggle.BackgroundColor3 = isOn and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)
