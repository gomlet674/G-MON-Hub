-- SERVER LOGIC (REAL WORKING LOGIC)
-- FOR YOUR OWN GAME ONLY

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Remote = ReplicatedStorage:WaitForChild("HubRemote")

local BF_RUNNING = {}
local CAR_RUNNING = {}

-- ===== BLOX FRUIT AUTO FARM (OWN GAME) =====
local function startBFAutoFarm(player)
    if BF_RUNNING[player] then return end
    BF_RUNNING[player] = true

    task.spawn(function()
        while BF_RUNNING[player] do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.5) continue end

            -- CARI ENEMY TERDEKAT (ganti folder Enemy sesuai game kamu)
            local nearest, dist = nil, math.huge
            for _, mob in pairs(workspace.Enemies:GetChildren()) do
                if mob:FindFirstChild("HumanoidRootPart") then
                    local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = mob
                    end
                end
            end

            if nearest then
                hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                -- SERANG (logic asli game kamu)
                if nearest:FindFirstChild("Humanoid") then
                    nearest.Humanoid:TakeDamage(25)
                end
            end

            task.wait(0.2)
        end
    end)
end

local function stopBFAutoFarm(player)
    BF_RUNNING[player] = nil
end

-- ===== CAR TYCOON AUTO FARM =====
local function startCarFarm(player)
    if CAR_RUNNING[player] then return end
    CAR_RUNNING[player] = true

    task.spawn(function()
        local car = workspace.Cars:FindFirstChild(player.Name)
        if not car or not car.PrimaryPart then return end

        local startCF = car.PrimaryPart.CFrame

        while CAR_RUNNING[player] do
            car:SetPrimaryPartCFrame(car.PrimaryPart.CFrame * CFrame.new(0,0,-5))
            -- TAMBAH UANG (server-side aman)
            player.leaderstats.Money.Value += 10
            task.wait(0.1)
        end

        -- KEMBALI KE POSISI AWAL
        car:SetPrimaryPartCFrame(startCF)
    end)
end

local function stopCarFarm(player)
    CAR_RUNNING[player] = nil
end

-- ===== REMOTE HANDLER =====
Remote.OnServerEvent:Connect(function(player, action, state)
    if action == "BF_AUTO_FARM" then
        if state then startBFAutoFarm(player) else stopBFAutoFarm(player) end
    elseif action == "CAR_AUTO_FARM" then
        if state then startCarFarm(player) else stopCarFarm(player) end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    BF_RUNNING[p] = nil
    CAR_RUNNING[p] = nil
end)

-- ===== ALL SEA AUTO FARM =====

local SeaEnemies = {
    [1] = workspace:WaitForChild("Sea1Enemies"),
    [2] = workspace:WaitForChild("Sea2Enemies"),
    [3] = workspace:WaitForChild("Sea3Enemies")
}

local SeaPlaceId = {
    [1] = 2753915549, -- Sea 1 PlaceId
    [2] = 4442272183, -- Sea 2 PlaceId
   [2] = 7449423635, -- Sea 2 PlaceIdd
}

local function getCurrentSea()
    for sea, id in pairs(SeaPlaceId) do
        if game.PlaceId == id then
            return sea
        end
    end
end

local function startBFAutoFarm(player)
    if BF_RUNNING[player] then return end
    BF_RUNNING[player] = true

    task.spawn(function()
        while BF_RUNNING[player] do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local sea = getCurrentSea()

            if not hrp or not sea then
                task.wait(0.5)
                continue
            end

            local enemies = SeaEnemies[sea]
            local nearest, dist = nil, math.huge

            for _, mob in pairs(enemies:GetChildren()) do
                if mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                    local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = mob
                    end
                end
            end

            if nearest then
                hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,4)
                nearest.Humanoid:TakeDamage(40)
            end

            task.wait(0.2)
        end
    end)
end
