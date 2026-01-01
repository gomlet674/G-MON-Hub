-- main.lua (G-MON Hub) - Unified build
-- Features: Blox AutoFarm, CDT (Car Dealership Tycoon) full features incl. Buy Car Limited,
-- BuildAboat/Haruka AutoFarm, Status GUI, Save/Load settings, Rayfield fallback UI.
-- Best-effort robust heuristics for remotes/UI. Use in private/testing places only.

-- ===== BOOTSTRAP =====
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local HttpService = pcall(function() return game:GetService("HttpService") end) and game:GetService("HttpService") or nil
local LP = Players.LocalPlayer

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
    if sec > 5 then sec = 5 end
    task.wait(sec)
end

local function tryWriteFile(name, content)
    pcall(function()
        if writefile then writefile(name, content) end
    end)
end
local function tryReadFile(name)
    if isfile then
        local ok, data = pcall(function() return readfile(name) end)
        if ok then return data end
    end
    return nil
end

-- ===== NOTIFICATION (try SetCore, fallback custom) =====
local function notify(title, text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = tostring(title or "G-MON"), Text = tostring(text or ""), Duration = duration})
    end)
    -- fallback: lightweight ScreenGui
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui")
        local sg = Instance.new("ScreenGui")
        sg.Name = "GMonNotifyTemp"
        sg.ResetOnSpawn = false
        sg.Parent = pg
        local frame = Instance.new("Frame", sg)
        frame.Size = UDim2.new(0, 360, 0, 60)
        frame.Position = UDim2.new(0.5, -180, 0.05, 0)
        frame.BackgroundTransparency = 0.1
        frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
        frame.BorderSizePixel = 0
        local tl = Instance.new("TextLabel", frame)
        tl.Size = UDim2.new(1, -12, 1, -12)
        tl.Position = UDim2.new(0,6,0,6)
        tl.BackgroundTransparency = 1
        tl.TextColor3 = Color3.fromRGB(255,255,255)
        tl.Text = "["..tostring(title).."] "..tostring(text)
        tl.TextWrapped = true
        tl.Font = Enum.Font.Gotham
        tl.TextSize = 14
        spawn(function()
            task.wait(duration)
            pcall(function() sg:Destroy() end)
        end)
    end)
end

-- ===== STATE =====
local STATE = {
    GAME = "ALL",        -- default ALL
    StartTime = os.time(),
    Modules = {},
    Rayfield = nil, Window = nil, Tabs = {},
    Status = nil,
    Flags = {},
    UIHandles = {},
    Settings = {}
}

-- load settings from file if possible
local function loadSettings()
    local raw = tryReadFile("gmon_settings.json")
    if raw and HttpService then
        pcall(function()
            STATE.Settings = HttpService:JSONDecode(raw) or {}
        end)
    end
end
local function saveSettings()
    if HttpService then
        local ok, enc = pcall(function() return HttpService:JSONEncode(STATE.Settings or {}) end)
        if ok then tryWriteFile("gmon_settings.json", enc) end
    end
end
loadSettings()

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
    -- keep simple: return "ALL" if unknown
    local pid = game.PlaceId
    -- common IDs (kept from user's script)
    if pid == 2753915549 then return "BLOX_FRUIT" end
    if pid == 1554960397 then return "CAR_TYCOON" end
    if pid == 537413528 then return "BUILD_A_BOAT" end

    local aliasMap = {
        BLOX_FRUIT = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","Quests","NPCQuests"},
        CAR_TYCOON = {"Cars","VehicleFolder","Vehicles","Dealership","Garage","CarShop","CarStages","CarsFolder","Dealership"},
        BUILD_A_BOAT = {"BoatStages","Stages","NormalStages","StageFolder","BoatStage","Chest","Treasure"}
    }
    for key, list in pairs(aliasMap) do
        for _, name in ipairs(list) do
            if Workspace:FindFirstChild(name) then
                return key
            end
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        local n = string.lower(obj.Name or "")
        if string.find(n, "enemy") or string.find(n, "mob") or string.find(n, "monster") then return "BLOX_FRUIT" end
        if string.find(n, "car") or string.find(n, "vehicle") or string.find(n, "garage") or string.find(n,"dealership") then return "CAR_TYCOON" end
        if string.find(n, "boat") or string.find(n, "stage") or string.find(n, "chest") then return "BUILD_A_BOAT" end
    end
    return "ALL"
end

function Utils.ShortLabelForGame(g)
    if g == "BLOX_FRUIT" then return "Blox" end
    if g == "CAR_TYCOON" then return "CDT" end
    if g == "BUILD_A_BOAT" then return "BuildAboat" end
    return "All"
end

STATE.Modules.Utils = Utils

-- ===== REMOTE / UI HELPER (robust search) =====
local function findRemoteByNames(names)
    -- names: array of strings to try
    local function check(obj)
        if not obj then return false end
        local cls = obj.ClassName
        if cls == "RemoteEvent" or cls == "RemoteFunction" or cls == "BindableEvent" or cls=="BindableFunction" then
            return true
        end
        return false
    end
    local function search(parent)
        for _,v in ipairs(parent:GetDescendants()) do
            if v.Name and table.find(names, v.Name) and check(v) then return v end
        end
        for _,v in ipairs(parent:GetDescendants()) do
            if check(v) then
                for _,n in ipairs(names) do
                    if string.find(string.lower(v.Name), string.lower(n)) then return v end
                end
            end
        end
        return nil
    end
    -- try common containers
    local candidates = {ReplicatedStorage}
    if ReplicatedStorage:FindFirstChild("Remotes") then table.insert(candidates, ReplicatedStorage.Remotes) end
    for _,c in ipairs(candidates) do
        local found = search(c)
        if found then return found end
    end
    -- last resort: search entire game
    return search(game)
end

local function findRemoteByPattern(pattern)
    pattern = pattern:lower()
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v.ClassName=="RemoteEvent" or v.ClassName=="RemoteFunction") and string.find(string.lower(v.Name), pattern) then
            return v
        end
    end
    return nil
