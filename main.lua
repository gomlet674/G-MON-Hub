
-- main_final_gmon.lua
-- G-MON final: Blox (kept) + CDT_Money (AutoFarm money only) + Build_A_Boat_For_Treasure (Haruka renamed)
-- SAFE_CALL wrappers, Status GUI, Rayfield fallback.

repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local function SAFE_CALL(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if not ok then warn("[G-MON] SAFE_CALL error:", res) end
    return ok, res
end
local function SAFE_WAIT(sec)
    sec = tonumber(sec) or 0.1
    if sec < 0.01 then sec = 0.01 end
    if sec > 5 then sec = 5 end
    task.wait(sec)
end

local STATE = {
    GAME = "UNKNOWN",
    StartTime = os.time(),
    Modules = {},
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    Status = nil,
    Flags = {},
    LastAction = "Idle"
}

local Utils = {}
function Utils.SafeChar()
    local ok, c = pcall(function() return LP and LP.Character end)
    if not ok or not c then return nil end
    if c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then return c end
    return nil
end
function Utils.AntiAFK()
    if not LP then return end
    SAFE_CALL(function()
        LP.Idled:Connect(function()
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam and cam.CFrame then
                    VirtualUser:Button2Down(Vector2.new(0,0), cam.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0,0), cam.CFrame)
                else
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

function Utils.FlexibleDetectByAliases()
    local pid = game.PlaceId
    if pid == 2753915549 then return "BLOX_FRUIT" end
    if pid == 1554960397 then return "CAR_TYCOON" end
    if pid == 537413528 then return "BUILD_A_BOAT" end
    -- heuristics
    local aliasMap = {
        BLOX_FRUIT = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs"},
        CAR_TYCOON = {"Cars","Dealership","Tycoons","Races"},
        BUILD_A_BOAT = {"BoatStages","Stages","Treasure","Chest"}
    }
    for key, list in pairs(aliasMap) do
        for _, name in ipairs(list) do
            if Workspace:FindFirstChild(name) then return key end
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        local n = string.lower(obj.Name or "")
        if string.find(n, "enemy") or string.find(n, "mob") then return "BLOX_FRUIT" end
        if string.find(n, "car") or string.find(n, "race") or string.find(n, "tycoon") then return "CAR_TYCOON" end
        if string.find(n, "boat") or string.find(n, "treasure") or string.find(n, "stage") then return "BUILD_A_BOAT" end
    end
    return "UNKNOWN"
end

function Utils.ShortLabelForGame(g)
    if g == "BLOX_FRUIT" then return "Blox" end
    if g == "CAR_TYCOON" then return "CDT Money" end
    if g == "BUILD_A_BOAT" then return "Build A Boat" end
    return tostring(g or "Unknown")
end

STATE.Modules.Utils = Utils

-- ===== BLOX (kept minimal) =====
do
    local M = {}
    M.config = { attack_delay = 0.35, range = 10, long_range = false, fast_attack = false }
    M.running = false
    M._task = nil

    local function findEnemyFolder()
        local hints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs"}
        for _, name in ipairs(hints) do local f = Workspace:FindFirstChild(name) if f then return f end end
        return nil
    end

    local function loop()
        while M.running do
            task.wait(0.12)
            SAFE_CALL(function()
                if STATE.GAME ~= "BLOX_FRUIT" then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local folder = findEnemyFolder(); if not folder then return end
                local nearest, bestDist = nil, math.huge
                for _, mob in ipairs(folder:GetChildren()) do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                        local hum = mob:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if d < bestDist and d <= (M.config.range or 10) then bestDist, nearest = d, mob end
                        end
                    end
                end
                if not nearest and M.config.long_range then
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
                if not nearest then return end
                if M.config.long_range then
                    local dmg = M.config.fast_attack and 35 or 20
                    local hits = M.config.fast_attack and 3 or 1
                    for i=1,hits do pcall(function() if nearest and nearest:FindFirstChild("Humanoid") then nearest.Humanoid:TakeDamage(dmg) end end) end
                    STATE.LastAction = "LongHit -> "..tostring(nearest.Name or "mob")
                else
                    pcall(function() hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
                    if M.config.fast_attack then
                        for i=1,3 do pcall(function() if nearest and nearest:FindFirstChild("Humanoid") then nearest.Humanoid:TakeDamage(30) end end) end
                        STATE.LastAction = "FastMelee -> "..tostring(nearest.Name or "mob")
                    else
                        pcall(function() if nearest and nearest:FindFirstChild("Humanoid") then nearest.Humanoid:TakeDamage(18) end end)
                        STATE.LastAction = "Melee -> "..tostring(nearest.Name or "mob")
                    end
                end
            end)
        end
    end

    function M.start() if M.running then return end; M.running = true; STATE.Flags.Blox = true; M._task = task.spawn(loop) end
    function M.stop() M.running = false; STATE.Flags.Blox = false; M._task = nil end

    STATE.Modules.Blox = M
end

-- ===== CDT_Money (simplified auto farm money only) =====
do
    local M = {}
    M.running = false
    M.settings = { speed = 300, autoDrive = false, autoCollect = false }
    M._task = nil

    local function getPlayerCar()
        local char = LP.Character
        if not char then return nil end
        local seat = char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart
        if seat and seat.Parent then
            local car = seat.Parent.Parent or seat.Parent
            if car and car:IsA("Model") then return car end
        end
        local carsRoot = Workspace:FindFirstChild("Cars") or Workspace
        for _, v in ipairs(carsRoot:GetChildren()) do
            if v:IsA("Model") and v.PrimaryPart then
                local owner = (v:FindFirstChild("Owner") and tostring(v.Owner.Value)) or (v:GetAttribute and v:GetAttribute("Owner")) or ""
                if owner == LP.Name then return v end
            end
        end
        return nil
    end

    local function ensureAnchorPart()
        local p = Workspace:FindFirstChild("gmon_justapart")
        if not p then
            p = Instance.new("Part")
            p.Name = "gmon_justapart"
            p.Size = Vector3.new(10000,20,10000)
            p.Anchored = true
            p.CanCollide = false
            p.Position = (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position or Vector3.new()) + Vector3.new(0,1000,0)
            p.Parent = Workspace
        end
        return p
    end

    local function autoDriveLoop()
        while M.running and M.settings.autoDrive do
            task.wait(0.12)
            SAFE_CALL(function()
                local car = getPlayerCar()
                if not car or not car.PrimaryPart then return end
                local justapart = ensureAnchorPart()
                local speed = tonumber(M.settings.speed) or 300
                local target = justapart.CFrame * CFrame.new(0,10,-1000)
                local dist = (car.PrimaryPart.Position - target.Position).magnitude
                local TweenService = game:GetService("TweenService")
                local TweenInfoToUse = TweenInfo.new(math.max(0.2, dist / math.max(1, speed)), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
                local TweenValue = Instance.new("CFrameValue")
                TweenValue.Value = car:GetPrimaryPartCFrame()
                local conn
                conn = TweenValue.Changed:Connect(function()
                    if car and car.PrimaryPart then
                        pcall(function() car:PivotTo(TweenValue.Value) end)
                        pcall(function() car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed end)
                    end
                end)
                local OnTween = TweenService:Create(TweenValue, TweenInfoToUse, {Value = target})
                OnTween:Play()
                OnTween.Completed:Wait()
                if conn then conn:Disconnect() end
            end)
        end
    end

    local function autoCollectLoop()
        while M.running and M.settings.autoCollect do
            task.wait(0.6)
            SAFE_CALL(function()
                local car = getPlayerCar()
                if not car then return end
                local collectRoot = Workspace:FindFirstChild("Collectibles")
                if not collectRoot then return end
                for _, v in ipairs(collectRoot:GetDescendants()) do
                    if v:IsA("Model") and v.PrimaryPart and v.Parent == collectRoot then
                        pcall(function() car:PivotTo(v.PrimaryPart.CFrame) end); break
                    end
                end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true
        STATE.Flags.CDT_Money = true
        M._task = {}
        table.insert(M._task, task.spawn(autoDriveLoop))
        table.insert(M._task, task.spawn(autoCollectLoop))
    end

    function M.stop()
        M.running = false
        STATE.Flags.CDT_Money = false
        M._task = nil
    end

    STATE.Modules.CDT_Money = M
end

-- ===== Build_A_Boat_For_Treasure (Haruka renamed) =====
do
    local M = {}
    M.autoRunning = false
    M.goldRunning = false
    M._autoTask = nil
    M._goldGui = nil

    local function haruka_auto_loop(character)
        while M.autoRunning do
            if not character or not character.Parent then
                wait(1); character = LP.Character; if not character then continue end
            end
            wait(1.2)
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then wait(1) continue end
            local velObj = Instance.new("BodyVelocity")
            velObj.MaxForce = Vector3.new(0,1,0)
            velObj.Velocity = Vector3.new(0, -0.1, 0)
            velObj.Parent = hrp
            pcall(function() hrp.CFrame = CFrame.new(-135.900,72,623.750) end)
            local loopCount = 0
            while hrp and hrp.CFrame and M.autoRunning and loopCount < 1500 do
                for i=1,50 do
                    if not M.autoRunning then break end
                    if hrp and hrp.Parent then pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0,0,0.3) end) end
                end
                loopCount = loopCount + 1
                wait()
                if hrp and hrp.CFrame and hrp.CFrame.Z >= 8600.75 then break end
            end
            if velObj and velObj.Parent then pcall(function() velObj:Destroy() end) end
            if M.autoRunning then
                pcall(function() hrp.CFrame = CFrame.new(-150.900,72,2000.750) end); wait(0.2)
                pcall(function() hrp.CFrame = CFrame.new(-150.900,72,2500.750) end); wait(0.5)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9488.1377) end); wait(0.5)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9495.1377) end); wait(1)
                pcall(function() hrp.CFrame = CFrame.new(-205.900,20,1700.750) end); wait(2.3)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9488.1377) end); wait(0.6)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9495.1377) end); wait(1.4)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9488.1377) end)
            end
        end
    end

    function M.startAutoFarm()
        if M.autoRunning then return end
        M.autoRunning = true
        STATE.Flags.TreasureAuto = true
        if LP.Character then M._autoTask = task.spawn(function() haruka_auto_loop(LP.Character) end) end
        LP.CharacterAdded:Connect(function(c) wait(2); if M.autoRunning then task.spawn(function() haruka_auto_loop(c) end) end end)
    end
    function M.stopAutoFarm() M.autoRunning = false; STATE.Flags.TreasureAuto = false; M._autoTask = nil end

    local function create_gold_gui()
        local player = LP
        if not player then return nil end
        local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        local GoldGui = Instance.new("ScreenGui"); GoldGui.Name = "GMon_TreasureGoldTracker"; GoldGui.ResetOnSpawn = false; GoldGui.Parent = pg
        local Frame = Instance.new("Frame"); Frame.Size = UDim2.new(0, 260, 0, 140); Frame.Position = UDim2.new(0,10,0,10); Frame.BackgroundColor3 = Color3.fromRGB(12,12,12); Frame.BackgroundTransparency = 0.12; Frame.BorderSizePixel = 0; Frame.Parent = GoldGui
        local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0,10); Corner.Parent = Frame
        local labels = {} local texts = {"Start:", "Now:", "Earned:", "Uptime:"}
        for i, t in ipairs(texts) do
            local holder = Instance.new("Frame"); holder.Size = UDim2.new(1,-20,0,30); holder.Position = UDim2.new(0,10,0,10+(i-1)*30); holder.BackgroundTransparency = 1; holder.Parent = Frame
            local left = Instance.new("TextLabel"); left.Size = UDim2.new(0.6,0,1,0); left.Text = t; left.TextColor3 = Color3.fromRGB(190,190,190); left.BackgroundTransparency = 1; left.TextSize = 14; left.Font = Enum.Font.Gotham; left.TextXAlignment = Enum.TextXAlignment.Left; left.Parent = holder
            local right = Instance.new("TextLabel"); right.Size = UDim2.new(0.4,0,1,0); right.Position = UDim2.new(0.6,0,0,0); right.Text = "0"; right.TextColor3 = Color3.fromRGB(255,255,255); right.BackgroundTransparency = 1; right.TextSize = 14; right.Font = Enum.Font.GothamBold; right.TextXAlignment = Enum.TextXAlignment.Right; right.Parent = holder
            labels[i] = right
        end
        return {Gui = GoldGui, Labels = labels, StartTime = os.time()}
    end

    local function gold_loop(stateObj)
        if not stateObj then return end
        local player = LP
        local Mroot = nil
        SAFE_CALL(function() if player and player:FindFirstChild("PlayerGui") then Mroot = player.PlayerGui end end)
        local baseAmount = 0
        stateObj.Labels[1].Text = "0"; stateObj.Labels[2].Text = "0"; stateObj.Labels[3].Text = "0"; stateObj.Labels[4].Text = "00:00"
        while M.goldRunning do
            if Mroot then
                local found = nil
                for _, child in ipairs(Mroot:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Text and child.Text:match("%d") then
                        local num = tonumber((child.Text:gsub("[^%d]","")))
                        if num then found = child; break end
                    end
                end
                if found then
                    local cur = tonumber(found.Text:gsub("[^%d]","")) or 0
                    stateObj.Labels[2].Text = tostring(cur)
                    if cur > baseAmount then
                        local earned = tonumber(stateObj.Labels[3].Text) or 0
                        earned = earned + (cur - baseAmount)
                        stateObj.Labels[3].Text = tostring(earned)
                        baseAmount = cur
                    elseif cur < baseAmount then baseAmount = cur end
                end
            end
            local elapsed = os.time() - stateObj.StartTime
            stateObj.Labels[4].Text = string.format("%02d:%02d", math.floor(elapsed/60), elapsed%60)
            wait(1)
        end
    end

    function M.startGoldTracker()
        if M.goldRunning then return end
        M.goldRunning = true
        STATE.Flags.TreasureGold = true
        local obj = create_gold_gui()
        if obj then M._goldGui = obj; task.spawn(function() gold_loop(obj) end) end
    end
    function M.stopGoldTracker()
        M.goldRunning = false; STATE.Flags.TreasureGold = false
        if M._goldGui and M._goldGui.Gui and M._goldGui.Gui.Parent then pcall(function() M._goldGui.Gui:Destroy() end) end
        M._goldGui = nil
    end

    STATE.Modules.Build_A_Boat_For_Treasure = M
end

-- Rayfield fallback
do
    local ok, Ray = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
    if ok and Ray then STATE.Rayfield = Ray else
        local Fallback = {}
        function Fallback:CreateWindow() local win = {} function win:CreateTab() return { CreateLabel=function() end, CreateButton=function() end, CreateToggle=function() end, CreateSlider=function() end } end; function win:CreateNotification() end; return win end
        function Fallback:Notify() end
        STATE.Rayfield = Fallback
    end
end

-- Status GUI
do
    local Status = {}
    function Status.Create()
        SAFE_CALL(function()
            local pg = LP:WaitForChild("PlayerGui")
            local sg = Instance.new("ScreenGui"); sg.Name = "GMonStatusGui"; sg.ResetOnSpawn = false; sg.Parent = pg
            local frame = Instance.new("Frame"); frame.Name = "StatusFrame"; frame.Size = UDim2.new(0, 340, 0, 180); frame.Position = UDim2.new(1, -350, 0, 10); frame.BackgroundTransparency = 0.12; frame.BackgroundColor3 = Color3.fromRGB(18,18,18); frame.BorderSizePixel = 0; frame.Parent = sg
            local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,8); corner.Parent = frame
            local title = Instance.new("TextLabel"); title.Parent = frame; title.Size = UDim2.new(1, -16, 0, 24); title.Position = UDim2.new(0,8,0,6); title.BackgroundTransparency = 1; title.Text = "G-MON Status"; title.TextColor3 = Color3.fromRGB(255,255,255); title.TextXAlignment = Enum.TextXAlignment.Left; title.Font = Enum.Font.SourceSansBold; title.TextSize = 16
            local sub = Instance.new("TextLabel"); sub.Parent = frame; sub.Size = UDim2.new(1, -16, 0, 18); sub.Position = UDim2.new(0,8,0,30); sub.BackgroundTransparency = 1; sub.Text = Utils.ShortLabelForGame(STATE.GAME); sub.TextColor3 = Color3.fromRGB(200,200,200); sub.TextXAlignment = Enum.TextXAlignment.Left; sub.Font = Enum.Font.SourceSans; sub.TextSize = 12
            local function makeLine(y)
                local holder = Instance.new("Frame"); holder.Parent = frame; holder.Size = UDim2.new(1, -16, 0, 20); holder.Position = UDim2.new(0,8,0,y); holder.BackgroundTransparency = 1
                local dot = Instance.new("Frame"); dot.Parent = holder; dot.Size = UDim2.new(0, 12, 0, 12); dot.Position = UDim2.new(0, 0, 0, 4); dot.BackgroundColor3 = Color3.fromRGB(200,0,0)
                local lbl = Instance.new("TextLabel"); lbl.Parent = holder; lbl.Size = UDim2.new(1, -18, 1, 0); lbl.Position = UDim2.new(0, 18, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = ""; lbl.TextColor3 = Color3.fromRGB(230,230,230); lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
                return {dot = dot, lbl = lbl}
            end
            local lines = {}
            lines.runtime = makeLine(52); lines.bf = makeLine(74); lines.cdt = makeLine(96); lines.tb = makeLine(118); lines.last = makeLine(140)
            lines.runtime.lbl.Text = "Runtime: 00h:00m:00s"; lines.bf.lbl.Text = "Blox: OFF"; lines.cdt.lbl.Text = "CDT Money: OFF"; lines.tb.lbl.Text = "Treasure: OFF"; lines.last.lbl.Text = "Last: Idle"
            STATE.Status = { frame = frame, lines = lines }
            -- draggable
            local dragging, dragInput, startMousePos, startFramePos = false, nil, Vector2.new(0,0), Vector2.new(0,0)
            local function getMouse() return UIS:GetMouseLocation() end
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; dragInput = input; startMousePos = getMouse(); startFramePos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                    input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false; dragInput = nil end end)
                end
            end)
            frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
            UIS.InputChanged:Connect(function(input)
                if not dragging then return end
                if dragInput and input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local mousePos = getMouse(); local delta = mousePos - startMousePos; local newAbs = startFramePos + delta
                local cam = workspace.CurrentCamera; local vp = (cam and cam.ViewportSize) or Vector2.new(800,600)
                local fw = frame.AbsoluteSize.X; local fh = frame.AbsoluteSize.Y
                newAbs = Vector2.new(math.clamp(newAbs.X, 0, math.max(0, vp.X - fw)), math.clamp(newAbs.Y, 0, math.max(0, vp.Y - fh)))
                frame.Position = UDim2.new(0, newAbs.X, 0, newAbs.Y)
            end)
        end)
    end
    function Status.UpdateRuntime() SAFE_CALL(function() if STATE.Status and STATE.Status.lines and STATE.Status.lines.runtime then STATE.Status.lines.runtime.lbl.Text = "Runtime: "..Utils.FormatTime(os.time() - STATE.StartTime) end end) end
    function Status.SetIndicator(name, on, text) SAFE_CALL(function() if not STATE.Status or not STATE.Status.lines or not STATE.Status.lines[name] then return end local ln = STATE.Status.lines[name]; if on then ln.dot.BackgroundColor3 = Color3.fromRGB(0,200,0) else ln.dot.BackgroundColor3 = Color3.fromRGB(200,0,0) end if text then ln.lbl.Text = text end end) end
    STATE.Status = STATE.Status or {}
    STATE.Status.Create = Status.Create
    STATE.Status.UpdateRuntime = Status.UpdateRuntime
    STATE.Status.SetIndicator = Status.SetIndicator
