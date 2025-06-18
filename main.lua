-- main.lua – Grow A Garden Hub (GMON)

-- tunggu sampai game selesai load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Replicated       = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")

local lp = Players.LocalPlayer

-- Flags
local Flags = {
    AutoHatch       = false,
    ESPPrediction   = false,
}

-- Egg → Possible Pets mapping (Grow a Garden Wiki)
local predictionMap = {
    CommonEgg      = { "Golden Lab", "Dog", "Bunny" },
    UncommonEgg    = { "Black Bunny", "Chicken", "Cat", "Deer" },
    RareEgg        = { "Orange Tabby", "Spotted Deer", "Pig", "Rooster", "Monkey" },
    LegendaryEgg   = { "Cow", "Silver Monkey", "Sea Otter", "Turtle", "Polar Bear" },
    MythicalEgg    = { "Grey Mouse", "Brown Mouse", "Squirrel", "Red Giant Ant", "Red Fox" },
    BugEgg         = { "Snail", "Giant Ant", "Caterpillar", "Praying Mantis", "Dragonfly" },
    BeeEgg         = { "Bee", "Honey Bee", "Bear Bee", "Petal Bee", "Queen Bee" },
    ["Anti BeeEgg"] = { "Wasp", "Tarantula Hawk", "Moth", "Butterfly", "Disco Bee" },
}

-- Helper untuk New Instance
local function New(cls, props, parent)
    local inst = Instance.new(cls)
    for k,v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- Fungsi draggable (mouse & touch)
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ====== UI ======

-- ScreenGui
local screenGui = New("ScreenGui", {
    Name         = "GrowAGardenHub",
    ResetOnSpawn = false,
    Parent       = lp:WaitForChild("PlayerGui"),
})

-- Tombol "GMON" untuk toggle main frame
local gmonBtn = New("TextButton", {
    Name               = "GMONToggle",
    Text               = "GMON",
    Size               = UDim2.new(0, 70, 0, 35),
    Position           = UDim2.new(0, 20, 0, 20),
    BackgroundColor3   = Color3.fromRGB(45,45,45),
    TextColor3         = Color3.fromRGB(255,255,255),
    AutoButtonColor    = false,
    ZIndex              = 2,
}, screenGui)
New("UICorner", { CornerRadius = UDim.new(0,6) }, gmonBtn)
makeDraggable(gmonBtn)

-- Main Frame
local frame = New("Frame", {
    Name             = "MainUI",
    Size             = UDim2.new(0, 260, 0, 180),
    Position         = UDim2.new(0, 20, 0, 70),
    BackgroundColor3 = Color3.fromRGB(25,25,25),
    BorderColor3     = Color3.fromRGB(75,75,75),
    BorderSizePixel  = 1,
}, screenGui)
New("UICorner", { CornerRadius = UDim.new(0,8) }, frame)
makeDraggable(frame)
frame.Visible = false

gmonBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Title
New("TextLabel", {
    Parent            = frame,
    Size              = UDim2.new(1,0,0,30),
    BackgroundTransparency = 1,
    Text              = "🌱 Grow A Garden Hub",
    Font              = Enum.Font.GothamBold,
    TextSize          = 18,
    TextColor3        = Color3.fromRGB(255,255,255),
    TextXAlignment    = Enum.TextXAlignment.Center,
}, frame)

-- Container untuk tombol
local container = New("Frame", {
    Parent    = frame,
    Size      = UDim2.new(1,-20,1,-60),
    Position  = UDim2.new(0,10,0,40),
    BackgroundTransparency = 1,
}, frame)
New("UIListLayout", {
    Parent    = container,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0,8),
}, container)

-- Fungsi buat toggle di dalam UI
local function createToggle(labelText, field)
    local btn = New("TextButton", {
        Parent           = container,
        Size             = UDim2.new(1,0,0,36),
        BackgroundColor3 = Color3.fromRGB(60,60,60),
        AutoButtonColor  = false,
    })
    New("UICorner", { CornerRadius = UDim.new(0,6) }, btn)

    local lbl = New("TextLabel", {
        Parent         = btn,
        Size           = UDim2.new(1,-60,1,0),
        Position       = UDim2.new(0,10,0,0),
        BackgroundTransparency = 1,
        Text           = labelText .. ": OFF",
        Font           = Enum.Font.Gotham,
        TextSize       = 16,
        TextColor3     = Color3.fromRGB(240,240,240),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local status = New("TextLabel", {
        Parent         = btn,
        Size           = UDim2.new(0,40,1,0),
        Position       = UDim2.new(1,-50,0,0),
        BackgroundTransparency = 1,
        Text           = "OFF",
        Font           = Enum.Font.Gotham,
        TextSize       = 16,
        TextColor3     = Color3.fromRGB(255,85,85),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    btn.MouseButton1Click:Connect(function()
        Flags[field] = not Flags[field]
        status.Text = Flags[field] and "ON" or "OFF"
        status.TextColor3 = Flags[field] and Color3.fromRGB(85,255,85) or Color3.fromRGB(255,85,85)
    end)
end

-- tambahkan dua toggle
createToggle("Auto Hatch",     "AutoHatch")
createToggle("ESP Prediction", "ESPPrediction")

-- Info kecil
New("TextLabel", {
    Parent            = frame,
    Size              = UDim2.new(1,-20,0,16),
    Position          = UDim2.new(0,10,1,-22),
    BackgroundTransparency = 1,
    Text              = "Drag anywhere • Press M to toggle",
    Font              = Enum.Font.Gotham,
    TextSize          = 12,
    TextColor3        = Color3.fromRGB(160,160,160),
    TextXAlignment    = Enum.TextXAlignment.Left,
}, frame)

-- Toggle UI via key M
UserInputService.InputBegan:Connect(function(inp, gp)
    if not gp and inp.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- AUTO HATCH Logic
task.spawn(function()
    local hatchRem = Replicated:WaitForChild("Remotes"):WaitForChild("HatchEgg")
    while task.wait(1) do
        if Flags.AutoHatch then
            for eggType in pairs(predictionMap) do
                pcall(hatchRem.InvokeServer, hatchRem, eggType)
            end
        end
    end
end)

-- ESP Prediction Logic
task.spawn(function()
    while task.wait(2) do
        if Flags.ESPPrediction then
            for _, mdl in ipairs(Workspace:GetDescendants()) do
                if mdl:IsA("Model") and predictionMap[mdl.Name] and not mdl:FindFirstChild("ESP_GUI") then
                    local part = mdl:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local bb = New("BillboardGui", {
                            Parent      = mdl,
                            Name        = "ESP_GUI",
                            Adornee     = part,
                            Size        = UDim2.new(0,120,0,28),
                            StudsOffset = Vector3.new(0,3,0),
                            AlwaysOnTop = true,
                        })
                        New("UICorner", { CornerRadius = UDim.new(0,4) }, bb)
                        New("TextLabel", {
                            Parent              = bb,
                            Size                = UDim2.new(1,0,1,0),
                            BackgroundTransparency = 0.6,
                            BackgroundColor3    = Color3.fromRGB(0,0,0),
                            TextColor3          = Color3.fromRGB(255,255,0),
                            Font                = Enum.Font.Gotham,
                            TextSize            = 14,
                            Text                = "🎁 ".. table.concat(predictionMap[mdl.Name], ", "),
                            TextWrapped         = true,
                        })
                    end
                end
            end
        else
            for _, gui in ipairs(Workspace:GetDescendants()) do
                if gui.Name == "ESP_GUI" then gui:Destroy() end
            end
        end
    end
end)
