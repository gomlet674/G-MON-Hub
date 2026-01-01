-- G-MON | CDT-focused main.lua
-- Fokus: Car Dealership Tycoon features + Night Vision + Save/Load settings
-- Lightweight UI (Rayfield if available, fallback noop)
-- Usage: paste to executor (LocalScript)

-- BOOTSTRAP
repeat task.wait() until game:IsLoaded()
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UIS            = game:GetService("UserInputService")
local Workspace      = workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting       = game:GetService("Lighting")
local HttpService    = game:GetService("HttpService")
local TweenService   = game:GetService("TweenService")
local LP             = Players.LocalPlayer

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
    StartTime = os.time(),
    Modules = {},
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    Status = nil,
    Flags = {},
    LastAction = "Idle",
    Settings = {}, -- runtime settings / to save
    SettingsFile = "gmon_cdt_settings.json"
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
    if pid == 1554960397 then return "CAR_TYCOON" end
    -- try simple workspace heuristics
    local aliasMap = {
        CAR_TYCOON = {"Cars","VehicleFolder","Vehicles","Dealership","Garage","CarShop","CarStages","CarsFolder"}
    }
    for key,list in pairs(aliasMap) do
        for _,name in ipairs(list) do
            if Workspace:FindFirstChild(name) then return key end
        end
    end
    -- fallback
    return "ALL"
end

STATE.Modules.Utils = Utils

