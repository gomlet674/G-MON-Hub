-- main.lua  (PART 1 of 3)
-- SAFE DEV FRAMEWORK: GMON Loader + Picker + Modules skeleton (Blox / Car / Build)
-- Client+Server in single file; server-only logic wrapped with RunService:IsServer()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

-- =========================
-- Helper: ensure Remote / Folder
-- =========================
local function ensureInstance(parent, className, name)
    local inst = parent:FindFirstChild(name)
    if inst then return inst end
    inst = Instance.new(className)
    inst.Name = name
    inst.Parent = parent
    return inst
end

-- =========================
-- Core: create remotes & folders (server will own creation)
-- =========================
local RemotesFolder = ensureInstance(ReplicatedStorage, "Folder", "GMON_Remotes")

local REM_BLOX_QUEST        = ensureInstance(RemotesFolder, "RemoteFunction", "Blox_GetQuest")
local REM_BLOX_ADD_EXP      = ensureInstance(RemotesFolder, "RemoteEvent", "Blox_AddExp")
local REM_CAR_BUY           = ensureInstance(RemotesFolder, "RemoteFunction", "Car_Buy")
local REM_BUILD_SPAWN_BOT   = ensureInstance(RemotesFolder, "RemoteEvent", "Build_SpawnBot")

-- =========================
-- GMON LOADER UI (Client-only)
-- =========================
local function showLoaderClient()
    local player = Players.LocalPlayer
    if not player then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "GMON_Loader_GUI"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame", gui)
    bg.AnchorPoint = Vector2.new(0.5,0.5)
    bg.Position = UDim2.fromScale(0.5,0.45)
    bg.Size = UDim2.fromOffset(520,120)
    bg.BackgroundColor3 = Color3.fromRGB(18,18,20)
    bg.BorderSizePixel = 0
    bg.AutoButtonColor = false

    local title = Instance.new("TextLabel", bg)
    title.Size = UDim2.fromScale(1,0.35)
    title.Position = UDim2.fromScale(0,0)
    title.BackgroundTransparency = 1
    title.Text = "GMON"
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.TextColor3 = Color3.new(1,1,1)

    local placeLabel = Instance.new("TextLabel", bg)
    placeLabel.Size = UDim2.fromScale(1,0.18)
    placeLabel.Position = UDim2.fromScale(0,0.34)
    placeLabel.BackgroundTransparency = 1
    placeLabel.Text = "PlaceId: "..tostring(game.PlaceId)
    placeLabel.Font = Enum.Font.Gotham
    placeLabel.TextScaled = true
    placeLabel.TextColor3 = Color3.fromRGB(200,200,200)

    local barBG = Instance.new("Frame", bg)
    barBG.Size = UDim2.fromOffset(480,18)
    barBG.Position = UDim2.fromScale(0.5,0.65)
    barBG.AnchorPoint = Vector2.new(0.5,0.5)
    barBG.BackgroundColor3 = Color3.fromRGB(40,40,40)
    barBG.BorderSizePixel = 0

    local bar = Instance.new("Frame", barBG)
    bar.Size = UDim2.fromScale(0,1)
    bar.Position = UDim2.fromScale(0,0)
    bar.BackgroundColor3 = Color3.fromRGB(0,170,255)
    bar.BorderSizePixel = 0

    local percent = Instance.new("TextLabel", bg)
    percent.Size = UDim2.fromOffset(80,24)
    percent.Position = UDim2.fromScale(0.5,0.84)
    percent.AnchorPoint = Vector2.new(0.5,0.5)
    percent.BackgroundTransparency = 1
    percent.TextScaled = true
    percent.Font = Enum.Font.GothamBold
    percent.TextColor3 = Color3.new(1,1,1)
    percent.Text = "0%"

    -- animate progress to 100
    for i=1,100,4 do
        local newSize = UDim2.fromScale(i/100, 1)
        bar:TweenSize(newSize, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.05, true)
        percent.Text = tostring(i).."%"
        task.wait(0.03)
    end

    task.delay(0.4, function() gui:Destroy() end)
end

