-- source.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = _G.GMONHub.TweenService
local LocalPlayer = _G.GMONHub.LocalPlayer

-- Helper: Get closest mob or chest within range
local function GetNearestTarget()
    local nearest
    local nearestDist = math.huge
    for _, mob in pairs(workspace:GetChildren()) do
        if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            local root = mob:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < nearestDist and dist < 100 then -- max range 100 studs
                    nearestDist = dist
                    nearest = mob
                end
            end
        end
    end
    return nearest
end

-- Tween to position function
local function TweenToPosition(targetPos)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    local tweenInfo = TweenInfo.new((hrp.Position - targetPos).Magnitude / 30, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos) + Vector3.new(0,3,0)})
    tween:Play()
    tween.Completed:Wait()
end

-- Farming loop
spawn(function()
    while true do
        if _G.GMONHub.AutoFarmEnabled() then
            local target = GetNearestTarget()
            if target then
                local hrp = target:FindFirstChild("HumanoidRootPart")
                if hrp then
                    TweenToPosition(hrp.Position)
                    wait(0.3)
                    -- Attack logic, depending on SelectedWeapon
                    local weapon = _G.GMONHub.SelectedWeapon()
                    if weapon == "Melee" then
                        -- Example melee attack function call
                        pcall(function()
                            LocalPlayer.Character.Humanoid:MoveTo(hrp.Position)
                            -- Simulate melee attack
                        end)
                    elseif weapon == "Fruit" then
                        -- Use fruit skill (needs implementation)
                    elseif weapon == "Sword" then
                        -- Use sword skill (needs implementation)
                    elseif weapon == "Gun" then
                        -- Use gun skill (needs implementation)
                    end
                end
            else
                wait(1)
            end
        else
            wait(0.5)
        end
        wait(0.1)
    end
end)

-- Aimbot Logic (simple)
local mouse = LocalPlayer:GetMouse()
RunService.RenderStepped:Connect(function()
    if _G.GMONHub.AimbotEnabled() then
        local closestPlayer
        local closestDist = math.huge
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0 then
                local pos = plr.Character.HumanoidRootPart.Position
                local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(pos)
                if onScreen then
                    local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = plr
                    end
                end
            end
        end
        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = closestPlayer.Character.HumanoidRootPart.Position
            local camera = workspace.CurrentCamera
            camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
        end
    end
end)