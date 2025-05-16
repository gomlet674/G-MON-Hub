local GMON = {}

-- ESP God Chalice
function GMON.ESPGodChalice()
    for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
        if v:IsA("Tool") and v.Name == "God's Chalice" then
            local Billboard = Instance.new("BillboardGui", v)
            Billboard.Size = UDim2.new(0, 100, 0, 40)
            Billboard.AlwaysOnTop = true
            Billboard.Name = "GMON_ESP"

            local Text = Instance.new("TextLabel", Billboard)
            Text.Text = "GOD CHALICE"
            Text.Size = UDim2.new(1, 0, 1, 0)
            Text.TextScaled = true
            Text.TextColor3 = Color3.fromRGB(255, 50, 50)
            Text.BackgroundTransparency = 1
        end
    end
end

-- Farm Chest, stop if God Chalice found
local farmRunning = false
function GMON.FarmChest()
    farmRunning = true
    while farmRunning and task.wait(0.5) do
        local foundChalice = false
        for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
            if v:IsA("Tool") and v.Name == "God's Chalice" then
                foundChalice = true
                break
            end
        end

        if foundChalice then
            farmRunning = false
            warn("God Chalice ditemukan, Farm dihentikan.")
            break
        end

        -- Farm semua chest
        for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
            if v:IsA("Model") and v.Name:lower():find("chest") then
                game.Players.LocalPlayer.Character:PivotTo(v:GetPivot())
                wait(1)
            end
        end
    end
end

return GMON