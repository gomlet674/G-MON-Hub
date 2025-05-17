local function createFloatingToggle()
    local UserInputService = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    local toggleGui = Instance.new("ScreenGui", CoreGui)
    toggleGui.Name = "GMON_FloatingToggle"
    toggleGui.ResetOnSpawn = false

    local dragFrame = Instance.new("Frame", toggleGui)
    dragFrame.Size = UDim2.new(0, 120, 0, 120)
    dragFrame.Position = UDim2.new(0.05, 0, 0.5, 0)
    dragFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    dragFrame.BackgroundTransparency = 0.4
    dragFrame.BorderSizePixel = 0
    dragFrame.Active = true
    dragFrame.Draggable = true
    dragFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    dragFrame.ClipsDescendants = true
    dragFrame.Name = "FloatingFrame"
    dragFrame.ZIndex = 1000
    dragFrame:TweenSize(UDim2.new(0, 120, 0, 120), "Out", "Sine", 0.3)

    -- Membuat frame jadi bulat
    local uicorner = Instance.new("UICorner", dragFrame)
    uicorner.CornerRadius = UDim.new(1, 0)

    -- Tombol Auto Farm
    local autoFarmBtn = Instance.new("TextButton", dragFrame)
    autoFarmBtn.Size = UDim2.new(1, -10, 0.4, -5)
    autoFarmBtn.Position = UDim2.new(0, 5, 0.05, 0)
    autoFarmBtn.Text = "Auto Farm OFF"
    autoFarmBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    autoFarmBtn.TextColor3 = Color3.new(1, 1, 1)
    autoFarmBtn.AutoButtonColor = true
    autoFarmBtn.ZIndex = 1001
    local afCorner = Instance.new("UICorner", autoFarmBtn)
    afCorner.CornerRadius = UDim.new(0.5, 0)

    -- Tombol Farm Chest
    local chestBtn = Instance.new("TextButton", dragFrame)
    chestBtn.Size = UDim2.new(1, -10, 0.4, -5)
    chestBtn.Position = UDim2.new(0, 5, 0.55, 0)
    chestBtn.Text = "Farm Chest OFF"
    chestBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    chestBtn.TextColor3 = Color3.new(1, 1, 1)
    chestBtn.AutoButtonColor = true
    chestBtn.ZIndex = 1001
    local chCorner = Instance.new("UICorner", chestBtn)
    chCorner.CornerRadius = UDim.new(0.5, 0)

    -- Toggle Logic
    local autoFarm = false
    local farmChest = false

    autoFarmBtn.MouseButton1Click:Connect(function()
        autoFarm = not autoFarm
        _G.ToggleAutoFarm = autoFarm
        autoFarmBtn.Text = autoFarm and "Auto Farm ON" or "Auto Farm OFF"
        autoFarmBtn.BackgroundColor3 = autoFarm and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    end)

    chestBtn.MouseButton1Click:Connect(function()
        farmChest = not farmChest
        _G.ToggleFarmChest = farmChest
        chestBtn.Text = farmChest and "Farm Chest ON" or "Farm Chest OFF"
        chestBtn.BackgroundColor3 = farmChest and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(100, 100, 100)
    end)
end

-- Panggil ini setelah UI utama muncul
createFloatingToggle()