end

-- find player money heuristically
local function getPlayerMoney()
    -- 1) leaderstats
    if LP:FindFirstChild("leaderstats") then
        for _,v in ipairs(LP.leaderstats:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                local name = string.lower(v.Name)
                if name:find("cash") or name:find("money") or name:find("coins") or name:find("balance") or #v.Name>0 then
                    return tonumber(v.Value) or 0
                end
            end
        end
    end
    -- 2) attributes
    if LP:GetAttribute("Money") then return tonumber(LP:GetAttribute("Money")) or 0 end
    if LP:GetAttribute("Cash") then return tonumber(LP:GetAttribute("Cash")) or 0 end
    -- 3) try PlayerGui labels (search for a visible textlabel with digits)
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _,child in ipairs(pg:GetDescendants()) do
            if child:IsA("TextLabel") and child.Text and #child.Text>0 then
                local digits = child.Text:gsub("[^%d]","")
                if #digits>=1 then
                    local n = tonumber(digits)
                    if n and n>0 and n<1e12 then
                        return n
                    end
                end
            end
        end
    end
    return 0
end

-- parse price strings like "$37,500,000" or "37.500.000" into number
local function parsePrice(p)
    if not p then return 0 end
    local s = tostring(p)
    s = s:gsub("[%$%,%.]","")
    local n = tonumber(s)
    return n or 0
end

-- attempt to click UI button matching name (fallback)
local function clickGuiButtonByKeyword(keyword)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    keyword = string.lower(keyword)
    for _,v in ipairs(pg:GetDescendants()) do
        if v:IsA("TextButton") or v:IsA("ImageButton") then
            local nm = tostring(v.Name or "")
            local txt = tostring(v.Text or "")
            if string.find(string.lower(nm), keyword) or string.find(string.lower(txt), keyword) then
                pcall(function() firesignal and firesignal(v.MouseButton1Click) end)
                pcall(function() v:Activate() end)
                return true
            end
        end
    end
    return false
end

-- ===== Blox Module (kept) =====
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
        notify("G-MON", "Blox AutoFarm started", 3)
    end

    function M.stop()
        M.running = false
        STATE.Flags.Blox = false
        M._task = nil
        notify("G-MON", "Blox AutoFarm stopped", 3)
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

