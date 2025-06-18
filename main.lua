-- main.lua – Grow A Garden Hub (FIXED UI)

-- WAIT FOR GAME TO LOAD
if not game:IsLoaded() then game.Loaded:Wait() end

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer

-- FLAGS
local Flags = {
    AutoHatch = false,
    ESP = false
}

-- PREDICTION MAP
local predictionMap = {
    BasicEgg = { "Bunny", "Bear", "Pig" },
    RareEgg = { "Raccoon", "Red Fox", "Dragon Fly" },
    EpicEgg = { "Disco Bee", "Phantom" },
}

-- UI CREATION
local gui = Instance.new("ScreenGui", lp:WaitForChild("PlayerGui"))
gui.Name = "GrowHub"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 180)
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Name = "MainUI"
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 8)

-- TITLE
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "🌱 Grow A Garden Hub"
title.Font = Enum.Font.SourceSansSemibold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)

-- BUTTON CONTAINER
local container = Instance.new("Frame", frame)
container.Size = UDim2.new(1, -20, 1, -50)
container.Position = UDim2.new(0, 10, 0, 40)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- CREATE TOGGLE BUTTON
local function createToggle(text, flagName)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.AutoButtonColor = false

    local uic = Instance.new("UICorner", btn)
    uic.CornerRadius = UDim.new(0, 6)

    local function update()
        btn.Text = text .. ": " .. (Flags[flagName] and "ON" or "OFF")
    end

    btn.MouseButton1Click:Connect(function()
        Flags[flagName] = not Flags[flagName]
        update()
    end)

    update()
    return btn
end

createToggle("Auto Hatch", "AutoHatch")
createToggle("ESP Prediction", "ESP")

-- KEY TOGGLE UI (M)
UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- AUTO HATCH LOOP
task.spawn(function()
    local remote = RS:WaitForChild("Remotes"):WaitForChild("HatchEgg")
    while true do
        task.wait(1)
        if Flags.AutoHatch then
            for egg in pairs(predictionMap) do
                pcall(function()
                    remote:InvokeServer(egg)
                end)
            end
        end
    end
end)

-- ESP PREDICTION LOOP
task.spawn(function()
    while true do
        task.wait(2)
        if Flags.ESP then
            for _, model in ipairs(Workspace:GetDescendants()) do
                if model:IsA("Model") and predictionMap[model.Name] and not model:FindFirstChild("ESP") then
                    local part = model:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local bb = Instance.new("BillboardGui", model)
                        bb.Name = "ESP"
                        bb.Size = UDim2.new(0, 120, 0, 30)
                        bb.StudsOffset = Vector3.new(0, 3, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = part

                        local label = Instance.new("TextLabel", bb)
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.TextColor3 = Color3.new(1, 1, 0)
                        label.Font = Enum.Font.SourceSans
                        label.TextSize = 14
                        label.TextWrapped = true
                        label.Text = "🎁 " .. table.concat(predictionMap[model.Name], ", ")
                    end
                end
            end
        else
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BillboardGui") and v.Name == "ESP" then
                    v:Destroy()
                end
            end
        end
    end
end)
