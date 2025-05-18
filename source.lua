-- source.lua
local M = {}

-- contoh daftar boss per sea
M.bossPerSea = {
    [1] = {"Gorilla King","Bobby","Saw","Yeti"},
    [2] = {"Mob Leader","Vice Admiral","Warden"},
    [3] = {"Swan","Magma Admiral","Fishman Lord"}
}

function M.allBosses()
    local sea = game.Players.LocalPlayer:FindFirstChild("SeaLevel") and game.Players.LocalPlayer.SeaLevel.Value or 1
    local list = {}
    for s=1,3 do
        for _,b in ipairs(M.bossPerSea[s]) do
            table.insert(list, b)
        end
    end
    return list
end

function M.getMoonPhase()
    local m = os.date("*t").min % 8
    local phases = { "🌑","🌒","🌓","🌔","🌕","🌖","🌗","🌘" }
    return phases[m+1].." "..(m).."/4"
end

function M.islandSpawned(name)
    return workspace:FindFirstChild(name) ~= nil
end

function M.hasGodChalice()
    -- misal cek di inventory
    return game.Players.LocalPlayer.Backpack:FindFirstChild("GodChalice")~=nil
end

function M.autoFarm(player, maxLevel)
    -- iterasi quest level 1–maxLevel, sea 1–3
    local sea = player:FindFirstChild("SeaLevel") and player.SeaLevel.Value or 1
    for lvl=1,maxLevel do
        -- panggil remote quest
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.Quest:InvokeServer(sea, lvl)
        end)
    end
end

function M.farmBoss(player, bossName)
    -- cari NPC boss di workspace dan teleport/serang
    local boss = workspace:FindFirstChild(bossName)
    if boss and boss.PrimaryPart then
        player.Character:SetPrimaryPartCFrame(boss.PrimaryPart.CFrame * CFrame.new(0,5,0))
    end
end

function M.farmChest(player)
    -- cari semua chest di world, bawa player ke sana
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj.Name=="Chest" and obj:FindFirstChild("Sea") then
            local sea = player:FindFirstChild("SeaLevel") and player.SeaLevel.Value or 1
            if obj.Sea.Value == sea then
                pcall(function()
                    game:GetService("ReplicatedStorage").Remotes.OpenChest:InvokeServer(obj)
                end)
            end
        end
    end
end

return M