-- source.lua
 -- Modul logic untuk GMON Hub UI

local M = {}

-- Daftar boss per sea (1-3) 
M.bossPerSea = { [1] = {"Gorilla King","Bobby","Saw","Yeti"}, [2] = {"Mob Leader","Vice Admiral","Warden"}, [3] = {"Swan","Magma Admiral","Fishman Lord"} }

-- Mengembalikan list semua boss berdasarkan sea 
player function M.allBosses() local plr = game.Players.LocalPlayer local sea = plr:FindFirstChild("SeaLevel") and plr.SeaLevel.Value or 1 local list = {} for s = 1, 3 do for _, bossName in ipairs(M.bossPerSea[s]) do table.insert(list, bossName) end end return list end

-- Menghitung fase bulan berdasarkan menit 
function M.getMoonPhase() local minute = os.date("*t").min local idx = minute % 8 + 1 local phases = {"🌑","🌒","🌓","🌔","🌕","🌖","🌗","🌘"} return phases[idx] .. " (" .. (idx-1) .. "/4)" end

-- Cek apakah sebuah pulau spawn di workspace 
function M.islandSpawned(name) return workspace:FindFirstChild(name) ~= nil end

-- Contoh cek keberadaan item God Chalice di Backpack
 function M.hasGodChalice() local plr = game.Players.LocalPlayer return plr.Backpack:FindFirstChild("GodChalice") ~= nil end

-- Auto farm quest: panggil remote Quest untuk tiap level hingga maxLevel di semua sea 1-3 
function M.autoFarm(plr, maxLevel) local sea = plr:FindFirstChild("SeaLevel") and plr.SeaLevel.Value or 1 for lvl = 1, maxLevel do pcall(function() game.ReplicatedStorage.Remotes.Quest:InvokeServer(sea, lvl) end) end end

-- Farm boss terpilih 
function M.farmBoss(plr, bossName) local boss = workspace:FindFirstChild(bossName) if boss and boss.PrimaryPart then local root = plr.Character and plr.Character.PrimaryPart if root then root.CFrame = boss.PrimaryPart.CFrame * CFrame.new(0,5,0) end end end

-- Farm semua chest di sea saat ini 
function M.farmChest(plr) local sea = plr:FindFirstChild("SeaLevel") and plr.SeaLevel.Value or 1 for _, obj in ipairs(workspace:GetDescendants()) do if obj.Name == "Chest" and obj:FindFirstChild("Sea") then if obj.Sea.Value == sea then pcall(function() game.ReplicatedStorage.Remotes.OpenChest:InvokeServer(obj) end) end end end end

return M

