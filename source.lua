-- source.lua – Logic Eksekusi GMON Hub
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- Cek dan tunggu karakter
repeat task.wait() until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
local hrp = lp.Character:WaitForChild("HumanoidRootPart")

-- FARM INTERVAL
local interval = _G.Config.FarmInterval or 0.5

-- LOOP LOGIC
task.spawn(function()
    while true do
        task.wait(interval)

        -- AutoFarm
        if _G.Flags.AutoFarm then
            -- Contoh: teleport ke lokasi monster
            local target = workspace:FindFirstChild("Enemy")
            if target then
                hrp.CFrame = target.CFrame + Vector3.new(0, 5, 0)
            end
        end

        -- Kill Aura
        if _G.Flags.KillAura then
            for _, enemy in ipairs(workspace:GetChildren()) do
                if enemy:FindFirstChild("Humanoid") and (enemy.Position - hrp.Position).magnitude < 10 then
                    local tool = lp.Character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("RemoteFunction") then
                        pcall(function()
                            tool.RemoteFunction:InvokeServer(enemy)
                        end)
                    end
                end
            end
        end

        -- Sea Mode (contoh fitur laut)
        if _G.Flags.SeaRadar then
            print("[SeaRadar] Aktif: memantau musuh laut...")
        end

        -- Prehistoric Mode
        if _G.Flags.JurassicMode then
            print("[Prehistoric] Mode aktif")
        end

        -- ESP (Enemy Highlight)
        if _G.Flags.ESP then
            for _, ent in ipairs(workspace:GetChildren()) do
                if ent:FindFirstChild("Humanoid") and not ent:FindFirstChild("ESPBox") then
                    local box = Instance.new("BoxHandleAdornment", ent)
                    box.Name = "ESPBox"
                    box.Adornee = ent
                    box.Size = Vector3.new(4, 7, 4)
                    box.AlwaysOnTop = true
                    box.ZIndex = 5
                    box.Color3 = Color3.fromRGB(255, 0, 0)
                    box.Transparency = 0.7
                end
            end
        end

        -- DevilFruit Detection
        if _G.Flags.AutoFruit then
            for _, item in ipairs(workspace:GetDescendants()) do
                if item:IsA("Tool") and item.Name:lower():find("fruit") then
                    hrp.CFrame = item.Handle.CFrame + Vector3.new(0, 3, 0)
                    print("Fruit ditemukan:", item.Name)
                    break
                end
            end
        end
    end
end)