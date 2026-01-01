-- main.lua (G-MON Hub merged + Haruka + Dealership)
-- NOTE: keep backup of previous scripts before running.

-- BOOTSTRAP
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- SAFE helpers
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

-- STATE
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

-- UTILS
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

-- Flexible detection (kept as in your script)
function Utils.FlexibleDetectByAliases()
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
            if Workspace:FindFirstChild(name) then return key end
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
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

-- ================= Blox Module (unchanged logic but uses detection toggle)
do
    local M = {}
    M.config = { attack_delay = 0.35, range = 10, long_range = false, fast_attack = false }
    M.running = false
    M._task = nil

    local function findEnemyFolder()
        local hints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs"}
        for _, name in ipairs(hints) do
            local f = Workspace:FindFirstChild(name)
            if f then return f end
        end
        return nil
    end

    local function loop()
        while M.running do
            task.wait(0.12)
            SAFE_CALL(function()
                -- only run if detected or forced Blox (keep behavior)
                if STATE.GAME ~= "BLOX_FRUIT" and STATE.GAME ~= "ALL" then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local folder = findEnemyFolder()
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

    function M.start()
        if M.running then return end
        M.running = true
        STATE.Flags.Blox = true
        M._task = task.spawn(loop)
    end
    function M.stop()
        M.running = false
        STATE.Flags.Blox = false
        M._task = nil
    end
    function M.ExposeConfig()
        return {
            { type="slider", name="Range (studs)", min=1, max=50, current=M.config.range, onChange=function(v) M.config.range = v end },
            { type="slider", name="Attack Delay (ms)", min=50, max=1000, current=math.floor(M.config.attack_delay*1000), onChange=function(v) M.config.attack_delay = v/1000 end },
            { type="toggle", name="Fast Attack", current=M.config.fast_attack, onChange=function(v) M.config.fast_attack = v end },
            { type="toggle", name="Long Range Hit", current=M.config.long_range, onChange=function(v) M.config.long_range = v end }
        }
    end
    STATE.Modules.Blox = M
end

-- ================= Car Module (kept but will only run if STATE.GAME allows) ==============
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

    local function loop()
        while M.running do
            task.wait(0.2)
            SAFE_CALL(function()
                if STATE.GAME ~= "CAR_TYCOON" and STATE.GAME ~= "ALL" then return end
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
        M.running = true; STATE.Flags.Car = true
        M._task = task.spawn(loop)
    end

    function M.stop()
        M.running = false; STATE.Flags.Car = false
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

    function M.ExposeConfig()
        return {
            { type="slider", name="Car Speed", min=20, max=200, current=M.speed, onChange=function(v) M.speed = v end }
        }
    end

    STATE.Modules.Car = M
end

-- ================= Boat Module (kept) =================
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

    local function loop()
        while M.running do
            task.wait(0.2)
            SAFE_CALL(function()
                if STATE.GAME ~= "BUILD_A_BOAT" and STATE.GAME ~= "ALL" then return end
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
        M._task = task.spawn(loop)
    end

    function M.stop()
        M.running = false
        STATE.Flags.Boat = false
        M._task = nil
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Stage Delay (s)", min=0.5, max=6, current=M.delay, onChange=function(v) M.delay = v end }
        }
    end

    STATE.Modules.Boat = M
end

-- ================= HARUKA MODULE =================
do
    local M = {}
    M.autoRunning = false
    M.goldRunning = false
    M._autoTask = nil
    M._goldTask = nil
    M._goldGui = nil
    M._charConn = nil

    local function getLocalChar()
        local ok, c = pcall(function() return Players.LocalPlayer and Players.LocalPlayer.Character end)
        if not ok then return nil end
        if c and c.Parent then return c end
        return nil
    end

    local function haruka_auto_loop()
        local character = getLocalChar()
        while M.autoRunning do
            if not character or not character.Parent then
                task.wait(1)
                character = getLocalChar()
                if not character then task.wait(0.5) end
            end

            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1); character = getLocalChar(); goto cont end

            local velObj = Instance.new("BodyVelocity")
            velObj.Name = "_HarukaVel"
            velObj.MaxForce = Vector3.new(1e5,1e5,1e5)
            velObj.Velocity = Vector3.new(0, -0.1, 0)
            velObj.Parent = hrp

            pcall(function() hrp.CFrame = CFrame.new(-135.900,72,623.750) end)

            while hrp and hrp.CFrame and hrp.CFrame.Z < 8600.75 and M.autoRunning do
                for i=1,50 do
                    if not M.autoRunning then break end
                    if hrp then pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0,0,0.3) end) end
                end
                task.wait(0.1)
            end

            if velObj and velObj.Parent then pcall(function() velObj:Destroy() end) end

            if M.autoRunning then
                pcall(function() hrp.CFrame = CFrame.new(-150.900,72,2000.750) end); task.wait(0.2)
                pcall(function() hrp.CFrame = CFrame.new(-150.900,72,2500.750) end); task.wait(0.5)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9488.1377) end); task.wait(0.5)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9495.1377) end); task.wait(1)
                pcall(function() hrp.CFrame = CFrame.new(-205.900,20,1700.750) end); task.wait(2.3)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9488.1377) end); task.wait(0.6)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9495.1377) end); task.wait(1.4)
                pcall(function() hrp.CFrame = CFrame.new(-55.8801956,-361.116333,9488.1377) end)
            end
            ::cont::
            task.wait(0.25)
        end
    end

    function M.startAutoFarm()
        if M.autoRunning then return end
        M.autoRunning = true; STATE.Flags.HarukaAuto = true
        if M._autoTask == nil then M._autoTask = task.spawn(haruka_auto_loop) end
        if M._charConn == nil then
            M._charConn = Players.LocalPlayer.CharacterAdded:Connect(function()
                task.wait(2)
                if M.autoRunning and M._autoTask == nil then M._autoTask = task.spawn(haruka_auto_loop) end
            end)
        end
    end

    function M.stopAutoFarm()
        M.autoRunning = false; STATE.Flags.HarukaAuto = false
        M._autoTask = nil
        if M._charConn then pcall(function() M._charConn:Disconnect() end); M._charConn = nil end
    end

    -- Gold tracker (lightweight)
    local function create_gold_gui()
        local player = Players.LocalPlayer
        if not player then return nil end
        local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        local GoldGui = Instance.new("ScreenGui")
        GoldGui.Name = "HarukaGoldTracker"
        GoldGui.ResetOnSpawn = false
        GoldGui.Parent = pg

        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 280, 0, 160)
        Frame.Position = UDim2.new(0, 10, 0, 10)
        Frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
        Frame.BackgroundTransparency = 0.1
        Frame.BorderSizePixel = 0
        Frame.Parent = GoldGui

        local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0,10); Corner.Parent = Frame
        local Stroke = Instance.new("UIStroke"); Stroke.Color = Color3.fromRGB(50,50,50); Stroke.Thickness = 2; Stroke.Parent = Frame

        local labels = {}
        local texts = {"Start Balance:", "Current:", "Earned:", "Uptime:"}
        for i, t in ipairs(texts) do
            local holder = Instance.new("Frame"); holder.Size = UDim2.new(1,-20,0,30); holder.Position = UDim2.new(0,10,0,15+(i-1)*35); holder.BackgroundTransparency = 1; holder.Parent = Frame
            local left = Instance.new("TextLabel"); left.Size = UDim2.new(0.6,0,1,0); left.Text = t; left.TextColor3 = Color3.fromRGB(180,180,180); left.BackgroundTransparency = 1; left.TextSize = 14; left.Font = Enum.Font.Gotham; left.TextXAlignment = Enum.TextXAlignment.Left; left.Parent = holder
            local right = Instance.new("TextLabel"); right.Size = UDim2.new(0.4,0,1,0); right.Position = UDim2.new(0.6,0,0,0); right.Text = "0"; right.TextColor3 = Color3.fromRGB(255,255,255); right.BackgroundTransparency = 1; right.TextSize = 14; right.Font = Enum.Font.GothamBold; right.TextXAlignment = Enum.TextXAlignment.Right; right.Parent = holder
            labels[i] = right
        end

        return {Gui = GoldGui, Labels = labels, StartTime = os.time()}
    end

    local function try_find_amount_label(root)
        if not root then return nil end
        local function findRec(n)
            local out = {}
            if n:IsA("TextLabel") then table.insert(out, n) end
            for _,c in ipairs(n:GetChildren()) do
                for _,v in ipairs(findRec(c)) do table.insert(out, v) end
            end
            return out
        end
        local candidates = findRec(root)
        for _, lbl in ipairs(candidates) do
            local ok, txt = pcall(function() return tostring(lbl.Text or "") end)
            if not ok or not txt then goto contlbl end
            local cleaned = txt:gsub("%s",""):gsub(",","")
            local digits = cleaned:match("(%d+)")
            if digits and tonumber(digits) then return lbl end
            ::contlbl::
        end
        for _, child in ipairs(root:GetDescendants()) do
            if child:IsA("TextLabel") then
                local ok, txt = pcall(function() return tostring(child.Text or "") end)
                if ok and txt then
                    local cleaned = txt:gsub("%s",""):gsub(",","")
                    local digits = cleaned:match("(%d+)")
                    if digits and tonumber(digits) then return child end
                end
            end
        end
        return nil
    end

    local function gold_loop(stateObj)
        if not stateObj then return end
        local player = Players.LocalPlayer
        if not player then return end
        local Mroot = player:FindFirstChild("PlayerGui")
        local startLabel = nil
        local baseAmount = 0
        stateObj.Labels[1].Text = "0"; stateObj.Labels[2].Text = "0"; stateObj.Labels[3].Text = "0"; stateObj.Labels[4].Text = "00:00"
        while M.goldRunning do
            if Mroot then
                local found = nil
                if Mroot:FindFirstChild("GoldGui") and Mroot.GoldGui:FindFirstChild("Frame") then
                    local ok, frame = pcall(function() return Mroot.GoldGui.Frame end)
                    if ok and frame then found = try_find_amount_label(frame) end
                end
                if not found then
                    for _, child in ipairs(Mroot:GetDescendants()) do
                        if child:IsA("TextLabel") then
                            local ok, txt = pcall(function() return tostring(child.Text or "") end)
                            if ok and txt then
                                local cleaned = txt:gsub("%s",""):gsub(",","")
                                local digits = cleaned:match("(%d+)")
                                if digits and tonumber(digits) then found = child; break end
                            end
                        end
                    end
                end
                if found and (not startLabel) then startLabel = found; baseAmount = tonumber((found.Text:gsub("[^%d]",""))) or 0 end
                if found then
                    local cur = tonumber((found.Text:gsub("[^%d]",""))) or 0
                    stateObj.Labels[2].Text = tostring(cur)
                    if cur > baseAmount then
                        local earned = tonumber(stateObj.Labels[3].Text) or 0
                        earned = earned + (cur - baseAmount)
                        stateObj.Labels[3].Text = tostring(earned)
                        baseAmount = cur
                    elseif cur < baseAmount then
                        baseAmount = cur
                    end
                end
            end
            local elapsed = os.time() - stateObj.StartTime
            local mm = math.floor(elapsed/60); local ss = elapsed%60
            stateObj.Labels[4].Text = string.format("%02d:%02d", mm, ss)
            task.wait(1)
        end
    end

    function M.startGoldTracker()
        if M.goldRunning then return end
        M.goldRunning = true; STATE.Flags.HarukaGold = true
        local obj = create_gold_gui()
        if obj then M._goldGui = obj if M._goldTask == nil then M._goldTask = task.spawn(function() gold_loop(obj) end) end end
    end

    function M.stopGoldTracker()
        M.goldRunning = false; STATE.Flags.HarukaGold = false
        if M._goldGui and M._goldGui.Gui and M._goldGui.Gui.Parent then pcall(function() M._goldGui.Gui:Destroy() end) end
        M._goldGui = nil; M._goldTask = nil
    end

    function M.ExposeConfig()
        return {
            { type="toggle", name="Haruka AutoFarm", current=false, onChange=function(v) if v then M.startAutoFarm() else M.stopAutoFarm() end end },
            { type="toggle", name="Haruka Gold Tracker", current=false, onChange=function(v) if v then M.startGoldTracker() else M.stopGoldTracker() end end }
        }
    end

    STATE.Modules.Haruka = M
