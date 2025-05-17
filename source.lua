-- source.lua - GMON Hub Full Logic Connected to main.lua

-- Services local Players = game:GetService("Players") local ReplicatedStorage = game:GetService("ReplicatedStorage") local TweenService = game:GetService("TweenService") local RunService = game:GetService("RunService")

-- Player and character local LocalPlayer = Players.LocalPlayer local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() local HRP = Character:WaitForChild("HumanoidRootPart")

-- Global flags and config from main.lua local flags = _G.Flags local config = _G.Config

-- Helper: Teleport to position local function teleport(pos) HRP.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end

-- Helper: Fire server event local function fireEvent(eventName, ...) local event = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild(eventName) if event then event:FireServer(...) end end

-- ========================== -- Auto Farm by Sea & Level -- ========================== local seaInfo = { {min=1, max=600, folder="Sea1", mob="Bandit"}, {min=600, max=1500, folder="Sea2", mob="proffesor"}, {min=1500, max=2650, folder="Sea3", mob="Serpent hunter"}, }

local function getSeaData() local lvl = LocalPlayer:FindFirstChild("Level") and LocalPlayer.Level.Value or 1 for _, info in ipairs(seaInfo) do if lvl >= info.min and lvl < info.max then return info end end return seaInfo[1] end

local function autoFarm() if not flags.AutoFarm then return end local info = getSeaData() local mobs = workspace:FindFirstChild("Mobs") and workspace.Mobs:FindFirstChild(info.folder) if mobs then for _, mob in ipairs(mobs:GetChildren()) do if mob.Name == info.mob and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then teleport(mob.HumanoidRootPart.Position) fireEvent("AttackMob", mob) task.wait(config.FarmInterval) break end end end end

-- ========================== -- Farm Boss Logic -- ========================== local bossList = { Sea1 = {"Cyborg"}, Sea2 = {"Tide keeper", "cutsed captain"}, Sea3 = {"cake queen"}, }

local function autoBoss() if not (flags.FarmBossSelected or flags.FarmAllBoss) then return end local info = getSeaData() local bosses = bossList[info.folder] or {} for _, bossName in ipairs(bosses) do if flags.FarmBossSelected and flags.SelectedBoss ~= bossName then continue end local boss = workspace:FindFirstChild("Bosses") and workspace.Bosses:FindFirstChild(bossName) if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then teleport(boss.HumanoidRootPart.Position) fireEvent("AttackMob", boss) task.wait(1) if not flags.FarmAllBoss then break end end end end

-- ========================== -- Farm Chest Logic -- ========================== local function farmChests() if not flags.FarmChest then return end local chests = workspace:FindFirstChild("Chests") and workspace.Chests:GetChildren() or {} for _, chest in ipairs(chests) do if chest:IsA("BasePart") then local dist = (HRP.Position - chest.Position).Magnitude local tween = TweenService:Create(HRP, TweenInfo.new(dist/100), {CFrame = chest.CFrame * CFrame.new(0,3,0)}) tween:Play() tween.Completed:Wait() fireEvent("CollectChest", chest) task.wait(0.5) end end end

-- ========================== -- Item Auto Farm -- ========================== local function autoItem() if flags.AutoCDK then fireEvent("CollectItem", "CDK") end if flags.AutoYama then fireEvent("CollectItem", "Yama") end if flags.AutoTushita then fireEvent("CollectItem", "Tushita") end if flags.AutoSoulGuitar then fireEvent("CollectItem", "SoulGuitar") end end

-- ========================== -- Prehistoric Island Logic -- ========================== local function autoPrehistoric() if flags.KillGolem then local golem = workspace:FindFirstChild("Prehistoric") and workspace.Prehistoric:FindFirstChild("Golem") if golem and golem.Humanoid.Health>0 then teleport(golem.HumanoidRootPart.Position); fireEvent("AttackMob", golem) end end if flags.DefendVolcano then local guard = workspace.Prehistoric and workspace.Prehistoric:FindFirstChild("VolcanoGuard") if guard then teleport(guard.HumanoidRootPart.Position); fireEvent("AttackMob", guard) end end if flags.CollectDragonEgg then for _, egg in ipairs(workspace.Prehistoric and workspace.Prehistoric.Eggs or {}) do teleport(egg.Position); fireEvent("CollectItem", egg) end end if flags.CollectBones then for _, bone in ipairs(workspace.Prehistoric and workspace.Prehistoric.Bones or {}) do teleport(bone.Position); fireEvent("CollectItem", bone) end end end

