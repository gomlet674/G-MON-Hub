-- source.lua - GMON Hub Logic

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local activeThreads = {}

-- UTIL: Jalankan fungsi berulang jika flag aktif
local function runFlagLoop(flagName, interval, fn)
    if activeThreads[flagName] then return end
    activeThreads[flagName] = true
    task.spawn(function()
        while _G.Flags[flagName] do
            local success, err = pcall(fn)
            if not success then warn("Error in", flagName, ":", err) end
            task.wait(interval or 0.5)
        end
        activeThreads[flagName] = false
    end)
end

-- Autofarm contoh
if _G.Flags["AutoFarm"] then
    runFlagLoop("AutoFarm", _G.Config.FarmInterval, function()
        local mobs = Workspace:FindFirstChild("Mobs")
        if mobs then
            for _, mob in pairs(mobs:GetChildren()) do
                if mob:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character:PivotTo(mob.HumanoidRootPart.CFrame * CFrame.new(0, 5, -5))
                    break
                end
            end
        end
    end)
end

-- ESP logic sederhana
if _G.Flags["ESPPlayers"] then
    runFlagLoop("ESPPlayers", 1, function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not player.Character:FindFirstChild("ESPTag") then
                    local tag = Instance.new("BillboardGui", player.Character)
                    tag.Name = "ESPTag"
                    tag.Size = UDim2.new(0,100,0,20)
                    tag.Adornee = player.Character:FindFirstChild("Head")
                    tag.AlwaysOnTop = true

                    local name = Instance.new("TextLabel", tag)
                    name.Size = UDim2.new(1,0,1,0)
                    name.BackgroundTransparency = 1
                    name.Text = player.Name
                    name.TextColor3 = Color3.new(1,0,0)
                    name.TextScaled = true
                end
            end
        end
    end)
end

-- Devil Fruit Finder contoh
if _G.Flags["FruitFinder"] then
    runFlagLoop("FruitFinder", 2, function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj.Name:lower():find("fruit") then
                print("[GMON] Found fruit:", obj:GetFullName())
            end
        end
    end)
end

-- Tambah fitur lain sesuai flag
-- Contoh: AutoChest, AutoKitsune, ESPMobs, AutoKill, dll...

return true