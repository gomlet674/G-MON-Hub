-- G-MON Hub - final main.lua
-- Merged: Blox Fruit module, Car Dealership Tycoon (CDT), Haruka (separate Build A Boat tab), Anti-Kick, Status GUI
-- Movement (fly) removed per request.
-- Client-only script, uses Rayfield if available, fallback UI otherwise.

repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- SAFE helpers
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
    if g == "CAR_TYCOON" then return "CDT" end
    if g == "BUILD_A_BOAT" then return "Build A Boat" end
    return tostring(g or "Unknown")
end

STATE.Modules.Utils = Utils

-- ===== MODULES =====

-- BLOX Module
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

-- CarBase Module (kept)
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

    STATE.Modules.CarBase = M
end

-- CDT Module (extended)
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
    CDT.speed = 300
    CDT._tasks = {}
    CDT.stars = 0
    CDT.smaller = 0
    CDT.bigger = 999999999

    local function saveDeliveryConfig()
        SAFE_CALL(function()
            if type(writefile) == "function" then
                local s = tostring(CDT.stars.." "..CDT.smaller.." "..CDT.bigger)
                pcall(function() writefile("cdtdelivery.txt", s) end)
            end
        end)
    end
    local function loadDeliveryConfig()
        SAFE_CALL(function()
            if type(isfile) == "function" and isfile("cdtdelivery.txt") then
                local content = readfile("cdtdelivery.txt")
                if content and #content>0 then
                    local parts = {}
                    for p in string.gmatch(content, "%S+") do table.insert(parts, p) end
                    CDT.stars = tonumber(parts[1]) or CDT.stars
                    CDT.smaller = tonumber(parts[2]) or CDT.smaller
                    CDT.bigger = tonumber(parts[3]) or CDT.bigger
                end
            end
        end)
    end
    loadDeliveryConfig()

    local function findPlayerPlot()
        if not Workspace:FindFirstChild("Tycoons") then return nil end
        for _,v in pairs(Workspace.Tycoons:GetDescendants()) do
            if v.Name == "Owner" and v.ClassName == "StringValue" and (string.find(v.Parent.Name,"Plot") or string.find(v.Parent.Name,"Slot")) and v.Value == LP.Name then
                return v.Parent
            end
        end
        return nil
    end

    function CDT.startAutoFarm()
        if CDT.Auto then return end
        CDT.Auto = true
        CDT._tasks.auto = task.spawn(function()
            SAFE_CALL(function()
                if not Workspace:FindFirstChild("justapart") then
                    pcall(function()
                        local p = Instance.new("Part", Workspace)
                        p.Name = "justapart"
                        p.Size = Vector3.new(10000,20,10000)
                        p.Anchored = true
                        p.Position = Vector3.new(0,1000,0)
                    end)
                end
                while CDT.Auto do
                    task.wait(0.8)
                    local chr = LP.Character
                    if not chr or not chr:FindFirstChild("Humanoid") or not chr:FindFirstChild("HumanoidRootPart") then continue end
                    if not chr.Humanoid.SeatPart then continue end
                    local seat = chr.Humanoid.SeatPart
                    local car = seat.Parent
                    if not car or not car.PrimaryPart then continue end
                    pcall(function()
                        local speed = CDT.speed or 300
                        car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
                    end)
                    task.wait(2)
                end
            end)
        end)
    end
    function CDT.stopAutoFarm() CDT.Auto=false if CDT._tasks.auto then pcall(function() task.cancel(CDT._tasks.auto) end); CDT._tasks.auto=nil end end

    function CDT.startCollectibles()
        if CDT.collectables then return end
        CDT.collectables = true
        CDT._tasks.collect = task.spawn(function()
            while CDT.collectables do
                task.wait(0.7)
                local chr = LP.Character
                if not chr or not chr:FindFirstChild("HumanoidRootPart") or not chr:FindFirstChild("Humanoid") then continue end
                if not chr.Humanoid.SeatPart then continue end
                local car = chr.Humanoid.SeatPart.Parent
                if not Workspace:FindFirstChild("Collectibles") then continue end
                for _,v in pairs(Workspace.Collectibles:GetDescendants()) do
                    if not CDT.collectables then break end
                    if v:IsA("BasePart") and v.Parent and v.Parent.PrimaryPart then
                        pcall(function() car:SetPrimaryPartCFrame(v.Parent.PrimaryPart.CFrame) end)
                        task.wait(0.5)
                        break
                    end
                end
            end
        end)
    end
    function CDT.stopCollectibles() CDT.collectables=false if CDT._tasks.collect then pcall(function() task.cancel(CDT._tasks.collect) end); CDT._tasks.collect=nil end end

    function CDT.startOpenKit()
        if CDT.open then return end
        CDT.open = true
        CDT._tasks.open = task.spawn(function()
            while CDT.open do
                task.wait(1.5)
                SAFE_CALL(function()
                    local svc = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("RemotesFolder")
                    if svc and svc:FindFirstChild("Services") and svc.Services:FindFirstChild("CarKitEventServiceRemotes") and svc.Services.CarKitEventServiceRemotes:FindFirstChild("ClaimFreePack") then
                        pcall(function() svc.Services.CarKitEventServiceRemotes.ClaimFreePack:InvokeServer() end)
                    end
                end)
            end
        end)
    end
    function CDT.stopOpenKit() CDT.open=false if CDT._tasks.open then pcall(function() task.cancel(CDT._tasks.open) end); CDT._tasks.open=nil end end

    function CDT.startExtinguishFire()
        if CDT.fireman then return end
        CDT.fireman = true
        CDT._tasks.fire = task.spawn(function()
            while CDT.fireman do
                SAFE_CALL(function()
                    local rem = ReplicatedStorage:FindFirstChild("Remotes")
                    if rem and rem:FindFirstChild("Switch") then
                        pcall(function() rem.Switch:FireServer("FireDealership") end)
                    end
                end)
                task.wait(1)
            end
        end)
    end
    function CDT.stopExtinguishFire() CDT.fireman=false if CDT._tasks.fire then pcall(function() task.cancel(CDT._tasks.fire) end); CDT._tasks.fire=nil end end

    function CDT.startAutoSellCars()
        if CDT.Customer then return end
        CDT.Customer = true
        CDT._tasks.sell = task.spawn(function()
            while CDT.Customer do
                task.wait(1)
                SAFE_CALL(function()
                    local tycoon = findPlayerPlot()
                    if not tycoon or not tycoon:FindFirstChild("Dealership") then return end
                    local customer = nil
                    for _,v in pairs(tycoon.Dealership:GetChildren()) do
                        if v.ClassName == "Model" and v.PrimaryPart and v.PrimaryPart.Name == "HumanoidRootPart" then
                            customer = v; break
                        end
                    end
                    if not customer then return end
                    local npcRem = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("DealershipCustomerController")
                    if npcRem and npcRem:FindFirstChild("NPCHandler") then
                        pcall(function()
                            npcRem.NPCHandler:FireServer({Action="AcceptOrder", OrderId = customer:GetAttribute("OrderId")})
                            task.wait(0.4)
                            npcRem.NPCHandler:FireServer({OrderId = customer:GetAttribute("OrderId"), Action="CompleteOrder", Specs = {}})
                            task.wait(0.6)
                            npcRem.NPCHandler:FireServer({Action="CollectReward", OrderId = customer:GetAttribute("OrderId")})
                        end)
                    end
                    task.wait(2)
                end)
            end
        end)
    end
    function CDT.stopAutoSellCars() CDT.Customer=false if CDT._tasks.sell then pcall(function() task.cancel(CDT._tasks.sell) end); CDT._tasks.sell=nil end end

    function CDT.startAutoDelivery()
        if CDT.deliver then return end
        CDT.deliver = true
        CDT._tasks.deliver = task.spawn(function()
            while CDT.deliver do
                task.wait(1.2)
                SAFE_CALL(function()
                    local jobRem = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("DealershipCustomerController")
                    if jobRem and jobRem:FindFirstChild("JobRemoteHandler") then
                        pcall(function()
                            jobRem.JobRemoteHandler:FireServer({Action="TryToCompleteJob"})
                            task.wait(0.5)
                            jobRem.JobRemoteHandler:FireServer({Action="CollectReward"})
                        end)
                    end
                end)
            end
        end)
    end
    function CDT.stopAutoDelivery() CDT.deliver=false if CDT._tasks.deliver then pcall(function() task.cancel(CDT._tasks.deliver) end); CDT._tasks.deliver=nil end end

    function CDT.startAutoUpgrade()
        if CDT.buyer then return end
        CDT.buyer = true
        CDT._tasks.buyer = task.spawn(function()
            while CDT.buyer do
                task.wait(0.8)
                SAFE_CALL(function()
                    local tyc = findPlayerPlot()
                    if not tyc or not tyc:FindFirstChild("Dealership") or not tyc.Dealership:FindFirstChild("Purchases") then return end
                    for _,v in pairs(tyc.Dealership.Purchases:GetChildren()) do
                        if not CDT.buyer then break end
                        if v:FindFirstChild("TycoonButton") and v.TycoonButton:FindFirstChild("Button") then
                            local btn = v.TycoonButton.Button
                            if btn.Transparency == 0 then
                                pcall(function() ReplicatedStorage.Remotes.Build:FireServer("BuyItem", v.Name) end)
                                task.wait(0.25)
                            end
                        end
                    end
                end)
            end
        end)
    end
    function CDT.stopAutoUpgrade() CDT.buyer=false if CDT._tasks.buyer then pcall(function() task.cancel(CDT._tasks.buyer) end); CDT._tasks.buyer=nil end end

    local popupConn = nil
    function CDT.enablePopupBlock()
        if CDT.annoy then return end
        CDT.annoy = true
        popupConn = LP.PlayerGui.ChildAdded:Connect(function(ok)
            if ok and ok.Name and (ok.Name == "Popup2" or ok.Name == "AnnoyPopup") then
                pcall(function() ok:Destroy() end)
            end
        end)
    end
    function CDT.disablePopupBlock()
        CDT.annoy = false
        if popupConn then pcall(function() popupConn:Disconnect() end); popupConn = nil end
    end

    function CDT.setDeliveryConfig(stars, mini, maxi)
        CDT.stars = tonumber(stars) or CDT.stars
        CDT.smaller = tonumber(mini) or CDT.smaller
        CDT.bigger = tonumber(maxi) or CDT.bigger
        saveDeliveryConfig()
    end

    function CDT.ExposeConfig()
        return {
            { type="toggle", name="Auto Farm (Vehicles)", current=CDT.Auto, onChange=function(v) if v then CDT.startAutoFarm() else CDT.stopAutoFarm() end end },
            { type="toggle", name="Auto Farm Collectibles", current=CDT.collectables, onChange=function(v) if v then CDT.startCollectibles() else CDT.stopCollectibles() end end },
            { type="toggle", name="Auto Open Vehicle Kit", current=CDT.open, onChange=function(v) if v then CDT.startOpenKit() else CDT.stopOpenKit() end end },
            { type="toggle", name="Auto Extinguish Fire", current=CDT.fireman, onChange=function(v) if v then CDT.startExtinguishFire() else CDT.stopExtinguishFire() end end },
            { type="toggle", name="Auto Sell Cars", current=CDT.Customer, onChange=function(v) if v then CDT.startAutoSellCars() else CDT.stopAutoSellCars() end end },
            { type="toggle", name="Auto Delivery", current=CDT.deliver, onChange=function(v) if v then CDT.startAutoDelivery() else CDT.stopAutoDelivery() end end },
            { type="toggle", name="Auto Upgrade Plot", current=CDT.buyer, onChange=function(v) if v then CDT.startAutoUpgrade() else CDT.stopAutoUpgrade() end end },
            { type="toggle", name="Annoying Popup Disabler", current=CDT.annoy, onChange=function(v) if v then CDT.enablePopupBlock() else CDT.disablePopupBlock() end end },
            { type="slider", name="AutoDrive Speed (CDT)", min=50, max=1000, current=CDT.speed, onChange=function(v) CDT.speed = v end },
            { type="input", name="Delivery: Min Stars", current=CDT.stars, onChange=function(v) CDT.setDeliveryConfig(tonumber(v) or CDT.stars, CDT.smaller, CDT.bigger) end },
            { type="input", name="Delivery: Min Reward", current=CDT.smaller, onChange=function(v) CDT.setDeliveryConfig(CDT.stars, tonumber(v) or CDT.smaller, CDT.bigger) end },
            { type="input", name="Delivery: Max Reward", current=CDT.bigger, onChange=function(v) CDT.setDeliveryConfig(CDT.stars, CDT.smaller, tonumber(v) or CDT.bigger) end }
        }
    end

    STATE.Modules.CarDeal = CDT
