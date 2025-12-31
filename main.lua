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
    lines.runtime.lbl.Text = "Runtime: 00h:00m:00s"
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

-- tambahan variabel BF
local BF_range = 10            -- default jarak (studs)
local BF_long_range = false    -- serang dari jauh (tanpa teleport)
local BF_fast_attack = false
local BF_attack_delay_backup = BF_attack_delay -- akan di-set ketika fast attack on

-- Tambahkan UI controls (paste ini di dalam 'if GAME == "BLOX_FRUIT" then' bersama FiturTab)
FiturTab:CreateSlider({
    Name = "Range Farming (studs) 1-20",
    Range = {1,20},
    Increment = 1,
    CurrentValue = BF_range,
    Callback = function(v) BF_range = v end
})

FiturTab:CreateToggle({
    Name = "Long Range Hit (serang tanpa teleport)",
    CurrentValue = false,
    Callback = function(v)
        BF_long_range = v
        if v then
            Rayfield:Notify({Title="G-MON", Content="Long Range Hit ON", Duration=2})
        else
            Rayfield:Notify({Title="G-MON", Content="Long Range Hit OFF", Duration=2})
        end
        -- update indikator (menjaga konsistensi)
        setIndicator("bf", BF_Auto or BF_Fast or BF_Quest or BF_long_range, nil)
    end
})

FiturTab:CreateToggle({
    Name = "Fast Attack (percepat pukulan)",
    CurrentValue = false,
    Callback = function(v)
        BF_fast_attack = v
        if v then
            -- simpan backup lalu kurangi delay
            BF_attack_delay_backup = BF_attack_delay
            BF_attack_delay = math.max(0.03, BF_attack_delay_backup * 0.25) -- sangat cepat, tapi aman minimal 30ms
            Rayfield:Notify({Title="G-MON", Content="Fast Attack ENABLED", Duration=2})
        else
            -- restore
            BF_attack_delay = BF_attack_delay_backup or 0.35
            Rayfield:Notify({Title="G-MON", Content="Fast Attack DISABLED", Duration=2})
        end
    end
})

