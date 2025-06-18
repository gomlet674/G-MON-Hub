-- GMON Hub Complete UI Script (UinYnya)
-- Place this LocalScript inside StarterPlayerScripts or StarterGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote Events
local RemoteFolder = ReplicatedStorage:WaitForChild("GMONHubRemotes")
local AutoHatchToggleEvent = RemoteFolder:WaitForChild("AutoHatchToggle")
local SelectPetEvent = RemoteFolder:WaitForChild("SelectPet")
local PlantSeedEvent = RemoteFolder:WaitForChild("PlantSeed")
local HarvestPlantEvent = RemoteFolder:WaitForChild("HarvestPlant")
local RequestInventoryEvent = RemoteFolder:WaitForChild("RequestInventory")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GMONHubUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame (75% transparent with vibrant RGB color)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0,1)
mainFrame.Position = UDim2.new(0, 20, 1, -20)
mainFrame.Size = UDim2.new(0, 360, 0, 510)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
mainFrame.BackgroundTransparency = 0.75
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.ClipsDescendants = true
mainFrame.Draggable = true

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 15)
uiCorner.Parent = mainFrame

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 48)
titleLabel.BackgroundColor3 = Color3.fromRGB(30,30,30)
titleLabel.BackgroundTransparency = 0.25
titleLabel.BorderSizePixel = 0
titleLabel.Parent = mainFrame
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "GMON Hub - Garden"
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
titleLabel.TextSize = 22
titleLabel.TextStrokeTransparency = 0.7

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 15)
titleCorner.Parent = titleLabel

-- UIListLayout for vertical stacking
local contentLayout = Instance.new("UIListLayout")
contentLayout.Parent = mainFrame
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 12)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Spacer after title
local spacer1 = Instance.new("Frame")
spacer1.Size = UDim2.new(1, 0, 0, 12)
spacer1.BackgroundTransparency = 1
spacer1.Parent = mainFrame

-- Auto Hatch Toggle Button
local autoHatchToggle = Instance.new("TextButton")
autoHatchToggle.Name = "AutoHatchToggle"
autoHatchToggle.Size = UDim2.new(0.92, 0, 0, 48)
autoHatchToggle.BackgroundColor3 = Color3.fromRGB(0, 85, 170)
autoHatchToggle.BackgroundTransparency = 0.25
autoHatchToggle.BorderSizePixel = 0
autoHatchToggle.Parent = mainFrame
autoHatchToggle.Font = Enum.Font.GothamSemibold
autoHatchToggle.Text = "Auto Hatch: OFF"
autoHatchToggle.TextColor3 = Color3.fromRGB(240, 240, 240)
autoHatchToggle.TextSize = 20

local autoHatchCorner = Instance.new("UICorner")
autoHatchCorner.CornerRadius = UDim.new(0, 12)
autoHatchCorner.Parent = autoHatchToggle

local autoHatchEnabled = false
autoHatchToggle.MouseButton1Click:Connect(function()
    autoHatchEnabled = not autoHatchEnabled
    autoHatchToggle.Text = "Auto Hatch: " .. (autoHatchEnabled and "ON" or "OFF")
    AutoHatchToggleEvent:FireServer(autoHatchEnabled)
end)

-- Pet Selection Label and Dropdown
local petSelectionLabel = Instance.new("TextLabel")
petSelectionLabel.Name = "PetSelectionLabel"
petSelectionLabel.Size = UDim2.new(0.92, 0, 0, 24)
petSelectionLabel.BackgroundTransparency = 1
petSelectionLabel.Font = Enum.Font.GothamSemibold
petSelectionLabel.Text = "Select Pet:"
petSelectionLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
petSelectionLabel.TextSize = 18
petSelectionLabel.TextXAlignment = Enum.TextXAlignment.Left
petSelectionLabel.Parent = mainFrame

local petSelectionDropdown = Instance.new("TextButton")
petSelectionDropdown.Name = "PetSelectionDropdown"
petSelectionDropdown.Size = UDim2.new(0.92, 0, 0, 36)
petSelectionDropdown.BackgroundColor3 = Color3.fromRGB(0, 85, 170)
petSelectionDropdown.BackgroundTransparency = 0.25
petSelectionDropdown.BorderSizePixel = 0
petSelectionDropdown.Font = Enum.Font.GothamSemibold
petSelectionDropdown.Text = "No Pets"
petSelectionDropdown.TextColor3 = Color3.fromRGB(230, 230, 230)
petSelectionDropdown.TextSize = 18
petSelectionDropdown.Parent = mainFrame

local petDropdownCorner = Instance.new("UICorner")
petDropdownCorner.CornerRadius = UDim.new(0, 12)
petDropdownCorner.Parent = petSelectionDropdown

