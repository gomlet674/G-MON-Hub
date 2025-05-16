-- GMON HUB - Custom UI tanpa Rayfield
-- By gomlet674

-- Load fitur dari source.lua
local GMON = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

-- UI Library Buatan Sendiri
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GMONHubUI"
ScreenGui.ResetOnSpawn = false

-- Frame Utama
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 250)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

-- RGB Border
local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 12)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Thickness = 3
spawn(function()
	while true do
		for i = 0, 255, 4 do
			UIStroke.Color = Color3.fromHSV(i / 255, 1, 1)
			wait()
		end
	end
end)

-- Title
local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "GMON HUB"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.TextScaled = true

-- Button ESP God Chalice
local Button1 = Instance.new("TextButton", MainFrame)
Button1.Size = UDim2.new(0, 300, 0, 40)
Button1.Position = UDim2.new(0, 25, 0, 50)
Button1.Text = "ESP God Chalice"
Button1.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Button1.TextColor3 = Color3.fromRGB(255, 255, 255)
Button1.MouseButton1Click:Connect(function()
	GMON.ESPGodChalice()
end)

-- Button Farm Chest
local Button2 = Instance.new("TextButton", MainFrame)
Button2.Size = UDim2.new(0, 300, 0, 40)
Button2.Position = UDim2.new(0, 25, 0, 100)
Button2.Text = "Start Farm Chest"
Button2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Button2.TextColor3 = Color3.fromRGB(255, 255, 255)
Button2.MouseButton1Click:Connect(function()
	GMON.FarmChest()
end)

-- Toggle UI Button (RGB melingkar)
local ToggleUI = Instance.new("ScreenGui", game.CoreGui)
ToggleUI.Name = "GMON_Toggle"

local ToggleBtn = Instance.new("TextButton", ToggleUI)
ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
ToggleBtn.Position = UDim2.new(1, -60, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = "G"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local ToggleUICorner = Instance.new("UICorner", ToggleBtn)
ToggleUICorner.CornerRadius = UDim.new(1, 0)

local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Thickness = 2

spawn(function()
	while true do
		for i = 0, 255, 5 do
			ToggleStroke.Color = Color3.fromHSV(i / 255, 1, 1)
			wait()
		end
	end
end)

local visible = true
ToggleBtn.MouseButton1Click:Connect(function()
	visible = not visible
	MainFrame.Visible = visible
end)