-- ========================== -- Kitsune Island Logic -- ========================== local function autoKitsune() if flags.CollectAzure then for _, ember in ipairs(workspace:FindFirstChild("KitsuneIsland") and workspace.KitsuneIsland.AzureEmbers or {}) do teleport(ember.Position); fireEvent("CollectItem", ember) end end if flags.TradeAzure then fireEvent("TradeItem", "AzureEmber") end end

-- ========================== -- Leviathan Logic -- ========================== local function autoLeviathan() if flags.AttackLeviathan then local levi = workspace:FindFirstChild("Bosses") and workspace.Bosses:FindFirstChild("Leviathan") if levi and levi.Humanoid.Health>0 then teleport(levi.HumanoidRootPart.Position); fireEvent("AttackMob", levi) end end end

-- ========================== -- DevilFruit Logic -- ========================== local function autoDevilFruit() if flags.GachaFruit then fireEvent("GachaFruit") end if flags.FruitTarget then fireEvent("SelectFruit", flags.FruitTarget) end end

-- ========================== -- ESP Logic -- ========================== local ESPBoxes = {} local function updateESP() -- clear for obj, box in pairs(ESPBoxes) do box:Destroy(); ESPBoxes[obj]=nil end -- fruit if flags.ESPFruit then for _, f in ipairs(workspace:FindFirstChild("Fruits") or {}) do if f:IsA("BasePart") then local b=Instance.new("BoxHandleAdornment", f); b.Adornee=f; b.Size=f.Size; b.Color3=Color3.new(1,0,0); b.AlwaysOnTop=true; b.Transparency=0.5; ESPBoxes[f]=b end end end -- player if flags.ESPPlayer then for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then local part=p.Character:FindFirstChild("HumanoidRootPart"); if part then local b=Instance.new("BoxHandleAdornment", part); b.Adornee=part; b.Size=part.Size; b.Color3=Color3.new(0,1,0); b.AlwaysOnTop=true; b.Transparency=0.5; ESPBoxes[part]=b end end end end -- chest if flags.ESPChest then for _, c in ipairs(workspace:FindFirstChild("Chests") or {}) do if c:IsA("BasePart") then local b=Instance.new("BoxHandleAdornment", c); b.Adornee=c; b.Size=c.Size; b.Color3=Color3.new(1,1,0); b.AlwaysOnTop=true; b.Transparency=0.5; ESPBoxes[c]=b end end end -- flower if flags.ESPFlower then for _, fl in ipairs(workspace:FindFirstChild("Flowers") or {}) do if fl:IsA("BasePart") then local b=Instance.new("BoxHandleAdornment", fl); b.Adornee=fl; b.Size=fl.Size; b.Color3=Color3.new(1,0,1); b.AlwaysOnTop=true; b.Transparency=0.5; ESPBoxes[fl]=b end end end end

-- ========================== -- Misc Logic -- ========================== -- Server Hop local TeleportService = game:GetService("TeleportService") local function serverHop() if flags.ServerHop then task.wait(600); TeleportService:Teleport(game.PlaceId, LocalPlayer) end end -- Redeem Codes local codes={"Code1","Code2"} local function redeemCodes() if flags.RedeemCodes then for _,c in ipairs(codes) do fireEvent("RedeemCode", c); task.wait(0.5) end; flags.RedeemCodes=false end end -- FPS Booster, Auto Awaken, Fast Attack placeholders local function fpsBoost() if flags.FPSBooster then -- implement as needed end end local function autoAwaken() if flags.AutoAwaken then fireEvent("AwakenFruit") end end local function fastAttack() if flags.FastAttack then -- implement rapid fire logic end end

-- ========================== -- Main Loop -- ========================== RunService.Heartbeat:Connect(function() autoFarm(); autoBoss(); farmChests(); autoItem(); autoPrehistoric(); autoKitsune(); autoLeviathan(); autoDevilFruit() updateESP(); serverHop(); redeemCodes(); fpsBoost(); autoAwaken(); fastAttack() end)

print("GMON Hub Full source.lua loaded")