local petListFrame = Instance.new("Frame")
petListFrame.Name = "PetListFrame"
petListFrame.Size = UDim2.new(0.92, 0, 0, 160)
petListFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
petListFrame.BackgroundTransparency = 0.3
petListFrame.BorderSizePixel = 0
petListFrame.ClipsDescendants = true
petListFrame.Visible = false
petListFrame.Parent = mainFrame

local petListCorner = Instance.new("UICorner")
petListCorner.CornerRadius = UDim.new(0, 12)
petListCorner.Parent = petListFrame

local petListLayout = Instance.new("UIListLayout")
petListLayout.Parent = petListFrame
petListLayout.SortOrder = Enum.SortOrder.LayoutOrder
petListLayout.Padding = UDim.new(0, 8)

local petsData = {}
local selectedPetIndex = 0

local function updatePetList(inventoryPets)
    -- Clear existing pet buttons
    for _, child in pairs(petListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    petsData = inventoryPets or {}
    if #petsData == 0 then
        petSelectionDropdown.Text = "No Pets"
        petListFrame.Visible = false
        selectedPetIndex = 0
        return
    end

    -- Default select first pet if none selected
    if selectedPetIndex == 0 or not petsData[selectedPetIndex] then
        selectedPetIndex = 1
    end

    petSelectionDropdown.Text = petsData[selectedPetIndex].PetName or ("Pet " .. selectedPetIndex)

    for i, pet in ipairs(petsData) do
        local petBtn = Instance.new("TextButton")
        petBtn.Name = "PetBtn_" .. i
        petBtn.Size = UDim2.new(1, 0, 0, 36)
        petBtn.BackgroundColor3 = (i == selectedPetIndex) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(0, 120, 220)
        petBtn.BackgroundTransparency = 0.2
        petBtn.BorderSizePixel = 0
        petBtn.Font = Enum.Font.GothamSemibold
        petBtn.Text = pet.PetName or ("Pet " .. i)
        petBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
        petBtn.TextSize = 16
        petBtn.Parent = petListFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = petBtn

        petBtn.MouseButton1Click:Connect(function()
            selectedPetIndex = i
            petSelectionDropdown.Text = pet.PetName or ("Pet " .. i)
            petListFrame.Visible = false
            SelectPetEvent:FireServer(selectedPetIndex)
        end)
    end
end

petSelectionDropdown.MouseButton1Click:Connect(function()
    petListFrame.Visible = not petListFrame.Visible
end)

-- Seeds Label and Scroll
local gardenSeedsLabel = Instance.new("TextLabel")
gardenSeedsLabel.Name = "GardenSeedsLabel"
gardenSeedsLabel.Size = UDim2.new(0.92, 0, 0, 24)
gardenSeedsLabel.BackgroundTransparency = 1
gardenSeedsLabel.Font = Enum.Font.GothamSemibold
gardenSeedsLabel.Text = "Seeds (Click to Plant):"
gardenSeedsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
gardenSeedsLabel.TextSize = 18
gardenSeedsLabel.TextXAlignment = Enum.TextXAlignment.Left
gardenSeedsLabel.Parent = mainFrame

local seedsListFrame = Instance.new("ScrollingFrame")
seedsListFrame.Name = "SeedsListFrame"
seedsListFrame.Size = UDim2.new(0.92, 0, 0, 120)
seedsListFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
seedsListFrame.BackgroundTransparency = 0.3
seedsListFrame.BorderSizePixel = 0
seedsListFrame.Parent = mainFrame
seedsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
seedsListFrame.ScrollBarThickness = 6

local seedsListCorner = Instance.new("UICorner")
seedsListCorner.CornerRadius = UDim.new(0, 12)
seedsListCorner.Parent = seedsListFrame

local seedsListLayout = Instance.new("UIListLayout")
seedsListLayout.Parent = seedsListFrame
seedsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
seedsListLayout.Padding = UDim.new(0, 8)
seedsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
seedsListLayout.FillDirection = Enum.FillDirection.Horizontal
seedsListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local maxSeedButtonWidth = 80

local function updateSeedsList(seedInventory)
    for _, child in pairs(seedsListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    if not seedInventory then return end

    local count = 0
    for seedName, quantity in pairs(seedInventory) do
        if quantity > 0 then
            count += 1
            local seedBtn = Instance.new("TextButton")
            seedBtn.Name = "SeedBtn_" .. seedName
            seedBtn.Size = UDim2.new(0, maxSeedButtonWidth, 0, 40)
            seedBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            seedBtn.BackgroundTransparency = 0.3
            seedBtn.BorderSizePixel = 0
            seedBtn.Font = Enum.Font.GothamSemibold
            seedBtn.Text = seedName .. "\n(" .. quantity .. ")"
            seedBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
            seedBtn.TextWrapped = true
            seedBtn.TextSize = 14
            seedBtn.Parent = seedsListFrame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 12)
            btnCorner.Parent = seedBtn

            seedBtn.MouseButton1Click:Connect(function()
                PlantSeedEvent:FireServer(seedName)
            end)
        end
    end
    seedsListFrame.CanvasSize = UDim2.new(0, maxSeedButtonWidth * count + (count - 1) * 8, 0, 0)
end

-- Garden plants label + scrolling list
local gardenPlantsLabel = Instance.new("TextLabel")
gardenPlantsLabel.Name = "GardenPlantsLabel"
gardenPlantsLabel.Size = UDim2.new(0.92, 0, 0, 24)
gardenPlantsLabel.BackgroundTransparency = 1
gardenPlantsLabel.Font = Enum.Font.GothamSemibold
gardenPlantsLabel.Text = "Garden Plants (Click to Harvest):"
gardenPlantsLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
gardenPlantsLabel.TextSize = 18
gardenPlantsLabel.TextXAlignment = Enum.TextXAlignment.Left
gardenPlantsLabel.Parent = mainFrame

local plantsListFrame = Instance.new("ScrollingFrame")
plantsListFrame.Name = "PlantsListFrame"
plantsListFrame.Size = UDim2.new(0.92, 0, 0, 150)
plantsListFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
plantsListFrame.BackgroundTransparency = 0.3
plantsListFrame.BorderSizePixel = 0
plantsListFrame.Parent = mainFrame
plantsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
plantsListFrame.ScrollBarThickness = 6

local plantsListCorner = Instance.new("UICorner")
plantsListCorner.CornerRadius = UDim.new(0, 12)
plantsListCorner.Parent = plantsListFrame

local plantsListLayout = Instance.new("UIListLayout")
plantsListLayout.Parent = plantsListFrame
plantsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
plantsListLayout.Padding = UDim.new(0, 6)

local function updatePlantsList(gardenPlants)
    for _, child in pairs(plantsListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    if not gardenPlants then return end

    for i, plant in ipairs(gardenPlants) do
        local name = plant.SeedName or "Seed"
        local readyStatus = plant.IsReady and "Ready" or "Growing..."
        local plantBtn = Instance.new("TextButton")
        plantBtn.Name = "PlantBtn_" .. i
        plantBtn.Size = UDim2.new(1, 0, 0, 32)
        plantBtn.BackgroundColor3 = plant.IsReady and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 100)
        plantBtn.BackgroundTransparency = 0.2
        plantBtn.BorderSizePixel = 0
        plantBtn.Font = Enum.Font.GothamSemibold
        plantBtn.Text = name .. " - " .. readyStatus
        plantBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
        plantBtn.TextSize = 16
        plantBtn.Parent = plantsListFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = plantBtn

        plantBtn.MouseButton1Click:Connect(function()
            if plant.IsReady then
                HarvestPlantEvent:FireServer(i)
            end
        end)
    end

    local layout = plantsListFrame:FindFirstChildOfClass("UIListLayout")
    if layout then
        wait()
        plantsListFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end
end

-- Message label for status messages
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.new(0.92, 0, 0, 36)
messageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.BackgroundTransparency = 0.85
messageLabel.BorderSizePixel = 0
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.fromRGB(40, 40, 40)
messageLabel.Font = Enum.Font.GothamSemibold
messageLabel.TextSize = 16
messageLabel.TextWrapped = true
messageLabel.Parent = mainFrame

local messageCorner = Instance.new("UICorner")
messageCorner.CornerRadius = UDim.new(0, 12)
messageCorner.Parent = messageLabel

local function showMessage(text, duration)
    messageLabel.Text = text
    delay(duration or 3, function()
        if messageLabel.Text == text then
            messageLabel.Text = ""
        end
    end)
end

-- Listen for inventory updates from the server
RequestInventoryEvent.OnClientEvent:Connect(function(inventory, gardenPlants, pets, selectedPet)
    updateSeedsList(inventory.Seeds)
    updatePlantsList(gardenPlants)
    updatePetList(pets)

    -- Update selected pet index
    if selectedPet then
        for i, pet in ipairs(pets) do
            if pet == selectedPet or (pet.PetName == selectedPet.PetName) then
                selectedPetIndex = i
                petSelectionDropdown.Text = pet.PetName or "Selected Pet"
                break
            end
        end
    end
end)

-- Listen for generic feedback (simulate by showing console prints)
local function onServerMessage(text)
    showMessage(text, 5)
end

-- Periodically request inventory update
spawn(function()
    while true do
        RequestInventoryEvent:FireServer()
        wait(10)
    end
end)

-- Show initial UI message
showMessage("Welcome to GMON Hub! Toggle Auto Hatch and manage your garden.", 5)

