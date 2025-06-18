-- GMON Roblox Script
-- Features inspired by Skull Hub and Isna Hamzah
-- Auto detection for Block Fruit, Grow a Garden, Build a Boat
-- Anime-themed background UI with switch tabs for each supported game

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Create main UI Container
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GMONHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui
ScreenGui.DisplayOrder = 9999

-- Background Frame with Anime Background (using placeholder image URL)
local BackgroundFrame = Instance.new("ImageLabel")
BackgroundFrame.Name = "Background"
BackgroundFrame.BackgroundColor3 = Color3.new(0, 0, 0)
BackgroundFrame.BackgroundTransparency = 0.3
BackgroundFrame.Image = "https://storage.googleapis.com/workspace-0f70711f-8b4e-4d94-86f1-2a93ccde5887/image/1b97511c-5736-4e6f-b3b1-c4a9e95ef656.png"
BackgroundFrame.ImageTransparency = 0.3
BackgroundFrame.Size = UDim2.new(1, 0, 1, 0)
BackgroundFrame.Position = UDim2.new(0, 0, 0, 0)
BackgroundFrame.ScaleType = Enum.ScaleType.Cover
BackgroundFrame.Parent = ScreenGui

-- Main GUI Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 600)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Parent = ScreenGui
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 10
MainFrame.LayoutOrder = 1
MainFrame.BorderColor3 = Color3.new(0,0,0)
MainFrame.BackgroundTransparency = 0.85

-- Round corners and shadow (using UIStroke for border)
local UICornerMain = Instance.new("UICorner")
UICornerMain.CornerRadius = UDim.new(0, 18)
UICornerMain.Parent = MainFrame

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(68, 43, 121)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local UICornerTitle = Instance.new("UICorner")
UICornerTitle.CornerRadius = UDim.new(0, 18)
UICornerTitle.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -24, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "GMON Hub"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 24
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 36, 0, 36)
CloseButton.Position = UDim2.new(1, -44, 0, 3)
CloseButton.BackgroundColor3 = Color3.fromRGB(153, 51, 51)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 20
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.AutoButtonColor = false
CloseButton.Parent = TitleBar

local UICornerClose = Instance.new("UICorner")
UICornerClose.CornerRadius = UDim.new(0, 12)
UICornerClose.Parent = CloseButton

-- Close Button functionality
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

-- Tab Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 0, 42)
TabContainer.Position = UDim2.new(0, 0, 0, 42)
TabContainer.BackgroundColor3 = Color3.fromRGB(50, 35, 90)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local UIListLayoutTabs = Instance.new("UIListLayout")
UIListLayoutTabs.FillDirection = Enum.FillDirection.Horizontal
UIListLayoutTabs.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayoutTabs.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayoutTabs.Padding = UDim.new(0, 8)
UIListLayoutTabs.Parent = TabContainer

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -32, 1, -96)
ContentContainer.Position = UDim2.new(0, 16, 0, 96)
ContentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ContentContainer.BorderSizePixel = 0
ContentContainer.Parent = MainFrame

local UICornerContent = Instance.new("UICorner")
UICornerContent.CornerRadius = UDim.new(0, 16)
UICornerContent.Parent = ContentContainer

local UIListLayoutContent = Instance.new("UIListLayout")
UIListLayoutContent.Padding = UDim.new(0, 12)
UIListLayoutContent.Parent = ContentContainer

-- Utility function to create tabs
local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Text = name
    btn.Size = UDim2.new(0, 140, 1, -12)
    btn.BackgroundColor3 = Color3.fromRGB(70, 50, 130)
    btn.TextColor3 = Color3.fromRGB(200, 200, 230)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.AutoButtonColor = false
    btn.Parent = TabContainer
    btn.ClipsDescendants = true

    local UICornerTab = Instance.new("UICorner")
    UICornerTab.CornerRadius = UDim.new(0, 14)
    UICornerTab.Parent = btn

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(98, 65, 160)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if not btn:GetAttribute("Active") then
            TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(70, 50, 130)}):Play()
        end
    end)

    return btn
end

-- Feature Container creation utility
local function createFeatureSection(title)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, 0, 0, 400)
    section.BackgroundTransparency = 1
    section.Visible = false
    section.Parent = ContentContainer
    return section
end

