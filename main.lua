-- G-MON Hub - FINAL (CDT + BuyCar + Haruka minimal + NightVision + Save/Load)
-- Integrates original modules (Blox kept, CarBase kept, CDT kept) with BuyCar UI and Settings tab.
-- Robust: Rayfield if available, fallback ScreenGui. Error popup on major errors.

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
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

-- compatibility helpers (many executors)
local has_writefile = (type(writefile) == "function")
local has_isfile = (type(isfile) == "function")
local has_readfile = (type(readfile) == "function")
local has_setclipboard = (type(setclipboard) == "function")

-- SAFE helpers
local function SAFE_CALL(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[G-MON] SAFE_CALL error:", res)
        -- show UI error popup
        pcall(function() 
            if _G.GMonShowError then _G.GMonShowError(tostring(res)) end
        end)
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
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    LastAction = "Idle",
    SettingsFile = "gmon_cdt_settings.json",
    SavedMemory = nil
}

-- UTILS
local Utils = {}
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
        BLOX_FRUIT = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","Quests","NPCQuests"},
        CAR_TYCOON = {"Cars","VehicleFolder","Vehicles","Dealership","Garage","CarShop","CarStages","CarsFolder"},
        BUILD_A_BOAT = {"BoatStages","Stages","NormalStages","StageFolder","BoatStage","Chest","Treasure"}
    }
    for key, list in pairs(aliasMap) do
        for _, name in ipairs(list) do
            if Workspace:FindFirstChild(name) then return key end
        end
    end
    -- fallback to ALL
    return "ALL"
end
function Utils.ShortLabelForGame(g)
    if g == "BLOX_FRUIT" then return "Blox" end
    if g == "CAR_TYCOON" then return "CDT" end
    if g == "BUILD_A_BOAT" then return "Haruka" end
    return tostring(g or "All")
end

STATE.Modules.Utils = Utils

-- ERROR POPUP util (global so SAFE_CALL can call)
do
    local function ShowErrorUI(msg)
        -- simple ScreenGui popup with copy button
        pcall(function()
            local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui",5)
            if not pg then return end
            local gui = Instance.new("ScreenGui", pg)
            gui.Name = "GMonErrorPopup"
            gui.ResetOnSpawn = false
            local frame = Instance.new("Frame", gui)
            frame.Size = UDim2.new(0,420,0,160)
            frame.Position = UDim2.new(0.5, -210, 0.1, 0)
            frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
            frame.BorderSizePixel = 0
            local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
            local title = Instance.new("TextLabel", frame)
            title.Size = UDim2.new(1, -20, 0, 30)
            title.Position = UDim2.new(0,10,0,10)
            title.BackgroundTransparency = 1
            title.Text = "G-MON ERROR"
            title.TextColor3 = Color3.new(1,0.2,0.2)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 18
            title.TextXAlignment = Enum.TextXAlignment.Left
            local body = Instance.new("TextBox", frame)
            body.Size = UDim2.new(1, -20, 0, 80)
            body.Position = UDim2.new(0,10,0,44)
            body.TextWrapped = true
            body.ClearTextOnFocus = false
            body.Text = msg or "Unknown error"
            body.TextColor3 = Color3.fromRGB(230,230,230)
            body.Font = Enum.Font.Gotham
            body.TextSize = 14
            body.BackgroundTransparency = 0.15
            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(0,120,0,30)
            btn.Position = UDim2.new(1, -130, 1, -40)
            btn.Text = "Copy & Close"
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.MouseButton1Click:Connect(function()
                pcall(function()
                    if has_setclipboard then setclipboard(body.Text) end
                    gui:Destroy()
                end)
            end)
        end)
    end
    _G.GMonShowError = ShowErrorUI
end

-- ========== MODULES (Blox, CarBase, CarDeal, Haruka) ==========
-- For fidelity to user's request: keep logic from user's merged main.lua modules.
-- (Due to length and to preserve behavior exactly, code below is adapted from the provided large main.lua,
--  preserving functions and flows; minimal adjustments for safety/pcall & UI integration.)

-- === Blox module (kept) ===
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
                local char = Utils.SafeChar and Utils.SafeChar() or (LP and LP.Character)
                if not char then return end
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
        STATE.Flags = STATE.Flags or {}
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

-- === CarBase module (kept) ===
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

