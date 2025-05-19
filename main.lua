-- loader.lua
repeat task.wait() until game:IsLoaded()

local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")

-- Keybind to toggle UI on PC
local TOGGLE_KEY = Enum.KeyCode.RightControl

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "GMonWideUI"
screenGui.ResetOnSpawn = false
screenGui.Parent       = CoreGui

-- MAIN WINDOW
local main = Instance.new("Frame", screenGui)
main.Name             = "MainWindow"
main.Size             = UDim2.new(0,600,0,360)
main.Position         = UDim2.new(0.5,-300,0.5,-180)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)
main.Active           = true
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

-- RAINBOW BORDER
local stroke = Instance.new("UIStroke", main)
stroke.Thickness       = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
task.spawn(function()
    local h = 0
    while main.Parent do
        stroke.Color = Color3.fromHSV(h,1,1)
        h = (h + 0.005) % 1
        task.wait(0.02)
    end
end)

-- LEFT SIDEBAR (scrollable)
local sidebar = Instance.new("ScrollingFrame", main)
sidebar.Name               = "Sidebar"
sidebar.Size               = UDim2.new(0,140,1,0)
sidebar.Position           = UDim2.new(0,0,0,0)
sidebar.ScrollBarThickness = 6
sidebar.BackgroundColor3   = Color3.fromRGB(30,30,30)
sidebar.BorderSizePixel    = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,12)

local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding   = UDim.new(0,12)

-- Auto-adjust canvas height
sidebar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    sidebar.CanvasSize = UDim2.new(0,0,0,sideLayout.AbsoluteContentSize.Y)
end)

-- G-MON HEADER
local header = Instance.new("TextLabel", sidebar)
header.LayoutOrder            = 0
header.Size                   = UDim2.new(1,0,0,40)
header.BackgroundTransparency = 1
header.Text                   = "G-MON"
header.Font                   = Enum.Font.GothamBold
header.TextSize               = 20
header.TextColor3             = Color3.new(1,1,1)
header.TextXAlignment         = Enum.TextXAlignment.Center

-- YOUR FEATURES
local pages = {
    "Info","Main","Item","Sea Event","Prehistoric","Kitsune",
    "Mirage","Race v4","Devil Fruit","ESP","Misc","Setting"
}

-- Create a table to hold button references
local tabButtons = {}

for i,name in ipairs(pages) do
    local btn = Instance.new("TextButton", sidebar)
    btn.Name            = name.."Tab"
    btn.LayoutOrder     = i
    btn.Size            = UDim2.new(1,-20,0,32)
    btn.Position        = UDim2.new(0,10,0,0)
    btn.BackgroundColor3= Color3.fromRGB(35,35,35)
    btn.AutoButtonColor = false
    btn.Font            = Enum.Font.Gotham
    btn.TextSize        = 16
    btn.TextColor3      = Color3.new(1,1,1)
    btn.Text            = name
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    tabButtons[i] = btn
end

-- RIGHT PANEL
local panel = Instance.new("Frame", main)
panel.Name             = "Panel"
panel.Size             = UDim2.new(1,-148,1,0)
panel.Position         = UDim2.new(0,148,0,0)
panel.BackgroundColor3 = Color3.fromRGB(28,28,28)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,12)

-- TOP BAR
local topbar = Instance.new("Frame", panel)
topbar.Size               = UDim2.new(1,0,0,40)
topbar.BackgroundTransparency = 1

-- Page Title
local pageTitle = Instance.new("TextLabel", topbar)
pageTitle.Size               = UDim2.new(1,-100,1,0)
pageTitle.Position           = UDim2.new(0,80,0,0)
pageTitle.BackgroundTransparency = 1
pageTitle.Font               = Enum.Font.GothamBold
pageTitle.TextSize           = 18
pageTitle.Text               = pages[1]
pageTitle.TextColor3         = Color3.new(1,1,1)
pageTitle.TextXAlignment     = Enum.TextXAlignment.Left

-- Toggle UI Button
local toggleBtn = Instance.new("TextButton", topbar)
toggleBtn.Size               = UDim2.new(0,32,0,32)
toggleBtn.Position           = UDim2.new(1,-36,0,4)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Font               = Enum.Font.GothamBold
toggleBtn.TextSize           = 24
toggleBtn.Text               = "≡"
toggleBtn.TextColor3         = Color3.new(1,1,1)
toggleBtn.AutoButtonColor    = false
toggleBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = not screenGui.Enabled
end)

-- CONTENT SCROLL
local content = Instance.new("ScrollingFrame", panel)
content.Name               = "Content"
content.Size               = UDim2.new(1,-20,1,-60)
content.Position           = UDim2.new(0,10,0,50)
content.CanvasSize         = UDim2.new(0,0,0,1)
content.ScrollBarThickness = 8
content.BackgroundTransparency = 1
Instance.new("UICorner", content).CornerRadius = UDim.new(0,6)

local contentLayout = Instance.new("UIListLayout", content)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding   = UDim.new(0,12)
-- auto-adjust
contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    content.CanvasSize = UDim2.new(0,0,0,contentLayout.AbsoluteContentSize.Y)
end)

-- Helper to populate content
local function fillPage(idx)
    content:ClearAllChildren()
    for i=1,8 do
        local row = Instance.new("Frame", content)
        row.Size               = UDim2.new(1,0,0,30)
        row.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", row)
        lbl.Size                = UDim2.new(0.7,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text                = pages[idx].." Option "..i
        lbl.Font                = Enum.Font.Gotham
        lbl.TextSize            = 16
        lbl.TextColor3          = Color3.new(1,1,1)
        lbl.TextXAlignment      = Enum.TextXAlignment.Left

        local toggle = Instance.new("TextButton", row)
        toggle.Size             = UDim2.new(0,24,0,24)
        toggle.Position         = UDim2.new(1,-28,0,3)
        toggle.BackgroundColor3 = Color3.fromRGB(80,80,80)
        toggle.AutoButtonColor  = false
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,4)

        local state = false
        toggle.MouseButton1Click:Connect(function()
            state = not state
            toggle.BackgroundColor3 = state and Color3.fromRGB(0,200,120) or Color3.fromRGB(80,80,80)
        end)
    end
    pageTitle.Text = pages[idx]
end

-- Wire up tabs
for i,btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        fillPage(i)
    end)
end

-- Initialize first page
fillPage(1)

-- Make window draggable
do
    local dragging, startPos, dragStart
    UserInput.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and i.Target:IsDescendantOf(main) then
            dragging = true
            startPos = main.Position
            dragStart = i.Position
        end
    end)
    UserInput.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Toggle UI on PC
UserInput.InputBegan:Connect(function(i,g)
    if not g and i.KeyCode == TOGGLE_KEY then
        screenGui.Enabled = not screenGui.Enabled
    end
end)