-- Activate tab function
local activeTab = nil
local function activateTab(tabBtn, contentFrame)
    -- Deactivate all tabs and hide content frames
    for _, btn in pairs(TabContainer:GetChildren()) do
        if btn:IsA("TextButton") then
            btn:SetAttribute("Active", false)
            TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(70, 50, 130)}):Play()
        end
    end
    for _, frame in pairs(ContentContainer:GetChildren()) do
        frame.Visible = false
    end

    -- Activate selected tab and show content
    tabBtn:SetAttribute("Active", true)
    TweenService:Create(tabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(120, 100, 210)}):Play()
    contentFrame.Visible = true
    activeTab = tabBtn.Name
end

-- GAME DETECTION --
local SupportedGames = {
    ["BlockFruit"] = 2753915549,
    ["GrowARichGarden"] = 537413528,
    ["BuildABoatForTreasure"] = 536102540
}

local currentGame = nil
local PlaceId = game.PlaceId

for gameName, placeId in pairs(SupportedGames) do
    if PlaceId == placeId then
        currentGame = gameName
        break
    end
end

if not currentGame then
    -- Unsupported game message
    local unsupportedLabel = Instance.new("TextLabel")
    unsupportedLabel.Size = UDim2.new(1, 0, 1, 0)
    unsupportedLabel.BackgroundTransparency = 1
    unsupportedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    unsupportedLabel.Font = Enum.Font.GothamBold
    unsupportedLabel.TextSize = 24
    unsupportedLabel.Text = "GMON Hub: Unsupported Game"
    unsupportedLabel.Parent = ContentContainer
end

-- TAB CREATION BASED ON SUPPORTED GAMES
local tabs = {}
local sections = {}

-- Helper function to create toggle button
local function createToggleButton(parent, text, default)
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, 0, 0, 44)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(220, 220, 255)
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 8, 0, 0)
    label.Size = UDim2.new(0.75, 0, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btnFrame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 44, 0, 24)
    toggle.Position = UDim2.new(1, -52, 0, 10)
    toggle.BackgroundColor3 = default and Color3.fromRGB(100, 180, 100) or Color3.fromRGB(178, 34, 34)
    toggle.Text = default and "ON" or "OFF"
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 16
    toggle.TextColor3 = Color3.fromRGB(20, 20, 20)
    toggle.AutoButtonColor = false
    toggle.Parent = btnFrame
    local toggled = default

    toggle.MouseButton1Click:Connect(function()
        toggled = not toggled
        toggle.BackgroundColor3 = toggled and Color3.fromRGB(100, 180, 100) or Color3.fromRGB(178, 34, 34)
        toggle.Text = toggled and "ON" or "OFF"
        btnFrame:SetAttribute("state", toggled)
        if btnFrame.OnToggle then
            btnFrame:OnToggle(toggled)
        end
    end)

    btnFrame:SetAttribute("state", default)
    return btnFrame
end

-- ========== BLOCK FRUIT FEATURES ==========
local function blockFruitFeatures(parent)
    local label = Instance.new("TextLabel")
    label.Text = "Block Fruit Features"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 22
    label.TextColor3 = Color3.fromRGB(180, 180, 255)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Parent = parent

    -- Auto Farm Toggle
    local autoFarmToggle = createToggleButton(parent, "Auto Farm", false)
    autoFarmToggle.Parent = parent

    -- Collect Fruits Toggle
    local collectFruitsToggle = createToggleButton(parent, "Auto Collect Fruits", false)
    collectFruitsToggle.Parent = parent

    -- Auto Skill Attack Toggle
    local autoSkillAttackToggle = createToggleButton(parent, "Auto Skill Attack", false)
    autoSkillAttackToggle.Parent = parent

    -- Dummy variable flags
    local toggles = {
        autoFarm = false,
        collectFruits = false,
        autoSkillAttack = false,
    }

    autoFarmToggle:OnToggle(function(state)
        toggles.autoFarm = state
    end)

    collectFruitsToggle:OnToggle(function(state)
        toggles.collectFruits = state
    end)

    autoSkillAttackToggle:OnToggle(function(state)
        toggles.autoSkillAttack = state
    end)

    -- Block Fruit Auto-Farming and other features runner
    spawn(function()
        while true do
            wait(0.3)
            if toggles.autoFarm then
                -- Auto Farm logic - simplified example: teleport to nearest enemy and attack
                local enemy = nil

                for _, npc in pairs(workspace:GetChildren()) do
                    if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc.Name ~= LocalPlayer.Name then
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
                        if dist < 100 then
                            enemy = npc
                            break
                        end
                    end
                end

                if enemy and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    -- Teleport near enemy
                    LocalPlayer.Character.HumanoidRootPart.CFrame = enemy.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                end
            end

            if toggles.collectFruits then
                -- Collect nearby fruits
                for _, fruit in pairs(workspace:GetChildren()) do
                    if fruit.Name == "Fruit" and fruit:IsA("BasePart") then
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - fruit.Position).Magnitude
                        if dist < 30 then
                            fruit.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                        end
                    end
                end
            end

            if toggles.autoSkillAttack then
                -- Auto skill attack simplified (send key events to fire skill)
                -- Requires actual game API or key event simulation
            end
        end
    end)