-- ===== CDT Module (full features incl. Buy Car Limited) =====
do
    local CDT = {}
    CDT.Auto = false
    CDT.collectables = false
    CDT.open = false
    CDT.fireman = false
    CDT.Customer = false
    CDT.deliver = false
    CDT.buyer = false
    CDT.annoy = false
    CDT.spawned = false
    CDT.speed = (STATE.Settings.CDT_Speed or 300)
    CDT._tasks = {}

    CDT.stars = tonumber(STATE.Settings.CDT_Stars or 0) or 0
    CDT.smaller = tonumber(STATE.Settings.CDT_MinReward or 0) or 0
    CDT.bigger = tonumber(STATE.Settings.CDT_MaxReward or 999999999) or 999999999

    local function saveCDTConfig()
        STATE.Settings.CDT_Speed = CDT.speed
        STATE.Settings.CDT_Stars = CDT.stars
        STATE.Settings.CDT_MinReward = CDT.smaller
        STATE.Settings.CDT_MaxReward = CDT.bigger
        saveSettings()
    end

    -- find player's tycoon
    local function findPlayerPlot()
        if not Workspace:FindFirstChild("Tycoons") then return nil end
        for _,v in pairs(Workspace.Tycoons:GetDescendants()) do
            if v.Name == "Owner" and v.ClassName == "StringValue" and (string.find(v.Parent.Name,"Plot") or string.find(v.Parent.Name,"Slot")) and v.Value == LP.Name then
                return v.Parent
            end
        end
        return nil
    end

    -- Auto Farm (vehicle) simplified:
    function CDT.startAutoFarm()
        if CDT.Auto then return end
        CDT.Auto = true
        CDT._tasks.auto = task.spawn(function()
            SAFE_CALL(function()
                if not Workspace:FindFirstChild("justapart") then
                    local new = Instance.new("Part",Workspace)
                    new.Name = "justapart"
                    new.Size = Vector3.new(10000,20,10000)
                    new.Anchored = true
                    new.Position = (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position) and (LP.Character.HumanoidRootPart.Position + Vector3.new(0,1000,0)) or Vector3.new(0,1000,0)
                end
                while CDT.Auto do
                    task.wait(0.5)
                    local chr = LP.Character
                    if not chr or not chr:FindFirstChild("Humanoid") or not chr:FindFirstChild("HumanoidRootPart") then continue end
                    if not chr.Humanoid.SeatPart then continue end
                    local car = chr.Humanoid.SeatPart.Parent.Parent or chr.Humanoid.SeatPart.Parent
                    if not car or not car.PrimaryPart then continue end
                    pcall(function()
                        local pos = Workspace.justapart.CFrame * CFrame.new(0,10,-1000)
                        if car.PrimaryPart then
                            car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * CDT.speed
                            car:SetPrimaryPartCFrame(pos)
                        end
                    end)
                end
            end)
        end)
        notify("G-MON", "CDT AutoFarm started", 3)
        saveCDTConfig()
    end
    function CDT.stopAutoFarm()
        CDT.Auto = false
        if CDT._tasks.auto then pcall(function() task.cancel(CDT._tasks.auto) end); CDT._tasks.auto = nil end
        notify("G-MON", "CDT AutoFarm stopped", 3)
    end

    -- other CDT features (collectibles/openkit/fireman/buyer/delivery) kept minimal like earlier merged script:
    function CDT.startCollectibles()
        if CDT.collectables then return end
        CDT.collectables = true
        CDT._tasks.collect = task.spawn(function()
            while CDT.collectables do
                task.wait(0.8)
                local chr = LP.Character
                if not chr or not chr:FindFirstChild("HumanoidRootPart") or not chr:FindFirstChild("Humanoid") then continue end
                if not chr.Humanoid.SeatPart then continue end
                local car = chr.Humanoid.SeatPart.Parent.Parent or chr.Humanoid.SeatPart.Parent
                if not (Workspace:FindFirstChild("Collectibles")) then continue end
                for _,v in pairs(Workspace.Collectibles:GetDescendants()) do
                    if v:IsA("Model") and v.PrimaryPart and v.Parent and v.PrimaryPart.Transparency ~= 1 then
                        pcall(function() car:SetPrimaryPartCFrame(v.PrimaryPart.CFrame) end)
                        break
                    end
                end
            end
        end)
        notify("G-MON", "CDT Collectibles started", 2)
    end
    function CDT.stopCollectibles()
        CDT.collectables = false
        if CDT._tasks.collect then pcall(function() task.cancel(CDT._tasks.collect) end); CDT._tasks.collect = nil end
        notify("G-MON", "CDT Collectibles stopped", 2)
    end

    function CDT.startOpenKit()
        if CDT.open then return end
        CDT.open = true
        CDT._tasks.open = task.spawn(function()
            while CDT.open do
                task.wait(1)
                SAFE_CALL(function()
                    local svc = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
                    local r = svc:FindFirstChild("CarKitEventServiceRemotes") or svc:FindFirstChild("CarKitEventService")
                    if r and r:FindFirstChild("ClaimFreePack") then
                        pcall(function() r.ClaimFreePack:InvokeServer() end)
                    end
                end)
            end
        end)
        notify("G-MON", "CDT Open Kit started", 2)
    end
    function CDT.stopOpenKit()
        CDT.open = false
        if CDT._tasks.open then pcall(function() task.cancel(CDT._tasks.open) end); CDT._tasks.open = nil end
        notify("G-MON", "CDT Open Kit stopped", 2)
    end

    function CDT.ExposeConfig()
        return {
            { type="toggle", name="Auto Farm (Vehicles)", current=CDT.Auto, onChange=function(v) if v then CDT.startAutoFarm() else CDT.stopAutoFarm() end end },
            { type="toggle", name="Auto Collectibles", current=CDT.collectables, onChange=function(v) if v then CDT.startCollectibles() else CDT.stopCollectibles() end end },
            { type="toggle", name="Auto Open Kit", current=CDT.open, onChange=function(v) if v then CDT.startOpenKit() else CDT.stopOpenKit() end end },
            { type="slider", name="AutoDrive Speed (CDT)", min=50, max=1000, current=CDT.speed, onChange=function(v) CDT.speed = v; saveCDTConfig() end },
            { type="input", name="Delivery: Min Stars", current=CDT.stars, onChange=function(v) CDT.stars = tonumber(v) or CDT.stars; saveCDTConfig() end },
            { type="input", name="Delivery: Min Reward", current=CDT.smaller, onChange=function(v) CDT.smaller = tonumber(v) or CDT.smaller; saveCDTConfig() end },
            { type="input", name="Delivery: Max Reward", current=CDT.bigger, onChange=function(v) CDT.bigger = tonumber(v) or CDT.bigger; saveCDTConfig() end }
        }
    end

    -- ===== BUY CAR LIMITED (UI + logic) =====
    -- Define limited car list
    CDT.LimitedCars = {
        { Name = "Hyperluxe Balle", IdName = "Bugatti5", PriceStr = "$37,500,000", Price = parsePrice("$37,500,000") },
        { Name = "Hyperluxe 300+ / SS+", IdName = "HyperluxeSS", PriceStr = "$35,000,000", Price = parsePrice("$35,000,000") },
        { Name = "Hyperluxe Vision GT", IdName = "VisionGT", PriceStr = "$30,000,000", Price = parsePrice("$30,000,000") }
    }

    -- Try several remote patterns for purchasing (heuristics)
    local purchaseRemoteCandidates = {"DealershipCustomerController", "PurchaseCar", "BuyCar", "BuyVehicle", "Dealership", "SpawnCar", "Purchase"}

    local function tryRemotePurchase(carIdName)
        -- attempt to locate remote functions/events and call common patterns
        -- pattern 1: ReplicatedStorage.Remotes.DealershipCustomerController.NPCHandler:FireServer({Action="Buy", ...})
        local rems = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
        local found = nil
        for _,name in ipairs({"DealershipCustomerController","DealershipController","CustomerController","DealershipCustomer"}) do
            local node = rems:FindFirstChild(name) or rems:FindFirstChild(name.."_Remotes")
            if node then
                -- try NPCHandler, NPCHandler:FireServer pattern
                local npc = node:FindFirstChild("NPCHandler") or node:FindFirstChild("NPCHandlerRemotes")
                if npc and npc.ClassName=="RemoteEvent" then
                    pcall(function()
                        npc:FireServer({Action="BuyLimited", Car = carIdName})
                    end)
                    return true
                end
                -- try JobRemoteHandler or JobRemote
                local jr = node:FindFirstChild("JobRemoteHandler") or node:FindFirstChild("JobRemote")
                if jr and jr.ClassName=="RemoteEvent" then
                    pcall(function() jr:FireServer({Action="Buy", Car = carIdName}) end)
                    return true
                end
            end
        end
        -- try generic remote by name search
        for _,pattern in ipairs({"buy","purchase","spawn","dealership"}) do
            local rem = findRemoteByPattern(pattern)
            if rem then
                pcall(function()
                    if rem.ClassName=="RemoteFunction" then
                        rem:InvokeServer("BuyCar", carIdName)
                    else
                        rem:FireServer({Action="BuyCar", Car = carIdName})
                    end
                end)
                return true
            end
        end
        return false
    end

    -- Buy Car main function
    function CDT.BuyCarLimited(index)
        index = tonumber(index) or 1
        local data = CDT.LimitedCars[index]
        if not data then notify("G-MON", "Car data not found.", 3); return false end
        local playerMoney = getPlayerMoney()
        if playerMoney < data.Price then
            notify("G-MON", "Not enough money for "..data.Name.." (need "..tostring(data.Price)..")", 4)
            return false
        end

        -- try remote purchase first
        local ok = pcall(function() ok = tryRemotePurchase(data.IdName) end)
        if ok then
            notify("G-MON", "Attempted purchase via remote for "..data.Name, 3)
            return true
        end

        -- fallback: try to click UI buttons that match the car name
        local clicked = clickGuiButtonByKeyword(data.Name) or clickGuiButtonByKeyword(data.IdName) or clickGuiButtonByKeyword("buy "..data.Name)
        if clicked then
            notify("G-MON", "Clicked UI to buy "..data.Name, 3)
            return true
        end

        notify("G-MON", "Buy attempt failed; remote/UI not found.", 4)
        return false
    end

    STATE.Modules.CarDeal = CDT
