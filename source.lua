-- GMON Hub - source.lua -- Dibuat untuk Roblox Blox Fruits, memuat seluruh fitur utama seperti ESP, Auto Farm, Sea Event, dll.

local GMON = {}

-- SERVICES 
local Players = game:GetService("Players") local ReplicatedStorage = game:GetService("ReplicatedStorage") local Workspace = game:GetService("Workspace") local HttpService = game:GetService("HttpService") local RunService = game:GetService("RunService") local TweenService = game:GetService("TweenService") local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer local Character = function() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end

-- UTILITIES 
function GMON:TweenTo(pos) pcall(function() local hrp = Character():WaitForChild("HumanoidRootPart") local tween = TweenService:Create(hrp, TweenInfo.new((hrp.Position - pos).Magnitude/300, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)}) tween:Play() tween.Completed:Wait() end) end

function GMON:EquipBestWeapon() local Backpack = LocalPlayer.Backpack local Priority = {"Blox Fruit", "Sword", "Melee"} for _, class in ipairs(Priority) do for _, item in pairs(Backpack:GetChildren()) do if item:IsA("Tool") and item.ToolTip:find(class) then LocalPlayer.Character.Humanoid:EquipTool(item) return end end end end

function GMON:AutoFarm() RunService.Heartbeat:Connect(function() if GMON.AutoFarmEnabled then local lvl = LocalPlayer.Data.Level.Value local mob = GMON:GetMobForLevel(lvl) if mob then GMON:TweenTo(mob.Position + Vector3.new(0, 30, 0)) GMON:EquipBestWeapon() LocalPlayer.Character.Humanoid:MoveTo(mob.Position) end end end) end

function GMON:GetMobForLevel(lvl) for _, v in pairs(GMON.MobTable) do if lvl >= v.Min and lvl <= v.Max then local mob = Workspace.Enemies:FindFirstChild(v.Name) if mob then return mob end end end return nil end

GMON.MobTable = { {Name="Bandit", Min=5, Max=10}, {Name="Leviathan Minion", Min=2450, Max=2475},
  -- Tambahkan semua data mob dari level 5-2650 sesuai update Gravity }

function GMON:AutoChest() while GMON.AutoChestEnabled do for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("TouchTransmitter") and v.Parent:FindFirstChild("TouchInterest") then GMON:TweenTo(v.Position) wait(0.5) end end wait(5) end end

function GMON:AutoBoss() if GMON.BossTarget and Workspace.Enemies:FindFirstChild(GMON.BossTarget) then local boss = Workspace.Enemies[GMON.BossTarget] GMON:TweenTo(boss.Position + Vector3.new(0, 30, 0)) end end

function GMON:ESP() for _, v in pairs(Workspace:GetChildren()) do if v:IsA("Model") and v:FindFirstChild("Humanoid") then local highlight = Instance.new("Highlight", v) highlight.FillColor = Color3.fromRGB(255, 0, 0) highlight.OutlineColor = Color3.fromRGB(255, 255, 255) end end end

function GMON:AutoSeaEvents() while GMON.SeaEventEnabled do for _, v in pairs(Workspace.SeaEvents:GetChildren()) do if v:IsA("Model") then GMON:TweenTo(v:GetPivot().Position) end end wait(10) end end

function GMON:ServerHop() local function Hop() local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/2753915549/servers/Public?sortOrder=Asc&limit=100")) for _, server in pairs(servers.data) do if server.playing < server.maxPlayers then TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id) end end end Hop() end

function GMON:FPSBooster() for _, v in pairs(game:GetDescendants()) do if v:IsA("BasePart") then v.Material = Enum.Material.Plastic v.Reflectance = 0 end end setfpscap(30) end

function GMON:AutoAwakenFruit()
    -- Implementasi tergantung event atau raid 
  end

function GMON:AutoEnchant() 
      -- Cek lokasi enchant dan auto klik NPC atau GUI end

function GMON:AutoCrafting() 
        -- Cek material dan NPC crafting, lalu otomatis buat end

function GMON:BountyFarm() 
          -- Temukan player musuh dan auto ke lokasi 
        end

-- TOGGLE SETUP 
          GMON.AutoFarmEnabled = false GMON.AutoChestEnabled = false GMON.SeaEventEnabled = false GMON.BossTarget = "Leviathan"

return GMON

