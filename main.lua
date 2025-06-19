-- main.lua – Grow A Garden Hub “NatHub” Style ESP Eggs

-- Wait until game is loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Replicated       = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

-- Flags
local Flags = {
    ESP_Common      = false,
    ESP_Uncommon    = false,
    ESP_Rare        = false,
    ESP_Legendary   = false,
    ESP_Mythical    = false,
    ESP_Bug         = false,
    ESP_Bee         = false,
    ESP_AntiBee     = false,
}

-- Prediction map
local predictionMap = {
    CommonEgg      = { "Golden Lab", "Dog", "Bunny" },
    UncommonEgg    = { "Black Bunny", "Chicken", "Cat", "Deer" },
    RareEgg        = { "Orange Tabby", "Spotted Deer", "Pig", "Rooster", "Monkey" },
    LegendaryEgg   = { "Cow", "Silver Monkey", "Sea Otter", "Turtle", "Polar Bear" },
    MythicalEgg    = { "Grey Mouse", "Brown Mouse", "Squirrel", "Red Giant Ant", "Red Fox" },
    BugEgg         = { "Snail", "Giant Ant", "Caterpillar", "Praying Mantis", "Dragonfly" },
    BeeEgg         = { "Bee", "Honey Bee", "Bear Bee", "Petal Bee", "Queen Bee" },
    AntiBeeEgg     = { "Wasp", "Tarantula Hawk", "Moth", "Butterfly", "Disco Bee" },
}

-- Helper to create Instance
local function New(cls, props, parent)
    local inst = Instance.new(cls)
    for k,v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- Draggable handling (mouse & touch)
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos  = frame.Position
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
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Create ScreenGui
local screenGui = New("ScreenGui", {
    Name = "NatHubGrowGarden",
    ResetOnSpawn = false,
    Parent = lp:WaitForChild("PlayerGui"),
})

-- GMON Toggle Button
local toggleBtn = New("TextButton", {
    Name = "GMONToggle",
    Text = "GMON",
    Size = UDim2.new(0, 60, 0, 32),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    TextColor3 = Color3.fromRGB(230, 230, 230),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    AutoButtonColor = false,
    ZIndex = 10,
}, screenGui)
New("UICorner", { CornerRadius = UDim.new(0,6) }, toggleBtn)
makeDraggable(toggleBtn)

-- Main Frame
local frame = New("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 280, 0, 400),
    Position = UDim2.new(0, 12, 0, 52),
    BackgroundColor3 = Color3.fromRGB(28, 28, 28),
    BorderColor3 = Color3.fromRGB(60, 60, 60),
    BorderSizePixel = 1,
    Visible = false,
}, screenGui)
New("UICorner", { CornerRadius = UDim.new(0,8) }, frame)
makeDraggable(frame)

-- Title Bar
local titleBar = New("Frame", {
    Parent = frame,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
}, frame)
New("UICorner", { CornerRadius = UDim.new(0,8) }, titleBar)

New("TextLabel", {
    Parent = titleBar,
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "ESP Egg Prediction",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255,255,255),
    TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

-- Close Button
local closeBtn = New("TextButton", {
    Parent = titleBar,
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -34, 0, 3),
    Text = "✕",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(200,200,200),
    BackgroundTransparency = 1,
    AutoButtonColor = false,
}, titleBar)
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

-- Content ScrollingFrame
local scroll = New("ScrollingFrame", {
    Parent = frame,
    Size = UDim2.new(1, -20, 1, -40),
    Position = UDim2.new(0, 10, 0, 35),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6,
    BackgroundTransparency = 1,
}, frame)
local layout = New("UIListLayout", {
    Parent = scroll,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 10),
}, scroll)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-- Toggle Switch Factory
local function createSwitch(label, flagName)
    local holder = New("Frame", {
        Parent = scroll,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
    }, scroll)
    New("TextLabel", {
        Parent = holder,
        Size = UDim2.new(0.75, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(230,230,230),
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 0),
    }, holder)

    local sw = New("Frame", {
        Parent = holder,
        Size = UDim2.new(0, 40, 0, 24),
        Position = UDim2.new(1, -50, 0.5, -12),
        BackgroundColor3 = Color3.fromRGB(60,60,60),
        BorderSizePixel = 0,
        Name = "SwitchHolder",
    }, holder)
    New("UICorner", { CornerRadius = UDim.new(0,12) }, sw)

    local knob = New("Frame", {
        Parent = sw,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0,2,0,2),
        BackgroundColor3 = Color3.fromRGB(200,200,200),
        Name = "Knob",
    }, sw)
    New("UICorner", { CornerRadius = UDim.new(0,10) }, knob)

    -- update visual
    local function update()
        if Flags[flagName] then
            knob:TweenPosition(UDim2.new(1, -22, 0, 2), "InOut", "Quad", 0.15, true)
            sw.BackgroundColor3 = Color3.fromRGB(0,170,0)
        else
            knob:TweenPosition(UDim2.new(0, 2, 0, 2), "InOut", "Quad", 0.15, true)
            sw.BackgroundColor3 = Color3.fromRGB(60,60,60)
        end
    end

    sw.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Flags[flagName] = not Flags[flagName]
            update()
        end
    end)

    update()
