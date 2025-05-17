local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local function createRGBFrame(parent, size, position)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- Untuk pinggiran RGB, kita buat 4 frame di tiap sisi dengan UICorner
    local thickness = 4
    local sides = {}

    sides.top = Instance.new("Frame", frame)
    sides.top.Size = UDim2.new(1, 0, 0, thickness)
    sides.top.Position = UDim2.new(0, 0, 0, 0)
    sides.top.BackgroundColor3 = Color3.new(1, 0, 0)
    sides.top.BorderSizePixel = 0

    sides.bottom = Instance.new("Frame", frame)
    sides.bottom.Size = UDim2.new(1, 0, 0, thickness)
    sides.bottom.Position = UDim2.new(0, 0, 1, -thickness)
    sides.bottom.BackgroundColor3 = Color3.new(1, 0, 0)
    sides.bottom.BorderSizePixel = 0

    sides.left = Instance.new("Frame", frame)
    sides.left.Size = UDim2.new(0, thickness, 1, 0)
    sides.left.Position = UDim2.new(0, 0, 0, 0)
    sides.left.BackgroundColor3 = Color3.new(1, 0, 0)
    sides.left.BorderSizePixel = 0

    sides.right = Instance.new("Frame", frame)
    sides.right.Size = UDim2.new(0, thickness, 1, 0)
    sides.right.Position = UDim2.new(1, -thickness, 0, 0)
    sides.right.BackgroundColor3 = Color3.new(1, 0, 0)
    sides.right.BorderSizePixel = 0

    -- Animate RGB warna bergantian
    local t = 0
    RunService.Heartbeat:Connect(function(dt)
        t = t + dt * 2 -- kecepatan warna berubah
        local r = (math.sin(t) + 1) / 2
        local g = (math.sin(t + 2*math.pi/3) + 1) / 2
        local b = (math.sin(t + 4*math.pi/3) + 1) / 2
        local color = Color3.new(r, g, b)
        for _, side in pairs(sides) do
            side.BackgroundColor3 = color
        end
    end)

    return frame
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GMonHub"
screenGui.Parent = PlayerGui
screenGui.ResetOnSpawn = false

-- Background frame melingkar kiri (rounded besar)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.15
mainFrame.Position = UDim2.new(0, 20, 0.1, 0)
mainFrame.Size = UDim2.new(0, 450, 0, 600)
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.ClipsDescendants = true
mainFrame.BorderSizePixel = 0
mainFrame.AutomaticSize = Enum.AutomaticSize.None
mainFrame.ZIndex = 10

-- Rounded corners
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 60)
uiCorner.Parent = mainFrame

-- RGB pinggiran frame utama
local rgbBorder = createRGBFrame(mainFrame, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Parent = mainFrame
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = titleBar
titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "G-Mon-Hub"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Buttons (Minimize & Close)
local btnMinimize = Instance.new("TextButton")
btnMinimize.Parent = titleBar
btnMinimize.Size = UDim2.new(0, 40, 0, 30)
btnMinimize.Position = UDim2.new(0.8, 0, 0.1, 0)
btnMinimize.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btnMinimize.Text = "−"
btnMinimize.Font = Enum.Font.GothamBold
btnMinimize.TextSize = 24
btnMinimize.TextColor3 = Color3.fromRGB(255, 255, 255)
btnMinimize.BorderSizePixel = 0
btnMinimize.AutoButtonColor = true
btnMinimize.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

local btnClose = Instance.new("TextButton")
btnClose.Parent = titleBar
btnClose.Size = UDim2.new(0, 40, 0, 30)
btnClose.Position = UDim2.new(0.9, 0, 0.1, 0)
btnClose.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
btnClose.Text = "✕"
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 22
btnClose.TextColor3 = Color3.fromRGB(255, 255, 255)
btnClose.BorderSizePixel = 0
btnClose.AutoButtonColor = true
btnClose.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Dragging function untuk mainFrame via titleBar
local dragging
local dragInput
local dragStart
local startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Tab container kiri
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Parent = mainFrame
tabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tabContainer.Position = UDim2.new(0, 0, 0, 40)
tabContainer.Size = UDim2.new(0, 150, 1, -40)
tabContainer.BorderSizePixel = 0

local tabLayout = Instance.new("UIListLayout")
tabLayout.Parent = tabContainer
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)

-- Tab names
local tabNames = {
    "Info", "Main", "Item", "Stats", "Sea Events", "Kitsune", 
    "Prehistoric", "Fruit", "ESP", "Player", "Setting", "Misc"
}

-- Panel konten kanan
local contentPanel = Instance.new("Frame")
contentPanel.Name = "ContentPanel"
contentPanel.Parent = mainFrame
contentPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
contentPanel.Position = UDim2.new(0, 150, 0, 40)
contentPanel.Size = UDim2.new(1, -150, 1, -40)
contentPanel.BorderSizePixel = 0

-- Fungsi buat tombol tab
local function createTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Parent = tabContainer
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Font = Enum.Font.GothamBold
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 18
    btn.LayoutOrder = #tabContainer:GetChildren()
    return btn
end

-- Membuat tombol tab
local tabButtons = {}
for _, tabName in ipairs(tabNames) do
    local tabBtn = createTabButton(tabName)
    table.insert(tabButtons, tabBtn)
end

-- Fungsi update konten tiap tab
local function updateContent(tabName)
    contentPanel:ClearAllChildren()
    
    -- Contoh isi konten untuk tab Main dengan tombol toggle
    if tabName == "Main" then
        local label = Instance.new("TextLabel")
        label.Parent = contentPanel
        label.Size = UDim2.new(1, 0, 0, 40)
        label.Position = UDim2.new(0, 10, 0, 10)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 22
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Text = "Auto Farm"

        local toggle = Instance.new("TextButton")
        toggle.Parent = contentPanel
        toggle.Size = UDim2.new(0, 100, 0, 40)
        toggle.Position = UDim2.new(0, 10, 0, 60)
        toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        toggle.BorderSizePixel = 0
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 20
        toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
        toggle.Text = "OFF"

        local enabled = false
        toggle.MouseButton1Click:Connect(function()
            enabled = not enabled
            if enabled then
                toggle.Text = "ON"
                toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            else
                toggle.Text = "OFF"
                toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            -- Logic toggle fitur auto farm bisa dimasukkan di sini
        end)

    else
        local label = Instance.new("TextLabel")
        label.Parent = contentPanel
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 28
        label.Text = "Content for " .. tabName
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
    end
end

-- Connect klik tombol tab
for _, btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        updateContent(btn.Text)
    end)
end

-- Default buka tab Info
updateContent("Info")

mainFrame.Visible = true