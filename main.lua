
-- GMON Hub Main Script
-- UI Background and Toggle
local CoreGui = game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "GMON_MainUI"

local BG = Instance.new("ImageLabel", ScreenGui)
BG.Name = "Background"
BG.Size = UDim2.new(0, 600, 0, 400)
BG.Position = UDim2.new(0.5, -300, 0.5, -200)
BG.BackgroundTransparency = 1
BG.Image = "rbxassetid://88817335071002"

-- Toggle Button
local Toggle = Instance.new("ImageButton", ScreenGui)
Toggle.Size = UDim2.new(0, 40, 0, 40)
Toggle.Position = UDim2.new(0, 20, 0.5, -100)
Toggle.BackgroundTransparency = 1
Toggle.Image = "rbxassetid://94747801090737"

Toggle.MouseButton1Click:Connect(function()
    BG.Visible = not BG.Visible
end)

-- GMON Hub Label
local Title = Instance.new("TextLabel", BG)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "GMON Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255,255,255)

-- Sample Tab: Auto Farm
local AutoFarm = Instance.new("TextButton", BG)
AutoFarm.Size = UDim2.new(0, 200, 0, 40)
AutoFarm.Position = UDim2.new(0, 20, 0, 60)
AutoFarm.Text = "Auto Farm"
AutoFarm.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
AutoFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoFarm.MouseButton1Click:Connect(function()
    print("Auto Farm Activated")
end)
