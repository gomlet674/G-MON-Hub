-- source.lua - GMON Hub Logic
repeat task.wait() until game:IsLoaded()

-- Services
local Players       = game:GetService("Players")
local Replicated    = game:GetService("ReplicatedStorage")
local Workspace     = game:GetService("Workspace")
local RunService    = game:GetService("RunService")

local player = Players.LocalPlayer

-- Utility: Safe pcall wrapper
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("GMON Logic error:", err) end
end

-- Main loop: runs every frame
RunService.Heartbeat:Connect(function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- == Info flags don't require action here (display only) ==

    -- == Main features ==
    if _G.Flags.AutoFarm then
        safe(function()
            -- Example: fire server to attack nearest mob
            local mob = Workspace:FindFirstChild("Mobs"):GetChildren()[1]
            if mob and mob:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/attack", "All")
            end
        end)
    end

    if _G.Flags.FarmBossSelected and _G.Flags.SelectedSea1Boss then
        safe(function()
            local boss = Workspace:FindFirstChild("Bosses")[_G.Flags.SelectedSea1Boss]
            if boss and boss:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = boss.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/attack", "All")
            end
        end)
    end

    if _G.Flags.FarmAllBoss then
        safe(function()
            for _, boss in ipairs(Workspace:FindFirstChild("Bosses"):GetChildren()) do
                if boss:FindFirstChild("HumanoidRootPart") then
                    hrp.CFrame = boss.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                    Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/attack", "All")
                    task.wait(_G.Config.FarmInterval)
                end
            end
        end)
    end

    if _G.Flags.MasteryFruit then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/masteryfruit", "")
        end)
    end

    -- == Item features ==
    if _G.Flags.AutoCDK then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/redeemcode", "")
        end)
    end
    if _G.Flags.AutoYama then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/getyama", "")
        end)
    end
    if _G.Flags.AutoTushita then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/gettushita", "")
        end)
    end
    if _G.Flags.AutoSoulGuitar then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/getsoulguitar", "")
        end)
    end

    -- == Sea events ==
    if _G.Flags.KillSeaBeast then
        safe(function()
            local beast = Workspace:FindFirstChild("SeaBeast")
            if beast and beast:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = beast.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/attack", "All")
            end
        end)
    end
    if _G.Flags.AutoSail then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/sailboat", "")
        end)
    end

    -- == Prehistoric ==
    if _G.Flags.KillGolem then
        safe(function()
            local golem = Workspace:FindFirstChild("Prehistoric"):FindFirstChild("Golem")
            if golem and golem:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = golem.HumanoidRootPart.CFrame * CFrame.new(0,5,0)
                Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/attack", "All")
            end
        end)
    end
    if _G.Flags.DefendVolcano then
        safe(function()
            -- Walk to volcano center
            hrp.CFrame = Workspace:Prehistoric.VolcanoCenter.CFrame
        end)
    end
    if _G.Flags.CollectDragonEgg then
        safe(function()
            for _, egg in ipairs(Workspace:Prehistoric:GetChildren()) do
                if egg.Name == "DragonEgg" then
                    hrp.CFrame = egg.CFrame * CFrame.new(0,5,0)
                end
            end
        end)
    end
    if _G.Flags.CollectBones then
        safe(function()
            for _, bone in ipairs(Workspace:Prehistoric:GetChildren()) do
                if bone.Name == "Bone" then
                    hrp.CFrame = bone.CFrame * CFrame.new(0,5,0)
                end
            end
        end)
    end

    -- == Kitsune ==
    if _G.Flags.CollectAzure then
        safe(function()
            for _, ember in ipairs(Workspace:ThirdSea.KitsuneIsland:GetChildren()) do
                if ember.Name == "AzureEmber" then
                    hrp.CFrame = ember.CFrame * CFrame.new(0,5,0)
                end
            end
        end)
    end
    if _G.Flags.TradeAzure then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/tradeazure", "")
        end)
    end

    -- == Leviathan ==
    if _G.Flags.AttackLeviathan then
        safe(function()
            local levi = Workspace:FindFirstChild("Leviathan")
            if levi and levi:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = levi.HumanoidRootPart.CFrame * CFrame.new(0,5,0)
                Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/attack", "All")
            end
        end)
    end

    -- == DevilFruit ==
    if _G.Flags.GachaFruit then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/gachafruit", "")
        end)
    end

    -- == ESP ==
-- Tables to keep track of created adornments
local espItems = {
    fruits = {},
    players = {},
    chests = {},
    flowers = {}
}

-- Utility to clear adornments of a category
local function clearESP(tbl)
    for _, adorn in pairs(tbl) do
        if adorn and adorn.Parent then
            adorn:Destroy()
        end
    end
    table.clear(tbl)
end

-- Create a BoxHandleAdornment on instance
local function createBoxESP(obj, color)
    if not obj or not obj:IsA("BasePart") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = obj
    box.Size     = obj.Size + Vector3.new(0.2,0.2,0.2)
    box.Transparency   = 0.5
    box.AlwaysOnTop    = true
    box.ZIndex         = 1
    box.Color3         = color
    box.Parent         = obj
    return box
end

RunService.Heartbeat:Connect(function()
    -- Fruits
    if _G.Flags.ESPFruit then
        clearESP(espItems.fruits)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Fruit" and obj:IsA("BasePart") then
                table.insert(espItems.fruits, createBoxESP(obj, Color3.fromRGB(255, 0, 0)))
            end
        end
    else
        clearESP(espItems.fruits)
    end

    -- Players
    if _G.Flags.ESPPlayer then
        clearESP(espItems.players)
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character then
                local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    table.insert(espItems.players, createBoxESP(hrp, Color3.fromRGB(0, 255, 0)))
                end
            end
        end
    else
        clearESP(espItems.players)
    end

    -- Chests
    if _G.Flags.ESPChest then
        clearESP(espItems.chests)
        for _, chest in ipairs(Workspace:GetDescendants()) do
            if chest.Name:lower():find("chest") and chest:IsA("BasePart") then
                table.insert(espItems.chests, createBoxESP(chest, Color3.fromRGB(0, 0, 255)))
            end
        end
    else
        clearESP(espItems.chests)
    end

    -- Flowers
    if _G.Flags.ESPFlower then
        clearESP(espItems.flowers)
        for _, flower in ipairs(Workspace:GetDescendants()) do
            if flower.Name:lower():find("flower") and flower:IsA("BasePart") then
                table.insert(espItems.flowers, createBoxESP(flower, Color3.fromRGB(255, 255, 0)))
            end
        end
    else
        clearESP(espItems.flowers)
    end
end)

    -- == Misc ==
    if _G.Flags.ServerHop then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/serverhop", "")
        end)
    end
    if _G.Flags.RedeemCodes then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/redeemall", "")
        end)
    end
    if _G.Flags.FPSBooster then
        workspace.FilteringEnabled = false
        Settings().Physics.ThrottleAdjustTime = 1
    end
    if _G.Flags.AutoAwaken then
        safe(function()
            Replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/awakenfruit", "")
        end)
    end

    -- == Settings: Fast Attack ==
    if _G.Flags.FastAttack then
        workspace.Gravity = 0
    else
        workspace.Gravity = 196.2
    end
end)