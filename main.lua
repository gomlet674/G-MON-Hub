--[[
  G-MON Hub - main.lua (FINAL single-file)
  - Semua fungsi didefinisikan dulu
  - Dynamic UI (Rayfield) sesuai deteksi game
  - SAFE_CALL wrappers to avoid nil-call errors
  - Modules: Blox (AutoFarm), Car (AutoDrive), Boat (Auto Gold)
  - Fallback Rayfield/no-op UI if HttpGet blocked
  - Usage: paste into executor (LocalScript), run in-game (client)
--]]

-- ===== BOOTSTRAP =====
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local LP = Players.LocalPlayer

print("Something is wrong") 

-- ===== SAFE HELPERS =====
local function SAFE_CALL(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[G-MON] SAFE_CALL error:", res)
    end
    return ok, res
end

local function SAFE_WAIT(sec)
    sec = tonumber(sec) or 0.1
    if sec < 0.01 then sec = 0.01 end
    if sec > 2 then sec = 2 end
    task.wait(sec)
end

-- ===== STATE =====
local STATE = {
    GAME = "UNKNOWN",        -- detected game key
    StartTime = os.time(),
    Modules = {},            -- module tables
    Rayfield = nil, Window = nil, Tabs = {}, -- ui
    Status = nil,            -- status gui
    Flags = {},              -- feature flags (booleans)
    UIHandles = {},          -- store created control handles if needed
}

-- ===== UTILS & DETECTION =====
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
    -- returns "BLOX_FRUIT"/"CAR_TYCOON"/"BUILD_A_BOAT"/"UNKNOWN"
    local pid = game.PlaceId
    if pid == 2753915549 then return "BLOX_FRUIT" end
    if pid == 1554960397 then return "CAR_TYCOON" end
    if pid == 537413528 then return "BUILD_A_BOAT" end

    local aliasMap = {
        BLOX_FRUIT = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","Quests","NPCQuests"},
        CAR_TYCOON = {"Cars","VehicleFolder","Vehicles","Dealership","Garage","CarShop","CarStages","CarsFolder"},
        BUILD_A_BOAT = {"BoatStages","Stages","NormalStages","StageFolder","BoatStage","Chest","Treasure"}
    }
    for key, list in pairs(aliasMap) do
        for _, name in ipairs(list) do
            if workspace:FindFirstChild(name) then
                return key
            end
        end
    end
    -- heuristics by names
    for _, obj in ipairs(workspace:GetChildren()) do
        local n = string.lower(obj.Name or "")
        if string.find(n, "enemy") or string.find(n, "mob") or string.find(n, "monster") then return "BLOX_FRUIT" end
        if string.find(n, "car") or string.find(n, "vehicle") or string.find(n, "garage") then return "CAR_TYCOON" end
        if string.find(n, "boat") or string.find(n, "stage") or string.find(n, "chest") then return "BUILD_A_BOAT" end
    end
    return "UNKNOWN"
end

function Utils.ShortLabelForGame(g)
    if g == "BLOX_FRUIT" then return "Blox" end
    if g == "CAR_TYCOON" then return "Car" end
    if g == "BUILD_A_BOAT" then return "Boat" end
    return tostring(g or "Unknown")
end

STATE.Modules.Utils = Utils

-- ===== MODULES (declare functions BEFORE UI) =====

-- Blox module (AutoFarm / Fast Attack)
do
    local M = {}
    M.config = { attack_delay = 0.35, range = 10, long_range = false, fast_attack = false }
    M.running = false
    M._task = nil

    function M._loop()
        while M.running do
            task.wait(0.12)
            SAFE_CALL(function()
                if STATE.GAME ~= "BLOX_FRUIT" then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

                -- find enemy folder heuristics
                local folderHints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs"}
                local folder = nil
                for _, name in ipairs(folderHints) do local f = Workspace:FindFirstChild(name); if f then folder = f; break end end
                if not folder then return end

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
                else
                    pcall(function() hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
                    if M.config.fast_attack then
                        for i=1,3 do pcall(function() if nearest and nearest:FindFirstChild("Humanoid") then nearest.Humanoid:TakeDamage(30) end end) end
                    else
                        pcall(function() if nearest and nearest:FindFirstChild("Humanoid") then nearest.Humanoid:TakeDamage(18) end end)
                    end
                end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true
        STATE.Flags.Blox = true
        M._task = task.spawn(M._loop)
    end

    function M.stop()
        M.running = false
        STATE.Flags.Blox = false
        M._task = nil
    end

    STATE.Modules.Blox = M
end

-- Car module (Auto Drive)
do
    local M = {}
    M.running = false
    M.chosen = nil
    M.speed = 60
    M._task = nil

    local function isOwnedByPlayer(m)
        if not m or not m:IsA("Model") then return false end
        if tostring(m.Name) == tostring(LP.Name) then return true end
        local ok, ownerVal = pcall(function()
            local o = m:FindFirstChild("Owner") or m:FindFirstChild("OwnerName")
            if o then return tostring(o.Value) end
            if m.GetAttribute then return m:GetAttribute("Owner") end
            return nil
        end)
        if ok and ownerVal and tostring(ownerVal) == tostring(LP.Name) then return true end
        local ok2, idVal = pcall(function()
            local v = m:FindFirstChild("OwnerUserId") or m:FindFirstChild("UserId")
            if v then return tonumber(v.Value) end
            if m.GetAttribute then return m:GetAttribute("OwnerUserId") end
            return nil
        end)
        if ok2 and tonumber(idVal) and tonumber(idVal) == LP.UserId then return true end
        return false
    end

    function M.choosePlayerFastestCar()
        local carsRoot = Workspace:FindFirstChild("Cars") or Workspace
        local candidates = {}
        for _, m in ipairs(carsRoot:GetDescendants()) do
            if m:IsA("Model") and m.PrimaryPart then
                if isOwnedByPlayer(m) then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then
            for _, m in ipairs(Workspace:GetChildren()) do
                if m:IsA("Model") and m.PrimaryPart and #m:GetDescendants() > 5 then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then return nil end
        local best, bestVal = nil, -math.huge
        for _, car in ipairs(candidates) do
            local val = #car:GetDescendants()
            if val > bestVal then bestVal, best = val, car end
        end
        return best
    end

    local function ensureLinearVelocity(prim)
        if not prim then return nil end
        local att = prim:FindFirstChild("_GmonAttach")
        if not att then att = Instance.new("Attachment"); att.Name = "_GmonAttach"; att.Parent = prim end
        local lv = prim:FindFirstChild("_GmonLV")
        if not lv then
            lv = Instance.new("LinearVelocity")
            lv.Name = "_GmonLV"
            lv.Attachment0 = att
            lv.MaxForce = math.huge
            lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
            lv.Parent = prim
        end
        return lv, att
    end

    function M._loop()
        while M.running do
            task.wait(0.2)
            SAFE_CALL(function()
                if STATE.GAME ~= "CAR_TYCOON" then return end
                if not M.chosen or not M.chosen.PrimaryPart then
                    local car = M.choosePlayerFastestCar()
                    if not car or not car.PrimaryPart then STATE.Flags.Car = false; return end
                    M.chosen = car
                    if not car:FindFirstChild("_GmonStartPos") then
                        local cv = Instance.new("CFrameValue"); cv.Name = "_GmonStartPos"; cv.Value = car.PrimaryPart.CFrame; cv.Parent = car
                    end
                    pcall(function()
                        local orig = car.PrimaryPart.CFrame
                        car:SetPrimaryPartCFrame(CFrame.new(orig.Position.X, orig.Position.Y - 500, orig.Position.Z))
                    end)
                end
                if M.chosen and M.chosen.PrimaryPart then
                    local prim = M.chosen.PrimaryPart
                    local lv = ensureLinearVelocity(prim)
                    if lv then lv.VectorVelocity = prim.CFrame.LookVector * (M.speed or 60) end
                end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true
        STATE.Flags.Car = true
        M._task = task.spawn(M._loop)
    end

    function M.stop()
        M.running = false
        STATE.Flags.Car = false
        if M.chosen then
            SAFE_CALL(function()
                if M.chosen.PrimaryPart then
                    local prim = M.chosen.PrimaryPart
                    local lv = prim:FindFirstChild("_GmonLV"); if lv then pcall(function() lv:Destroy() end) end
                    local att = prim:FindFirstChild("_GmonAttach"); if att then pcall(function() att:Destroy() end) end
                end
                local tag = M.chosen:FindFirstChild("_GmonStartPos")
                if tag and tag:IsA("CFrameValue") and M.chosen.PrimaryPart then pcall(function() M.chosen:SetPrimaryPartCFrame(tag.Value) end); pcall(function() tag:Destroy() end) end
                local fv = M.chosen:FindFirstChild("_GmonFloorRef"); if fv and fv.Value and fv.Value.Parent then pcall(function() fv.Value:Destroy() end) end
                if M.chosen.GetAttribute and M.chosen:GetAttribute("GmonFloor") then pcall(function() M.chosen:SetAttribute("GmonFloor", nil) end) end
            end)
        end
        M.chosen = nil
    end

    STATE.Modules.Car = M
end

-- Boat module (Auto stages)
do
    local M = {}
    M.running = false
    M.delay = 1.5
    M._task = nil

    local function collectStages(root)
        local out = {}
        if not root then return out end
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("BasePart") then
                local lname = string.lower(obj.Name or "")
                local ok, col = pcall(function() return obj.Color end)
                local isDark = false
                if ok and col then if (col.R + col.G + col.B) / 3 < 0.2 then isDark = true end end
                if isDark or string.find(lname, "stage") or string.find(lname, "black") or string.find(lname, "dark") or string.find(lname, "trigger") then
                    table.insert(out, obj)
                end
            end
        end
        return out
    end

    function M._loop()
        while M.running do
            task.wait(0.2)
            SAFE_CALL(function()
                if STATE.GAME ~= "BUILD_A_BOAT" then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

                local roots = {}
                for _, n in ipairs({"BoatStages","Stages","NormalStages","StageFolder","BoatStage"}) do local r = Workspace:FindFirstChild(n); if r then table.insert(roots, r) end end
                if #roots == 0 then table.insert(roots, Workspace) end

                local stages = {}
                for _, r in ipairs(roots) do local s = collectStages(r); for _, p in ipairs(s) do table.insert(stages, p) end end
                if #stages == 0 then for _, obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") and string.find(string.lower(obj.Name or ""), "stage") then table.insert(stages, obj) end end end
                if #stages == 0 then STATE.Flags.Boat = false; M.running = false; return end

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
                    if not M.running then break end
                    if part and part.Parent then pcall(function() hrp.CFrame = part.CFrame * CFrame.new(0,3,0) end) end
                    SAFE_WAIT(M.delay or 1.5)
                end

                -- find chest
                local candidate = nil
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then local ln = string.lower(v.Name or ""); if string.find(ln, "chest") or string.find(ln, "treasure") or string.find(ln, "golden") then candidate = v; break end
                    elseif v:IsA("Model") and v.PrimaryPart then local ln = string.lower(v.Name or ""); if string.find(ln, "chest") or string.find(ln, "treasure") or string.find(ln, "golden") then candidate = v.PrimaryPart; break end
                    end
                end
                if candidate then pcall(function() hrp.CFrame = candidate.CFrame * CFrame.new(0,3,0) end) end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true
        STATE.Flags.Boat = true
        M._task = task.spawn(M._loop)
    end

    function M.stop()
        M.running = false
        STATE.Flags.Boat = false
        M._task = nil
    end

    STATE.Modules.Boat = M
end

-- ===== RAYFIELD LOAD (safe with fallback) =====
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        STATE.Rayfield = Ray
    else
        warn("[G-MON] Rayfield load failed; using minimal fallback UI.")
        -- minimal no-op UI that provides the functions used below
        local Fallback = {}
        function Fallback:CreateWindow(opts)
            local win = {}
            function win:CreateTab(name)
                local tab = {}
                function tab:CreateLabel() end
                function tab:CreateParagraph() end
                function tab:CreateButton(tbl) end
                function tab:CreateToggle(tbl) end
                function tab:CreateSlider(tbl) end
                return tab
            end
            function win:CreateNotification() end
            return win
        end
        function Fallback:Notify() end
        STATE.Rayfield = Fallback
    end
end

-- ===== STATUS GUI (draggable) =====
do
    local Status = {}
    function Status.Create()
        local ok = pcall(function()
            local pg = LP:WaitForChild("PlayerGui")
            local sg = Instance.new("ScreenGui")
            sg.Name = "GMonStatusGui"
            sg.ResetOnSpawn = false
            sg.Parent = pg

            local frame = Instance.new("Frame")
            frame.Name = "StatusFrame"
            frame.Size = UDim2.new(0, 320, 0, 170)
            frame.Position = UDim2.new(1, -330, 0, 10)
            frame.BackgroundTransparency = 0.12
            frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
            frame.BorderSizePixel = 0
            frame.Parent = sg

            local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,8); corner.Parent = frame

            local title = Instance.new("TextLabel")
            title.Parent = frame
            title.Size = UDim2.new(1, -16, 0, 24)
            title.Position = UDim2.new(0,8,0,6)
            title.BackgroundTransparency = 1
            title.Text = "G-MON Status"
            title.TextColor3 = Color3.fromRGB(255,255,255)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Font = Enum.Font.SourceSansBold
            title.TextSize = 16

            local sub = Instance.new("TextLabel")
            sub.Parent = frame
            sub.Size = UDim2.new(1, -16, 0, 18)
            sub.Position = UDim2.new(0,8,0,30)
            sub.BackgroundTransparency = 1
            sub.Text = Utils.ShortLabelForGame(STATE.GAME)
            sub.TextColor3 = Color3.fromRGB(200,200,200)
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.Font = Enum.Font.SourceSans
            sub.TextSize = 12

            local function makeLine(y)
                local holder = Instance.new("Frame"); holder.Parent = frame
                holder.Size = UDim2.new(1, -16, 0, 20); holder.Position = UDim2.new(0,8,0,y)
                holder.BackgroundTransparency = 1
                local dot = Instance.new("Frame"); dot.Parent = holder
                dot.Size = UDim2.new(0, 12, 0, 12); dot.Position = UDim2.new(0, 0, 0, 4)
                dot.BackgroundColor3 = Color3.fromRGB(200,0,0)
                local lbl = Instance.new("TextLabel"); lbl.Parent = holder
                lbl.Size = UDim2.new(1, -18, 1, 0); lbl.Position = UDim2.new(0, 18, 0, 0)
                lbl.BackgroundTransparency = 1; lbl.Text = ""; lbl.TextColor3 = Color3.fromRGB(230,230,230)
                lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
                return {dot = dot, lbl = lbl}
            end

            local lines = {}
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

            STATE.Status = { frame = frame, lines = lines }
            -- draggable handled lightly
            local dragging = false; local dragInput = nil; local startMousePos = Vector2.new(0,0); local startFramePos = Vector2.new(0,0)
            local function getMousePos() return UIS:GetMouseLocation() end
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; dragInput = input; startMousePos = getMousePos(); startFramePos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                    input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false; dragInput = nil end end)
                end
            end)
            frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
            UIS.InputChanged:Connect(function(input)
                if not dragging then return end
                if dragInput and input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local mousePos = getMousePos(); local delta = mousePos - startMousePos; local newAbs = startFramePos + delta
                local cam = workspace.CurrentCamera; local vp = (cam and cam.ViewportSize) or Vector2.new(800,600); local fw = frame.AbsoluteSize.X; local fh = frame.AbsoluteSize.Y
                newAbs = Vector2.new(math.clamp(newAbs.X, 0, math.max(0, vp.X - fw)), math.clamp(newAbs.Y, 0, math.max(0, vp.Y - fh)))
                frame.Position = UDim2.new(0, newAbs.X, 0, newAbs.Y)
            end)
        end)
    end

    function Status.UpdateRuntime()
        SAFE_CALL(function() if STATE.Status and STATE.Status.lines and STATE.Status.lines.runtime then STATE.Status.lines.runtime.lbl.Text = "Runtime: "..Utils.FormatTime(os.time() - STATE.StartTime) end end)
    end

    function Status.SetIndicator(name, on, text)
        SAFE_CALL(function()
            if not STATE.Status or not STATE.Status.lines or not STATE.Status.lines[name] then return end
            local ln = STATE.Status.lines[name]
            if on then ln.dot.BackgroundColor3 = Color3.fromRGB(0,200,0) else ln.dot.BackgroundColor3 = Color3.fromRGB(200,0,0) end
            if text then ln.lbl.Text = text end
        end)
    end

    STATE.Status = STATE.Status or {}
    STATE.Status.Create = Status.Create
    STATE.Status.UpdateRuntime = Status.UpdateRuntime
    STATE.Status.SetIndicator = Status.SetIndicator
end

-- create status gui
SAFE_CALL(function() if STATE.Status and STATE.Status.Create then STATE.Status.Create() end end)

-- ===== UI BUILDING: dynamic, after modules declared =====
-- Note: Rayfield may be fallback (no-op). All UI callbacks call functions that are already defined.
SAFE_CALL(function()
    -- ensure window & tabs exist
    STATE.Window = (STATE.Rayfield and STATE.Rayfield.CreateWindow) and STATE.Rayfield:CreateWindow({
        Name = "G-MON Hub",
        LoadingTitle = "G-MON Hub",
        LoadingSubtitle = "Ready",
        ConfigurationSaving = { Enabled = false }
    }) or nil

    if STATE.Window then
        STATE.Tabs.Info = STATE.Window:CreateTab("Info")
        STATE.Tabs.Fitur = STATE.Window:CreateTab("Fitur")
        STATE.Tabs.Move = STATE.Window:CreateTab("Movement")
        STATE.Tabs.Debug = STATE.Window:CreateTab("Debug")
    else
        -- fallback: create dummy tables with noop functions so code below can call safely
        local function noop() end
        local function makeTab()
            return {
                CreateLabel = noop, CreateParagraph = noop, CreateButton = noop,
                CreateToggle = noop, CreateSlider = noop
            }
        end
        STATE.Tabs.Info = makeTab()
        STATE.Tabs.Fitur = makeTab()
        STATE.Tabs.Move = makeTab()
        STATE.Tabs.Debug = makeTab()
    end

    local Tabs = STATE.Tabs

    -- Info tab: detection status and override
    Tabs.Info:CreateLabel("G-MON Hub - client-only. Use only in private/testing places.")
    local detectNowBtn = Tabs.Info:CreateButton and Tabs.Info:CreateButton({
        Name = "Detect Game Now",
        Callback = function()
            SAFE_CALL(function()
                local detected = Utils.FlexibleDetectByAliases()
                if detected and detected ~= "UNKNOWN" then
                    STATE.GAME = detected
                    if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(detected), Duration=3}) end
                else
                    if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detect: Unknown", Duration=3}) end
                end
                -- rebuild feature controls
                if buildFeatureControls then SAFE_CALL(buildFeatureControls) end
            end)
        end
    }) or nil

    Tabs.Info:CreateButton({ Name = "Force Blox", Callback = function() STATE.GAME = "BLOX_FRUIT"; SAFE_CALL(buildFeatureControls); if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Forced: Blox", Duration=2}) end end })
    Tabs.Info:CreateButton({ Name = "Force Car", Callback = function() STATE.GAME = "CAR_TYCOON"; SAFE_CALL(buildFeatureControls); if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Forced: Car", Duration=2}) end end })
    Tabs.Info:CreateButton({ Name = "Force Boat", Callback = function() STATE.GAME = "BUILD_A_BOAT"; SAFE_CALL(buildFeatureControls); if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Forced: Boat", Duration=2}) end end })
    Tabs.Info:CreateParagraph({ Title = "Note", Content = "If detection is wrong, use Force buttons. UI will rebuild accordingly." })

    -- Build feature controls based on STATE.GAME
    function buildFeatureControls()
        -- STOP all modules first to avoid duplicates
        SAFE_CALL(function()
            if STATE.Modules.Blox and STATE.Modules.Blox.stop then STATE.Modules.Blox.stop() end
            if STATE.Modules.Car and STATE.Modules.Car.stop then STATE.Modules.Car.stop() end
            if STATE.Modules.Boat and STATE.Modules.Boat.stop then STATE.Modules.Boat.stop() end
        end)

        local g = STATE.GAME or Utils.FlexibleDetectByAliases()
        STATE.GAME = g

        -- update status labels if present
        SAFE_CALL(function()
            if STATE.Status and STATE.Status.SetIndicator then
                STATE.Status.SetIndicator("bf", g=="BLOX_FRUIT", (g=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
                STATE.Status.SetIndicator("car", g=="CAR_TYCOON", (g=="CAR_TYCOON") and "Car: Available" or "Car: N/A")
                STATE.Status.SetIndicator("boat", g=="BUILD_A_BOAT", (g=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
            end
        end)

        -- Create controls in Fitur tab only for relevant game
        -- Rayfield UI does not provide remove; to avoid duplicates, we rely on re-run / single instance usage.
        if g == "BLOX_FRUIT" then
            Tabs.Fitur:CreateLabel("Blox Fruit Controls")
            Tabs.Fitur:CreateToggle({ Name = "Auto Farm (Blox)", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Blox.start) else SAFE_CALL(STATE.Modules.Blox.stop) end end })
            Tabs.Fitur:CreateToggle({ Name = "Long Range Hit", CurrentValue = STATE.Modules.Blox.config.long_range, Callback = function(v) STATE.Modules.Blox.config.long_range = v end })
            Tabs.Fitur:CreateToggle({ Name = "Fast Attack (client)", CurrentValue = STATE.Modules.Blox.config.fast_attack, Callback = function(v) STATE.Modules.Blox.config.fast_attack = v end })
            Tabs.Fitur:CreateSlider({ Name = "Attack Delay (ms)", Range = {50,1000}, Increment = 25, CurrentValue = math.floor((STATE.Modules.Blox.config.attack_delay or 0.35)*1000), Callback = function(v) STATE.Modules.Blox.config.attack_delay = v/1000 end })
            Tabs.Fitur:CreateSlider({ Name = "Range Farming (studs)", Range = {1,50}, Increment = 1, CurrentValue = STATE.Modules.Blox.config.range or 10, Callback = function(v) STATE.Modules.Blox.config.range = v end })
        elseif g == "CAR_TYCOON" then
            Tabs.Fitur:CreateLabel("Car Tycoon Controls")
            Tabs.Fitur:CreateToggle({ Name = "Car AutoDrive", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Car.start) else SAFE_CALL(STATE.Modules.Car.stop) end end })
            Tabs.Fitur:CreateSlider({ Name = "Car Speed", Range = {20,200}, Increment = 5, CurrentValue = STATE.Modules.Car.speed or 60, Callback = function(v) STATE.Modules.Car.speed = v end })
        elseif g == "BUILD_A_BOAT" then
            Tabs.Fitur:CreateLabel("Build A Boat Controls")
            Tabs.Fitur:CreateToggle({ Name = "Boat Auto Stages", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Boat.start) else SAFE_CALL(STATE.Modules.Boat.stop) end end })
            Tabs.Fitur:CreateSlider({ Name = "Stage Delay (s)", Range = {0.5,6}, Increment = 0.5, CurrentValue = STATE.Modules.Boat.delay or 1.5, Callback = function(v) STATE.Modules.Boat.delay = v end })
        else
            Tabs.Fitur:CreateLabel("No auto features detected for this place. Use Info tab to force.")
        end
    end

    -- initial build
    local detected = Utils.FlexibleDetectByAliases()
    STATE.GAME = detected
    SAFE_CALL(buildFeatureControls)

    -- Movement tab: lightweight fly
    local flyEnabled = false; local flySpeed = 60; local flyY = 0
    Tabs.Move:CreateToggle({ Name = "Fly", Callback = function(v) flyEnabled = v end })
    Tabs.Move:CreateSlider({ Name = "Fly Speed", Range = {20,150}, Increment = 5, CurrentValue = flySpeed, Callback = function(v) flySpeed = v end })
    Tabs.Move:CreateSlider({ Name = "Fly Y", Range = {-60,60}, Increment = 1, CurrentValue = flyY, Callback = function(v) flyY = v end })
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

    -- Debug
    Tabs.Debug:CreateButton({ Name = "Force Start All", Callback = function() SAFE_CALL(STATE.Modules.Blox.start); SAFE_CALL(STATE.Modules.Car.start); SAFE_CALL(STATE.Modules.Boat.start) end })
    Tabs.Debug:CreateButton({ Name = "Stop All", Callback = function() SAFE_CALL(STATE.Modules.Blox.stop); SAFE_CALL(STATE.Modules.Car.stop); SAFE_CALL(STATE.Modules.Boat.stop) end })
end)

-- ===== STATUS UPDATER =====
task.spawn(function()
    while true do
        SAFE_WAIT(1)
        SAFE_CALL(function()
            if STATE.Status and STATE.Status.UpdateRuntime then STATE.Status.UpdateRuntime() end
            if STATE.Status and STATE.Status.SetIndicator then
                STATE.Status.SetIndicator("last", false, "Last: "..(STATE.LastAction or "Idle"))
            end
        end)
    end
end)

-- ===== ANTI AFK =====
SAFE_CALL(function() Utils.AntiAFK() end)

-- ===== STAGED AUTO-INIT (lazy) =====
task.spawn(function()
    SAFE_WAIT(1)
    SAFE_CALL(function() if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Initializing...", Duration=3}) end end)
    SAFE_WAIT(3)
    SAFE_CALL(function()
        -- final detection, but do not auto-start modules (let user toggle)
        local det = Utils.FlexibleDetectByAliases()
        if det and det ~= "UNKNOWN" then STATE.GAME = det end
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(STATE.GAME), Duration=3}) end
    end)
end)

print("[G-MON] main.lua loaded. Detected game:", STATE.GAME)