-- GMON HUB - source.lua -- Berisi fungsi logika utama seperti Farm Chest & ESP God Chalice

local GMON = {}

-- Fungsi ESP God Chalice function GMON.ESPGodChalice() for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do if v:IsA("Tool") and v.Name == "God's Chalice" then local Billboard = Instance.new("BillboardGui") Billboard.Size = UDim2.new(0, 100, 0, 40) Billboard.Adornee = v.Handle or v:FindFirstChildWhichIsA("Part") Billboard.AlwaysOnTop = true

local Label = Instance.new("TextLabel", Billboard)
        Label.Size = UDim2.new(1, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = "GOD CHALICE"
        Label.TextColor3 = Color3.fromRGB(255, 0, 0)
        Label.TextStrokeTransparency = 0
        Label.TextScaled = true

        Billboard.Parent = v
    end
end

end

-- Variabel kontrol farm chest local runningFarm = false local function findGodChalice() for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do if v:IsA("Tool") and v.Name == "God's Chalice" then return true end end return false end

-- Fungsi mulai farm chest function GMON.FarmChest() runningFarm = true while runningFarm and task.wait(1) do if findGodChalice() then warn("God's Chalice ditemukan! Berhenti farm chest.") runningFarm = false break end for _, chest in pairs(game:GetService("Workspace"):GetDescendants()) do if chest:IsA("Model") and string.find(chest.Name:lower(), "chest") and chest:FindFirstChild("TouchInterest") then local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if hrp then hrp.CFrame = chest:GetModelCFrame() + Vector3.new(0, 3, 0) firetouchinterest(hrp, chest:FindFirstChildWhichIsA("Part"), 0) firetouchinterest(hrp, chest:FindFirstChildWhichIsA("Part"), 1) task.wait(0.3) end end end end end

-- Fungsi stop farm chest function GMON.StopFarmChest() runningFarm = false end

return GMON