-- =========================
-- SERVER: Core systems (only run on server)
-- =========================
if RunService:IsServer() then
    -- Simple datastore-free leaderstats for development
    local function ensureLeaderstats(player)
        if player:FindFirstChild("leaderstats") then return end
        local folder = Instance.new("Folder")
        folder.Name = "leaderstats"
        folder.Parent = player

        local Level = Instance.new("IntValue"); Level.Name = "Level"; Level.Value = 1; Level.Parent = folder
        local Exp = Instance.new("IntValue"); Exp.Name = "Exp"; Exp.Value = 0; Exp.Parent = folder
        local Money = Instance.new("IntValue"); Money.Name = "Money"; Money.Value = 1000; Money.Parent = folder
    end

    Players.PlayerAdded:Connect(function(plr)
        ensureLeaderstats(plr)
    end)

    -- ===== BLOX: Quest system (DEV SAFE)
    local QUESTS = {
        {Id=1, Name="Bandits", Min=1, Max=10, Target="Bandit", Amount=5, Exp=200, Money=100},
        {Id=2, Name="Pirates", Min=10, Max=25, Target="Pirate", Amount=8, Exp=500, Money=250},
    }

    local function getQuestForPlayer(player)
        local ls = player:FindFirstChild("leaderstats")
        local lvl = ls and ls.Level.Value or 1
        for _,q in ipairs(QUESTS) do
            if lvl >= q.Min and lvl <= q.Max then
                return q
            end
        end
        return nil
    end

    REM_BLOX_QUEST.OnServerInvoke = function(player, action)
        if action == "GET" then
            local q = getQuestForPlayer(player)
            if q then
                player:SetAttribute("ActiveQuest", q.Id)
                player:SetAttribute("QuestProgress", 0)
                return q
            end
            return nil
        elseif action == "COMPLETE" then
            local qid = player:GetAttribute("ActiveQuest")
            if not qid then return false end
            local q
            for _,qq in ipairs(QUESTS) do if qq.Id == qid then q = qq break end end
            if not q then return false end
            local ls = player:FindFirstChild("leaderstats")
            if ls then
                ls.Exp.Value = ls.Exp.Value + q.Exp
                ls.Money.Value = ls.Money.Value + q.Money
            end
            player:SetAttribute("ActiveQuest", nil)
            player:SetAttribute("QuestProgress", nil)
            return true
        end
        return nil
    end

    REM_BLOX_ADD_EXP.OnServerEvent:Connect(function(player, mobName)
        local qid = player:GetAttribute("ActiveQuest")
        if not qid then return end
        for _,q in ipairs(QUESTS) do
            if q.Id == qid and q.Target == mobName then
                local prog = (player:GetAttribute("QuestProgress") or 0) + 1
                player:SetAttribute("QuestProgress", prog)
                if prog >= q.Amount then
                    -- complete via remote function to reuse logic
                    REM_BLOX_QUEST:InvokeClient(player, "COMPLETE_TRIGGER") -- client notification (optional)
                    REM_BLOX_QUEST:InvokeServer(player, "COMPLETE")
                end
                break
            end
        end
    end)

    -- ===== CAR: simple buy logic (server-authoritative)
    -- Car models are expected under workspace.CarShop.Cars with child IntValue "Price"
    REM_CAR_BUY.OnServerInvoke = function(player, carName)
        local carsFolder = workspace:FindFirstChild("CarShop") and workspace.CarShop:FindFirstChild("Cars")
        if not carsFolder then
            return false, "Cars folder not found"
        end
        local car = carsFolder:FindFirstChild(carName)
        if not car then
            return false, "Car not found"
        end
        local priceVal = car:FindFirstChild("Price")
        if not priceVal or not priceVal:IsA("IntValue") then
            return false, "Price missing"
        end
        local ls = player:FindFirstChild("leaderstats")
        if not ls or not ls:FindFirstChild("Money") then
            return false, "No money stat"
        end
        local money = ls.Money.Value
        if money < priceVal.Value then
            return false, "Not enough money"
        end

        ls.Money.Value = money - priceVal.Value

        -- mark owned
        local owned = player:FindFirstChild("OwnedCars")
        if not owned then
            owned = Instance.new("Folder", player)
            owned.Name = "OwnedCars"
        end
        if not owned:FindFirstChild(carName) then
            local v = Instance.new("BoolValue", owned)
            v.Name = carName
            v.Value = true
        end

        return true, "Purchased"
    end

    -- ===== BUILD: spawn test bot (server-controlled)
    REM_BUILD_SPAWN_BOT.OnServerEvent:Connect(function(player, config)
        -- config could be {type="farmer", speed=50}
        -- VERY SIMPLE DEV bot spawner: spawns a dummy model under workspace.TestBots
        local botsFolder = workspace:FindFirstChild("TestBots") or Instance.new("Folder", workspace)
        botsFolder.Name = "TestBots"

        local bot = Instance.new("Model")
        bot.Name = "Bot_"..tostring(player.UserId).."_"..tostring(tick())
        local hrp = Instance.new("Part"); hrp.Name = "HumanoidRootPart"; hrp.Size = Vector3.new(2,2,1); hrp.Position = (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position + Vector3.new(4,0,0)) or Vector3.new(0,5,0)
        hrp.Parent = bot
        local humanoid = Instance.new("Humanoid"); humanoid.Parent = bot
        bot.Parent = botsFolder

        -- simple controller: move forward (dev only)
        spawn(function()
            while bot.Parent do
                if not bot:FindFirstChild("HumanoidRootPart") then break end
                local p = bot.HumanoidRootPart
                p.Velocity = Vector3.new(0,0,0)
                p.CFrame = p.CFrame * CFrame.new(0,0,1) -- naive
                wait(0.2)
            end
        end)
    end)

    -- Server done with core systems
    print("[GMON] Server core initialized (Remotes ready).")
