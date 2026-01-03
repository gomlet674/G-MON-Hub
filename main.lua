--[[
===========================================================================
  GMON HUB - main.lua (FINAL, single-file)
  - Combines: Blox Fruit, Car Dealership Tycoon, Build A Boat
  - Features: AntiAFK, God Mode, Rejoin / ServerHop, Gold Tracker,
              AutoFarm modules, AutoDrive Car, Auto Build (hook), Teleports,
              Profile save/load per-game, Rayfield UI with fallback,
              Draggable Status GUI, safe wrappers and runtime manager.
  - NOTES:
    * Designed for private/testing use only.
    * Executor APIs (writefile/readfile/isfile/isfolder/makefolder, loadstring, HttpGet)
      are used when available. If not available, features still try their best.
    * Avoids aggressive anti-cheat bypasses; uses safe methods.
===========================================================================
--]]

-- BOOTSTRAP
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

-- SAFE HELPERS
local function SAFE_CALL(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[GMON] SAFE_CALL error:", res)
    end
    return ok, res
end

local function SAFE_WAIT(t)
    t = tonumber(t) or 0.1
    if t < 0.01 then t = 0.01 end
    if t > 5 then t = 5 end
    task.wait(t)
end

-- CORE STATE
local GMON = {
    StartTime = os.time(),
    Modules = {},
    Flags = {},
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    Status = nil,
    LastAction = "Idle"
}

-- ====================
-- UTILITIES & DETECTION
-- ====================
local Utils = {}

function Utils.SafeChar()
    local ok, c = pcall(function() return LP and LP.Character end)
    if not ok or not c then return nil end
    if c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then return c end
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

function Utils.FlexibleDetectGame()
    local pid = game.PlaceId
    if pid == 2753915549 or pid == 4442272183 or pid == 7449423635 then return "BLOX_FRUIT" end
    if pid == 1554960397 or pid == 654732683 then return "CAR_TYCOON" end
    if pid == 537413528 or pid == 142823291 then return "BUILD_A_BOAT" end

    -- Heuristic detection
    local map = {
        BLOX_FRUIT = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","Quests"},
        CAR_TYCOON = {"Cars","VehicleFolder","Dealership","Garage","CarShop"},
        BUILD_A_BOAT = {"BoatStages","Stages","NormalStages","StageFolder","BoatStage","Chest","Treasure"}
    }
    for k, names in pairs(map) do
        for _,n in ipairs(names) do
            if Workspace:FindFirstChild(n) then return k end
        end
    end
    for _,obj in ipairs(Workspace:GetChildren()) do
        local n = string.lower(obj.Name or "")
        if string.find(n,"enemy") or string.find(n,"mob") or string.find(n,"monster") then return "BLOX_FRUIT" end
        if string.find(n,"car") or string.find(n,"vehicle") or string.find(n,"garage") then return "CAR_TYCOON" end
        if string.find(n,"boat") or string.find(n,"stage") or string.find(n,"treasure") or string.find(n,"chest") then return "BUILD_A_BOAT" end
    end
    return "UNKNOWN"
end

function Utils.ShortLabel(g)
    if g=="BLOX_FRUIT" then return "Blox" end
    if g=="CAR_TYCOON" then return "Car" end
    if g=="BUILD_A_BOAT" then return "Boat" end
    return tostring(g or "Unknown")
end

GMON.Utils = Utils

-- ====================
-- RAYFIELD LOAD (safe)
-- ====================
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        GMON.Rayfield = Ray
    else
        GMON.Rayfield = nil
    end
end

-- ====================
-- FALLBACK UI (if Rayfield missing)
-- ====================
local function makeFallbackWindow(title)
    local W = {}
    local sg = Instance.new("ScreenGui")
    sg.Name = "GMON_FallbackUI"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = LP:WaitForChild("PlayerGui") end)

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 480, 0, 580)
    frame.Position = UDim2.new(0, 10, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1,-8,0,30)
    titleLbl.Position = UDim2.new(0,4,0,4)
    titleLbl.Text = title
    titleLbl.Font = Enum.Font.SourceSansBold
    titleLbl.TextSize = 18
    titleLbl.TextColor3 = Color3.fromRGB(230,230,230)
    titleLbl.BackgroundTransparency = 1

    local content = Instance.new("Frame", frame)
    content.Size = UDim2.new(1, -8, 1, -44)
    content.Position = UDim2.new(0,4,0,40)
    content.BackgroundTransparency = 1

    function W:CreateTab(name)
        local Tab = {}
        local y = #content:GetChildren() * 34 + 4
        local header = Instance.new("TextLabel", content)
        header.Position = UDim2.new(0, 4, 0, y)
        header.Size = UDim2.new(1, -8, 0, 28)
        header.Text = "[ " .. tostring(name) .. " ]"
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.SourceSansSemibold
        header.TextSize = 14
        header.TextColor3 = Color3.fromRGB(200,200,200)
        y = y + 34

        function Tab:CreateLabel(txt)
            local lbl = Instance.new("TextLabel", content)
            lbl.Position = UDim2.new(0,8,0,y)
            lbl.Size = UDim2.new(1,-16,0,20)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSans
            lbl.TextSize = 13
            lbl.TextColor3 = Color3.fromRGB(200,200,200)
            lbl.Text = txt
            y = y + 24
            return lbl
        end

        function Tab:CreateParagraph(tbl)
            return Tab:CreateLabel((tbl.Title and (tbl.Title..": ") or "") .. (tbl.Content or ""))
        end

        function Tab:CreateButton(tbl)
            local b = Instance.new("TextButton", content)
            b.Position = UDim2.new(0,8,0,y)
            b.Size = UDim2.new(1,-16,0,28)
            b.Text = tbl.Name or "Button"
            b.Font = Enum.Font.SourceSansBold
            b.TextSize = 14
            b.BackgroundColor3 = Color3.fromRGB(42,42,42)
            b.TextColor3 = Color3.fromRGB(230,230,230)
            b.MouseButton1Click:Connect(function() SAFE_CALL(tbl.Callback) end)
            y = y + 34
            return b
        end

        function Tab:CreateToggle(tbl)
            local frame = Instance.new("Frame", content)
            frame.Position = UDim2.new(0,8,0,y)
            frame.Size = UDim2.new(1,-16,0,28)
            frame.BackgroundTransparency = 1
            local lbl = Instance.new("TextLabel", frame)
            lbl.Size = UDim2.new(0.75,0,1,0)
            lbl.Position = UDim2.new(0,0,0,0)
            lbl.Text = tbl.Name or "Toggle"
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSans
            lbl.TextSize = 13
            lbl.TextColor3 = Color3.fromRGB(220,220,220)
            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(0.24,0,1,0)
            btn.Position = UDim2.new(0.76,0,0,0)
            btn.Text = tbl.CurrentValue and "ON" or "OFF"
            btn.Font = Enum.Font.SourceSansBold
            btn.TextSize = 13
            btn.BackgroundColor3 = tbl.CurrentValue and Color3.fromRGB(30,160,50) or Color3.fromRGB(100,100,100)
            btn.TextColor3 = Color3.fromRGB(230,230,230)
            btn.MouseButton1Click:Connect(function()
                local nv = not (tbl.CurrentValue)
                tbl.CurrentValue = nv
                btn.Text = nv and "ON" or "OFF"
                btn.BackgroundColor3 = nv and Color3.fromRGB(30,160,50) or Color3.fromRGB(100,100,100)
                SAFE_CALL(tbl.Callback, nv)
            end)
            y = y + 34
            return frame
        end

        function Tab:CreateSlider(tbl)
            -- simple "setter" button for fallback
            local label = Instance.new("TextLabel", content)
            label.Position = UDim2.new(0,8,0,y)
            label.Size = UDim2.new(1,-16,0,22)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.SourceSans
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220,220,220)
            label.Text = tbl.Name .. " : " .. tostring(tbl.CurrentValue)
            local btn = Instance.new("TextButton", content)
            btn.Position = UDim2.new(0,8,0,y+24)
            btn.Size = UDim2.new(1,-16,0,26)
            btn.Text = "Apply ("..tostring(tbl.CurrentValue)..")"
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 13
            btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
            btn.TextColor3 = Color3.fromRGB(230,230,230)
            btn.MouseButton1Click:Connect(function() SAFE_CALL(tbl.Callback, tbl.CurrentValue) end)
            y = y + 60
            return {label=label, button=btn}
        end

        return Tab
    end

    function W:Notify(params)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = params.Title or "GMON",
                Text = params.Content or "",
                Duration = params.Duration or 4
            })
        end)
    end

    return W
