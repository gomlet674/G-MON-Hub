-- GMON Hub Enhanced UI with Tabs, Scroll, Draggable, RGB Effect

local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "GMON_Hub_Enhanced"
screenGui.ResetOnSpawn = false

-- Toggle Button
local openButton = Instance.new("TextButton")
openButton.Parent = screenGui
openButton.Size = UDim2.new(0, 40, 0, 40)
openButton.Position = UDim2.new(0, 10, 0, 10)
openButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
openButton.Text = ""
Instance.new("UICorner", openButton).CornerRadius = UDim.new(1, 0)

-- Main UI Frame
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- Tab Buttons
local tabNames = {"Info", "Main", "Item", "Race", "Sea Events", "Prehistoric", "Kitsune", "Mirage", "Devil Fruit", "ESP", "Misc", "Setting"}
local currentTab = nil

local tabHolder = Instance.new("Frame", mainFrame)
tabHolder.Size = UDim2.new(1, 0, 0, 30)
tabHolder.BackgroundTransparency = 1

local tabLayout = Instance.new("UIListLayout", tabHolder)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Container for all tab pages
local container = Instance.new("Frame", mainFrame)
container.Position = UDim2.new(0, 0, 0, 35)
container.Size = UDim2.new(1, 0, 1, -35)
container.BackgroundTransparency = 1

-- Tab content setup
local tabs = {}
for _, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton", tabHolder)
    btn.Size = UDim2.new(0, 90, 1, 0)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame", container)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 6
    page.Visible = false
    page.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    tabs[name] = page

    btn.MouseButton1Click:Connect(function()
        if currentTab then tabs[currentTab].Visible = false end
        currentTab = name
        tabs[name].Visible = true
    end)
end

-- Toggle row creator
local function createSwitch(parent, labelText)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 30)
    row.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", row)
    label.Text = labelText
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = Instance.new("TextButton", row)
    toggleBtn.Size = UDim2.new(0.25, 0, 1, 0)
    toggleBtn.Position = UDim2.new(0.75, 0, 0, 0)
    toggleBtn.Text = "OFF"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.TextSize = 14
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

    local on = false
    toggleBtn.MouseButton1Click:Connect(function()
        on = not on
        toggleBtn.Text = on and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = on and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(120, 0, 0)
    end)
end

-- Example content for Info tab
createSwitch(tabs["Info"], "Moon Phase")
createSwitch(tabs["Info"], "Kitsune Island")
createSwitch(tabs["Info"], "God Chalice")
createSwitch(tabs["Info"], "Mirage Island")
createSwitch(tabs["Info"], "Prehistoric Island")
createSwitch(tabs["Info"], "Tyrant of the Skies")

-- Example content for Main tab
createSwitch(tabs["Main"], "Farm Level")
createSwitch(tabs["Main"], "Farm Nearest")
createSwitch(tabs["Main"], "Farm Boss Selected")

-- Open/close toggle
openButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- RGB background effect (optional aesthetic)
spawn(function()
    local hue = 0
    while true do
        hue = (hue + 0.005) % 1
        local color = Color3.fromHSV(hue, 1, 1)
        openButton.BackgroundColor3 = color
        wait(0.03)
    end
end)

-- Activate default tab
tabs["Info"].Visible = true
currentTab = "Info"