end

-- ========== GROW A GARDEN FEATURES ==========
local function growAGardenFeatures(parent)
    local label = Instance.new("TextLabel")
    label.Text = "Grow A Garden Features"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 22
    label.TextColor3 = Color3.fromRGB(180, 255, 180)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Parent = parent

    -- Auto Plant Toggle
    local autoPlantToggle = createToggleButton(parent, "Auto Plant", false)
    autoPlantToggle.Parent = parent

    -- Auto Harvest Toggle
    local autoHarvestToggle = createToggleButton(parent, "Auto Harvest", false)
    autoHarvestToggle.Parent = parent

    local toggles = {
        autoPlant = false,
        autoHarvest = false,
    }

    autoPlantToggle:OnToggle(function(state)
        toggles.autoPlant = state
    end)

    autoHarvestToggle:OnToggle(function(state)
        toggles.autoHarvest = state
    end)

    spawn(function()
        while true do
            wait(0.5)
            if toggles.autoPlant then
                -- Auto plant logic (simulated)
                -- For demo purposes, try to click planting area or fire remote events if available
            end

            if toggles.autoHarvest then
                -- Auto harvest nearby grown plants
            end
        end
    end)
end

-- ========== BUILD A BOAT FEATURES ==========
local function buildABoatFeatures(parent)
    local label = Instance.new("TextLabel")
    label.Text = "Build A Boat Features"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 22
    label.TextColor3 = Color3.fromRGB(180, 210, 255)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Parent = parent

    -- Auto Build Toggle
    local autoBuildToggle = createToggleButton(parent, "Auto Build Boat", false)
    autoBuildToggle.Parent = parent

    -- Auto Collect Materials Toggle
    local autoCollectToggle = createToggleButton(parent, "Auto Collect Materials", false)
    autoCollectToggle.Parent = parent

    local toggles = {
        autoBuild = false,
        autoCollect = false,
    }

    autoBuildToggle:OnToggle(function(state)
        toggles.autoBuild = state
    end)

    autoCollectToggle:OnToggle(function(state)
        toggles.autoCollect = state
    end)

    spawn(function()
        while true do
            wait(0.3)
            if toggles.autoCollect then
                -- Auto Collect materials logic (simulated)
            end

            if toggles.autoBuild then
                -- Auto build logic (simulated)
            end
        end
    end)
end

-- Create tabs and sections per game if supported
if currentGame == "BlockFruit" then
    local tab = createTab("Block Fruit")
    tab.Parent = TabContainer
    local section = createFeatureSection("Block Fruit")
    section.Parent = ContentContainer
    blockFruitFeatures(section)
    table.insert(tabs, tab)
    table.insert(sections, section)
elseif currentGame == "GrowARichGarden" then
    local tab = createTab("Grow A Garden")
    tab.Parent = TabContainer
    local section = createFeatureSection("Grow A Garden")
    section.Parent = ContentContainer
    growAGardenFeatures(section)
    table.insert(tabs, tab)
    table.insert(sections, section)
elseif currentGame == "BuildABoatForTreasure" then
    local tab = createTab("Build A Boat")
    tab.Parent = TabContainer
    local section = createFeatureSection("Build A Boat")
    section.Parent = ContentContainer
    buildABoatFeatures(section)
    table.insert(tabs, tab)
    table.insert(sections, section)
else
    -- Unsupported game, no tabs
end

-- If there are tabs, activate the first by default
if #tabs > 0 then
    activateTab(tabs[1], sections[1])
end

-- Allow switching tabs on click
for i, tab in pairs(tabs) do
    tab.MouseButton1Click:Connect(function()
        activateTab(tab, sections[i])
    end)
end

-- Draggable UI functionality with mouse
local dragging
local dragInput
local dragStart
local startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Animate open UI fade in
ScreenGui.Enabled = true
MainFrame.BackgroundTransparency = 1
TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.15}):Play()

-- Final message print
print("[GMON Hub] Loaded for game:", currentGame or "Unsupported")

-- End of script