end

-- ===== Haruka / Build A Boat simplified module =====
do
    local M = {}
    M.autoRunning = false
    M._autoTask = nil

    local function haruka_auto_loop()
        while M.autoRunning do
            task.wait(1.2)
            local char = game.Players.LocalPlayer.Character
            if not char then continue end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then wait(1); continue end
            -- example patrol movement: try teleport to a few coords heuristically
            pcall(function() hrp.CFrame = CFrame.new(0,50,0) end)
            task.wait(0.5)
            pcall(function() hrp.CFrame = CFrame.new(0,50,50) end)
            task.wait(0.5)
            pcall(function() hrp.CFrame = CFrame.new(0,50,100) end)
        end
    end

    function M.startAutoFarm()
        if M.autoRunning then return end
        M.autoRunning = true
        STATE.Flags.HarukaAuto = true
        M._autoTask = task.spawn(haruka_auto_loop)
        notify("G-MON", "BuildAboat AutoFarm started", 3)
    end

    function M.stopAutoFarm()
        M.autoRunning = false
        STATE.Flags.HarukaAuto = false
        M._autoTask = nil
        notify("G-MON", "BuildAboat AutoFarm stopped", 3)
    end

    function M.ExposeConfig()
        return {
            { type="toggle", name="AutoFarm (BuildAboat)", current=false, onChange=function(v) if v then M.startAutoFarm() else M.stopAutoFarm() end end }
        }
    end

    STATE.Modules.Haruka = M
