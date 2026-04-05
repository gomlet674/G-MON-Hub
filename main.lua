--[[
    VALTRIX CHEVION V22 - ALL-IN-ONE HUB
    - FEATURE: 3 Separate ESPs (Player, Zombie, Item)
    - FEATURE: Auto Farm synced with Item ESP Filter
    - EXCLUDED: Torso, Cube, Tin Can, Thin Can, Baseplate
    - INCLUDED: Fuel, Screw, Scrap, Battery, MRE, Ammo & Draggable
    - FULL UI: Spectate, Tween, Kill Aura, RGB Engine
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
_G.Toggles = {
    Radius = 150,
    Cooldown = 0.5
}
_G.SpecIndex = 1
local TargetPlr = nil

-- [1] UI PROTECTOR & RGB ENGINE
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Valtrix_V22_AllInOne"
pcall(function() ScreenGui.Parent = gethui() or CoreGui end)

local function SyncRGB(object, flag)
    task.spawn(function()
        while object and object.Parent do
            if _G.Toggles[flag] then
                local color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                if object:IsA("UIStroke") then object.Color = color
                elseif object:IsA("TextLabel") or object:IsA("TextButton") then object.TextColor3 = color end
            else
                local offColor = Color3.fromRGB(180, 180, 180)
                if object:IsA("UIStroke") then object.Color = Color3.fromRGB(45, 45, 50)
                elseif object:IsA("TextLabel") or object:IsA("TextButton") then object.TextColor3 = offColor end
            end
            RunService.RenderStepped:Wait()
        end
    end)
end

-- [2] MAIN FRAME
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 600, 0, 550)
Main.Position = UDim2.new(0.5, -300, 0.5, -275)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Border = Instance.new("UIStroke", Main)
Border.Thickness = 3
_G.Toggles["MainUI"] = true
SyncRGB(Border, "MainUI")

local function CreateWinBtn(txt, pos, color, func)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0, 25, 0, 25)
    b.Position = pos
    b.Text = txt
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(func)
    return b
end

CreateWinBtn("X", UDim2.new(1, -35, 0, 10), Color3.fromRGB(180, 50, 50), function() ScreenGui:Destroy() end)
CreateWinBtn("—", UDim2.new(1, -65, 0, 10), Color3.fromRGB(60, 60, 70), function() Main.Visible = false end)

-- Profile UI
local Profile = Instance.new("Frame", Main)
Profile.Size = UDim2.new(1, -20, 0, 60)
Profile.Position = UDim2.new(0, 10, 0, 45)
Profile.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", Profile)

local Av = Instance.new("ImageLabel", Profile)
Av.Size = UDim2.new(0, 50, 0, 50)
Av.Position = UDim2.new(0, 5, 0, 5)
Av.BackgroundTransparency = 1
Instance.new("UICorner", Av).CornerRadius = UDim.new(1, 0)
Av.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

local Welcome = Instance.new("TextLabel", Profile)
Welcome.Size = UDim2.new(1, -70, 1, 0)
Welcome.Position = UDim2.new(0, 65, 0, 0)
Welcome.Text = "LOGGED AS: " .. LocalPlayer.DisplayName:upper()
Welcome.TextColor3 = Color3.new(1, 1, 1)
Welcome.Font = Enum.Font.GothamBold
Welcome.TextSize = 14
Welcome.TextXAlignment = Enum.TextXAlignment.Left
Welcome.BackgroundTransparency = 1

-- [3] SPECTATE PANEL (INDEPENDENT)
local SpecPanel = Instance.new("Frame", Main)
SpecPanel.Size = UDim2.new(0.38, -10, 0, 410)
SpecPanel.Position = UDim2.new(0.62, 0, 0, 115)
SpecPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Instance.new("UICorner", SpecPanel)

local Viewport = Instance.new("ViewportFrame", SpecPanel)
Viewport.Size = UDim2.new(1, 0, 0, 180)
Viewport.BackgroundTransparency = 1

local SpecName = Instance.new("TextLabel", SpecPanel)
SpecName.Size = UDim2.new(1, 0, 0, 25)
SpecName.Position = UDim2.new(0, 0, 0, 185)
SpecName.Text = "Target: None"
SpecName.TextColor3 = Color3.new(0, 1, 1)
SpecName.Font = Enum.Font.GothamBold
SpecName.BackgroundTransparency = 1

