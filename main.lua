-- loader.lua
repeat task.wait() until game:IsLoaded()

local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")

-- SCREEN GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "SkullHubLoader"
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = CoreGui

-- MAIN FRAME
local frame = Instance.new("Frame", screenGui)
frame.Name             = "LoaderFrame"
frame.Size             = UDim2.new(0, 360, 0, 300)
frame.Position         = UDim2.new(0.5, -180, -1, 0)  -- start above screen
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel  = 0
frame.Active           = true
frame.ClipsDescendants = true

-- ROUNDED CORNERS
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)

-- RAINBOW BORDER
local stroke = Instance.new("UIStroke", frame)
stroke.Thickness       = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
task.spawn(function()
    local hue = 0
    while frame.Parent do
        stroke.Color = Color3.fromHSV(hue,1,1)
        hue = (hue + 0.005) % 1
        task.wait(0.01)
    end
end)

-- CROWN ICON (poking out the top-center)
local icon = Instance.new("ImageLabel", frame)
icon.Name                  = "Icon"
icon.Size                  = UDim2.new(0, 100, 0, 100)
icon.Position              = UDim2.new(0.5, -50, 0, -50)  -- half poking out
icon.BackgroundTransparency= 1
icon.Image                 = "rbxassetid://6031075938"
icon.ScaleType             = Enum.ScaleType.Fit
Instance.new("UICorner", icon).CornerRadius = UDim.new(1,0)

-- TITLE
local title = Instance.new("TextLabel", frame)
title.Name                  = "Title"
title.Size                  = UDim2.new(1, 0, 0, 30)
title.Position              = UDim2.new(0, 0, 0, 60)
title.BackgroundTransparency = 1
title.Font                  = Enum.Font.GothamBold
title.TextSize              = 22
title.Text                  = "Skull Hub"
title.TextColor3            = Color3.new(1,1,1)
title.TextXAlignment        = Enum.TextXAlignment.Center
title.TextYAlignment        = Enum.TextYAlignment.Center

-- LOAD BUTTON
local loadBtn = Instance.new("TextButton", frame)
loadBtn.Name                = "LoadBtn"
loadBtn.Size                = UDim2.new(0.4, 0, 0, 36)
loadBtn.Position            = UDim2.new(0.55, 0, 1, -60)  -- flush-right near bottom
loadBtn.BackgroundColor3    = Color3.fromRGB(0,150,250)
loadBtn.Font                = Enum.Font.GothamBold
loadBtn.TextSize            = 18
loadBtn.Text                = "Load Script"
loadBtn.TextColor3          = Color3.new(1,1,1)
local loadCorner = Instance.new("UICorner", loadBtn)
loadCorner.CornerRadius      = UDim.new(0,8)

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Name                = "CloseBtn"
closeBtn.Size                = UDim2.new(0,32,0,32)
closeBtn.Position            = UDim2.new(1,-36,0,4)
closeBtn.BackgroundTransparency = 1
closeBtn.Font                = Enum.Font.GothamBold
closeBtn.TextSize            = 24
closeBtn.Text                = "✕"
closeBtn.TextColor3          = Color3.new(1,1,1)
closeBtn.MouseButton1Click:Connect(function()
    -- slide out then destroy
    TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -180, -1, 0)
    }):Play():Wait()
    screenGui:Destroy()
end)

-- SLIDE-IN ANIMATION
TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -180, 0.3, 0)
}):Play()

-- LOAD CALLBACK
loadBtn.MouseButton1Click:Connect(function()
    loadBtn.Text = "Loading..."
    local ok, err = pcall(function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/hungquan99/SkullHub/main/loader.lua",
            true
        ))()
    end)
    if not ok then
        loadBtn.Text = "Error"
        warn("SkullHub load error:", err)
    end
end)

-- MAKE FRAME DRAGGABLE
do
    local dragging, dragStart, startPos, dragInput
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = i
        end
    end)
    UserInput.InputChanged:Connect(function(i)
        if dragging and i == dragInput then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end