-- ===== CDT MODULE (extracted & slightly simplified) =====
do
    local CDT = {}
    CDT.Auto = false; CDT.collectables = false; CDT.open = false; CDT.fireman = false
    CDT.Customer = false; CDT.deliver = false; CDT.buyer = false; CDT.annoy = false
    CDT.speed = 300
    CDT.stars = 0; CDT.smaller = 0; CDT.bigger = 999999999
    CDT._tasks = {}
    CDT.spawned = false

    local function saveDeliveryConfig()
        local data = { stars = CDT.stars, smaller = CDT.smaller, bigger = CDT.bigger, speed = CDT.speed }
        local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
        if ok and encoded then
            if writefile then
                pcall(function() writefile(STATE.SettingsFile, encoded) end)
            else
                STATE.Settings.__file_fallback = encoded
            end
        end
    end
    local function loadDeliveryConfig()
        local content = nil
        if isfile and isfile(STATE.SettingsFile) then
            pcall(function() content = readfile(STATE.SettingsFile) end)
        elseif STATE.Settings.__file_fallback then
            content = STATE.Settings.__file_fallback
        end
        if content and #content>0 then
            local ok, t = pcall(function() return HttpService:JSONDecode(content) end)
            if ok and type(t) == "table" then
                CDT.stars = tonumber(t.stars) or CDT.stars
                CDT.smaller = tonumber(t.smaller) or CDT.smaller
                CDT.bigger = tonumber(t.bigger) or CDT.bigger
                CDT.speed = tonumber(t.speed) or CDT.speed
            end
        end
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
                    local new = Instance.new("Part", Workspace)
                    new.Name = "justapart"
                    new.Size = Vector3.new(10000,20,10000)
                    new.Anchored = true
                    local okpos = pcall(function() new.Position = LP.Character.HumanoidRootPart.Position + Vector3.new(0,1000,0) end)
                end
                while CDT.Auto do
                    task.wait(0.6)
                    local chr = LP.Character
                    if not chr or not chr:FindFirstChild("Humanoid") or not chr:FindFirstChild("HumanoidRootPart") then continue end
                    if not chr.Humanoid.SeatPart then continue end
                    local carModel = chr.Humanoid.SeatPart.Parent
                    if carModel and carModel.PrimaryPart then
                        pcall(function()
                            carModel:PivotTo(Workspace.justapart.CFrame * CFrame.new(0,10,1000))
                        end)
                        local pos = Workspace.justapart.CFrame * CFrame.new(0,10,-1000)
                        local speed = CDT.speed or 300
                        if carModel.PrimaryPart then
                            carModel.PrimaryPart.AssemblyLinearVelocity = (pos.Position - carModel.PrimaryPart.Position).Unit * speed
                        end
                    end
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
                task.wait(0.6)
                local chr = LP.Character
                if not chr or not chr:FindFirstChild("Humanoid") or not chr:FindFirstChild("HumanoidRootPart") then continue end
                if not chr.Humanoid.SeatPart then continue end
                local car = chr.Humanoid.SeatPart.Parent
                if Workspace:FindFirstChild("Collectibles") then
                    for _,v in pairs(Workspace.Collectibles:GetChildren()) do
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
                task.wait(1)
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

    function CDT.startExtinguishFire()
        if CDT.fireman then return end
        CDT.fireman = true
        CDT._tasks.fire = task.spawn(function()
            while CDT.fireman do
                SAFE_CALL(function()
                    if not LP.Backpack:FindFirstChildOfClass("Tool") and not LP.Character:FindFirstChildOfClass("Tool") then
                        local rem = ReplicatedStorage:FindFirstChild("Remotes")
                        if rem and rem:FindFirstChild("Switch") then
                            pcall(function() rem.Switch:FireServer("FireDealership") end)
                        end
                        task.wait(10)
                    else
                        -- try to interact through TaskController if available
                        local tryRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TaskController")
                        if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TaskController") and ReplicatedStorage.Remotes.TaskController:FindFirstChild("ActionGameDataReplication") then
                            local t = ReplicatedStorage.Remotes.TaskController.ActionGameDataReplication
                            -- attempt interact (safe)
                            pcall(function()
                                t:FireServer("TryInteractWithItem", {["GameName"] = "FirefighterGame", ["Action"] = "UpdatePlayerToolState", ["Data"] = {["IsActive"] = true, ["ToolName"] = "Extinguisher"}})
                            end)
                        end
                        task.wait(1)
                    end
                end)
                task.wait(0.5)
            end
        end)
    end
    function CDT.stopExtinguishFire()
        CDT.fireman = false
        if CDT._tasks.fire then pcall(function() task.cancel(CDT._tasks.fire) end); CDT._tasks.fire = nil end
    end

    function CDT.startAutoSellCars()
        if CDT.Customer then return end
        CDT.Customer = true
        CDT._tasks.sell = task.spawn(function()
            while CDT.Customer do
                task.wait(1)
                SAFE_CALL(function()
                    local tyc = findPlayerPlot()
                    if not tyc then return end
                    local customer = nil
                    if tyc:FindFirstChild("Dealership") then
                        for _,v in pairs(tyc.Dealership:GetChildren()) do
                            if v.ClassName == "Model" and v.PrimaryPart ~= nil then
                                customer = v; break
                            end
                        end
                    end
                    if not customer then return end
                    task.wait(5)
                    local gmenu = LP.PlayerGui:FindFirstChild("Menu")
                    if not gmenu or not gmenu:FindFirstChild("Inventory") then return end
                    local bestChoice = nil
                    for _,v in pairs(gmenu.Inventory.CarShop.Frame.Frame:GetDescendants()) do
                        if v.Name == "PriceValue" and typeof(v.Value) == "string" then
                            local okstr = v.Value:gsub(",",""):gsub("%$","")
                            local priceNum = tonumber(okstr)
                            if priceNum and priceNum >= CDT.smaller and priceNum <= CDT.bigger then
                                bestChoice = v; break
                            end
                        end
                    end
                    if not bestChoice then return end
                    -- Accept/Complete/Collect using remotes if exist (safe)
                    local rem = ReplicatedStorage:FindFirstChild("Remotes")
                    if rem and rem:FindFirstChild("DealershipCustomerController") and rem.DealershipCustomerController:FindFirstChild("NPCHandler") then
                        local handler = rem.DealershipCustomerController.NPCHandler
                        pcall(function()
                            handler:FireServer({["Action"] = "AcceptOrder", ["OrderId"] = customer:GetAttribute("OrderId")})
                            task.wait(0.3)
                            handler:FireServer({["OrderId"] = customer:GetAttribute("OrderId"), ["Action"] = "CompleteOrder", ["Specs"] = {["Car"] = bestChoice.Parent.Name}})
                            task.wait(0.3)
                            handler:FireServer({["Action"] = "CollectReward", ["OrderId"] = customer:GetAttribute("OrderId")})
                        end)
                    end
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
            while CDT.deliver do
                task.wait(1)
                SAFE_CALL(function()
                    if LP.Character and LP.Character:FindFirstChild("Humanoid") and LP.Character.Humanoid.SeatPart then
                        -- try to Fire servers to spawn/complete delivery (using remotes if present)
                        local rem = ReplicatedStorage:FindFirstChild("Remotes")
                        if rem and rem:FindFirstChild("DealershipCustomerController") and rem.DealershipCustomerController:FindFirstChild("JobRemoteHandler") then
                            local j = rem.DealershipCustomerController.JobRemoteHandler
                            pcall(function() j:FireServer(_G.remotetable or {}) end)
                        end
                    else
                        -- try to request job spawn
                        local rem = ReplicatedStorage:FindFirstChild("Remotes")
                        if rem and rem:FindFirstChild("DealershipCustomerController") and rem.DealershipCustomerController:FindFirstChild("JobRemoteHandler") then
                            local j = rem.DealershipCustomerController.JobRemoteHandler
                            pcall(function() j:FireServer(_G.remotetable or {}) end)
                        end
                    end
                end)
            end
        end)
    end
    function CDT.stopAutoDelivery()
        CDT.deliver = false
        if CDT._tasks.deliver then pcall(function() task.cancel(CDT._tasks.deliver) end); CDT._tasks.deliver = nil end
    end

    function CDT.startAutoUpgrade()
        if CDT.buyer then return end
        CDT.buyer = true
        CDT._tasks.buyer = task.spawn(function()
            while CDT.buyer do
                task.wait(0.6)
                SAFE_CALL(function()
                    local tyc = findPlayerPlot()
                    if not tyc or not tyc:FindFirstChild("Dealership") then return end
                    for _,v in pairs(tyc.Dealership.Purchases:GetChildren()) do
                        if v:FindFirstChild("TycoonButton") and v.TycoonButton.Button and v.TycoonButton.Button.Transparency == 0 then
                            pcall(function() ReplicatedStorage.Remotes.Build:FireServer("BuyItem", v.Name) end)
                            task.wait(0.25)
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
        popupConn = LP.PlayerGui.ChildAdded:Connect(function(c)
            if c and c.Name == "Popup2" then pcall(function() c:Destroy() end) end
        end)
    end
    function CDT.disablePopupBlock()
        CDT.annoy = false
        if popupConn then pcall(function() popupConn:Disconnect() end); popupConn = nil end
    end

    function CDT.setDeliveryConfig(st, mini, maxi)
        CDT.stars = tonumber(st) or CDT.stars
        CDT.smaller = tonumber(mini) or CDT.smaller
        CDT.bigger = tonumber(maxi) or CDT.bigger
        saveDeliveryConfig()
    end

    function CDT.setSpeed(v)
        CDT.speed = tonumber(v) or CDT.speed
        saveDeliveryConfig()
    end

    function CDT.ExposeConfig()
        return {
            { type="toggle", name="Auto Farm (Vehicles)", current=CDT.Auto, onChange=function(v) if v then CDT.startAutoFarm() else CDT.stopAutoFarm() end end },
            { type="toggle", name="Auto Collectibles", current=CDT.collectables, onChange=function(v) if v then CDT.startCollectibles() else CDT.stopCollectibles() end end },
            { type="toggle", name="Auto Open Vehicle Kit", current=CDT.open, onChange=function(v) if v then CDT.startOpenKit() else CDT.stopOpenKit() end end },
            { type="toggle", name="Auto Extinguish Fire", current=CDT.fireman, onChange=function(v) if v then CDT.startExtinguishFire() else CDT.stopExtinguishFire() end end },
            { type="toggle", name="Auto Sell Cars", current=CDT.Customer, onChange=function(v) if v then CDT.startAutoSellCars() else CDT.stopAutoSellCars() end end },
            { type="toggle", name="Auto Delivery", current=CDT.deliver, onChange=function(v) if v then CDT.startAutoDelivery() else CDT.stopAutoDelivery() end end },
            { type="toggle", name="Auto Upgrade Plot", current=CDT.buyer, onChange=function(v) if v then CDT.startAutoUpgrade() else CDT.stopAutoUpgrade() end end },
            { type="toggle", name="Popup Disabler", current=CDT.annoy, onChange=function(v) if v then CDT.enablePopupBlock() else CDT.disablePopupBlock() end end },
            { type="slider", name="AutoDrive Speed (CDT)", min=50, max=1000, current=CDT.speed, onChange=function(v) CDT.setSpeed(v) end },
            { type="input", name="Delivery: Min Stars", current=CDT.stars, onChange=function(v) CDT.stars = tonumber(v) or CDT.stars; saveDeliveryConfig() end },
            { type="input", name="Delivery: Min Reward", current=CDT.smaller, onChange=function(v) CDT.smaller = tonumber(v) or CDT.smaller; saveDeliveryConfig() end },
            { type="input", name="Delivery: Max Reward", current=CDT.bigger, onChange=function(v) CDT.bigger = tonumber(v) or CDT.bigger; saveDeliveryConfig() end }
        }
    end

    STATE.Modules.CarDeal = CDT
end

-- ===== Night Vision helper =====
local NV = {}
NV.cc = nil
NV.enabled = false
NV.strength = 0.3 -- default brightness-ish
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

-- ===== Rayfield load (safe fallback minimal) =====
do
    local ok, Ray = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
    if ok and Ray then STATE.Rayfield = Ray else
        local Fallback = {}
        function Fallback:CreateWindow(opts)
            local win = {}
            function win:CreateTab(name)
                local tab = {}
                function tab:CreateLabel(txt) end
                function tab:CreateParagraph(tbl) end
                function tab:CreateButton(tbl) end
                function tab:CreateToggle(tbl) end
                function tab:CreateSlider(tbl) end
                function tab:CreateInput(tbl) end
                return tab
            end
            function win:CreateNotification() end
            return win
        end
        function Fallback:Notify() end
        STATE.Rayfield = Fallback
    end
end

-- ===== Build UI (minimal, CDT only) =====
local function buildUI()
    SAFE_CALL(function()
        STATE.Window = (STATE.Rayfield and STATE.Rayfield.CreateWindow) and STATE.Rayfield:CreateWindow({
            Name = "G-MON CDT",
            LoadingTitle = "G-MON CDT",
            LoadingSubtitle = "CDT features",
            ConfigurationSaving = { Enabled = false }
        }) or nil

        local Tabs = {}
        if STATE.Window then
            Tabs.Info = STATE.Window:CreateTab("Info")
            Tabs.CDT = STATE.Window:CreateTab("CDT")
            Tabs.NV = STATE.Window:CreateTab("NightVision")
            Tabs.Settings = STATE.Window:CreateTab("Settings")
        else
            local function mk() return { CreateLabel=function() end, CreateParagraph=function() end, CreateButton=function() end, CreateToggle=function() end, CreateSlider=function() end, CreateInput=function() end } end
            Tabs.Info = mk(); Tabs.CDT = mk(); Tabs.NV = mk(); Tabs.Settings = mk()
        end
        STATE.Tabs = Tabs

        -- Info
        SAFE_CALL(function()
            Tabs.Info:CreateLabel("G-MON CDT - fokus ke CDT features.")
            local detected = Utils.FlexibleDetectByAliases()
            Tabs.Info:CreateParagraph({ Title = "Detected", Content = tostring(detected) })
            Tabs.Info:CreateParagraph({ Title = "Note", Content = "UNKNOWN => ALL (module will be usable in any place). Save/Load available in Settings." })
        end)

        -- CDT tab: expose config from module
        SAFE_CALL(function()
            local t = Tabs.CDT
            t:CreateLabel("Car Dealership Tycoon controls")
            local conf = STATE.Modules.CarDeal and STATE.Modules.CarDeal.ExposeConfig and STATE.Modules.CarDeal.ExposeConfig() or {}
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
                    end
                end
            end
            t:CreateParagraph({ Title = "Tip", Content = "Toggle features on/off. Delivery limits saved to file." })
        end)

        -- Night Vision
        SAFE_CALL(function()
            local t = Tabs.NV
            t:CreateLabel("Night Vision")
            t:CreateToggle({ Name = "Enable Night Vision", CurrentValue = false, Callback = function(v) if v then NV.enable() else NV.disable() end end })
            t:CreateSlider({ Name = "Night Vision (Y) Strength", Range = {0,100}, Increment = 1, CurrentValue = math.floor((NV.strength or 0.3)*100), Callback = function(v) NV.setStrength((v or 30)/100) end })
            t:CreateParagraph({ Title = "Note", Content = "Y = strength (0-100). This uses a ColorCorrection effect in Lighting." })
        end)

        -- Settings: Save / Load
        SAFE_CALL(function()
            local t = Tabs.Settings
            t:CreateLabel("Settings")
            t:CreateButton({ Name = "Save CDT Settings", Callback = function()
                SAFE_CALL(function()
                    -- gather settings
                    if STATE.Modules.CarDeal then
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
                            if writefile then
                                pcall(function() writefile(STATE.SettingsFile, encoded) end)
                                if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="CDT settings saved.", Duration=3}) end
                            else
                                STATE.Settings.__file_fallback = encoded
                                if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Saved to memory (no writefile).", Duration=3}) end
                            end
                        end
                    end
                end)
            end })
            t:CreateButton({ Name = "Load CDT Settings", Callback = function()
                SAFE_CALL(function()
                    local content = nil
                    if isfile and isfile(STATE.SettingsFile) then
                        pcall(function() content = readfile(STATE.SettingsFile) end)
                    elseif STATE.Settings.__file_fallback then
                        content = STATE.Settings.__file_fallback
                    end
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
                            if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="CDT settings loaded.", Duration=3}) end
                        else
                            if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Failed to parse settings.", Duration=3}) end
                        end
                    else
                        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="No saved settings found.", Duration=3}) end
                    end
                end)
            end })
            t:CreateButton({ Name = "Export Settings (clipboard)", Callback = function()
                SAFE_CALL(function()
                    local ok, encoded = pcall(function()
                        local cd = STATE.Modules.CarDeal
                        local data = {
                            speed = cd.speed, stars = cd.stars, smaller = cd.smaller, bigger = cd.bigger,
                            toggles = { Auto = cd.Auto, Collectables = cd.collectables, Open = cd.open, Fire = cd.fireman, Sell = cd.Customer, Deliver = cd.deliver, Buyer = cd.buyer, Popup = cd.annoy },
                            nightVision = { enabled = NV.enabled, strength = NV.strength }
                        }
                        return HttpService:JSONEncode(data)
                    end)
                    if ok and encoded then
                        if setclipboard then pcall(function() setclipboard(encoded) end) end
                        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Exported to clipboard (if available).", Duration=3}) end
                    end
                end)
            end })
        end)
    end)
end

-- ===== STATUS minimal (runtime text in output + indicator) =====
task.spawn(function()
    while true do
        SAFE_WAIT(1)
        pcall(function()
            local last = STATE.LastAction or "Idle"
            -- small debug print to console (keeps user aware)
            -- avoid spamming too much
            if os.time() % 10 == 0 then
                print(("[G-MON CDT] uptime %s | last: %s"):format(Utils.FormatTime(os.time()-STATE.StartTime), last))
            end
        end)
    end
end)

-- INITIALIZE
local function MainStart()
    SAFE_CALL(function()
        -- detection: if not CDT use "ALL"
        local det = Utils.FlexibleDetectByAliases() or "ALL"
        if det == "UNKNOWN" then det = "ALL" end
        STATE.GAME = det
        buildUI()
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON CDT", Content="Loaded (CDT features).", Duration=4}) end
        print("[G-MON CDT] ready. Detected:", STATE.GAME)
    end)
    return true
end

-- run
MainStart()

-- return as module-like if execute inside executor that expects return
return {
    Start = MainStart,
    NV = NV,
    CDT = STATE.Modules.CarDeal
}