end

-- Create switches for each egg type
createSwitch("CommonEgg",    "ESP_Common")
createSwitch("UncommonEgg",  "ESP_Uncommon")
createSwitch("RareEgg",      "ESP_Rare")
createSwitch("LegendaryEgg", "ESP_Legendary")
createSwitch("MythicalEgg",  "ESP_Mythical")
createSwitch("BugEgg",       "ESP_Bug")
createSwitch("BeeEgg",       "ESP_Bee")
createSwitch("Anti BeeEgg",  "ESP_AntiBee")

-- ganti bagian createSwitch dengan yang ini:

local function createSwitch(label, flagName)
    -- holder
    local holder = New("Frame", {
        Parent = scroll,
        Size   = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
    })
    -- label teks
    New("TextLabel", {
        Parent         = holder,
        Size           = UDim2.new(0.75, 0, 1, 0),
        Position       = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text           = label,
        Font           = Enum.Font.Gotham,
        TextSize       = 14,
        TextColor3     = Color3.fromRGB(230,230,230),
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- switch sebagai TextButton
    local sw = New("TextButton", {
        Parent           = holder,
        Size             = UDim2.new(0, 40, 0, 24),
        Position         = UDim2.new(1, -50, 0.5, -12),
        BackgroundColor3 = Color3.fromRGB(60,60,60),
        AutoButtonColor  = false,
        Text             = "",         -- kosongkan text
    })
    New("UICorner", { CornerRadius = UDim.new(0,12) }, sw)

    -- knob di dalam sw
    local knob = New("Frame", {
        Parent           = sw,
        Size             = UDim2.new(0, 20, 0, 20),
        Position         = UDim2.new(0,2,0,2),
        BackgroundColor3 = Color3.fromRGB(200,200,200),
    })
    New("UICorner", { CornerRadius = UDim.new(0,10) }, knob)

    -- fungsi update visual
    local function update()
        if Flags[flagName] then
            sw.BackgroundColor3 = Color3.fromRGB(0,170,0)
            knob:TweenPosition(UDim2.new(1, -22, 0, 2), "InOut", "Quad", 0.15, true)
        else
            sw.BackgroundColor3 = Color3.fromRGB(60,60,60)
            knob:TweenPosition(UDim2.new(0, 2, 0, 2), "InOut", "Quad", 0.15, true)
        end
    end

    -- sekarang event klik pakai MouseButton1Click
    sw.MouseButton1Click:Connect(function()
        Flags[flagName] = not Flags[flagName]
        update()
    end)

    -- inisialisasi posisi awal
    update()
end
-- Toggle main frame
toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Hotkey M
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- ESP Egg Prediction Logic
task.spawn(function()
    while task.wait(1.5) do
        -- clear old GUIs
        for _, gui in ipairs(Workspace:GetDescendants()) do
            if gui.Name == "EggESP" and gui:IsA("BillboardGui") then
                gui:Destroy()
            end
        end

        for eggName, pets in pairs(predictionMap) do
            local flagKey = "ESP_" .. eggName:gsub("Egg", "")
            if Flags[flagKey] then
                for _, model in ipairs(Workspace:GetDescendants()) do
                    if model:IsA("Model") and model.Name == eggName then
                        local part = model:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local bb = New("BillboardGui", {
                                Name = "EggESP",
                                Parent = model,
                                Adornee = part,
                                Size = UDim2.new(0, 140, 0, 30),
                                StudsOffset = Vector3.new(0, 3, 0),
                                AlwaysOnTop = true,
                            }, model)
                            New("UICorner", { CornerRadius = UDim.new(0,4) }, bb)
                            New("TextLabel", {
                                Parent = bb,
                                Size = UDim2.new(1,0,1,0),
                                BackgroundTransparency = 0.6,
                                BackgroundColor3 = Color3.fromRGB(0,0,0),
                                TextColor3 = Color3.fromRGB(255,255,0),
                                Font = Enum.Font.Gotham,
                                TextSize = 14,
                                Text = "→ " .. table.concat(pets, ", "),
                                TextWrapped = true,
                            }, bb)
                        end
                    end
                end
            end
        end
    end
end)
