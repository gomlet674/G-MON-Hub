-- main.lua – Grow A Garden Hub (Mobile/Desktop)

-- tunggu game selesai load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Replicated       = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")

local lp = Players.LocalPlayer

-- flags
local Flags = {
    AutoHatch     = false,
    ESPPrediction = false,
}

-- map telur → pet yang mungkin muncul
local predictionMap = {
    BasicEgg = { "Bunny", "Bear", "Pig" },
    RareEgg  = { "Raccoon", "Red Fox", "Dragon Fly" },
    EpicEgg  = { "Disco Bee", "Phantom" },
}

-- helper pembuatan UI
local function New(cls, props, parent)
    local inst = Instance.new(cls)
    for k,v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- fungsi draggable (mouse + touch)
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            -- detect end
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- buat ScreenGui
local screenGui = New("ScreenGui", {
    Name = "GrowAGardenHub",
    Parent = lp:WaitForChild("PlayerGui"),
    ResetOnSpawn = false,
})

-- main frame
local frame = New("Frame", {
    Name = "MainUI",
    Size = UDim2.new(0, 260, 0, 180),
    Position = UDim2.new(0, 20, 0, 100),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BorderColor3 = Color3.fromRGB(75, 75, 75),
    BorderSizePixel = 1,
}, screenGui)
New("UICorner", { CornerRadius = UDim.new(0, 8) }, frame)
makeDraggable(frame)

-- judul
New("TextLabel", {
    Parent = frame,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "🌱 Grow A Garden Hub",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Center,
}, frame)

-- container tombol
local container = New("Frame", {
    Parent = frame,
    Size = UDim2.new(1, -20, 1, -60),
    Position = UDim2.new(0, 10, 0, 40),
    BackgroundTransparency = 1,
}, frame)
New("UIListLayout", {
    Parent = container,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
}, container)

-- fungsi buat toggle button
local function createToggle(text, field)
    local btn = New("TextButton", {
        Parent = container,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(68, 68, 68),
        AutoButtonColor = false,
        Text = "",  -- kita buat label child
    })
    New("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)

    local lbl = New("TextLabel", {
        Parent = btn,
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text .. ": OFF",
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local status = New("TextLabel", {
        Parent = btn,
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(1, -50, 0, 0),
        BackgroundTransparency = 1,
        Text = "OFF",
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 85, 85),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    btn.MouseButton1Click:Connect(function()
        Flags[field] = not Flags[field]
        status.Text = Flags[field] and "ON" or "OFF"
        status.TextColor3 = Flags[field] and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(255, 85, 85)
    end)
    return btn
end

-- buat dua toggle
createToggle("Auto Hatch",     "AutoHatch")
createToggle("ESP Prediction", "ESPPrediction")

-- info kecil di bawah
New("TextLabel", {
    Parent = frame,
    Size = UDim2.new(1, -20, 0, 16),
    Position = UDim2.new(0, 10, 1, -22),
    BackgroundTransparency = 1,
    Text = "Drag anywhere to move • M to toggle UI",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(160, 160, 160),
    TextXAlignment = Enum.TextXAlignment.Left,
}, frame)

-- toggle UI dengan M
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- LOGIC AUTO HATCH
task.spawn(function()
    local rem = Replicated:WaitForChild("Remotes"):WaitForChild("HatchEgg")
    while task.wait(1) do
        if Flags.AutoHatch then
            for eggType in pairs(predictionMap) do
                pcall(rem.InvokeServer, rem, eggType)
            end
        end
    end
end)

-- LOGIC ESP PREDICTION
task.spawn(function()
    while task.wait(2) do
        if Flags.ESPPrediction then
            for _,mdl in ipairs(Workspace:GetDescendants()) do
                if mdl:IsA("Model") and predictionMap[mdl.Name] and not mdl:FindFirstChild("ESP_GUI") then
                    local part = mdl:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local bb = New("BillboardGui", {
                            Parent = mdl,
                            Name = "ESP_GUI",
                            Adornee = part,
                            Size = UDim2.new(0, 120, 0, 28),
                            StudsOffset = Vector3.new(0, 3, 0),
                            AlwaysOnTop = true,
                        })
                        New("UICorner", { CornerRadius = UDim.new(0,4) }, bb)
                        New("TextLabel", {
                            Parent = bb,
                            Size = UDim2.new(1,0,1,0),
                            BackgroundTransparency = 0.7,
                            BackgroundColor3 = Color3.fromRGB(0,0,0),
                            TextColor3 = Color3.fromRGB(255,255,0),
                            Font = Enum.Font.Gotham,
                            TextSize = 14,
                            Text = "🎁 ".. table.concat(predictionMap[mdl.Name], ", "),
                            TextWrapped = true,
                        })
                    end
                end
            end
        else
            for _,gui in ipairs(Workspace:GetDescendants()) do
                if gui.Name == "ESP_GUI" then
                    gui:Destroy()
                end
            end
        end
    end
end)
