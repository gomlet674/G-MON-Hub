-- GUI Toggle Setup
local chestToggle = false
local espToggle = false

-- Simple Notification
local function notify(msg)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "GMON HUB",
            Text = msg,
            Duration = 5
        })
    end)
end

-- ESP GOD CHALICE
local function espGodChalice()
    notify("ESP God Chalice Active!")
    while espToggle do
        task.wait(1)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj.Name == "God's Chalice" and not obj:FindFirstChild("ESP") then
                local billboard = Instance.new("BillboardGui", obj)
                billboard.Name = "ESP"
                billboard.Size = UDim2.new(0, 100, 0, 40)
                billboard.Adornee = obj.Handle or obj:FindFirstChildWhichIsA("Part")
                billboard.AlwaysOnTop = true

                local text = Instance.new("TextLabel", billboard)
                text.Size = UDim2.new(1, 0, 1, 0)
                text.Text = "GOD CHALICE"
                text.TextColor3 = Color3.new(1, 0, 0)
                text.BackgroundTransparency = 1
                text.TextStrokeTransparency = 0.5
            end
        end
    end
end

-- FARM CHEST
local function farmChest()
    notify("Farm Chest Started!")
    while chestToggle do
        local chests = {}
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and not v:FindFirstChild("HumanoidRootPart") and v.Name:find("Chest") then
                table.insert(chests, v)
            elseif v:IsA("Tool") and v.Name == "God's Chalice" then
                notify("FOUND GOD CHALICE!")
                chestToggle = false
                return
            end
        end

        -- Kocok urutan chest agar tidak tempat yang sama terus
        for i = #chests, 2, -1 do
            local j = math.random(1, i)
            chests[i], chests[j] = chests[j], chests[i]
        end

        for _, chest in pairs(chests) do
            if not chestToggle then break end
            if chest and chest:IsDescendantOf(workspace) then
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = chest:GetModelCFrame()
                task.wait(1.25)
            end
        end

        task.wait(2)
    end
end

-- Toggle UI (melengkung dan RGB toggle)
local function createToggleUI()
    if game:GetService("CoreGui"):FindFirstChild("GMON_Toggle") then
        game:GetService("CoreGui"):FindFirstChild("GMON_Toggle"):Destroy()
    end

    local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    gui.Name = "GMON_Toggle"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 160, 0, 160)
    frame.Position = UDim2.new(0.02, 0, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Active = true
    frame.Draggable = true

    local uiCorner = Instance.new("UICorner", frame)
    uiCorner.CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    task.spawn(function()
        while gui and gui.Parent do
            for i = 0, 1, 0.02 do
                local r = math.sin(i * math.pi * 2) * 127 + 128
                local g = math.sin(i * math.pi * 2 + 2) * 127 + 128
                local b = math.sin(i * math.pi * 2 + 4) * 127 + 128
                stroke.Color = Color3.fromRGB(r, g, b)
                task.wait(0.03)
            end
        end
    end)

    -- ESP Toggle
    local espBtn = Instance.new("TextButton", frame)
    espBtn.Size = UDim2.new(0.9, 0, 0, 40)
    espBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
    espBtn.Text = "ESP God Chalice: OFF"
    espBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    espBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 10)

    espBtn.MouseButton1Click:Connect(function()
        espToggle = not espToggle
        espBtn.Text = "ESP God Chalice: " .. (espToggle and "ON" or "OFF")
        if espToggle then
            task.spawn(espGodChalice)
        end
    end)

    -- Farm Chest Toggle
    local chestBtn = Instance.new("TextButton", frame)
    chestBtn.Size = UDim2.new(0.9, 0, 0, 40)
    chestBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
    chestBtn.Text = "Farm Chest: OFF"
    chestBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    chestBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", chestBtn).CornerRadius = UDim.new(0, 10)

    chestBtn.MouseButton1Click:Connect(function()
        chestToggle = not chestToggle
        chestBtn.Text = "Farm Chest: " .. (chestToggle and "ON" or "OFF")
        if chestToggle then
            task.spawn(farmChest)
        end
    end)
end

-- Run UI
createToggleUI()