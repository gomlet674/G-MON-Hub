-- loader.lua
repeat task.wait() until game:IsLoaded()

local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")

-- PARENT GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "GMonWideUI"
screenGui.Parent         = CoreGui

-- MAIN WINDOW
local main = Instance.new("Frame", screenGui)
main.Name               = "Main"
main.Size               = UDim2.new(0, 600, 0, 360)
main.Position           = UDim2.new(0.5, -300, 0.5, -180)
main.BackgroundColor3   = Color3.fromRGB(25,25,25)
main.Active             = true
main.ClipsDescendants   = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

-- RAINBOW BORDER
local stroke = Instance.new("UIStroke", main)
stroke.Thickness       = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
task.spawn(function()
    local hue = 0
    while main.Parent do
        stroke.Color = Color3.fromHSV(hue,1,1)
        hue = (hue + 0.005) % 1
        task.wait(0.02)
    end
end)

-- LEFT SIDEBAR AS SCROLLINGFRAME
local sidebar = Instance.new("ScrollingFrame", main)
sidebar.Name               = "Sidebar"
sidebar.Size               = UDim2.new(0, 140, 1, 0)
sidebar.Position           = UDim2.new(0, 0, 0, 0)
sidebar.CanvasSize         = UDim2.new(0, 0, 0, 400)
sidebar.ScrollBarThickness = 6
sidebar.BackgroundColor3   = Color3.fromRGB(30,30,30)
sidebar.BorderSizePixel    = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,12)

local layout = Instance.new("UIListLayout", sidebar)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding   = UDim.new(0,12)

-- G-MON LABEL AT TOP
local title = Instance.new("TextLabel", sidebar)
title.Size               = UDim2.new(1,0,0,40)
title.BackgroundTransparency = 1
title.Text               = "G-MON"
title.Font               = Enum.Font.GothamBold
title.TextSize           = 20
title.TextColor3         = Color3.new(1,1,1)
title.TextXAlignment     = Enum.TextXAlignment.Center
title.LayoutOrder        = 0

-- LEFT TAB BUTTONS
local tabs = {"Info","Main","Setting","Item","Material","Event","Stop All Tween","Extra1","Extra2"}
for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", sidebar)
    btn.Size               = UDim2.new(1,-20,0,32)
    btn.Position           = UDim2.new(0,10,0,0)
    btn.BackgroundColor3   = Color3.fromRGB(35,35,35)
    btn.Text               = name
    btn.Font               = Enum.Font.Gotham
    btn.TextSize           = 16
    btn.TextColor3         = Color3.new(1,1,1)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.LayoutOrder        = i
end

-- RIGHT PANEL
local panel = Instance.new("Frame", main)
panel.Name               = "Panel"
panel.Size               = UDim2.new(1, -148, 1, 0)
panel.Position           = UDim2.new(0, 148, 0, 0)
panel.BackgroundColor3   = Color3.fromRGB(28,28,28)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,12)

-- TOPBAR
local topbar = Instance.new("Frame", panel)
topbar.Size               = UDim2.new(1,0,0,40)
topbar.BackgroundTransparency = 1

-- BACK BUTTON
local backBtn = Instance.new("TextButton", topbar)
backBtn.Size               = UDim2.new(0,80,1,0)
backBtn.BackgroundTransparency = 1
backBtn.Font               = Enum.Font.GothamSemibold
backBtn.TextSize           = 16
backBtn.Text               = "← Back"
backBtn.TextColor3         = Color3.new(1,1,1)

-- PAGE TITLE
local pageTitle = Instance.new("TextLabel", topbar)
pageTitle.Size             = UDim2.new(1, -100, 1, 0)
pageTitle.Position         = UDim2.new(0,80,0,0)
pageTitle.BackgroundTransparency = 1
pageTitle.Font             = Enum.Font.GothamBold
pageTitle.TextSize         = 18
pageTitle.Text             = "Setting"
pageTitle.TextColor3       = Color3.new(1,1,1)
pageTitle.TextXAlignment   = Enum.TextXAlignment.Left

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Size               = UDim2.new(0,32,0,32)
closeBtn.Position           = UDim2.new(1,-36,0,4)
closeBtn.BackgroundTransparency = 1
closeBtn.Font               = Enum.Font.GothamBold
closeBtn.TextSize           = 24
closeBtn.Text               = "✕"
closeBtn.TextColor3         = Color3.new(1,1,1)
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- CONTENT SCROLL
local content = Instance.new("ScrollingFrame", panel)
content.Size               = UDim2.new(1,-20,1,-60)
content.Position           = UDim2.new(0,10,0,50)
content.CanvasSize         = UDim2.new(0,0,0,600)
content.ScrollBarThickness = 8
content.BackgroundTransparency = 1

local contentLayout = Instance.new("UIListLayout", content)
contentLayout.Padding      = UDim.new(0,16)

-- CREATE TOGGLE ENTRY FUNCTION
local function makeToggle(text)
    local line = Instance.new("Frame", content)
    line.Size               = UDim2.new(1,0,0,30)
    line.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", line)
    lbl.Size                = UDim2.new(0.7,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text                = text
    lbl.Font                = Enum.Font.Gotham
    lbl.TextSize            = 16
    lbl.TextColor3          = Color3.new(1,1,1)
    lbl.TextXAlignment      = Enum.TextXAlignment.Left

    local box = Instance.new("TextButton", line)
    box.Size                = UDim2.new(0,24,0,24)
    box.Position            = UDim2.new(1,-28,0,3)
    box.BackgroundColor3    = Color3.fromRGB(80,80,80)
    box.AutoButtonColor     = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)

    local state = false
    box.MouseButton1Click:Connect(function()
        state = not state
        box.BackgroundColor3 = state and Color3.fromRGB(0,200,120) or Color3.fromRGB(80,80,80)
    end)
end

-- EXAMPLE TOGGLES
for i=1,12 do
    makeToggle("Option "..i)
end

-- MAKE MAIN DRAGGABLE
do
    local dragging, dragStart, startPos, dragInput
    main.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    main.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then
            dragInput = i
        end
    end)
    UserInput.InputChanged:Connect(function(i)
        if dragging and i==dragInput then
            local delta = i.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end