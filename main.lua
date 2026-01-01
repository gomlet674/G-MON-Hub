-- G-MON Hub - merged CDT + Haruka version
-- Keeps Blox Fruit module, replaces Car tab with Car Dealership Tycoon (CDT) features,
-- replaces Build A Boat tab with Haruka features. Removed Scripts tab.

-- BOOTSTRAP
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local TextService = game:GetService("TextService")
local LP = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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

-- UTILS & DETECTION (unchanged)
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
    if g == "BUILD_A_BOAT" then return "Haruka" end
    return tostring(g or "Unknown")
end

STATE.Modules.Utils = Utils

-- ===== MODULES (Blox/Built-in kept) =====
-- For brevity, keep Blox module, Car baseline and Boat baseline from prior script unchanged.
-- (BEGIN Blox module)
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
-- (END Blox module)

-- Keep Car baseline module (for generic cars) but we will add a NEW CarDeal module for CDT features
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

    STATE.Modules.CarBase = M
end

-- ===== CAR DEALERSHIP TYCOON (CDT) MODULE (NEW) =====
do
    local CDT = {}
    -- flags & state
    CDT.Auto = false
    CDT.collectables = false
    CDT.open = false
    CDT.fireman = false
    CDT.Customer = false
    CDT.deliver = false
    CDT.deliver2 = false
    CDT.buyer = false
    CDT.annoy = false
    CDT.checkif = nil
    CDT.spawned = false
    CDT.speed = 300 -- default auto-drive speed used in original script
    CDT._tasks = {}

    -- delivery config (stars,min,max) loaded/saved via cdtdelivery.txt
    CDT.stars = 0
    CDT.smaller = 0
    CDT.bigger = 999999999

    -- helper to save/load delivery config
    local function saveDeliveryConfig()
        local s = tostring(CDT.stars.." "..CDT.smaller.." "..CDT.bigger)
        pcall(function() writefile("cdtdelivery.txt", s) end)
    end
    local function loadDeliveryConfig()
        pcall(function()
            if isfile and isfile("cdtdelivery.txt") then
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

    -- small helper: find player's tycoon plot (from original)
    local function findPlayerPlot()
        for _,v in pairs(Workspace.Tycoons:GetDescendants()) do
            if v.Name == "Owner" and v.ClassName == "StringValue" and (string.find(v.Parent.Name,"Plot") or string.find(v.Parent.Name,"Slot")) and v.Value == LP.Name then
                return v.Parent
            end
        end
        return nil
    end

    -- Auto Farm (drive back/forth) simplified from original Auto Farm code
    function CDT.startAutoFarm()
        if CDT.Auto then return end
        CDT.Auto = true
        CDT._tasks.auto = task.spawn(function()
            SAFE_CALL(function()
                -- create "justapart" ground part if absent
                if not Workspace:FindFirstChild("justapart") then
                    local new = Instance.new("Part",Workspace)
                    new.Name = "justapart"
                    new.Size = Vector3.new(10000,20,10000)
                    new.Anchored = true
                    new.Position = LP.Character.HumanoidRootPart.Position + Vector3.new(0,1000,0)
                end
                while CDT.Auto do
                    task.wait()
                    local chr = LP.Character
                    if not chr or not chr:FindFirstChild("Humanoid") or not chr:FindFirstChild("HumanoidRootPart") then continue end
                    if not chr.Humanoid.SeatPart then
                        -- nothing to do until in vehicle
                        continue
                    end
                    local car = chr.Humanoid.SeatPart.Parent.Parent
                    if not car or not car.PrimaryPart then
                        continue
                    end

                    -- position to far point and tween to opposite like original
                    pcall(function()
                        car:PivotTo(Workspace:FindFirstChild("justapart").CFrame * CFrame.new(0,10,1000))
                    end)
                    local pos = Workspace:FindFirstChild("justapart").CFrame * CFrame.new(0,10,-1000)
                    local dist = (car.PrimaryPart.Position - pos.Position).magnitude
                    local speed = CDT.speed or 300
                    local TweenInfoToUse = TweenInfo.new(dist/speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, true, 0)
                    local TweenValue = Instance.new("CFrameValue")
                    TweenValue.Value = car.WorldPivot
                    TweenValue.Changed:Connect(function()
                        if car.PrimaryPart then
                            car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
                            pcall(function() car:PivotTo(TweenValue.Value) end)
                        end
                    end)
                    local OnTween = TweenService:Create(TweenValue, TweenInfoToUse, {Value = pos})
                    OnTween:Play()
                    OnTween.Completed:Wait()
                    if car.PrimaryPart then
                        car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
                    end
                end
            end)
        end)
    end

    function CDT.stopAutoFarm()
        CDT.Auto = false
        if CDT._tasks.auto then
            pcall(function() task.cancel(CDT._tasks.auto) end)
            CDT._tasks.auto = nil
        end
    end

    -- Auto Collectibles (drives to collectibles)
    function CDT.startCollectibles()
        if CDT.collectables then return end
        CDT.collectables = true
        CDT._tasks.collect = task.spawn(function()
            while CDT.collectables do
                task.wait()
                local chr = LP.Character
                if not chr or not chr:FindFirstChild("Humanoid") or not chr:FindFirstChild("HumanoidRootPart") then continue end
                if not chr.Humanoid.SeatPart then continue end
                local car = chr.Humanoid.SeatPart.Parent.Parent
                for _,v in pairs(Workspace.Collectibles:GetDescendants()) do
                    if v:IsA("Model") and v.Parent ~= nil and v.Parent.Parent == Workspace.Collectibles and v.PrimaryPart and v:GetChildren()[2] and v:GetChildren()[2]:FindFirstChild("Part") and v:GetChildren()[2]:FindFirstChildOfClass("BillboardGui") and v:GetChildren()[2]:FindFirstChildOfClass("BillboardGui").Enabled then
                        pcall(function() car:PivotTo(v.PrimaryPart.CFrame) end)
                        break
                    end
                end
            end
        end)
    end

    function CDT.stopCollectibles()
        CDT.collectables = false
        if CDT._tasks.collect then pcall(function() task.cancel(CDT._tasks.collect) end); CDT._tasks.collect = nil end
    end

    -- Auto Open Vehicle Kit (invoke remote)
    function CDT.startOpenKit()
        if CDT.open then return end
        CDT.open = true
        CDT._tasks.open = task.spawn(function()
            while CDT.open do
                task.wait()
                pcall(function()
                    local svc = ReplicatedStorage:FindFirstChild("Remotes")
                    if svc and svc:FindFirstChild("Services") and svc.Services:FindFirstChild("CarKitEventServiceRemotes") and svc.Services.CarKitEventServiceRemotes:FindFirstChild("ClaimFreePack") then
                        svc.Services.CarKitEventServiceRemotes.ClaimFreePack:InvokeServer()
                    end
                end)
            end
        end)
    end

    function CDT.stopOpenKit()
        CDT.open = false
        if CDT._tasks.open then pcall(function() task.cancel(CDT._tasks.open) end); CDT._tasks.open = nil end
    end
    
    -- Auto Extinguish Fire (uses TaskController ActionGameDataReplication remote like original)
    function CDT.startExtinguishFire()
        if CDT.fireman then return end
        CDT.fireman = true
        CDT._tasks.fire = task.spawn(function()
            while CDT.fireman do
                SAFE_CALL(function()
                    workspace.Gravity = 196
                    if not LP.Backpack:FindFirstChildOfClass("Tool") and not LP.Character:FindFirstChildOfClass("Tool") then
                        local rem = ReplicatedStorage:FindFirstChild("Remotes")
                        if rem and rem:FindFirstChild("Switch") then
                            pcall(function() rem.Switch:FireServer("FireDealership") end)
                        end
                        wait(10)
                    elseif LP.Backpack:FindFirstChildOfClass("Tool") then
                        pcall(function() LP.Character.Humanoid:EquipTool(LP.Backpack:FindFirstChildOfClass("Tool")) end)
                        wait(1)
                    elseif LP.Character:FindFirstChildOfClass("Tool") then
                        if LP.PlayerGui:FindFirstChild("FireGuide") then
                            local test = nil
                            for _,v in pairs(workspace:GetDescendants()) do
                                if v.Name == "FirePart" then test = v; pcall(function() LP.Character.HumanoidRootPart.CFrame = v.CFrame end) end
                            end
                            if test == nil then
                                pcall(function() LP.Character.HumanoidRootPart.CFrame = LP.PlayerGui.FireGuide.Adornee.CFrame end)
                            else
                                pcall(function()
                                    for _,vv in pairs(test.Parent:GetDescendants()) do
                                        if (vv.ClassName == "Part" and vv.CanCollide == true) or (vv.ClassName == "MeshPart" and vv.CanCollide == true) then
                                            vv.CanCollide = false
                                        end
                                    end
                                    workspace.Gravity = 0
                                    repeat
                                        task.wait()
                                        ReplicatedStorage.Remotes.TaskController.ActionGameDataReplication:FireServer("TryInteractWithItem", {["GameName"] = "FirefighterGame", ["Action"] = "UpdatePlayerToolState", ["Data"] = {["IsActive"] = true, ["ToolName"] = "Extinguisher"}})
                                        LP.Character.HumanoidRootPart.CFrame = test.CFrame * CFrame.new(0,10,0)
                                        LP.Character.HumanoidRootPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(-90),0,0)
                                    until not LP.PlayerGui:FindFirstChild("FireGuide")
                                    LP.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                                    wait(5)
                                    ReplicatedStorage.Remotes.TaskController.ActionGameDataReplication:FireServer("TryInteractWithItem", {["GameName"] = "FirefighterGame", ["Action"] = "TryToCollectReward", ["Data"] = {}})
                                end)
                            end
                        end
                    end
                end)
                wait(0.5)
            end
        end)
    end

    function CDT.stopExtinguishFire()
        CDT.fireman = false
        workspace.Gravity = 196
        if CDT._tasks.fire then pcall(function() task.cancel(CDT._tasks.fire) end); CDT._tasks.fire = nil end
    end

    -- Auto Sell Cars (Dealership flow from original)
    function CDT.startAutoSellCars()
        if CDT.Customer then return end
        CDT.Customer = true
        CDT._tasks.sell = task.spawn(function()
            while CDT.Customer do
                task.wait()
                SAFE_CALL(function()
                    local function plot()
                        return findPlayerPlot()
                    end
                    local tycoon = plot()
                    if not tycoon then return end
                    local customer = nil
                    for _,v in pairs(tycoon.Dealership:GetChildren()) do
                        if v.ClassName == "Model" and v.PrimaryPart ~= nil and v.PrimaryPart.Name == "HumanoidRootPart" then
                            customer = v
                            break
                        end
                    end
                    if not customer then return end
                    wait(5)
                    local text = customer:GetAttribute("OrderSpecBudget"):split(";")
                    local num = tonumber(text[2]) or 99999999
                    local guis = LP.PlayerGui
                    local menu = guis.Menu
                    if not menu then return end
                    local bestChoice = nil
                    -- scan menu for price values
                    for _,v in pairs(menu.Inventory.CarShop.Frame.Frame:GetDescendants()) do
                        if v.Name == "PriceValue" and typeof(v.Value) == "string" then
                            local okstr = string.gsub(v.Value, ",", ""):split("$")[2]
                            local priceNum = tonumber(okstr)
                            if priceNum and priceNum > tonumber(text[1]) and priceNum < tonumber(text[2]) then
                                if not bestChoice or priceNum < bestChoice.price then
                                    bestChoice = { node = v, price = priceNum }
                                end
                            end
                        end
                    end
                    if not bestChoice then return end
                    -- reconstruct name similarly to original: take chars until non-digit
                    local nameStr = bestChoice.node.Parent.Name
                    local buildName = ""
                    for i=1,#nameStr do
                        local ch = nameStr:sub(i,i)
                        if tonumber(ch) then break end
                        buildName = buildName..ch
                    end
                    -- accept order
                    ReplicatedStorage.Remotes.DealershipCustomerController.NPCHandler:FireServer({["Action"] = "AcceptOrder", ["OrderId"] = customer:GetAttribute("OrderId")})
                    wait()
                    ReplicatedStorage.Remotes.DealershipCustomerController.NPCHandler:FireServer({["OrderId"] = customer:GetAttribute("OrderId"), ["Action"] = "CompleteOrder", ["Specs"] = {["Car"] = buildName .. nameStr:match("%d+$"), ["Color"] = customer:GetAttribute("OrderSpecColor"), ["Rims"] = customer:GetAttribute("OrderSpecRims"), ["Springs"] = customer:GetAttribute("OrderSpecSprings"), ["RimColor"] = customer:GetAttribute("OrderSpecRimColor")}})
                    wait()
                    ReplicatedStorage.Remotes.DealershipCustomerController.NPCHandler:FireServer({["Action"] = "CollectReward", ["OrderId"] = customer:GetAttribute("OrderId")})
                    repeat wait() until not customer.Parent or not CDT.Customer
                    wait(5)
                end)
            end
        end)
    end

    function CDT.stopAutoSellCars()
        CDT.Customer = false
        if CDT._tasks.sell then pcall(function() task.cancel(CDT._tasks.sell) end); CDT._tasks.sell = nil end
    end

    -- Auto Delivery (complex flow from original) - simplified but keeps remote calls
    function CDT.startAutoDelivery()
        if CDT.deliver then return end
        CDT.deliver = true
        CDT._tasks.deliver = task.spawn(function()
            local resetcharactervalue1 = 0
            local devpart2 = 1
            -- background watchers (from original)
            task.spawn(function()
                while CDT.deliver do
                    task.wait()
                    pcall(function()
                        if LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character.Humanoid.Sit == false then
                            wait(5)
                            CDT.spawned = false
                        end
                    end)
                end
            end)
            task.spawn(function()
                while CDT.deliver do
                    task.wait()
                    if devpart2 ~= nil then
                        resetcharactervalue1 = 0
                    else
                        if resetcharactervalue1 >= 20 then
                            resetcharactervalue1 = 0
                            pcall(function() LP.Character:BreakJoints() end)
                            wait(1)
                        end
                    end
                end
            end)

            while CDT.deliver do
                task.wait()
                SAFE_CALL(function()
                    if LP.Character.Humanoid.SeatPart ~= nil then
                        task.wait(1)
                        devpart2 = nil
                        for _,v in pairs(Workspace.ActionTasksGames.Jobs:GetDescendants()) do
                            if v.Name == "DeliveryPart" and v.Transparency ~= 1 then
                                devpart2 = v
                                workspace.Gravity = 0
                                CDT.spawned = false
                                pcall(function() LP.Character.Humanoid.SeatPart.Parent.Parent:PivotTo(v.CFrame) end)
                                pcall(function() LP.Character.Humanoid.SeatPart.Parent.Parent:PivotTo(v.CFrame*CFrame.new(-30,20,-10)) end)
                                pcall(function() LP.Character.Humanoid.SeatPart.Parent.Parent:PivotTo(v.CFrame*CFrame.Angles(0,math.rad(90),0)) end)
                                for _,vv in pairs(LP.Character.Humanoid.SeatPart.Parent.Parent:GetChildren()) do
                                    if vv.ClassName == "Model" and vv:GetAttribute("StockTurbo") then
                                        for _,b in pairs(Workspace.ActionTasksGames.Jobs:GetChildren()) do
                                            if b.ClassName == "Model" and b:GetAttribute("JobId") then
                                                ReplicatedStorage.Remotes.DealershipCustomerController.JobRemoteHandler:FireServer({["Action"] = "TryToCompleteJob", ["JobId"] = b:GetAttribute("JobId")})
                                                ReplicatedStorage.Remotes.DealershipCustomerController.JobRemoteHandler:FireServer({["JobId"] = LP.PlayerGui.MissionRewardStars:GetAttribute("JobId"), ["Action"] = "CollectReward"})
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if devpart2 == nil then
                        resetcharactervalue1 = resetcharactervalue1 + 1
                    end
                    if LP.Character.Humanoid.Sit == false and CDT.spawned ~= true then
                        ReplicatedStorage.Remotes.DealershipCustomerController.JobRemoteHandler:FireServer(_G.remotetable)
                        workspace.Gravity = 196
                        CDT.spawned = true
                        wait(0.1)
                    end
                end)
            end
        end)
    end

    function CDT.stopAutoDelivery()
        CDT.deliver = false
        if CDT._tasks.deliver then pcall(function() task.cancel(CDT._tasks.deliver) end); CDT._tasks.deliver = nil end
        workspace.Gravity = 196
    end

    -- Auto Upgrade Plot (buy items)
    function CDT.startAutoUpgrade()
        if CDT.buyer then return end
        CDT.buyer = true
        CDT._tasks.buyer = task.spawn(function()
            while CDT.buyer do
                task.wait()
                SAFE_CALL(function()
                    local function plot() return findPlayerPlot() end
                    local tyc = plot()
                    if not tyc then return end
                    for _,v in pairs(tyc.Dealership.Purchases:GetChildren()) do
                        if CDT.buyer == true and v.TycoonButton and v.TycoonButton.Button and v.TycoonButton.Button.Transparency == 0 then
                            ReplicatedStorage.Remotes.Build:FireServer("BuyItem", v.Name)
                            wait(0.3)
                        end
                    end
                end)
            end
        end)
    end

    function CDT.stopAutoUpgrade()
        CDT.buyer = false
        if CDT._tasks.buyer then pcall(function() task.cancel(CDT._tasks.buyer) end); CDT._tasks.buyer = nil end
    end

    -- Annoying popup disabler
    local popupConn = nil
    function CDT.enablePopupBlock()
        if CDT.annoy then return end
        CDT.annoy = true
        popupConn = LP.PlayerGui.ChildAdded:Connect(function(ok)
            if ok.Name == "Popup2" then
                pcall(function() ok:Destroy() end)
            end
        end)
    end
    function CDT.disablePopupBlock()
        CDT.annoy = false
        if popupConn then pcall(function() popupConn:Disconnect() end); popupConn = nil end
    end

    -- Delivery options tab UI values (we'll expose in UI)
    function CDT.setDeliveryConfig(stars, mini, maxi)
        CDT.stars = tonumber(stars) or CDT.stars
        CDT.smaller = tonumber(mini) or CDT.smaller
        CDT.bigger = tonumber(maxi) or CDT.bigger
        saveDeliveryConfig()
    end

    Tabs.CDT:CreateButton({
    Name = "Buy Car",
    CurrentValue = false,
    Callback = function(v)
        STATE.Modules.CarDeal.AutoBuy = v
        if v then
            STATE.Modules.CarDeal:AutoBuyLoop()
        end
    end
})
    
    -- load cdtdelivery.txt if exists (done earlier)
    loadDeliveryConfig()

    -- Expose module API
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
            { type="input", name="Delivery: Min Stars", current=CDT.stars, onChange=function(v) CDT.stars = tonumber(v) or CDT.stars; saveDeliveryConfig() end },
            { type="input", name="Delivery: Min Reward", current=CDT.smaller, onChange=function(v) CDT.smaller = tonumber(v) or CDT.smaller; saveDeliveryConfig() end },
            { type="input", name="Delivery: Max Reward", current=CDT.bigger, onChange=function(v) CDT.bigger = tonumber(v) or CDT.bigger; saveDeliveryConfig() end }
            type="button",
    name="Buy Car",
    onClick=function()
        if CDT and CDT.AutoBuyLoop then
            CDT.AutoBuy = true
            CDT:AutoBuyLoop()
        end
    end
        }
    end

    STATE.Modules.CarDeal = CDT
