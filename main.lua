-- main.lua
-- Place as a LocalScript (e.g. via loader)

-- SERVICES
local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")

-- PARENT GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name              = "GMonHubUI"
screenGui.ResetOnSpawn      = false
screenGui.Parent            = CoreGui

-- MAIN FRAME
local frame = Instance.new("Frame", screenGui)
frame.Name                  = "MainFrame"
frame.AnchorPoint           = Vector2.new(0.5, 0.5)
frame.Position              = UDim2.new(0.5, 0, 0.5, 0)
frame.Size                  = UDim2.new(0, 420, 0, 280)
frame.BackgroundColor3      = Color3.fromRGB(30,30,30)
frame.BackgroundTransparency = 0
frame.Active                = true
frame.ClipsDescendants      = true

-- ROUNDED CORNERS
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)

-- RAINBOW BORDER
local border = Instance.new("UIStroke", frame)
border.Thickness            = 3
border.ApplyStrokeMode      = Enum.ApplyStrokeMode.Border
task.spawn(function()
    local hue = 0
    while frame.Parent do
        border.Color = Color3.fromHSV(hue,1,1)
        hue = (hue + 0.005) % 1
        task.wait(0.01)
    end
end)

-- TITLE BAR
local title = Instance.new("TextLabel", frame)
title.Name                  = "Title"
title.Size                  = UDim2.new(1, 0, 0, 40)
title.Position              = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text                  = "G-Mon Hub"
title.Font                  = Enum.Font.GothamBold
title.TextSize              = 22
title.TextColor3            = Color3.new(1,1,1)
title.TextXAlignment        = Enum.TextXAlignment.Center
title.TextYAlignment        = Enum.TextYAlignment.Center

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Name                = "Close"
closeBtn.Size                = UDim2.new(0, 32, 0, 32)
closeBtn.Position            = UDim2.new(1, -36, 0, 4)
closeBtn.BackgroundTransparency = 1
closeBtn.Text                = "✕"
closeBtn.Font                = Enum.Font.GothamBold
closeBtn.TextSize            = 24
closeBtn.TextColor3          = Color3.new(1,1,1)
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- CONTAINER FOR OPTIONS
local container = Instance.new("Frame", frame)
container.Name               = "Options"
container.Size               = UDim2.new(1, -20, 1, -60)
container.Position           = UDim2.new(0,10,0,50)
container.BackgroundTransparency = 1

-- SCROLL CANVAS
local uiList = Instance.new("UIListLayout", container)
uiList.SortOrder             = Enum.SortOrder.LayoutOrder
uiList.Padding               = UDim.new(0,12)

-- UTILITY: Create a toggle line
local function makeToggle(name, initial, callback)
    local line = Instance.new("Frame", container)
    line.Size = UDim2.new(1, 0, 0, 30)
    line.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", line)
    lbl.Size           = UDim2.new(0.7, 0, 1, 0)
    lbl.Position       = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text           = name
    lbl.Font           = Enum.Font.Gotham
    lbl.TextSize       = 16
    lbl.TextColor3     = Color3.new(1,1,1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center

    local btn = Instance.new("TextButton", line)
    btn.Size           = UDim2.new(0, 40, 0, 20)
    btn.Position       = UDim2.new(1, -44, 0.5, -10)
    btn.BackgroundColor3 = initial and Color3.fromRGB(0,200,120) or Color3.fromRGB(90,90,90)
    btn.Text           = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = initial
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0,200,120) or Color3.fromRGB(90,90,90)
        callback(state)
    end)

    return line
end

-- EXAMPLE TOGGLES
makeToggle("Auto Farm", false, function(on)
    print("Auto Farm toggled to", on)
end)

makeToggle("Auto Chest", true, function(on)
    print("Auto Chest toggled to", on)
end)

-- DROPDOWN-LIKE (CLICK FOR MORE)
local dropdown = makeToggle("Select Weapon ▶", false, function(on)
    if on then
        print("Opening weapon list…")
        -- you can spawn a small submenu here
    else
        print("Closing weapon list…")
    end
end)

-- MAKE FRAME DRAGGABLE
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
    UserInput.InputChanged:Connect(function(inp)
        if dragging and inp == dragInput then
            local delta = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end