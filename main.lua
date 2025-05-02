-- GMON Main Script UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "GMONMain"

local background = Instance.new("ImageLabel", ScreenGui)
background.Size = UDim2.new(0, 500, 0, 350)
background.Position = UDim2.new(0.5, -250, 0.5, -175)
background.Image = "rbxassetid://88817335071002"
background.BackgroundTransparency = 1

local title = Instance.new("TextLabel", background)
title.Text = "GMON Hub"
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 10)
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.BackgroundTransparency = 1

-- Auto Farm Button (contoh)
local farmBtn = Instance.new("TextButton", background)
farmBtn.Text = "Auto Farm"
farmBtn.Size = UDim2.new(0.4, 0, 0, 40)
farmBtn.Position = UDim2.new(0.05, 0, 0.3, 0)
farmBtn.TextScaled = true

farmBtn.MouseButton1Click:Connect(function()
    print("Auto Farm Started")
end)