end

-- ============== Dealership Module (from user script) =================
do
    local D = {}
    D.running = false
    D.uiReady = false
    D.lib = nil
    D.windows = {}

    -- races helper (as you provided)
    local function races()
        local tab = {"None"}
        if workspace:FindFirstChild("Races") then
            for i,v in pairs(workspace.Races:GetChildren()) do
                if v:IsA("Model") then
                    table.insert(tab,v.Name)
                end
            end
        end
        return tab
    end

    -- safe anti AFK (duplicate ok)
    local vu = game:GetService("VirtualUser")
    pcall(function()
        Players.LocalPlayer.Idled:Connect(function()
           vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
           wait(1)
           vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
    end)

    -- namecall hook: capture certain remote calls; fixed arg checks
    local ok_mt, mt = pcall(function() return getrawmetatable(game) end)
    local namecall
    if ok_mt and mt then
        setreadonly(mt, false)
        namecall = mt.__namecall
        local new_namecall = newcclosure(function(self, ...)
            local Method = getnamecallmethod()
            local Args = {...}
            -- helper to safely read table field
            local function tableAction(a)
                if type(a) == "table" and a.Action then return a.Action end
                return nil
            end
            -- intercepts
            if Method == 'FireServer' and tostring(self.Name) == "JobRemoteHandler" and tableAction(Args[1]) == "StartDeliveryJob" then
                _G.remotetable = Args
            elseif Method == 'FireServer' and tostring(self.Name) == "StartLobby" then
                _G.remotetable1 = Args; _G.remote1 = self
            elseif Method == 'FireServer' and tostring(self.Name) == "Vote" and Args[2] == "Vote" or Method == 'FireServer' and tostring(self.Name) == "Vote" and Args[2] == "VoteRace" then
                _G.remotetable2 = Args; _G.remote2 = self
            elseif Method == 'FireServer' and tostring(self.Name) == "Vote" and type(Args[2])=="string" and string.find(tostring(Args[2]),"Vote") and Args[2] ~= "Vote" and  Args[2] ~= "VoteRace" then
                _G.remotetable3 = Args; _G.remote3 = self
            elseif (Method == 'Raycast' or Method == 'Ray') and (_G.racetest or _G.racetest2) then
                if type(Args) == "table" and Args[2] then
                    Args[2] = Vector3.new(0,-1000,0)
                end
            elseif Method == 'FireServer' and tostring(self.Name) == "NPCHandler" and tableAction(Args[1]) == "DeclineOrder" then
                return
            end
            return namecall(self, ...)
        end)
        mt.__namecall = new_namecall
        setreadonly(mt, true)
    end

    -- create UI using your library (cleaned & safer)
    function D.start()
        if D.running then return end
        D.running = true
        task.spawn(function()
            -- try to load UI lib (your linked library)
            local success, library = pcall(function()
                return loadstring(game:HttpGet("https://raw.githubusercontent.com/Marco8642/science/main/ui%20libs2", true))()
            end)
            if not success or not library then
                warn("Dealership UI lib failed to load")
                D.running = false
                return
            end
            D.lib = library
            -- Create windows (we will create a few windows like your script)
            -- Vehicle Dealership window
            local ok, example = pcall(function()
                return library:CreateWindow({ text = "Vehicle Dealership" })
            end)
            if not ok or not example then
                warn("failed to create dealership window")
                D.running = false
                return
            end

            -- EXAMPLE: Add controls (mirroring the provided script, but safe)
            -- Speed input
            example:AddBox("Enter Auto Drive Speed", function(object, focus)
                if focus then
                    _G.speed = tonumber(object.Text) or _G.speed
                end
            end)

            -- Auto Farm (vehicle) toggle
            example:AddToggle("Auto Farm", function(state)
                _G.auto = (state and true or false)
                -- ensure gravity restored
                workspace.Gravity = workspace.Gravity or workspace.Gravity
                task.spawn(function()
                    while _G.auto do
                        task.wait()
                        local chr = Players.LocalPlayer.Character
                        if not chr then break end
                        local seat = chr:FindFirstChild("Humanoid") and chr.Humanoid.SeatPart
                        if not seat then task.wait(1); continue end
                        local car = seat.Parent and seat.Parent.Parent or nil
                        if not car or not car.PrimaryPart then task.wait(1); continue end

                        if not workspace:FindFirstChild("justapart") then
                            local new = Instance.new("Part", workspace)
                            new.Name = "justapart"
                            new.Size = Vector3.new(10000,20,10000)
                            new.Anchored = true
                            new.Position = chr.HumanoidRootPart.Position + Vector3.new(0,1000,0)
                        end
                        local justapart = workspace:FindFirstChild("justapart")
                        if not justapart then task.wait(1); continue end
                        local speed = tonumber(_G.speed) or 300
                        local destCFrame = justapart.CFrame * CFrame.new(0,10,-1000)
                        -- pivot to start far forward then tween back
                        car:PivotTo(justapart.CFrame * CFrame.new(0,10,1000))
                        local pos = justapart.CFrame * CFrame.new(0,10,-1000)
                        local dist = (car.PrimaryPart.Position - pos.Position).magnitude
                        car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
                        local TweenService = game:GetService("TweenService")
                        local TweenInfoToUse = TweenInfo.new((dist / speed), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, true, 0)
                        local TweenValue = Instance.new("CFrameValue")
                        TweenValue.Value = car:GetPrimaryPartCFrame()
                        TweenValue.Changed:Connect(function()
                            if car and car.PrimaryPart then
                                car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
                                car:PivotTo(TweenValue.Value)
                                car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
                            end
                        end)
                        local OnTween = TweenService:Create(TweenValue, TweenInfoToUse, {Value = pos})
                        OnTween:Play()
                        OnTween.Completed:Wait()
                        if car and car.PrimaryPart then car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed end
                        task.wait(0.3)
                    end
                end)
            end)

            -- Auto Collectibles
            example:AddToggle("Auto Farm Collectibles ", function(state)
                _G.collectables = (state and true or false)
                task.spawn(function()
                    while _G.collectables do
                        task.wait()
                        local chr = Players.LocalPlayer.Character
                        if not chr then break end
                        local seat = chr:FindFirstChild("Humanoid") and chr.Humanoid.SeatPart
                        if not seat or not seat.Parent then task.wait(0.6); continue end
                        local car = seat.Parent.Parent
                        if not car then task.wait(1); continue end
                        local collect = workspace:FindFirstChild("Collectibles")
                        if not collect then task.wait(1); continue end
                        for _,v in pairs(collect:GetDescendants()) do
                            if v:IsA("Model") and v.PrimaryPart and v.Parent and v.Parent.Parent == collect then
                                -- some games use billboard gui visibility; check safely
                                local ok, enabled = pcall(function()
                                    local gui = v:GetChildren()[2] and v:GetChildren()[2]:FindFirstChild("Part") and v:GetChildren()[2]:FindFirstChild("Part"):FindFirstChildOfClass("BillboardGui")
                                    return gui and gui.Enabled
                                end)
                                if ok and enabled then
                                    car:PivotTo(v.PrimaryPart.CFrame)
                                    break
                                end
                            end
                        end
                    end
                end)
            end)

            -- many other features from your script are heavy and game-specific.
            -- For brevity & safety: implement them as modular toggles which call safe functions.
            -- Auto Open Vehicle Kit
            example:AddToggle("Auto Open Vehicle Kit", function(state)
                _G.open = (state and true or false)
                task.spawn(function()
                    while _G.open do
                        task.wait(0.8)
                        pcall(function()
                            if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Services") and ReplicatedStorage.Remotes.Services:FindFirstChild("CarKitEventServiceRemotes") and ReplicatedStorage.Remotes.Services.CarKitEventServiceRemotes:FindFirstChild("ClaimFreePack") then
                                ReplicatedStorage.Remotes.Services.CarKitEventServiceRemotes.ClaimFreePack:InvokeServer()
                            end
                        end)
                    end
                end)
            end)

            -- Auto Extinguish Fire (simplified safe version)
            example:AddToggle("Auto Extinguish Fire", function(state)
                _G.fireman = (state and true or false)
                task.spawn(function()
                    while _G.fireman do
                        task.wait()
                        pcall(function()
                            workspace.Gravity = 196
                            local plr = Players.LocalPlayer
                            if not plr then return end
                            local char = plr.Character
                            if not char then return end
                            if not plr.Backpack:FindFirstChildOfClass("Tool") and not char:FindFirstChildOfClass("Tool") then
                                if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Switch") then
                                    ReplicatedStorage.Remotes.Switch:FireServer("FireDealership")
                                end
                                task.wait(10)
                            elseif plr.Backpack:FindFirstChildOfClass("Tool") then
                                pcall(function() char.Humanoid:EquipTool(plr.Backpack:FindFirstChildOfClass("Tool")) end)
                                task.wait(1)
                            elseif char:FindFirstChildOfClass("Tool") then
                                if plr.PlayerGui:FindFirstChild("FireGuide") then
                                    -- attempt to move to FirePart
                                    local test = nil
                                    for i,v in pairs(workspace:GetDescendants()) do
                                        if v.Name == "FirePart" then test = v; char.HumanoidRootPart.CFrame = v.CFrame; break end
                                    end
                                    if not test then
                                        pcall(function() char.HumanoidRootPart.CFrame = plr.PlayerGui.FireGuide.Adornee.CFrame end)
                                    else
                                        -- set collisions off and loop interaction
                                        pcall(function()
                                            for _,vv in pairs(test.Parent:GetDescendants()) do
                                                if (vv.ClassName == "Part" or vv.ClassName == "MeshPart") and vv.CanCollide == true then
                                                    vv.CanCollide = false
                                                end
                                            end
                                            workspace.Gravity = 0
                                            repeat
                                                task.wait()
                                                ReplicatedStorage.Remotes.TaskController.ActionGameDataReplication:FireServer("TryInteractWithItem", {["GameName"]="FirefighterGame", ["Action"]="UpdatePlayerToolState", ["Data"]={["IsActive"]=true,["ToolName"]="Extinguisher"}})
                                                char.HumanoidRootPart.CFrame = test.CFrame * CFrame.new(0,10,0)
                                                char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(-90),0,0)
                                            until not Players.LocalPlayer.PlayerGui:FindFirstChild("FireGuide") or not _G.fireman
                                            char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                                            task.wait(1)
                                            ReplicatedStorage.Remotes.TaskController.ActionGameDataReplication:FireServer("TryInteractWithItem", {["GameName"]="FirefighterGame", ["Action"]="TryToCollectReward", ["Data"]={}})
                                        end)
                                    end
                                end
                            end
                        end)
                    end
                end)
            end)

            -- Add other toggles/button placeholders (Auto Sell Cars, Auto Delivery, etc)
            example:AddToggle("Auto Sell Cars", function(state)
                _G.Customer = (state and true or false)
                task.spawn(function()
                    while _G.Customer do
                        task.wait(1)
                        -- Implement safe minimal behavior: try to accept/compelete if UI present
                        pcall(function()
                            local plr = Players.LocalPlayer
                            if not plr then return end
                            if plr.PlayerGui:FindFirstChild("Menu") and plr.PlayerGui.Menu:FindFirstChild("Inventory") then
                                -- attempt simple call; original script has many game-specific steps — user should test in-game
                            end
                        end)
                    end
                end)
            end)

            -- Race window (simplified, preserve your provided race logic but keep robust checks)
            local rWindow = library:CreateWindow({ text = "Race" })
            rWindow:AddBox("Enter Auto Race Speed", function(object, focus)
                if focus then _G.speed = tonumber(object.Text) or _G.speed end
            end)

            rWindow:AddToggle("Auto Race", function(state)
                _G.racetest = (state and true or false)
                task.spawn(function()
                    while _G.racetest do
                        task.wait()
                        -- find nearest race main
                        local race = nil; local distance = math.huge
                        if workspace:FindFirstChild("Races") then
                            for _,v in pairs(workspace.Races:GetDescendants()) do
                                if v.Name == "Main" and v.ClassName == "UnionOperation" then
                                    local Dist = (Players.LocalPlayer.Character.HumanoidRootPart.Position - v.Position).magnitude
                                    if Dist < distance then distance = Dist; race = v end
                                end
                            end
                        end
                        if not race then task.wait(2); continue end
                        -- attempt to request stream and use captured remote events (if available)
                        if _G.remotetable1 then
                            -- try fire remote to join
                            pcall(function() _G.remote1:FireServer(unpack(_G.remotetable1)) end)
                        end
                        -- now wait for race UI etc; much of your original logic relies on in-game UI structure
                        task.wait(1)
                    end
                end)
            end)

            rWindow:AddToggle("Auto Drift Race", function(state)
                _G.racetest3 = (state and true or false)
                task.spawn(function()
                    while _G.racetest3 do
                        task.wait(1)
                        -- simplified: attempt pivot to race start when possible
                        task.wait(0.5)
                    end
                end)
            end)

            rWindow:AddToggle("AutoFarm[laps|checkpoints]", function(state)
                _G.racetest = (state and true or false)
            end)

            -- Misc window
            local misc = library:CreateWindow({ text = "Misc" })
            misc:AddButton("Make Obtainable[Cosmetic]", function()
                pcall(function()
                    for i,v in pairs(ReplicatedStorage.Customization:GetDescendants()) do
                        if not v:GetAttribute("MoneyPrice") then v:SetAttribute("MoneyPrice", 0.00000) end
                    end
                end)
            end)
            misc:AddButton("Force Load Map", function()
                task.spawn(function()
                    for i,v in pairs(workspace:GetDescendants()) do
                        if v.ClassName == "Model" and v:FindFirstChild("WorldPivot") then
                            pcall(function() Players.LocalPlayer:RequestStreamAroundAsync(v.WorldPivot.Position,1) end)
                            task.wait(0.05)
                        end
                    end
                end)
            end)
            misc:AddLabel("Race Teleports")
            misc:AddDropdown(races(), function(state)
                -- teleport to chosen race union operation
                task.spawn(function()
                    for i,v in pairs(workspace.Races:GetChildren()) do
                        if v.Name == state and v:FindFirstChildOfClass("UnionOperation") then
                            local chr = Players.LocalPlayer.Character
                            if not chr then return end
                            if not chr.Humanoid.SeatPart then
                                pcall(function() chr.HumanoidRootPart.CFrame = v:FindFirstChildOfClass("UnionOperation").CFrame end)
                            else
                                local car = chr.Humanoid.SeatPart.Parent.Parent
                                pcall(function() car:PivotTo(v:FindFirstChildOfClass("UnionOperation").CFrame) end)
                            end
                            break
                        end
                    end
                end)
            end)

            -- load delivery config if exists
            if pcall(function() return readfile end) and pcall(function() return isfile("cdtdelivery.txt") end) and isfile("cdtdelivery.txt") then
                local ok, content = pcall(function() return readfile("cdtdelivery.txt") end)
                if ok and type(content)=="string" then
                    local t = content:split(" ")
                    _G.stars = tonumber(t[1]) or _G.stars
                    _G.smaller = tonumber(t[2]) or _G.smaller
                    _G.bigger = tonumber(t[3]) or _G.bigger
                end
            end

            D.uiReady = true
            D.windows = { example = example, race = rWindow, misc = misc }
        end)
    end

    function D.stop()
        D.running = false
        -- no direct cleanup because UI lib manages windows; if library exposes destroy, call it
        if D.lib and D.lib.Destroy then pcall(function() D.lib:Destroy() end) end
        D.lib = nil
        D.windows = {}
    end

    STATE.Modules.Dealership = D
