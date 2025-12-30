-- MainServer.lua
-- Template server-side untuk AUTOFARM (untuk GAME MILIKMU SENDIRI)
-- Modular: Sea enemies, Car path, BuildAboat gold demo
-- *JANGAN* gunakan untuk cheating di game publik.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Create RemoteEvent if not exists (server must create)
local Remote = ReplicatedStorage:FindFirstChild("HubRemote")
if not Remote then
    Remote = Instance.new("RemoteEvent")
    Remote.Name = "HubRemote"
    Remote.Parent = ReplicatedStorage
end

-- State tables
local BF_RUNNING = {}   -- players running bloomfruit/autofarm
local CAR_RUNNING = {}
local BOAT_RUNNING = {}

-- CONFIG: Map place id -> sea index (sesuaikan PlaceId milikmu)
local SeaPlaceId = {
    [1] = 2753915549, -- ganti
    [2] = 4442272183, -- ganti
    [3] = 7449423635, -- ganti
}
-- CONFIG: Folders in workspace that contain enemies per sea (sesuaikan nama folder)
local SeaFolders = {
    [1] = workspace:FindFirstChild("Sea1Enemies"),
    [2] = workspace:FindFirstChild("Sea2Enemies"),
    [3] = workspace:FindFirstChild("Sea3Enemies"),
}

-- Helper: get numeric sea index for current place
local function getCurrentSea()
    for k,v in pairs(SeaPlaceId) do
        if game.PlaceId == v then
            return k
        end
    end
    -- fallback: nil (means not in a sea-specific place)
    return nil
end

-- Utility: ensure leaderstats money/gold exist
local function ensureLeaderstats(player)
    if not player:FindFirstChild("leaderstats") then
        local ls = Instance.new("Folder")
        ls.Name = "leaderstats"
        ls.Parent = player
        local money = Instance.new("IntValue")
        money.Name = "Money"
        money.Value = 0
        money.Parent = ls
        local gold = Instance.new("IntValue")
        gold.Name = "Gold"
        gold.Value = 0
        gold.Parent = ls
    end
end

Players.PlayerAdded:Connect(function(p)
    ensureLeaderstats(p)
end)

-- Find nearest valid enemy part (expects enemy model has HumanoidRootPart & Humanoid)
local function findNearestEnemyInFolder(player, folder)
    if not folder then return nil end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local best, bestDist = nil, math.huge
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
            local hum = mob:FindFirstChild("Humanoid")
            if hum.Health > 0 then
                local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = mob
                end
            end
        end
    end
    return best, bestDist
end

-- SAFE: Teleport player near the enemy (server-side). Pastikan tidak memaksa physics terlalu agresif.
local function teleportNear(player, targetModel, offset)
    offset = offset or Vector3.new(0, 0, 4)
    if not targetModel or not targetModel:FindFirstChild("HumanoidRootPart") then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local targetPos = targetModel.HumanoidRootPart.Position + offset
    -- use SetPrimaryPartCFrame on character's HumanoidRootPart
    local ok, err = pcall(function()
        hrp.CFrame = CFrame.new(targetPos)
    end)
    return ok
end

-- DAMAGE helper (server must call acceptable damage function; here we call TakeDamage if exists)
local function damageEnemy(enemy, amount)
    if not enemy then return end
    local hum = enemy:FindFirstChild("Humanoid")
    if hum and hum.Health > 0 then
        hum:TakeDamage(amount)
    end
end

-- ===== BLOX FRUIT: AUTO FARM (All Sea) =====
local function startBFAutoFarm(player)
    if BF_RUNNING[player] then return end
    BF_RUNNING[player] = true
    ensureLeaderstats(player)

    task.spawn(function()
        while BF_RUNNING[player] do
            local sea = getCurrentSea()
            if not sea then
                -- Not in a sea place; skip and wait
                task.wait(1)
                continue
            end

            local folder = SeaFolders[sea]
            if not folder then
                task.wait(1)
                continue
            end

            local enemy, dist = findNearestEnemyInFolder(player, folder)
            if enemy then
                -- teleport near and "attack"
                teleportNear(player, enemy, Vector3.new(0,0,4))
                damageEnemy(enemy, 35) -- sesuaikan
                -- award server-side currency / xp / drops (contoh: money + gold)
                player.leaderstats.Money.Value = player.leaderstats.Money.Value + 10
                player.leaderstats.Gold.Value = player.leaderstats.Gold.Value + 1
            else
                -- no enemies found; wait longer
                task.wait(1)
            end

            task.wait(0.25) -- throttle loop
        end
    end)
end

local function stopBFAutoFarm(player)
    BF_RUNNING[player] = nil
end

-- ===== CAR: Path & Solid Track + Car Runner =====
-- Creates a simple straight track starting from car start position
local TracksFolder = workspace:FindFirstChild("AutoTracks") or Instance.new("Folder", workspace)
TracksFolder.Name = "AutoTracks"

