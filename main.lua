-- G-MON Hub - single-file (merged with Isnahamzah / Gemini Blox features)
-- Use in private/testing only.

-- BOOTSTRAP
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualInputManager = (pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager")) or nil
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
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
function Utils.FlexibleDetectByAliases()
    local pid = game.PlaceId
    if pid == 2753915549 then return "BLOX_FRUIT" end
    if pid == 1554960397 then return "CAR_TYCOON" end
    if pid == 537413528 then return "BUILD_A_BOAT" end
    local aliasMap = {
        BLOX_FRUIT = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","Quests","NPCQuests"},
        CAR_TYCOON = {"Cars","VehicleFolder","Vehicles","Dealership","Garage","CarShop"},
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
        if string.find(n, "car") or string.find(n, "vehicle") then return "CAR_TYCOON" end
        if string.find(n, "boat") or string.find(n, "stage") or string.find(n, "chest") then return "BUILD_A_BOAT" end
    end
    return "UNKNOWN"
end
STATE.Modules.Utils = Utils

-- RAYFIELD LOAD (optional)
do
    local ok, Ray = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
    if ok and Ray then STATE.Rayfield = Ray else STATE.Rayfield = nil end
end

-- STATUS GUI
do
    local Status = {}
    function Status.Create()
        SAFE_CALL(function()
            local pg = LP:WaitForChild("PlayerGui")
            local sg = Instance.new("ScreenGui"); sg.Name = "GMonStatusGui"; sg.ResetOnSpawn = false; sg.Parent = pg
            local frame = Instance.new("Frame", sg); frame.Name = "StatusFrame"; frame.Size = UDim2.new(0, 320, 0, 170); frame.Position = UDim2.new(1, -330, 0, 10)
            frame.BackgroundTransparency = 0.12; frame.BackgroundColor3 = Color3.fromRGB(18,18,18); frame.BorderSizePixel = 0
            local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
            local title = Instance.new("TextLabel", frame); title.Size = UDim2.new(1, -16,0,24); title.Position=UDim2.new(0,8,0,6); title.BackgroundTransparency=1; title.Text="G-MON Status"; title.TextColor3=Color3.fromRGB(255,255,255); title.TextXAlignment=Enum.TextXAlignment.Left; title.Font=Enum.Font.SourceSansBold; title.TextSize=16
            local sub = Instance.new("TextLabel", frame); sub.Parent=frame; sub.Size=UDim2.new(1,-16,0,18); sub.Position=UDim2.new(0,8,0,30); sub.BackgroundTransparency=1; sub.Text=Utils.FlexibleDetectByAliases(); sub.TextColor3=Color3.fromRGB(200,200,200); sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Font=Enum.Font.SourceSans; sub.TextSize=12
            local function makeLine(y)
                local holder = Instance.new("Frame", frame); holder.Size = UDim2.new(1, -16, 0, 20); holder.Position = UDim2.new(0,8,0,y); holder.BackgroundTransparency = 1
                local dot = Instance.new("Frame", holder); dot.Size = UDim2.new(0, 12, 0, 12); dot.Position = UDim2.new(0, 0, 0, 4); dot.BackgroundColor3 = Color3.fromRGB(200,0,0)
                local lbl = Instance.new("TextLabel", holder); lbl.Size = UDim2.new(1, -18, 1, 0); lbl.Position=UDim2.new(0, 18, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = ""; lbl.TextColor3 = Color3.fromRGB(230,230,230); lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
                return {dot = dot, lbl = lbl}
            end
            local lines = {}
            lines.runtime = makeLine(52); lines.bf = makeLine(74); lines.car = makeLine(96); lines.boat = makeLine(118); lines.last = makeLine(140)
            lines.runtime.lbl.Text = "Runtime: 00h:00m:00s"
            lines.bf.lbl.Text = "Blox: OFF"; lines.car.lbl.Text = "Car: OFF"; lines.boat.lbl.Text = "Boat: OFF"; lines.last.lbl.Text = "Last: Idle"
            STATE.Status = { frame = frame, lines = lines }
        end)
    end
    function Status.UpdateRuntime()
        SAFE_CALL(function() if STATE.Status and STATE.Status.lines and STATE.Status.lines.runtime then STATE.Status.lines.runtime.lbl.Text = "Runtime: "..Utils.FormatTime(os.time() - STATE.StartTime) end end)
    end
    function Status.SetIndicator(name, on, text)
        SAFE_CALL(function() if not STATE.Status or not STATE.Status.lines or not STATE.Status.lines[name] then return end local ln = STATE.Status.lines[name]; if on then ln.dot.BackgroundColor3 = Color3.fromRGB(0,200,0) else ln.dot.BackgroundColor3 = Color3.fromRGB(200,0,0) end if text then ln.lbl.Text = text end end)
    end
    STATE.Status = STATE.Status or {}
    STATE.Status.Create = Status.Create
    STATE.Status.UpdateRuntime = Status.UpdateRuntime
    STATE.Status.SetIndicator = Status.SetIndicator
end

SAFE_CALL(function() if STATE.Status and STATE.Status.Create then STATE.Status.Create() end end)

-- ============================
-- BLOX FRUIT MODULE (extended with Isna/Gemini features)
-- ============================
do
    local M = {}
    -- config includes fields from Isna script
    M.config = {
        AutoFarm = false,
        AutoStats = false,
        SelectStat = "Melee",
        SelectWeapon = "Melee",
        FarmDistance = 35,
        FastAttack = true,
        MobToFarm = "None",
        AutoHaki = true,
        ESPPlayers = false
    }
    M.running = false
    M._task = nil
    M._esp_tagged = {}

    -- helper: scan enemies list to build mob options
    local function scanMobs()
        local out = {}
        local ok, enemies = pcall(function() return Workspace:FindFirstChild("Enemies") end)
        if not ok or not enemies then return out end
        for _,v in ipairs(enemies:GetChildren()) do
            if v and v.Name and not table.find(out, v.Name) then table.insert(out, v.Name) end
        end
        table.sort(out)
        return out
    end

    -- Equip weapon: attempt to equip tool whose ToolTip matches SelectWeapon or whose Name contains the keyword
    local function EquipWeapon()
        local backpack = LP:FindFirstChild("Backpack")
        local char = Utils.SafeChar()
        if not backpack or not char then return end
        local want = M.config.SelectWeapon or "Melee"
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local tooltip = (tool.ToolTip or ""):lower()
                local tname = (tool.Name or ""):lower()
                if tooltip:find(want:lower()) or tname:find(want:lower()) then
                    pcall(function() char.Humanoid:EquipTool(tool) end)
                    return
                end
            end
        end
    end

    -- Attempt attack (fast attack) fallback uses VirtualInputManager else VirtualUser click simulation
    local function AttemptAttack()
        if not M.config.FastAttack then return end
        local ok = false
        if VirtualInputManager then
            ok = pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
        end
        if not ok then
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam and cam.CFrame then
                    VirtualUser:Button1Down(Vector2.new(0,0), cam.CFrame)
                    task.wait(0.02)
                    VirtualUser:Button1Up(Vector2.new(0,0), cam.CFrame)
                end
            end)
        end
    end

    -- Auto stats: call remote like original (uses CommF_ with AddPoint)
    local function UpStats()
        local ok, rem = pcall(function() return ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_") end)
        if not ok or not rem then return end
        local args = {"AddPoint", M.config.SelectStat, 1}
        pcall(function() rem:InvokeServer(unpack(args)) end)
    end

    -- Auto Haki: call remote "Buso" as in original
    local function AutoHaki()
        local ok, rem = pcall(function() return ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_") end)
        if not ok or not rem then return end
        if not Utils.SafeChar():FindFirstChild("HasBuso") then
            pcall(function() rem:InvokeServer("Buso") end)
        end
    end

    -- Tween safe teleport used by Isna
    local function TweenTo(targetCFrame)
        local char = Utils.SafeChar()
        if not char then return end
        local Root = char:FindFirstChild("HumanoidRootPart")
        if not Root then return end
        local Distance = (Root.Position - targetCFrame.Position).Magnitude
        local Speed = 300
        local Info = TweenService:Create(Root, TweenInfo.new(math.max(0.05, Distance / Speed), Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        Root.Velocity = Vector3.new(0,0,0)
        Info:Play()
        task.wait(math.min(0.25, Distance / Speed))
        if Distance <= 50 then
            Info:Cancel()
            pcall(function() Root.CFrame = targetCFrame end)
        end
    end

    -- find target mob by name in Workspace.Enemies
    local function findTargetMob()
        if not Workspace:FindFirstChild("Enemies") then return nil end
        for _, v in pairs(Workspace.Enemies:GetChildren()) do
            if v and v.Name == M.config.MobToFarm and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                return v
            end
        end
        return nil
    end

    -- ESP player: add BillboardGui to head
    local function addESPToPlayer(p)
        if not p or not p.Character or not p.Character:FindFirstChild("Head") then return end
        if p == LP then return end
        if p.Character.Head:FindFirstChild("GMonESP") then return end
        local bg = Instance.new("BillboardGui"); bg.Name = "GMonESP"; bg.Size = UDim2.new(0,200,0,50); bg.StudsOffset = Vector3.new(0,2.5,0); bg.AlwaysOnTop = true; bg.Parent = p.Character.Head
        local lbl = Instance.new("TextLabel", bg); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.SourceSansBold; lbl.Text = p.Name; lbl.TextColor3 = Color3.new(1,0,0); lbl.TextSize = 18; lbl.TextStrokeTransparency = 0
        M._esp_tagged[p] = bg
    end
    local function removeESPFromPlayer(p)
        if not p then return end
        local gui = M._esp_tagged[p]
        if gui and gui.Parent then pcall(function() gui:Destroy() end) end
        M._esp_tagged[p] = nil
    end

    -- main loop
    local function loop()
        while M.running do
            task.wait(0.12)
            SAFE_CALL(function()
                -- ESP upkeep
                if M.config.ESPPlayers then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LP then addESPToPlayer(p) end
                    end
                else
                    for p,_ in pairs(M._esp_tagged) do removeESPFromPlayer(p) end
                end

                -- AutoStats
                if M.config.AutoStats then
                    UpStats()
                end

                -- AutoFarm core
                if M.config.AutoFarm then
                    local target = findTargetMob()
                    if target and target:FindFirstChild("HumanoidRootPart") then
                        local root = Utils.SafeChar()
                        if not root then return end
                        local hrp = root:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local FarmPos = target.HumanoidRootPart.CFrame * CFrame.new(0, M.config.FarmDistance or 35, 0)
                        TweenTo(FarmPos)
                        -- Equip & Attack
                        EquipWeapon()
                        if (hrp.Position - target.HumanoidRootPart.Position).Magnitude < 60 then
                            AttemptAttack()
                            if M.config.AutoHaki then AutoHaki() end
                        end
                        STATE.LastAction = "Farming -> "..tostring(target.Name)
                    else
                        -- no target found: optionally idle / search
                        STATE.LastAction = "No target"
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
        -- cleanup ESP
        for p,_ in pairs(M._esp_tagged) do removeESPFromPlayer(p) end
    end

    function M.ExposeConfig()
        -- return controls metadata for UI builder (used by Rayfield if desired)
        return {
            { type="toggle", name="AutoFarm", current=M.config.AutoFarm, onChange=function(v) M.config.AutoFarm = v end },
            { type="dropdown", name="MobToFarm", options=scanMobs(), current=M.config.MobToFarm, onChange=function(v) M.config.MobToFarm = v end },
            { type="slider", name="FarmDistance", min=5, max=100, current=M.config.FarmDistance, onChange=function(v) M.config.FarmDistance = v end },
            { type="toggle", name="FastAttack", current=M.config.FastAttack, onChange=function(v) M.config.FastAttack = v end },
            { type="toggle", name="AutoHaki", current=M.config.AutoHaki, onChange=function(v) M.config.AutoHaki = v end },
            { type="toggle", name="AutoStats", current=M.config.AutoStats, onChange=function(v) M.config.AutoStats = v end },
            { type="dropdown", name="SelectStat", options={"Melee","Defense","Sword","Demon Fruit","Gun"}, current=M.config.SelectStat, onChange=function(v) M.config.SelectStat = v end },
            { type="dropdown", name="SelectWeapon", options={"Melee","Sword","Blox Fruit"}, current=M.config.SelectWeapon, onChange=function(v) M.config.SelectWeapon = v end },
            { type="toggle", name="ESP Players", current=M.config.ESPPlayers, onChange=function(v) M.config.ESPPlayers = v end }
        }
    end

    STATE.Modules.Blox = M
end

-- ============================
-- CAR & BOAT modules (unchanged simplified)
-- ============================
-- (Keep minimal implementations to preserve GMON UI)
do
    -- Car module (same as before)
    -- ============================
-- CAR DEALERSHIP TYCOON - integrated CDT features for GMON
-- Replace existing Car module with this block
-- ============================
do
    local M = {}
    M.running = false
    M.chosen = nil
    M.speed = 60
    M._task = nil

    -- CDT-specific features
    M.SelectedCar = ""
    M.CarPrice = 0
    M.AutoLimited = false
    M.AutoDrive = false

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- Utilities
    local function safe_find(child, name)
        local ok, res = pcall(function() return child and child:FindFirstChild(name) end)
        if ok then return res end
        return nil
    end

    local function GetCarList()
        local out = {}
        if ReplicatedStorage:FindFirstChild("Cars") then
            for _,v in ipairs(ReplicatedStorage.Cars:GetChildren()) do
                if v and v.Name then table.insert(out, v.Name) end
            end
            table.sort(out)
        end
        return out
    end

    function M.GetCarPrice(carName)
        if not ReplicatedStorage:FindFirstChild("Cars") then return "N/A" end
        local carData = ReplicatedStorage.Cars:FindFirstChild(carName)
        if carData then
            local ok, price = pcall(function() return carData:GetAttribute("Price") end)
            return (ok and price) or "N/A"
        end
        return "N/A"
    end

    function M.BuyCar(carName)
        if not carName or carName == "" then return false, "No car selected" end
        local ok, rem = pcall(function() return ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("BuyCar") end)
        if ok and rem and rem.FireServer then
            pcall(function() rem:FireServer(carName) end)
            return true
        end
        return false, "Buy remote not found: Remotes.BuyCar"
    end

    -- AutoLimited loop (scans cars and buys limited)
    function M._autoLimitedLoop()
        while M.AutoLimited do
            task.wait(1)
            pcall(function()
                local carsRoot = ReplicatedStorage:FindFirstChild("Cars")
                local ownedFolder = safe_find(LocalPlayer, "OwnedCars") or safe_find(LocalPlayer, "Owned")
                if carsRoot then
                    for _, car in pairs(carsRoot:GetChildren()) do
                        local isLimited = false
                        local okAttr, attr = pcall(function() return car:GetAttribute("IsLimited") end)
                        if okAttr and attr == true then isLimited = true end
                        if isLimited then
                            local owned = false
                            if ownedFolder then
                                if ownedFolder:FindFirstChild(car.Name) then owned = true end
                            end
                            if not owned then
                                -- notify (best-effort)
                                if STATE.Rayfield and STATE.Rayfield.Notify then
                                    pcall(function() STATE.Rayfield:Notify({Title="GMON - CDT", Content="Buying limited: "..car.Name, Duration=4}) end)
                                else
                                    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="GMON - CDT", Text="Buying: "..car.Name, Duration=3}) end)
                                end
                                pcall(function() M.BuyCar(car.Name) end)
                                task.wait(0.6)
                            end
                        end
                    end
                end
            end)
        end
    end

    -- AutoDrive loop: if player is seated in car, attempt to move car forward periodically
    function M._autoDriveLoop()
        while M.AutoDrive do
            task.wait(0.1)
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChildOfClass("Humanoid") then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    local seat = humanoid.SeatPart
                    if seat and seat.Parent then
                        local car = seat.Parent
                        local prim = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart")
                        if prim then
                            -- safe attempt: move slightly in lookVector direction
                            local targetPos = prim.Position + prim.CFrame.LookVector * 10
                            pcall(function() prim:PivotTo(CFrame.new(targetPos)) end)
                        end
                    end
                end
            end)
        end
    end

    -- Start/Stop wrappers for AutoLimited & AutoDrive
    function M.SetAutoLimited(enabled)
        M.AutoLimited = enabled
        if enabled then
            task.spawn(function() M._autoLimitedLoop() end)
        end
    end

    function M.SetAutoDrive(enabled)
        M.AutoDrive = enabled
        if enabled then
            task.spawn(function() M._autoDriveLoop() end)
        end
    end

    -- Expose minimal start/stop to keep compatibility with GMON's StartAll / StopAll
    function M.start()
        if M.running then return end
        M.running = true
        STATE.Flags.Car = true
    end

    function M.stop()
        M.running = false
        STATE.Flags.Car = false
        M.AutoDrive = false
        M.AutoLimited = false
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Car Speed", min=20, max=200, current=M.speed, onChange=function(v) M.speed = v end },
            { type="toggle", name="Auto Limited Buy (scan ReplicatedStorage)", current=false, onChange=function(v) M.SetAutoLimited(v) end },
            { type="toggle", name="Auto Drive (while seated)", current=false, onChange=function(v) M.SetAutoDrive(v) end }
        }
    end

    -- UI Integration: if GMON Window & TabCar exist, add CDT UI controls
    SAFE_CALL(function()
        local tab = (STATE.Tabs and STATE.Tabs.TabCar) or nil
        local winNotify = function(title, content, duration)
            if STATE.Rayfield and STATE.Rayfield.Notify then
                pcall(function() STATE.Rayfield:Notify({Title=title, Content=content, Duration=duration or 3}) end)
            else
                pcall(function() StarterGui:SetCore("SendNotification", {Title=title, Text=content, Duration=duration or 3}) end)
            end
        end

        if tab and tab.CreateLabel then
            tab:CreateLabel("Car Dealership Tycoon - CDT features")
            -- Auto Limited toggle
            if tab.CreateToggle then
                tab:CreateToggle({
                    Name = "Auto Buy NEW Limited",
                    CurrentValue = false,
                    Callback = function(v)
                        M.SetAutoLimited(v)
                        winNotify("GMON - CDT", "AutoLimited set to "..tostring(v))
                    end
                })
            end

            -- Dropdown: Car selector - fallback if dropdown unsupported
            local carList = GetCarList()
            if tab.CreateDropdown then
                tab:CreateDropdown({
                    Name = "Select Car (CWR)",
                    Default = carList[1] or "None",
                    Options = carList,
                    Callback = function(value)
                        M.SelectedCar = value
                        M.CarPrice = M.GetCarPrice(value)
                        winNotify("GMON - CDT", "Selected: "..tostring(value).." Price: "..tostring(M.CarPrice))
                    end
                })
            else
                -- Fallback: just a button to refresh list + console set
                tab:CreateButton({ Name = "Refresh Car List (console)", Callback = function()
                    local list = GetCarList()
                    winNotify("GMON - CDT", "Car list refreshed ("..tostring(#list).." items). See console (print).")
                    print("[GMON CDT] CarList:", unpack(list))
                end })
            end

            if tab.CreateButton then
                tab:CreateButton({
                    Name = "Check Price & Info",
                    Callback = function()
                        if M.SelectedCar ~= "" and M.SelectedCar ~= nil then
                            local price = M.GetCarPrice(M.SelectedCar)
                            winNotify("GMON - CDT", "Car: "..M.SelectedCar.." Price: "..tostring(price))
                        else
                            winNotify("GMON - CDT", "No car selected (use dropdown or set M.SelectedCar in console).")
                        end
                    end
                })
                tab:CreateButton({
                    Name = "BUY SELECTED CAR NOW",
                    Callback = function()
                        if M.SelectedCar and M.SelectedCar ~= "" then
                            local ok, err = M.BuyCar(M.SelectedCar)
                            if ok then winNotify("GMON - CDT", "Buy attempted: "..M.SelectedCar) else winNotify("GMON - CDT", "Buy failed: "..tostring(err)) end
                        else
                            winNotify("GMON - CDT", "No car selected!")
                        end
                    end
                })
            end

            -- Auto Drive toggle
            if tab.CreateToggle then
                tab:CreateToggle({
                    Name = "Auto Drive (while seated)",
                    CurrentValue = false,
                    Callback = function(v)
                        M.SetAutoDrive(v)
                        winNotify("GMON - CDT", "AutoDrive set to "..tostring(v))
                    end
                })
            end
        end
    end)

    STATE.Modules.Car = M
end

    -- Boat module (same as before)
    local Boat = {}
    Boat.running = false
    Boat.delay = 1.5
    Boat._task = nil
    function Boat.start() Boat.running = true; STATE.Flags.Boat = true end
    function Boat.stop() Boat.running = false; STATE.Flags.Boat = false end
    function Boat.ExposeConfig() return { {type="slider", name="Stage Delay (s)", min=0.5, max=6, current=Boat.delay, onChange=function(v) Boat.delay=v end} } end
    STATE.Modules.Boat = Boat
end

-- GOLD TRACKER (kept minimal)
local GoldTracker = {}
GoldTracker.running = false
GoldTracker.gui = nil
local function create_gold_gui()
    local player = LP
    if not player then return nil end
    local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    local GoldGui = Instance.new("ScreenGui"); GoldGui.Name = "GMonGoldTracker"; GoldGui.ResetOnSpawn = false; GoldGui.Parent = pg
    local Frame = Instance.new("Frame", GoldGui); Frame.Size = UDim2.new(0, 280, 0, 160); Frame.Position = UDim2.new(0, 10, 0, 10); Frame.BackgroundColor3 = Color3.fromRGB(0,0,0); Frame.BackgroundTransparency = 0.1; Frame.BorderSizePixel = 0
    local Corner = Instance.new("UICorner", Frame); Corner.CornerRadius = UDim.new(0,10)
    local labels = {}
    local rowTexts = { "Start:", "Current:", "Gained:", "Time:" }
    for i, txt in ipairs(rowTexts) do
        local rowFrame = Instance.new("Frame", Frame); rowFrame.Size = UDim2.new(1, -20, 0, 30); rowFrame.Position = UDim2.new(0, 10, 0, 15 + (i - 1) * 35); rowFrame.BackgroundTransparency = 1
        local left = Instance.new("TextLabel", rowFrame); left.Size = UDim2.new(0.6, 0, 1, 0); left.Text = txt; left.TextColor3 = Color3.fromRGB(180, 180, 180); left.BackgroundTransparency = 1; left.TextSize = 14; left.Font = Enum.Font.Gotham; left.TextXAlignment = Enum.TextXAlignment.Left
        local right = Instance.new("TextLabel", rowFrame); right.Size = UDim2.new(0.4, 0, 1, 0); right.Position = UDim2.new(0.6, 0, 0, 0); right.Text = "0"; right.TextColor3 = Color3.fromRGB(255, 255, 255); right.BackgroundTransparency = 1; right.TextSize = 14; right.Font = Enum.Font.GothamBold; right.TextXAlignment = Enum.TextXAlignment.Right; right.Name = "Value" .. i
        labels[i] = right
    end
    return { Gui = GoldGui, Frame = Frame, Labels = labels, StartTime = os.time() }
end
local function find_numeric_label(root)
    if not root then return nil end
    if root:IsA("TextLabel") then
        local txt = tostring(root.Text):gsub("%%D",""):gsub("%s","")
        if txt ~= "" and tonumber(txt) then return root end
    end
    for _, c in ipairs(root:GetChildren()) do
        local found = find_numeric_label(c)
        if found then return found end
    end
    return nil
end
local function gold_loop(guiobj)
    if not guiobj then return end
    local playerGui = LP:WaitForChild("PlayerGui")
    if not playerGui then return end
    local goldLabel = nil
    local startAmount = 0; local gained = 0
    goldLabel = (playerGui:FindFirstChild("GoldGui") and find_numeric_label(playerGui.GoldGui.Frame)) or find_numeric_label(playerGui)
    if goldLabel then startAmount = tonumber((goldLabel.Text:gsub("[^%d]",""))) or 0 end
    guiobj.Labels[1].Text = tostring(startAmount); guiobj.Labels[2].Text = tostring(startAmount); guiobj.Labels[3].Text = tostring(0); guiobj.Labels[4].Text = "00:00"
    while GoldTracker.running do
        if not goldLabel or not goldLabel.Parent then goldLabel = (playerGui:FindFirstChild("GoldGui") and find_numeric_label(playerGui.GoldGui.Frame)) or find_numeric_label(playerGui) end
        if goldLabel then
            local cur = tonumber((goldLabel.Text:gsub("[^%d]",""))) or 0
            guiobj.Labels[2].Text = tostring(cur)
            if cur > startAmount then
                gained = gained + (cur - startAmount)
                guiobj.Labels[3].Text = tostring(gained)
                startAmount = cur
            elseif cur < startAmount then
                startAmount = cur
            end
        end
        local elapsed = os.time() - guiobj.StartTime
        guiobj.Labels[4].Text = string.format("%02d:%02d", math.floor(elapsed/60), elapsed%60)
        task.wait(1)
    end
end
function GoldTracker.start()
    if GoldTracker.running then return end
    GoldTracker.running = true
    local obj = create_gold_gui()
    GoldTracker.gui = obj
    if obj then task.spawn(function() gold_loop(obj) end) end
    STATE.Flags.Gold = true
end
function GoldTracker.stop()
    GoldTracker.running = false
    STATE.Flags.Gold = false
    if GoldTracker.gui and GoldTracker.gui.Gui and GoldTracker.gui.Gui.Parent then
        pcall(function() GoldTracker.gui.Gui:Destroy() end)
    end
    GoldTracker.gui = nil
end
STATE.Modules.GoldTracker = GoldTracker

-- ============================
-- UI BUILDING (Rayfield if available, else fallback)
-- ============================
local function makeFallbackWindow(title)
    local W = {}
    W._root = Instance.new("ScreenGui"); W._root.Name = "GMonFallbackGUI"; W._root.ResetOnSpawn = false
    pcall(function() W._root.Parent = LP:WaitForChild("PlayerGui") end)
    local frame = Instance.new("Frame", W._root); frame.Size = UDim2.new(0, 420, 0, 520); frame.Position = UDim2.new(0, 10, 0, 60); frame.BackgroundColor3 = Color3.fromRGB(25,25,25); frame.ClipsDescendants = true
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
    local titleL = Instance.new("TextLabel", frame); titleL.Size = UDim2.new(1, -8, 0, 30); titleL.Position = UDim2.new(0,4,0,4); titleL.Text = title; titleL.Font = Enum.Font.SourceSansBold; titleL.TextSize = 18; titleL.TextColor3 = Color3.fromRGB(220,220,220); titleL.BackgroundTransparency = 1
    local content = Instance.new("Frame", frame); content.Position = UDim2.new(0,4,0,40); content.Size = UDim2.new(1, -8, 1, -44); content.BackgroundTransparency = 1
    function W:CreateTab(name)
        local Tab = {}
        local y = #content:GetChildren() * 36
        local label = Instance.new("TextLabel", content); label.Position = UDim2.new(0,2,0,y); label.Size = UDim2.new(1,-4,0,32); label.Text = "[ "..name.." ]"; label.Font = Enum.Font.SourceSans; label.TextSize = 14; label.TextColor3 = Color3.fromRGB(200,200,200); label.BackgroundTransparency = 1
        function Tab:CreateLabel(txt) local L=Instance.new("TextLabel", content); L.Position=UDim2.new(0,6,0,y+36); L.Size=UDim2.new(1,-12,0,20); L.Text=txt; L.BackgroundTransparency=1; L.TextColor3=Color3.fromRGB(200,200,200); L.Font=Enum.Font.SourceSans; L.TextSize=13; y=y+26; return L end
        function Tab:CreateButton(tbl) local b = Instance.new("TextButton", content); b.Position = UDim2.new(0,6,0,y+36); b.Size = UDim2.new(1,-12,0,26); b.Text = tbl.Name or "Button"; b.Font=Enum.Font.SourceSansBold; b.TextSize=14; b.BackgroundColor3=Color3.fromRGB(40,40,40); b.TextColor3=Color3.fromRGB(230,230,230); b.MouseButton1Click:Connect(function() SAFE_CALL(tbl.Callback) end); y=y+32; return b end
        function Tab:CreateToggle(tbl) local frame = Instance.new("Frame", content); frame.Position = UDim2.new(0,6,0,y+36); frame.Size = UDim2.new(1,-12,0,26); frame.BackgroundTransparency=1; local label = Instance.new("TextLabel", frame); label.Size = UDim2.new(0.8,0,1,0); label.Text = tbl.Name; label.BackgroundTransparency=1; label.TextColor3=Color3.fromRGB(220,220,220); label.Font=Enum.Font.SourceSans; label.TextSize=14; local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0.18,0,1,0); btn.Position = UDim2.new(0.82,0,0,0); btn.Text = tbl.CurrentValue and "ON" or "OFF"; btn.Font = Enum.Font.SourceSansBold; btn.TextSize=14; btn.BackgroundColor3 = tbl.CurrentValue and Color3.fromRGB(30,140,40) or Color3.fromRGB(100,100,100); btn.MouseButton1Click:Connect(function() local nv = not tbl.CurrentValue; tbl.CurrentValue = nv; btn.Text = nv and "ON" or "OFF"; btn.BackgroundColor3 = nv and Color3.fromRGB(30,140,40) or Color3.fromRGB(100,100,100); SAFE_CALL(tbl.Callback, nv) end); y=y+32; return frame end
        function Tab:CreateSlider(tbl) local label = Instance.new("TextLabel", content); label.Position = UDim2.new(0,6,0,y+36); label.Size = UDim2.new(1,-12,0,22); label.Text = string.format("%s: %s", tbl.Name, tostring(tbl.CurrentValue)); label.TextColor3=Color3.fromRGB(220,220,220); label.BackgroundTransparency=1; y=y+26; local btn = Instance.new("TextButton", content); btn.Position = UDim2.new(0,6,0,y+36); btn.Size = UDim2.new(1,-12,0,26); btn.Text = "Set Value"; btn.Font = Enum.Font.SourceSans; btn.TextSize=14; btn.MouseButton1Click:Connect(function() SAFE_CALL(tbl.Callback, tbl.CurrentValue) end); y=y+32; return {label=label, button=btn} end
        function Tab:CreateDropdown(tbl) -- simple non-interactive: calls with current on click
            local label = Instance.new("TextLabel", content); label.Position = UDim2.new(0,6,0,y+36); label.Size = UDim2.new(1,-12,0,22); label.Text = tbl.Name .. " (use console to set)"; label.TextColor3=Color3.fromRGB(220,220,220); label.BackgroundTransparency=1; y=y+26
            local btn = Instance.new("TextButton", content); btn.Position = UDim2.new(0,6,0,y+36); btn.Size = UDim2.new(1,-12,0,26); btn.Text = "Open Options"; btn.Font = Enum.Font.SourceSans; btn.TextSize=14; btn.MouseButton1Click:Connect(function() SAFE_CALL(tbl.Callback, tbl.Default) end); y=y+32; return {label=label, button=btn}
        end
        return Tab
    end
    function W:Notify(params) pcall(function() StarterGui:SetCore("SendNotification", {Title = params.Title or "G-MON", Text = params.Content or "", Duration = params.Duration or 3}) end); print("[G-MON Notify]", params.Title, params.Content) end
    return W
end

-- Build UI
local Window = nil
if STATE.Rayfield and type(STATE.Rayfield.CreateWindow) == "function" then
    Window = STATE.Rayfield:CreateWindow({ Name = "G-MON Hub", LoadingTitle = "G-MON Hub", LoadingSubtitle = "Ready", ConfigurationSaving = { Enabled = true, FileName = "GMonConfig" } })
else
    Window = makeFallbackWindow("G-MON Hub")
end
STATE.Window = Window

-- Build tabs and attach Blox controls
local Tabs = {}
SAFE_CALL(function()
    if Window.CreateTab then
        Tabs.Info = Window:CreateTab("Info")
        Tabs.TabBlox = Window:CreateTab("Blox Fruit")
        Tabs.TabCar = Window:CreateTab("Car Tycoon")
        Tabs.TabBoat = Window:CreateTab("Build A Boat")
        Tabs.System = Window:CreateTab("System")
    end
end)
STATE.Tabs = Tabs

-- Info tab
SAFE_CALL(function()
    local t = Tabs.Info
    if t.CreateLabel then t:CreateLabel("G-MON Hub - Blox Extended") end
    if t.CreateParagraph then t:CreateParagraph({ Title = "Detected", Content = Utils.FlexibleDetectByAliases() }) end
    if t.CreateToggle then t:CreateToggle({ Name = "Gold Tracker (cross-game)", CurrentValue = false, Callback = function(v) if v then GoldTracker.start() else GoldTracker.stop() end end }) end
end)

-- Blox Tab: add controls based on M.ExposeConfig
SAFE_CALL(function()
    local t = Tabs.TabBlox
    local M = STATE.Modules.Blox
    if t.CreateLabel then t:CreateLabel("Blox Fruit - Extended Controls") end
    if t.CreateToggle then t:CreateToggle({ Name = "Auto Farm Selected Mob", CurrentValue = M.config.AutoFarm, Callback = function(v) M.config.AutoFarm = v; if v then SAFE_CALL(STATE.Modules.Blox.start) else SAFE_CALL(STATE.Modules.Blox.stop) end end }) end
    -- Mob dropdown: the fallback UI builder may not support full dropdown; create a simple button to refresh list
    if t.CreateDropdown then
        local mobs = {}
        pcall(function() mobs = (function() local o={}; if Workspace:FindFirstChild("Enemies") then for _,v in pairs(Workspace.Enemies:GetChildren()) do if not table.find(o, v.Name) then table.insert(o, v.Name) end end end; table.sort(o); return o end)() end)
        t:CreateDropdown({ Name = "Select Mob (console)", Default = M.config.MobToFarm, Options = mobs, Callback = function(v) end })
    end
    if t.CreateSlider then t:CreateSlider({ Name = "FarmDistance (studs)", Range = {5,100}, Increment = 1, CurrentValue = M.config.FarmDistance, Callback = function(v) M.config.FarmDistance = v end }) end
    if t.CreateToggle then t:CreateToggle({ Name = "Fast Attack", CurrentValue = M.config.FastAttack, Callback = function(v) M.config.FastAttack = v end }) end
    if t.CreateToggle then t:CreateToggle({ Name = "Auto Haki", CurrentValue = M.config.AutoHaki, Callback = function(v) M.config.AutoHaki = v end }) end
    if t.CreateToggle then t:CreateToggle({ Name = "Auto Stats", CurrentValue = M.config.AutoStats, Callback = function(v) M.config.AutoStats = v end }) end
    if t.CreateDropdown then t:CreateDropdown({ Name = "Select Stat (console)", Default = M.config.SelectStat, Options = {"Melee","Defense","Sword","Demon Fruit","Gun"}, Callback = function(v) end }) end
    if t.CreateDropdown then t:CreateDropdown({ Name = "Select Weapon (console)", Default = M.config.SelectWeapon, Options = {"Melee","Sword","Blox Fruit"}, Callback = function(v) end }) end
    if t.CreateToggle then t:CreateToggle({ Name = "ESP Players", CurrentValue = M.config.ESPPlayers, Callback = function(v) M.config.ESPPlayers = v end }) end

    -- Teleport buttons (use game's remotes if available)
    if t.CreateButton then
        t:CreateButton({ Name = "Teleport to Sea 1", Callback = function()
            local ok, rem = pcall(function() return ReplicatedStorage.Remotes.CommF_ end)
            if ok and rem then pcall(function() rem:InvokeServer("TravelMain") end) else (Window.Notify and Window.Notify or makeFallbackWindow("G-MON").Notify)({Title="G-MON", Content="Remote not found: CommF_", Duration=3}) end
        end })
        t:CreateButton({ Name = "Teleport to Sea 2", Callback = function()
            local ok, rem = pcall(function() return ReplicatedStorage.Remotes.CommF_ end)
            if ok and rem then pcall(function() rem:InvokeServer("TravelDressrosa") end) else (Window.Notify and Window.Notify or makeFallbackWindow("G-MON").Notify)({Title="G-MON", Content="Remote not found: CommF_", Duration=3}) end
        end })
        t:CreateButton({ Name = "Teleport to Sea 3", Callback = function()
            local ok, rem = pcall(function() return ReplicatedStorage.Remotes.CommF_ end)
            if ok and rem then pcall(function() rem:InvokeServer("TravelZou") end) else (Window.Notify and Window.Notify or makeFallbackWindow("G-MON").Notify)({Title="G-MON", Content="Remote not found: CommF_", Duration=3}) end
        end })
    end
end)

-- CAR, BOAT, SYSTEM tabs (basic)
SAFE_CALL(function()
    local t = Tabs.TabCar
    if t and t.CreateLabel then t:CreateLabel("Car Tycoon Controls (basic)") end
    local t2 = Tabs.TabBoat
    if t2 and t2.CreateLabel then t2:CreateLabel("Build A Boat Controls (basic)") end
    local sys = Tabs.System
    if sys and sys.CreateLabel then sys:CreateLabel("System") end
    if sys and sys.CreateButton then sys:CreateButton({ Name = "Force Detect", Callback = function() local det=Utils.FlexibleDetectByAliases(); STATE.GAME=det; STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A") end }) end
end)

-- ApplyGame & status updater
local function ApplyGame(gameKey)
    STATE.GAME = gameKey or Utils.FlexibleDetectByAliases()
    SAFE_CALL(function()
        STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
        STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Car: Available" or "Car: N/A")
        STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: Blox extended", Duration=3}) end
    end)
end
task.spawn(function()
    while true do SAFE_WAIT(1); SAFE_CALL(function() if STATE.Status and STATE.Status.UpdateRuntime then STATE.Status.UpdateRuntime() end; if STATE.Status and STATE.Status.SetIndicator then STATE.Status.SetIndicator("last", false, "Last: "..(STATE.LastAction or "Idle")) end end) end
end)

-- INIT
SAFE_CALL(function()
    ApplyGame(Utils.FlexibleDetectByAliases())
    Utils.AntiAFK()
    print("[G-MON] Blox extended loaded.")
end)

-- Expose some helpers for console/testing
_G.GMON = _G.GMON or {}
_G.GMON.Modules = STATE.Modules
_G.GMON.SetMob = function(m) if STATE.Modules.Blox then STATE.Modules.Blox.config.MobToFarm = m end end
_G.GMON.SetWeapon = function(w) if STATE.Modules.Blox then STATE.Modules.Blox.config.SelectWeapon = w end end
_G.GMON.StartBlox = function() SAFE_CALL(function() STATE.Modules.Blox.start() end) end
_G.GMON.StopBlox = function() SAFE_CALL(function() STATE.Modules.Blox.stop() end) end

return STATE