end

-- Haruka Module (kept separate, will appear in Build A Boat tab)
do
    local M = {}
    M.autoRunning = false
    M.goldRunning = false
    M._autoTask = nil
    M._goldGui = nil

    local function haruka_auto_loop(character)
        while M.autoRunning do
            if not character or not character.Parent then
                wait(1)
                character = game.Players.LocalPlayer.Character
                if not character then continue end
            end

            wait(1.24)
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then wait(1) continue end

            local velObj = Instance.new("BodyVelocity", hrp)
            velObj.Velocity = Vector3.new(0, -0.1, 0)
            pcall(function() hrp.CFrame = CFrame.new(-135.900,72,623.750) end)

            while hrp and hrp.CFrame and hrp.CFrame.Z < 8600.75 and M.autoRunning do
                for i=1,50 do
                    if not M.autoRunning then break end
                    if hrp then pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0,0,0.3) end) end
                end
                wait()
            end

            if velObj then pcall(function() velObj:Destroy() end) end

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
        STATE.Flags.HarukaAuto = true
        if game.Players.LocalPlayer.Character then
            M._autoTask = task.spawn(function() haruka_auto_loop(game.Players.LocalPlayer.Character) end)
        end
        game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
            wait(2)
            if M.autoRunning then task.spawn(function() haruka_auto_loop(char) end) end
        end)
    end

    function M.stopAutoFarm()
        M.autoRunning = false
        STATE.Flags.HarukaAuto = false
        M._autoTask = nil
    end

    local function create_gold_gui()
        local player = game.Players.LocalPlayer
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
        local texts = {"Начальный баланс:", "Текущий баланс:", "Заработано:", "Время работы:"}
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
            local s = lbl.Text:gsub("%%D","")
            local num = s:gsub("%s",""):gsub(",","")
            if num ~= "" and tonumber(num) then return lbl end
            local digits = num:match("(%d+)")
            if digits and tonumber(digits) then return lbl end
        end
        return nil
    end

    local function gold_loop(stateObj)
        if not stateObj then return end
        local player = game.Players.LocalPlayer
        local root = player:FindFirstChild("PlayerGui")
        local Mroot = nil
        SAFE_CALL(function()
            if player and player:FindFirstChild("PlayerGui") then Mroot = player.PlayerGui end
        end)
        local startLabel = nil
        local baseAmount = 0
        stateObj.Labels[1].Text = "0"
        stateObj.Labels[2].Text = "0"
        stateObj.Labels[3].Text = "0"
        stateObj.Labels[4].Text = "0:00"
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
                            local txt = child.Text:gsub("%%D",""):gsub("%s","")
                            if txt ~= "" then
                                local num = txt:match("(%d+)")
                                if num and tonumber(num) then found = child; break end
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
            wait(1)
        end
    end

    function M.startGoldTracker()
        if M.goldRunning then return end
        M.goldRunning = true
        STATE.Flags.HarukaGold = true
        local obj = create_gold_gui()
        if obj then
            M._goldGui = obj
            task.spawn(function() gold_loop(obj) end)
        end
    end

    function M.stopGoldTracker()
        M.goldRunning = false
        STATE.Flags.HarukaGold = false
        if M._goldGui and M._goldGui.Gui and M._goldGui.Gui.Parent then
            pcall(function() M._goldGui.Gui:Destroy() end)
        end
        M._goldGui = nil
    end

    function M.ExposeConfig()
        return {
            { type="toggle", name="Haruka AutoFarm", current=false, onChange=function(v) if v then M.startAutoFarm() else M.stopAutoFarm() end end },
            { type="toggle", name="Haruka Gold Tracker", current=false, onChange=function(v) if v then M.startGoldTracker() else M.stopGoldTracker() end end }
        }
    end

    STATE.Modules.Haruka = M
