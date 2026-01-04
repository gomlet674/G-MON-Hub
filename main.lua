-- GMON Hub - Merged (Blox Fruit, Car Dealership, Build A Boat) -- Combined and cleaned by Gemini Assistant -- Features: tabs for Blox Fruit, Car Dealership, Build A Boat, Info, Main, Settings -- Includes: Anti-AFK, Anti-Kick (safe), Rejoin Server, Save/Load UI config, Rayfield/Fallback UI

-- BOOTSTRAP
 repeat task.wait() until game:IsLoaded() local Players = game:GetService("Players") local RunService = game:GetService("RunService") local UIS = game:GetService("UserInputService") local VirtualUser = game:GetService("VirtualUser") local Workspace = workspace local ReplicatedStorage = game:GetService("ReplicatedStorage") local TeleportService = game:GetService("TeleportService") local MarketplaceService = game:GetService("MarketplaceService") local HttpService = game:GetService("HttpService") local LP = Players.LocalPlayer

-- SAFE helpers 
local function SAFE_CALL(fn, ...) if type(fn) ~= "function" then return false end local ok, res = pcall(fn, ...) if not ok then warn("[G-MON] SAFE_CALL error:", res) end return ok, res end

local function SAFE_WAIT(sec) sec = tonumber(sec) or 0.1 if sec < 0.01 then sec = 0.01 end if sec > 5 then sec = 5 end task.wait(sec) end

-- STATE 
local STATE = { GAME = "UNKNOWN", StartTime = os.time(), Modules = {}, Rayfield = nil, Window = nil, Tabs = {}, Status = nil, Flags = {}, LastAction = "Idle", ConfigFile = "gmon_hub_config.json", }

-- UTILS
local Utils = {} function Utils.SafeChar() local ok, c = pcall(function() return LP and LP.Character end) if not ok or not c then return nil end if c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then return c end return nil end

function Utils.AntiAFK() if not LP then return end SAFE_CALL(function() LP.Idled:Connect(function() pcall(function() local cam = workspace.CurrentCamera if cam and cam.CFrame then VirtualUser:Button2Down(Vector2.new(0,0), cam.CFrame) task.wait(1) VirtualUser:Button2Up(Vector2.new(0,0), cam.CFrame) else pcall(function() VirtualUser:Button2Down(); task.wait(1); VirtualUser:Button2Up() end) end end) end) end) end

function Utils.FormatTime(sec) sec = math.max(0, math.floor(sec or 0)) local h = math.floor(sec/3600); local m = math.floor((sec%3600)/60); local s = sec%60 if h>0 then return string.format("%02dh:%02dm:%02ds", h,m,s) end return string.format("%02dm:%02ds", m,s) end

function Utils.FlexibleDetectByAliases() local pid = game.PlaceId if pid == 2753915549 then return "BLOX_FRUIT" end if pid == 1554960397 then return "CAR_TYCOON" end if pid == 537413528 then return "BUILD_A_BOAT" end

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

function Utils.ShortLabelForGame(g) if g == "BLOX_FRUIT" then return "Blox" end if g == "CAR_TYCOON" then return "Car" end if g == "BUILD_A_BOAT" then return "Boat" end return tostring(g or "Unknown") end

STATE.Modules.Utils = Utils

-- RAYFIELD LOAD (safe fallback to simple UI) 
local function load_rayfield() local ok, Ray = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end) if ok and Ray then STATE.Rayfield = Ray return Ray else warn("[G-MON] Rayfield load failed; using fallback UI.") local Fallback = {} function Fallback:CreateWindow(opts) local win = {} function win:CreateTab(name) local tab = {} function tab:CreateLabel() end function tab:CreateParagraph() end function tab:CreateButton(tbl) end function tab:CreateToggle(tbl) end function tab:CreateSlider(tbl) end function tab:CreateDropdown(tbl) end return tab end function win:CreateNotification() end return win end function Fallback:Notify() end STATE.Rayfield = Fallback return Fallback end end