end

-- MAKE WINDOW (Rayfield preferred)
if GMON.Rayfield and type(GMON.Rayfield.CreateWindow) == "function" then
    GMON.Window = GMON.Rayfield:CreateWindow({
        Name = "G-MON Hub",
        LoadingTitle = "G-MON Hub",
        LoadingSubtitle = "Ready",
        ConfigurationSaving = { Enabled = true, FolderName = "GMON_Settings" }
    })
else
    GMON.Window = makeFallbackWindow("G-MON Hub")
end

-- ====================
-- STATUS GUI (draggable)
-- ====================
do
    local sg = Instance.new("ScreenGui")
    sg.Name = "GMonStatusGui"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = LP:WaitForChild("PlayerGui") end)

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 340, 0, 140)
    frame.Position = UDim2.new(1, -350, 0, 16)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0,0)
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -16, 0, 26)
    title.Position = UDim2.new(0, 8, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "G-MON Status"
    title.TextColor3 = Color3.fromRGB(240,240,240)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left

    local runtime = Instance.new("TextLabel", frame)
    runtime.Size = UDim2.new(1, -16, 0, 18)
    runtime.Position = UDim2.new(0, 8, 0, 36)
    runtime.BackgroundTransparency = 1
    runtime.Font = Enum.Font.SourceSans
    runtime.TextSize = 13
    runtime.TextColor3 = Color3.fromRGB(200,200,200)
    runtime.Text = "Runtime: 00:00"

    local info_blox = Instance.new("TextLabel", frame)
    info_blox.Size = UDim2.new(1, -16, 0, 16)
    info_blox.Position = UDim2.new(0,8,0,58)
    info_blox.BackgroundTransparency = 1
    info_blox.Font = Enum.Font.SourceSans
    info_blox.TextSize = 13
    info_blox.TextColor3 = Color3.fromRGB(200,200,200)
    info_blox.Text = "Blox: OFF"

    local info_car = info_blox:Clone(); info_car.Parent = frame
    info_car.Position = UDim2.new(0,8,0,76); info_car.Text = "Car: OFF"

    local info_boat = info_blox:Clone(); info_boat.Parent = frame
    info_boat.Position = UDim2.new(0,8,0,94); info_boat.Text = "Boat: OFF"

    local last = info_blox:Clone(); last.Parent = frame
    last.Position = UDim2.new(0,8,0,112); last.Text = "Last: Idle"

    GMON.Status = {
        Gui = sg,
        Frame = frame,
        Runtime = runtime,
        Blox = info_blox,
        Car = info_car,
        Boat = info_boat,
        Last = last
    }

    -- Draggable
    do
        local dragging, dragInput, startPos, startMouse = false, nil, nil, nil
        local function getMouse() return UIS:GetMouseLocation() end
        frame.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragInput = inp; startMouse = getMouse(); startPos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then dragging = false; dragInput = nil end
                end)
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                local delta = getMouse() - startMouse
                local newPos = startPos + delta
                frame.Position = UDim2.new(0, math.clamp(newPos.X, 0, (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X - frame.AbsoluteSize.X) or 800), 0, math.clamp(newPos.Y, 0, (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y - frame.AbsoluteSize.Y) or 600))
            end
        end)
    end

    -- Update loop
    task.spawn(function()
        while task.wait(1) do
            local elapsed = os.time() - GMON.StartTime
            pcall(function()
                GMON.Status.Runtime.Text = "Runtime: " .. Utils.FormatTime(elapsed)
                GMON.Status.Blox.Text = "Blox: " .. (GMON.Flags.Blox and "ON" or "OFF")
                GMON.Status.Car.Text = "Car: " .. (GMON.Flags.Car and "ON" or "OFF")
                GMON.Status.Boat.Text = "Boat: " .. (GMON.Flags.Boat and "ON" or "OFF")
                GMON.Status.Last.Text = "Last: "..(GMON.LastAction or "Idle")
            end)
        end
    end)
