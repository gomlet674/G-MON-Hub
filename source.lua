-- source.lua | GMON-Redz Logic

local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local Players         = game:GetService("Players")

local LP              = Players.LocalPlayer
local HRP             = LP.Character and LP.Character:WaitForChild("HumanoidRootPart")
local Camera          = workspace.CurrentCamera

-- Utility: TweenTo
local function TweenTo(pos, speed)
    speed = speed or 200
    if not HRP then return end
    local dist = (HRP.Position - pos).Magnitude
    local ti = TweenInfo.new(dist/speed, Enum.EasingStyle.Linear)
    local tw = TweenService:Create(HRP,ti,{CFrame=CFrame.new(pos)})
    tw:Play(); tw.Completed:Wait()
end

-- Find nearest enemy
local function GetNearestEnemy()
    local nearest, nd = nil, math.huge
    for _,m in ipairs(workspace.Enemies:GetChildren()) do
        if m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Humanoid")
           and m.Humanoid.Health>0 then
            local d=(HRP.Position-m.HumanoidRootPart.Position).Magnitude
            if d<nd then nd,nearest=d,m end
        end
    end
    return nearest
end

-- Find nearest chest part
local function GetNearestChest()
    local nearest, nd = nil, math.huge
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Part") and o.Name:lower():find("chest") then
            local d=(HRP.Position-o.Position).Magnitude
            if d<nd then nd,nearest=d,o end
        end
    end
    return nearest
end

-- Attack function
local function AttackLoop()
    while true do
        if _G.AutoFarm or _G.AutoChest then
            if _G.AutoFarm then
                local m=GetNearestEnemy()
                if m then
                    TweenTo(m.HumanoidRootPart.Position+Vector3.new(0,3,0),250)
                    LP.Character.Humanoid:MoveTo(m.HumanoidRootPart.Position)
                    task.wait(0.3)
                    pcall(function() LP.Character.Humanoid:EquipTool(LP.Backpack:FindFirstChild(_G.SelectedWeapon)) end)
                    task.wait(0.2)
                end
            end
            if _G.AutoChest then
                local c=GetNearestChest()
                if c then
                    TweenTo(c.Position+Vector3.new(0,3,0),250)
                    task.wait(1)
                end
            end
        end
        task.wait(0.1)
    end
end

-- Aimbot
local function Aimbot()
    RunService.RenderStepped:Connect(function()
        if _G.Aimbot then
            local nearest,md = nil,math.huge
            local mouse=LP:GetMouse()
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr~=LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local sp,pos = Camera:WorldToScreenPoint(plr.Character.HumanoidRootPart.Position)
                    if pos and _G.Aimbot then
                        local d=(Vector2.new(mouse.X,mouse.Y)-Vector2.new(sp.X,sp.Y)).Magnitude
                        if d<md then md,nearest=d,plr end
                    end
                end
            end
            if nearest then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearest.Character.HumanoidRootPart.Position)
            end
        end
    end)
end

-- Fruit Mastery
local function FruitMastery()
    spawn(function()
        while true do
            if _G.FruitMastery then
                pcall(function()  _G.GMONHub.TweenTo(HRP.Position,200) end) -- dummy
                -- simulate fruit skill here
            end
            task.wait(5)
        end
    end)
end

-- Fast Attack & Auto Click
local function FastClick()
    spawn(function()
        while true do
            if _G.FastAttack or _G.AutoClick then
                pcall(function()
                    local tool = LP.Character:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end)
            end
            task.wait(0.2)
        end
    end)
end

-- Auto Equip Accessory
local function EquipAccessory()
    spawn(function()
        while true do
            if _G.AutoEquipAccessory then
                for _,it in ipairs(LP.Backpack:GetChildren()) do
                    if it:IsA("Tool") and it.Name:lower():find("accessory") then
                        LP.Character.Humanoid:EquipTool(it)
                    end
                end
            end
            task.wait(30)
        end
    end)
end

-- Initialization
FruitMastery()
FastClick()
EquipAccessory()
Aimbot()
spawn(AttackLoop)

print("GMON Redz Hub logic loaded!")