local function createSolidTrack(originCFrame, length, step, partSize)
    length = length or 40
    step = step or 12
    partSize = partSize or Vector3.new(12, 2, 12)
    local folder = Instance.new("Folder")
    folder.Name = "Track_" .. HttpService:GenerateGUID(false)
    folder.Parent = TracksFolder
    for i = 1, length do
        local p = Instance.new("Part")
        p.Size = partSize
        p.Anchored = true
        p.CanCollide = true
        p.Material = Enum.Material.Metal
        p.Position = (originCFrame * CFrame.new(0, -3, -i * step)).p
        p.Parent = folder
    end
    return folder
end

-- Move car along track parts sequentially (simple snap movement)
local function runCarAlongTrack(player, carModel, trackFolder)
    if not carModel or not carModel.PrimaryPart then return end
    local startCF = carModel.PrimaryPart.CFrame
    local parts = {}
    for _, part in ipairs(trackFolder:GetChildren()) do
        if part:IsA("BasePart") then table.insert(parts, part) end
    end
    table.sort(parts, function(a,b) return a.Position.Z < b.Position.Z end) -- simple sort (adjust per orientation)
    local index = 1
    while CAR_RUNNING[player] and carModel.PrimaryPart and #parts > 0 do
        local target = parts[index]
        if target then
            carModel:SetPrimaryPartCFrame(CFrame.new(target.Position + Vector3.new(0,4,0)))
            -- give money each step
            if player and player:FindFirstChild("leaderstats") then
                player.leaderstats.Money.Value = player.leaderstats.Money.Value + 5
            end
            index = index + 1
            if index > #parts then index = 1 end
        end
        task.wait(0.12) -- speed control
    end

    -- restore car to start position
    if carModel and carModel.PrimaryPart then
        carModel:SetPrimaryPartCFrame(startCF)
    end
end

local function startCarFarm(player)
    if CAR_RUNNING[player] then return end
    CAR_RUNNING[player] = true
    ensureLeaderstats(player)

    task.spawn(function()
        local car = workspace:FindFirstChild("Cars") and workspace.Cars:FindFirstChild(player.Name)
        if not car or not car.PrimaryPart then
            -- nothing to run
            CAR_RUNNING[player] = nil
            return
        end
        local startCF = car.PrimaryPart.CFrame
        local track = createSolidTrack(startCF, 40, 14, Vector3.new(12,2,12))

        runCarAlongTrack(player, car, track)

        -- cleanup
        if track and track.Parent then track:Destroy() end
        CAR_RUNNING[player] = nil
    end)
end

local function stopCarFarm(player)
    CAR_RUNNING[player] = nil
end

-- ===== BUILD A BOAT: Auto Gold Farm (Demo) =====
-- This demo expects workspace.BuildBoatTreasures with Parts or Models named "Treasure" or "Chest"
local function findNearestTreasure(player)
    local folder = workspace:FindFirstChild("BuildBoatTreasures")
    if not folder then return nil end
    return findNearestEnemyInFolder(player, folder) -- reusing function: treasures as models with HumanoidRootPart or PrimaryPart
end

local function startBoatGoldFarm(player)
    if BOAT_RUNNING[player] then return end
    BOAT_RUNNING[player] = true
    ensureLeaderstats(player)

    task.spawn(function()
        while BOAT_RUNNING[player] do
            -- find nearest treasure
            local nearest = nil
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and workspace:FindFirstChild("BuildBoatTreasures") then
                local folder = workspace.BuildBoatTreasures
                local best, bestDist = nil, math.huge
                for _, obj in ipairs(folder:GetChildren()) do
                    local pos = nil
                    if obj:IsA("BasePart") then pos = obj.Position
                    elseif obj:IsA("Model") and obj.PrimaryPart then pos = obj.PrimaryPart.Position end
                    if pos then
                        local d = (pos - hrp.Position).Magnitude
                        if d < bestDist then bestDist, best = d, obj end
                    end
                end
                nearest = best
            end

            if nearest then
                -- teleport and "collect" (demo)
                if nearest:IsA("BasePart") then
                    hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0,3,0))
                    nearest:Destroy()
                elseif nearest:IsA("Model") and nearest.PrimaryPart then
                    hrp.CFrame = CFrame.new(nearest.PrimaryPart.Position + Vector3.new(0,3,0))
                    nearest:Destroy()
                end
                -- award gold
                player.leaderstats.Gold.Value = player.leaderstats.Gold.Value + 5
            else
                task.wait(1)
            end

            task.wait(0.3)
        end
    end)
end

local function stopBoatGoldFarm(player)
    BOAT_RUNNING[player] = nil
end

-- ===== Remote handling =====
Remote.OnServerEvent:Connect(function(player, action, state)
    if action == "BF_AUTO_FARM" then
        if state then startBFAutoFarm(player) else stopBFAutoFarm(player) end
    elseif action == "CAR_AUTO_FARM" then
        if state then startCarFarm(player) else stopCarFarm(player) end
    elseif action == "BOAT_GOLD_FARM" then
        if state then startBoatGoldFarm(player) else stopBoatGoldFarm(player) end
    end
end)

-- cleanup on leave
Players.PlayerRemoving:Connect(function(p)
    BF_RUNNING[p] = nil
    CAR_RUNNING[p] = nil
    BOAT_RUNNING[p] = nil
end)

print("[MainServer] Loaded: AutoFarm template ready (use only on your own place).")
