--[[
    VALTRIX CHEVION V4 - ULTIMATE FINAL VERSION
    Game: Survive The Apocalypse (Roblox)
    Semua Executor Supported (Delta, Codex, Arceus, Fluxus, etc.)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- [1] UI SETUP & PROTECTION
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixChevionFinal"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = gethui() or CoreGui end)

-- Global States
_G.Toggles = {
    AutoFarmGen = false, AutoFarmItem = false, AutoFarmAirdrop = false, AutoKill = false,
    ESPPlayer = false, ESPZombie = false, ESPItem = false, AutoRevive = false
}
_G.Values = { Speed = 16, Jump = 50, BackpackFull = 5, CurrentCount = 0 }

-- Cleanup
for _, v in pairs(CoreGui:GetChildren()) do if v.Name == ScreenGui.Name and v ~= ScreenGui then v:Destroy() end end

-- [2] UI DESIGN (Compact & Clean)
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 500, 0, 350)
Main.Position = UDim2.new(0.5, -250, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "VALTRIX CHEVION V4 - FINAL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Font = Enum.Font.GothamBold

local Container = Instance.new("ScrollingFrame", Main)
Container.Size = UDim2.new(1, -20, 1, -50)
Container.Position = UDim2.new(0, 10, 0, 45)
Container.BackgroundTransparency = 1
Container.CanvasSize = UDim2.new(0, 0, 2, 0)
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 5)

-- [3] ESP HELPER (Health + Studs + Box)
local function AddESP(object, color, isPlayer, isZombie)
    if not object:FindFirstChild("ValtrixESP") then
        local bg = Instance.new("BillboardGui", object)
        bg.Name = "ValtrixESP"
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.AlwaysOnTop = true
        bg.ExtentsOffset = Vector3.new(0, 3, 0)

        local txt = Instance.new("TextLabel", bg)
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = color
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 12
        txt.TextStrokeTransparency = 0

        -- Box 3D
        local box = Instance.new("SelectionBox", object)
        box.Adornee = object
        box.Color3 = color
        box.LineThickness = 0.05
        box.Transparency = 0.5

        task.spawn(function()
            while object and object.Parent and ScreenGui.Parent do
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((char.HumanoidRootPart.Position - object.Position).Magnitude)
                    local healthStr = ""
                    
                    if isPlayer or isZombie then
                        local hum = object.Parent:FindFirstChild("Humanoid")
                        if hum then
                            healthStr = " | HP: " .. math.floor(hum.Health)
                        end
                    end
                    
                    txt.Text = object.Parent.Name .. "\n[" .. dist .. " Studs]" .. healthStr
                    
                    -- Visibility logic
                    local toggle = (isPlayer and _G.Toggles.ESPPlayer) or (isZombie and _G.Toggles.ESPZombie) or _G.Toggles.ESPItem
                    txt.Visible = toggle
                    box.Visible = toggle
                end
                task.wait(0.1)
            end
        end)
    end
end

-- [4] FUNCTIONAL TOOLS
local function MakeToggle(name, flag)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)

    btn.MouseButton1Click:Connect(function()
        _G.Toggles[flag] = not _G.Toggles[flag]
        btn.Text = name .. ": " .. (_G.Toggles[flag] and "ON" or "OFF")
        btn.BackgroundColor3 = _G.Toggles[flag] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(40, 40, 40)
    end)
end

local function MakeSlider(name, flag, min, max)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.Text = name .. " (Click Set to Apply)"
    lbl.TextColor3 = Color3.new(1, 1, 1)
    
    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(0, 100, 0, 25)
    input.Position = UDim2.new(0, 10, 0, 20)
    input.Text = tostring(_G.Values[flag])
    
    local set = Instance.new("TextButton", frame)
    set.Size = UDim2.new(0, 60, 0, 25)
    set.Position = UDim2.new(0, 120, 0, 20)
    set.Text = "SET"
    set.MouseButton1Click:Connect(function() _G.Values[flag] = tonumber(input.Text) or min end)

    local res = Instance.new("TextButton", frame)
    res.Size = UDim2.new(0, 60, 0, 25)
    res.Position = UDim2.new(0, 190, 0, 20)
    res.Text = "RESET"
    res.MouseButton1Click:Connect(function() 
        _G.Values[flag] = (flag == "Speed" and 16 or 50)
        input.Text = tostring(_G.Values[flag])
    end)
end

-- [5] IN-GAME LOGIC (THE "ENGINE")
RunService.RenderStepped:Connect(function()
    pcall(function()
        local hum = LocalPlayer.Character.Humanoid
        hum.WalkSpeed = _G.Values.Speed
        hum.JumpPower = _G.Values.Jump
    end)
end)

-- Scan for ESP (Players & Zombies)
task.spawn(function()
    while task.wait(2) do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                AddESP(p.Character.HumanoidRootPart, Color3.new(0, 1, 0), true, false)
            end
        end
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Humanoid") and v.Parent.Name:lower():find("zombie") and v.Parent:FindFirstChild("HumanoidRootPart") then
                AddESP(v.Parent.HumanoidRootPart, Color3.new(1, 0, 0), false, true)
            end
            if _G.Toggles.ESPItem and v:IsA("BasePart") then
                local n = v.Name:lower()
                if n:find("fuel") or n:find("scrap") or n:find("medkit") or n:find("bandage") then
                    AddESP(v, Color3.new(1, 1, 0), false, false)
                end
            end
        end
    end
end)

-- Auto Farm Core
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local char = LocalPlayer.Character
            local root = char.HumanoidRootPart
            
            if _G.Toggles.AutoFarmGen then
                -- Logic: Ambil Backpack -> Cari Fuel -> Penuh -> Drop di Gen
                local backpack = char:FindFirstChild("Backpack") or LocalPlayer.Backpack:FindFirstChild("Backpack")
                if backpack then char.Humanoid:EquipTool(backpack) end
                
                if _G.Values.CurrentCount < _G.Values.BackpackFull then
                    for _, v in pairs(Workspace:GetDescendants()) do
                        if v.Name:lower():find("fuel") and v:IsA("BasePart") then
                            root.CFrame = v.CFrame
                            _G.Values.CurrentCount = _G.Values.CurrentCount + 1
                            task.wait(0.3)
                            break
                        end
                    end
                else
                    -- Ke Generator
                    for _, v in pairs(Workspace:GetDescendants()) do
                        if v.Name:lower():find("generator") then
                            root.CFrame = v.CFrame * CFrame.new(0, 5, 0)
                            _G.Values.CurrentCount = 0
                            task.wait(1)
                            break
                        end
                    end
                end
            end
        end)
    end
end)

-- UI BUILD
MakeToggle("Auto Farm Generator", "AutoFarmGen")
MakeToggle("Auto Farm Items (Craft)", "AutoFarmItem")
MakeToggle("Auto Farm Airdrop", "AutoFarmAirdrop")
MakeToggle("Auto Kill Melee Zombie", "AutoKill")
MakeToggle("ESP Player (+Health/Studs)", "ESPPlayer")
MakeToggle("ESP Zombie (+Health/Studs)", "ESPZombie")
MakeToggle("ESP Items (Fuel/Scrap)", "ESPItem")
MakeToggle("Auto Revive Players", "AutoRevive")
MakeSlider("WalkSpeed", "Speed", 16, 500)
MakeSlider("JumpPower", "Jump", 50, 500)

local Unload = Instance.new("TextButton", Container)
Unload.Size = UDim2.new(1, 0, 0, 35)
Unload.Text = "UNLOAD SCRIPT"
Unload.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
Unload.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

print("VALTRIX CHEVION V4 LOADED!")
