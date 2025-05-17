-- source.lua (core logic untuk semua fitur)
local Players   = game:GetService("Players")
local RS        = game:GetService("RunService")
local RepStore  = game:GetService("ReplicatedStorage")
local TweenSvc  = game:GetService("TweenService")

local flags = {
    AutoFarm             = false,
    AutoChest            = false,
    WeaponMode           = "Melee",
    AutoKitsune          = false,
    AutoPrehistoric      = false,
    AutoBossPrehistoric  = false,
    AutoCollectPrehistoric = false,
    AutoDragonDojo       = false,
    AutoRaceV4           = false,
    FastAttack           = false,
    FarmInterval         = 0.5,
    BoatSpeed            = 100,
}

-- helper: teleport & attack
local function attackTarget(npc)
    local char = Players.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- simple touch attack
    hrp.CFrame = CFrame.new(npc.HumanoidRootPart.Position + Vector3.new(0,5,0))
    firetouchinterest(hrp, npc.HumanoidRootPart, 0)
    task.wait(0.1)
    firetouchinterest(hrp, npc.HumanoidRootPart, 1)
end

-- AUTO FARM
spawn(function()
    while true do
        task.wait()
        if flags.AutoFarm then
            local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local nearest, d = nil, math.huge
                for _, npc in pairs(workspace.Enemies:GetChildren()) do
                    if npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health>0 then
                        local dist = (npc.HumanoidRootPart.Position-hrp.Position).Magnitude
                        if dist<d then d,nearest=dist,npc end
                    end
                end
                if nearest then
                    for i=1,3 do
                        attackTarget(nearest)
                        task.wait(flags.FarmInterval)
                    end
                end
            end
        end
    end
end)

-- AUTO CHEST
spawn(function()
    while true do
        task.wait(1)
        if flags.AutoChest then
            for _, chest in pairs(workspace.Chests:GetChildren()) do
                if (chest.Position-Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude<20 then
                    firetouchinterest(Players.LocalPlayer.Character.HumanoidRootPart, chest, 0)
                    task.wait(0.1)
                    firetouchinterest(Players.LocalPlayer.Character.HumanoidRootPart, chest, 1)
                end
            end
        end
    end
end)

-- KITSUNE ISLAND
spawn(function()
    while true do
        task.wait(2)
        if flags.AutoKitsune then
            -- teleport & collect logic…
        end
    end
end)

-- PREHISTORIC
spawn(function()
    while true do
        task.wait(2)
        if flags.AutoPrehistoric or flags.AutoBossPrehistoric or flags.AutoCollectPrehistoric then
            -- implement sesuai kebutuhan…
        end
    end
end)

-- SEA EVENT
spawn(function()
    while true do
        task.wait(5)
        if flags.BoatSpeed then
            -- boat speed already applied via slider/button
        end
    end
end)

-- DRAGON DOJO
spawn(function()
    while true do
        task.wait(5)
        if flags.AutoDragonDojo then
            -- logic dojo…
        end
    end
end)

-- RACE V4
spawn(function()
    while true do
        task.wait(5)
        if flags.AutoRaceV4 then
            -- logic race…
        end
    end
end)

-- Wipe tweens when requested
game:GetService("UserInputService").InputBegan:Connect(function(inp)
    if inp.KeyCode==Enum.KeyCode.Delete then
        for _,t in pairs(TweenSvc:GetPlayingTweens()) do t:Cancel() end
    end
end)

print("G-Mon Hub logic loaded!")