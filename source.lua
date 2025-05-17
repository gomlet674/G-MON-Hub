repeat wait() until game:IsLoaded()

-- Toggle Flags
local chestToggle = false
local espToggle = false

-- Notification
local function notify(msg)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "GMON HUB",
            Text = msg,
            Duration = 5
        })
    end)
end

-- ESP God Chalice
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

-- Farm Chest
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

-- Toggle UI
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

    -- ESP Button
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

    -- Chest Button
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

-- Key System GUI
local function showKeySystem()
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    ScreenGui.Name = "GMON_Loader"

    local background = Instance.new("ImageLabel", ScreenGui)
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Image = "rbxassetid://16790218639"
    background.BackgroundTransparency = 1
    background.ScaleType = Enum.ScaleType.Crop
    background.ZIndex = 0

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 420, 0, 200)
    Frame.Position = UDim2.new(0.5, -210, 0.5, -100)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.Active = true
    Frame.Draggable = true
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 15)

    local RGBBorder = Instance.new("UIStroke", Frame)
    RGBBorder.Thickness = 2
    RGBBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    task.spawn(function()
        while true do
            for i = 0, 1, 0.01 do
                local r = math.sin(i * math.pi * 2) * 127 + 128
                local g = math.sin(i * math.pi * 2 + 2) * 127 + 128
                local b = math.sin(i * math.pi * 2 + 4) * 127 + 128
                RGBBorder.Color = Color3.fromRGB(r, g, b)
                wait(0.03)
            end
        end
    end)

    local Title = Instance.new("TextLabel", Frame)
    Title.Text = "GMON HUB KEY SYSTEM"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundTransparency = 1

    local KeyBox = Instance.new("TextBox", Frame)
    KeyBox.PlaceholderText = "Enter Your Key..."
    KeyBox.Size = UDim2.new(0.9, 0, 0, 35)
    KeyBox.Position = UDim2.new(0.05, 0, 0.35, 0)
    KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    KeyBox.Font = Enum.Font.Gotham
    KeyBox.Text = ""
    KeyBox.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

    local Submit = Instance.new("TextButton", Frame)
    Submit.Size = UDim2.new(0.4, 0, 0, 35)
    Submit.Position = UDim2.new(0.05, 0, 0.7, 0)
    Submit.Text = "Submit"
    Submit.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Submit.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 8)

    local GetKey = Instance.new("TextButton", Frame)
    GetKey.Size = UDim2.new(0.4, 0, 0, 35)
    GetKey.Position = UDim2.new(0.55, 0, 0.7, 0)
    GetKey.Text = "Get Key"
    GetKey.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    GetKey.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0, 8)

    GetKey.MouseButton1Click:Connect(function()
        setclipboard("https://linkvertise.com/your-key-page")
        notify("Link copied to clipboard!")
    end)

    Submit.MouseButton1Click:Connect(function()
        if KeyBox.Text == "gmonkey" then
            notify("Key Verified!")
            ScreenGui:Destroy()
            createToggleUI()
        else
            notify("Invalid Key!")
        end
    end)
end

-- Start
showKeySystem()