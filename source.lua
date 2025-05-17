-- source.lua

-- Referensi ke main.lua
local GMON = require(game:GetService("CoreGui"):WaitForChild("GMONHub"))

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Config
local FarmRadius = 80 -- radius untuk cari mob
local ChestRadius = 80

-- Utility Functions
local function getNearestEnemy()
    local nearest
    local nearestDistance = math.huge
    for _, mob in pairs(Workspace.Enemies:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
            local dist = (HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
            if dist < FarmRadius then
                if dist < nearestDistance then
                    nearest = mob
                    nearestDistance = dist
                end
            end
        end
    end
    return nearest
end

local function getNearestChest()
    local nearest
    local nearestDistance = math.huge
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("Part") and part.Name:lower():find("chest") then
            local dist = (HumanoidRootPart.Position - part.Position).Magnitude
            if dist < ChestRadius then
                if dist < nearestDistance then
                    nearest = part
                    nearestDistance = dist
                end
            end
        end
    end
    return nearest
end

-- Weapon Equip Logic
local function equipWeapon(weaponType)
    local backpack = Player.Backpack
    local char = Player.Character
    if not char then return end

    local function equip(item)
        if char:FindFirstChild(item.Name) == nil then
            Player.Character.Humanoid:EquipTool(item)
        end
    end

    if weaponType == "Melee" then
        -- Cari tool melee prioritas
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("melee") or tool.Name:lower():find("katana") or tool.Name:lower():find("sword")) then
                equip(tool)
                return
            end
        end
    elseif weaponType == "Fruit" then
        -- Cari tool buah di backpack
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("fruit") then
                equip(tool)
                return
            end
        end
    elseif weaponType == "Sword" then
        -- Prioritaskan sword
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("sword") then
                equip(tool)
                return
            end
        end
    elseif weaponType == "Gun" then
        -- Cari senjata jarak jauh (gun)
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol") or tool.Name:lower():find("rifle")) then
                equip(tool)
                return
            end
        end
    end
end

-- Simple attack function (klik kiri)
local function attack()
    local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Klik kiri otomatis (sebagai simulasi)
    local mouse = Player:GetMouse()
    -- Simulate attack by activating tool
    tool:Activate()
end

-- Aimbot Logic (simple)
local function aimbot()
    if not GMON.AimbotEnabled() then return end
    local target = getNearestEnemy()
    if not target then return end
    local targetPart = target:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    -- Set camera CFrame ke target
    local camera = workspace.CurrentCamera
    camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
end

-- Auto Farm Logic
local function autoFarm()
    if not GMON.AutoFarmEnabled() then return end

    local enemy = getNearestEnemy()
    if enemy and enemy:FindFirstChild("HumanoidRootPart") then
        -- Tween ke posisi dekat enemy
        GMON.TweenTo(enemy.HumanoidRootPart.Position + Vector3.new(0, 3, 0), 300)

        -- Equip weapon sesuai pilihan
        equipWeapon(GMON.SelectedWeapon())

        -- Attack terus sampai enemy mati
        while enemy.Humanoid.Health > 0 and GMON.AutoFarmEnabled() do
            attack()
            task.wait(0.3)
        end
    else
        task.wait(0.5)
    end
end

-- Auto Chest Logic
local function autoChest()
    if not GMON.AutoChestEnabled() then return end
    local chest = getNearestChest()
    if chest then
        GMON.TweenTo(chest.Position + Vector3.new(0, 3, 0), 300)
        task.wait(1.5)
    else
        task.wait(3)
    end
end

-- Main Loop
RunService.Heartbeat:Connect(function()
    if GMON.AutoFarmEnabled() then
        autoFarm()
    end
    if GMON.AutoChestEnabled() then
        autoChest()
    end
    if GMON.AimbotEnabled() then
        aimbot()
    end
end)

-- Server Hop (Optional)
local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId

local function serverHop()
    local servers = {}
    local HttpService = game:GetService("HttpService")
    local success, response = pcall(function()
        return game:HttpGetAsync("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    end)
    if success then
        local data = HttpService:JSONDecode(response)
        if data and data.data then
            for _, server in pairs(data.data) do
                if server.playing < server.maxPlayers then
                    table.insert(servers, server.id)
                end
            end
        end
    end

    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(PlaceId, randomServer, Player)
    end
end

-- Command to hop server via chat (/hop)
Player.Chatted:Connect(function(msg)
    if msg:lower() == "/hop" then
        serverHop()
    end
end)

-- Auto Equip Accessory (Example)
local function autoEquipAccessory()
    local char = Player.Character
    if not char then return end
    for _, acc in pairs(Player.Backpack:GetChildren()) do
        if acc:IsA("Tool") and (acc.Name:lower():find("accessory") or acc.Name:lower():find("ring") or acc.Name:lower():find("amulet")) then
            Player.Character.Humanoid:EquipTool(acc)
        end
    end
end

-- Auto Equip accessory setiap 60 detik
task.spawn(function()
    while true do
        autoEquipAccessory()
        task.wait(60)
    end
end)

print("GMON Hub source.lua loaded successfully.")