local function UpdateViewport(plr)
    Viewport:ClearAllChildren()
    if not plr or not plr.Character then return end
    plr.Character.Archivable = true
    local clone = plr.Character:Clone()
    clone.Parent = Viewport
    local vCam = Instance.new("Camera")
    vCam.CFrame = CFrame.new(clone.HumanoidRootPart.Position + clone.HumanoidRootPart.CFrame.LookVector * 6 + Vector3.new(0,2,0), clone.HumanoidRootPart.Position)
    Viewport.CurrentCamera = vCam
    vCam.Parent = Viewport
    SpecName.Text = plr.DisplayName
end

local function CreateSpecBtn(txt, pos, color)
    local b = Instance.new("TextButton", SpecPanel)
    b.Size = UDim2.new(1, -20, 0, 32)
    b.Position = pos
    b.Text = txt
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    Instance.new("UICorner", b)
    return b
end

local NextBtn = CreateSpecBtn("NEXT PLAYER", UDim2.new(0, 10, 0, 220), Color3.fromRGB(40, 40, 50))
local RefreshBtn = CreateSpecBtn("REFRESH LIST", UDim2.new(0, 10, 0, 257), Color3.fromRGB(40, 40, 50))
local SpecToggleBtn = CreateSpecBtn("SPECTATE: OFF", UDim2.new(0, 10, 0, 294), Color3.fromRGB(60, 40, 40))
local TweenPlrBtn = CreateSpecBtn("TWEEN TO PLAYER", UDim2.new(0, 10, 0, 331), Color3.fromRGB(40, 60, 40))

NextBtn.MouseButton1Click:Connect(function()
    local plrs = Players:GetPlayers()
    _G.SpecIndex = _G.SpecIndex + 1
    if _G.SpecIndex > #plrs then _G.SpecIndex = 1 end
    TargetPlr = plrs[_G.SpecIndex]
    if TargetPlr == LocalPlayer then _G.SpecIndex = _G.SpecIndex + 1 TargetPlr = plrs[_G.SpecIndex] end
    UpdateViewport(TargetPlr)
end)

RefreshBtn.MouseButton1Click:Connect(function()
    _G.SpecIndex = 1
    TargetPlr = nil
    SpecName.Text = "Refreshing..."
    task.wait(0.5)
    UpdateViewport(Players:GetPlayers()[1])
end)

SpecToggleBtn.MouseButton1Click:Connect(function()
    _G.Toggles.Spectate = not _G.Toggles.Spectate
    SpecToggleBtn.Text = "SPECTATE: " .. (_G.Toggles.Spectate and "ON" or "OFF")
    SpecToggleBtn.BackgroundColor3 = _G.Toggles.Spectate and Color3.fromRGB(40, 60, 40) or Color3.fromRGB(60, 40, 40)
    if _G.Toggles.Spectate and TargetPlr and TargetPlr.Character then Camera.CameraSubject = TargetPlr.Character.Humanoid else Camera.CameraSubject = LocalPlayer.Character.Humanoid end
end)

-- [4] UI TOGGLES & INPUTS
local Container = Instance.new("ScrollingFrame", Main)
Container.Size = UDim2.new(0.6, 0, 1, -125)
Container.Position = UDim2.new(0, 10, 0, 115)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 2
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 6)

local function AddToggle(text, flag)
    local b = Instance.new("TextButton", Container)
    b.Size = UDim2.new(1, -10, 0, 40)
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    b.Text = "  " .. text .. ": OFF"
    b.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", b)
    local s = Instance.new("UIStroke", b)
    s.Thickness = 1.5
    s.Color = Color3.fromRGB(45, 45, 50)
    SyncRGB(s, flag)
    SyncRGB(b, flag)
    b.MouseButton1Click:Connect(function()
        _G.Toggles[flag] = not _G.Toggles[flag]
        b.Text = "  " .. text .. ": " .. (_G.Toggles[flag] and "ON" or "OFF")
    end)
end