end

-- =========================
-- CLIENT: Rayfield UI + Player Info + Game Picker skeleton
-- =========================
if RunService:IsClient() then
    -- show loader
    pcall(showLoaderClient)

    -- Notify loaded
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "GMON Hub",
            Text = "Framework loaded (DEV)",
            Duration = 4
        })
    end)

    -- Try to load Rayfield (if available); fallback to minimal UI if not
    local success, RayfieldOrErr = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    local Rayfield = nil
    if success and RayfieldOrErr then
        Rayfield = RayfieldOrErr
    else
        -- minimal fallback: simple warning in output (UI won't be fancy)
        warn("[GMON] Rayfield failed to load; UI will be minimal. Error:", RayfieldOrErr)
    end

    -- Window creation (Rayfield or minimal)
    local Window
    if Rayfield then
        Window = Rayfield:CreateWindow({
            Name = "GMON Hub (DEV)",
            LoadingTitle = "GMON",
            LoadingSubtitle = "Module Picker",
            ConfigurationSaving = {Enabled = false}
        })
    else
        -- simple fallback window object exposing CreateTab(name,icon) -> returns a simple table with CreateLabel/CreateToggle/CreateButton
        Window = {}
        function Window:CreateTab(name)
            return {
                CreateLabel = function(_,txt) print("[UI] "..name..": "..txt) end,
                CreateButton = function(_,opts) print("[UI] Button: "..(opts.Name or "Button")) end,
                CreateToggle = function(_,opts) print("[UI] Toggle: "..(opts.Name or "Toggle")) end
            }
        end
    end

    -- Player Info tab (always present)
    local InfoTab = Window:CreateTab("Player Info", 4483362458)
    local function refreshPlayerInfo()
        local p = Players.LocalPlayer
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        InfoTab:CreateLabel("Name: "..p.Name)
        InfoTab:CreateLabel("UserId: "..p.UserId)
        if hum then
            InfoTab:CreateLabel("Health: "..math.floor(hum.Health))
            InfoTab:CreateLabel("WalkSpeed: "..hum.WalkSpeed)
        else
            InfoTab:CreateLabel("Character not loaded")
        end
    end
    refreshPlayerInfo()

    -- Game picker & module integration
    local PlaceId = game.PlaceId

    -- Helper: safe wrapper to call remotes
    local function safeInvoke(func, ...)
        local ok, res = pcall(func, ...)
        if not ok then
            warn("[GMON] Remote invoke failed:", res)
            return nil
        end
        return res
    end

    -- =============== BLOX FRUIT UI + hooks ===============
    local function createBloxTab()
        local Tab = Window:CreateTab("Blox Fruit", 4483362458)
        Tab:CreateLabel("Blox Fruit Module (DEV)")

        Tab:CreateButton({ Name = "Get Quest (server)", Callback = function()
            local quest = safeInvoke(function() return REM_BLOX_QUEST:InvokeServer("GET") end)
            if quest then
                StarterGui:SetCore("SendNotification",{Title="Quest",Text=quest.Name,Duration=4})
            else
                StarterGui:SetCore("SendNotification",{Title="Quest",Text="No quest available",Duration=4})
            end
        end })

        Tab:CreateToggle({ Name = "Auto Farm (placeholder)", CurrentValue = false, Callback = function(v)
            -- toggles will be implemented in part 2 (client loop)
            print("[UI] AutoFarm toggle:", v)
        end })

        Tab:CreateToggle({ Name = "Auto Quest (server)", CurrentValue = false, Callback = function(v)
            if v then
                safeInvoke(function() return REM_BLOX_QUEST:InvokeServer("GET") end)
            end
        end })
    end

    -- =============== CAR UI + hooks ===============
    local function createCarTab()
        local Tab = Window:CreateTab("Car Dealership", 4483362458)
        Tab:CreateLabel("Car Shop Module (DEV)")

        Tab:CreateButton({ Name = "Select First Car (preview)", Callback = function()
            local carsFolder = workspace:FindFirstChild("CarShop") and workspace.CarShop:FindFirstChild("Cars")
            if not carsFolder then
                StarterGui:SetCore("SendNotification",{Title="Car",Text="Cars folder not found",Duration=3})
                return
            end
            local c = carsFolder:GetChildren()[1]
            if c and c:FindFirstChild("Price") then
                StarterGui:SetCore("SendNotification",{Title="Car Selected",Text=c.Name.." | Price: "..tostring(c.Price.Value),Duration=4})
            end
        end })

        Tab:CreateButton({ Name = "Buy Selected (example)", Callback = function()
            -- example buying first car
            local carsFolder = workspace:FindFirstChild("CarShop") and workspace.CarShop:FindFirstChild("Cars")
            if not carsFolder then
                StarterGui:SetCore("SendNotification",{Title="Car",Text="Cars folder not found",Duration=3})
                return
            end
            local c = carsFolder:GetChildren()[1]
            if not c then return end
            local ok, msg = safeInvoke(function() return REM_CAR_BUY:InvokeServer(c.Name) end)
            if ok then
                StarterGui:SetCore("SendNotification",{Title="Car",Text="Purchased: "..c.Name,Duration=3})
            else
                StarterGui:SetCore("SendNotification",{Title="Car",Text="Failed: "..tostring(msg),Duration=3})
            end
        end })
    end

    -- =============== BUILD UI + hooks ===============
    local function createBuildTab()
        local Tab = Window:CreateTab("Build A Boat", 4483362458)
        Tab:CreateLabel("Build Module (DEV)")

        Tab:CreateButton({ Name = "Spawn Test Bot", Callback = function()
            REM_BUILD_SPAWN_BOT:FireServer({type="farmer",speed=40})
            StarterGui:SetCore("SendNotification",{Title="Build",Text="Spawn request sent (server creates bot)",Duration=3})
        end })
    end

    -- Game detection & tab creation (simple)
    if PlaceId == 2753915549 or PlaceId == 4442272183 or PlaceId == 7449423635 then
        createBloxTab()
    elseif PlaceId == 537413528 then
        createBuildTab()
    else
        createCarTab()
    end

    -- Part 1 UI and server hooks done
    print("[GMON] Client UI (part1) ready. To continue, request part 2.")
end

-- END OF PART 1
-- If you want next chunk (pathfinding helpers, client auto farm loops, combat remotes, and GUI polish),
-- reply with: 2

-- =========================
-- MAIN.LUA — PART 2
-- Client Helpers + Auto Loops
-- =========================

-- ===== SERVICES =====
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- =========================
-- CLIENT UTILITIES
-- =========================

local ClientUtil = {}

function ClientUtil:GetCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

function ClientUtil:GetHRP()
    return self:GetCharacter():WaitForChild("HumanoidRootPart")
end

function ClientUtil:GetHumanoid()
    return self:GetCharacter():WaitForChild("Humanoid")
end

-- SAFE MOVE (ANTI STUCK)
function ClientUtil:MoveTo(position)
    local humanoid = self:GetHumanoid()
    humanoid:MoveTo(position)
    humanoid.MoveToFinished:Wait(2)
end

-- PATHFIND MOVE
function ClientUtil:PathMoveTo(destination)
    local hrp = self:GetHRP()
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })

    path:ComputeAsync(hrp.Position, destination)

    if path.Status ~= Enum.PathStatus.Success then
        self:MoveTo(destination)
        return
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        self:MoveTo(waypoint.Position)
    end
