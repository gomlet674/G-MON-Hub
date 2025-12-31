--[[
  G-MON Hub - Single-file "Skull Hub" style (Lazy modular, Mobile-safe)
  - Single file, staged lazy execution to avoid overload/lag crash
  - Rayfield GUI (auto-load), fallback minimal UI if HttpGet blocked
  - Modules: Utils (AntiAFK, SafeChar), Status GUI, BloxFruit, CarTycoon, BuildABoat
  - All heavy loops are defined but started later (staged); can be started via UI immediately
  - Client-only. Use in private/testing places only.
--]]

-- ===== Bootstrap / Safety =====
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local LP = Players.LocalPlayer

local function safe_pcall(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok, res
end

local function safe_wait(sec)
    if type(sec) ~= "number" then sec = 0.1 end
    task.wait(sec)
end

-- ===== Global state =====
local STATE = {
    GAME = "UNKNOWN",
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    StatusGui = nil,
    Modules = {}, -- will hold module tables
    ActiveHandles = {}, -- if need to stop loops
    StartTime = os.time()
}

-- ===== Utils module =====
do
    local Utils = {}
    function Utils.DetectGame()
        local id = game.PlaceId
        if id == 2753915549 then return "BLOX_FRUIT" end
        if id == 1554960397 then return "CAR_TYCOON" end
        if id == 537413528 then return "BUILD_A_BOAT" end
        return "UNKNOWN"
    end

    function Utils.SafeChar()
        local ok, c = pcall(function() return LP and LP.Character end)
        if not ok or not c then return nil end
        if c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then return c end
        return nil
    end

    function Utils.AntiAFK()
        -- protect with pcall; use camera only if available
        if not LP then return end
        safe_pcall(function()
            LP.Idled:Connect(function()
                pcall(function()
                    local cam = workspace.CurrentCamera
                    if cam and cam.CFrame then
                        VirtualUser:Button2Down(Vector2.new(0,0), cam.CFrame)
                        task.wait(1)
                        VirtualUser:Button2Up(Vector2.new(0,0), cam.CFrame)
                    else
                        -- fallback
                        pcall(function() VirtualUser:Button2Down(); task.wait(1); VirtualUser:Button2Up() end)
                    end
                end)
            end)
        end)
    end

    function Utils.FormatTime(sec)
        sec = math.max(0, math.floor(sec or 0))
        local h = math.floor(sec/3600); local m = math.floor((sec%3600)/60); local s = sec%60
        if h>0 then return string.format("%02dh:%02dm:%02ds", h,m,s) end
        return string.format("%02dm:%02ds", m,s)
    end

    STATE.Modules.Utils = Utils
end

-- ===== Rayfield load (immediate attempt) =====
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        STATE.Rayfield = Ray
    else
        warn("[G-MON] Rayfield load failed, using fallback UI. Reason:", Ray)
        -- Minimal fallback object with the methods used below
        STATE.Rayfield = {
            CreateWindow = function(opts)
                return {
                    CreateTab = function() 
                        return {
                            CreateLabel = function() end,
                            CreateParagraph = function() end,
                            CreateButton = function() end,
                            CreateToggle = function() end,
                            CreateSlider = function() end,
                        }
                    end,
                    CreateNotification = function() end
                }
            end,
            Notify = function() end,
            CreateNotification = function() end
        }
    end
end

-- ===== Create main window & tabs (safe) =====
do
    local Ray = STATE.Rayfield
    local ok, win = pcall(function()
        return Ray:CreateWindow({
            Name = "G-MON Hub",
            LoadingTitle = "G-MON Hub",
            LoadingSubtitle = "Boot...",
            ConfigurationSaving = { Enabled = false }
        })
    end)
    if ok and win then
        STATE.Window = win
        STATE.Tabs.Info = win:CreateTab("Info")
        STATE.Tabs.Main = win:CreateTab("Main")
        STATE.Tabs.Movement = win:CreateTab("Movement")
        STATE.Tabs.Debug = win:CreateTab("Debug")
    else
        warn("[G-MON] CreateWindow failed, continuing without Rayfield window")
        STATE.Window = nil
        STATE.Tabs.Info = { CreateParagraph = function() end, CreateLabel=function() end }
        STATE.Tabs.Main = { CreateToggle=function() end, CreateButton=function() end, CreateSlider=function() end }
        STATE.Tabs.Movement = { CreateToggle=function() end, CreateSlider=function() end }
        STATE.Tabs.Debug = { CreateLabel = function() end }
    end
end

-- ===== Status GUI module (lightweight, minimal instances) =====
do
    local Status = {}
    local sroot = nil
    local frame = nil
    local lines = {}

    function Status.Create()
        local ok, res = pcall(function()
            local pg = LP:FindFirstChild("PlayerGui")
            local tries = 0
            while not pg and tries < 30 do task.wait(0.1); tries = tries + 1; pg = LP:FindFirstChild("PlayerGui") end
            if not pg then error("PlayerGui not found") end

            sroot = Instance.new("ScreenGui")
            sroot.Name = "GMonStatusGui"
            sroot.ResetOnSpawn = false
            sroot.Parent = pg

            frame = Instance.new("Frame")
            frame.Name = "GMon_Frame"
            frame.Size = UDim2.new(0, 260, 0, 140)
            frame.Position = UDim2.new(0.7, 0, 0.02, 0)
            frame.BackgroundTransparency = 0.12
            frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
            frame.BorderSizePixel = 0
            frame.Parent = sroot

            local corner = Instance.new("UICorner")
            corner.Parent = frame
            corner.CornerRadius = UDim.new(0,8)

            local title = Instance.new("TextLabel")
            title.Parent = frame
            title.Size = UDim2.new(1, -16, 0, 22)
            title.Position = UDim2.new(0,8,0,6)
            title.BackgroundTransparency = 1
            title.Text = "G-MON Status"
            title.Font = Enum.Font.SourceSansBold; title.TextSize = 16
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.TextColor3 = Color3.fromRGB(255,255,255)

            local sub = Instance.new("TextLabel")
            sub.Parent = frame
            sub.Size = UDim2.new(1, -16, 0, 18)
            sub.Position = UDim2.new(0,8,0,30)
            sub.BackgroundTransparency = 1
            sub.Text = STATE.GAME or "UNKNOWN"
            sub.Font = Enum.Font.SourceSans; sub.TextSize = 12
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.TextColor3 = Color3.fromRGB(200,200,200)

            local function makeLine(y)
                local holder = Instance.new("Frame"); holder.Parent = frame
                holder.Size = UDim2.new(1, -16, 0, 20); holder.Position = UDim2.new(0,8,0,y)
                holder.BackgroundTransparency = 1

                local dot = Instance.new("Frame"); dot.Parent = holder
                dot.Size = UDim2.new(0,12,0,12); dot.Position = UDim2.new(0,0,0,4)
                dot.BackgroundColor3 = Color3.fromRGB(200,0,0)

                local lbl = Instance.new("TextLabel"); lbl.Parent = holder
                lbl.Size = UDim2.new(1, -18, 1, 0); lbl.Position = UDim2.new(0,18,0,0)
                lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(230,230,230)
                lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
                return {dot = dot, lbl = lbl}
            end

            lines.runtime = makeLine(52)
            lines.bf = makeLine(74)
            lines.car = makeLine(96)
            lines.boat = makeLine(118)
            lines.last = makeLine(140)

            lines.runtime.lbl.Text = "Runtime: 00h:00m:00s"
            lines.bf.lbl.Text = "Blox: OFF"
            lines.car.lbl.Text = "Car: OFF"
            lines.boat.lbl.Text = "Boat: OFF"
            lines.last.lbl.Text = "Last: Idle"
        end)
        if not ok then warn("[G-MON] Status.Create failed:", res) end
        return ok
    end

    function Status.Set(name, on, text)
        pcall(function()
            local ln = lines[name]
            if not ln then return end
            if on then ln.dot.BackgroundColor3 = Color3.fromRGB(0,200,0) else ln.dot.BackgroundColor3 = Color3.fromRGB(200,0,0) end
            if text then ln.lbl.Text = text else ln.lbl.Text = ln.lbl.Text end
        end)
    end

    function Status.UpdateRuntime()
        pcall(function()
            if not lines.runtime then return end
            lines.runtime.lbl.Text = "Runtime: "..STATE.Modules.Utils.FormatTime(os.time() - STATE.StartTime)
        end)
    end

    STATE.StatusGui = Status
end

-- ===== Module definitions (functions only, not started yet) =====
do
    -- Blox module (defines start/stop)
    local Blox = {}
    Blox.config = {
        attack_delay = 0.35,
        range = 10,
        long_range = false,
        fast_attack = false
    }
    Blox._running = false
    function Blox.start()
        if Blox._running then return end
        Blox._running = true
        STATE.StatusGui.Set("bf", true, "Blox: ON")
        STATE.ActiveHandles.Blox = task.spawn(function()
            while Blox._running do
                task.wait(0.12)
                pcall(function()
                    if STATE.GAME ~= "BLOX_FRUIT" then return end
                    local char = STATE.Modules.Utils.SafeChar()
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

                    -- simple quest detection first (safe)
                    -- (only teleport to first BasePart in Quests folder if exists)
                    local qfolder = Workspace:FindFirstChild("Quests") or nil
                    if qfolder and qfolder:IsA("Folder") then
                        local qtarget
                        for _, obj in ipairs(qfolder:GetDescendants()) do
                            if obj:IsA("BasePart") then qtarget = obj; break end
                        end
                        if qtarget then
                            pcall(function() hrp.CFrame = qtarget.CFrame * CFrame.new(0,3,0) end)
                            STATE.StatusGui.Set("last", true, "Last: Goto Quest")
                            task.wait(1)
                            continue
                        end
                    end

                    -- auto farm basic: find nearest in folder names
                    local seaNames = {"Enemies","Monsters","Mobs"}
                    local folder = nil
                    for _, n in ipairs(seaNames) do
                        local f = Workspace:FindFirstChild(n)
                        if f then folder = f; break end
                    end
                    if not folder then return end

                    local nearest, bestDist = nil, math.huge
                    for _, mob in ipairs(folder:GetChildren()) do
                        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                            local hum = mob:FindFirstChild("Humanoid")
                            if hum and hum.Health > 0 then
                                local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                                if d < bestDist and d <= (Blox.config.range or 10) then bestDist, nearest = d, mob end
                            end
                        end
                    end

                    if not nearest and Blox.config.long_range then
                        -- search nearest ignoring range
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

                    if not nearest then
                        -- nothing in range
                        return
                    end

                    if Blox.config.long_range then
                        local dmg = Blox.config.fast_attack and 35 or 20
                        local hits = Blox.config.fast_attack and 3 or 1
                        for i=1,hits do
                            pcall(function()
                                if nearest and nearest:FindFirstChild("Humanoid") then
                                    nearest.Humanoid:TakeDamage(dmg)
                                end
                            end)
                        end
                        STATE.StatusGui.Set("last", true, "Last: LongHit")
                    else
                        pcall(function() hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
                        if Blox.config.fast_attack then
                            for i=1,3 do
                                pcall(function()
                                    if nearest and nearest:FindFirstChild("Humanoid") then
                                        nearest.Humanoid:TakeDamage(30)
                                    end
                                end)
                            end
                            STATE.StatusGui.Set("last", true, "Last: FastMelee")
                        else
                            pcall(function()
                                if nearest and nearest:FindFirstChild("Humanoid") then
                                    nearest.Humanoid:TakeDamage(18)
                                end
                            end)
                            STATE.StatusGui.Set("last", true, "Last: Melee")
                        end
                    end
                end)
            end
        end)
    end
    function Blox.stop()
        Blox._running = false
        STATE.StatusGui.Set("bf", false, "Blox: OFF")
        if STATE.ActiveHandles.Blox then
            -- no direct kill; handle will exit loop
            STATE.ActiveHandles.Blox = nil
        end
    end
    STATE.Modules.Blox = Blox
end

do
    -- Car module
    local Car = {}
    Car._running = false
    Car.speed = 60
    Car.chosen = nil
    function Car.choosePlayerFastestCar()
        -- safer scanning heuristics
        local carsRoot = Workspace:FindFirstChild("Cars") or Workspace
        local owned = {}
        for _, m in ipairs(carsRoot:GetDescendants()) do
            if m:IsA("Model") and m.PrimaryPart then
                -- owner heuristics
                local ok, ownerVal = pcall(function()
                    local o = m:FindFirstChild("Owner") or m:FindFirstChild("OwnerName")
                    if o then return tostring(o.Value) end
                    if m.GetAttribute then return m:GetAttribute("Owner") end
                    return nil
                end)
                if ok and ownerVal and tostring(ownerVal) == tostring(LP.Name) then
                    table.insert(owned, m)
                end
            end
        end
        if #owned == 0 then
            -- fallback: return first big model found
            for _, m in ipairs(Workspace:GetChildren()) do
                if m:IsA("Model") and m.PrimaryPart and #m:GetDescendants() > 5 then
                    return m
                end
            end
            return nil
        end
        -- pick by heuristic
        local best, bestVal = nil, -1
        for _, car in ipairs(owned) do
            local v = #car:GetDescendants()
            if v and v > bestVal then bestVal, best = v, car end
        end
        return best
    end

    local function attachFloorForCar(car, origCF)
        pcall(function()
            if not car then return end
            if car:FindFirstChild("_GmonFloorRef") then return end
            if not origCF then return end
            local floor = Instance.new("Part")
            floor.Name = "_GmonFloor_GMON"
            floor.Size = Vector3.new(300,2,300)
            floor.Position = Vector3.new(origCF.Position.X, origCF.Position.Y - 500, origCF.Position.Z)
            floor.Anchored = true
            floor.CanCollide = true
            floor.Transparency = 0.15
            floor.Parent = Workspace
            local fv = Instance.new("ObjectValue"); fv.Name = "_GmonFloorRef"; fv.Value = floor; fv.Parent = car
            if pcall(function() return car.SetAttribute end) then
                pcall(function() car:SetAttribute("GmonFloor", true) end)
            end
        end)
    end

    function Car.start()
        if Car._running then return end
        Car._running = true
        STATE.StatusGui.Set("car", true, "Car: ON")
        STATE.ActiveHandles.Car = task.spawn(function()
            while Car._running do
                task.wait(0.2)
                pcall(function()
                    if STATE.GAME ~= "CAR_TYCOON" then return end
                    if not Car.chosen or not Car.chosen.PrimaryPart then
                        Car.chosen = Car.choosePlayerFastestCar()
                        if Car.chosen and Car.chosen.PrimaryPart then
                            -- store start pos
                            if not Car.chosen:FindFirstChild("_GmonStartPos") then
                                local cv = Instance.new("CFrameValue"); cv.Name = "_GmonStartPos"; cv.Value = Car.chosen.PrimaryPart.CFrame; cv.Parent = Car.chosen
                            end
                            local ok, origCF = pcall(function() return Car.chosen.PrimaryPart.CFrame end)
                            if ok and origCF then attachFloorForCar(Car.chosen, origCF) end
                            -- move car under map to simulate driving if needed
                            if ok and origCF then
                                pcall(function() Car.chosen:SetPrimaryPartCFrame(CFrame.new(origCF.Position.X, origCF.Position.Y - 500, origCF.Position.Z)) end)
                            end
                        else
                            STATE.StatusGui.Set("last", false, "Last: NoCar")
                            return
                        end
                    end
                    -- ensure BodyVelocity exists & update
                    if Car.chosen and Car.chosen.PrimaryPart then
                        local prim = Car.chosen.PrimaryPart
                        pcall(function()
                            local bv = prim:FindFirstChild("_GmonBV")
                            if not bv then
                                bv = Instance.new("BodyVelocity"); bv.Name = "_GmonBV"; bv.MaxForce = Vector3.new(1e6,0,1e6); bv.P = 1250; bv.Parent = prim
                            end
                            bv.Velocity = prim.CFrame.LookVector * Car.speed
                        end)
                    end
                end)
            end
        end)
    end

    function Car.stop()
        Car._running = false
        STATE.StatusGui.Set("car", false, "Car: OFF")
        if Car.chosen then
            pcall(function()
                if Car.chosen.PrimaryPart then
                    local bv = Car.chosen.PrimaryPart:FindFirstChild("_GmonBV")
                    if bv then bv:Destroy() end
                end
                local tag = Car.chosen:FindFirstChild("_GmonStartPos")
                if tag and tag:IsA("CFrameValue") then
                    pcall(function() Car.chosen:SetPrimaryPartCFrame(tag.Value) end)
                    pcall(function() tag:Destroy() end)
                end
                local fv = Car.chosen:FindFirstChild("_GmonFloorRef")
                if fv and fv.Value and fv.Value.Parent then pcall(function() fv.Value:Destroy() end) end
                if Car.chosen.GetAttribute and Car.chosen:GetAttribute("GmonFloor") then pcall(function() Car.chosen:SetAttribute("GmonFloor", nil) end) end
            end)
        end
        Car.chosen = nil
        STATE.ActiveHandles.Car = nil
    end

    STATE.Modules.Car = Car
end

do
    -- Boat module
    local Boat = {}
    Boat._running = false
    Boat.delay = 1.5

    local function collectBoatStages(root)
        local stages = {}
        if not root then return stages end
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("BasePart") then
                local lname = string.lower(obj.Name or "")
                local ok, col = pcall(function() return obj.Color end)
                local isDark = false
                if ok and col then
                    if (col.R + col.G + col.B) / 3 < 0.2 then isDark = true end
                end
                if isDark or string.find(lname, "stage") or string.find(lname, "black") or string.find(lname, "dark") or string.find(lname, "trigger") then
                    table.insert(stages, obj)
                end
            end
        end
        return stages
    end

    function Boat.start()
        if Boat._running then return end
        Boat._running = true
        STATE.StatusGui.Set("boat", true, "Boat: ON")
        STATE.ActiveHandles.Boat = task.spawn(function()
            while Boat._running do
                task.wait(0.2)
                pcall(function()
                    if STATE.GAME ~= "BUILD_A_BOAT" then return end
                    local char = STATE.Modules.Utils.SafeChar()
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

                    -- gather roots
                    local boatRoots = {}
                    for _, n in ipairs({"BoatStages","Stages","NormalStages","StageFolder","BoatStage"}) do
                        local r = Workspace:FindFirstChild(n)
                        if r then table.insert(boatRoots, r) end
                    end
                    if #boatRoots == 0 then table.insert(boatRoots, Workspace) end

                    local stages = {}
                    for _, root in ipairs(boatRoots) do
                        local s = collectBoatStages(root)
                        for _, p in ipairs(s) do table.insert(stages, p) end
                    end
                    if #stages == 0 then
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("BasePart") and string.find(string.lower(obj.Name or ""), "stage") then table.insert(stages, obj) end
                        end
                    end
                    if #stages == 0 then
                        Boat._running = false
                        STATE.StatusGui.Set("boat", false, "Boat: OFF")
                        STATE.StatusGui.Set("last", false, "No stages")
                        return
                    end

                    -- dedupe & sort
                    local seen, uniq = {}, {}
                    for _, p in ipairs(stages) do
                        if p and p.Position then
                            local key = string.format("%.2f_%.2f_%.2f", p.Position.X, p.Position.Y, p.Position.Z)
                            if not seen[key] then seen[key] = true; table.insert(uniq, p) end
                        end
                    end
                    stages = uniq
                    table.sort(stages, function(a,b) return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude end)

                    for _, part in ipairs(stages) do
                        if not Boat._running then break end
                        if part and part.Parent then
                            pcall(function() hrp.CFrame = part.CFrame * CFrame.new(0,3,0) end)
                            STATE.StatusGui.Set("last", false, "Boat Stage -> "..tostring(part.Name))
                        end
                        task.wait(Boat.delay or 1.5)
                    end

                    -- find chest
                    local candidate = nil
                    for _, v in ipairs(Workspace:GetDescendants()) do
                        if v:IsA("BasePart") then
                            local ln = string.lower(v.Name or "")
                            if string.find(ln, "chest") or string.find(ln, "treasure") or string.find(ln, "golden") then
                                candidate = v; break
                            end
                        elseif v:IsA("Model") and v.PrimaryPart then
                            local ln = string.lower(v.Name or "")
                            if string.find(ln, "chest") or string.find(ln, "treasure") or string.find(ln, "golden") then
                                candidate = v.PrimaryPart; break
                            end
                        end
                    end
                    if candidate then
                        pcall(function() hrp.CFrame = candidate.CFrame * CFrame.new(0,3,0) end)
                        STATE.StatusGui.Set("last", false, "Reached chest")
                    else
                        STATE.StatusGui.Set("last", false, "No chest found")
                    end
                end)
            end
        end)
    end

    function Boat.stop()
        Boat._running = false
        STATE.StatusGui.Set("boat", false, "Boat: OFF")
        STATE.ActiveHandles.Boat = nil
    end

    STATE.Modules.Boat = Boat
end

-- ===== Wiring UI controls (Main Tab controls + manual start buttons) =====
do
    local InfoTab = STATE.Tabs.Info
    local MainTab = STATE.Tabs.Main
    local MoveTab = STATE.Tabs.Movement
    local DebugTab = STATE.Tabs.Debug
    local Ray = STATE.Rayfield

    -- Info content
    safe_pcall(function()
        InfoTab:CreateLabel("G-MON Hub - Single-file Lazy Modular")
        InfoTab:CreateParagraph({
            Title = "Notes",
            Content = "Modules load staged to avoid overload. Use buttons below to start modules immediately. Client-only. Use in private/testing places only."
        })
    end)

    -- Add toggles & buttons for modules (these create the UI controllers but do not auto-start heavy loops)
    safe_pcall(function()
        -- Blox controls
        MainTab:CreateToggle({
            Name = "Blox AutoFarm (toggle to start/stop)",
            CurrentValue = false,
            Callback = function(v)
                if v then
                    STATE.Modules.Blox.start()
                else
                    STATE.Modules.Blox.stop()
                end
            end
        })
        -- Blox extras: sliders
        MainTab:CreateSlider({
            Name = "Attack Delay (ms)",
            Range = {50,1000},
            Increment = 25,
            CurrentValue = 350,
            Callback = function(v) STATE.Modules.Blox.config.attack_delay = v/1000 end
        })
        MainTab:CreateSlider({
            Name = "Range (studs) 1-50",
            Range = {1,50},
            Increment = 1,
            CurrentValue = 10,
            Callback = function(v) STATE.Modules.Blox.config.range = v end
        })
        MainTab:CreateToggle({
            Name = "Long Range Hit",
            CurrentValue = false,
            Callback = function(v) STATE.Modules.Blox.config.long_range = v end
        })
        MainTab:CreateToggle({
            Name = "Fast Attack (client)",
            CurrentValue = false,
            Callback = function(v) STATE.Modules.Blox.config.fast_attack = v end
        })

        -- Car controls
        MainTab:CreateToggle({
            Name = "Car AutoDrive (toggle)",
            CurrentValue = false,
            Callback = function(v)
                if v then STATE.Modules.Car.start() else STATE.Modules.Car.stop() end
            end
        })
        MainTab:CreateSlider({
            Name = "Car Speed (sim)",
            Range = {20,200},
            Increment = 5,
            CurrentValue = 60,
            Callback = function(v) STATE.Modules.Car.speed = v end
        })

        -- Boat controls
        MainTab:CreateToggle({
            Name = "Boat Auto Stages",
            CurrentValue = false,
            Callback = function(v)
                if v then STATE.Modules.Boat.start() else STATE.Modules.Boat.stop() end
            end
        })
        MainTab:CreateSlider({
            Name = "Boat Stage Delay (s)",
            Range = {0.5,6},
            Increment = 0.5,
            CurrentValue = 1.5,
            Callback = function(v) STATE.Modules.Boat.delay = v end
        })

        -- Movement Tab (fly)
        MoveTab:CreateToggle({ Name = "Fly", Callback = function(v) STATE.Modules.FlyEnabled = v end })
        MoveTab:CreateSlider({ Name = "Fly Speed", Range = {20,150}, Increment = 5, CurrentValue = 60, Callback = function(v) STATE.Modules.FlySpeed = v end })
        MoveTab:CreateSlider({ Name = "Fly Y", Range = {-60,60}, Increment = 1, CurrentValue = 0, Callback = function(v) STATE.Modules.FlyY = v end })

        -- Debug
        DebugTab:CreateButton({ Name = "Force Start All Modules NOW", Callback = function()
            safe_pcall(function() STATE.Modules.Blox.start() end)
            safe_pcall(function() STATE.Modules.Car.start() end)
            safe_pcall(function() STATE.Modules.Boat.start() end)
        end })
        DebugTab:CreateButton({ Name = "Stop All Modules", Callback = function()
            safe_pcall(function() STATE.Modules.Blox.stop() end)
            safe_pcall(function() STATE.Modules.Car.stop() end)
            safe_pcall(function() STATE.Modules.Boat.stop() end)
        end })
    end)

    -- UI: Report detected game in window subtitle if possible
    pcall(function()
        local gameName = STATE.Modules.Utils.DetectGame()
        STATE.GAME = gameName
        if STATE.Window and STATE.Window.LoadingSubtitle ~= nil then
            -- Some Rayfield implementations allow updating subtitle via label; do a notify instead
            STATE.Rayfield:Notify({ Title = "G-MON", Content = "Detected game: "..tostring(gameName), Duration = 4 })
        end
    end)
end

-- ===== Lightweight Movement (Fly) implementation hooked to RenderStepped =====
do
    local flyEnabled = false
    local flySpeed = 60
    local flyY = 0
    STATE.Modules.FlyEnabled = false
    STATE.Modules.FlySpeed = 60
    STATE.Modules.FlyY = 0

    RunService.RenderStepped:Connect(function()
        if not STATE.Modules.FlyEnabled then return end
        pcall(function()
            local c = STATE.Modules.Utils.SafeChar()
            if not c then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            local dir = Vector3.new(0,0,0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            local v = Vector3.new(dir.X * (STATE.Modules.FlySpeed or 60), (STATE.Modules.FlyY or 0), dir.Z * (STATE.Modules.FlySpeed or 60))
            pcall(function() c.HumanoidRootPart.Velocity = v end)
        end)
    end)
end

-- ===== Status updater loop (lightweight) =====
task.spawn(function()
    while true do
        safe_wait(1)
        pcall(function() if STATE.StatusGui then STATE.StatusGui.UpdateRuntime() end end)
    end
end)

-- ===== Anti AFK start (safe & immediate) =====
safe_pcall(function() STATE.Modules.Utils.AntiAFK() end)

-- ===== Staged/Delayed module boot (LAZY LOAD) =====
-- Purpose: avoid initial overload. Modules are defined above; we call init/soft-start in stages.
task.spawn(function()
    -- Stage 0: minimal wait to let executor settle
    safe_wait(1)

    -- Stage 1: UI & status (already created via Rayfield, but create status gui instances)
    safe_pcall(function()
        if STATE.StatusGui and STATE.StatusGui.Create then STATE.StatusGui.Create() end
    end)

    -- Stage 2: after small delay, perform light wiring; DO NOT start heavy loops
    safe_wait(6) -- wait a few seconds before starting features
    safe_pcall(function()
        -- Inform user
        STATE.Rayfield:Notify({ Title = "G-MON", Content = "Modules loaded in background...", Duration = 4 })
    end)

    -- Stage 3: start low-cost modules / prepare resources
    safe_wait(8) -- wait more to spread load (user will experience small initial lag only)
    safe_pcall(function()
        STATE.Modules.Utils -- already available
        -- We DON'T auto-start heavy loops. Only prepare.
    end)

    -- Stage 4: optionally auto-start modules based on detected game but keep it deferred
    safe_wait(10)
    safe_pcall(function()
        local g = STATE.Modules.Utils.DetectGame()
        STATE.GAME = g
        -- If you want auto-start on detection, uncomment next lines:
        -- if g == "BLOX_FRUIT" then STATE.Modules.Blox.start() end
        -- if g == "CAR_TYCOON" then STATE.Modules.Car.start() end
        -- if g == "BUILD_A_BOAT" then STATE.Modules.Boat.start() end

        -- Instead: show notification and rely on user to toggle or debug-start
        STATE.Rayfield:Notify({ Title = "G-MON", Content = "Detected game: "..tostring(g).." | use toggles to start features", Duration = 6 })
    end)

    -- Stage 5: final background idle checks (keep very light)
    safe_wait(12)
    safe_pcall(function()
        -- all modules are ready to be started on-demand; keep loops off until user toggles.
        STATE.Rayfield:Notify({ Title = "G-MON", Content = "Initialization complete (lazy)", Duration = 4 })
    end)
end)

-- ===== End of single-file script =====
print("[G-MON] Single-file lazy modular script loaded. Use the GUI toggles to start modules. Detected Game:", STATE.GAME)
