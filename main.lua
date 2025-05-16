-- GMON HUB - UI Tanpa Rayfield, dengan Toggle dan RGB Border

-- Load fitur source.lua
local GMON = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua"))()

-- Buat GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GMON_UI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Frame utama
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 400, 0, 250)
Frame.Position = UDim2.new(0.5, -200, 0.5, -125)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true

-- Corner & RGB Stroke
local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 12)

local UIStroke = Instance.new("UIStroke", Frame)
UIStroke.Thickness = 2
spawn(function()
	while wait() do
		for i = 0, 255, 4 do
			UIStroke.Color = Color3.fromHSV(i/255, 1, 1)
			wait()
		end
	end
end)

-- Judul
local Title = Instance.new("TextLabel")
Title.Text = "GMON HUB"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Parent = Frame

-- Tombol ESP God Chalice
local ESPBtn = Instance.new("TextButton")
ESPBtn.Size = UDim2.new(0, 350, 0, 40)
ESPBtn.Position = UDim2.new(0, 25, 0, 60)
ESPBtn.Text = "ESP God Chalice"
ESPBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ESPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPBtn.Parent = Frame
ESPBtn.MouseButton1Click:Connect(function()
	GMON.ESPGodChalice()
end)

-- Tombol Farm Chest
local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(0, 350, 0, 40)
FarmBtn.Position = UDim2.new(0, 25, 0, 110)
FarmBtn.Text = "Auto Farm Chest"
FarmBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.Parent = Frame
FarmBtn.MouseButton1Click:Connect(function()
	GMON.FarmChest()
end)

-- Tombol Toggle (kanan layar, RGB)
local ToggleGui = Instance.new("ScreenGui", game.CoreGui)
ToggleGui.Name = "GMON_Toggle"

local ToggleBtn = Instance.new("TextButton", ToggleGui)
ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
ToggleBtn.Position = UDim2.new(1, -60, 0.5, -20)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = "G"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local corner = Instance.new("UICorner", ToggleBtn)
corner.CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new("UIStroke", ToggleBtn)
toggleStroke.Thickness = 2

spawn(function()
	while wait() do
		for i = 0, 255, 4 do
			toggleStroke.Color = Color3.fromHSV(i/255, 1, 1)
			wait()
		end
	end
end)

local isVisible = true
ToggleBtn.MouseButton1Click:Connect(function()
	isVisible = not isVisible
	Frame.Visible = isVisible
end)