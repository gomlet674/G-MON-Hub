--[[
    VALTRIX CHEVION V6 - GOD EDITION (STABLE)
    Game: Survive The Apocalypse
    - Sinkronisasi RGB (Mati saat Toggle OFF)
    - Cooldown Collect System (Anti-Error)
    - Toggle Key: F3 (PC) & Button (Mobile)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- [1] UI PROTECTOR
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixFinal_V6"
pcall(function() ScreenGui.Parent = gethui() or CoreGui end)

-- Global States
_G.Toggles = {
    AutoFarmGen = false, AutoFarmItem = false, 
    ESPItem = false, ESPZombie = false, ESPPlayer = false,
    RGBMode = true
}
_G.Values = { Speed = 16, Jump = 50, ItemCooldown = 0.5 }

-- [2] RGB SYSTEM (Fixed: Mati saat Toggle OFF)
local function ApplyRGB(object, flag)
    task.spawn(function()
        while object and object.Parent do
            if _G.Toggles[flag] and _G.Toggles.RGBMode then
                local hue = tick() % 5 / 5
                local color = Color3.fromHSV(hue, 0.8, 1)
                if object:IsA("UIStroke") then object.Color = color
                elseif object:IsA("TextLabel") or object:IsA("TextButton") then object.TextColor3 = color end
            else
                -- Warna Default saat OFF
                if object:IsA("UIStroke") then object.Color = Color3.fromRGB(45, 45, 50)
                elseif object:IsA("TextLabel") then object.TextColor3 = Color3.fromRGB(200, 200, 200)
                elseif object:IsA("TextButton") then object.TextColor3 = Color3.fromRGB(150, 150, 150) end
            end
            RunService.RenderStepped:Wait()
        end
    end)
end

-- [3] MAIN GUI CONSTRUCTION (Persis Gambar)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 500, 0, 320)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ApplyRGB(MainStroke, "RGBMode") -- Main Frame selalu RGB jika Master RGB On

-- Header Area
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Text = "Valtrix Chevion"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local UserInfo = Instance.new("TextLabel", Header)
UserInfo.Position = UDim2.new(1, -150, 0, 0)
UserInfo.Size = UDim2.new(0, 100, 1, 0)
UserInfo.Text = LocalPlayer.Name
UserInfo.Font = Enum.Font.GothamSemibold
UserInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
UserInfo.TextXAlignment = Enum.TextXAlignment.Right

-- Tab System
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Position = UDim2.new(0, 0, 0, 50)
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 30, 40)

local TabLayout = Instance.new("UIListLayout", TabContainer)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

local Pages = {}
local function CreateTab(name, order)
    local btn = Instance.new("TextButton", TabContainer)
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.LayoutOrder = order

    local page = Instance.new("ScrollingFrame", MainFrame)
    page.Position = UDim2.new(0, 10, 0, 95)
    page.Size = UDim2.new(1, -20, 1, -105)
    page.BackgroundTransparency = 1
    page.Visible = (order == 1)
    page.ScrollBarThickness = 2
    
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        page.Visible = true
    end)
    Pages[name] = page
    return page
end

local PageMain = CreateTab("Main", 1)
local PageVisual = CreateTab("Visual", 2)
local PageSpeed = CreateTab("Speed", 3)
local PageMisc = CreateTab("Misc", 4)

-- [4] UI COMPONENTS
local function AddToggle(parent, text, flag)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    btn.Text = "  " .. text .. ": OFF"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1.5
    ApplyRGB(stroke, flag)

    btn.MouseButton1Click:Connect(function()
        _G.Toggles[flag] = not _G.Toggles[flag]
        btn.Text = "  " .. text .. ": " .. (_G.Toggles[flag] and "ON" or "OFF")
    end)
end

-- [5] AUTO FARM LOGIC (Persis Gambar: Bensin/Fuel & Scraps)
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if _G.Toggles.AutoFarmGen or _G.Toggles.AutoFarmItem then
                local char = LocalPlayer.Character
                local root = char.HumanoidRootPart
                
                -- Cari Item (Fuel atau Scraps di gambar)
                for _, item in pairs(Workspace:GetDescendants()) do
                    if item:IsA("BasePart") and item.Transparency < 1 then
                        local n = item.Name:lower()
                        if n:find("fuel") or n:find("scrap") or n:find("part") then
                            -- Teleport & Collect
                            root.CFrame = item.CFrame
                            task.wait(_G.Values.ItemCooldown) -- Cooldown agar tidak error
                            
                            -- Cek jika sudah penuh (simulasi) atau langsung antar
                            local gen = Workspace:FindFirstChild("Generator", true) or Workspace:FindFirstChild("Crafting", true)
                            if gen then
                                root.CFrame = gen.CFrame * CFrame.new(0, 5, 0)
                                task.wait(0.3)
                            end
                            break
                        end
                    end
                end
            end
        end)
    end
end)

-- [6] TOGGLE UI (F3 & Button)
local function ToggleUI()
    MainFrame.Visible = not MainFrame.Visible
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.F3 then
        ToggleUI()
    end
end)

-- Mobile Button
local MobileBtn = Instance.new("TextButton", ScreenGui)
MobileBtn.Size = UDim2.new(0, 50, 0, 50)
MobileBtn.Position = UDim2.new(0, 10, 0.5, 0)
MobileBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
MobileBtn.Text = "V"
MobileBtn.Font = Enum.Font.GothamBold
MobileBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", MobileBtn).CornerRadius = UDim.new(1, 0)
local MobStroke = Instance.new("UIStroke", MobileBtn)
ApplyRGB(MobStroke, "RGBMode")

MobileBtn.MouseButton1Click:Connect(ToggleUI)

-- [7] POPULATE MENU
AddToggle(PageMain, "Auto Farm Generator", "AutoFarmGen")
AddToggle(PageMain, "Auto Farm Item", "AutoFarmItem")

AddToggle(PageVisual, "ESP Item", "ESPItem")
AddToggle(PageVisual, "ESP Zombie", "ESPZombie")
AddToggle(PageVisual, "ESP Player", "ESPPlayer")

AddToggle(PageMisc, "Master RGB Effect", "RGBMode")

-- Speed System
RunService.Heartbeat:Connect(function()
    pcall(function()
        LocalPlayer.Character.Humanoid.WalkSpeed = _G.Values.Speed
    end)
end)

print("Valtrix Chevion V6 Loaded - Press F3 to Toggle")
