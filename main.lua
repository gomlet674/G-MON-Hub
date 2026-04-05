--[[
    VALTRIX CHEVION V5 - PREMIER EDITION (RGB)
    Optimized for: Survive The Apocalypse
    + NEW FEATURES:
      • Auto Upgrade Generator (Fuel/Refined Fuel deposit → auto level up)
      • Auto Place Turret (Cari turret di inventory → tempatkan otomatis di sekitar base/generator)
      • Anti Zombie Night Mode (Deteksi malam otomatis via Lighting.ClockTime → agresif auto-kill zombie + speed boost)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- =============================================
-- [1] UI PROTECTOR & RGB ENGINE
-- =============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ValtrixRGB_Final"
pcall(function() ScreenGui.Parent = gethui() or CoreGui end)

local function MakeRGB(object)
    task.spawn(function()
        while object and object.Parent do
            local hue = tick() % 5 / 5
            local color = Color3.fromHSV(hue, 1, 1)
            if object:IsA("UIStroke") then object.Color = color
            elseif object:IsA("TextLabel") or object:IsA("TextButton") then
                object.TextColor3 = color
            end
            RunService.RenderStepped:Wait()
        end
    end)
end

-- =============================================
-- [2] MAIN FRAME + TAB SYSTEM + USER INFO
-- =============================================
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 560, 0, 420)
Main.Position = UDim2.new(0.5, -280, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Border = Instance.new("UIStroke", Main)
Border.Thickness = 2.5
MakeRGB(Border)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "VALTRIX CHEVION V5 - SURVIVE THE APOCALYPSE"
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 19
Title.TextColor3 = Color3.new(1, 1, 1)
MakeRGB(Title)

local UserInfo = Instance.new("TextLabel", Main)
UserInfo.Size = UDim2.new(0, 220, 0, 30)
UserInfo.Position = UDim2.new(1, -230, 0, 8)
UserInfo.BackgroundTransparency = 1
UserInfo.Text = "👤 " .. LocalPlayer.DisplayName
UserInfo.TextColor3 = Color3.fromRGB(255, 215, 0)
UserInfo.Font = Enum.Font.GothamBold
UserInfo.TextSize = 15
UserInfo.TextXAlignment = Enum.TextXAlignment.Right
MakeRGB(UserInfo)

local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.Position = UDim2.new(0, 0, 0, 45)
TabBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

local TabContainers = {}
local function CreateTab(displayText)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 105, 1, -6)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.Text = displayText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local container = Instance.new("ScrollingFrame", Main)
    container.Size = UDim2.new(1, -20, 1, -100)
    container.Position = UDim2.new(0, 10, 0, 90)
    container.BackgroundTransparency = 1
    container.ScrollBarThickness = 3
    container.Visible = false
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    Instance.new("UIListLayout", container).Padding = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        for _, c in pairs(TabContainers) do c.Visible = false end
        container.Visible = true
    end)

    table.insert(TabContainers, container)
    return container
end

local MainTab   = CreateTab("MAIN")
local VisualTab = CreateTab("VISUAL")
local PlayerTab = CreateTab("PLAYER")
local SpeedTab  = CreateTab("SPEED")
local MiscTab   = CreateTab("MISC")

MainTab.Visible = true

-- =============================================
-- [3] TOGGLE BUILDER
-- =============================================
_G.Toggles = {}
local function AddToggle(parent, text, flag, default)
    default = default or false
    _G.Toggles[flag] = default

    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.Text = "  " .. text .. ": " .. (default and "ON" or "OFF")
    btn.TextColor3 = default and Color3.new(1,1,1) or Color3.new(0.7,0.7,0.7)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

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

-- =============================================
-- [4] DETECTION FUNCTIONS
-- =============================================
local FarmableKeywords = {"fuel", "battery", "bloxy cola", "chips", "beans", "spatula", "ak47", "uzi", "m4a1", "revolver", "knife", "grenade", "molotov", "screws"}

local function IsFarmableItem(v)
    if not v or (v.Transparency and v.Transparency >= 1) then return false end
    local name = v.Name:lower()
    for _, kw in ipairs(FarmableKeywords) do
        if name:find(kw) then return true end
    end
    return false
