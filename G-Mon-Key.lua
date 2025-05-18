-- G-Mon-Key.lua

-- SETTINGS
local VALID_KEY = "GmonHub311851f3c742a8f78dce99e56992555609d23497928e9b33802e7127610c2e"
local rgbSpeed = 0.5

-- SERVICES
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")

-- GUI PARENT (CoreGui untuk executor, PlayerGui untuk Studio)
local parentGui = (game:GetService("RunService"):IsStudio() and
    game.Players.LocalPlayer:WaitForChild("PlayerGui")) or
    game:GetService("CoreGui")

-- MAIN SCREENGUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GMon_KeyUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = parentGui

-- MAIN FRAME
local frame = Instance.new("Frame", screenGui)
frame.AnchorPoint        = Vector2.new(0.5, 0.5)
frame.Position           = UDim2.new(0.5, 0, 0.5, 0)
frame.Size               = UDim2.new(0, 400, 0, 160)
frame.BackgroundColor3   = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.1
frame.Name               = "MainFrame"
frame.ClipsDescendants   = true

-- ROUNDED CORNERS
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

-- RGB BORDER
local border = Instance.new("UIStroke", frame)
border.Thickness         = 2
border.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border

-- BORDER ANIMATION
task.spawn(function()
    while frame.Parent do
        for hue = 0, 1, 0.01 do
            border.Color = Color3.fromHSV(hue, 1, 1)
            task.wait(rgbSpeed)
        end
    end
end)

-- TITLE
local title = Instance.new("TextLabel", frame)
title.Size               = UDim2.new(1, -20, 0, 30)
title.Position           = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text               = "G-Mon Hub Key"
title.TextColor3         = Color3.new(1, 1, 1)
title.Font               = Enum.Font.GothamBold
title.TextSize           = 18
title.TextXAlignment     = Enum.TextXAlignment.Left

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size            = UDim2.new(0, 24, 0, 24)
closeBtn.Position        = UDim2.new(1, -30, 0, 8)
closeBtn.BackgroundTransparency = 1
closeBtn.Text            = "✕"
closeBtn.TextColor3      = Color3.new(1, 1, 1)
closeBtn.Font            = Enum.Font.GothamBold
closeBtn.TextSize        = 18
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- INPUT BOX
local input = Instance.new("TextBox", frame)
input.Size               = UDim2.new(0.8, 0, 0, 28)
input.Position           = UDim2.new(0.1, 0, 0.35, 0)
input.PlaceholderText    = "Enter Key..."
input.ClearTextOnFocus   = true
input.BackgroundColor3   = Color3.fromRGB(30, 30, 30)
input.TextColor3         = Color3.new(1, 1, 1)
input.Font               = Enum.Font.Gotham
input.TextSize           = 14
Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

-- CHECK BUTTON
local checkBtn = Instance.new("TextButton", frame)
checkBtn.Size            = UDim2.new(0.35, 0, 0, 28)
checkBtn.Position        = UDim2.new(0.1, 0, 0.7, 0)
checkBtn.Text            = "Check Key"
checkBtn.BackgroundColor3= Color3.fromRGB(50, 100, 50)
checkBtn.TextColor3      = Color3.new(1, 1, 1)
checkBtn.Font            = Enum.Font.GothamBold
checkBtn.TextSize        = 14
Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0, 6)

-- GET KEY BUTTON
local getKeyBtn = Instance.new("TextButton", frame)
getKeyBtn.Size           = UDim2.new(0.35, 0, 0, 28)
getKeyBtn.Position       = UDim2.new(0.55, 0, 0.7, 0)
getKeyBtn.Text           = "Get Key"
getKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
getKeyBtn.TextColor3     = Color3.new(1, 1, 1)
getKeyBtn.Font           = Enum.Font.GothamBold
getKeyBtn.TextSize       = 14
Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 6)

getKeyBtn.MouseButton1Click:Connect(function()
    setclipboard("https://linkvertise.com/1209226/get-key-gmon-hub-script")
    StarterGui:SetCore("SendNotification", {
        Title = "G-Mon Hub",
        Text  = "Link key copied!",
        Duration = 3
    })
end)

-- CHECK LOGIC
checkBtn.MouseButton1Click:Connect(function()
    if input.Text == VALID_KEY then
        StarterGui:SetCore("SendNotification", {
            Title = "Key Valid",
            Text  = "Loading G-Mon Hub…",
            Duration = 2
        })
        task.wait(0.5)
        screenGui:Destroy()
        -- jalankan main.lua
        local ok, err = pcall(function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/main.lua", true))()
        end
    else
        StarterGui:SetCore("SendNotification", {
            Title = "Invalid Key",
            Text  = "Please get a valid key.",
            Duration = 3
        })
        input.Text = ""
    end
end)

-- DRAGGABLE FRAME
do
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startPos = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp == dragInput then
            local delta = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end