end

SAFE_CALL(function() if STATE.Status and STATE.Status.Create then STATE.Status.Create() end end)

-- UI build
local function buildUI()
    SAFE_CALL(function()
        STATE.Window = (STATE.Rayfield and STATE.Rayfield.CreateWindow) and STATE.Rayfield:CreateWindow({ Name = "G-MON Hub", LoadingTitle = "G-MON Hub", LoadingSubtitle = "Ready", ConfigurationSaving = { Enabled = false } }) or nil
        local Tabs = {}
        if STATE.Window then
            Tabs.Info = STATE.Window:CreateTab("Info")
            Tabs.TabBlox = STATE.Window:CreateTab("Blox Fruit")
            Tabs.TabCDT = STATE.Window:CreateTab("CDT Money")
            Tabs.TabTreasure = STATE.Window:CreateTab("Build A Boat")
            Tabs.Move = STATE.Window:CreateTab("Movement")
            Tabs.Debug = STATE.Window:CreateTab("Debug")
        else
            local function makeTab() return { CreateLabel=function() end, CreateParagraph=function() end, CreateButton=function() end, CreateToggle=function() end, CreateSlider=function() end } end
            Tabs.Info = makeTab(); Tabs.TabBlox = makeTab(); Tabs.TabCDT = makeTab(); Tabs.TabTreasure = makeTab(); Tabs.Move = makeTab(); Tabs.Debug = makeTab()
        end
        STATE.Tabs = Tabs

        SAFE_CALL(function()
            Tabs.Info:CreateLabel("G-MON Hub - client-only")
            Tabs.Info:CreateParagraph({ Title = "Detected", Content = Utils.ShortLabelForGame(STATE.GAME) })
            Tabs.Info:CreateButton({ Name = "Detect Now", Callback = function()
                SAFE_CALL(function()
                    local det = Utils.FlexibleDetectByAliases()
                    if det and det ~= "UNKNOWN" then
                        STATE.GAME = det
                        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(det), Duration=3}) end
                    else
                        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: Unknown", Duration=3}) end
                    end
                    STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
                    STATE.Status.SetIndicator("cdt", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "CDT: Available" or "CDT: N/A")
                    STATE.Status.SetIndicator("tb", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
                end)
            end })
            Tabs.Info:CreateButton({ Name = "Force CDT", Callback = function() STATE.GAME = "CAR_TYCOON"; STATE.Status.SetIndicator("cdt", true, "CDT: Forced") end })
            Tabs.Info:CreateButton({ Name = "Force Blox", Callback = function() STATE.GAME = "BLOX_FRUIT"; STATE.Status.SetIndicator("bf", true, "Blox: Forced") end })
            Tabs.Info:CreateButton({ Name = "Force Boat", Callback = function() STATE.GAME = "BUILD_A_BOAT"; STATE.Status.SetIndicator("tb", true, "Boat: Forced") end })
        end)

        SAFE_CALL(function()
            local t = Tabs.TabBlox
            t:CreateLabel("Blox Fruit Controls")
            t:CreateToggle({ Name = "Auto Farm (Blox)", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Blox.start) else SAFE_CALL(STATE.Modules.Blox.stop) end end })
            t:CreateToggle({ Name = "Fast Attack", CurrentValue = STATE.Modules.Blox.config.fast_attack, Callback = function(v) STATE.Modules.Blox.config.fast_attack = v end })
            t:CreateSlider({ Name = "Range Farming (studs)", Range = {1,50}, Increment = 1, CurrentValue = STATE.Modules.Blox.config.range or 10, Callback = function(v) STATE.Modules.Blox.config.range = v end })
        end)

        SAFE_CALL(function()
            local t = Tabs.TabCDT
            t:CreateLabel("CDT Money (Auto Farm Money Only)")
            t:CreateSlider({ Name = "Drive Speed", Range = {50,800}, Increment = 10, CurrentValue = STATE.Modules.CDT_Money.settings.speed or 300, Callback = function(v) STATE.Modules.CDT_Money.settings.speed = v end })
            t:CreateToggle({ Name = "Auto Drive Money", CurrentValue = false, Callback = function(v) STATE.Modules.CDT_Money.settings.autoDrive = v end })
            t:CreateToggle({ Name = "Auto Collectibles", CurrentValue = false, Callback = function(v) STATE.Modules.CDT_Money.settings.autoCollect = v end })
            t:CreateButton({ Name = "Start CDT Money Module", Callback = function() SAFE_CALL(STATE.Modules.CDT_Money.start) end })
            t:CreateButton({ Name = "Stop CDT Money Module", Callback = function() SAFE_CALL(STATE.Modules.CDT_Money.stop) end })
        end)

        SAFE_CALL(function()
            local t = Tabs.TabTreasure
            t:CreateLabel("Build A Boat (Haruka -> Treasure)")
            t:CreateToggle({ Name = "Treasure AutoFarm (Haruka)", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Build_A_Boat_For_Treasure.startAutoFarm) else SAFE_CALL(STATE.Modules.Build_A_Boat_For_Treasure.stopAutoFarm) end end })
            t:CreateToggle({ Name = "Treasure Gold Tracker", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Build_A_Boat_For_Treasure.startGoldTracker) else SAFE_CALL(STATE.Modules.Build_A_Boat_For_Treasure.stopGoldTracker) end end })
        end)

        SAFE_CALL(function()
            local t = Tabs.Move
            local flyEnabled = false; local flySpeed = 60; local flyY = 0
            t:CreateLabel("Movement")
            t:CreateToggle({ Name = "Fly", Callback = function(v) flyEnabled = v end })
            t:CreateSlider({ Name = "Fly Speed", Range = {20,150}, Increment = 5, CurrentValue = flySpeed, Callback = function(v) flySpeed = v end })
            RunService.RenderStepped:Connect(function()
                if not flyEnabled then return end
                pcall(function()
                    local c = Utils.SafeChar(); if not c then return end
                    local cam = workspace.CurrentCamera; if not cam then return end
                    local dir = Vector3.new(0,0,0)
                    if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                    local vel = Vector3.new(dir.X * flySpeed, flyY, dir.Z * flySpeed)
                    pcall(function() c.HumanoidRootPart.Velocity = vel end)
                end)
            end)
        end)

        SAFE_CALL(function()
            local t = Tabs.Debug
            t:CreateLabel("Debug")
            t:CreateButton({ Name = "Start All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.start); SAFE_CALL(STATE.Modules.CDT_Money.start); SAFE_CALL(STATE.Modules.Build_A_Boat_For_Treasure.startAutoFarm) end })
            t:CreateButton({ Name = "Stop All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.stop); SAFE_CALL(STATE.Modules.CDT_Money.stop); SAFE_CALL(STATE.Modules.Build_A_Boat_For_Treasure.stopAutoFarm); SAFE_CALL(STATE.Modules.Build_A_Boat_For_Treasure.stopGoldTracker) end })
        end)
    end)
end

local function ApplyGame(gameKey)
    STATE.GAME = gameKey or Utils.FlexibleDetectByAliases()
    SAFE_CALL(function()
        STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
        STATE.Status.SetIndicator("cdt", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "CDT: Available" or "CDT: N/A")
        STATE.Status.SetIndicator("tb", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
    end)
end

task.spawn(function()
    while true do
        SAFE_WAIT(1)
        SAFE_CALL(function()
            if STATE.Status and STATE.Status.UpdateRuntime then STATE.Status.UpdateRuntime() end
            if STATE.Status and STATE.Status.SetIndicator then STATE.Status.SetIndicator("last", false, "Last: "..(STATE.LastAction or "Idle")) end
        end)
    end
end)

local Main = {}
function Main.Start()
    SAFE_CALL(function()
        buildUI()
        local det = Utils.FlexibleDetectByAliases()
        STATE.GAME = det
        ApplyGame(STATE.GAME)
        Utils.AntiAFK()
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use tabs to control modules", Duration=5}) end
        print("[G-MON] main_final_gmon started. Detected game:", STATE.GAME)
    end)
    return true
end

return Main