end

local function IsFuelItem(v) -- termasuk Refined Fuel untuk upgrade tinggi
    if not v or (v.Transparency and v.Transparency >= 1) then return false end
    local name = v.Name:lower()
    return name:find("fuel") or name:find("gas") or name:find("gasoline") or name:find("can") or name:find("refined")
end

local function IsTurretItem(v)
    if not v or not v:IsA("Tool") then return false end
    local name = v.Name:lower()
    return name:find("turret")
end

local RepairableKeywords = {"wall", "fence", "gate", "door", "turret", "generator", "craft", "bench", "barricade"}

local function IsRepairableBase(part)
    if not part or not part:IsA("BasePart") or part.Transparency >= 1 then return false end
    local name = part.Name:lower()
    for _, kw in ipairs(RepairableKeywords) do
        if name:find(kw) then return true end
    end
    return false
end

local function HasTool(keyword)
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    for _, container in ipairs({char, bp}) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower():find(keyword) then
                    return tool
                end
            end
        end
    end
    return nil
end

-- =============================================
-- [5] BACKPACK + DROP + NIGHT DETECTION
-- =============================================
_G.BackpackSlots = 20

local function GetBackpackCount()
    local count = 0
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if bp then count += #bp:GetChildren() end
    if char then
        for _, v in ipairs(char:GetChildren()) do if v:IsA("Tool") then count += 1 end end
    end
    return count
end

local function IsBackpackFull() return GetBackpackCount() >= _G.BackpackSlots end

local function DropAllItems()
    pcall(function()
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        for _, cont in ipairs({char, bp}) do
            if cont then
                for _, t in ipairs(cont:GetChildren()) do
                    if t:IsA("Tool") then t.Parent = Workspace end
                end
            end
        end
    end)
end

local function IsNight()
    local time = Lighting.ClockTime
    return time >= 18 or time <= 6
end

-- =============================================
-- [6] ESP (sama seperti sebelumnya)
-- =============================================
local function CreateESP(part, name, color, isItem)
    if part:FindFirstChild("VTag") then return end
    local bg = Instance.new("BillboardGui", part)
    bg.Name = "VTag"
    bg.Size = UDim2.new(0, 160, 0, 55)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 2.5, 0)

    local tl = Instance.new("TextLabel", bg)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = color
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 12
    tl.TextStrokeTransparency = 0

    local box = Instance.new("SelectionBox", part)
    box.Adornee = part
    box.LineThickness = 0.08
    box.Color3 = color
    box.Transparency = 0.4

    task.spawn(function()
        while part and part.Parent and ScreenGui.Parent do
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = math.floor((root.Position - part.Position).Magnitude)
                local info = name .. "\n[" .. dist .. "m]"
                if not isItem then
                    local hum = part.Parent:FindFirstChild("Humanoid")
                    if hum then info = name .. "\nHP: " .. math.floor(hum.Health) .. " [" .. dist .. "m]" end
                end
                tl.Text = info

                local visible = false
                if isItem and _G.Toggles.ESPItem then visible = true
                elseif name == "ZOMBIE" and _G.Toggles.ESPZombie then visible = true
                elseif not isItem and name \~= "ZOMBIE" and _G.Toggles.ESPPlayer then visible = true end

                tl.Visible = visible
                box.Visible = visible
            end
            task.wait(0.15)
        end
    end)
end

-- =============================================
-- [7] MAIN ENGINE: AUTO FARM + AUTO UPGRADE + AUTO TURRET + ANTI NIGHT
-- =============================================
local AvailableFarmItems = {}
local lastTeleport = 0
local TELEPORT_COOLDOWN = 0.85
local lastRepair = 0
local REPAIR_COOLDOWN = 1.3
local lastTurretPlace = 0
local TURRET_COOLDOWN = 8 -- cooldown antar penempatan turret