end

-- ===== RAYFIELD LOAD (safe fallback) =====
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        STATE.Rayfield = Ray
    else
        warn("[G-MON] Rayfield load failed; using fallback UI.")
        -- minimal fallback UI builder (procedural ScreenGui controls)
        local Fallback = {}
        function Fallback:CreateWindow(opts)
            local win = {}
            local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui")
            local baseGui = Instance.new("ScreenGui", pg)
            baseGui.Name = "GMonFallbackUI"
            baseGui.ResetOnSpawn = false

            local main = Instance.new("Frame", baseGui)
            main.Size = UDim2.new(0, 540, 0, 420)
            main.Position = UDim2.new(0.02,0,0.05,0)
            main.BackgroundColor3 = Color3.fromRGB(18,18,18)
            main.BorderSizePixel = 0
            local title = Instance.new("TextLabel", main)
            title.Size = UDim2.new(1,0,0,32)
            title.Text = opts and opts.Name or "G-MON"
            title.BackgroundTransparency = 1
            title.TextColor3 = Color3.new(1,1,1)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 16

            function win:CreateTab(name)
                local tabFrame = Instance.new("Frame", main)
                tabFrame.Size = UDim2.new(1, -12, 1, -48)
                tabFrame.Position = UDim2.new(0,6,0,36)
                tabFrame.BackgroundTransparency = 1
                local scroll = Instance.new("ScrollingFrame", tabFrame)
                scroll.Size = UDim2.new(1, -12, 1, -12)
                scroll.Position = UDim2.new(0,6,0,6)
                scroll.CanvasSize = UDim2.new(0,0,0,0)
                local layout = Instance.new("UIListLayout", scroll)
                layout.Padding = UDim.new(0,6)
                layout.SortOrder = Enum.SortOrder.LayoutOrder

                local tab = {}
                function tab:CreateLabel(txt) local l = Instance.new("TextLabel", scroll); l.Size = UDim2.new(1,0,0,26); l.BackgroundTransparency=1; l.Text=tostring(txt); l.TextColor3=Color3.fromRGB(220,220,220); l.Font=Enum.Font.Gotham; l.TextSize=14; end
                function tab:CreateParagraph(tbl) tab:CreateLabel((tbl.Title and (tbl.Title..": ") or "")..(tbl.Content or "")) end
                function tab:CreateButton(tbl)
                    local b = Instance.new("TextButton", scroll)
                    b.Size = UDim2.new(1,0,0,36)
                    b.Text = tbl.Name or "Button"
                    b.Font = Enum.Font.GothamBold; b.TextSize=14
                    b.BackgroundColor3 = Color3.fromRGB(40,40,40); b.TextColor3 = Color3.new(1,1,1)
                    b.LayoutOrder = #scroll:GetChildren()
                    b.MouseButton1Click:Connect(function() SAFE_CALL(tbl.Callback) end)
                end
                function tab:CreateToggle(tbl)
                    local holder = Instance.new("Frame", scroll); holder.Size=UDim2.new(1,0,0,36); holder.BackgroundTransparency=1
                    local l = Instance.new("TextLabel", holder); l.Size=UDim2.new(0.75,0,1,0); l.Text=tostring(tbl.Name); l.BackgroundTransparency=1; l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=Enum.Font.Gotham; l.TextColor3=Color3.fromRGB(220,220,220)
                    local btn = Instance.new("TextButton", holder); btn.Size=UDim2.new(0.22,0,0,26); btn.Position=UDim2.new(0.78,0,0.08,0); btn.Text=(tbl.CurrentValue and "ON" or "OFF"); btn.Font=Enum.Font.GothamBold; btn.TextSize=14; btn.BackgroundColor3=Color3.fromRGB(35,35,35);
                    btn.MouseButton1Click:Connect(function()
                        btn.Text = (btn.Text=="ON") and "OFF" or "ON"
                        SAFE_CALL(tbl.Callback, btn.Text=="ON")
                    end)
                end
                function tab:CreateSlider(tbl)
                    tab:CreateParagraph({Title=tbl.Name, Content=("Value: "..tostring(tbl.CurrentValue))})
                    -- simple slider omitted for brevity; recommend using Rayfield if available
                end
                function tab:CreateInput(tbl)
                    local holder = Instance.new("Frame", scroll); holder.Size=UDim2.new(1,0,0,36); holder.BackgroundTransparency=1
                    local l = Instance.new("TextLabel", holder); l.Size=UDim2.new(0.6,0,1,0); l.Text=tostring(tbl.Name); l.BackgroundTransparency=1; l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=Enum.Font.Gotham; l.TextColor3=Color3.fromRGB(220,220,220)
                    local box = Instance.new("TextBox", holder); box.Size=UDim2.new(0.36,0,0,26); box.Position=UDim2.new(0.62,0,0.08,0); box.Text=tostring(tbl.CurrentText or "")
                    local btn = Instance.new("TextButton", holder); btn.Size=UDim2.new(0.18,0,0,20); btn.Position=UDim2.new(0.82,0,0.08,0); btn.Text="Set"
                    btn.MouseButton1Click:Connect(function() SAFE_CALL(tbl.Callback, box.Text) end)
                end
                return tab
            end

            function win:CreateNotification() end
            return win
        end
        function Fallback:Notify() end
        STATE.Rayfield = Fallback
    end