-- CAR controls
if GAME == "CAR_DEALERSHIP_TYCOON" then
    FiturTab:CreateTiggle({
            Name = "Auto Farm Money", 
            CurrentValue = false, 
            Callback = function(v) 
          Car_Auto = v
            if v then      
                    
local CAR_speed : 60
nStart menggunakan mobil milik player: pasang floor baawa, simulasikan 'W' via  BodyVelcityocal --
              
    function startUsingPlayerCar(underMap   underrMpYY =underMMapY r -500
    local car = choosePlayerrFsstetCar(()    if not car or nott ca.PrimaryPart then
         lastAction = "N owned car found"
        Rayfieeld:Notfy({Title=="G-MON", Content="No owne car found  CDT)", Duraation=}})
        eturn nil
    end

    chosenCarrModel = car

-- Simpan osisii wwalsekalili
  ifinotot caar:FindFirstChid"_GonStartPoos"s") hen
      localal taag = Instancene"CFrameValue"e")
         tag.Name"_GmonStartPos"s"
        tag.Value = car.PrimaryPart.CFrame
        tag.Parent = car
        CAR_start_CFramee = ag.Value

  elsese
      -- update local var jga jika ssudahadada
      localal tag = caar:FindFirstChi"_GmonSttatPos"")")
     ifif tathenen CAR_start_CFFrae = ttagVa  -- Teleport mobil ke bawah map (tetap jaga X,Z)Z)
  localal ok, origCF = pcalfunctionon(returnrn car.PrimaryPart.CFramendnd)
       localal targetCF = CFrame.new(origCF.Position.X, underMapY, origCF.Position.Z)
        pcalfunctionon() car:SetPrimaryPartCFrame(targetCFendnd)
  endnd

  -- Buat floor di bawah agar mobil punya ground untuk berjalanan
  ifinotot car:GetAttribut"GmonFloor"r"thenen
      localal floor = Instance.ne"Part"t")
        floor.Name "_GmonFloor_GMON"N"
        floor.Size = Vector3.ne300002 230000)
        floor.Position = Vector3.new(origCF.Position.X, underMapY 1 1, origCF.Position.Z)
        floor.Anchored trueue
        floor.CanCollide trueu        floor.TopSurface = Enum.SurfaceType.Smooth
        floor.Material = Enum.Material.SmoothPlastic
        floor.Transparency = 0.15
        floor.Parent = Workspace
        car:SetAttribute("GmonFloor", true)
        -- simpan ref di model untuk hapus nanti
        local fv = Instance.new("ObjectValue")
        fv.Name = "_GmonFloorRef"
        fv.Value = floor
        fv.Parent = car
    end

    -- Pastikan player duduk/berada dekat kursi (visual)
    if SafeChar() then
        for _, obj in ipairs(car:GetDescendants()) do
            if obj:IsA("VehicleSeat") then
                pcall(function()
                    SafeChar().HumanoidRootPart.CFrame = obj.CFrame * CFrame.new(0,2,0)
                end)
                break
            end
        end
    end

    -- Pasang BodyVelocity pada PrimaryPart (jika belum ada)
    if car.PrimaryPart and not car.PrimaryPart:FindFirstChild("_GmonBV") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "_GmonBV"
        bv.MaxForce = Vector3.new(1e5, 0, 1e5) -- hanya XZ (agar tidak mengangkat)
        bv.Velocity = car.PrimaryPart.CFrame.LookVector * CAR_speed
        bv.P = 1250
        bv.Parent = car.PrimaryPart
    else
        -- update velocity awal
        pcall(function()
            if car.PrimaryPart and car.PrimaryPart:FindFirstChild("_GmonBV") then
                car.PrimaryPart._GmonBV.Velocity = car.PrimaryPart.CFrame.LookVector * CAR_speed
            end
        end)
    end

    lastAction = "Using car (CDT): "..tostring(car.Name)
    return car
end

-- Stop / restore mobil
local function stopUsingPlayerCar()
    if not chosenCarModel then return end
    pcall(function()
        -- hapus BodyVelocity
        if chosenCarModel.PrimaryPart and chosenCarModel.PrimaryPart:FindFirstChild("_GmonBV") then
            chosenCarModel.PrimaryPart._GmonBV:Destroy()
        end
        -- kembalikan ke pos awal jika ada
        local tag = chosenCarModel:FindFirstChild("_GmonStartPos")
        if tag and tag:IsA("CFrameValue") and chosenCarModel.PrimaryPart then
            chosenCarModel:SetPrimaryPartCFrame(tag.Value)
            -- optional: hapus tag jika mau
            pcall(function() tag:Destroy() end)
        end
        -- hapus floor ref jika ada
        local fv = chosenCarModel:FindFirstChild("_GmonFloorRef")
        if fv and fv.Value and fv.Value.Parent then
            fv.Value:Destroy()
        end
        -- hapus atribut floor
        if chosenCarModel:GetAttribute("GmonFloor") then chosenCarModel:SetAttribute("GmonFloor", nil)
      end
    end)
    lastAction = "Car restored"
    chosenCarModel = nil
    CAR_start_CFrame = nil
end
   --- BOAT controls ---
-- ===== BOAT: Auto Gold Stages (ganti blok BOAT lama dengan ini) =====
-- pastikan BOAT_delay sudah dideklarasikan di atas (default 1.5)
if GAME == "BUILD_A_BOAT" then 
BOAT_delay = BOAT_delay or 1.5

local function isDarkPart(part)
    if not part or not part:IsA("BasePart") then return false end
    -- BrickColor check (Really black) OR color brightness check (gelap)
    local ok, name = pcall(function() return part.BrickColor.Name end)
    if ok and (name == "Really black" or name == "Black") then return true end
    local col = part.Color
    local brightness = (col.R + col.G + col.B) / 3
    if brightness < 0.2 then return true end
    return false