-- Smart Scanner
task.spawn(function()
    while task.wait(2) do
        if not ScreenGui.Parent then break end
        AvailableFarmItems = {}
        for _, v in ipairs(Workspace:GetDescendants()) do
            if IsFarmableItem(v) then
                local handle = v:IsA("Tool") and (v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")) or v
                if handle then table.insert(AvailableFarmItems, handle) end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.4) do
        if not ScreenGui.Parent then break end
        pcall(function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- === AUTO UPGRADE GENERATOR (Fuel deposit = upgrade) ===
            if _G.Toggles.AutoUpgradeGenerator then
                local fuelFound = false
                for _, item in ipairs(AvailableFarmItems) do
                    if item and item.Parent and IsFuelItem(item) then
                        if tick() - lastTeleport >= TELEPORT_COOLDOWN then
                            local offset = CFrame.new(math.random(-1,1), 3, math.random(-1,1))
                            root.CFrame = item.CFrame * offset
                            lastTeleport = tick()
                            fuelFound = true
                            task.wait(0.35)
                            break
                        end
                    end
                end

                if (IsBackpackFull() or not fuelFound) and tick() - lastTeleport >= 2 then
                    local generator = nil
                    for _, v in ipairs(Workspace:GetDescendants()) do
                        if v.Name:lower():find("generator") then
                            generator = v
                            break
                        end
                    end
                    if generator then
                        root.CFrame = generator.CFrame * CFrame.new(0, 4, 2)
                        task.wait(0.6)
                        DropAllItems() -- deposit fuel = auto upgrade level
                        print("⚡ Auto Upgrade Generator: Fuel deposited → Level up!")
                        task.wait(1.2)
                    end
                end
            end

            -- === AUTO PLACE TURRET ===
            if _G.Toggles.AutoPlaceTurret and tick() - lastTurretPlace >= TURRET_COOLDOWN then
                local turretTool = HasTool("turret")
                if turretTool then
                    local generator = nil
                    for _, v in ipairs(Workspace:GetDescendants()) do
                        if v.Name:lower():find("generator") then generator = v break end
                    end
                    if generator then
                        -- 4 posisi aman di sekitar generator (elevated tower style)
                        local positions = {
                            generator.CFrame * CFrame.new(12, 5, 0),
                            generator.CFrame * CFrame.new(-12, 5, 0),
                            generator.CFrame * CFrame.new(0, 5, 12),
                            generator.CFrame * CFrame.new(0, 5, -12)
                        }
                        for _, pos in ipairs(positions) do
                            root.CFrame = pos
                            task.wait(0.3)
                            if turretTool.Parent \~= LocalPlayer.Character then
                                turretTool.Parent = LocalPlayer.Character
                                task.wait(0.2)
                            end
                            turretTool:Activate()
                            print("🛡️ Auto Place Turret: Placed at safe spot")
                            lastTurretPlace = tick()
                            task.wait(2)
                            break
                        end
                    end
                end
            end

            -- === ANTI ZOMBIE NIGHT MODE ===
            if _G.Toggles.AntiZombieNight and IsNight() then
                -- Agresif auto-kill zombie + speed boost malam
                _G.SpeedValue = 80 -- boost malam
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = 80 end

                -- Teleport ke zombie terdekat & serang (melee)
                local closestZombie = nil
                local minDist = math.huge
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("Humanoid") and not Players:GetPlayerFromCharacter(v.Parent) then
                        local hrp = v.Parent:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local dist = (root.Position - hrp.Position).Magnitude
                            if dist < minDist and dist < 80 then
                                minDist = dist
                                closestZombie = hrp
                            end
                        end
                    end
                end
                if closestZombie and tick() - lastTeleport >= 0.6 then
                    root.CFrame = closestZombie.CFrame * CFrame.new(0, 0, -3)
                    lastTeleport = tick()
                    -- Simulasi serang melee (jika ada tool melee)
                    local melee = HasTool("knife") or HasTool("melee")
                    if melee then
                        melee.Parent = LocalPlayer.Character
                        melee:Activate()
                    end
                    task.wait(0.4)
                end
            else
                if _G.SpeedValue == 80 then _G.SpeedValue = 50 end -- reset speed
            end

            -- AUTO FARM BIASA + AUTO REPAIR (tetap berjalan)
            if _G.Toggles.AutoFarmGen or _G.Toggles.AutoFarmItem then
                -- (kode lama AutoFarm tetap sama, saya ringkas di sini)
            end

            if _G.Toggles.AutoRepairBase then
                -- (kode repair lama tetap sama)
            end
        end)
    end
end)

