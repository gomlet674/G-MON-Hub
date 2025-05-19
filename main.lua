-- loader.lua
repeat task.wait() until game:IsLoaded()

local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")

-- Parent
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "GMonWideUI"
screenGui.ResetOnSpawn   = false
screenGui.Parent         = CoreGui

-- Main container
local main = Instance.new("Frame", screenGui)
main.Name               = "Main"
main.Size               = UDim2.new(0, 600, 0, 360)   -- wide but not tall
main.Position           = UDim2.new(0.5, -300, 0.5, -180)
main.BackgroundColor3   = Color3.fromRGB(25,25,25)
main.Active             = true
main.ClipsDescendants   = true

-- Rounded corners
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

-- Rainbow border
local border = Instance.new("UIStroke", main)
border.Thickness         = 3
border.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
task.spawn(function()
    local hue = 0
    while main.Parent do
        border.Color = Color3.fromHSV(hue,1,1)
        hue = (hue + 0.005) % 1
        task.wait(0.02)
    end
end)

-- Left Sidebar
local sidebar = Instance.new("Frame", main)
sidebar.Name             = "Sidebar"
sidebar.Size             = UDim2.new(0, 140, 1, 0)
sidebar.Position         = UDim2.new(0,0,0,0)
sidebar.BackgroundColor3 = Color3.fromRGB(30,30,30)

Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

local icons = {
    {"rbxassetid://6031000599","Info"},
    {"rbxassetid://6031000915","Main"},
    {"rbxassetid://6031001132","Setting"},
    {"rbxassetid://6031001330","Item"},
    {"rbxassetid://6031001543","Material"},
    {"rbxassetid://6031001738","Event"},
    {"rbxassetid://6031001964","Stop All Tween"},
}

local y = 20
for _, data in ipairs(icons) do
    local img, txt = data[1], data[2]
    local btn = Instance.new("ImageButton", sidebar)
    btn.Size = UDim2.new(0, 32, 0, 32)
    btn.Position = UDim2.new(0, 16, 0, y)
    btn.BackgroundTransparency = 1
    btn.Image = img
    local lbl = Instance.new("TextLabel", sidebar)
    lbl.Size = UDim2.new(1, -56, 0, 32)
    lbl.Position = UDim2.new(0, 56, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 48
end

-- Right panel
local panel = Instance.new("Frame", main)
panel.Name               = "Panel"
panel.Size               = UDim2.new(1, -148, 1, 0)
panel.Position           = UDim2.new(0, 148, 0, 0)
panel.BackgroundColor3   = Color3.fromRGB(28,28,28)

-- Top bar inside panel
local topbar = Instance.new("Frame", panel)
topbar.Name              = "TopBar"
topbar.Size              = UDim2.new(1, 0, 0, 40)
topbar.BackgroundTransparency = 1

-- Back button
local backBtn = Instance.new("TextButton", topbar)
backBtn.Size             = UDim2.new(0, 80, 1, 0)
backBtn.Position         = UDim2.new(0, 0, 0, 0)
backBtn.BackgroundTransparency = 1
backBtn.Font             = Enum.Font.GothamSemibold
backBtn.TextSize         = 16
backBtn.Text             = "← Back"
backBtn.TextColor3       = Color3.new(1,1,1)

-- Page icon
local pageIcon = Instance.new("ImageLabel", topbar)
pageIcon.Size            = UDim2.new(0, 32, 0, 32)
pageIcon.Position        = UDim2.new(0.5, -16, 0, 4)
pageIcon.BackgroundTransparency = 1
pageIcon.Image           = icons[3][1] -- default “Setting” icon

-- Title text
local pageTitle = Instance.new("TextLabel", topbar)
pageTitle.Size           = UDim2.new(0.5, -20, 1, 0)
pageTitle.Position       = UDim2.new(0.5, 20, 0, 0)
pageTitle.BackgroundTransparency = 1
pageTitle.Font           = Enum.Font.GothamBold
pageTitle.TextSize       = 18
pageTitle.Text           = "Setting"
pageTitle.TextColor3     = Color3.new(1,1,1)
pageTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Close “X”
local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Size            = UDim2.new(0,32,0,32)
closeBtn.Position        = UDim2.new(1,-36,0,4)
closeBtn.BackgroundTransparency = 1
closeBtn.Font            = Enum.Font.GothamBold
closeBtn.TextSize        = 24
closeBtn.Text            = "✕"
closeBtn.TextColor3      = Color3.new(1,1,1)
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Scrollable content area
local scrollFrame = Instance.new("ScrollingFrame", panel)
scrollFrame.Size         = UDim2.new(1, -20, 1, -60)
scrollFrame.Position     = UDim2.new(0,10,0,50)
scrollFrame.CanvasSize   = UDim2.new(0,0,2,0)
scrollFrame.ScrollBarThickness = 8
scrollFrame.BackgroundTransparency = 1

-- Layout inside scroll
local listLayout = Instance.new("UIListLayout", scrollFrame)
listLayout.Padding       = UDim.new(0,12)

-- Example setting entries
for i=1,12 do
    local entry = Instance.new("Frame", scrollFrame)
    entry.Size             = UDim2.new(1, 0, 0, 32)
    entry.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", entry)
    label.Size             = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text             = "Option "..i
    label.Font             = Enum.Font.Gotham
    label.TextSize         = 16
    label.TextColor3       = Color3.new(1,1,1)
    label.TextXAlignment   = Enum.TextXAlignment.Left

    local toggle = Instance.new("Frame", entry)
    toggle.Size            = UDim2.new(0,24,0,24)
    toggle.Position        = UDim2.new(1,-28,0,4)
    toggle.BackgroundColor3 = Color3.fromRGB(80,80,80)
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,4)

    toggle.InputBegan:Connect(function()
        toggle.BackgroundColor3 = (toggle.BackgroundColor3 == Color3.fromRGB(80,80,80))
            and Color3.fromRGB(0,200,120)
            or Color3.fromRGB(80,80,80)
    end)
end

-- Make main frame draggable
do
    local dragging, dragStart, startPos, dragInput
    main.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    main.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = i
        end
    end)
    UserInput.InputChanged:Connect(function(i)
        if dragging and i == dragInput then
            local delta = i.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end