end

-- ====================
-- MODULE: BLOX FRUIT (full)
-- ====================
do
    local M = {}
    M.config = { attack_delay = 0.35, range = 12, long_range = false, fast_attack = false, auto_stats = false, stat_to = "Melee" }
    M.running = false
    M._task = nil

    local function findEnemies()
        local hints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs"}
        for _,h in ipairs(hints) do
            local f = Workspace:FindFirstChild(h)
            if f then return f end
        end
        -- fallback: scan for models with humanoid
        local out = {}
        for _,d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and d:FindFirstChild("HumanoidRootPart") then
                table.insert(out, d)
            end
        end
        return (#out>0) and Workspace or nil
    end

    local function nearestEnemy(hrp)
        local folder = findEnemies()
        if not folder then return nil end
        local best, bestDist = nil, math.huge
        for _,mob in ipairs(folder:GetDescendants()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") then
                local hum = mob:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < bestDist and d <= (M.config.range or 12) then bestDist, best = d, mob end
                end
            end
        end
        return best
    end

    local function attackLoop()
        while M.running do
            task.wait(0.12)
            SAFE_CALL(function()
                if not M.running then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local target = nearestEnemy(hrp)
                if not target then return end
                if M.config.long_range then
                    local dmg = M.config.fast_attack and 35 or 20
                    local hits = M.config.fast_attack and 3 or 1
                    for i=1,hits do pcall(function() if target and target:FindFirstChildOfClass("Humanoid") then target:FindFirstChildOfClass("Humanoid"):TakeDamage(dmg) end end) end
                    GMON.LastAction = "Blox LongHit -> "..tostring(target.Name or "mob")
                else
                    pcall(function() hrp.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
                    if M.config.fast_attack then
                        for i=1,3 do pcall(function() if target and target:FindFirstChildOfClass("Humanoid") then target:FindFirstChildOfClass("Humanoid"):TakeDamage(30) end end) end
                        GMON.LastAction = "Blox FastMelee -> "..tostring(target.Name or "mob")
                    else
                        pcall(function() if target and target:FindFirstChildOfClass("Humanoid") then target:FindFirstChildOfClass("Humanoid"):TakeDamage(18) end end)
                        GMON.LastAction = "Blox Melee -> "..tostring(target.Name or "mob")
                    end
                end
                -- optional auto stats (game specific remote names vary)
                if M.config.auto_stats then
                    pcall(function()
                        local rem = game:GetService("ReplicatedStorage"):FindFirstChild("CommF_") or game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
                        if rem and rem.InvokeServer then
                            rem:InvokeServer("AddPoint", M.config.stat_to)
                        end
                    end)
                end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true; GMON.Flags.Blox = true
        M._task = task.spawn(attackLoop)
    end

    function M.stop()
        M.running = false; GMON.Flags.Blox = false
        M._task = nil
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Range (studs)", min=2, max=60, current=M.config.range, onChange=function(v) M.config.range = v end },
            { type="slider", name="Attack Delay (ms)", min=50, max=1000, current=math.floor(M.config.attack_delay*1000), onChange=function(v) M.config.attack_delay = v/1000 end },
            { type="toggle", name="Fast Attack", current=M.config.fast_attack, onChange=function(v) M.config.fast_attack = v end },
            { type="toggle", name="Long Range Hit", current=M.config.long_range, onChange=function(v) M.config.long_range = v end },
            { type="toggle", name="Auto Upgrade Stats", current=M.config.auto_stats, onChange=function(v) M.config.auto_stats = v end }
        }
    end

    GMON.Modules.Blox = M
end

-- ====================
-- MODULE: CAR DEALERSHIP TYCOON
-- ====================
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
            if o and o.Value then return tostring(o.Value) end
            if m.GetAttribute then return m:GetAttribute("Owner") end
            return nil
        end)
        if ok and ownerVal and tostring(ownerVal) == tostring(LP.Name) then return true end
        local ok2, idVal = pcall(function()
            local v = m:FindFirstChild("OwnerUserId") or m:FindFirstChild("UserId")
            if v and v.Value then return tonumber(v.Value) end
            if m.GetAttribute then return m:GetAttribute("OwnerUserId") end
            return nil
        end)
        if ok2 and tonumber(idVal) and tonumber(idVal) == LP.UserId then return true end
        return false
    end

    local function choosePlayerCar()
        local root = Workspace:FindFirstChild("Cars") or Workspace
        local candidates = {}
        for _,m in ipairs(root:GetDescendants()) do
            if m:IsA("Model") and m.PrimaryPart then
                if isOwnedByPlayer(m) then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then
            for _,m in ipairs(root:GetDescendants()) do
                if m:IsA("Model") and m.PrimaryPart and #m:GetDescendants() > 5 then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then return nil end
        table.sort(candidates, function(a,b) return #a:GetDescendants() > #b:GetDescendants() end)
        return candidates[1]
    end

    local function ensureLV(part)
        if not part then return nil end
        local att = part:FindFirstChild("_GmonAttach") or Instance.new("Attachment", part); att.Name = "_GmonAttach"
        local lv = part:FindFirstChild("_GmonLV")
        if not lv then
            lv = Instance.new("LinearVelocity")
            lv.Name = "_GmonLV"
            lv.Attachment0 = att
            lv.MaxForce = math.huge
            lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
            lv.Parent = part
        end
        return lv
    end

    local function driveLoop()
        while M.running do
            task.wait(0.12)
            SAFE_CALL(function()
                if not M.running then return end
                if not M.chosen or not M.chosen.PrimaryPart then
                    local car = choosePlayerCar()
                    if not car or not car.PrimaryPart then GMON.Flags.Car = false; return end
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
                    local lv = ensureLV(prim)
                    if lv then lv.VectorVelocity = prim.CFrame.LookVector * (M.speed or 60) end
                end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true; GMON.Flags.Car = true
        M._task = task.spawn(driveLoop)
    end

    function M.stop()
        M.running = false; GMON.Flags.Car = false
        if M.chosen then
            SAFE_CALL(function()
                if M.chosen.PrimaryPart then
                    local prim = M.chosen.PrimaryPart
                    local lv = prim:FindFirstChild("_GmonLV"); if lv then pcall(function() lv:Destroy() end) end
                    local att = prim:FindFirstChild("_GmonAttach"); if att then pcall(function() att:Destroy() end) end
                end
                local tag = M.chosen:FindFirstChild("_GmonStartPos")
                if tag and tag:IsA("CFrameValue") and M.chosen.PrimaryPart then pcall(function() M.chosen:SetPrimaryPartCFrame(tag.Value) end); pcall(function() tag:Destroy() end) end
            end)
        end
        M.chosen = nil
    end

    function M.TryBuy(modelName)
        -- NOTE: Game-specific remote; user must adapt to their private game's remote names.
        local rem = Workspace:FindFirstChild("BuyCar") or game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("BuyCar")
        if rem and rem:IsA("RemoteEvent") then
            SAFE_CALL(function() rem:FireServer(modelName) end)
            return true
        end
        warn("[GMON] Car buy remote not found. Adapt script to your game.")
        return false
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Car Speed", min=20, max=200, current=M.speed, onChange=function(v) M.speed = v end }
        }
    end

    GMON.Modules.Car = M
end

-- ====================
-- MODULE: BUILD A BOAT (Treasure)
-- ====================
do
    local M = {}
    M.running = false
    M.delay = 1.5
    M._task = nil
    M.teleports = { spawn = CFrame.new(0,5,0), shop = CFrame.new(10,5,0), build_area = CFrame.new(0,5,50) }
    M.PlacePartFunction = nil -- user hook: function(partName, cframe) return true/false end

    local function collectStages(root)
        local out = {}
        if not root then return out end
        for _,obj in ipairs(root:GetDescendants()) do
            if obj:IsA("BasePart") then
                local lname = string.lower(obj.Name or "")
                local ok, col = pcall(function() return obj.Color end)
                local isDark = false
                if ok and col then if (col.R + col.G + col.B) / 3 < 0.2 then isDark = true end end
                if isDark or string.find(lname,"stage") or string.find(lname,"black") or string.find(lname,"trigger") or string.find(lname,"dark") then
                    table.insert(out, obj)
                end
            end
        end
        return out
    end

    local function autoLoop()
        while M.running do
            task.wait(0.2)
            SAFE_CALL(function()
                if not M.running then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

                local roots = {}
                for _,n in ipairs({"BoatStages","Stages","NormalStages","StageFolder","BoatStage"}) do
                    local r = Workspace:FindFirstChild(n)
                    if r then table.insert(roots, r) end
                end
                if #roots == 0 then table.insert(roots, Workspace) end

                local stages = {}
                for _,r in ipairs(roots) do
                    local s = collectStages(r)
                    for _,p in ipairs(s) do table.insert(stages, p) end
                end
                if #stages == 0 then
                    for _,obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and string.find(string.lower(obj.Name or ""), "stage") then table.insert(stages, obj) end
                    end
                end
                if #stages == 0 then GMON.Flags.Boat = false; M.running = false; return end

                local seen, uniq = {}, {}
                for _,p in ipairs(stages) do
                    if p and p.Position then
                        local key = string.format("%.2f_%.2f_%.2f", p.Position.X, p.Position.Y, p.Position.Z)
                        if not seen[key] then seen[key] = true; table.insert(uniq, p) end
                    end
                end
                stages = uniq
                table.sort(stages, function(a,b) return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude end)

                for _,part in ipairs(stages) do
                    if not M.running then break end
                    if part and part.Parent then pcall(function() hrp.CFrame = part.CFrame * CFrame.new(0,3,0) end) end
                    SAFE_WAIT(M.delay or 1.2)
                end

                -- find chest
                local candidate = nil
                for _,v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then local ln = string.lower(v.Name or ""); if string.find(ln,"chest") or string.find(ln,"treasure") or string.find(ln,"golden") then candidate = v; break end
                    elseif v:IsA("Model") and v.PrimaryPart then local ln = string.lower(v.Name or ""); if string.find(ln,"chest") or string.find(ln,"treasure") or string.find(ln,"golden") then candidate = v.PrimaryPart; break end
                    end
                end
                if candidate then pcall(function() hrp.CFrame = candidate.CFrame * CFrame.new(0,3,0) end) end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true; GMON.Flags.Boat = true
        M._task = task.spawn(autoLoop)
    end

    function M.stop()
        M.running = false; GMON.Flags.Boat = false
        M._task = nil
    end

    function M.TeleportTo(name)
        local preset = M.teleports[name]
        if not preset then warn("Preset not found:", name); return end
        local char = Utils.SafeChar(); if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.CFrame = preset end) end
    end

    function M.AutoBuildOnce(list)
        if not list or #list==0 then return false, "No parts" end
        if type(M.PlacePartFunction) ~= "function" then return false, "Set PlacePartFunction hook first" end
        local char = Utils.SafeChar(); if not char then return false, "No character" end
        local base = (char.PrimaryPart and char.PrimaryPart.CFrame) or CFrame.new(0,5,0)
        for i,name in ipairs(list) do
            local pos = base * CFrame.new(0,0,2*i)
            local ok, res = pcall(function() return M.PlacePartFunction(name, pos) end)
            if not ok or res == false then warn("[GMON AutoBuild] failed placing", name, tostring(res)) end
            SAFE_WAIT(0.15)
        end
        return true
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Stage Delay (s)", min=0.2, max=6, current=M.delay, onChange=function(v) M.delay = v end }
        }
    end

    GMON.Modules.Boat = M
end

-- ====================
-- GOLD TRACKER (general)
-- ====================
local GoldTracker = {}
GoldTracker.running = false
GoldTracker.guiobj = nil

local function createGoldGui()
    local player = LP
    if not player then return nil end
    local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    local scr = Instance.new("ScreenGui"); scr.Name = "GMonGoldGui"; scr.ResetOnSpawn = false; scr.Parent = pg
    local frame = Instance.new("Frame", scr)
    frame.Size = UDim2.new(0, 280, 0, 160)
    frame.Position = UDim2.new(0,10,0,10)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0); frame.BackgroundTransparency = 0.12; frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(50,50,50); stroke.Thickness = 2

    local labels = {}
    local rows = {"Start:","Current:","Gained:","Time:"}
    for i,t in ipairs(rows) do
        local r = Instance.new("Frame", frame); r.Size = UDim2.new(1,-20,0,30); r.Position = UDim2.new(0,10,0,15 + (i-1)*35); r.BackgroundTransparency = 1
        local left = Instance.new("TextLabel", r); left.Size = UDim2.new(0.6,0,1,0); left.BackgroundTransparency = 1; left.Font = Enum.Font.Gotham; left.TextSize = 14; left.TextColor3 = Color3.fromRGB(180,180,180); left.Text = t
        local right = Instance.new("TextLabel", r); right.Size = UDim2.new(0.4,0,1,0); right.Position = UDim2.new(0.6,0,0,0); right.BackgroundTransparency = 1; right.Font = Enum.Font.GothamBold; right.TextSize = 14; right.TextColor3 = Color3.fromRGB(255,255,255); right.Text = "0"
        labels[i] = right
    end
    return {Gui = scr, Frame = frame, Labels = labels, StartTime = os.time()}
end

local function findNumeric(root)
    if not root then return nil end
    if root:IsA("TextLabel") then
        local txt = tostring(root.Text or ""):gsub("%s","")
        if txt ~= "" then
            local num = txt:match("(%d+)")
            if num then return root end
        end
    end
    for _,c in ipairs(root:GetChildren()) do
        local f = findNumeric(c)
        if f then return f end
    end
    return nil
end

local function goldLoop(gui)
    if not gui then return end
    local playerGui = LP:WaitForChild("PlayerGui")
    local goldLabel = nil
    local startAmount = 0
    local gained = 0
    gui.Labels[1].Text = "0"; gui.Labels[2].Text = "0"; gui.Labels[3].Text = "0"; gui.Labels[4].Text = "00:00"
    while GoldTracker.running do
        if not goldLabel or not goldLabel.Parent then
            -- game-specific attempt
            if playerGui:FindFirstChild("GoldGui") and playerGui.GoldGui:FindFirstChild("Frame") then
                goldLabel = findNumeric(playerGui.GoldGui.Frame)
            else
                goldLabel = findNumeric(playerGui)
            end
            if goldLabel then startAmount = tonumber((goldLabel.Text or ""):gsub("[^%d]","")) or 0 end
            gui.Labels[1].Text = tostring(startAmount)
        end
        if goldLabel and goldLabel.Parent then
            local cur = tonumber((goldLabel.Text or ""):gsub("[^%d]","")) or 0
            gui.Labels[2].Text = tostring(cur)
            if cur > startAmount then
                gained = gained + (cur - startAmount)
                gui.Labels[3].Text = tostring(gained)
                startAmount = cur
            elseif cur < startAmount then
                startAmount = cur
            end
        end
        local elapsed = os.time() - gui.StartTime
        gui.Labels[4].Text = string.format("%02d:%02d", math.floor(elapsed/60), elapsed%60)
        task.wait(1)
    end
end

function GoldTracker.start()
    if GoldTracker.running then return end
    GoldTracker.running = true
    GoldTracker.guiobj = createGoldGui()
    if GoldTracker.guiobj then task.spawn(function() goldLoop(GoldTracker.guiobj) end) end
    GMON.Flags.Gold = true
end

function GoldTracker.stop()
    GoldTracker.running = false
    GMON.Flags.Gold = false
    if GoldTracker.guiobj and GoldTracker.guiobj.Gui and GoldTracker.guiobj.Gui.Parent then
        pcall(function() GoldTracker.guiobj.Gui:Destroy() end)
    end
    GoldTracker.guiobj = nil
end

GMON.Modules.GoldTracker = GoldTracker

-- ====================
-- SYSTEM: God Mode, Rejoin, ServerHop
-- ====================
do
    local S = {}
    S.God = false
    S._loop = nil

    function S.EnableGod(v)
        S.God = not not v
        if S._loop then S._loop = nil end
        if S.God then
            S._loop = task.spawn(function()
                while S.God do
                    local c = Utils.SafeChar()
                    if c then
                        local hum = c:FindFirstChildOfClass("Humanoid")
                        if hum then
                            pcall(function()
                                hum.MaxHealth = 1e8
                                hum.Health = hum.MaxHealth
                            end)
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end

    function S.Rejoin()
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end

    function S.ServerHop()
        SAFE_CALL(function()
            if not HttpService.HttpEnabled then S.Rejoin(); return end
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            local resp = game:HttpGet(url)
            local data = HttpService:JSONDecode(resp)
            if data and data.data then
                for _,srv in ipairs(data.data) do
                    if srv.playing and srv.playing < (srv.maxPlayers or 0) and srv.id then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                        return
                    end
                end
            end
            S.Rejoin()
        end)
    end

    GMON.System = S
end

-- ====================
-- PROFILE SAVE / LOAD (per-game)
-- ====================
do
    local folder = "GMON_Profiles"
    local filename = folder .. "/" .. tostring(Utils.FlexibleDetectGame() or "UNKNOWN") .. ".json"

    pcall(function() if not isfolder then return end end)

    local function ensureFolder()
        local ok, _ = pcall(function()
            if isfolder and not isfolder(folder) then makefolder(folder) end
        end)
        return ok
    end

    function GMON.SaveProfile()
        local ok = pcall(function()
            ensureFolder()
            local data = {
                Blox = GMON.Modules.Blox and GMON.Modules.Blox.config or nil,
                Car = GMON.Modules.Car and { speed = GMON.Modules.Car.speed } or nil,
                Boat = GMON.Modules.Boat and { delay = GMON.Modules.Boat.delay } or nil
            }
            if writefile then
                writefile(filename, HttpService:JSONEncode(data))
            end
        end)
        if not ok then warn("[GMON] SaveProfile failed") end
    end

    function GMON.LoadProfile()
        local ok = pcall(function()
            if isfile and isfile(filename) then
                local raw = readfile(filename)
                local data = HttpService:JSONDecode(raw)
                if data and data.Blox and GMON.Modules.Blox then
                    for k,v in pairs(data.Blox) do GMON.Modules.Blox.config[k] = v end
                end
                if data and data.Car and GMON.Modules.Car then
                    GMON.Modules.Car.speed = data.Car.speed or GMON.Modules.Car.speed
                end
                if data and data.Boat and GMON.Modules.Boat then
                    GMON.Modules.Boat.delay = data.Boat.delay or GMON.Modules.Boat.delay
                end
            end
        end)
        if not ok then warn("[GMON] LoadProfile failed") end
    end

    -- auto-load at startup
    pcall(function() GMON.LoadProfile() end)
end

-- ====================
-- UI BUILD (Rayfield or fallback) - full tabs & callbacks
-- ====================
do
    local win = GMON.Window
    local Tabs = {}
    local function createTabSafe(name)
        if win and win.CreateTab then return win:CreateTab(name) end
        -- fallback: Window itself has CreateTab for fallback
        return win:CreateTab(name)
    end

    Tabs.Settings = createTabSafe("Settings")
    Tabs.Info = createTabSafe("Info")
    Tabs.Main = createTabSafe("Main")
    Tabs.TabBlox = createTabSafe("Blox Fruit")
    Tabs.TabCar = createTabSafe("Car Tycoon")
    Tabs.TabBoat = createTabSafe("Build A Boat")
    GMON.Tabs = Tabs

    -- SETTINGS
    SAFE_CALL(function()
        local t = Tabs.Settings
        if t.CreateLabel then t:CreateLabel("Settings & Profiles") end
        if t.CreateButton then
            t:CreateButton({ Name = "Save Profile (now)", Callback = function() SAFE_CALL(GMON.SaveProfile); (win.Notify and win:Notify or makeFallbackWindow("G-MON").Notify)({Title="GMON", Content="Profile saved", Duration=2}) end })
        end
        if t.CreateButton then
            t:CreateButton({ Name = "Load Profile (now)", Callback = function() SAFE_CALL(GMON.LoadProfile); (win.Notify and win:Notify or makeFallbackWindow("G-MON").Notify)({Title="GMON", Content="Profile loaded", Duration=2}) end })
        end
        if t.CreateToggle then
            t:CreateToggle({ Name = "Auto Save Every 10s", CurrentValue = true, Callback = function(v) GMON.Flags.AutoSave = v end })
        end
    end)

    -- INFO
    SAFE_CALL(function()
        local t = Tabs.Info
        if t.CreateLabel then t:CreateLabel("Information") end
        if t.CreateParagraph then t:CreateParagraph({ Title = "Detected", Content = Utils.ShortLabel(Utils.FlexibleDetectGame()) }) end
        if t.CreateToggle then
            t:CreateToggle({ Name = "Gold Tracker (cross-game)", CurrentValue = false, Callback = function(v) if v then GoldTracker.start() else GoldTracker.stop() end end })
        end
    end)

    -- MAIN
    SAFE_CALL(function()
        local t = Tabs.Main
        if t.CreateLabel then t:CreateLabel("Main Controls") end
        if t.CreateButton then t:CreateButton({ Name = "Force Detect", Callback = function()
            local d = Utils.FlexibleDetectGame(); GMON.Flags.Detected = d
            (win.Notify and win:Notify or makeFallbackWindow("G-MON").Notify)({Title="GMON", Content="Detected: "..tostring(d), Duration=3})
        end }) end
        if t.CreateButton then t:CreateButton({ Name = "Stop All Modules", Callback = function() SAFE_CALL(GMON.Modules.Blox.stop); SAFE_CALL(GMON.Modules.Car.stop); SAFE_CALL(GMON.Modules.Boat.stop); SAFE_CALL(GoldTracker.stop) end }) end
        if t.CreateButton then t:CreateButton({ Name = "Start All Modules (if applicable)", Callback = function()
            SAFE_CALL(function()
                local g = Utils.FlexibleDetectGame()
                if g == "BLOX_FRUIT" then GMON.Modules.Blox.start() end
                if g == "CAR_TYCOON" then GMON.Modules.Car.start() end
                if g == "BUILD_A_BOAT" then GMON.Modules.Boat.start() end
            end)
        end }) end
    end)

    -- BLOX TAB
    SAFE_CALL(function()
        local t = Tabs.TabBlox
        if t.CreateLabel then t:CreateLabel("Blox Fruit Controls") end
        if t.CreateToggle then t:CreateToggle({ Name = "Blox Auto (module)", CurrentValue = false, Callback = function(v) if v then GMON.Modules.Blox.start() else GMON.Modules.Blox.stop() end end }) end
        if t.CreateToggle then t:CreateToggle({ Name = "Fast Attack", CurrentValue = GMON.Modules.Blox.config.fast_attack, Callback = function(v) GMON.Modules.Blox.config.fast_attack = v end }) end
        if t.CreateToggle then t:CreateToggle({ Name = "Long Range Hit", CurrentValue = GMON.Modules.Blox.config.long_range, Callback = function(v) GMON.Modules.Blox.config.long_range = v end }) end
        if t.CreateSlider then t:CreateSlider({ Name = "Range Farming (studs)", Range = {1,50}, Increment = 1, CurrentValue = GMON.Modules.Blox.config.range or 12, Callback = function(v) GMON.Modules.Blox.config.range = v end }) end
        if t.CreateSlider then t:CreateSlider({ Name = "Attack Delay (ms)", Range = {50,1000}, Increment = 25, CurrentValue = math.floor((GMON.Modules.Blox.config.attack_delay or 0.35)*1000), Callback = function(v) GMON.Modules.Blox.config.attack_delay = v/1000 end }) end
    end)

    -- CAR TAB
    SAFE_CALL(function()
        local t = Tabs.TabCar
        if t.CreateLabel then t:CreateLabel("Car Dealership Controls") end
        if t.CreateToggle then t:CreateToggle({ Name = "Car AutoDrive", CurrentValue = false, Callback = function(v) if v then GMON.Modules.Car.start() else GMON.Modules.Car.stop() end end }) end
        if t.CreateSlider then t:CreateSlider({ Name = "Car Speed", Range = {20,200}, Increment = 5, CurrentValue = GMON.Modules.Car.speed or 60, Callback = function(v) GMON.Modules.Car.speed = v end }) end
        if t.CreateButton then t:CreateButton({ Name = "Choose Player Car", Callback = function()
            local chosen = GMON.Modules.Car.choosePlayerFastestCar and GMON.Modules.Car.choosePlayerFastestCar() or GMON.Modules.Car.chosen
            if chosen then (win.Notify and win:Notify or makeFallbackWindow("G-MON").Notify)({Title="GMON", Content="Chosen car: "..tostring(chosen.Name), Duration=3}) else (win.Notify and win:Notify or makeFallbackWindow("G-MON").Notify)({Title="GMON", Content="No car found", Duration=3}) end
        end }) end
    end)

    -- BOAT TAB
    SAFE_CALL(function()
        local t = Tabs.TabBoat
        if t.CreateLabel then t:CreateLabel("Build A Boat Controls") end
        if t.CreateToggle then t:CreateToggle({ Name = "Boat Auto Stages", CurrentValue = false, Callback = function(v) if v then GMON.Modules.Boat.start() else GMON.Modules.Boat.stop() end end }) end
        if t.CreateSlider then t:CreateSlider({ Name = "Stage Delay (s)", Range = {0.5,6}, Increment = 0.5, CurrentValue = GMON.Modules.Boat.delay or 1.5, Callback = function(v) GMON.Modules.Boat.delay = v end }) end
        if t.CreateButton then t:CreateButton({ Name = "Teleport: Build Area", Callback = function() GMON.Modules.Boat.TeleportTo("build_area") end }) end
        if t.CreateButton then t:CreateButton({ Name = "Teleport: Spawn", Callback = function() GMON.Modules.Boat.TeleportTo("spawn") end }) end
        if t.CreateButton then t:CreateButton({ Name = "Auto Build - Demo", Callback = function()
            local ok,msg = GMON.Modules.Boat.AutoBuildOnce({"Block","Wheel","Cannon"})
            (win.Notify and win:Notify or makeFallbackWindow("G-MON").Notify)({Title="GMON", Content=tostring(ok).." "..tostring(msg), Duration=3})
        end }) end
    end)
end

-- ====================
-- STARTUP & RUNTIME MANAGEMENT
-- ====================
-- Auto-save toggle
GMON.Flags.AutoSave = true
task.spawn(function()
    while task.wait(10) do
        if GMON.Flags.AutoSave then SAFE_CALL(GMON.SaveProfile) end
    end
end)

-- set anti-afk by default
Utils.AntiAFK()

-- initial game detect + UI notify
task.spawn(function()
    local det = Utils.FlexibleDetectGame()
    if GMON.Window and GMON.Window.Notify then GMON.Window:Notify({Title="GMON Hub", Content="Loaded. Detected: "..tostring(det), Duration=4}) end
    print("[GMON] Loaded. Detected:", det)
end)

-- Export Main interface
local Main = {}
function Main.StartAll()
    SAFE_CALL(function()
        GMON.Modules.Blox.start()
        GMON.Modules.Car.start()
        GMON.Modules.Boat.start()
    end)
end
function Main.StopAll()
    SAFE_CALL(function()
        GMON.Modules.Blox.stop()
        GMON.Modules.Car.stop()
        GMON.Modules.Boat.stop()
    end)
end

Main.GMON = GMON
Main.Utils = Utils
Main.Window = GMON.Window

return Main
```0