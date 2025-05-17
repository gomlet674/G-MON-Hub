-- GMON Hub - source.lua -- Semua logika fitur utama dimasukkan di sini

local Players = game:GetService("Players") local LocalPlayer = Players.LocalPlayer local RunService = game:GetService("RunService") local TweenService = game:GetService("TweenService") local VirtualInputManager = game:GetService("VirtualInputManager") local HttpService = game:GetService("HttpService")

local GMON = {}


---

-- Utility Functions --

function GMON:TweenTo(pos) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then local hrp = LocalPlayer.Character.HumanoidRootPart local tweenInfo = TweenInfo.new((hrp.Position - pos).Magnitude / 300, Enum.EasingStyle.Linear) local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos)}) tween:Play() tween.Completed:Wait() end end

function GMON:GetWeapon(type) local backpack = LocalPlayer.Backpack for _, v in pairs(backpack:GetChildren()) do if v:IsA("Tool") then if type == "Melee" and string.find(v.Name, "Combat") then return v end if type == "Sword" and string.find(v.Name, "Sword") then return v end if type == "Fruit" and not string.find(v.Name, "Sword") and not string.find(v.Name, "Gun") and not string.find(v.Name, "Combat") then return v end if type == "Gun" and string.find(v.Name, "Gun") then return v end end end end

function GMON:EquipWeapon(type) local tool = GMON:GetWeapon(type) if tool then LocalPlayer.Character.Humanoid:EquipTool(tool) end end


---

-- Auto Farm Feature --

GMON.AutoFarm = false GMON.SelectedWeapon = "Melee"

function GMON:StartAutoFarm() spawn(function() while GMON.AutoFarm do local mob = GMON:GetNearestMob() if mob then GMON:TweenTo(mob.HumanoidRootPart.Position + Vector3.new(0, 5, 0)) wait(0.5) GMON:EquipWeapon(GMON.SelectedWeapon) end wait() end end) end

function GMON:GetNearestMob() local nearest local dist = math.huge for _, mob in pairs(workspace.Enemies:GetChildren()) do if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then local d = (mob.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude if d < dist then dist = d nearest = mob end end end return nearest end


---

-- Aimbot Feature --

GMON.Aimbot = false function GMON:EnableAimbot() local camera = workspace.CurrentCamera RunService.RenderStepped:Connect(function() if GMON.Aimbot then local target = GMON:GetNearestMob() if target then camera.CFrame = CFrame.new(camera.CFrame.Position, target.HumanoidRootPart.Position) end end end) end


---

-- Fruit Mastery --

GMON.FruitMastery = false function GMON:TrainFruit() spawn(function() while GMON.FruitMastery do GMON:EquipWeapon("Fruit") VirtualInputManager:SendKeyEvent(true, "Z", false, game) wait(5) end end) end


---

-- Fast Attack + Click --

GMON.FastAttack = false GMON.AutoClick = false function GMON:EnableAttack() spawn(function() while true do if GMON.FastAttack or GMON.AutoClick then pcall(function() local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool") if tool then tool:Activate() end end) end wait(0.2) end end) end


---

-- Auto Equip Accessory --

function GMON:AutoEquipAccessory() for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do if item:IsA("Tool") and string.find(item.Name, "Accessory") then LocalPlayer.Character.Humanoid:EquipTool(item) end end end


---

-- Initialization --

GMON:EnableAimbot() GMON:EnableAttack()

return GMON

