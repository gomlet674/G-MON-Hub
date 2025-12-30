--[[
  G-MON Hub Exploit - Client Only (Updated)
  - Rayfield GUI
  - Info + Fitur tabs
  - Status realtime (green = ON, red = OFF)
  - Notifications on toggle
  - Save start position when feature ON; restore when OFF
  - Anti AFK, safe pcall
  - Features:
      * Blox Fruit: Auto Farm (by sea/level), Fast Melee (near), Auto Quest (if "Quests" exist)
      * Car Tycoon: Auto Drive (choose fastest car), store/restore car pos
      * Build A Boat: Auto Gold (stage->stage), store/restore player pos
  - CLIENT ONLY. Use in private/testing places only.
]]


-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local LP = Players.LocalPlayer

-- ===== Anti AFK =====
LP.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

-- ===== Helpers =====
local function SafeChar()
    local ok, c = pcall(function() return LP.Character end)
    if not ok or not c then return nil end
    if c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then return c end
    return nil
end

local function FindFolderByNames(list)
    for _, name in ipairs(list) do
        local f = Workspace:FindFirstChild(name)
        if f then return f end
    end
    return nil
end

local function formatTime(sec)
    sec = math.max(0, math.floor(sec or 0))
    local h = math.floor(sec/3600); local m = math.floor((sec%3600)/60); local s = sec%60
    if h>0 then return string.format("%02dh:%02dm:%02ds", h,m,s) end
    return string.format("%02dm:%02ds", m,s)
end

-- ===== Game detection (adjust PlaceId if needed) =====
local GAME = "UNKNOWN"
local place = game.PlaceId
if place == 2753915549 then
    GAME = "BLOX_FRUIT"
elseif place == 1554960397 then
    GAME = "CAR_TYCOON"
elseif place == 537413528 then
    GAME = "BUILD_A_BOAT"
end

-- ===== Load Rayfield (safe) =====
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok or not Rayfield then
    warn("[G-MON] Failed to load Rayfield.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "G-MON Hub",
    LoadingTitle = "G-MON Hub",
    LoadingSubtitle = GAME,
    ConfigurationSaving = { Enabled = false }
})

local InfoTab = Window:CreateTab("Info")
local FiturTab = Window:CreateTab("Fitur")