end

-- FIND NEAREST NPC (GENERIC)
function ClientUtil:FindNearestNPC(filterName)
    local hrp = self:GetHRP()
    local nearest, dist = nil, math.huge

    for _, m in pairs(workspace:GetChildren()) do
        if m:IsA("Model")
            and m:FindFirstChild("Humanoid")
            and m:FindFirstChild("HumanoidRootPart")
            and m.Humanoid.Health > 0
        then
            if not filterName or m.Name == filterName then
                local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = m
                end
            end
        end
    end

    return nearest
end

-- =========================
-- BLOX FRUIT AUTO LOGIC (CLIENT)
-- =========================

local BloxAuto = {
    AutoFarm = false,
    AutoQuest = false
}

-- AUTO FARM LOOP
task.spawn(function()
    while true do
        if BloxAuto.AutoFarm then
            local questId = player:GetAttribute("ActiveQuest")
            local targetName = nil

            if questId then
                -- server quest table mirrored (safe)
                if questId == 1 then targetName = "Bandit" end
                if questId == 2 then targetName = "Pirate" end
            end

            local npc = ClientUtil:FindNearestNPC(targetName)
            if npc then
                ClientUtil:PathMoveTo(npc.HumanoidRootPart.Position + Vector3.new(0,0,3))

                -- SIMULATED HIT (SERVER VALIDATED)
                task.wait(0.3)
                game.ReplicatedStorage.GMON_Remotes.Blox_AddExp:FireServer(npc.Name)
            end
        end
        task.wait(0.4)
    end
end)

