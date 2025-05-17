-- source.lua - Logic utama GMON Hub Roblox Blox Fruits

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Helper fungsi umum
local function waitForChild(parent, childName, timeout)
    timeout = timeout or 5
    local child = parent:FindFirstChild(childName)
    if child then return child end
    child = parent.ChildAdded:Wait()
    if child.Name == childName then return child end
    return nil
end

-- Variables internal
local flags = _G.Flags
local config = _G.Config

-- References to important remotes and objects
local EventsFolder = ReplicatedStorage:WaitForChild("Events") -- Ganti sesuai nama event sebenarnya
local RemoteEvents = EventsFolder:WaitForChild("RemoteEvents") -- contoh
local BossFolder = workspace:FindFirstChild("Bosses") or workspace:FindFirstChild("BossFolder")

-- ============================
-- Auto Farm Logic
-- ============================
local function AutoFarm()
    if not flags.AutoFarm then return end
    -- Contoh: Cari quest sesuai level dan farm mob terdekat
    -- Ini contoh sederhana, sesuaikan dengan quest dan mob sebenarnya
    local quest = ReplicatedStorage.Quests:FindFirstChild("Quest" .. tostring(LocalPlayer.Level.Value))
    if quest then
        local mob = workspace.Mobs:FindFirstChild(quest.MobName.Value)
        if mob and mob.Health > 0 then
            -- Teleport ke mob
            Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
            -- Serang mob dengan senjata atau skill
            -- Panggil remote event serang mob
            RemoteEvents.Attack:FireServer(mob)
        end
    end
end

-- ============================
-- Auto Boss Logic
-- ============================
local function AutoBoss()
    if flags.FarmBossSelected or flags.FarmAllBoss then
        for _, boss in pairs(BossFolder:GetChildren()) do
            if boss.Health > 0 then
                if flags.FarmBossSelected and boss.Name ~= flags.BossSelected then
                    continue
                end
                -- Teleport ke boss
                Character.HumanoidRootPart.CFrame = boss.HumanoidRootPart.CFrame * CFrame.new(0, 0, 10)
                -- Serang boss
                RemoteEvents.Attack:FireServer(boss)
                task.wait(1)
            end
        end
    end
end

-- ============================
-- ESP Logic
-- ============================
local ESPItems = {}

local function CreateESP(obj, color)
    if ESPItems[obj] then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = obj
    box.Size = obj.Size
    box.Color3 = color
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Transparency = 0.5
    box.Parent = obj
    ESPItems[obj] = box
end

local function RemoveESP()
    for obj, esp in pairs(ESPItems) do
        if esp and esp.Parent then
            esp:Destroy()
        end
        ESPItems[obj] = nil
    end
end

local function UpdateESP()
    RemoveESP()
    if flags.ESPFruit then
        for _, fruit in pairs(workspace.Fruits:GetChildren()) do
            if fruit:IsA("BasePart") then
                CreateESP(fruit, Color3.new(1, 0, 0))
            end
        end
    end
    if flags.ESPPlayer then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                CreateESP(plr.Character.HumanoidRootPart, Color3.new(0, 1, 0))
            end
        end
    end
    if flags.ESPChest then
        for _, chest in pairs(workspace.Chests:GetChildren()) do
            if chest:IsA("BasePart") then
                CreateESP(chest, Color3.new(1, 1, 0))
            end
        end
    end
    if flags.ESPFlower then
        for _, flower in pairs(workspace.Flowers:GetChildren()) do
            if flower:IsA("BasePart") then
                CreateESP(flower, Color3.new(1, 0, 1))
            end
        end
    end
end

-- ============================
-- Server Hop Logic
-- ============================
local TeleportService = game:GetService("TeleportService")

local function ServerHop()
    if not flags.ServerHop then return end
    local PlaceID = game.PlaceId
    local Servers = {}
    -- Contoh query server dengan HTTP, atau gunakan API khusus Roblox jika tersedia
    -- Di sini menggunakan cara sederhana reload server saat kondisi tertentu tercapai
    wait(600) -- delay sebelum server hop
    TeleportService:Teleport(PlaceID, LocalPlayer)
end

-- ============================
-- Redeem Codes Logic
-- ============================
local RedeemCodes = {
    "Code1",
    "Code2",
    "Code3"
}

local function RedeemAllCodes()
    if not flags.RedeemCodes then return end
    for _, code in pairs(RedeemCodes) do
        local success, err = pcall(function()
            RemoteEvents.RedeemCode:InvokeServer(code)
        end)
        task.wait(0.5)
    end
    flags.RedeemCodes = false
end

-- ============================
-- Auto Awaken Fruit Logic
-- ============================
local function AutoAwaken()
    if not flags.AutoAwaken then return end
    -- Contoh panggil remote awaken fruit
    RemoteEvents.AwakenFruit:FireServer()
end

-- ============================
-- Fast Attack Logic
-- ============================
local function FastAttack()
    if not flags.FastAttack then return end
    -- Contoh: panggil remote attack berkali-kali
    -- Bisa diintegrasi dengan AutoFarm atau AutoBoss
end

-- ============================
-- Update Loop
-- ============================
RunService.Heartbeat:Connect(function()
    -- Update Character reference
    if not Character or not Character.Parent then
        Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    end

    if flags.AutoFarm then
        AutoFarm()
    end

    if flags.FarmBossSelected or flags.FarmAllBoss then
        AutoBoss()
    end

    UpdateESP()

    if flags.ServerHop then
        ServerHop()
    end

    if flags.RedeemCodes then
        RedeemAllCodes()
    end

    if flags.AutoAwaken then
        AutoAwaken()
    end

    if flags.FastAttack then
        FastAttack()
    end
end)

print("GMON Hub Logic Loaded")