-- === Car Dealership Tycoon (CDT) module (kept from original, with buy car integration later) ===
do
    local CDT = {}
    -- copy original flags/state & functions (kept behavior)
    CDT.Auto = false; CDT.collectables = false; CDT.open = false; CDT.fireman = false
    CDT.Customer = false; CDT.deliver = false; CDT.deliver2 = false; CDT.buyer = false
    CDT.annoy = false; CDT.checkif = nil; CDT.spawned = false; CDT.speed = 300
    CDT._tasks = {}
    CDT.stars = 0; CDT.smaller = 0; CDT.bigger = 999999999

    -- save/load delivery config
    local function saveDeliveryConfig()
        local s = tostring(CDT.stars.." "..CDT.smaller.." "..CDT.bigger.." "..CDT.speed)
        if has_writefile then
            pcall(function() writefile(STATE.SettingsFile, s) end)
        else
            STATE.SavedMemory = s
        end
    end
    local function loadDeliveryConfig()
        local content = nil
        if has_isfile and has_readfile and isfile(STATE.SettingsFile) then
            pcall(function() content = readfile(STATE.SettingsFile) end)
        else
            content = STATE.SavedMemory
        end
        if content and #content>0 then
            local parts = {}
            for p in string.gmatch(content, "%S+") do table.insert(parts, p) end
            CDT.stars = tonumber(parts[1]) or CDT.stars
            CDT.smaller = tonumber(parts[2]) or CDT.smaller
            CDT.bigger = tonumber(parts[3]) or CDT.bigger
            CDT.speed = tonumber(parts[4]) or CDT.speed
        end
    end
    loadDeliveryConfig()

    local function findPlayerPlot()
        for _,v in pairs(Workspace.Tycoons:GetDescendants()) do
            if v.Name == "Owner" and v.ClassName == "StringValue" and (string.find(v.Parent.Name,"Plot") or string.find(v.Parent.Name,"Slot")) and v.Value == LP.Name then
                return v.Parent
            end
        end
        return nil
    end

    -- startAutoFarm, stopAutoFarm, startCollectibles, stopCollectibles, startOpenKit, stopOpenKit,
    -- startExtinguishFire, stopExtinguishFire, startAutoSellCars, stopAutoSellCars, startAutoDelivery,
    -- stopAutoDelivery, startAutoUpgrade, stopAutoUpgrade, popup block functions
    -- (We reuse logic from earlier merged script - kept intact, only minor pcall wrappers)

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
                    pcall(function() new.Position = LP.Character.HumanoidRootPart.Position + Vector3.new(0,1000,0) end)
                end
                while CDT.Auto do
                    task.wait()
                    local chr = LP.Character
                    if not chr or not chr:FindFirstChild("Humanoid") or not chr:FindFirstChild("HumanoidRootPart") then continue end
                    if not chr.Humanoid.SeatPart then continue end
                    local car = chr.Humanoid.SeatPart.Parent
                    if not car or not car.PrimaryPart then continue end
                    pcall(function()
                        car:PivotTo(Workspace:FindFirstChild("justapart").CFrame * CFrame.new(0,10,1000))
                    end)
                    local pos = Workspace:FindFirstChild("justapart").CFrame * CFrame.new(0,10,-1000)
                    local dist = (car.PrimaryPart.Position - pos.Position).magnitude
                    local speed = CDT.speed or 300
                    if car.PrimaryPart then
                        car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * speed
                    end
                    task.wait(1)
                end
            end)
        end)
    end
    function CDT.stopAutoFarm()
        CDT.Auto = false
        if CDT._tasks.auto then pcall(function() task.cancel(CDT._tasks.auto) end); CDT._tasks.auto = nil end
    end

    function CDT.startCollectibles()
        if CDT.collectables then return end
        CDT.collectables = true
        CDT._tasks.collect = task.spawn(function()
            while CDT.collectables do
                task.wait()
                local chr = LP.Character
                if not chr or not chr:FindFirstChild("Humanoid") or not chr:FindFirstChild("HumanoidRootPart") then continue end
                if not chr.Humanoid.SeatPart then continue end
                local car = chr.Humanoid.SeatPart.Parent
                if Workspace:FindFirstChild("Collectibles") then
                    for _,v in pairs(Workspace.Collectibles:GetDescendants()) do
                        if v:IsA("Model") and v.PrimaryPart then
                            pcall(function() car:PivotTo(v.PrimaryPart.CFrame) end)
                            break
                        end
                    end
                end
            end
        end)
    end
    function CDT.stopCollectibles()
        CDT.collectables = false
        if CDT._tasks.collect then pcall(function() task.cancel(CDT._tasks.collect) end); CDT._tasks.collect = nil end
    end

    function CDT.startOpenKit()
        if CDT.open then return end
        CDT.open = true
        CDT._tasks.open = task.spawn(function()
            while CDT.open do
                task.wait()
                SAFE_CALL(function()
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
                        task.wait(10)
                    elseif LP.Backpack:FindFirstChildOfClass("Tool") then
                        pcall(function() LP.Character.Humanoid:EquipTool(LP.Backpack:FindFirstChildOfClass("Tool")) end)
                        task.wait(1)
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
                                    task.wait(5)
                                    ReplicatedStorage.Remotes.TaskController.ActionGameDataReplication:FireServer("TryInteractWithItem", {["GameName"] = "FirefighterGame", ["Action"] = "TryToCollectReward", ["Data"] = {}})
                                end)
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end
    function CDT.stopExtinguishFire()
        CDT.fireman = false
        workspace.Gravity = 196
        if CDT._tasks.fire then pcall(function() task.cancel(CDT._tasks.fire) end); CDT._tasks.fire = nil end
    end

    function CDT.startAutoSellCars()
        if CDT.Customer then return end
        CDT.Customer = true
        CDT._tasks.sell = task.spawn(function()
            while CDT.Customer do
                task.wait()
                SAFE_CALL(function()
                    local tycoon = findPlayerPlot()
                    if not tycoon then return end
                    local customer = nil
                    for _,v in pairs(tycoon.Dealership:GetChildren()) do
                        if v.ClassName == "Model" and v.PrimaryPart ~= nil and v.PrimaryPart.Name == "HumanoidRootPart" then
                            customer = v
                            break
                        end
                    end
                    if not customer then return end
                    task.wait(5)
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
                    -- reconstruct name similarly to original
                    local nameStr = bestChoice.node.Parent.Name
                    local buildName = ""
                    for i=1,#nameStr do
                        local ch = nameStr:sub(i,i)
                        if tonumber(ch) then break end
                        buildName = buildName..ch
                    end
                    -- accept order (using remotes)
                    local rem = ReplicatedStorage:FindFirstChild("Remotes")
                    if rem and rem:FindFirstChild("DealershipCustomerController") and rem.DealershipCustomerController:FindFirstChild("NPCHandler") then
                        local handler = rem.DealershipCustomerController.NPCHandler
                        pcall(function()
                            handler:FireServer({["Action"] = "AcceptOrder", ["OrderId"] = customer:GetAttribute("OrderId")})
                            task.wait()
                            handler:FireServer({["OrderId"] = customer:GetAttribute("OrderId"), ["Action"] = "CompleteOrder", ["Specs"] = {["Car"] = buildName .. nameStr:match("%d+$"), ["Color"] = customer:GetAttribute("OrderSpecColor"), ["Rims"] = customer:GetAttribute("OrderSpecRims"), ["Springs"] = customer:GetAttribute("OrderSpecSprings"), ["RimColor"] = customer:GetAttribute("OrderSpecRimColor")}})
                            task.wait()
                            handler:FireServer({["Action"] = "CollectReward", ["OrderId"] = customer:GetAttribute("OrderId")})
                        end)
                    end
                    repeat task.wait() until not customer.Parent or not CDT.Customer
                    task.wait(5)
                end)
            end
        end)
    end
    function CDT.stopAutoSellCars()
        CDT.Customer = false
        if CDT._tasks.sell then pcall(function() task.cancel(CDT._tasks.sell) end); CDT._tasks.sell = nil end
    end

    function CDT.startAutoDelivery()
        if CDT.deliver then return end
        CDT.deliver = true
        CDT._tasks.deliver = task.spawn(function()
            local resetcharactervalue1 = 0
            local devpart2 = 1
            task.spawn(function()
                while CDT.deliver do
                    task.wait()
                    pcall(function()
                        if LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character.Humanoid.Sit == false then
                            task.wait(5)
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
                            task.wait(1)
                        end
                    end
                end
            end)

            while CDT.deliver do
                task.wait()
                SAFE_CALL(function()
                    if LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character.Humanoid.SeatPart ~= nil then
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
                    if LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character.Humanoid.Sit == false and CDT.spawned ~= true then
                        if ReplicatedStorage and ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("DealershipCustomerController") and ReplicatedStorage.Remotes.DealershipCustomerController:FindFirstChild("JobRemoteHandler") then
                            pcall(function() ReplicatedStorage.Remotes.DealershipCustomerController.JobRemoteHandler:FireServer(_G.remotetable) end)
                        end
                        workspace.Gravity = 196
                        CDT.spawned = true
                        task.wait(0.1)
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

    function CDT.startAutoUpgrade()
        if CDT.buyer then return end
        CDT.buyer = true
        CDT._tasks.buyer = task.spawn(function()
            while CDT.buyer do
                task.wait()
                SAFE_CALL(function()
                    local tyc = findPlayerPlot()
                    if not tyc then return end
                    for _,v in pairs(tyc.Dealership.Purchases:GetChildren()) do
                        if CDT.buyer == true and v.TycoonButton and v.TycoonButton.Button and v.TycoonButton.Button.Transparency == 0 then
                            ReplicatedStorage.Remotes.Build:FireServer("BuyItem", v.Name)
                            task.wait(0.3)
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
            { type="slider", name="AutoDrive Speed (CDT)", min=50, max=1000, current=CDT.speed, onChange=function(v) CDT.speed = v; saveDeliveryConfig() end },
            { type="input", name="Delivery: Min Stars", current=CDT.stars, onChange=function(v) CDT.stars = tonumber(v) or CDT.stars; saveDeliveryConfig() end },
            { type="input", name="Delivery: Min Reward", current=CDT.smaller, onChange=function(v) CDT.smaller = tonumber(v) or CDT.smaller; saveDeliveryConfig() end },
            { type="input", name="Delivery: Max Reward", current=CDT.bigger, onChange=function(v) CDT.bigger = tonumber(v) or CDT.bigger; saveDeliveryConfig() end }
        }
    end

    STATE.Modules.CarDeal = CDT
end

-- === Haruka module (kept but only auto farm exposed) ===
do
    local M = {}
    M.autoRunning = false
    M._autoTask = nil

    local function haruka_auto_loop(character)
        while M.autoRunning do
            if not character or not character.Parent then
                task.wait(1)
                character = game.Players.LocalPlayer.Character
                if not character then continue end
            end
            task.wait(1.24)
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1) continue end
            if not M.autoRunning then break end
            pcall(function() hrp.CFrame = CFrame.new(-135.900,72,623.750) end)
            while hrp and hrp.CFrame and hrp.CFrame.Z < 8600.75 and M.autoRunning do
                for i=1,50 do
                    if not M.autoRunning then break end
                    if hrp then pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0,0,0.3) end) end
                end
                task.wait()
            end
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
        end
    end

    function M.startAutoFarm()
        if M.autoRunning then return end
        M.autoRunning = true
        STATE.Flags = STATE.Flags or {}
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

    function M.ExposeConfig()
        return {
            { type="toggle", name="Haruka AutoFarm", current=false, onChange=function(v) if v then M.startAutoFarm() else M.stopAutoFarm() end end }
        }
    end

    STATE.Modules.Haruka = M
end

-- ===== Night Vision helper =====
local NV = {}
NV.cc = nil
NV.enabled = false
NV.strength = 0.3
function NV.enable()
    if NV.enabled then return end
    NV.enabled = true
    if not NV.cc then
        NV.cc = Lighting:FindFirstChild("GMon_NightVision")
        if not NV.cc then
            NV.cc = Instance.new("ColorCorrectionEffect")
            NV.cc.Name = "GMon_NightVision"
            NV.cc.Parent = Lighting
        end
    end
    NV.cc.Contrast = math.clamp(NV.strength, -1, 1)
    NV.cc.Saturation = math.clamp(NV.strength * 0.5, -1, 2)
    NV.cc.Brightness = math.clamp(NV.strength * 0.8, -0.5, 2)
end
function NV.disable()
    NV.enabled = false
    if NV.cc then
        pcall(function() NV.cc.Contrast = 0; NV.cc.Saturation = 0; NV.cc.Brightness = 0 end)
    end
end
function NV.setStrength(v)
    NV.strength = tonumber(v) or NV.strength
    if NV.enabled then NV.enable() end
end

-- ===== Rayfield loader (pcall) =====
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        STATE.Rayfield = Ray
    else
        warn("[G-MON] Rayfield not available, using UI fallback.")
        STATE.Rayfield = nil
    end
end

-- ===== Car list for BuyCar UI (example list; you can extend) =====
local CarsDB = {
    { Name = "Hyperluxe Balle", Keyword = "hyperluxe", Price = "$37,500,000" },
    { Name = "Hyperluxe SS+", Keyword = "ss", Price = "$35,000,000" },
    { Name = "Hyperluxe Vision GT", Keyword = "vision", Price = "$30,000,000" },
    { Name = "Macchina Vicenza", Keyword = "vicenza", Price = "$22,000,000" }
}

-- ===== UI Build (Rayfield if available else fallback ScreenGui) =====
local function buildUI()
    SAFE_CALL(function()
        local Window
        if STATE.Rayfield and STATE.Rayfield.CreateWindow then
            Window = STATE.Rayfield:CreateWindow({
                Name = "G-MON Hub",
                LoadingTitle = "G-MON Hub",
                LoadingSubtitle = "CDT + Haruka + NV",
                ConfigurationSaving = { Enabled = false }
            })
        end

        STATE.Window = Window
        local Tabs = {}
        if Window then
            Tabs.Info = Window:CreateTab("Info")
            Tabs.Blox = Window:CreateTab("Blox Fruit")
            Tabs.Car = Window:CreateTab("Car Dealership") -- CDT + BuyCar UI
            Tabs.Haruka = Window:CreateTab("Haruka")
            Tabs.NV = Window:CreateTab("Night Vision")
            Tabs.Settings = Window:CreateTab("Settings")
        else
            -- fallback simple table with methods that do nothing to avoid crashes
            local function mk() return { CreateLabel=function() end, CreateParagraph=function() end, CreateButton=function() end, CreateToggle=function() end, CreateSlider=function() end, CreateInput=function() end } end
            Tabs.Info = mk(); Tabs.Blox = mk(); Tabs.Car = mk(); Tabs.Haruka = mk(); Tabs.NV = mk(); Tabs.Settings = mk()
        end
        STATE.Tabs = Tabs

        -- Info tab
        SAFE_CALL(function()
            Tabs.Info:CreateLabel("G-MON Hub - Full CDT integration")
            Tabs.Info:CreateParagraph({ Title = "Detected", Content = Utils.ShortLabelForGame(STATE.GAME) })
            Tabs.Info:CreateParagraph({ Title = "Note", Content = "This client script runs CDT features, Blox options, Haruka AutoFarm, Night Vision, and Save/Load settings." })
        end)

        -- Blox tab
        SAFE_CALL(function()
            local t = Tabs.Blox
            t:CreateLabel("Blox Fruit Controls")
            t:CreateToggle({ Name = "Auto Farm (Blox)", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Blox.start) else SAFE_CALL(STATE.Modules.Blox.stop) end end })
            t:CreateToggle({ Name = "Fast Attack", CurrentValue = STATE.Modules.Blox.config.fast_attack, Callback = function(v) STATE.Modules.Blox.config.fast_attack = v end })
            t:CreateToggle({ Name = "Long Range Hit", CurrentValue = STATE.Modules.Blox.config.long_range, Callback = function(v) STATE.Modules.Blox.config.long_range = v end })
            t:CreateSlider({ Name = "Range Farming (studs)", Range = {1,50}, Increment = 1, CurrentValue = STATE.Modules.Blox.config.range or 10, Callback = function(v) STATE.Modules.Blox.config.range = v end })
            t:CreateSlider({ Name = "Attack Delay (ms)", Range = {50,1000}, Increment = 25, CurrentValue = math.floor((STATE.Modules.Blox.config.attack_delay or 0.35)*1000), Callback = function(v) STATE.Modules.Blox.config.attack_delay = v/1000 end })
        end)

        -- Car Dealership tab (CDT) + BuyCar integrated
        SAFE_CALL(function()
            local t = Tabs.Car
            t:CreateLabel("Car Dealership Tycoon (CDT)")

            -- expose CDT controls
            local conf = STATE.Modules.CarDeal.ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then
                    t:CreateToggle({ Name = opt.name, CurrentValue = opt.current or false, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                elseif opt.type == "slider" then
                    t:CreateSlider({ Name = opt.name, Range = {opt.min or 50, opt.max or 1000}, Increment = opt.Increment or 1, CurrentValue = opt.current, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                elseif opt.type == "input" then
                    if t.CreateInput then
                        t:CreateInput({ Name = opt.name, CurrentText = tostring(opt.current or ""), Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                    else
                        t:CreateParagraph({ Title = opt.name, Content = tostring(opt.current or "") })
                    end
                end
            end

            t:CreateParagraph({ Title = "Buy Car", Content = "Select a car below then press BUY (this simulates clicking the in-game buy button by searching PlayerGui buttons)." })

            -- Create select dropdown (Rayfield) or fallback: create a series of buttons
            if STATE.Rayfield and STATE.Rayfield.CreateWindow and STATE.Rayfield.CreateDropdown then
                -- hypothetical: use Rayfield dropdown if available
                local names = {}
                for _,c in ipairs(CarsDB) do table.insert(names, c.Name) end
                t:CreateParagraph({ Title = "Available Cars", Content = table.concat(names, ", ") })
                -- We'll create button per car instead (Rayfield variations differ). Create per-car buy button:
                for _,car in ipairs(CarsDB) do
                    t:CreateButton({ Name = car.Name .. "  -  " .. car.Price, Callback = function()
                        -- show price and attempt to buy
                        SAFE_CALL(function()
                            -- display a quick notify
                            if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Attempting to buy "..car.Name, Duration=3}) end
                            -- try to find and fire matching TextButton in PlayerGui
                            local found = false
                            for _,v in pairs(LP.PlayerGui:GetDescendants()) do
                                if v:IsA("TextButton") then
                                    if string.find(string.lower(v.Name), string.lower(car.Keyword)) or string.find(string.lower(v.Text), string.lower(car.Keyword)) then
                                        pcall(function() firesignal(v.MouseButton1Click) end)
                                        found = true
                                        break
                                    end
                                end
                            end
                            if not found then
                                -- fallback: try to call :Activate() or :FireServer? We can't assume remote name.
                                if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Buy button not found in GUI.", Duration=4}) end
                                _G.GMonShowError("Buy action could not find in-game buy button for: "..car.Name)
                            end
                        end)
                    end})
                end
            else
                -- fallback: create a small ScreenGui selector
                local function showBuyGui()
                    local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui",5)
                    if not pg then return end
                    if pg:FindFirstChild("GMonBuyCarGui") then pcall(function() pg.GMonBuyCarGui:Destroy() end) end
                    local sg = Instance.new("ScreenGui", pg)
                    sg.Name = "GMonBuyCarGui"; sg.ResetOnSpawn = false
                    local frame = Instance.new("Frame", sg)
                    frame.Size = UDim2.new(0, 320, 0, 260)
                    frame.Position = UDim2.new(0.5, -160, 0.25, 0)
                    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
                    local corner = Instance.new("UICorner", frame)
                    corner.CornerRadius = UDim.new(0,8)
                    local title = Instance.new("TextLabel", frame)
                    title.Size = UDim2.new(1, -20, 0, 30); title.Position = UDim2.new(0,10,0,10)
                    title.BackgroundTransparency = 1; title.Text = "G-MON Buy Car"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold; title.TextSize = 16
                    local list = Instance.new("ScrollingFrame", frame)
                    list.Size = UDim2.new(1, -20, 0, 160); list.Position = UDim2.new(0,10,0,44)
                    list.CanvasSize = UDim2.new(0,0,0,0)
                    list.BackgroundTransparency = 0.15
                    local ui = Instance.new("UIListLayout", list)
                    ui.Padding = UDim.new(0,6)
                    local priceLabel = Instance.new("TextLabel", frame)
                    priceLabel.Size = UDim2.new(1, -20, 0, 24); priceLabel.Position = UDim2.new(0,10,1, -60)
                    priceLabel.BackgroundTransparency = 1; priceLabel.Text = "Price: -"; priceLabel.TextColor3 = Color3.new(1,1,1); priceLabel.Font = Enum.Font.Gotham; priceLabel.TextSize = 14
                    local buyBtn = Instance.new("TextButton", frame)
                    buyBtn.Size = UDim2.new(0,100,0,30); buyBtn.Position = UDim2.new(1, -110, 1, -30)
                    buyBtn.Text = "Buy"; buyBtn.Font = Enum.Font.GothamBold; buyBtn.TextSize = 14
                    local selected = nil
                    for _,car in ipairs(CarsDB) do
                        local btn = Instance.new("TextButton", list)
                        btn.Size = UDim2.new(1, -10, 0, 28)
                        btn.Text = car.Name
                        btn.Font = Enum.Font.Gotham
                        btn.TextSize = 14
                        btn.BackgroundTransparency = 0.2
                        btn.MouseButton1Click:Connect(function()
                            selected = car
                            priceLabel.Text = "Price: "..(car.Price or "-")
                        end)
                    end
                    list.CanvasSize = UDim2.new(0,0,0, (#CarsDB * 34))
                    buyBtn.MouseButton1Click:Connect(function()
                        if not selected then
                            _G.GMonShowError("No car selected to buy.")
                            return
                        end
                        -- try to find GUI buy button and click
                        local found = false
                        for _,v in pairs(LP.PlayerGui:GetDescendants()) do
                            if v:IsA("TextButton") then
                                if string.find(string.lower(v.Name), string.lower(selected.Keyword)) or string.find(string.lower(v.Text), string.lower(selected.Keyword)) then
                                    pcall(function() firesignal(v.MouseButton1Click) end)
                                    found = true
                                    break
                                end
                            end
                        end
                        if not found then
                            _G.GMonShowError("Buy button not found in PlayerGui for: "..selected.Name)
                        end
                    end)
                end
                t:CreateButton({ Name = "Open Buy Car UI", Callback = function() SAFE_CALL(showBuyGui) end })
            end
        end)

        -- Haruka tab (only AutoFarm)
        SAFE_CALL(function()
            local t = Tabs.Haruka
            t:CreateLabel("Haruka (Build A Boat) Features")
            local conf = STATE.Modules.Haruka.ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then
                    t:CreateToggle({ Name = opt.name, CurrentValue = opt.current or false, Callback = function(v) SAFE_CALL(opt.onChange, v) end })
                end
            end
        end)

        -- Night Vision tab
        SAFE_CALL(function()
            local t = Tabs.NV
            t:CreateLabel("Night Vision")
            t:CreateToggle({ Name = "Enable Night Vision", CurrentValue = NV.enabled, Callback = function(v) if v then NV.enable() else NV.disable() end end })
            t:CreateSlider({ Name = "Night Vision (Y) Strength", Range = {0,100}, Increment = 1, CurrentValue = math.floor((NV.strength or 0.3)*100), Callback = function(v) NV.setStrength((v or 30)/100) end })
            t:CreateParagraph({ Title = "Note", Content = "Uses ColorCorrectionEffect in Lighting." })
        end)

        -- Settings tab (replaces Fly)
        SAFE_CALL(function()
            local t = Tabs.Settings
            t:CreateLabel("Settings (Save / Load)")
            t:CreateButton({ Name = "Save CDT Settings", Callback = function()
                SAFE_CALL(function()
                    local cd = STATE.Modules.CarDeal
                    local dump = {
                        speed = cd.speed, stars = cd.stars, smaller = cd.smaller, bigger = cd.bigger,
                        toggles = {
                            Auto = cd.Auto, Collectables = cd.collectables, Open = cd.open, Fire = cd.fireman,
                            Sell = cd.Customer, Deliver = cd.deliver, Buyer = cd.buyer, Popup = cd.annoy
                        },
                        nightVision = { enabled = NV.enabled, strength = NV.strength }
                    }
                    local ok, encoded = pcall(function() return HttpService:JSONEncode(dump) end)
                    if ok and encoded then
                        if has_writefile then
                            pcall(function() writefile(STATE.SettingsFile, encoded) end)
                            if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Saved settings to file.", Duration=3}) end
                        else
                            STATE.SavedMemory = encoded
                            if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Saved settings to memory (no writefile).", Duration=3}) end
                        end
                    end
                end)
            end})
            t:CreateButton({ Name = "Load CDT Settings", Callback = function()
                SAFE_CALL(function()
                    local content = nil
                    if has_isfile and has_readfile and isfile(STATE.SettingsFile) then pcall(function() content = readfile(STATE.SettingsFile) end) end
                    if not content then content = STATE.SavedMemory end
                    if content and #content>0 then
                        local ok, tdata = pcall(function() return HttpService:JSONDecode(content) end)
                        if ok and type(tdata) == "table" then
                            local cd = STATE.Modules.CarDeal
                            if cd then
                                cd.speed = tonumber(tdata.speed) or cd.speed
                                cd.stars = tonumber(tdata.stars) or cd.stars
                                cd.smaller = tonumber(tdata.smaller) or cd.smaller
                                cd.bigger = tonumber(tdata.bigger) or cd.bigger
                                local tog = tdata.toggles or {}
                                if tog.Auto then cd.startAutoFarm() else cd.stopAutoFarm() end
                                if tog.Collectables then cd.startCollectibles() else cd.stopCollectibles() end
                                if tog.Open then cd.startOpenKit() else cd.stopOpenKit() end
                                if tog.Fire then cd.startExtinguishFire() else cd.stopExtinguishFire() end
                                if tog.Sell then cd.startAutoSellCars() else cd.stopAutoSellCars() end
                                if tog.Deliver then cd.startAutoDelivery() else cd.stopAutoDelivery() end
                                if tog.Buyer then cd.startAutoUpgrade() else cd.stopAutoUpgrade() end
                                if tog.Popup then cd.enablePopupBlock() else cd.disablePopupBlock() end
                            end
                            if tdata.nightVision then
                                NV.setStrength(tonumber(tdata.nightVision.strength) or NV.strength)
                                if tdata.nightVision.enabled then NV.enable() else NV.disable() end
                            end
                            if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Settings loaded.", Duration=3}) end
                        else
                            _G.GMonShowError("Failed to parse settings file.")
                        end
                    else
                        _G.GMonShowError("No saved settings found.")
                    end
                end)
            end})
            t:CreateButton({ Name = "Export Settings (Clipboard)", Callback = function()
                SAFE_CALL(function()
                    local cd = STATE.Modules.CarDeal
                    local data = {
                        speed = cd.speed, stars = cd.stars, smaller = cd.smaller, bigger = cd.bigger,
                        toggles = { Auto = cd.Auto, Collectables = cd.collectables, Open = cd.open, Fire = cd.fireman, Sell = cd.Customer, Deliver = cd.deliver, Buyer = cd.buyer, Popup = cd.annoy },
                        nightVision = { enabled = NV.enabled, strength = NV.strength }
                    }
                    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
                    if ok and encoded then
                        if has_setclipboard then pcall(function() setclipboard(encoded) end) end
                        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Exported settings to clipboard (if supported).", Duration=3}) end
                    end
                end)
            end})
            t:CreateButton({ Name = "Import Settings (Clipboard)", Callback = function()
                SAFE_CALL(function()
                    if not has_setclipboard then _G.GMonShowError("No clipboard support in this executor.") return end
                    local ok, clip = pcall(function() return getclipboard() end)
                    if not ok or not clip then _G.GMonShowError("Failed to read clipboard.") return end
                    local ok2, parsed = pcall(function() return HttpService:JSONDecode(clip) end)
                    if not ok2 then _G.GMonShowError("Clipboard did not contain valid settings JSON.") return end
                    local cd = STATE.Modules.CarDeal
                    cd.speed = tonumber(parsed.speed) or cd.speed
                    cd.stars = tonumber(parsed.stars) or cd.stars
                    cd.smaller = tonumber(parsed.smaller) or cd.smaller
                    cd.bigger = tonumber(parsed.bigger) or cd.bigger
                    -- apply toggles
                    local tog = parsed.toggles or {}
                    if tog.Auto then cd.startAutoFarm() else cd.stopAutoFarm() end
                    if tog.Collectables then cd.startCollectibles() else cd.stopCollectibles() end
                    if tog.Open then cd.startOpenKit() else cd.stopOpenKit() end
                    if tog.Fire then cd.startExtinguishFire() else cd.stopExtinguishFire() end
                    if tog.Sell then cd.startAutoSellCars() else cd.stopAutoSellCars() end
                    if tog.Deliver then cd.startAutoDelivery() else cd.stopAutoDelivery() end
                    if tog.Buyer then cd.startAutoUpgrade() else cd.stopAutoUpgrade() end
                    if tog.Popup then cd.enablePopupBlock() else cd.disablePopupBlock() end
                    if parsed.nightVision then NV.setStrength(parsed.nightVision.strength) if parsed.nightVision.enabled then NV.enable() else NV.disable() end end
                    if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Imported settings from clipboard.", Duration=3}) end
                end)
            end})
        end)
    end)
end

-- Status updater (console & optional notifications)
task.spawn(function()
    while true do
        SAFE_WAIT(1)
        pcall(function()
            if os.time() % 10 == 0 then
                print(("[G-MON] uptime %s | last: %s"):format(Utils.FormatTime(os.time()-STATE.StartTime), STATE.LastAction or "Idle"))
            end
        end)
    end
end)

-- Apply detection & start UI
local function ApplyGame()
    STATE.GAME = Utils.FlexibleDetectByAliases()
    if STATE.GAME == "UNKNOWN" then STATE.GAME = "ALL" end
end

local function MainStart()
    SAFE_CALL(function()
        ApplyGame()
        buildUI()
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use Car Dealership tab for CDT features", Duration=4}) end
        print("[G-MON] Hub loaded. Detected:", STATE.GAME)
    end)
end

-- initialize
MainStart()

-- Return table for external control if executor expects it
return {
    Start = MainStart,
    NV = NV,
    CDT = STATE.Modules.CarDeal
}