load_rayfield()

-- STATUS GUI (simple, draggable) 
do local Status = {} function Status.Create() SAFE_CALL(function() local pg = LP:WaitForChild("PlayerGui") local sg = Instance.new("ScreenGui") sg.Name = "GMonStatusGui" sg.ResetOnSpawn = false sg.Parent = pg

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
        title.Text = "G-MON Hub"
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

-- ---------- MODULE: BLOX FRUIT (adapted) ---------- 
do local M = {} M.config = { attack_delay = 0.35, range = 10, long_range = false, fast_attack = false } M.running = false M._task = nil

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
            if STATE.GAME ~= "BLOX_FRUIT" then return end
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

-- ---------- MODULE: CAR (includes Dealership features) ---------- 
do local M = {} M.running = false M.chosen = nil M.speed = 60 M._task = nil M.autoLimited = false M.selectedCar = ""

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

-- Car Dealership: Auto Buy Limited & Price Checker
function M.GetCarPrice(carName)
    local carsRoot = ReplicatedStorage:FindFirstChild("Cars")
    if not carsRoot then return "N/A" end
    local c = carsRoot:FindFirstChild(carName)
    if c and c:GetAttribute then
        return c:GetAttribute("Price") or "N/A"
    end
    -- fallback: try module
    local ok, mod = pcall(function() return ReplicatedStorage:FindFirstChild("Modules") and require(ReplicatedStorage.Modules:FindFirstChild("Cars")) end)
    if ok and type(mod) == "table" and mod[carName] and mod[carName].Price then return mod[carName].Price end
    return "N/A"
end

function M.BuyCar(carName)
    local rem = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Remote")
    if not rem then return end
    local buy = rem:FindFirstChild("BuyCar") or rem:FindFirstChild("BuyVehicle")
    if buy and buy.FireServer then
        pcall(function() buy:FireServer(carName) end)
    end
end

function M.StartAutoLimited()
    if M.autoLimited then return end
    M.autoLimited = true
    STATE.Flags.AutoLimited = true
    task.spawn(function()
        local lastBuy = 0
        while M.autoLimited do
            task.wait(1)
            pcall(function()
                local carsRoot = ReplicatedStorage:FindFirstChild("Cars")
                if not carsRoot then return end
                for _, car in pairs(carsRoot:GetChildren()) do
                    local isLimited = false
                    if car.GetAttribute then isLimited = car:GetAttribute("IsLimited") == true end
                    if not isLimited then
                        -- try tag name
                        if string.find(string.lower(car.Name or ""), "limited") then isLimited = true end
                    end
                    if isLimited then
                        local owned = false
                        if LP:FindFirstChild("OwnedCars") and LP.OwnedCars:FindFirstChild(car.Name) then owned = true end
                        if not owned and tick() - lastBuy > 4 then
                            lastBuy = tick()
                            M.BuyCar(car.Name)
                        end
                    end
                end
            end)
        end
    end)
end

function M.StopAutoLimited()
    M.autoLimited = false
    STATE.Flags.AutoLimited = false
end

STATE.Modules.Car = M

end

-- ---------- MODULE: BOAT (Build A Boat) ---------- 
do local M = {} M.running = false M.delay = 1.5 M._task = nil

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

-- ---------- HARUKA (Scripts picker lightweight) ---------- 
do local M = {} M.autoRunning = false M.goldRunning = false M._autoTask = nil

local function haruka_auto_loop(character)
    while M.autoRunning do
        if not character or not character.Parent then
            task.wait(1)
            character = game.Players.LocalPlayer.Character
        else
            task.wait(1.24)
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1) else
                local velObj = Instance.new("BodyVelocity")
                velObj.Velocity = Vector3.new(0, -0.1, 0)
                velObj.MaxForce = Vector3.new(1e5,1e5,1e5)
                velObj.Parent = hrp

                pcall(function() hrp.CFrame = CFrame.new(-135.900,72,623.750) end)
                while hrp and hrp.Parent and hrp.CFrame.Z < 8600.75 and M.autoRunning do
                    for i=1,50 do
                        if not M.autoRunning then break end
                        if hrp then pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0,0,0.3) end) end
                    end
                    task.wait()
                end
                pcall(function() velObj:Destroy() end)
            end
        end
    end