end

-- RAYFIELD LOAD (safe fallback)
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then STATE.Rayfield = Ray else
        warn("[G-MON] Rayfield load failed; using fallback UI.")
        local Fallback = {}
        function Fallback:CreateWindow()
            local win = {}
            function win:CreateTab() local tab = {} function tab:CreateLabel() end function tab:CreateParagraph() end function tab:CreateButton() end function tab:CreateToggle() end function tab:CreateSlider() end return tab end
            function win:CreateNotification() end
            return win
        end
        function Fallback:Notify() end
        STATE.Rayfield = Fallback
    end
end

-- STATUS GUI (draggable)
do
    local Status = {}
    function Status.Create()
        SAFE_CALL(function()
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
                holder.Size = UDim2.new(1, -16, 0, 20); holder.Position = UDim2.new(0,8,0,y); holder.BackgroundTransparency = 1
                local dot = Instance.new("Frame"); dot.Parent = holder
                dot.Size = UDim2.new(0, 12, 0, 12); dot.Position = UDim2.new(0, 0, 0, 4); dot.BackgroundColor3 = Color3.fromRGB(200,0,0)
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

            -- draggable
            local dragging, dragInput, startMousePos, startFramePos = false, nil, Vector2.new(0,0), Vector2.new(0,0)
            local function getMouse() return UIS:GetMouseLocation() end
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; dragInput = input; startMousePos = getMouse(); startFramePos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then dragging = false; dragInput = nil end
                    end)
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