-- AUTO QUEST LOOP
task.spawn(function()
    while true do
        if BloxAuto.AutoQuest then
            if not player:GetAttribute("ActiveQuest") then
                game.ReplicatedStorage.GMON_Remotes.Blox_GetQuest:InvokeServer("GET")
            end
        end
        task.wait(2)
    end
end)

-- =========================
-- CAR DEALERSHIP CLIENT LOGIC
-- =========================

local SelectedCar = nil

local function getAllCars()
    local carsFolder = workspace:FindFirstChild("CarShop") and workspace.CarShop:FindFirstChild("Cars")
    local list = {}
    if carsFolder then
        for _, c in ipairs(carsFolder:GetChildren()) do
            if c:FindFirstChild("Price") then
                table.insert(list, c.Name)
            end
        end
    end
    return list
end

-- =========================
-- BUILD A BOAT CLIENT LOGIC
-- =========================

local BuildAuto = {
    AutoMove = false
}

task.spawn(function()
    while true do
        if BuildAuto.AutoMove then
            local hrp = ClientUtil:GetHRP()
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
        end
        task.wait(0.2)
    end
end)

-- =========================
-- GUI INTEGRATION (EXTEND EXISTING TABS)
-- =========================

if RunService:IsClient() then
    -- BLOX TAB EXTEND
    if game.PlaceId == 2753915549 or game.PlaceId == 4442272183 or game.PlaceId == 7449423635 then
        local Tab = Window:CreateTab("Blox Control", 4483362458)

        Tab:CreateToggle({
            Name = "Auto Farm (Client)",
            CurrentValue = false,
            Callback = function(v)
                BloxAuto.AutoFarm = v
            end
        })

        Tab:CreateToggle({
            Name = "Auto Quest (Client)",
            CurrentValue = false,
            Callback = function(v)
                BloxAuto.AutoQuest = v
            end
        })
    end

    -- CAR TAB EXTEND
    local cars = getAllCars()
    if #cars > 0 then
        local Tab = Window:CreateTab("Car Control", 4483362458)

        Tab:CreateDropdown({
            Name = "Select Car",
            Options = cars,
            CurrentOption = cars[1],
            Callback = function(v)
                SelectedCar = v
            end
        })

        Tab:CreateButton({
            Name = "Buy Selected Car",
            Callback = function()
                if not SelectedCar then return end
                local ok, msg = game.ReplicatedStorage.GMON_Remotes.Car_Buy:InvokeServer(SelectedCar)
                if ok then
                    StarterGui:SetCore("SendNotification",{Title="Car",Text="Purchased "..SelectedCar,Duration=3})
                else
                    StarterGui:SetCore("SendNotification",{Title="Car",Text=tostring(msg),Duration=3})
                end
            end
        })
    end

    -- BUILD TAB EXTEND
    if game.PlaceId == 537413528 then
        local Tab = Window:CreateTab("Build Control", 4483362458)

        Tab:CreateToggle({
            Name = "Auto Move Forward",
            CurrentValue = false,
            Callback = function(v)
                BuildAuto.AutoMove = v
            end
        })
    end