end

-- RAYFIELD LOAD (fallback)
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        STATE.Rayfield = Ray
    else
        warn("[G-MON] Rayfield load failed; using fallback UI.")
        local Fallback = {}
        function Fallback:CreateWindow()
            local win = {}
            function win:CreateTab(name)
                local tab = {}
                function tab:CreateLabel() end
                function tab:CreateParagraph() end
                function tab:CreateButton() end
                function tab:CreateToggle() end
                function tab:CreateSlider() end
                function tab:CreateInput() end
                return tab
            end
            function win:CreateNotification() end
            return win
        end
        function Fallback:Notify() end
        STATE.Rayfield = Fallback
    end
end

-- STATUS GUI
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
            lines.car.lbl.Text = "CDT: OFF"
            lines.boat.lbl.Text = "Build A Boat: OFF"
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

-- Anti-Kick (best-effort)
local AntiKick = {}
AntiKick.enabled = false
function AntiKick.tryEnable()
    if AntiKick.enabled then return true end
    SAFE_CALL(function()
        local ok, mt = pcall(function() return getrawmetatable and getrawmetatable(game) end)
        if ok and mt and not AntiKick.enabled then
            local old = mt.__namecall
            pcall(function() setreadonly(mt, false) end)
            local newc = (type(newcclosure) == "function") and newcclosure or function(f) return f end
            mt.__namecall = newc(function(self, ...)
                local method = getnamecallmethod and getnamecallmethod() or ""
                if tostring(self) == tostring(LP) and (method == "Kick" or method == "kick") then
                    return nil
                end
                return old(self, ...)
            end)
            pcall(function() setreadonly(mt, true) end)
            AntiKick.enabled = true
        end
    end)
    return AntiKick.enabled
