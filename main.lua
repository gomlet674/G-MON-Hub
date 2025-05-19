-- loader.lua
-- Drop this as a LocalScript (StarterPlayerScripts / executor)

repeat task.wait() until game:IsLoaded()

local CoreGui      = game:GetService("CoreGui")
local UserInput    = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Shortcut to toggle visibility
local TOGGLE_KEY = Enum.KeyCode.RightControl

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "GMonWideUI"
screenGui.ResetOnSpawn   = false
screenGui.Parent         = CoreGui

-- MAIN WINDOW
local main = Instance.new("Frame", screenGui)
main.Name               = "MainWindow"
main.Size               = UDim2.new(0,600,0,360)
main.Position           = UDim2.new(0.5,-300,0.5,-180)
main.BackgroundColor3   = Color3.fromRGB(25,25,25)
main.Active             = true
main.ClipsDescendants   = true
main.ZIndex             = 1
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
sidebar.BackgroundColor3   = Color3.fromRGB(30,30,30)
sidebar.ScrollBarThickness = 6
sidebar.CanvasSize         = UDim2.new(0, 0, 0, 500)
sidebar.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
sidebar.ZIndex             = 2
sidebar.ScrollBarImageColor3 = Color3.fromRGB(200,200,200)
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,12)

local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding   = UDim.new(0,12)

-- G-MON HEADER
local header = Instance.new("TextLabel", sidebar)
header.LayoutOrder        = 0
header.Size               = UDim2.new(1,0,0,40)
header.BackgroundTransparency = 1
header.Text               = "G-MON"
header.Font               = Enum.Font.GothamBold
header.TextSize           = 20
header.TextColor3         = Color3.new(1,1,1)
header.TextXAlignment     = Enum.TextXAlignment.Center

-- DEFINE PAGES
local pages = {
    {name="Info",     icon="rbxassetid://6031000599"},
    {name="Main",     icon="rbxassetid://6031000915"},
    {name="Setting",  icon="rbxassetid://6031001132"},
    {name="Item",     icon="rbxassetid://6031001330"},
    {name="Material", icon="rbxassetid://6031001543"},
    {name="Event",    icon="rbxassetid://6031001738"},
    {name="Tweens",   icon="rbxassetid://6031001964"},
}

-- Create tab buttons
for idx, page in ipairs(pages) do
    local btn = Instance.new("TextButton", sidebar)
    btn.Name            = page.name.."Tab"
    btn.LayoutOrder     = idx
    btn.Size            = UDim2.new(1,-20,0,32)
    btn.Position        = UDim2.new(0,10,0,0)
    btn.BackgroundColor3= Color3.fromRGB(35,35,35)
    btn.AutoButtonColor = false
    btn.Font            = Enum.Font.Gotham
    btn.TextSize        = 16
    btn.TextColor3      = Color3.new(1,1,1)
    btn.Text            = page.name
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    btn.MouseButton1Click:Connect(function()
        selectPage(idx)
    end)
end

-- RIGHT PANEL
local panel = Instance.new("Frame", main)
panel.Name             = "Panel"
panel.Size             = UDim2.new(1,-148,1,0)
panel.Position         = UDim2.new(0,148,0,0)
panel.BackgroundColor3 = Color3.fromRGB(28,28,28)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,12)

-- TOPBAR
local topbar = Instance.new("Frame", panel)
topbar.Name               = "TopBar"
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
backBtn.ScrollingEnabled   = false

-- PAGE ICON
local pageIcon = Instance.new("ImageLabel", topbar)
pageIcon.Size              = UDim2.new(0,24,0,24)
pageIcon.Position          = UDim2.new(0,88,0,8)
pageIcon.BackgroundTransparency = 1

-- PAGE TITLE
local pageTitle = Instance.new("TextLabel", topbar)
pageTitle.Size             = UDim2.new(1,-120,1,0)
pageTitle.Position         = UDim2.new(0,120,0,0)
pageTitle.BackgroundTransparency = 1
pageTitle.Font             = Enum.Font.GothamBold
pageTitle.TextSize         = 18
pageTitle.Text             = "Info"
pageTitle.TextColor3       = Color3.new(1,1,1)
pageTitle.TextXAlignment   = Enum.TextXAlignment.Left

-- CLOSE TOGGLE BUTTON
local toggleBtn = Instance.new("TextButton", topbar)
toggleBtn.Size             = UDim2.new(0,32,0,32)
toggleBtn.Position         = UDim2.new(1,-36,0,4)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Font             = Enum.Font.GothamBold
toggleBtn.TextSize         = 24
toggleBtn.Text             = "≡"
toggleBtn.TextColor3       = Color3.new(1,1,1)
toggleBtn.AutoButtonColor  = false

toggleBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = not screenGui.Enabled
end)

-- CONTENT AREA
local content = Instance.new("ScrollingFrame", panel)
content.Name               = "Content"
content.Size               = UDim2.new(1,-20,1,-60)
content.Position           = UDim2.new(0,10,0,50)
content.CanvasSize         = UDim2.new(0,0,2,0)
content.ScrollBarThickness = 8
content.BackgroundTransparency = 1

local contentLayout = Instance.new("UIListLayout", content)
contentLayout.Padding       = UDim.new(0,12)

-- HELPER TO CREATE A TOGGLE ROW
local function createToggle(text)
    local row = Instance.new("Frame", content)
    row.Size               = UDim2.new(1,0,0,30)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size              = UDim2.new(0.7,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = text
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 16
    lbl.TextColor3        = Color3.new(1,1,1)
    lbl.TextXAlignment    = Enum.TextXAlignment.Left

    local box = Instance.new("Frame", row)
    box.Size              = UDim2.new(0,24,0,24)
    box.Position          = UDim2.new(1,-28,0,3)
    box.BackgroundColor3  = Color3.fromRGB(80,80,80)
    box.AutoLocalize      = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)

    local state = false
    box.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            box.BackgroundColor3 = state and Color3.fromRGB(0,200,120) or Color3.fromRGB(80,80,80)
        end
    end)
end

-- FILL A PAGE
local function fillPage(idx)
    content:ClearAllChildren()
    contentLayout.Parent = content
    for i=1,12 do
        createToggle(pages[idx].name.." Option "..i)
    end
end

-- PAGE SELECTION LOGIC
local currentPage = 1
function selectPage(idx)
    currentPage = idx
    pageTitle.Text = pages[idx].name
    pageIcon.Image = pages[idx].icon
    fillPage(idx)
end

-- Initialize first page
selectPage(1)

-- MAKE THE ENTIRE WINDOW DRAGGABLE
do
    local dragging, dragStart, startPos
    UserInput.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            -- only start drag if clicked on main or its children
            if inp.Target:IsDescendantOf(main) then
                dragging = true
                dragStart = inp.Position
                startPos = main.Position
            end
        end
    end)
    UserInput.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInput.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- TOGGLE VISIBILITY VIA KEY
UserInput.InputBegan:Connect(function(inp, gp)
    if not gp and inp.KeyCode == TOGGLE_KEY then
        screenGui.Enabled = not screenGui.Enabled
    end
end)