end

local function collectBoatStages(root)
    local stages = {}
    if not root then return stages end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("BasePart") then
            local lname = string.lower(obj.Name or "")
            if isDarkPart(obj) or string.find(lname, "stage") or string.find(lname, "black") or string.find(lname, "dark") or string.find(lname, "trigger") then
                table.insert(stages, obj)
            end
        end
    end
    return stages
end

-- Find final chest (common names)
local function findNearestChestFrom(pos)
    local candidates = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local lname = string.lower(v.Name or "")
            if string.find(lname, "chest") or string.find(lname, "treasure") or string.find(lname, "golden") then
                table.insert(candidates, v)
            end
        elseif v:IsA("Model") and v.PrimaryPart then
            local lname = string.lower(v.Name or "")
            if string.find(lname, "chest") or string.find(lname, "treasure") or string.find(lname, "golden") then
                table.insert(candidates, v.PrimaryPart)
            end
        end
    end
    if #candidates == 0 then return nil end
    table.sort(candidates, function(a,b)
        return (a.Position - pos).Magnitude < (b.Position - pos).Magnitude
    end)
    return candidates[1]
end

-- Toggle (UI) — ganti bagian FiturTab:CreateToggle BOAT dengan ini (atau paste callback body)
if GAME == "BUILD_A_BOAT" then
    -- replace existing toggle/slider if present
    FiturTab:CreateToggle({
        Name = "Auto Gold Stages",
        CurrentValue = false,
        Callback = function(v)
            BOAT_Auto = v
            if v then
                -- simpan posisi awal pemain
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

-- BOAT main navigator (replace old BOAT loop)
task.spawn(function()
    while true do
        task.wait(0.2)
        if GAME ~= "BUILD_A_BOAT" then task.wait(0.5); continue end
        if not BOAT_Auto then task.wait(0.5); continue end
        pcall(function()
            local char = SafeChar()
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- collect candidate stage parts from likely roots
            local boatRoots = {}
            local hints = {"BoatStages","Stages","NormalStages","StageFolder","BoatStage"}
            for _, name in ipairs(hints) do
                local r = Workspace:FindFirstChild(name)
                if r then table.insert(boatRoots, r) end
            end
            -- fallback: whole workspace
            if #boatRoots == 0 then table.insert(boatRoots, Workspace) end

            -- gather dark stage parts
            local stages = {}
            for _, root in ipairs(boatRoots) do
                local s = collectBoatStages(root)
                for _, p in ipairs(s) do table.insert(stages, p) end
            end
            if #stages == 0 then
                -- if no dark stages found, try parts named 'Stage'
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(string.lower(obj.Name or ""), "stage") then
                        table.insert(stages, obj)
                    end
                end
            end
            if #stages == 0 then
                -- nothing to do
                Rayfield:Notify({Title="G-MON", Content="No black stage parts detected", Duration=3})
                BOAT_Auto = false
                setIndicator("boat", false, "Boat: OFF")
                return
            end

            -- deduplicate by position (simple)
            local seen = {}
            local uniq = {}
            for _, p in ipairs(stages) do
                local key = string.format("%.2f_%.2f_%.2f", p.Position.X, p.Position.Y, p.Position.Z)
                if not seen[key] then seen[key] = true; table.insert(uniq, p) end
            end
            stages = uniq

            -- sort stages by distance from starting point (BOAT_start_CFrame or player start)
            local referencePos = (BOAT_start_CFrame and BOAT_start_CFrame.p) or hrp.Position
            table.sort(stages, function(a,b)
                return (a.Position - referencePos).Magnitude < (b.Position - referencePos).Magnitude
            end)

            -- visit each stage in order
            for i, stagePart in ipairs(stages) do
                if not BOAT_Auto then break end
                if not stagePart or not stagePart.Parent then continue end
                -- teleport player to just above the stage part
                pcall(function()
                    if hrp and stagePart and stagePart:IsA("BasePart") then
                        hrp.CFrame = stagePart.CFrame * CFrame.new(0,3,0)
                        lastAction = "Boat Stage -> "..tostring(stagePart.Name)
                    end
                end)
                task.wait(BOAT_delay or 1.5)
            end

            -- after visiting stages, find nearest chest and teleport there
            local finalChest = findNearestChestFrom(hrp.Position)
            if finalChest then
                pcall(function()
                    hrp.CFrame = finalChest.CFrame * CFrame.new(0,3,0)
                    lastAction = "Boat Chest -> "..tostring(finalChest.Name)
                    Rayfield:Notify({Title="G-MON", Content="Reached chest", Duration=3})
                end)
            else
                Rayfield:Notify({Title="G-MON", Content="No chest found after stages", Duration=3})
            end

            -- optionally stop auto after chest reached
            -- BOAT_Auto = false
        end)
    end
end)

-- ===== Core loops =====

-- BF Loop
-- ===== BF Loop (UPDATE: support BF_range, BF_long_range, BF_fast_attack) =====
task.spawn(function()
    while true do
        task.wait(0.12)
        if GAME ~= "BLOX_FRUIT" then task.wait(0.5); continue end
        if not (BF_Auto or BF_Quest or BF_Fast) then continue end
        pcall(function()
            local char = SafeChar()
            if not char then return end
            local hrp = char.HumanoidRootPart

            -- Auto Quest handler (tetap sama)
            if BF_Quest then
                local qfolder = Workspace:FindFirstChild("Quests") or FindFolderByNames({"Quests","QuestGiver","NPCQuests"})
                if qfolder then
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
                    Rayfield:Notify({Title="G-MON", Content="No 'Quests' folder detected.", Duration=3})
                    BF_Quest = false
                    setIndicator("bf", BF_Auto, BF_Auto and "Blox: ON" or "Blox: OFF")
                    return
                end
            end

            -- Auto Farm logic
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

                -- find nearest mob within BF_range (studs)
                local nearest, bestDist = nil, math.huge
                for _, mob in ipairs(folder:GetChildren()) do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                        local hum = mob:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if d < bestDist and d <= (BF_range or 10) then bestDist, nearest = d, mob end
                        end
                    end
                end
                if not nearest then
                    -- jika tidak ada di range, tapi long_range aktif, mungkin cari target terdekat tanpa batas agar bisa serang jauh
                    if BF_long_range then
                        for _, mob in ipairs(folder:GetChildren()) do
                            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                                local hum = mob:FindFirstChild("Humanoid")
                                if hum and hum.Health > 0 then
                                    local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                                    if d < bestDist then bestDist, nearest = d, mob end
                                end
                            end
                        end
                    end
                end
                if not nearest then return end

                -- ACTION: jika Long Range aktif -> serang dari jauh tanpa teleport
                if BF_long_range then
                    -- hit power: pakai nilai dasar, bisa disesuaikan
                    local dmg = BF_Fast and 35 or 20
                    -- lakukan beberapa hit kalau BF_Fast on
                    local hits = BF_Fast and 3 or 1
                    for i=1,hits do
                        pcall(function()
                            if nearest and nearest:FindFirstChild("Humanoid") and nearest.Humanoid.Health > 0 then
                                nearest.Humanoid:TakeDamage(dmg)
                            end
                        end)
                    end
                    lastAction = string.format("LongHit -> %s (%.1fm)", tostring(nearest.Name or "mob"), bestDist)
                else
                    -- Tidak long range: teleport dekat lalu melee (existing behavior)
                    pcall(function()
                        hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                    end)
                    if BF_Fast then
                        for i=1,3 do
                            pcall(function()
                                if nearest and nearest:FindFirstChild("Humanoid") then
                                    nearest.Humanoid:TakeDamage(30)
                                end
                            end)
                        end
                        lastAction = "FastMelee -> "..tostring(nearest.Name or "mob")
                    else
                        pcall(function()
                            if nearest and nearest:FindFirstChild("Humanoid") then
                                nearest.Humanoid:TakeDamage(18)
                            end
                        end)
                        lastAction = "Melee -> "..tostring(nearest.Name or "mob")
                    end
                end

                task.wait(BF_attack_delay or 0.35)
            end
        end)
    end
end)
-- CAR Loop
-- CAR Auto W Loop
task.spawn(function()
    while true do
        task.wait() -- update per frame
        if GAME ~= "CAR_TYCOON" then task.wait(0.5); continue end
        if not CAR_Auto then
            -- jika fitur dimatikan, pastikan semua dibersihkan
            if chosenCarModel then
                pcall(stopUsingPlayerCar)
            end
            task.wait(0.2)
            continue
        end

        pcall(function()
            -- pastikan mobil tersedia & BV aktif
            if (not chosenCarModel) or (not chosenCarModel.PrimaryPart) then
                startUsingPlayerCar(-500)
                task.wait(0.2)
                return
            end

            local prim = chosenCarModel.PrimaryPart
            if not prim then return end

            -- jika BV hilang, pasang ulang
            if not prim:FindFirstChild("_GmonBV") then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "_GmonBV"
                bv.MaxForce = Vector3.new(1e5, 0, 1e5)
                bv.Velocity = prim.CFrame.LookVector * CAR_speed
                bv.P = 1250
                bv.Parent = prim
            else
                -- update arah & kecepatan sesuai rotasi mobil
                prim._GmonBV.Velocity = prim.CFrame.LookVector * CAR_speed
            end
        end)
    end
end))

-- restore car when disabled (handled in toggle callback - but ensure here too)
-- already part of toggle: we restore when CAR_Auto set to false

-- BOAT Loop
-- ===== Replace BOAT loop: Auto Gold Stages (teleport ke stage gelap -> chest) =====
task.spawn(function()
    while true do
        task.wait(0.2)
        if GAME ~= "BUILD_A_BOAT" then task.wait(0.5); continue end
        if not BOAT_Auto then task.wait(0.5); continue end
        pcall(function()
            local char = SafeChar()
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- cari root yang masuk akal
            local boatRoots = {}
            local hints = {"BoatStages","Stages","NormalStages","StageFolder","BoatStage"}
            for _, name in ipairs(hints) do
                local r = Workspace:FindFirstChild(name)
                if r then table.insert(boatRoots, r) end
            end
            if #boatRoots == 0 then table.insert(boatRoots, Workspace) end

            -- kumpulkan part "gelap"/stage dari root-root itu
            local stages = {}
            for _, root in ipairs(boatRoots) do
                for _, obj in ipairs(root:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local lname = string.lower(obj.Name or "")
                        -- deteksi berdasarkan nama atau warna gelap
                        local isDark = false
                        local ok, col = pcall(function() return obj.Color end)
                        if ok and col then
                            local brightness = (col.R + col.G + col.B) / 3
                            if brightness < 0.2 then isDark = true end
                        end
                        if isDark or string.find(lname, "stage") or string.find(lname, "black") or string.find(lname, "dark") or string.find(lname, "trigger") then
                            table.insert(stages, obj)
                        end
                    end
                end
            end

            -- fallback: cari parts berlabel "Stage" di seluruh workspace
            if #stages == 0 then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and string.find(string.lower(obj.Name or ""), "stage") then
                        table.insert(stages, obj)
                    end
                end
            end

            if #stages == 0 then
                Rayfield:Notify({Title="G-MON", Content="No stage parts detected (Boat)", Duration=3})
                BOAT_Auto = false
                setIndicator("boat", false, "Boat: OFF")
                return
            end

            -- dedup dan urutkan stages berdasarkan jarak dari titik awal (BOAT_start_CFrame jika ada)
            local seen, uniq = {}, {}
            for _, p in ipairs(stages) do
                local key = string.format("%.2f_%.2f_%.2f", p.Position.X, p.Position.Y, p.Position.Z)
                if not seen[key] then seen[key] = true; table.insert(uniq, p) end
            end
            stages = uniq
            local referencePos = (BOAT_start_CFrame and BOAT_start_CFrame.p) or hrp.Position
            table.sort(stages, function(a,b) return (a.Position - referencePos).Magnitude < (b.Position - referencePos).Magnitude end)

            -- navigasi stage-by-stage (teleport langsung ke tiap stage)
            for i, stagePart in ipairs(stages) do
                if not BOAT_Auto then break end
                if not stagePart or not stagePart.Parent then continue end
                pcall(function()
                    hrp.CFrame = stagePart.CFrame * CFrame.new(0, 3, 0)
                    lastAction = "Boat Stage -> "..tostring(stagePart.Name)
                end)
                task.wait(BOAT_delay or 1.5)
            end

            -- setelah lewat semua stage -> cari chest terdekat dan teleport kesana
            local function findNearestChestFrom(pos)
                local candidates = {}
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        local lname = string.lower(v.Name or "")
                        if string.find(lname, "chest") or string.find(lname, "treasure") or string.find(lname, "golden") then
                            table.insert(candidates, v)
                        end
                    elseif v:IsA("Model") and v.PrimaryPart then
                        local lname = string.lower(v.Name or "")
                        if string.find(lname, "chest") or string.find(lname, "treasure") or string.find(lname, "golden") then
                            table.insert(candidates, v.PrimaryPart)
                        end
                    end
                end
                if #candidates == 0 then return nil end
                table.sort(candidates, function(a,b) return (a.Position - pos).Magnitude < (b.Position - pos).Magnitude end)
                return candidates[1]
            end

            local finalChest = findNearestChestFrom(hrp.Position)
            if finalChest then
                pcall(function()
                    hrp.CFrame = finalChest.CFrame * CFrame.new(0,3,0)
                    lastAction = "Boat Chest -> "..tostring(finalChest.Name)
                    Rayfield:Notify({Title="G-MON", Content="Reached chest", Duration=3})
                end)
            else
                Rayfield:Notify({Title="G-MON", Content="No chest found after stages", Duration=3})
            end

            -- (opsional) hentikan BOAT_Auto jika sudah sampai chest:
            -- BOAT_Auto = false
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

-- Draggable status frame (robust: mouse + touch, clamped to viewport)
do
    local frame = status.frame
    local dragging = false
    local dragInput = nil
    local startMousePos = Vector2.new(0,0)
    local startFramePosAbs = Vector2.new(0,0)

    local function getMousePos()
        -- gunakan UserInputService untuk lokasi mouse (compatible dengan fullscreen & multi-monitor)
        return UIS:GetMouseLocation()
    end

    frame.InputBegan:Connect(function(input)
        -- hanya respon klik kiri atau sentuhan
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            startMousePos = getMousePos()
            -- simpan posisi frame dalam koordinat absolut (pixel)
            startFramePosAbs = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)

            -- stop dragging saat input berakhir
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragInput = nil
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if dragInput and input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

        -- hitung delta dan set posisi baru (dalam pixel), lalu clamp ke viewport
        local mousePos = getMousePos()
        local delta = mousePos - startMousePos
        local newAbs = startFramePosAbs + delta

        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600)
        local fw = frame.AbsoluteSize.X
        local fh = frame.AbsoluteSize.Y

        newAbs = Vector2.new(
            math.clamp(newAbs.X, 0, math.max(0, vp.X - fw)),
            math.clamp(newAbs.Y, 0, math.max(0, vp.Y - fh))
        )

        -- set posisi sebagai absolute UDim2 (Scale 0) — ini membuat posisi stabil
        frame.Position = UDim2.new(0, newAbs.X, 0, newAbs.Y)
    end)
end

-- ===== Final notify =====
Rayfield:Notify({Title="G-MON Hub", Content="Loaded — indicators & restore-on-off active", Duration=5})