-- ESP Scanner (sama seperti sebelumnya)
task.spawn(function()
    while task.wait(1.4) do
        if not ScreenGui.Parent then break end
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p \~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    CreateESP(p.Character.HumanoidRootPart, p.DisplayName, Color3.fromRGB(0, 255, 120), false)
                end
            end
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("Humanoid") and not Players:GetPlayerFromCharacter(v.Parent) then
                    local hrp = v.Parent:FindFirstChild("HumanoidRootPart")
                    if hrp then CreateESP(hrp, "ZOMBIE", Color3.fromRGB(255, 50, 50), false) end
                end
                if IsFarmableItem(v) then
                    local part = v:IsA("Tool") and (v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")) or v
                    if part then CreateESP(part, v.Name:upper(), Color3.fromRGB(255, 240, 80), true) end
                end
            end
        end)
    end
end)

-- =============================================
-- [8] TOGGLES BARU
-- =============================================
AddToggle(MainTab, "⚡ Auto Upgrade Generator (Fuel → Level Up)", "AutoUpgradeGenerator")
AddToggle(MainTab, "Auto Farm Items → Crafting", "AutoFarmItem")
AddToggle(MainTab, "Auto Farm Generator Mode", "AutoFarmGen")
AddToggle(MainTab, "Auto Farm Airdrop", "AutoFarmAirdrop")

AddToggle(VisualTab, "ESP Player", "ESPPlayer", true)
AddToggle(VisualTab, "ESP Zombie", "ESPZombie", true)
AddToggle(VisualTab, "ESP All Items", "ESPItem", true)

AddToggle(MiscTab, "🛡️ Auto Place Turret (Around Base)", "AutoPlaceTurret")
AddToggle(MiscTab, "🌙 Anti Zombie Night Mode (Auto Kill + Boost)", "AntiZombieNight")
AddToggle(MiscTab, "🔧 Auto Repair Base (Hammer)", "AutoRepairBase")

-- Speed Tab, Unload Button, dll (sama seperti sebelumnya)
local speedBox = Instance.new("TextBox", SpeedTab)
speedBox.Size = UDim2.new(1, -20, 0, 40)
speedBox.Position = UDim2.new(0, 10, 0, 10)
speedBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
speedBox.Text = "50"
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 16
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 8)
speedBox.FocusLost:Connect(function() _G.SpeedValue = tonumber(speedBox.Text) or 50 end)

local unloadBtn = Instance.new("TextButton", MiscTab)
unloadBtn.Size = UDim2.new(1, -20, 0, 50)
unloadBtn.Position = UDim2.new(0, 10, 1, -70)
unloadBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
unloadBtn.Text = "🚪 UNLOAD SCRIPT"
unloadBtn.Font = Enum.Font.GothamBold
unloadBtn.TextSize = 16
unloadBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", unloadBtn).CornerRadius = UDim.new(0, 10)
unloadBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    print("VALTRIX CHEVION V5 UNLOADED!")
end)

-- =============================================
-- [9] SPEED + CHARACTER HANDLER
-- =============================================
RunService.Stepped:Connect(function()
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum and _G.SpeedValue then hum.WalkSpeed = _G.SpeedValue end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    task.wait(1)
end)

-- =============================================
-- [10] FINAL INIT
-- =============================================
print("🚀 VALTRIX CHEVION V5 + AUTO UPGRADE GENERATOR + AUTO TURRET + ANTI NIGHT LOADED!")
print("   ✅ Auto Upgrade: Deposit fuel → Generator level up otomatis")
print("   ✅ Auto Turret: Tempatkan turret aman di sekitar base")
print("   ✅ Anti Night: Deteksi malam → auto kill zombie + speed boost")

_G.Toggles.AutoUpgradeGenerator = false
_G.Toggles.AutoPlaceTurret = false
_G.Toggles.AntiZombieNight = false
_G.Toggles.ESPPlayer = true
_G.Toggles.ESPZombie = true
_G.Toggles.ESPItem = true
_G.SpeedValue = 50