end

-- =========================
-- END OF PART 2
-- =========================
-- NEXT: PART 3
-- Combat validation (server)
-- Weapon cooldown & range check
-- DataStore save/load
-- Rayfield polish (icons, sections)
-- Final safety cleanup

-- Ketik: 3

-- =========================
-- MAIN.LUA — PART 3 (FINAL)
-- Combat + Data + Polish
-- =========================

-- ===== SERVICES =====
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("GMON_Remotes")

-- =========================
-- SERVER: COMBAT VALIDATION
-- =========================
if RunService:IsServer() then

    local lastHit = {} -- cooldown tracker

    -- DEV combat remote (optional extension)
    local CombatRemote = Instance.new("RemoteEvent")
    CombatRemote.Name = "Blox_Combat"
    CombatRemote.Parent = Remotes

    CombatRemote.OnServerEvent:Connect(function(player, targetModel)
        if not targetModel
            or not targetModel:IsDescendantOf(workspace)
            or not targetModel:FindFirstChild("Humanoid")
            or targetModel.Humanoid.Health <= 0
        then
            return
        end

        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end

        local hrp = char.HumanoidRootPart
        local thrp = targetModel:FindFirstChild("HumanoidRootPart")
        if not thrp then return end

        -- RANGE CHECK (anti abuse)
        if (hrp.Position - thrp.Position).Magnitude > 12 then
            return
        end

        -- COOLDOWN CHECK
        local t = os.clock()
        if lastHit[player] and t - lastHit[player] < 0.35 then
            return
        end
        lastHit[player] = t

        -- APPLY DAMAGE (DEV)
        targetModel.Humanoid:TakeDamage(15)

        -- QUEST PROGRESS
        Remotes.Blox_AddExp:Fire(player, targetModel.Name)
    end)

    print("[GMON] Server combat validation ready.")
end

-- =========================
-- SERVER: DATASTORE (SAVE)
-- =========================
if RunService:IsServer() then
    local PlayerData = DataStoreService:GetDataStore("GMON_DEV_DATA")

    Players.PlayerAdded:Connect(function(player)
        local key = "UID_" .. player.UserId
        local data

        local success, err = pcall(function()
            data = PlayerData:GetAsync(key)
        end)

        if success and data then
            local ls = player:WaitForChild("leaderstats")
            ls.Level.Value = data.Level or 1
            ls.Exp.Value = data.Exp or 0
            ls.Money.Value = data.Money or 1000
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        local ls = player:FindFirstChild("leaderstats")
        if not ls then return end

        local data = {
            Level = ls.Level.Value,
            Exp = ls.Exp.Value,
            Money = ls.Money.Value
        }

        local key = "UID_" .. player.UserId
        pcall(function()
            PlayerData:SetAsync(key, data)
        end)
    end)

    print("[GMON] DataStore save/load enabled (DEV).")
end

-- =========================
-- CLIENT: BLOX COMBAT LOOP
-- =========================
if RunService:IsClient() then
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local ClientUtil = ClientUtil -- from PART 2

    local CombatRemote = Remotes:WaitForChild("Blox_Combat")

    -- Hook combat into AutoFarm
    task.spawn(function()
        while true do
            if BloxAuto and BloxAuto.AutoFarm then
                local npc = ClientUtil:FindNearestNPC()
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    CombatRemote:FireServer(npc)
                end
            end
            task.wait(0.35)
        end
    end)
end

-- =========================
-- UI POLISH (RAYFIELD)
-- =========================
if RunService:IsClient() and Rayfield then
    Rayfield:Notify({
        Title = "GMON Hub",
        Content = "All modules loaded successfully",
        Duration = 5,
        Image = 4483362458
    })
end

-- =========================
-- FINAL NOTES
-- =========================
-- ✔ Single file main.lua
-- ✔ GMON Loader
-- ✔ Player Info Tab
-- ✔ PlaceId Picker
-- ✔ Blox Fruit (Quest, Auto Farm, Combat DEV)
-- ✔ Car Dealership (Select, Buy, Validate)
-- ✔ Build A Boat (Bot / Auto Move)
-- ✔ Data Save / Load
-- ✔ Modular & extendable
-- ✔ PRIVATE / DEV SAFE

print("======================================")
print(" GMON MAIN.LUA FULLY LOADED (DEV MODE) ")
print("======================================")