-- ===== Status Screen GUI =====
local function createStatusGui()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GmonStatusGui"
    sg.ResetOnSpawn = false
    sg.Parent = LP:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "StatusFrame"
    frame.Size = UDim2.new(0, 300, 0, 170)
    frame.Position = UDim2.new(1, -310, 0, 10)
    frame.BackgroundTransparency = 0.12
    frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -16, 0, 24)
    title.Position = UDim2.new(0,8,0,6)
    title.BackgroundTransparency = 1
    title.Text = "G-MON Status"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16

    local sub = Instance.new("TextLabel", frame)
    sub.Size = UDim2.new(1, -16, 0, 18)
    sub.Position = UDim2.new(0,8,0,30)
    sub.BackgroundTransparency = 1
    sub.Text = GAME
    sub.TextColor3 = Color3.fromRGB(200,200,200)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Font = Enum.Font.SourceSans
    sub.TextSize = 12

    local function makeLine(y)
        local holder = Instance.new("Frame", frame)
        holder.Size = UDim2.new(1, -16, 0, 20)
        holder.Position = UDim2.new(0,8,0,y)
        holder.BackgroundTransparency = 1

        local dot = Instance.new("Frame", holder)
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = UDim2.new(0, 0, 0, 4)
        dot.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- red default
        dot.Name = "Indicator"

        local lbl = Instance.new("TextLabel", holder)
        lbl.Size = UDim2.new(1, -18, 1, 0)
        lbl.Position = UDim2.new(0, 18, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = ""
        lbl.TextColor3 = Color3.fromRGB(230,230,230)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 12

        return {holder = holder, dot = dot, lbl = lbl}
    end

    local lines = {}
    lines.runtime = makeLine(52)
    lines.bf = makeLine(74)
    lines.car = makeLine(96)
    lines.boat = makeLine(118)
    lines.last = makeLine(140)

    -- initial text
    lines.runtime.lbl.Text = "Runtime: 00m:00s"
    lines.bf.lbl.Text = "Blox: OFF"
    lines.car.lbl.Text = "Car: OFF"
    lines.boat.lbl.Text = "Boat: OFF"
    lines.last.lbl.Text = "Last: Idle"

    return {gui = sg, frame = frame, lines = lines}
end

local status = createStatusGui()

-- ===== Runtime tracking =====
local startTime = os.time()
local BF_active_start, BF_total = nil, 0
local BFFast_active_start, BFFast_total = nil, 0
local CAR_active_start, CAR_total = nil, 0
local BOAT_active_start, BOAT_total = nil, 0

local function getActiveTime(startT, total)
    if startT then return total + (os.time() - startT) end
    return total
end

-- ===== Feature states & start positions =====
local BF_Auto, BF_Fast, BF_Quest = false, false, false
local BF_start_CFrame = nil

local CAR_Auto = false
local chosenCarModel = nil
local CAR_start_CFrame = nil
local CAR_start_taggedModel = nil

local BOAT_Auto = false
local BOAT_start_CFrame = nil

local lastAction = "Idle"
local currentSeaTarget = "N/A"

-- ===== small helper to set indicator color & label =====
local function setIndicator(name, on, text)
    local ln = status.lines[name]
    if not ln then return end
    if on then
        ln.dot.BackgroundColor3 = Color3.fromRGB(0,200,0)
    else
        ln.dot.BackgroundColor3 = Color3.fromRGB(200,0,0)
    end
    if text then ln.lbl.Text = text end
end

-- ===== Rayfield controls (Info + Fitur) =====
InfoTab:CreateLabel("G-MON Hub - client-only. Use only in private/testing places.")
InfoTab:CreateButton({
    Name = "Show Quick Help",
    Callback = function()
        if GAME == "BLOX_FRUIT" then
            Rayfield:Notify({Title="Help - Blox", Content="Auto Farm: ON -> teleport ke NPC & try melee hits. Fast Melee: spam melee (near). Auto Quest: try detect 'Quests' folder and move to quest NPC.", Duration=5})
        elseif GAME == "CAR_TYCOON" then
            Rayfield:Notify({Title="Help - Car", Content="Auto Drive: choose fastest car and move forward. Script stores start pos and returns when OFF.", Duration=5})
        elseif GAME == "BUILD_A_BOAT" then
            Rayfield:Notify({Title="Help - Boat", Content="Auto Gold: teleport stage-by-stage to triggers/chests. Stores start pos and returns when OFF.", Duration=5})
        else
            Rayfield:Notify({Title="Help", Content="PlaceId not supported by default.", Duration=5})
        end
    end
})

-- ===== Fitur tab controls =====
-- BLOX controls
local BF_attack_delay = 0.35
local BF_force_sea = nil

if GAME == "BLOX_FRUIT" then
    FiturTab:CreateToggle({
        Name = "Auto Farm (by sea/level)",
        CurrentValue = false,
        Callback = function(v)
            BF_Auto = v
            if v then
                BF_start_CFrame = (SafeChar() and SafeChar().HumanoidRootPart.CFrame) or nil
                Rayfield:Notify({Title="G-MON", Content="Blox AutoFarm ENABLED", Duration=3})
                setIndicator("bf", true, "Blox: ON")
                BF_active_start = BF_active_start or os.time()
            else
                Rayfield:Notify({Title="G-MON", Content="Blox AutoFarm DISABLED - returning to start", Duration=3})
                -- restore pos
                pcall(function()
                    local c = SafeChar()
                    if c and BF_start_CFrame then c.HumanoidRootPart.CFrame = BF_start_CFrame end
                end)
                setIndicator("bf", false, "Blox: OFF")
                if BF_active_start then BF_total = BF_total + (os.time() - BF_active_start); BF_active_start = nil end
            end
        end
    })

    FiturTab:CreateToggle({
        Name = "Fast Melee (near only)",
        CurrentValue = false,
        Callback = function(v)
            BF_Fast = v
            if v then
                Rayfield:Notify({Title="G-MON", Content="Fast Melee ENABLED", Duration=2})
                setIndicator("bf", true, "Blox: ON | Fast")
                BFFast_active_start = BFFast_active_start or os.time()
            else
                Rayfield:Notify({Title="G-MON", Content="Fast Melee DISABLED", Duration=2})
                -- keep BF indicator state depending BF_Auto
                setIndicator("bf", BF_Auto, BF_Auto and "Blox: ON" or "Blox: OFF")
                if BFFast_active_start then BFFast_total = BFFast_total + (os.time() - BFFast_active_start); BFFast_active_start = nil end
            end
        end
    })

    FiturTab:CreateToggle({
        Name = "Auto Quest (try detect 'Quests')",
        CurrentValue = false,
        Callback = function(v)
            BF_Quest = v
            if v then
                Rayfield:Notify({Title="G-MON", Content="Auto Quest ENABLED", Duration=3})
                setIndicator("bf", true, "Blox: ON | Quest")
                -- store position
                BF_start_CFrame = (SafeChar() and SafeChar().HumanoidRootPart.CFrame) or BF_start_CFrame
            else
                Rayfield:Notify({Title="G-MON", Content="Auto Quest DISABLED - returning to start", Duration=3})
                pcall(function()
                    local c = SafeChar()
                    if c and BF_start_CFrame then c.HumanoidRootPart.CFrame = BF_start_CFrame end
                end)
                setIndicator("bf", BF_Auto, BF_Auto and "Blox: ON" or "Blox: OFF")
            end
        end
    })

    FiturTab:CreateSlider({
        Name = "Attack Delay (ms)",
        Range = {100,1000},
        Increment = 50,
        CurrentValue = math.floor(BF_attack_delay*1000),
        Callback = function(v) BF_attack_delay = v/1000 end
    })

    FiturTab:CreateSlider({
        Name = "Override Target Sea (0=auto)",
        Range = {0,3},
        Increment = 1,
        CurrentValue = 0,
        Callback = function(v) BF_force_sea = (v==0) and nil or v end
    })
end

-- CAR controls
local CAR_step = 14
if GAME == "CAR_TYCOON" then
    FiturTab:CreateToggle({
        Name = "Auto Drive (choose fastest)",
        CurrentValue = false,
        Callback = function(v)
            CAR_Auto = v
            if v then
                -- choose car now
             -- ===== Car: pilih & jalankan mobil milik player (ganti bagian lama) =====

-- Helper: cari model mobil milik player
local function findPlayerCarsRoot()
    local carsRoot = workspace:FindFirstChild("Cars")
    if not carsRoot then return nil end
    local own = carsRoot:FindFirstChild(game.Players.LocalPlayer.Name)
    if own then
        if own:IsA("Model") and own.PrimaryPart then
            return {own}
        elseif own:IsA("Folder") or own:IsA("Model") then
            local list = {}
            for _, v in ipairs(own:GetChildren()) do
                if v:IsA("Model") and v.PrimaryPart then table.insert(list, v) end
            end
            if #list > 0 then return list end
        end
    end
    return nil
          end

    -- 2) fallback: cari mobil yang punya tag Owner / OwnerUserId / OwnerName
    local owned = {}
    for _, m in ipairs(carsRoot:GetChildren()) do
        if m:IsA("Model") and m.PrimaryPart then
            -- check StringValue / IntValue owners
            local ownerStr = m:FindFirstChild("Owner") or m:FindFirstChild("OwnerName")
            local ownerIdVal = m:FindFirstChild("OwnerUserId") or m:FindFirstChild("UserId")
            local matched = false
            if ownerStr and ownerStr.Value and tostring(ownerStr.Value) == tostring(game.Players.LocalPlayer.Name) then matched = true end
            if ownerIdVal and tonumber(ownerIdVal.Value) and tonumber(ownerIdVal.Value) == game.Players.LocalPlayer.UserId then matched = true end
            -- attribute check
            if not matched then
                local attrOwner = m:GetAttribute("Owner") or m:GetAttribute("OwnerName")
                if attrOwner and tostring(attrOwner) == tostring(game.Players.LocalPlayer.Name) then matched = true end
                local attrId = m:GetAttribute("OwnerUserId")
                if attrId and tonumber(attrId) == game.Players.LocalPlayer.UserId then matched = true end
            end
            if matched then table.insert(owned, m) end
        end
    end
    if #owned > 0 then return owned end

    -- 3) last resort: jika ada model bernama sama dengan player
    for _, m in ipairs(carsRoot:GetChildren()) do
        if m:IsA("Model") and m.PrimaryPart and m.Name == game.Players.LocalPlayer.Name then
            return {m}
        end
    end

    return nil
end

-- Pilih mobil TERCEPAT dari daftar model (heuristic)
local function choosePlayerFastestCar()
    local list = findPlayerCarsRoot()
    if not list or #list == 0 then return nil end
    local best, bestVal = nil, -math.huge
    for _, car in ipairs(list) do
        -- prefer NumberValue TopSpeed/Speed/MaxSpeed
        local top = car:FindFirstChild("TopSpeed") or car:FindFirstChild("Speed") or car:FindFirstChild("MaxSpeed")
        local v = nil
        if top and tonumber(top.Value) then v = tonumber(top.Value) end
        if not v then
            -- fallback: jumlah parts/descendants
            v = #car:GetDescendants()
        end
        if v > bestVal then bestVal, best = v, car end
    end
    return best
end

-- Car run controller (dipanggil dari loop utama CAR_Auto)
local function startUsingPlayerCar(stepDistance, underMapY)
    underMapY = underMapY or -500
    local car = choosePlayerFastestCar()
    if not car or not car.PrimaryPart then
        lastAction = "No owned car found"
        return nil
    end

    -- simpan start pos
    if not car:FindFirstChild("_GmonStartPos") then
        local tag = Instance.new("CFrameValue")
        tag.Name = "_GmonStartPos"
        tag.Value = car.PrimaryPart.CFrame
        tag.Parent = car
    end

    -- teleport car ke bawah map (jaga X,Z supaya di area aman)
    local ok, origCF = pcall(function() return car.PrimaryPart.CFrame end)
    if ok and origCF then
        local targetCF = CFrame.new(origCF.Position.X, underMapY, origCF.Position.Z) * CFrame.new(0,0,0)
        pcall(function() car:SetPrimaryPartCFrame(targetCF) end)
    end

    -- coba seat player if seat exists
    local seat = nil
    for _, obj in ipairs(car:GetDescendants()) do
        if obj:IsA("VehicleSeat") then seat = obj; break end
    end
    if seat and SafeChar() then
        pcall(function()
            SafeChar().HumanoidRootPart.CFrame = seat.CFrame * CFrame.new(0,2,0)
        end)
    end

    return car
end

-- restore function
local function restorePlayerCar(car)
    if not car or not car.PrimaryPart then return end
    local tag = car:FindFirstChild("_GmonStartPos")
    if tag and tag:IsA("CFrameValue") then
        pcall(function() car:SetPrimaryPartCFrame(tag.Value) end)
        tag:Destroy()
    end
end

-- BOAT controls
local BOAT_delay = 1.5
if GAME == "BUILD_A_BOAT" then
    FiturTab:CreateToggle({
        Name = "Auto Gold Stages",
        CurrentValue = false,
        Callback = function(v)
            BOAT_Auto = v
            if v then
                BOAT_start_CFrame = (SafeChar() and SafeChar().HumanoidRootPart.CFrame) or nil
                Rayfield:Notify({Title="G-MON", Content="Boat Auto ENABLED", Duration=3})
                setIndicator("boat", true, "Boat: ON")
                BOAT_active_start = BOAT_active_start or os.time()
            else
                Rayfield:Notify({Title="G-MON", Content="Boat Auto DISABLED - returning to start", Duration=3})
                pcall(function()
                    local c = SafeChar()
                    if c and BOAT_start_CFrame then c.HumanoidRootPart.CFrame = BOAT_start_CFrame end
                end)
                setIndicator("boat", false, "Boat: OFF")
                if BOAT_active_start then BOAT_total = BOAT_total + (os.time() - BOAT_active_start); BOAT_active_start = nil end
            end
        end
    })

    FiturTab:CreateSlider({
        Name = "Stage Delay (s)",
        Range = {0.5,6},
        Increment = 0.5,
        CurrentValue = BOAT_delay,
        Callback = function(v) BOAT_delay = v end
    })
end

-- ===== Core loops =====

-- BF Loop
task.spawn(function()
    while true do
        task.wait(0.12)
        if GAME ~= "BLOX_FRUIT" then task.wait(0.5); continue end
        if not (BF_Auto or BF_Quest or BF_Fast) then continue end
        pcall(function()
            local char = SafeChar()
            if not char then return end
            local hrp = char.HumanoidRootPart

            -- If Auto Quest is on: try find "Quests" and go there (simple)
            if BF_Quest then
                local qfolder = Workspace:FindFirstChild("Quests") or FindFolderByNames({"Quests","QuestGiver","NPCQuests"})
                if qfolder then
                    -- pick first quest giver or part
                    local qtarget = nil
                    for _, obj in ipairs(qfolder:GetDescendants()) do
                        if obj:IsA("BasePart") then qtarget = obj; break end
                    end
                    if qtarget then
                        hrp.CFrame = qtarget.CFrame * CFrame.new(0,3,0)
                        lastAction = "Goto Quest: "..(qtarget.Name or "quest")
                        task.wait(1)
                        return
                    end
                else
                    -- no quest folder found - notify once
                    Rayfield:Notify({Title="G-MON", Content="No 'Quests' folder detected.", Duration=3})
                    BF_Quest = false
                    setIndicator("bf", BF_Auto, BF_Auto and "Blox: ON" or "Blox: OFF")
                    return
                end
            end

            -- Auto Farm logic (find sea target)
            if BF_Auto then
                local targetSea = BF_force_sea
                if not targetSea then
                    local lvl = (LP:FindFirstChild("leaderstats") and LP.leaderstats:FindFirstChild("Level") and LP.leaderstats.Level.Value) or 0
                    if lvl < 10 then targetSea = 1 elseif lvl < 30 then targetSea = 2 else targetSea = 3 end
                end
                currentSeaTarget = tostring(targetSea)

                local seaNames = {
                    [1] = {"Enemies","Sea1Enemies","Monsters","Mobs"},
                    [2] = {"Sea2Enemies","Enemies2","Monsters2"},
                    [3] = {"Sea3Enemies","Bosses","EndEnemies"}
                }
                local folder = FindFolderByNames(seaNames[targetSea] or {"Enemies"})
                if not folder then return end

                -- find nearest mob
                local nearest, bestDist = nil, math.huge
                for _, mob in ipairs(folder:GetChildren()) do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                        local hum = mob:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if d < bestDist then bestDist, nearest = d, mob end
                        end
                    end
                end
                if not nearest then return end

                -- teleport near + melee
                hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                if BF_Fast then
                    for i=1,3 do
                        pcall(function()
                            if nearest and nearest:FindFirstChild("Humanoid") then
                                nearest.Humanoid:TakeDamage(20)
                            end
                        end)
                    end
                    lastAction = "FastMelee -> "..tostring(nearest.Name or "mob")
                else
                    pcall(function()
                        if nearest and nearest:FindFirstChild("Humanoid") then
                            nearest.Humanoid:TakeDamage(15)
                        end
                    end)
                    lastAction = "Melee -> "..tostring(nearest.Name or "mob")
                end

                task.wait(BF_attack_delay or 0.35)
            end
        end)
    end
end)

-- CAR Loop
task.spawn(function()
    while task.wait(0.12) do
        if not CAR_Auto then
            task.wait(0.5)
            continue
        end
        pcall(function()
            
            -- choose fastest available car (heuristic)
            local carsRoot = Workspace:FindFirstChild("Cars")
            if not carsRoot then return end
            local best, bestVal = nil, -math.huge
            for _, m in ipairs(carsRoot:GetChildren()) do
                if m:IsA("Model") and m.PrimaryPart then
                    local top = m:FindFirstChild("TopSpeed") or m:FindFirstChild("Speed") or m:FindFirstChild("MaxSpeed")
                    local v = nil
                    if top and tonumber(top.Value) then v = tonumber(top.Value) else v = #m:GetDescendants() end
                    if v and v > bestVal then bestVal, best = v, m end
                end
            end
            if not best then return end
            chosenCarModel = best
            -- store start pos if not stored
            if chosenCarModel and chosenCarModel.PrimaryPart and not chosenCarModel:FindFirstChild("_GmonStartPos") then
                local tag = Instance.new("CFrameValue")
                tag.Name = "_GmonStartPos"
                tag.Value = chosenCarModel.PrimaryPart.CFrame
                tag.Parent = chosenCarModel
                CAR_start_CFrame = tag.Value
            end
            -- attempt to seat player near seat
            local seat = nil
            for _, obj in ipairs(chosenCarModel:GetDescendants()) do
                if obj:IsA("VehicleSeat") then seat = obj; break end
            end
            if seat and SafeChar() then
                pcall(function()
                    SafeChar().HumanoidRootPart.CFrame = seat.CFrame * CFrame.new(0,2,0)
                end)
            end
            -- move car forward (snap)
            local ok, cf = pcall(function() return chosenCarModel.PrimaryPart.CFrame end)
            if ok and cf then
                chosenCarModel:SetPrimaryPartCFrame(cf * CFrame.new(0,0,-(CAR_step or 14)))
                lastAction = "Car -> "..tostring(chosenCarModel.Name)
            end
        end)
    end
end)

-- restore car when disabled (handled in toggle callback - but ensure here too)
-- already part of toggle: we restore when CAR_Auto set to false

-- BOAT Loop
task.spawn(function()
    while true do
        task.wait(0.2)
        if GAME ~= "BUILD_A_BOAT" then task.wait(0.5); continue end
        if not BOAT_Auto then continue end
        pcall(function()
            local char = SafeChar()
            if not char then return end
            local stagesRoot = Workspace:FindFirstChild("BoatStages") or Workspace:FindFirstChild("Stages")
            if not stagesRoot then return end
            local normal = stagesRoot:FindFirstChild("NormalStages") or stagesRoot
            local triggers = {}
            for _, obj in ipairs(normal:GetDescendants()) do
                if obj:IsA("BasePart") and (string.find(string.lower(obj.Name),"trigger") or string.find(string.lower(obj.Name),"chest")) then
                    table.insert(triggers, obj)
                end
            end
            if #triggers == 0 then
                for _, c in ipairs(normal:GetChildren()) do
                    local p = c:IsA("BasePart") and c or (c.PrimaryPart and c.PrimaryPart)
                    if p then table.insert(triggers, p) end
                end
            end
            if #triggers == 0 then return end
            table.sort(triggers, function(a,b) return a.Position.Z < b.Position.Z end)
            for _, trg in ipairs(triggers) do
                if not BOAT_Auto then break end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = trg.CFrame * CFrame.new(0,3,0)
                    lastAction = "Boat -> "..tostring(trg.Name)
                end
                task.wait(BOAT_delay or 1.5)
            end
        end)
    end
end)

-- ===== Status updater & indicator logic =====
local function updateIndicators()
    -- runtime
    local elapsed = os.time() - startTime
    status.lines.runtime.lbl.Text = "Runtime: "..formatTime(elapsed)
    -- BF
    local bfText = "Blox: "..(BF_Auto and "ON" or "OFF")
    if BF_Fast then bfText = bfText.." | Fast" end
    if BF_Quest then bfText = bfText.." | Quest" end
    status.lines.bf.lbl.Text = bfText
    setIndicator("bf", BF_Auto or BF_Fast or BF_Quest, bfText)
    -- Car
    local carText = "Car: "..(CAR_Auto and "ON" or "OFF")
    if chosenCarModel then carText = carText.." | "..tostring(chosenCarModel.Name) end
    status.lines.car.lbl.Text = carText
    setIndicator("car", CAR_Auto, carText)
    -- Boat
    status.lines.boat.lbl.Text = "Boat: "..(BOAT_Auto and "ON" or "OFF")
    setIndicator("boat", BOAT_Auto, "Boat: "..(BOAT_Auto and "ON" or "OFF"))
    -- last action
    status.lines.last.lbl.Text = "Last: "..tostring(lastAction or "Idle")
end

task.spawn(function()
    while true do
        task.wait(1)
        pcall(updateIndicators)
    end
end)

-- ===== Final notify =====
Rayfield:Notify({Title="G-MON Hub", Content="Loaded — indicators & restore-on-off active", Duration=5})