-- create status GUI
SAFE_CALL(function() if STATE.Status and STATE.Status.Create then STATE.Status.Create() end end)

-- UI BUILDING: create tabs + integrate modules (including Dealership)
local function buildUI()
    SAFE_CALL(function()
        STATE.Window = (STATE.Rayfield and STATE.Rayfield.CreateWindow) and STATE.Rayfield:CreateWindow({
            Name = "G-MON Hub",
            LoadingTitle = "G-MON Hub",
            LoadingSubtitle = "Ready",
            ConfigurationSaving = { Enabled = false }
        }) or nil

        local Tabs = {}
        if STATE.Window then
            Tabs.Info = STATE.Window:CreateTab("Info")
            Tabs.TabBlox = STATE.Window:CreateTab("Blox Fruit")
            Tabs.TabCar = STATE.Window:CreateTab("Car Tycoon")
            Tabs.TabBoat = STATE.Window:CreateTab("Build A Boat")
            Tabs.Move = STATE.Window:CreateTab("Movement")
            Tabs.Debug = STATE.Window:CreateTab("Debug")
            Tabs.Scripts = STATE.Window:CreateTab("Scripts")
            Tabs.Dealership = STATE.Window:CreateTab("Dealership")
        else
            local function makeTab() return { CreateLabel = function() end, CreateParagraph = function() end, CreateButton = function() end, CreateToggle = function() end, CreateSlider = function() end } end
            Tabs.Info = makeTab(); Tabs.TabBlox = makeTab(); Tabs.TabCar = makeTab(); Tabs.TabBoat = makeTab(); Tabs.Move = makeTab(); Tabs.Debug = makeTab(); Tabs.Scripts = makeTab(); Tabs.Dealership = makeTab()
        end
        STATE.Tabs = Tabs

        -- Info tab
        SAFE_CALL(function()
            Tabs.Info:CreateLabel("G-MON Hub - client-only. Use only in private/testing places.")
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
                    STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Car: Available" or "Car: N/A")
                    STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
                    if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="UI ready — use tabs", Duration=3}) end
                end)
            end })
            Tabs.Info:CreateButton({ Name = "Force Blox", Callback = function() STATE.GAME = "BLOX_FRUIT"; STATE.Status.SetIndicator("bf", true, "Blox: Forced"); if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Forced: Blox", Duration=2}) end end })
            Tabs.Info:CreateButton({ Name = "Force Car", Callback = function() STATE.GAME = "CAR_TYCOON"; STATE.Status.SetIndicator("car", true, "Car: Forced"); if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Forced: Car", Duration=2}) end end })
            Tabs.Info:CreateButton({ Name = "Force Boat", Callback = function() STATE.GAME = "BUILD_A_BOAT"; STATE.Status.SetIndicator("boat", true, "Boat: Forced"); if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Forced: Boat", Duration=2}) end end })
            Tabs.Info:CreateParagraph({ Title = "Note", Content = "Each game has its own tab. Use Force/Detect to update status. Features are separated to avoid duplicates." })
        end)

        -- Blox tab
        SAFE_CALL(function()
            local t = Tabs.TabBlox
            t:CreateLabel("Blox Fruit Controls")
            t:CreateToggle({ Name = "Auto Farm (Blox)", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Blox.start) else SAFE_CALL(STATE.Modules.Blox.stop) end end })
            t:CreateToggle({ Name = "Fast Attack", CurrentValue = STATE.Modules.Blox.config.fast_attack, Callback = function(v) STATE.Modules.Blox.config.fast_attack = v end })
            t:CreateToggle({ Name = "Long Range Hit", CurrentValue = STATE.Modules.Blox.config.long_range, Callback = function(v) STATE.Modules.Blox.config.long_range = v end })
            t:CreateSlider({ Name = "Range Farming (studs)", Range = {1,50}, Increment = 1, CurrentValue = STATE.Modules.Blox.config.range or 10, Callback = function(v) STATE.Modules.Blox.config.range = v end })
            t:CreateSlider({ Name = "Attack Delay (ms)", Range = {50,1000}, Increment = 25, CurrentValue = math.floor((STATE.Modules.Blox.config.attack_delay or 0.35)*1000), Callback = function(v) STATE.Modules.Blox.config.attack_delay = v/1000 end })
        end)

        -- Car tab
        SAFE_CALL(function()
            local t = Tabs.TabCar
            t:CreateLabel("Car Tycoon Controls")
            t:CreateToggle({ Name = "Car AutoDrive", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Car.start) else SAFE_CALL(STATE.Modules.Car.stop) end end })
            t:CreateSlider({ Name = "Car Speed", Range = {20,200}, Increment = 5, CurrentValue = STATE.Modules.Car.speed or 60, Callback = function(v) STATE.Modules.Car.speed = v end })
        end)

        -- Boat tab
        SAFE_CALL(function()
            local t = Tabs.TabBoat
            t:CreateLabel("Build A Boat Controls")
            t:CreateToggle({ Name = "Boat Auto Stages", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Boat.start) else SAFE_CALL(STATE.Modules.Boat.stop) end end })
            t:CreateSlider({ Name = "Stage Delay (s)", Range = {0.5,6}, Increment = 0.5, CurrentValue = STATE.Modules.Boat.delay or 1.5, Callback = function(v) STATE.Modules.Boat.delay = v end })
        end)

        -- Movement tab (fly)
        SAFE_CALL(function()
            local t = Tabs.Move
            local flyEnabled = false; local flySpeed = 60; local flyY = 0
            t:CreateLabel("Movement")
            t:CreateToggle({ Name = "Fly", Callback = function(v) flyEnabled = v end })
            t:CreateSlider({ Name = "Fly Speed", Range = {20,150}, Increment = 5, CurrentValue = flySpeed, Callback = function(v) flySpeed = v end })
            t:CreateSlider({ Name = "Fly Y", Range = {-60,60}, Increment = 1, CurrentValue = flyY, Callback = function(v) flyY = v end })
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

        -- Debug tab
        SAFE_CALL(function()
            local t = Tabs.Debug
            t:CreateLabel("Debug / Utility")
            t:CreateButton({ Name = "Force Start All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.start); SAFE_CALL(STATE.Modules.Car.start); SAFE_CALL(STATE.Modules.Boat.start) end })
            t:CreateButton({ Name = "Stop All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.stop); SAFE_CALL(STATE.Modules.Car.stop); SAFE_CALL(STATE.Modules.Boat.stop) end })
        end)

        -- Scripts tab (Haruka)
        SAFE_CALL(function()
            local t = Tabs.Scripts
            t:CreateLabel("Script Picker / Haruka Features")
            t:CreateParagraph({ Title = "Haruka (integrated)", Content = "Lightweight Auto Farm and Gold Tracker (from Haruka Hub). Toggle below to run." })
            t:CreateToggle({ Name = "Haruka Auto Farm", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Haruka.startAutoFarm) else SAFE_CALL(STATE.Modules.Haruka.stopAutoFarm) end end })
            t:CreateToggle({ Name = "Haruka Gold Tracker", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Haruka.startGoldTracker) else SAFE_CALL(STATE.Modules.Haruka.stopGoldTracker) end end })
            t:CreateButton({ Name = "Stop Haruka All", Callback = function() SAFE_CALL(STATE.Modules.Haruka.stopAutoFarm); SAFE_CALL(STATE.Modules.Haruka.stopGoldTracker) end })
            t:CreateParagraph({ Title = "Note", Content = "Haruka features can be used across games where applicable. Do not run conflicting auto-modules simultaneously." })
        end)

        -- Dealership tab (runs the dealership UI when clicked)
        SAFE_CALL(function()
            local t = Tabs.Dealership
            t:CreateLabel("Dealership / Vehicle Features")
            t:CreateButton({ Name = "Open Dealership UI", Callback = function() SAFE_CALL(function() if STATE.Modules.Dealership then STATE.Modules.Dealership.start() end end) end })
            t:CreateButton({ Name = "Stop Dealership UI", Callback = function() SAFE_CALL(function() if STATE.Modules.Dealership then STATE.Modules.Dealership.stop() end end) end })
            t:CreateParagraph({ Title = "Note", Content = "Dealership UI uses external library and exposes many vehicle/race features. Use with caution." })
        end)
    end)
end

-- Apply Game (set status indicators and notify)
local function ApplyGame(gameKey)
    STATE.GAME = gameKey or Utils.FlexibleDetectByAliases()
    SAFE_CALL(function()
        STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
        STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Car: Available" or "Car: N/A")
        STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(STATE.GAME), Duration=3}) end
    end)
end

-- STATUS UPDATER
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

-- INITIALIZATION
local Main = {}

function Main.Start()
    SAFE_CALL(function()
        buildUI()
        local det = Utils.FlexibleDetectByAliases()
        STATE.GAME = det
        ApplyGame(STATE.GAME)
        Utils.AntiAFK()
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use tabs to control modules (Dealership tab contains Vehicle UI)", Duration=5}) end
        print("[G-MON] main.lua started. Detected game:", STATE.GAME)
    end)
    return true
end

return Main