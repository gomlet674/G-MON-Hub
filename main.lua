-- GMON Hub - main.lua (Rayfield-first, full-feature)
-- Single-file. Requires Rayfield available at https://sirius.menu/rayfield
-- Purpose: Combined hub for Blox Fruit, Car Tycoon, Build A Boat (treasure)
-- Features: Rayfield UI, Save/Load config (Rayfield), Draggable status overlay, Gold tracker, AntiAFK, GodMode, Rejoin/ServerHop
-- Use privately for testing.

-- BOOTSTRAP / SERVICES
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

-- SAFE helpers
local function SAFE_CALL(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[GMON] SAFE_CALL error:", res)
    end
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
    StartTime = os.time(),
    Modules = {},
    Flags = {},
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    Status = nil,
    LastAction = "Idle",
    ConfigFileName = "GmonConfig"
}

-- UTILITIES
local Utils = {}
function Utils.FormatTime(sec)
    sec = math.max(0, math.floor(sec or 0))
    local h = math.floor(sec/3600); local m = math.floor((sec%3600)/60); local s = sec%60
    if h>0 then return string.format("%02dh:%02dm:%02ds", h,m,s) end
    return string.format("%02dm:%02ds", m,s)
end
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

-- GAME DETECTION helper (keeps it flexible)
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
        if string.find(n, "boat") or string.find(n, "stage") or string.find(n, "chest") or string.find(n, "treasure") then return "BUILD_A_BOAT" end
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

-- RAYFIELD LOAD (must succeed for this script)
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        STATE.Rayfield = Ray
    else
        error("[GMON] Fatal: Rayfield UI failed to load. Ensure your executor allows HttpGet and the URL is reachable.")
    end
end

-- Create Rayfield Window (with config saving)
STATE.Window = STATE.Rayfield:CreateWindow({
    Name = "G-MON Hub",
    LoadingTitle = "G-MON Hub",
    LoadingSubtitle = "Rayfield UI",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GmonConfigs",
        FileName = STATE.ConfigFileName
    }
})

-- STATUS OVERLAY (draggable) - works alongside Rayfield
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
            frame.Size = UDim2.new(0, 340, 0, 160)
            frame.Position = UDim2.new(1, -350, 0, 10)
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
            sub.Text = Utils.ShortLabelForGame(STATE.GAME or Utils.FlexibleDetectByAliases())
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

-- create status GUI now
SAFE_CALL(function() if STATE.Status and STATE.Status.Create then STATE.Status.Create() end end)

