-- source.lua - GMON Hub Full Logic

local Players = game:GetService("Players") local ReplicatedStorage = game:GetService("ReplicatedStorage") local TweenService = game:GetService("TweenService") local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() local HRP = Character:WaitForChild("HumanoidRootPart")

-- Globals from main.lua local flags = _G.Flags local config = _G.Config

--=== Data Definitions ===-- local seaData = { {name="Sea1", lvl={1,600}, folder=workspace:WaitForChild("Mobs"):WaitForChild("Sea1"), mob="Bandit"}, {name="Sea2", lvl={600,1500}, folder=workspace:WaitForChild("Mobs"):WaitForChild("Sea2"), mob="Pirate"}, {name="Sea3", lvl={1500,2650}, folder=workspace:WaitForChild("Mobs"):WaitForChild("Sea3"), mob="Marine"}, } local bossData = { Sea1={","Swan","Cyborg"}, Sea2={"Tide Keeper","ice admiral","cursed captain","Swan"}, Sea3={"Beautiful Pirate","Stone","cake queen","longma","Tyrant of the skies"}, }

-- Item farming (CDK, Yama, Tushita, SoulGuitar) local function autoFarmItems() if not flags.AutoCDK and not flags.AutoYama and not flags.AutoTushita and not flags.AutoSoulGuitar then return end local events = ReplicatedStorage:WaitForChild("Events") if flags.AutoCDK then events.CollectItem:FireServer("CDK") end if flags.AutoYama then events.CollectItem:FireServer("Yama") end if flags.AutoTushita then events.CollectItem:FireServer("Tushita") end if flags.AutoSoulGuitar then events.CollectItem:FireServer("SoulGuitar") end end

-- Prehistoric island logic local prehistoric = workspace:FindFirstChild("Prehistoric") local function autoPrehistoric() if not flags.KillGolem and not flags.DefendVolcano and not flags.CollectDragonEgg and not flags.CollectBones then return end local events = ReplicatedStorage:WaitForChild("Events") if flags.KillGolem then local golem = prehistoric:FindFirstChild("Golem") if golem and golem.Humanoid.Health>0 then HRP.CFrame = golem.HumanoidRootPart.CFrame * CFrame.new(0,5,0) events.AttackMob:FireServer(golem) end end if flags.DefendVolcano then local volcanoguard = prehistoric:FindFirstChild("VolcanoGuard") if volcanoguard then HRP.CFrame = volcanoguard.HumanoidRootPart.CFrame * CFrame.new(0,5,0) events.AttackMob:FireServer(volcanoguard) end end if flags.CollectDragonEgg then for _, egg in ipairs(prehistoric.Eggs:GetChildren()) do HRP.CFrame = egg.CFrame * CFrame.new(0,5,0) events.CollectItem:FireServer(egg) end end if flags.CollectBones then for _, bone in ipairs(prehistoric.Bones:GetChildren()) do HRP.CFrame = bone.CFrame * CFrame.new(0,5,0) events.CollectItem:FireServer(bone) end end end

-- Kitsune island logic local kitsune = workspace:FindFirstChild("KitsuneIsland") local function autoKitsune() if not flags.CollectAzure and not flags.TradeAzure then return end local events = ReplicatedStorage:WaitForChild("Events") if flags.CollectAzure then for _, ember in ipairs(kitsune.AzureEmbers:GetChildren()) do HRP.CFrame = ember.CFrame * CFrame.new(0,5,0) events.CollectItem:FireServer(ember) end end if flags.TradeAzure then events.TradeItem:FireServer("AzureEmber") end end

-- Leviathan logic local levi = workspace:FindFirstChild("LeviathanIsland") local function autoLeviathan() if not flags.AttackLeviathan then return end local boss = workspace.Bosses:FindFirstChild("Leviathan") if boss and boss.Humanoid.Health>0 then HRP.CFrame = boss.HumanoidRootPart.CFrame * CFrame.new(0,5,0) ReplicatedStorage:WaitForChild("Events"):WaitForChild("AttackMob"):FireServer(boss) end end

-- Existing features: AutoFarm, autoBoss, farmChests done earlier

-- Main update loop RunService.Heartbeat:Connect(function() -- Auto farm mob per sea if flags.AutoFarm then autoFarm() end -- Auto boss if flags.FarmBossSelected or flags.FarmAllBoss then autoBoss() end -- Farm chest if flags.FarmChest then farmChests() end -- Item farming autoFarmItems() -- Prehistoric autoPrehistoric() -- Kitsune autoKitsune() -- Leviathan autoLeviathan() end)

print("GMON Hub Full Logic Loaded")

