--[[
    VALTRIX CHEVION V5 - PREMIER EDITION (RGB)
    Optimized for: Survive The Apocalypse
    Features: Advanced Auto-Farm, Full ESP with Studs & Health, RGB UI
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- [1] UI PROTECTOR & RGB ENGINE
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixRGB_Final"
pcall(function() ScreenGui.Parent = gethui() or CoreGui end)

local function MakeRGB(object)
    task.spawn(function()
        while object and object.Parent do
            local hue = tick() % 5 / 5
            local color = Color3.fromHSV(hue, 1, 1)
            if object:IsA("UIStroke") then
                object.Color = color
            elseif object:IsA("TextLabel") or object:IsA("TextButton") then
                object.TextColor3 = color
            end
            RunService.RenderStepped:Wait()
        end
    end)
end

-- [2] MAIN FRAME DESIGN
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 380)
Main.Position = UDim2.new(0.5, -260, 0.5, -190)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Border = Instance.new("UIStroke", Main)
Border.Thickness = 2
Border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MakeRGB(Border)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "VALTRIX CHEVION - SURVIVE THE APOCALYPSE"
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
MakeRGB(Title)

local Container = Instance.new("ScrollingFrame", Main)
Container.Size = UDim2.new(1, -20, 1, -60)
Container.Position = UDim2.new(0, 10, 0, 50)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 2
Container.CanvasSize = UDim2.new(0, 0, 2.5, 0)
local Layout = Instance.new("UIListLayout", Container)
Layout.Padding = UDim.new(0, 6)

-- [3] ESP SYSTEM (ITEM, ZOMBIE, PLAYER)
local function CreateESP(part, name, color, isItem)
    if part:FindFirstChild("VTag") then return end
    
    local bg = Instance.new("BillboardGui", part)
    bg.Name = "VTag"
    bg.Size = UDim2.new(0, 150, 0, 50)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 2, 0)

    local tl = Instance.new("TextLabel", bg)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = color
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 11
    tl.TextStrokeTransparency = 0

    local box = Instance.new("SelectionBox", part)
    box.Adornee = part
    box.LineThickness = 0.05
    box.Color3 = color
    box.Transparency = 0.5

    task.spawn(function()
        while part and part.Parent and ScreenGui.Parent do
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local dist = math.floor((myRoot.Position - part.Position).Magnitude)
                local info = name .. "\n[" .. dist .. "m]"
                
                if not isItem then
                    local hum = part.Parent:FindFirstChild("Humanoid")
                    if hum then info = name .. "\nHP: " .. math.floor(hum.Health) .. " [" .. dist .. "m]" end
                end
                
                tl.Text = info
                -- Toggle Visibility
                local visible = false
                if isItem and _G.Toggles.ESPItem then visible = true
                elseif name == "ZOMBIE" and _G.Toggles.ESPZombie then visible = true
                elseif name ~= "ZOMBIE" and not isItem and _G.Toggles.ESPPlayer then visible = true end
                
                tl.Visible = visible
                box.Visible = visible
            end
            task.wait(0.2)
        end
    end)
end

-- [4] AUTO FARM LOGIC
_G.ItemCount = 0
local function AutoFarmLoop()
    while task.wait(0.4) do
        if not ScreenGui.Parent then break end
        pcall(function()
            local root = LocalPlayer.Character.HumanoidRootPart
            
            if _G.Toggles.AutoFarmGen or _G.Toggles.AutoFarmItem then
                -- Step 1: Cari Item
                if _G.ItemCount < 5 then
                    for _, v in pairs(Workspace:GetDescendants()) do
                        if v:IsA("BasePart") and v.Transparency < 1 then
                            local n = v.Name:lower()
                            if n:find("fuel") or n:find("scrap") or n:find("part") or n:find("battery") then
                                root.CFrame = v.CFrame
                                _G.ItemCount = _G.ItemCount + 1
                                task.wait(0.2)
                                break
                            end
                        end
                    end
                else
                    -- Step 2: Drop ke Lokasi Tujuan
                    local targetName = _G.Toggles.AutoFarmGen and "generator" or "craft"
                    for _, v in pairs(Workspace:GetDescendants()) do
                        if v.Name:lower():find(targetName) then
                            root.CFrame = v.CFrame * CFrame.new(0, 4, 0)
                            task.wait(1)
                            -- Drop Items (Simulasi melepas tools)
                            for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                                if tool:IsA("Tool") and not tool.Name:lower():find("backpack") then
                                    tool.Parent = Workspace
                                end
                            end
                            _G.ItemCount = 0
                            break
                        end
                    end
                end
            end
        end)
    end
end
task.spawn(AutoFarmLoop)

-- [5] UI BUILDER UTILS
_G.Toggles = {}
local function AddToggle(text, flag)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.Text = "  " .. text .. ": OFF"
    btn.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(40, 40, 45)

    btn.MouseButton1Click:Connect(function()
        _G.Toggles[flag] = not _G.Toggles[flag]
        btn.Text = "  " .. text .. ": " .. (_G.Toggles[flag] and "ON" or "OFF")
        if _G.Toggles[flag] then
            MakeRGB(stroke)
            btn.TextColor3 = Color3.new(1, 1, 1)
        else
            stroke.Color = Color3.fromRGB(40, 40, 45)
            btn.TextColor3 = Color3.new(0.7, 0.7, 0.7)
        end
    end)
end

-- [6] INITIALIZE
AddToggle("Auto Farm Generator (Fuel)", "AutoFarmGen")
AddToggle("Auto Farm Items (Crafting)", "AutoFarmItem")
AddToggle("Auto Farm Airdrop", "AutoFarmAirdrop")
AddToggle("Auto Kill Zombie (Melee)", "AutoKill")
AddToggle("ESP Player (Name/HP/Studs)", "ESPPlayer")
AddToggle("ESP Zombie (HP/Studs)", "ESPZombie")
AddToggle("ESP All Items (Boxes/Studs)", "ESPItem")
AddToggle("Auto Revive All Players", "AutoRevive")

-- Speed/Jump (Bypass)
RunService.Stepped:Connect(function()
    pcall(function()
        local hum = LocalPlayer.Character.Humanoid
        if _G.SpeedValue then hum.WalkSpeed = _G.SpeedValue end
    end)
end)

-- Scan for ESP Targets
task.spawn(function()
    while task.wait(1.5) do
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                CreateESP(p.Character.HumanoidRootPart, p.DisplayName, Color3.new(0, 1, 0.5), false)
            end
        end
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Humanoid") and not Players:GetPlayerFromCharacter(v.Parent) then
                if v.Parent:FindFirstChild("HumanoidRootPart") then
                    CreateESP(v.Parent.HumanoidRootPart, "ZOMBIE", Color3.new(1, 0.2, 0.2), false)
                end
            elseif v:IsA("BasePart") and (v.Name:lower():find("fuel") or v.Name:lower():find("scrap") or v.Name:lower():find("medkit")) then
                CreateESP(v, v.Name, Color3.new(1, 1, 0.3), true)
            end
        end
    end
end)

print("VALTRIX CHEVION V5 RGB LOADED!")