end

function M.startAutoFarm()
    if M.autoRunning then return end
    M.autoRunning = true
    STATE.Flags.HarukaAuto = true
    if game.Players.LocalPlayer.Character then
        M._autoTask = task.spawn(function() haruka_auto_loop(game.Players.LocalPlayer.Character) end)
    end
    game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(2)
        if M.autoRunning then task.spawn(function() haruka_auto_loop(char) end) end
    end)
end

function M.stopAutoFarm()
    M.autoRunning = false
    STATE.Flags.HarukaAuto = false
    M._autoTask = nil
end

STATE.Modules.Haruka = M

end

-- ---------- UI BUILD ---------- 
local function buildUI() SAFE_CALL(function() local Ray = STATE.Rayfield STATE.Window = (Ray and Ray.CreateWindow) and Ray:CreateWindow({ Name = "G-MON Hub", LoadingTitle = "G-MON Hub", LoadingSubtitle = "Ready", ConfigurationSaving = { Enabled = false } }) or nil

local Tabs = {}
    if STATE.Window then
        Tabs.Info = STATE.Window:CreateTab("Info")
        Tabs.Main = STATE.Window:CreateTab("Main")
        Tabs.TabBlox = STATE.Window:CreateTab("Blox Fruit")
        Tabs.TabCar = STATE.Window:CreateTab("Car Dealership Tycoon")
        Tabs.TabBoat = STATE.Window:CreateTab("Build A Boat")
        Tabs.Scripts = STATE.Window:CreateTab("Scripts")
        Tabs.Settings = STATE.Window:CreateTab("Settings")
    else
        local function makeTab()
            return { CreateLabel = function() end, CreateParagraph = function() end, CreateButton = function() end, CreateToggle = function() end, CreateSlider = function() end, CreateDropdown = function() end }
        end
        Tabs.Info = makeTab(); Tabs.Main = makeTab(); Tabs.TabBlox = makeTab(); Tabs.TabCar = makeTab(); Tabs.TabBoat = makeTab(); Tabs.Scripts = makeTab(); Tabs.Settings = makeTab()
    end
    STATE.Tabs = Tabs

    -- Info tab
    SAFE_CALL(function()
        local t = Tabs.Info
        t:CreateLabel("G-MON Hub - Combined: Blox Fruit / Car Dealership / Build A Boat")
        local detected = Utils.FlexibleDetectByAliases()
        local placeName = "Unknown"
        pcall(function() local info = MarketplaceService:GetProductInfo(game.PlaceId); if info and info.Name then placeName = info.Name end end)
        t:CreateParagraph({ Title = "Detected", Content = Utils.ShortLabelForGame(detected) })
        t:CreateParagraph({ Title = "Place", Content = "PlaceId: "..tostring(game.PlaceId).." | "..tostring(placeName) })
        t:CreateParagraph({ Title = "Notes", Content = "Use Main tab to see detected game and quick actions. Each game tab contains full features." })
    end)

    -- Main tab
    SAFE_CALL(function()
        local t = Tabs.Main
        t:CreateLabel("Quick Actions")
        t:CreateParagraph({ Title = "Detected Game", Content = Utils.ShortLabelForGame(STATE.GAME) })
        t:CreateButton({ Name = "Detect Now", Callback = function()
            local det = Utils.FlexibleDetectByAliases()
            STATE.GAME = det
            STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
            STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Car: Available" or "Car: N/A")
            STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
            if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(det), Duration=3}) end
        end })
        t:CreateButton({ Name = "Rejoin Server", Callback = function()
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
        end })
    end)

    -- BLOX tab
    SAFE_CALL(function()
        local t = Tabs.TabBlox
        t:CreateLabel("Blox Fruit Controls")
        t:CreateToggle({ Name = "Auto Farm (Blox)", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Blox.start) else SAFE_CALL(STATE.Modules.Blox.stop) end end })
        t:CreateToggle({ Name = "Fast Attack", CurrentValue = STATE.Modules.Blox.config.fast_attack, Callback = function(v) STATE.Modules.Blox.config.fast_attack = v end })
        t:CreateToggle({ Name = "Long Range Hit", CurrentValue = STATE.Modules.Blox.config.long_range, Callback = function(v) STATE.Modules.Blox.config.long_range = v end })
        t:CreateSlider({ Name = "Range Farming (studs)", Range = {1,50}, Increment = 1, CurrentValue = STATE.Modules.Blox.config.range or 10, Callback = function(v) STATE.Modules.Blox.config.range = v end })
        t:CreateSlider({ Name = "Attack Delay (ms)", Range = {50,1000}, Increment = 25, CurrentValue = math.floor((STATE.Modules.Blox.config.attack_delay or 0.35)*1000), Callback = function(v) STATE.Modules.Blox.config.attack_delay = v/1000 end })
    end)

    -- CAR tab (Dealership)
    SAFE_CALL(function()
        local t = Tabs.TabCar
        t:CreateLabel("Car Dealership Tycoon")
        t:CreateToggle({ Name = "Car AutoDrive", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Car.start) else SAFE_CALL(STATE.Modules.Car.stop) end end })
        t:CreateSlider({ Name = "Car Speed", Range = {20,200}, Increment = 5, CurrentValue = STATE.Modules.Car.speed or 60, Callback = function(v) STATE.Modules.Car.speed = v end })
        t:CreateParagraph({ Title = "Dealership", Content = "Auto Buy Limited / Price Checker below" })
        t:CreateToggle({ Name = "Auto Buy NEW Limited", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Car.StartAutoLimited) else SAFE_CALL(STATE.Modules.Car.StopAutoLimited) end end })
        t:CreateDropdown({ Name = "Select Car (CWR)", Options = (function()
            local out = {}
            local cars = ReplicatedStorage:FindFirstChild("Cars")
            if cars then for _,c in pairs(cars:GetChildren()) do table.insert(out, c.Name) end end
            table.sort(out)
            return out
        end)(), Default = "None", Callback = function(val) STATE.Modules.Car.selectedCar = val end })
        t:CreateButton({ Name = "Check Price & Info", Callback = function()
            local sel = STATE.Modules.Car.selectedCar
            if sel and sel ~= "" then
                local price = STATE.Modules.Car.GetCarPrice(sel)
                if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="Car Info", Content = sel.." | Price: "..tostring(price), Duration=4}) end
            else
                if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="Car Info", Content = "No car selected", Duration=3}) end
            end
        end })
        t:CreateButton({ Name = "BUY SELECTED CAR NOW", Callback = function()
            local sel = STATE.Modules.Car.selectedCar
            if sel and sel ~= "" then STATE.Modules.Car.BuyCar(sel) else if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="Error", Content = "No car selected"}) end end
        end })
    end)

    -- BOAT tab
    SAFE_CALL(function()
        local t = Tabs.TabBoat
        t:CreateLabel("Build A Boat Controls")
        t:CreateToggle({ Name = "Boat Auto Stages", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Boat.start) else SAFE_CALL(STATE.Modules.Boat.stop) end end })
        t:CreateSlider({ Name = "Stage Delay (s)", Range = {0.5,6}, Increment = 0.5, CurrentValue = STATE.Modules.Boat.delay or 1.5, Callback = function(v) STATE.Modules.Boat.delay = v end })
        t:CreateParagraph({ Title = "World Tools", Content = "Clear trees / set day time available in Scripts tab" })
    end)

    -- Scripts tab
    SAFE_CALL(function()
        local t = Tabs.Scripts
        t:CreateLabel("Script Picker & Utilities")
        t:CreateToggle({ Name = "Haruka AutoFarm (light)", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Haruka.startAutoFarm) else SAFE_CALL(STATE.Modules.Haruka.stopAutoFarm) end end })
        t:CreateButton({ Name = "Stop All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.stop); SAFE_CALL(STATE.Modules.Car.stop); SAFE_CALL(STATE.Modules.Boat.stop); SAFE_CALL(STATE.Modules.Haruka.stopAutoFarm) end })
        t:CreateButton({ Name = "Clear Trees & Rocks (World)", Callback = function() for _,v in pairs(Workspace:GetChildren()) do if v.Name == "Tree" or v.Name == "Rock" then pcall(function() v:Destroy() end) end end end })
        t:CreateButton({ Name = "Day Time (Full Bright)", Callback = function() pcall(function() game:GetService("Lighting").ClockTime = 14; game:GetService("Lighting").Brightness = 2; game:GetService("Lighting").GlobalShadows = false end) end })
    end)

    -- Settings tab
    SAFE_CALL(function()
        local t = Tabs.Settings
        t:CreateLabel("Settings & Utilities")
        t:CreateToggle({ Name = "Anti-AFK", CurrentValue = true, Callback = function(v) if v then Utils.AntiAFK() end end })
        t:CreateToggle({ Name = "Anti-Kick (no-op override)", CurrentValue = false, Callback = function(v)
            if v then
                if not LP.__gmon_oldKick then LP.__gmon_oldKick = LP.Kick end
                LP.Kick = function(...) warn("G-MON blocked a Kick") end
            else
                if LP.__gmon_oldKick then LP.Kick = LP.__gmon_oldKick; LP.__gmon_oldKick = nil end
            end
        end })
        t:CreateButton({ Name = "Rejoin Server", Callback = function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end) end })
        t:CreateButton({ Name = "Save Config", Callback = function()
            local ok, data = pcall(function() return HttpService:JSONEncode({flags = STATE.Flags, game = STATE.GAME}) end)
            if ok and writefile then
                pcall(function() writefile(STATE.ConfigFile, data) end)
                if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Config saved", Duration=2}) end
            else
                if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Save unsupported", Duration=2}) end
            end
        end })
        t:CreateButton({ Name = "Load Config", Callback = function()
            if readfile then
                local ok, str = pcall(function() return readfile(STATE.ConfigFile) end)
                if ok and str then
                    local ok2, dec = pcall(function() return HttpService:JSONDecode(str) end)
                    if ok2 and dec then
                        if dec.game then STATE.GAME = dec.game end
                        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Config loaded", Duration=2}) end
                    end
                else
                    if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="No config found", Duration=2}) end
                end
            else
                if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Load unsupported", Duration=2}) end
            end
        end })
    end)

end)

end

-- Apply Game (set status indicators) 
local function ApplyGame(gameKey) STATE.GAME = gameKey or Utils.FlexibleDetectByAliases() SAFE_CALL(function() STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A") STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Car: Available" or "Car: N/A") STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A") if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(STATE.GAME), Duration=3}) end end) end

-- STATUS UPDATER 
task.spawn(function() while true do SAFE_WAIT(1) SAFE_CALL(function() if STATE.Status and STATE.Status.UpdateRuntime then STATE.Status.UpdateRuntime() end if STATE.Status and STATE.Status.SetIndicator then STATE.Status.SetIndicator("last", false, "Last: "..(STATE.LastAction or "Idle")) end end) end end)

-- Anti-AFK Utils.AntiAFK()

-- Initialization 
local Main = {} function Main.Start() SAFE_CALL(function() buildUI() local det = Utils.FlexibleDetectByAliases() STATE.GAME = det ApplyGame(STATE.GAME) if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use tabs to control modules", Duration=5}) end print("[G-MON] main.lua started. Detected game:", STATE.GAME) end) return true end

-- run Main.Start()

return Main