local function AddInput(text, flag, min, max, default)
    local Frame = Instance.new("Frame", Container)
    Frame.Size = UDim2.new(1, -10, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Instance.new("UICorner", Frame)

    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(0.6, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.Text = text
    Lbl.TextColor3 = Color3.new(1,1,1)
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 12
    Lbl.BackgroundTransparency = 1
    Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local Box = Instance.new("TextBox", Frame)
    Box.Size = UDim2.new(0.3, 0, 0.7, 0)
    Box.Position = UDim2.new(0.65, 0, 0.15, 0)
    Box.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Box.TextColor3 = Color3.new(0, 1, 0.5)
    Box.Font = Enum.Font.GothamBold
    Box.Text = tostring(default)
    Instance.new("UICorner", Box)

    Box.FocusLost:Connect(function()
        local val = tonumber(Box.Text)
        if val then val = math.clamp(val, min, max) _G.Toggles[flag] = val Box.Text = tostring(val) end
    end)
end

AddToggle("Auto Fuel Generator (Fuel)", "AutoFarmGen")
AddToggle("Auto Farm All Loot", "AutoFarmItem")
AddToggle("Kill Aura (Fast Hit)", "KillAura")
AddToggle("ESP Players", "ESPPlayer")
AddToggle("ESP Zombies", "ESPZombie")
AddToggle("ESP Loot Items", "ESPItem")
AddInput("ESP Radius Limit (m)", "Radius", 5, 5000, 150)
AddInput("Scan Cooldown (s)", "Cooldown", 0.1, 5, 0.5)

-- [5] SMART LOOT FILTER
local function CheckLootValidity(obj)
    -- Cegah anggota tubuh zombie terdeteksi sebagai item
    if obj.Parent and obj.Parent:FindFirstChild("Humanoid") then return false, nil, nil end

    local n = obj.Name:lower()
    -- BLACKLIST
    if n:find("torso") or n:find("cube") or n:find("tin can") or n:find("thin can") or n == "handle" or n == "baseplate" then 
        return false, nil, nil 
    end

    -- ESSENTIALS (Kuning Emas)
    local essentials = {"refined fuel", "gasoline", "screw", "bloxy cola", "battery", "chips", "mre", "ammo", "spatula", "soft scraps"}
    for _, key in ipairs(essentials) do
        if n:find(key) then return true, "ESSENTIAL", Color3.new(1, 0.8, 0) end
    end

    -- DRAGGABLES (Hijau Cyan)
    if obj:FindFirstChildOfClass("ProximityPrompt") or obj:FindFirstChildOfClass("ClickDetector") or obj:IsA("Tool") then
        return true, "LOOT", Color3.new(0, 1, 0.7)
    end

    return false, nil, nil
end

-- [6] 3-WAY ESP ENGINE
local function ApplyESP(obj, name, color, category)
    if obj:FindFirstChild("ValtrixESP") then return end

    local bGui = Instance.new("BillboardGui", obj)
    bGui.Name = "ValtrixESP"
    bGui.Size = UDim2.new(0, 120, 0, 40)
    bGui.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel", bGui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11

    local box = Instance.new("SelectionBox", obj)
    box.Name = "ValtrixBox"
    box.Adornee = obj
    box.Color3 = color
    box.LineThickness = 0.05
    box.Transparency = 0.5

    task.spawn(function()
        while obj and obj.Parent do
            local enabled = false
            -- Pengecekan kategori ESP
            if category == "Player" and _G.Toggles.ESPPlayer then enabled = true
            elseif category == "Zombie" and _G.Toggles.ESPZombie then enabled = true
            elseif category == "Item" and _G.Toggles.ESPItem then enabled = true end

            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and enabled then
                local dist = (hrp.Position - obj.Position).Magnitude
                if dist <= _G.Toggles.Radius then
                    label.Visible = true
                    box.Visible = true
                    label.Text = name:upper() .. "\n[" .. math.floor(dist) .. "m]"
                else
                    label.Visible = false
                    box.Visible = false
                end
            else
                label.Visible = false
                box.Visible = false
            end
            task.wait(_G.Toggles.Cooldown)
        end
    end)
end

task.spawn(function()
    while true do
        pcall(function()
            -- 1. Scan Players
            for _, p in pairs(Players:GetPlayers()) do
                if not (p == LocalPlayer) and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then ApplyESP(hrp, p.DisplayName, Color3.new(0, 1, 1), "Player") end
                end
            end
            
            -- 2. Scan Zombies & Items
            for _, v in pairs(Workspace:GetDescendants()) do
                -- Cek apakah dia Zombie
                if v:IsA("Humanoid") and not Players:GetPlayerFromCharacter(v.Parent) then
                    local zhrp = v.Parent:FindFirstChild("HumanoidRootPart")
                    if zhrp then ApplyESP(zhrp, "ZOMBIE", Color3.new(1, 0, 0), "Zombie") end
                else
                    -- Jika bukan Zombie, cek apakah dia Item Valid
                    local isValid, cat, color = CheckLootValidity(v)
                    if isValid then
                        local root = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                        if root then ApplyESP(root, v.Name, color, "Item") end
                    end
                end
            end
        end)
        task.wait(_G.Toggles.Cooldown * 3)
    end
end)

-- [7] TWEEN ENGINE
local function SmoothTween(targetCF, speed)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local dist = (char.HumanoidRootPart.Position - targetCF.Position).Magnitude
    local tInfo = TweenInfo.new(dist/(speed or 50), Enum.EasingStyle.Linear)
    local tween = TweenService:Create(char.HumanoidRootPart, tInfo, {CFrame = targetCF})
    
    local nc = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)
    tween:Play()
    tween.Completed:Wait()
    nc:Disconnect()
end

TweenPlrBtn.MouseButton1Click:Connect(function()
    if TargetPlr and TargetPlr.Character then SmoothTween(TargetPlr.Character.HumanoidRootPart.CFrame, 80) end
end)

-- [8] AUTO FARM & KILL AURA LOOP
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char:FindFirstChild("Humanoid")
            
            -- KILL AURA
            if _G.Toggles.KillAura then
                local weapon = nil
                local wList = {"Fire Axe", "Spear", "Spiked Bat", "Crowbar", "Bat", "Knife", "Uzi"}
                for _, n in ipairs(wList) do 
                    weapon = LocalPlayer.Backpack:FindFirstChild(n) or char:FindFirstChild(n)
                    if weapon then break end
                end
                
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("Humanoid") and v.Health > 0 and not Players:GetPlayerFromCharacter(v.Parent) then
                        local zhrp = v.Parent:FindFirstChild("HumanoidRootPart")
                        if zhrp and (zhrp.Position - char.HumanoidRootPart.Position).Magnitude < 100 then
                            hum:EquipTool(weapon)
                            char.HumanoidRootPart.CFrame = zhrp.CFrame * CFrame.new(0, 0, 3)
                            if weapon then weapon:Activate() end
                            break
                        end
                    end
                end
            end

            -- SYNCED AUTO FARM (Hanya Farm Item yang Valid di Filter)
            if _G.Toggles.AutoFarmItem or _G.Toggles.AutoFarmGen then
                local bag = char:FindFirstChild("Bag") or char:FindFirstChild("Backpack") or LocalPlayer.Backpack:FindFirstChild("Bag") or LocalPlayer.Backpack:FindFirstChild("Backpack")
                if bag then hum:EquipTool(bag) end
                
                local target = nil
                for _, v in pairs(Workspace:GetDescendants()) do
                    local isValid, category, _ = CheckLootValidity(v)
                    if isValid then
                        local n = v.Name:lower()
                        if _G.Toggles.AutoFarmGen and (n:find("revolver") or n:find("Chips") or n:find("battery") or n:find("Gasoline")) then
                            target = v break
                        elseif _G.Toggles.AutoFarmItem then
                            target = v break
                        end
                    end
                end

                if target then
                    local handle = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart")
                    if handle then
                        SmoothTween(handle.CFrame, 60)
                        task.wait(0.2)
                        if bag then bag:Activate() end
                    end
                end
            end
        end)
    end
end)

-- [9] TOGGLE "V" BUTTON
local VBtn = Instance.new("TextButton", ScreenGui)
VBtn.Size = UDim2.new(0, 50, 0, 50)
VBtn.Position = UDim2.new(0, 20, 0.5, 0)
VBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
VBtn.Text = "V"
VBtn.Font = Enum.Font.GothamBold
VBtn.TextSize = 20
VBtn.Active = true
VBtn.Draggable = true
Instance.new("UICorner", VBtn).CornerRadius = UDim.new(1, 0)
local VStroke = Instance.new("UIStroke", VBtn)
VStroke.Thickness = 2
_G.Toggles["VBtn"] = true
SyncRGB(VStroke, "VBtn")
SyncRGB(VBtn, "VBtn")
VBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

print("VALTRIX V22 - ALL-IN-ONE HUB LOADED!")
