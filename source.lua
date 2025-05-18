-- source.lua
-- Modul logic untuk GMON Hub UI

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game.Players

local M = {}

-- Daftar boss per sea (1–3)
M.bossPerSea = {
    [1] = {"Gorilla King","Bobby","Saw","Yeti"},
    [2] = {"Mob Leader","Vice Admiral","Warden"},
    [3] = {"Swan","Magma Admiral","Fishman Lord"},
}

-- 1) Semua boss (digunakan dropdown Main)
function M.allBosses()
    local plr = Players.LocalPlayer
    local sea = (plr:FindFirstChild("SeaLevel") and plr.SeaLevel.Value) or 1
    local list = {}
    for s = 1, 3 do
        for _, b in ipairs(M.bossPerSea[s]) do
            table.insert(list, b)
        end
    end
    return list
end

-- 2) Fase Bulan (untuk tab Info)
function M.getMoonPhase()
    local minute = os.date("*t").min
    local idx    = (minute % 8) + 1
    local phases = {"🌑","🌒","🌓","🌔","🌕","🌖","🌗","🌘"}
    return phases[idx] .. " ("..(idx-1).."/4)"
end

-- 3) Cek Spawn Island
function M.islandSpawned(name)
    return workspace:FindFirstChild(name) ~= nil
end

-- 4) Cek GodChalice di Backpack
function M.hasGodChalice()
    local plr = Players.LocalPlayer
    return plr.Backpack:FindFirstChild("GodChalice") ~= nil
end

-- 5) Auto Farm Quest (sea 1–3, level 1–maxLevel)
function M.autoFarm(plr, maxLevel)
    local sea = (plr:FindFirstChild("SeaLevel") and plr.SeaLevel.Value) or 1
    for lvl = 1, maxLevel do
        pcall(function()
            ReplicatedStorage.Remotes.Quest:InvokeServer(sea, lvl)
        end)
    end
end

-- 6) Farm Boss — tanpa teleport kasar: gunakan Humanoid:MoveTo
function M.farmBoss(plr, bossName)
    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local boss = workspace:FindFirstChild(bossName)
    if hrp and boss and boss.PrimaryPart then
        -- Gerakkan karakter mendekati boss
        local hum = char:FindFirstChildOfClass("Humanoid")
        hum:MoveTo(boss.PrimaryPart.Position + Vector3.new(0,5,0))
    end
end

-- 7) Farm Chest — berjalan menuju setiap chest, lalu buka
function M.farmChest(plr)
    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local sea = (plr:FindFirstChild("SeaLevel") and plr.SeaLevel.Value) or 1

    for _, obj in ipairs(workspace:GetDescendants()) do
        -- filtrasi chest dengan properti Sea
        if obj.Name == "Chest" and obj:FindFirstChild("Sea") and obj.Sea.Value == sea then
            -- jalan ke chest
            hum:MoveTo(obj.PrimaryPart and obj.PrimaryPart.Position or obj.Position)
            -- tunggu sampai tiba (atau 1 detik timeout)
            local reached = hum.MoveToFinished:Wait(2)
            if reached then
                pcall(function()
                    ReplicatedStorage.Remotes.OpenChest:InvokeServer(obj)
                end)
            end
        end
    end
end

return M