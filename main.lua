-- main.lua – Grow A Garden Hub (All-in-One)

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- SERVICES
local Players          = game:GetService("Players")
local Replicated       = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")

local player = Players.LocalPlayer

-- KEY AUTHENTICATION (optional)
-- Uncomment and replace MY_SECRET_KEY to enable
--[[
local function promptKey()
    local key = ""
    pcall(function()
        key = game:GetService("StarterGui"):SetCore("PromptInput", {
            Title = "Enter GMON Key";
            Text = "";
        })
    end)
    return key
end

local enteredKey = promptKey()
if enteredKey ~= "MY_SECRET_KEY" then
    error("Unauthorized key.")
end
--]]

-- GLOBAL FLAGS
local Flags = {
    AutoHatch       = false,
    ESPPrediction   = false,
}

-- EGG → POSSIBLE PETS MAP
local predictionMap = {
    BasicEgg = { "Bunny", "Bear", "Pig" },
    RareEgg  = { "Raccoon", "Red Fox", "Dragon Fly" },
    EpicEgg  = { "Disco Bee", "Phantom" },
}

-- UI HELPER
local function New(cls, props, parent)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do
        inst[k] = v
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

-- Make a GUI draggable
local function makeDraggable(frame)
    local dragging, startPos, startInput
    frame.Active = true
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = frame.Position
            startInput = inp.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - startInput
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- BUILD MAIN UI
local screenGui = New("ScreenGui", {
    Name = "GrowAGardenHub",
    Parent = player:WaitForChild("PlayerGui"),
})

local frame = New("Frame", {
    Size = UDim2.new(0, 300, 0, 160),
    Position = UDim2.new(0, 50, 0, 100),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
}, screenGui)
New("UICorner", { CornerRadius = UDim.new(0, 8) }, frame)
makeDraggable(frame)

-- Title
New("TextLabel", {
    Text = "Grow A Garden Hub",
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.SourceSansSemibold,
    TextSize = 18,
}, frame)

-- Auto Hatch Toggle
local autoBtn = New("TextButton", {
    Text = "Auto Hatch: OFF",
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 40),
    BackgroundColor3 = Color3.fromRGB(60, 60, 60),
    TextColor3 = Color3.new(1, 1, 1),
    AutoButtonColor = false,
}, frame)
New("UICorner", { CornerRadius = UDim.new(0, 6) }, autoBtn)
autoBtn.MouseButton1Click:Connect(function()
    Flags.AutoHatch = not Flags.AutoHatch
    autoBtn.Text = "Auto Hatch: " .. (Flags.AutoHatch and "ON" or "OFF")
end)

-- ESP Prediction Toggle
local espBtn = New("TextButton", {
    Text = "ESP Predict: OFF",
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 80),
    BackgroundColor3 = Color3.fromRGB(60, 60, 60),
    TextColor3 = Color3.new(1, 1, 1),
    AutoButtonColor = false,
}, frame)
New("UICorner", { CornerRadius = UDim.new(0, 6) }, espBtn)
espBtn.MouseButton1Click:Connect(function()
    Flags.ESPPrediction = not Flags.ESPPrediction
    espBtn.Text = "ESP Predict: " .. (Flags.ESPPrediction and "ON" or "OFF")
end)

-- Close Hint
New("TextLabel", {
    Text = "Drag anywhere to move. Press M to toggle UI.",
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 10, 0, 130),
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(180, 180, 180),
    Font = Enum.Font.SourceSans,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, frame)

-- Toggle UI with M key
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- AUTO HATCH LOGIC
task.spawn(function()
    local hatchRem = Replicated:WaitForChild("Remotes"):WaitForChild("HatchEgg")
    while task.wait(1) do
        if Flags.AutoHatch then
            for eggType in pairs(predictionMap) do
                pcall(function()
                    hatchRem:InvokeServer(eggType)
                end)
            end
        end
    end
end)

-- ESP PREDICTION LOGIC
local function createBillboard(egg)
    if egg:FindFirstChild("PredictGui") then return end
    local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    local bb = New("BillboardGui", {
        Name = "PredictGui",
        Adornee = part,
        Size = UDim2.new(0, 120, 0, 40),
        StudsOffset = Vector3.new(0, 3, 0),
        AlwaysOnTop = true,
        Parent = egg,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 4) }, bb)

    local lbl = New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 255, 0),
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        TextWrapped = true,
        Parent = bb,
    })
    local poss = predictionMap[egg.Name] or { "Unknown" }
    lbl.Text = "Possible: " .. table.concat(poss, ", ")
end

task.spawn(function()
    while task.wait(2) do
        if Flags.ESPPrediction then
            for _, model in ipairs(Workspace:GetDescendants()) do
                if model:IsA("Model") and predictionMap[model.Name] then
                    createBillboard(model)
                end
            end
        else
            -- Remove all prediction GUIs
            for _, gui in ipairs(Workspace:GetDescendants()) do
                if gui.Name == "PredictGui" then
                    gui:Destroy()
                end
            end
        end
    end
end)