end

-- ===== HARUKA module (kept) =====
-- (the Haruka module that was already included in your script)
-- I will reference it in STATE.Modules.Haruka (kept unchanged from user's file)
-- For brevity, copy/paste the Haruka block from your supplied file (unchanged).
-- (BEGIN Haruka module)
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
            { type="toggle", name="Auto Farm (Build A Boat)", current=false,
  onChange=function(v)
      STATE.Flags.BoatAuto = v
      if v then M.startAutoFarm() else M.stopAutoFarm() 
     end
  end
   }
            
    STATE.Modules.Haruka = M
end
-- (END Haruka module)

-- RAYFIELD LOAD (safe fallback)
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

-- STATUS GUI (unchanged, minimal)
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
            lines.boat.lbl.Text = "Haruka: OFF"
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

-- UI BUILDING: create tabs per game. Removed Scripts tab; Boat tab used for Haruka.
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
            Tabs.TabBoat = STATE.Window:CreateTab("Haruka") -- Haruka UI here
            Tabs.Move = STATE.Window:CreateTab("Movement")
            Tabs.Debug = STATE.Window:CreateTab("Debug")
        else
            local function makeTab()
                return { CreateLabel = function() end, CreateParagraph = function() end, CreateButton = function() end, CreateToggle = function() end, CreateSlider = function() end, CreateInput = function() end }
            end
            Tabs.Info = makeTab(); Tabs.TabBlox = makeTab(); Tabs.TabCar = makeTab(); Tabs.TabBoat = makeTab(); Tabs.Move = makeTab(); Tabs.Debug = makeTab()
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
            Tabs.Info:CreateButton({ Name = "Force Blox", Callback = function() STATE.GAME = "BLOX_FRUIT"; STATE.Status.SetIndicator("bf", true, "Blox: Forced") end })
            Tabs.Info:CreateButton({ Name = "Force Car (CDT)", Callback = function() STATE.GAME = "CAR_TYCOON"; STATE.Status.SetIndicator("car", true, "Car: Forced") end })
            Tabs.Info:CreateButton({ Name = "Force Haruka", Callback = function() STATE.GAME = "BUILD_A_BOAT"; STATE.Status.SetIndicator("boat", true, "Haruka: Forced") end })
            Tabs.Info:CreateParagraph({ Title = "Note", Content = "Each game has its own tab. Use Force/Detect to update status. Features are separated to avoid conflicts." })
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

        -- CAR DEALERSHIP tab (CDT)
        SAFE_CALL(function()
            local t = Tabs.TabCar
            t:CreateLabel("Car Dealership Tycoon (CDT) Controls")

            -- create toggles & controls by reading ExposeConfig from module
            local conf = STATE.Modules.CarDeal.ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then
                    t:CreateToggle({ Name = opt.name, CurrentValue = opt.current or false, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                elseif opt.type == "slider" then
                    t:CreateSlider({ Name = opt.name, Range = {opt.min or opt.Range[1], opt.max or opt.Range[2]}, Increment = opt.Increment or 1, CurrentValue = opt.current, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                elseif opt.type == "input" then
                    -- some Rayfield libs use CreateInput or CreateBox; use CreateButton fallback
                    if t.CreateInput then
                        t:CreateInput({ Name = opt.name, CurrentText = tostring(opt.current or ""), Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                    else
                        t:CreateParagraph({ Title = opt.name, Content = tostring(opt.current or "") })
                        t:CreateButton({ Name = "Set "..opt.name, Callback = function() SAFE_CALL(function() local value = tostring(opt.current or ""); SAFE_CALL(opt.onChange, value) end) end })
                    end
                end
            end

            t:CreateParagraph({ Title = "Note", Content = "Use Delivery options to set minimum stars / rewards and save to cdtdelivery.txt via executor filesystem (if supported)." })
        end)

        -- HARUKA tab (Build A Boat replaced)
        SAFE_CALL(function()
            local t = Tabs.TabBoat
            t:CreateLabel("Features (Build A Boat slot)")
            local conf = STATE.Modules.Haruka.ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then
                    t:CreateToggle({ Name = opt.name, CurrentValue = opt.current or false, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                end
            end
            t:CreateParagraph({ Title = "Note", Content = "Haruka AutoFarm & Gold Tracker enabled here." })
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
            t:CreateButton({ Name = "Force Start All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.start); SAFE_CALL(STATE.Modules.CarBase.start); SAFE_CALL(STATE.Modules.Haruka.startAutoFarm) end })
            t:CreateButton({ Name = "Stop All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.stop); SAFE_CALL(STATE.Modules.CarBase.stop); SAFE_CALL(STATE.Modules.Haruka.stopAutoFarm) end })
        end)
    end)
end

-- Apply Game (set status indicators and notify)
local function ApplyGame(gameKey)
    STATE.GAME = gameKey or Utils.FlexibleDetectByAliases()
    SAFE_CALL(function()
        STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
        STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "CDT: Available" or "CDT: N/A")
        STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Haruka: Available" or "Haruka: N/A")
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

-- INITIALIZATION (lazy) - do not auto-start modules, user toggles them
local Main = {}

function Main.Start()
    SAFE_CALL(function()
        buildUI()
        local det = Utils.FlexibleDetectByAliases()
        STATE.GAME = det
        ApplyGame(STATE.GAME)
        Utils.AntiAFK()
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use tabs to control modules (CarDeal tab contains CDT features, Haruka tab has Haruka)", Duration=5}) end
        print("[G-MON] merged main started. Detected:", STATE.GAME)
    end)
    return true
end
-- ===============================
-- GMON SAVE / LOAD SETTINGS
-- ===============================
local SETTINGS_FILE = "gmon_settings.json"

local function collectSettings()
    return {
        Blox = STATE.Flags.Blox or false,
        CDT_AutoFarm = STATE.Modules.CarDeal and STATE.Modules.CarDeal.Auto or false,
        CDT_Delivery = STATE.Modules.CarDeal and STATE.Modules.CarDeal.deliver or false,
        CDT_Sell = STATE.Modules.CarDeal and STATE.Modules.CarDeal.Customer or false,
        Boat_AutoFarm = STATE.Flags.BoatAuto or false,
        FullBright = STATE.Flags.FullBright or false
    }
end

local function applySettings(data)
    if not data then return end
    SAFE_CALL(function()
        if data.Blox then STATE.Modules.Blox.start() end
        if data.CDT_AutoFarm then STATE.Modules.CarDeal.startAutoFarm() end
        if data.CDT_Delivery then STATE.Modules.CarDeal.startAutoDelivery() end
        if data.CDT_Sell then STATE.Modules.CarDeal.startAutoSellCars() end
        if data.Boat_AutoFarm then STATE.Modules.Haruka.startAutoFarm() end
        if data.FullBright then _G.GMON_FullBright(true) end
    end)
end

local function saveSettings()
    if writefile then
        writefile(SETTINGS_FILE, game:GetService("HttpService"):JSONEncode(collectSettings()))
    end
end

local function loadSettings()
    if readfile and isfile and isfile(SETTINGS_FILE) then
        local data = game:GetService("HttpService"):JSONDecode(readfile(SETTINGS_FILE))
        applySettings(data)
    end
        end
        
return Main