end

-- ===== STATUS GUI (improved) =====
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
            frame.Size = UDim2.new(0, 320, 0, 150)
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
            lines.car.lbl.Text = "CDT: OFF"
            lines.boat.lbl.Text = "BuildAboat: OFF"
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

-- create status gui
SAFE_CALL(function() if STATE.Status and STATE.Status.Create then STATE.Status.Create() end end)

-- ===== UI BUILDING (Rayfield if present, otherwise fallback UI) =====
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
            Tabs.TabCar = STATE.Window:CreateTab("Car Dealership")
            Tabs.TabBoat = STATE.Window:CreateTab("Build A Boat")
            Tabs.Save = STATE.Window:CreateTab("Settings")
            Tabs.Debug = STATE.Window:CreateTab("Debug")
        else
            -- fallback: use our Rayfield fallback create window which returns a "win" with CreateTab
            STATE.Window = STATE.Rayfield:CreateWindow({Name="G-MON Hub"})
            Tabs.Info = STATE.Window:CreateTab("Info")
            Tabs.TabBlox = STATE.Window:CreateTab("Blox Fruit")
            Tabs.TabCar = STATE.Window:CreateTab("Car Dealership")
            Tabs.TabBoat = STATE.Window:CreateTab("Build A Boat")
            Tabs.Save = STATE.Window:CreateTab("Settings")
            Tabs.Debug = STATE.Window:CreateTab("Debug")
        end
        STATE.Tabs = Tabs

        -- Info tab
        SAFE_CALL(function()
            Tabs.Info:CreateLabel("G-MON Hub - client-only. Use in private/testing places.")
            Tabs.Info:CreateParagraph({ Title = "Detected", Content = Utils.ShortLabelForGame(STATE.GAME) })
            Tabs.Info:CreateButton({ Name = "Detect Now", Callback = function()
                local det = Utils.FlexibleDetectByAliases()
                STATE.GAME = det
                STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT" or STATE.GAME=="ALL", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
                STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON" or STATE.GAME=="ALL", (STATE.GAME=="CAR_TYCOON") and "CDT: Available" or "CDT: N/A")
                STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT" or STATE.GAME=="ALL", (STATE.GAME=="BUILD_A_BOAT") and "BuildAboat: Available" or "BuildAboat: N/A")
                notify("G-MON", "Detect done: "..Utils.ShortLabelForGame(STATE.GAME), 3)
            end })
            Tabs.Info:CreateParagraph({ Title = "Note", Content = "Use tabs to control modules. Settings saved to gmon_settings.json if executor supports writefile/readfile." })
        end)

        -- Blox Tab
        SAFE_CALL(function()
            local t = Tabs.TabBlox
            t:CreateLabel("Blox Fruit Controls")
            local conf = STATE.Modules.Blox:ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then
                    t:CreateToggle({ Name = opt.name, CurrentValue = opt.current or false, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                elseif opt.type == "slider" then
                    t:CreateSlider({ Name = opt.name, Range = {opt.min or opt.Range[1], opt.max or opt.Range[2]}, Increment = opt.Increment or 1, CurrentValue = opt.current, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                end
            end
            t:CreateToggle({ Name = "Enable Blox AutoFarm", CurrentValue = false, Callback = function(v) if v then STATE.Modules.Blox.start() else STATE.Modules.Blox.stop() end end })
        end)

        -- Car Dealership tab (CDT)
        SAFE_CALL(function()
            local t = Tabs.TabCar
            t:CreateLabel("Car Dealership Tycoon (CDT)")

            -- expose CDT configs
            local conf = STATE.Modules.CarDeal:ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then
                    t:CreateToggle({ Name = opt.name, CurrentValue = opt.current or false, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                elseif opt.type == "slider" then
                    t:CreateSlider({ Name = opt.name, Range = {opt.min or opt.Range[1], opt.max or opt.Range[2]}, Increment = opt.Increment or 1, CurrentValue = opt.current, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                elseif opt.type == "input" then
                    t:CreateInput({ Name = opt.name, CurrentText = tostring(opt.current or ""), Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                end
            end

            -- Buy Car Limited UI (Select)
            t:CreateParagraph({ Title = "Buy Car Limited", Content = "Select a car to view price and buy." })
            -- build select using CreateButton list
            for i,car in ipairs(STATE.Modules.CarDeal.LimitedCars) do
                local name = car.Name
                local price = car.PriceStr
                t:CreateButton({ Name = ("Select: "..name), Callback = function()
                    -- show info and provide Buy button
                    notify("G-MON", "Selected: "..name.." | Price: "..price, 4)
                    -- show small GUI for Buy/Info using SetCore or fallback
                    local function showBuyGui()
                        local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui")
                        if pg:FindFirstChild("GMonBuyGui") then pg.GMonBuyGui:Destroy() end
                        local sg = Instance.new("ScreenGui", pg); sg.Name = "GMonBuyGui"; sg.ResetOnSpawn=false
                        local frame = Instance.new("Frame", sg); frame.Size=UDim2.new(0,320,0,120); frame.Position=UDim2.new(0.5,-160,0.5,-60); frame.BackgroundColor3=Color3.fromRGB(25,25,25)
                        local title = Instance.new("TextLabel", frame); title.Size=UDim2.new(1,0,0,28); title.BackgroundTransparency=1; title.Text="Buy Car Limited"; title.Font=Enum.Font.GothamBold; title.TextSize=16; title.TextColor3=Color3.new(1,1,1)
                        local label = Instance.new("TextLabel", frame); label.Size=UDim2.new(1,0,0,28); label.Position=UDim2.new(0,0,0,36); label.BackgroundTransparency=1; label.Text= name .. " | Price: " .. price; label.Font=Enum.Font.Gotham; label.TextSize=14; label.TextColor3=Color3.fromRGB(200,200,200)
                        local buyBtn = Instance.new("TextButton", frame); buyBtn.Size=UDim2.new(0.48,0,0,28); buyBtn.Position=UDim2.new(0.02,0,0,76); buyBtn.Text="Buy"; buyBtn.Font=Enum.Font.GothamBold; buyBtn.TextSize=14; buyBtn.BackgroundColor3=Color3.fromRGB(40,120,40)
                        local closeBtn = Instance.new("TextButton", frame); closeBtn.Size=UDim2.new(0.48,0,0,28); closeBtn.Position=UDim2.new(0.5,0,0,76); closeBtn.Text="Close"; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=14; closeBtn.BackgroundColor3=Color3.fromRGB(120,40,40)
                        buyBtn.MouseButton1Click:Connect(function()
                            -- find index by name
                            for idx,c in ipairs(STATE.Modules.CarDeal.LimitedCars) do
                                if c.Name == name then
                                    local ok = SAFE_CALL(function() return STATE.Modules.CarDeal.BuyCarLimited(idx) end)
                                    if ok then notify("G-MON", "Buy attempt sent for "..name, 4) end
                                end
                            end
                            pcall(function() sg:Destroy() end)
                        end)
                        closeBtn.MouseButton1Click:Connect(function() pcall(function() sg:Destroy() end) end)
                    end
                    showBuyGui()
                end })
            end
        end)

        -- Build A Boat tab (Haruka simplified)
        SAFE_CALL(function()
            local t = Tabs.TabBoat
            t:CreateLabel("Build A Boat (AutoFarm)")
            local conf = STATE.Modules.Haruka:ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then
                    t:CreateToggle({ Name = opt.name, CurrentValue = opt.current or false, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                end
            end
        end)

        -- Settings tab (save / load)
        SAFE_CALL(function()
            local t = Tabs.Save
            t:CreateLabel("Settings Save / Load")
            t:CreateButton({ Name = "Save Settings Now", Callback = function()
                saveSettings()
                notify("G-MON", "Settings saved", 2)
            end })
            t:CreateButton({ Name = "Load Settings Now", Callback = function()
                loadSettings()
                notify("G-MON", "Settings loaded", 2)
            end })
            t:CreateButton({ Name = "Reset Settings", Callback = function()
                STATE.Settings = {}; saveSettings(); notify("G-MON", "Settings reset", 2)
            end })
        end)

        -- Debug tab (reduced)
        SAFE_CALL(function()
            local t = Tabs.Debug
            t:CreateLabel("Debug / Utility")
            t:CreateButton({ Name = "Rebuild UI", Callback = function() SAFE_CALL(buildUI) end })
            t:CreateButton({ Name = "Detect & Apply Game", Callback = function() STATE.GAME = Utils.FlexibleDetectByAliases(); STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT" or STATE.GAME=="ALL"); notify("G-MON", "Applied game: "..Utils.ShortLabelForGame(STATE.GAME), 3) end })
            t:CreateButton({ Name = "Show ReplicatedStorage Structure (print)", Callback = function()
                local function scan(obj, indent)
                    indent = indent or ""
                    print(indent .. "- " .. obj.Name .. " [" .. obj.ClassName .. "]")
                    for _,v in ipairs(obj:GetChildren()) do
                        scan(v, indent .. "  ")
                    end
                end
                scan(ReplicatedStorage)
                notify("G-MON", "ReplicatedStorage printed to console", 3)
            end })
        end)
    end)
end

-- ===== STATUS UPDATER =====
task.spawn(function()
    while true do
        SAFE_WAIT(1)
        SAFE_CALL(function()
            if STATE.Status and STATE.Status.UpdateRuntime then STATE.Status.UpdateRuntime() end
            if STATE.Status and STATE.Status.SetIndicator then
                STATE.Status.SetIndicator("last", false, "Last: "..(STATE.LastAction or "Idle"))
            end
            -- update flags
            if STATE.Status and STATE.Status.SetIndicator then
                STATE.Status.SetIndicator("bf", STATE.Flags.Blox==true, (STATE.Flags.Blox and "Blox: ON") or "Blox: OFF")
                STATE.Status.SetIndicator("car", (STATE.Modules.CarDeal and (STATE.Modules.CarDeal.Auto==true or STATE.Modules.CarDeal.collectables==true)) or false, (STATE.Modules.CarDeal and "CDT") or "CDT: N/A")
                STATE.Status.SetIndicator("boat", STATE.Flags.HarukaAuto==true or STATE.Modules.Haruka.autoRunning==true, "BuildAboat")
            end
        end)
    end
end)

-- ===== ANTI AFK =====
SAFE_CALL(function() Utils.AntiAFK() end)

-- ===== INIT =====
local Main = {}
function Main.Start()
    SAFE_CALL(function()
        -- set initial game detection
        local det = Utils.FlexibleDetectByAliases()
        STATE.GAME = det or "ALL"
        STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT" or STATE.GAME=="ALL")
        STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON" or STATE.GAME=="ALL")
        STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT" or STATE.GAME=="ALL")
        buildUI()
        notify("G-MON Hub", "Loaded — use tabs to control modules", 4)
        print("[G-MON] main started. Detected:", STATE.GAME)
    end)
    return true
end

-- auto start
pcall(function() Main.Start() end)

return Main