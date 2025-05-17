-- source.lua - Integrated GMON Hub Logic

local Players = game:GetService("Players") local ReplicatedStorage = game:GetService("ReplicatedStorage") local TweenService = game:GetService("TweenService") local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() local HRP = Character:WaitForChild("HumanoidRootPart")

-- Globals from main.lua local flags = _G.Flags local config = _G.Config

-- Data for farming by sea local seaData = { { name = "Sea1", levelRange = {1, 600}, mobFolder = workspace:WaitForChild("Mobs"):WaitForChild("Sea1"), mobName = "Bandit" }, { name = "Sea2", levelRange = {600, 1500}, mobFolder = workspace:WaitForChild("Mobs"):WaitForChild("Sea2"), mobName = "Pirate" }, { name = "Sea3", levelRange = {1500, 2650}, mobFolder = workspace:WaitForChild("Mobs"):WaitForChild("Sea3"), mobName = "Marine" }, }

-- Data for bosses per sea local bossData = { Sea1 = {"Cyborg"}, Sea2 = {"Tide keeper", "Kraken"}, Sea3 = {"Tyrant of the skies"}, }

-- Helper to get player's sea based on level local function getCurrentSea() local lvl = LocalPlayer:FindFirstChild("Level") and LocalPlayer.Level.Value or 1 for i, data in ipairs(seaData) do if lvl >= data.levelRange[1] and lvl < data.levelRange[2] then return data end end return seaData[1] end

-- Auto Farm logic local function autoFarm() if not flags.AutoFarm then return end local data = getCurrentSea() for _, mob in ipairs(data.mobFolder:GetChildren()) do if mob.Name == data.mobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then HRP.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0,3,0) ReplicatedStorage:WaitForChild("Events"):WaitForChild("AttackMob"):FireServer(mob) task.wait(config.FarmInterval) break end end end

-- Auto Boss logic local function autoBoss() if not (flags.FarmBossSelected or flags.FarmAllBoss) then return end local sea = getCurrentSea().name for _, bossName in ipairs(bossData[sea] or {}) do if flags.FarmBossSelected and flags.SelectedBoss ~= bossName then continue end local boss = workspace:WaitForChild("Bosses"):FindFirstChild(bossName) if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then HRP.CFrame = boss.HumanoidRootPart.CFrame * CFrame.new(0,5,0) ReplicatedStorage:WaitForChild("Events"):WaitForChild("AttackMob"):FireServer(boss) task.wait(1) if not flags.FarmAllBoss then break end end end end

-- Farm Chest logic local function farmChests() if not flags.FarmChest then return end local chests = workspace:WaitForChild("Chests"):GetChildren() for _, chest in ipairs(chests) do if chest:IsA("BasePart") then local distance = (HRP.Position - chest.Position).Magnitude local tweenInfo = TweenService:Create(HRP, TweenInfo.new(distance/100), {CFrame = chest.CFrame * CFrame.new(0,3,0)}) tweenInfo:Play() tweenInfo.Completed:Wait() -- collect chest ReplicatedStorage:WaitForChild("Events"):WaitForChild("CollectChest"):FireServer(chest) task.wait(0.5) end end end

-- Update loop RunService.Heartbeat:Connect(function() autoFarm() autoBoss() farmChests() end)

print("GMON Hub source.lua loaded")