-- ============================
-- MODULE: System (AntiAFK, GodMode, Rejoin, ServerHop)
-- ============================
do
    local M = {}
    M.GodModeEnabled = false
    M._godLoop = nil

    function M.EnableAntiAFK()
        Utils.AntiAFK()
    end

    function M.SetGodMode(enabled)
        M.GodModeEnabled = enabled
        if enabled then
            if M._godLoop and task.cancel then task.cancel(M._godLoop) end
            M._godLoop = task.spawn(function()
                while M.GodModeEnabled do
                    local character = Utils.SafeChar()
                    if character then
                        local hum = character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            pcall(function()
                                hum.MaxHealth = 1e8
                                hum.Health = hum.MaxHealth
                                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                                hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                            end)
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            M._godLoop = nil
        end
    end

    function M.Rejoin()
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end

    function M.ServerHop()
        local success, err = pcall(function()
            if not HttpService.HttpEnabled then error("Http not enabled") end
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            local resp = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(resp)
            if data and data.data then
                for _,srv in ipairs(data.data) do
                    if srv.playing and (srv.playing < (srv.maxPlayers or 0)) and srv.id then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                        return
                    end
                end
            end
            M.Rejoin()
        end)
        if not success then
            warn("[GMON] ServerHop failed:", err)
            pcall(function() M.Rejoin() end)
        end
    end

    STATE.Modules.System = M
end

-- ============================
-- MODULE: Blox Fruit (Auto-farm)
-- ============================
do
    local M = {}
    M.config = { attack_delay = 0.35, range = 12, long_range = false, fast_attack = false }
    M.running = false
    M._task = nil

    local function findEnemyFolder()
        local hints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","NPCs"}
        for _, name in ipairs(hints) do
            local f = Workspace:FindFirstChild(name)
            if f then return f end
        end
        return Workspace
    end

    local function nearestEnemy(hrp)
        local folder = findEnemyFolder()
        if not folder then return nil end
        local best, bestDist = nil, math.huge
        for _, mob in ipairs(folder:GetDescendants()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") then
                local hum = mob:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local ok, pos = pcall(function() return mob.HumanoidRootPart.Position end)
                    if ok and pos then
                        local d = (pos - hrp.Position).Magnitude
                        if d < bestDist and d <= (M.config.range or 12) then bestDist, best = d, mob end
                    end
                end
            end
        end
        return best
    end

    local function loop()
        while M.running do
            task.wait(0.12)
            SAFE_CALL(function()
                if not M.running then return end
                if STATE.GAME ~= "BLOX_FRUIT" then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local target = nearestEnemy(hrp)
                if not target then return end
                pcall(function() hrp.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
                if M.config.fast_attack then
                    for i=1,3 do
                        pcall(function() if target and target:FindFirstChildOfClass("Humanoid") then target:FindFirstChildOfClass("Humanoid"):TakeDamage(25) end end)
                        task.wait(0.06)
                    end
                else
                    pcall(function() if target and target:FindFirstChildOfClass("Humanoid") then target:FindFirstChildOfClass("Humanoid"):TakeDamage(12) end end)
                end
                STATE.LastAction = "Blox Hit -> "..tostring(target.Name or "mob")
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

-- ============================
-- MODULE: Car Dealership Tycoon (Autodrive)
-- ============================
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
        M._task = task.spawn(loop)
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

-- ============================
-- MODULE: Build A Boat (Auto stages, Teleport presets, Auto-build hook)
-- ============================
do
    local M = {}
    M.running = false
    M.delay = 1.2
    M._task = nil
    M.teleports = {
        spawn = CFrame.new(0,5,0),
        shop = CFrame.new(10,5,0),
        build_area = CFrame.new(0,5,50)
    }
    M.PlacePartFunction = nil -- hook for auto-build

    local function collectStageParts()
        local out = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = string.lower(obj.Name or "")
                if string.find(n,"stage") or string.find(n,"black") or string.find(n,"trigger") then
                    table.insert(out, obj)
                end
            end
        end
        return out
    end

    local function autoStageLoop()
        while M.running do
            task.wait(0.2)
            SAFE_CALL(function()
                if not M.running then return end
                if STATE.GAME ~= "BUILD_A_BOAT" then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local parts = collectStageParts()
                if #parts == 0 then return end
                table.sort(parts, function(a,b) return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude end)
                for _, p in ipairs(parts) do
                    if not M.running then break end
                    if p and p.Parent then pcall(function() hrp.CFrame = p.CFrame * CFrame.new(0,3,0) end) end
                    SAFE_WAIT(M.delay or 1.2)
                end
                -- chest search
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then local ln = string.lower(v.Name or ""); if string.find(ln, "chest") or string.find(ln, "treasure") or string.find(ln, "gold") then pcall(function() hrp.CFrame = v.CFrame * CFrame.new(0,3,0) end); break end end
                end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true
        STATE.Flags.Boat = true
        M._task = task.spawn(autoStageLoop)
    end

    function M.stop()
        M.running = false
        STATE.Flags.Boat = false
        M._task = nil
    end

    function M.TeleportToPreset(name)
        local preset = M.teleports[name]
        if not preset then warn("Preset not found:", name); return end
        local char = Utils.SafeChar()
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.CFrame = preset end) end
    end

    function M.AutoBuildOnce(partNameList)
        local char = Utils.SafeChar()
        if not char then return false, "No character" end
        if not M.PlacePartFunction or type(M.PlacePartFunction) ~= "function" then
            return false, "No PlacePartFunction hook defined"
        end
        local basePos = (char.PrimaryPart and char.PrimaryPart.CFrame) or CFrame.new(0,5,0)
        for i, pname in ipairs(partNameList or {}) do
            local pos = basePos * CFrame.new(0, 0, 2 * i)
            local ok, err = pcall(function()
                local res = M.PlacePartFunction(pname, pos)
                if res == false then error("Place failed for "..tostring(pname)) end
            end)
            if not ok then warn("[GMON AutoBuild] failed placing", pname, err) end
            SAFE_WAIT(0.15)
        end
        return true
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Stage Delay (s)", min=0.2, max=6, current=M.delay, onChange=function(v) M.delay = v end }
        }
    end

    STATE.Modules.Boat = M
end

-- ============================
-- Gold Tracker (cross-game)
-- ============================
do
    local GT = {}
    GT.running = false; GT.gui = nil
    local function create_gold_gui()
        local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui")
        local sg = Instance.new("ScreenGui"); sg.Name = "GMON_GoldTracker"; sg.ResetOnSpawn = false; sg.Parent = pg
        local frame = Instance.new("Frame", sg); frame.Size = UDim2.new(0, 280, 0, 160); frame.Position = UDim2.new(0, 10, 0, 10); frame.BackgroundColor3 = Color3.fromRGB(14,14,14); local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
        local labels = {}
        local rows = {"Start:", "Current:", "Gained:", "Time:"}
        for i=1,4 do
            local row = Instance.new("TextLabel", frame)
            row.Size = UDim2.new(1, -20, 0, 30)
            row.Position = UDim2.new(0, 10, 0, 10 + (i-1)*36)
            row.BackgroundTransparency = 1
            row.Font = Enum.Font.Gotham
            row.TextSize = 14
            row.TextColor3 = Color3.fromRGB(230,230,230)
            row.Text = rows[i] .. " 0"
            labels[i] = row
        end
        return { Gui = sg, Frame = frame, Labels = labels, StartTime = os.time() }
    end
    local function find_numeric_label(root)
        if not root then return nil end
        if root:IsA("TextLabel") then
            local txt = tostring(root.Text):gsub("%s","")
            if txt ~= "" and tonumber(txt) then return root end
        end
        for _, c in ipairs(root:GetChildren()) do
            local f = find_numeric_label(c)
            if f then return f end
        end
        return nil
    end
    local function loop(guiobj)
        if not guiobj then return end
        local playerGui = LP:WaitForChild("PlayerGui")
        local goldLabel = nil; local startAmount = 0; local gained = 0
        while GT.running do
            if not goldLabel or not goldLabel.Parent then
                if playerGui:FindFirstChild("GoldGui") and playerGui.GoldGui:FindFirstChild("Frame") then goldLabel = find_numeric_label(playerGui.GoldGui.Frame) else goldLabel = find_numeric_label(playerGui) end
                if goldLabel then startAmount = tonumber((goldLabel.Text:gsub("[^%d]",""))) or 0 end
            end
            if goldLabel then
                local cur = tonumber((goldLabel.Text:gsub("[^%d]",""))) or 0
                if cur > startAmount then
                    gained = gained + (cur - startAmount)
                    startAmount = cur
                elseif cur < startAmount then
                    startAmount = cur
                end
                guiobj.Labels[1].Text = "Start: "..tostring(startAmount)
                guiobj.Labels[2].Text = "Current: "..tostring(cur)
                guiobj.Labels[3].Text = "Gained: "..tostring(gained)
            end
            guiobj.Labels[4].Text = "Time: "..string.format("%02d:%02d", math.floor((os.time()-guiobj.StartTime)/60), (os.time()-guiobj.StartTime)%60)
            SAFE_WAIT(1)
        end
    end
    function GT.start() if GT.running then return end; GT.running = true; GT.gui = create_gold_gui(); task.spawn(function() loop(GT.gui) end); STATE.Flags.Gold = true end
    function GT.stop() GT.running = false; STATE.Flags.Gold = false; if GT.gui and GT.gui.Gui and GT.gui.Gui.Parent then pcall(function() GT.gui.Gui:Destroy() end) end; GT.gui = nil end
    STATE.Modules.GoldTracker = GT
end

-- ============================
-- Build Rayfield UI Tabs and Controls (full)
-- ============================
do
    local Window = STATE.Window
    local Tabs = {}
    Tabs.Settings = Window:CreateTab("Settings")
    Tabs.Info = Window:CreateTab("Info")
    Tabs.Main = Window:CreateTab("Main")
    Tabs.Blox = Window:CreateTab("Blox Fruit")
    Tabs.Car = Window:CreateTab("Car Tycoon")
    Tabs.Boat = Window:CreateTab("Build A Boat")
    Tabs.System = Window:CreateTab("System")
    STATE.Tabs = Tabs

    -- Settings Tab
    do
        local s = Tabs.Settings
        s:CreateLabel("Configuration & Profiles")
        s:CreateParagraph({ Title = "Save / Load", Content = "Use Rayfield's configuration saving to store per-game profiles. FileName set to '"..STATE.ConfigFileName.."'" })
        s:CreateButton({ Name = "Save Config Now", Callback = function() SAFE_CALL(function() if STATE.Rayfield and STATE.Rayfield.SaveConfig then STATE.Rayfield:SaveConfiguration() end end) end })
        s:CreateButton({ Name = "Load Config Now", Callback = function() SAFE_CALL(function() if STATE.Rayfield and STATE.Rayfield.LoadConfiguration then STATE.Rayfield:LoadConfiguration() end end) end })
        s:CreateToggle({ Name = "Auto Enable AntiAFK", CurrentValue = true, Callback = function(v) if v then Utils.AntiAFK() end end })
    end

    -- Info Tab
    do
        local t = Tabs.Info
        t:CreateLabel("Information")
        t:CreateParagraph({ Title = "Detected Game", Content = Utils.ShortLabelForGame(STATE.GAME or Utils.FlexibleDetectByAliases()) })
        t:CreateParagraph({ Title = "Notes", Content = "This hub is for private/testing. Do not run in public servers. Use Rayfield configuration to save per-game profiles." })
        t:CreateToggle({ Name = "Gold Tracker (cross-game)", CurrentValue = false, Callback = function(v) if v then STATE.Modules.GoldTracker.start() else STATE.Modules.GoldTracker.stop() end end })
    end

    -- Main Tab
    do
        local t = Tabs.Main
        t:CreateLabel("Main Controls")
        t:CreateButton({ Name = "Detect Game Now", Callback = function()
            local det = Utils.FlexibleDetectByAliases(); STATE.GAME = det
            STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
            STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Car: Available" or "Car: N/A")
            STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
            STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(det), Duration=3})
        end })
        t:CreateButton({ Name = "Start All Modules (where applicable)", Callback = function()
            SAFE_CALL(function()
                if STATE.GAME == "BLOX_FRUIT" then STATE.Modules.Blox.start() end
                if STATE.GAME == "CAR_TYCOON" then STATE.Modules.Car.start() end
                if STATE.GAME == "BUILD_A_BOAT" then STATE.Modules.Boat.start() end
            end)
        end })
        t:CreateButton({ Name = "Stop All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.stop); SAFE_CALL(STATE.Modules.Car.stop); SAFE_CALL(STATE.Modules.Boat.stop); SAFE_CALL(STATE.Modules.GoldTracker.stop) end })
    end

    -- Blox Tab
    do
        local t = Tabs.Blox
        t:CreateLabel("Blox Fruit Module")
        t:CreateToggle({ Name = "Enable Auto Farm (Blox)", CurrentValue = false, Flag = "BloxAuto", Callback = function(v) if v then STATE.Modules.Blox.start() else STATE.Modules.Blox.stop() end end })
        t:CreateToggle({ Name = "Fast Attack", CurrentValue = STATE.Modules.Blox.config.fast_attack, Callback = function(v) STATE.Modules.Blox.config.fast_attack = v end })
        t:CreateToggle({ Name = "Long Range", CurrentValue = STATE.Modules.Blox.config.long_range, Callback = function(v) STATE.Modules.Blox.config.long_range = v end })
        t:CreateSlider({ Name = "Range (studs)", Min = 1, Max = 60, Current = STATE.Modules.Blox.config.range, Flag = "BloxRange", Callback = function(v) STATE.Modules.Blox.config.range = v end })
        t:CreateSlider({ Name = "Attack Delay (ms)", Min = 50, Max = 1000, Current = math.floor((STATE.Modules.Blox.config.attack_delay or 0.35)*1000), Callback = function(v) STATE.Modules.Blox.config.attack_delay = v/1000 end })
        t:CreateParagraph({ Title = "Warning", Content = "Auto farm logic is generic — adapt to specific private game if needed." })
    end

    -- Car Tab
    do
        local t = Tabs.Car
        t:CreateLabel("Car Tycoon Module")
        t:CreateToggle({ Name = "Enable AutoDrive", CurrentValue = false, Callback = function(v) if v then STATE.Modules.Car.start() else STATE.Modules.Car.stop() end end })
        t:CreateSlider({ Name = "Car Speed", Min = 20, Max = 200, Current = STATE.Modules.Car and STATE.Modules.Car.speed or 80, Callback = function(v) if STATE.Modules.Car then STATE.Modules.Car.speed = v end end })
        t:CreateButton({ Name = "Choose Player Car", Callback = function()
            local chosen = (STATE.Modules.Car and STATE.Modules.Car.choosePlayerFastestCar) and STATE.Modules.Car.choosePlayerFastestCar() or nil
            if chosen then STATE.Rayfield:Notify({Title="G-MON", Content="Chosen car: "..tostring(chosen.Name), Duration=3}) else STATE.Rayfield:Notify({Title="G-MON", Content="No car found", Duration=3}) end
        end })
    end

    -- Boat Tab
    do
        local t = Tabs.Boat
        t:CreateLabel("Build A Boat Module")
        t:CreateToggle({ Name = "Enable Auto Stages", CurrentValue = false, Callback = function(v) if v then STATE.Modules.Boat.start() else STATE.Modules.Boat.stop() end end })
        t:CreateSlider({ Name = "Stage Delay (s)", Min = 0.2, Max = 6, Current = STATE.Modules.Boat.delay or 1.2, Callback = function(v) STATE.Modules.Boat.delay = v end })
        t:CreateButton({ Name = "Teleport: Build Area", Callback = function() STATE.Modules.Boat.TeleportToPreset("build_area") end })
        t:CreateButton({ Name = "Teleport: Spawn", Callback = function() STATE.Modules.Boat.TeleportToPreset("spawn") end })
        t:CreateButton({ Name = "Auto Build - Demo", Callback = function()
            local ok, msg = STATE.Modules.Boat.AutoBuildOnce({"Block","Wheel","Cannon"})
            STATE.Rayfield:Notify({Title="G-MON", Content = tostring(ok) .. " " .. tostring(msg), Duration = 3})
        end })
    end

    -- System Tab
    do
        local t = Tabs.System
        t:CreateLabel("System Utilities")
        t:CreateToggle({ Name = "Anti AFK", CurrentValue = true, Callback = function(v) if v then STATE.Modules.System.EnableAntiAFK() end end })
        t:CreateToggle({ Name = "God Mode", CurrentValue = false, Callback = function(v) STATE.Modules.System.SetGodMode(v) end })
        t:CreateButton({ Name = "Rejoin", Callback = function() STATE.Modules.System.Rejoin() end })
        t:CreateButton({ Name = "ServerHop", Callback = function() STATE.Modules.System.ServerHop() end })
    end
end

-- Apply Game detection and status update
local function ApplyGame(gameKey)
    STATE.GAME = gameKey or Utils.FlexibleDetectByAliases()
    SAFE_CALL(function()
        STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
        STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Car: Available" or "Car: N/A")
        STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
        STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(STATE.GAME), Duration=3})
    end)
end

-- STATUS UPDATER (runtime & indicators)
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

-- MAIN START function
local Main = {}
function Main.Start()
    SAFE_CALL(function()
        local det = Utils.FlexibleDetectByAliases()
        STATE.GAME = det
        ApplyGame(STATE.GAME)
        Utils.AntiAFK()
        STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use Rayfield tabs to control modules (Save config via Rayfield)", Duration=5})
        print("[G-MON] main.lua started. Detected game:", STATE.GAME)
    end)
    return true
end

-- Expose Shortcuts & return
Main.STATE = STATE
Main.Utils = Utils
Main.Start = Main.Start
return Main