end
function AntiKick.tryDisable()
    AntiKick.enabled = false
end

-- UI BUILD (no Movement tab; Haruka in Build A Boat)
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
            Tabs.Debug = STATE.Window:CreateTab("Debug")
        else
            local function makeTab()
                return { CreateLabel = function() end, CreateParagraph = function() end, CreateButton = function() end, CreateToggle = function() end, CreateSlider = function() end, CreateInput = function() end }
            end
            Tabs.Info = makeTab(); Tabs.TabBlox = makeTab(); Tabs.TabCar = makeTab(); Tabs.TabBoat = makeTab(); Tabs.Debug = makeTab()
        end
        STATE.Tabs = Tabs

        -- Info
        SAFE_CALL(function()
            Tabs.Info:CreateLabel("G-MON Hub - client-only (private/testing).")
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
                    STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "CDT: Available" or "CDT: N/A")
                    STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Build A Boat: Available" or "Build A Boat: N/A")
                end)
            end })
            Tabs.Info:CreateButton({ Name = "Force Blox", Callback = function() STATE.GAME = "BLOX_FRUIT"; STATE.Status.SetIndicator("bf", true, "Blox: Forced") end })
            Tabs.Info:CreateButton({ Name = "Force CDT", Callback = function() STATE.GAME = "CAR_TYCOON"; STATE.Status.SetIndicator("car", true, "CDT: Forced") end })
            Tabs.Info:CreateButton({ Name = "Force Build A Boat", Callback = function() STATE.GAME = "BUILD_A_BOAT"; STATE.Status.SetIndicator("boat", true, "Build A Boat: Forced") end })
        end)

        -- Blox Tab
        SAFE_CALL(function()
            local t = Tabs.TabBlox
            t:CreateLabel("Blox Fruit Controls")
            t:CreateToggle({ Name = "Auto Farm (Blox)", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Blox.start) else SAFE_CALL(STATE.Modules.Blox.stop) end end })
            t:CreateToggle({ Name = "Fast Attack", CurrentValue = STATE.Modules.Blox.config.fast_attack, Callback = function(v) STATE.Modules.Blox.config.fast_attack = v end })
            t:CreateToggle({ Name = "Long Range Hit", CurrentValue = STATE.Modules.Blox.config.long_range, Callback = function(v) STATE.Modules.Blox.config.long_range = v end })
            t:CreateSlider({ Name = "Range Farming (studs)", Range = {1,50}, Increment = 1, CurrentValue = STATE.Modules.Blox.config.range or 10, Callback = function(v) STATE.Modules.Blox.config.range = v end })
            t:CreateSlider({ Name = "Attack Delay (ms)", Range = {50,1000}, Increment = 25, CurrentValue = math.floor((STATE.Modules.Blox.config.attack_delay or 0.35)*1000), Callback = function(v) STATE.Modules.Blox.config.attack_delay = v/1000 end })
        end)

        -- Car Dealership Tab (CDT)
        SAFE_CALL(function()
            local t = Tabs.TabCar
            t:CreateLabel("Car Dealership Tycoon (CDT) Controls")
            local conf = STATE.Modules.CarDeal.ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then
                    t:CreateToggle({ Name = opt.name, CurrentValue = opt.current or false, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                elseif opt.type == "slider" then
                    t:CreateSlider({ Name = opt.name, Range = {opt.min or 50, opt.max or 1000}, Increment = opt.Increment or 1, CurrentValue = opt.current or 300, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                elseif opt.type == "input" then
                    if t.CreateInput then
                        t:CreateInput({ Name = opt.name, CurrentText = tostring(opt.current or ""), Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                    else
                        t:CreateParagraph({ Title = opt.name, Content = tostring(opt.current or "") })
                        t:CreateButton({ Name = "Set "..opt.name, Callback = function() SAFE_CALL(function() SAFE_CALL(opt.onChange, tostring(opt.current or "")) end) end })
                    end
                end
            end
            t:CreateParagraph({ Title = "Note", Content = "CDT features are here (AutoFarm, AutoSell, Delivery, Upgrades, Popup blocker)." })
        end)

        -- Build A Boat Tab (Haruka separated)
        SAFE_CALL(function()
            local t = Tabs.TabBoat
            t:CreateLabel("Build A Boat - Haruka Features")
            t:CreateParagraph({ Title = "Haruka", Content = "Haruka AutoFarm and Gold Tracker are controlled here (kept separate from CDT)." })
            local harukaConf = STATE.Modules.Haruka.ExposeConfig()
            for _,opt in ipairs(harukaConf) do
                if opt.type == "toggle" then
                    t:CreateToggle({ Name = opt.name, CurrentValue = opt.current or false, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                end
            end
        end)

        -- Debug Tab
        SAFE_CALL(function()
            local t = Tabs.Debug
            t:CreateLabel("Debug / Utility")
            t:CreateButton({ Name = "Force Start Core Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.start); SAFE_CALL(STATE.Modules.CarBase.start) end })
            t:CreateButton({ Name = "Stop Core Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.stop); SAFE_CALL(STATE.Modules.CarBase.stop) end })
            t:CreateToggle({ Name = "Anti-Kick (best-effort)", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(AntiKick.tryEnable) else SAFE_CALL(AntiKick.tryDisable) end end })
            t:CreateButton({ Name = "Enable Anti-AFK", Callback = function() SAFE_CALL(Utils.AntiAFK) end })
        end)
    end)
end

-- Apply Game
local function ApplyGame(gameKey)
    STATE.GAME = gameKey or Utils.FlexibleDetectByAliases()
    SAFE_CALL(function()
        STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
        STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "CDT: Available" or "CDT: N/A")
        STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Build A Boat: Available" or "Build A Boat: N/A")
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

-- MAIN
local Main = {}
function Main.Start()
    SAFE_CALL(function()
        buildUI()
        local det = Utils.FlexibleDetectByAliases()
        STATE.GAME = det
        ApplyGame(STATE.GAME)
        Utils.AntiAFK()
        SAFE_CALL(AntiKick.tryEnable)
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use tabs to control modules (CDT tab contains CDT, Build A Boat has Haruka)", Duration=5}) end
        print("[G-MON] final main started. Detected:", STATE.GAME)
    end)
    return true
end

return Main