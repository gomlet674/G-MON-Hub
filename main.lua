-- G-MON Hub - main_final_with_vehicle_and_race.lua
-- Merged: original G-MON core (Blox), Vehicle (reworked from your Vehicle Dealership script),
-- Build_A_Boat_For_Treasure (lightweight), Status UI, Rayfield UI fallback
-- Safe, modular, Android/executor-friendly (best-effort)

repeat task.wait() until game:IsLoaded()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- SAFE helpers
local function SAFE_CALL(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if not ok then warn("[G-MON] SAFE_CALL:", res) end
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
    LastAction = "Idle",
    Remotes = {},      -- captured remote args by name
    VehicleSettings = { speed = 300, stars = 0, smaller = 0, bigger = 9999999 },
    VehicleLoops = {}
}

-- UTILS
local Utils = {}
function Utils.SafeChar() local ok,c = pcall(function() return LP and LP.Character end) if not ok or not c then return nil end
    if c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then return c end return nil end
function Utils.FormatTime(sec) sec = math.max(0, math.floor(sec or 0)); local h=math.floor(sec/3600); local m=math.floor((sec%3600)/60); local s=sec%60
    if h>0 then return string.format("%02dh:%02dm:%02ds",h,m,s) end
    return string.format("%02dm:%02ds",m,s)
end
function Utils.FlexibleDetectByAliases()
    local pid = game.PlaceId
    if pid == 2753915549 then return "BLOX_FRUIT" end
    local aliasMap = {
        BLOX_FRUIT = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","Quests","NPCQuests"},
        CAR_TYCOON = {"Cars","VehicleFolder","Vehicles","Dealership","Garage","CarShop","CarStages","CarsFolder"}
    }
    for key,list in pairs(aliasMap) do for _,name in ipairs(list) do if Workspace:FindFirstChild(name) then return key end end end
    for _,o in ipairs(Workspace:GetChildren()) do
        local n = tostring(o.Name):lower()
        if n:match("enemy") or n:match("mob") then return "BLOX_FRUIT" end
        if n:match("car") or n:match("vehicle") or n:match("dealership") then return "CAR_TYCOON" end
    end
    return "UNKNOWN"
end
function Utils.ShortLabelForGame(g) if g=="BLOX_FRUIT" then return "Blox" elseif g=="CAR_TYCOON" then return "Car" else return tostring(g or "Unknown") end end

STATE.Modules.Utils = Utils

-- ===== BLOX MODULE (kept) =====
do
    local M = {}
    M.config = { attack_delay = 0.35, range = 10, long_range = false, fast_attack = false }
    M.running = false; M._task = nil

    local function findEnemyFolder()
        local hints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs"}
        for _, name in ipairs(hints) do local f = Workspace:FindFirstChild(name) if f then return f end end
        return nil
    end

    local function loop()
        while M.running do
            task.wait(0.12)
            SAFE_CALL(function()
                if STATE.GAME ~= "BLOX_FRUIT" then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local folder = findEnemyFolder() if not folder then return end
                local nearest,bestDist = nil,math.huge
                for _,mob in ipairs(folder:GetChildren()) do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                        local hum = mob:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if d < bestDist and d <= (M.config.range or 10) then bestDist,nearest = d,mob end
                        end
                    end
                end
                if not nearest and M.config.long_range then
                    for _,mob in ipairs(folder:GetChildren()) do
                        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                            local hum = mob:FindFirstChild("Humanoid")
                            if hum and hum.Health > 0 then
                                local d=(mob.HumanoidRootPart.Position-hrp.Position).Magnitude
                                if d < bestDist then bestDist,nearest = d,mob end
                            end
                        end
                    end
                end
                if not nearest then return end
                if M.config.long_range then
                    local dmg = M.config.fast_attack and 35 or 20; local hits = M.config.fast_attack and 3 or 1
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

    function M.start() if M.running then return end; M.running=true; STATE.Flags.Blox=true; M._task = task.spawn(loop) end
    function M.stop() M.running=false; STATE.Flags.Blox=false; M._task=nil end
    function M.ExposeConfig()
        return {
            { type="slider", name="Range (studs)", min=1, max=50, current=M.config.range, onChange=function(v) M.config.range=v end},
            { type="slider", name="Attack Delay (ms)", min=50, max=1000, current=math.floor(M.config.attack_delay*1000), onChange=function(v) M.config.attack_delay=v/1000 end},
            { type="toggle", name="Fast Attack", current=M.config.fast_attack, onChange=function(v) M.config.fast_attack=v end},
            { type="toggle", name="Long Range Hit", current=M.config.long_range, onChange=function(v) M.config.long_range=v end}
        }
    end

    STATE.Modules.Blox = M
end

-- ===== VEHICLE MODULE (REWORKED from your Vehicle Dealership script) =====
do
    local M = {}
    M.running = {}
    M.settings = STATE.VehicleSettings -- speed, stars, smaller, bigger
    M.guiRef = nil

    local function safeGetChar() return Utils.SafeChar() end
    local function getPlayerVehicle()
        local char = LP.Character
        if not char then return nil end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart and hum.SeatPart.Parent then
            -- seat.Parent might be seat model or seat part hierarchy
            local p = hum.SeatPart.Parent
            -- some car models are seat.Parent.Parent
            if p.Parent and p.Parent:IsA("Model") and p.Parent.PrimaryPart then return p.Parent end
            if p:IsA("Model") then return p end
            return p
        end
        return nil
    end

    -- helpers to find Delivery truck (by JobId) and job parts
    local function findDeliveryTruck(jobId)
        if not jobId then return nil end
        local ok, children = pcall(function() return Workspace:FindFirstChild("Cars") and Workspace.Cars:GetChildren() or {} end)
        if not ok then return nil end
        for _,v in ipairs(children) do
            if v and v:GetAttribute and tostring(v.Name):lower():find("delivery") and tonumber(v:GetAttribute("JobId")) == tonumber(jobId) then
                return v
            end
        end
        return nil
    end

    -- AutoFarm: move car between two distant positions using a large invisible part anchor
    local function vehicle_autofarm_tick()
        local vehicle = getPlayerVehicle()
        if not vehicle then return end
        -- ensure 'justapart' exists
        local jp = Workspace:FindFirstChild("justapart")
        if not jp then
            jp = Instance.new("Part")
            jp.Name = "justapart"
            jp.Size = Vector3.new(10000,20,10000)
            jp.Anchored = true
            jp.CanCollide = false
            jp.Position = (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position + Vector3.new(0,1000,0)) or Vector3.new(0,1000,0)
            jp.Parent = Workspace
        end
        -- target positions relative to justapart: forward then back (mirrors your original logic)
        local p1 = jp.CFrame * CFrame.new(0,10,1000)
        local p2 = jp.CFrame * CFrame.new(0,10,-1000)
        -- tween vehicle primary part towards p2 using AssemblyLinearVelocity for stability
        local prim = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
        if not prim then return end
        local speed = tonumber(M.settings.speed) or 300
        local dist = (prim.Position - p2.Position).Magnitude
        -- set AssemblyLinearVelocity in one-shot loop; also use TweenValue to keep pivoting
        local TweenValue = Instance.new("CFrameValue")
        TweenValue.Value = vehicle:GetPrimaryPartCFrame()
        local TweenInfoToUse = TweenInfo.new(math.max(0.1, dist / math.max(1,speed)), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
        local conn
        conn = TweenValue.Changed:Connect(function()
            pcall(function()
                vehicle:PivotTo(TweenValue.Value)
                if prim then prim.AssemblyLinearVelocity = prim.CFrame.LookVector * speed end
            end)
        end)
        local OnTween = TweenService:Create(TweenValue, TweenInfoToUse, {Value = p2})
        OnTween:Play()
        OnTween.Completed:Wait()
        if conn then conn:Disconnect() end
        pcall(function() if prim then prim.AssemblyLinearVelocity = prim.CFrame.LookVector * speed end end)
    end

    -- AutoCollectibles tick
    local function vehicle_collectibles_tick()
        local vehicle = getPlayerVehicle()
        if not vehicle then return end
        local collectRoot = Workspace:FindFirstChild("Collectibles")
        if not collectRoot then return end
        for _,v in ipairs(collectRoot:GetDescendants()) do
            if v:IsA("Model") and v.PrimaryPart and v.Parent==collectRoot and #v:GetChildren()>0 then
                -- some checks for billboard gui enabled
                local ok = pcall(function()
                    local gui = v:GetChildren()[2]
                    if gui and gui:FindFirstChild("Part") and gui.Part:FindFirstChildOfClass("BillboardGui") and gui.Part:FindFirstChildOfClass("BillboardGui").Enabled then
                        vehicle:PivotTo(v.PrimaryPart.CFrame)
                        return
                    end
                end)
                if ok then break end
            end
        end
    end

    -- AutoOpenKit tick
    local function vehicle_openkit_tick()
        pcall(function()
            local svc = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
            local ok, rem = pcall(function() return ReplicatedStorage.Remotes.Services.CarKitEventServiceRemotes.ClaimFreePack end)
            if ok and rem then
                rem:InvokeServer()
            end
        end)
    end

    -- AutoExtinguish Fire tick
    local function vehicle_extinguish_tick()
        -- simplified: if FireGuide exists, teleport to it and call TaskController
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return end
        if not pg:FindFirstChild("FireGuide") then return end
        local guide = pg.FireGuide
        if guide and guide.Adornee and guide.Adornee.CFrame then
            SAFE_CALL(function() LP.Character.HumanoidRootPart.CFrame = guide.Adornee.CFrame end)
        end
        pcall(function()
            local rem = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TaskController")
            if rem and rem.ActionGameDataReplication then
                rem.ActionGameDataReplication:FireServer("TryInteractWithItem", {GameName="FirefighterGame", Action="UpdatePlayerToolState", Data={IsActive=true, ToolName="Extinguisher"}})
            end
        end)
    end

    -- AutoSellCars tick (simplified & robust)
    local function vehicle_autosell_tick()
        local function findPlot()
            for _,v in ipairs(Workspace:GetDescendants()) do
                if v.Name=="Owner" and v.ClassName=="StringValue" and v.Value==LP.Name and v.Parent then
                    return v.Parent
                end
            end
            return nil
        end
        local plot = findPlot()
        if not plot or not plot:FindFirstChild("Dealership") then return end
        local customer = nil
        for _,v in ipairs(plot.Dealership:GetChildren()) do
            if v.ClassName == "Model" and v.PrimaryPart and v.PrimaryPart.Name=="HumanoidRootPart" then customer = v; break end
        end
        if not customer then return end
        -- parse budget and find best car in menu (UI dependent) - keep robust with pcall
        SAFE_CALL(function()
            local budget = (customer:GetAttribute("OrderSpecBudget") or ""):split(";")
            local minp = tonumber(budget[1]) or 0
            local maxp = tonumber(budget[2]) or 1e9
            local menu = LP.PlayerGui and LP.PlayerGui:FindFirstChild("Menu")
            if not menu then return end
            local best, bestVal = nil, 1e18
            for _,node in ipairs(menu:GetDescendants()) do
                if node.Name=="PriceValue" and node.Value then
                    local num = tonumber((tostring(node.Value):gsub(",",""):match("%$(%d+)")) or "") or nil
                    if num and num > minp and num < maxp and num < bestVal then bestVal=num; best=node end
                end
            end
            if best then
                -- construct order string -> simplified safe approach: request AcceptOrder/CompleteOrder/CollectReward
                local npc = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("DealershipCustomerController")
                if npc and npc.NPCHandler then
                    npc.NPCHandler:FireServer({Action="AcceptOrder", OrderId=customer:GetAttribute("OrderId")})
                    task.wait(0.2)
                    npc.NPCHandler:FireServer({OrderId=customer:GetAttribute("OrderId"), Action="CompleteOrder", Specs={Car=tostring(best.Parent.Name), Color=customer:GetAttribute("OrderSpecColor"), Rims=customer:GetAttribute("OrderSpecRims"), Springs=customer:GetAttribute("OrderSpecSprings"), RimColor=customer:GetAttribute("OrderSpecRimColor")}})
                    task.wait(0.2)
                    npc.NPCHandler:FireServer({Action="CollectReward", OrderId=customer:GetAttribute("OrderId")})
                end
            end
        end)
    end

    -- DELIVERY tick logic (uses captured remotes stored in STATE.Remotes.JobRemoteHandler)
    local function vehicle_delivery_tick()
        local job = STATE.Remotes.JobRemoteHandler
        if not job then return end
        -- if player not seated, try fire remote to spawn job (safe call)
        local veh = getPlayerVehicle()
        if not veh then
            SAFE_CALL(function()
                if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes.DealershipCustomerController and ReplicatedStorage.Remotes.DealershipCustomerController.JobRemoteHandler then
                    ReplicatedStorage.Remotes.DealershipCustomerController.JobRemoteHandler:FireServer(job)
                end
            end)
            return
        end
        -- if seated, try to pivot to nearest DeliveryPart
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v.Name=="DeliveryPart" and v.Transparency~=1 and v:IsA("BasePart") then
                SAFE_CALL(function() veh:PivotTo(v.CFrame * CFrame.new(0,0,0)) end)
                break
            end
        end
    end

    -- RACE features (auto start / vote / auto checkpoint traversal)
    local function races_list()
        local out = {"None"}
        local ok, kids = pcall(function() return Workspace:FindFirstChild("Races") and Workspace.Races:GetChildren() or {} end)
        if ok then
            for _,v in ipairs(kids) do if v:IsA("Model") then table.insert(out, v.Name) end end
        end
        return out
    end

    local function vehicle_race_tick()
        -- simplified but robust: if we saw StartLobby/remote1 stored, call it; if we saw Vote, call it.
        if STATE.Remotes.StartLobby and STATE.Remotes.RemoteStart then
            pcall(function() STATE.Remotes.RemoteStart:FireServer(unpack(STATE.Remotes.StartLobby)) end)
        end
        if STATE.Remotes.Vote and STATE.Remotes.RemoteVote then
            pcall(function() STATE.Remotes.RemoteVote:FireServer(unpack(STATE.Remotes.Vote)) end)
        end
        -- advanced checkpoint automation can be implemented on top of this basic infrastructure
    end

    -- Loop management (start/stop named loops)
    local function startLoop(name, fn)
        if M.running[name] then return end
        M.running[name] = true
        task.spawn(function()
            while M.running[name] do
                local ok,err = pcall(fn)
                if not ok then warn("[VehicleLoop]", name, err); M.running[name] = false; break end
                task.wait(0.7)
            end
        end)
    end
    local function stopLoop(name) M.running[name] = false end

    -- Exposed commands
    function M.StartAutoFarm() startLoop("AutoFarm", vehicle_autofarm_tick) end
    function M.StopAutoFarm() stopLoop("AutoFarm") end
    function M.StartCollectibles() startLoop("Collectibles", vehicle_collectibles_tick) end
    function M.StopCollectibles() stopLoop("Collectibles") end
    function M.StartOpenKit() startLoop("OpenKit", vehicle_openkit_tick) end
    function M.StopOpenKit() stopLoop("OpenKit") end
    function M.StartExtinguish() startLoop("Extinguish", vehicle_extinguish_tick) end
    function M.StopExtinguish() stopLoop("Extinguish") end
    function M.StartAutoSell() startLoop("AutoSell", vehicle_autosell_tick) end
    function M.StopAutoSell() stopLoop("AutoSell") end
    function M.StartDelivery() startLoop("Delivery", vehicle_delivery_tick) end
    function M.StopDelivery() stopLoop("Delivery") end
    function M.StartRace() startLoop("Race", vehicle_race_tick) end
    function M.StopRace() stopLoop("Race") end

    function M.ExposeConfig()
        return {
            { type="slider", name="Drive Speed", min=50, max=1200, current=M.settings.speed or 300, onChange=function(v) M.settings.speed = v end },
            { type="box", name="Min Stars", current=tostring(M.settings.stars or 0), onChange=function(v) M.settings.stars = tonumber(v) or 0 end },
            { type="box", name="Min Reward", current=tostring(M.settings.smaller or 0), onChange=function(v) M.settings.smaller = tonumber(v) or 0 end },
            { type="box", name="Max Reward", current=tostring(M.settings.bigger or 9999999), onChange=function(v) M.settings.bigger = tonumber(v) or 9999999 end }
        }
    end

    STATE.Modules.Vehicle = M
end

-- ===== Build_A_Boat_For_Treasure module (lightweight placeholder) =====
do
    local M = {}
    M.autoRunning = false
    function M.start() M.autoRunning=true; STATE.Flags.Build_A_Boat_For_Treasure=true; task.spawn(function()
            while M.autoRunning do SAFE_WAIT(1); -- placeholder pathing or treasure collection
                pcall(function() -- simple safe movement example
                    local char = Utils.SafeChar(); if char and char:FindFirstChild("HumanoidRootPart") then
                        -- small nudge to avoid AFK
                        char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0,0,0.01)
                    end
                end)
            end
        end) end
    function M.stop() M.autoRunning=false; STATE.Flags.Build_A_Boat_For_Treasure=false end
    function M.ExposeConfig()
        return {
            { type="toggle", name="Build_A_Boat_For_Treasure Auto", current=false, onChange=function(v) if v then M.start() else M.stop() end end}
        }
    end
    STATE.Modules.Build_A_Boat_For_Treasure = M
end

-- ===== NAMECALL HOOK (attempt, fallback safe) =====
do
    local okHook, mt = pcall(function() return getrawmetatable(game) end)
    if okHook and mt and type(mt.__namecall) == "function" then
        local old = mt.__namecall
        local canChange, _ = pcall(function() setreadonly(mt,false) end)
        if not canChange then
            warn("[G-MON] getrawmetatable setreadonly blocked on this executor; namecall hook disabled.")
        else
            local newfn = newcclosure or function(f) return f end
            local hookfn = newfn(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                -- capture interesting remotes safely
                if method == "FireServer" then
                    local nm = tostring(self.Name or "")
                    pcall(function()
                        if nm == "JobRemoteHandler" and type(args[1])=="table" and args[1].Action == "StartDeliveryJob" then
                            STATE.Remotes.JobRemoteHandler = args[1]
                        elseif nm == "StartLobby" then
                            STATE.Remotes.StartLobby = args
                            STATE.Remotes.RemoteStart = self
                        elseif nm == "Vote" and (tostring(args[2])=="Vote" or tostring(args[2])=="VoteRace") then
                            STATE.Remotes.Vote = args
                            STATE.Remotes.RemoteVote = self
                        elseif nm == "NPCHandler" and type(args[1])=="table" and args[1].Action == "DeclineOrder" then
                            return -- swallow decline to avoid accidental declines
                        end
                    end)
                elseif (method == "Raycast" or method == "Ray") and (STATE.Modules.Vehicle and STATE.Modules.Vehicle.raceOverride) then
                    -- optional modify raycast if race override on - safe: do not alter unless explicitly enabled
                end
                return old(self, ...)
            end)
            mt.__namecall = hookfn
            pcall(function() setreadonly(mt,true) end)
        end
    else
        warn("[G-MON] Could not access getrawmetatable; remote-capture features will be limited.")
    end
end

-- ===== RAYFIELD LOAD (safe fallback) =====
do
    local ok, Ray = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
    if ok and Ray then STATE.Rayfield = Ray else
        warn("[G-MON] Rayfield load failed; using fallback UI.")
        local Fallback = {}
        function Fallback:CreateWindow(args)
            local win = {}
            function win:CreateTab(name)
                local tab = {}
                function tab:CreateLabel() end
                function tab:CreateParagraph() end
                function tab:CreateButton(tbl) end
                function tab:CreateToggle(tbl) end
                function tab:CreateSlider(tbl) end
                return tab
            end
            function win:CreateNotification() end
            return win
        end
        function Fallback:Notify() end
        STATE.Rayfield = Fallback
    end
end

-- ===== STATUS GUI (draggable) =====
do
    local Status = {}
    function Status.Create()
        SAFE_CALL(function()
            local pg = LP:WaitForChild("PlayerGui")
            local sg = Instance.new("ScreenGui"); sg.Name = "GMonStatusGui"; sg.ResetOnSpawn=false; sg.Parent = pg
            local frame = Instance.new("Frame"); frame.Name="StatusFrame"; frame.Size=UDim2.new(0,320,0,170); frame.Position=UDim2.new(1,-330,0,10)
            frame.BackgroundTransparency=0.12; frame.BackgroundColor3=Color3.fromRGB(18,18,18); frame.BorderSizePixel=0; frame.Parent=sg
            local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,8); corner.Parent=frame
            local title=Instance.new("TextLabel"); title.Parent=frame; title.Size=UDim2.new(1,-16,0,24); title.Position=UDim2.new(0,8,0,6)
            title.BackgroundTransparency=1; title.Text="G-MON Status"; title.TextColor3=Color3.fromRGB(255,255,255); title.TextXAlignment=Enum.TextXAlignment.Left; title.Font=Enum.Font.SourceSansBold; title.TextSize=16
            local sub=Instance.new("TextLabel"); sub.Parent=frame; sub.Size=UDim2.new(1,-16,0,18); sub.Position=UDim2.new(0,8,0,30); sub.BackgroundTransparency=1
            sub.Text=Utils.ShortLabelForGame(STATE.GAME); sub.TextColor3=Color3.fromRGB(200,200,200); sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Font=Enum.Font.SourceSans; sub.TextSize=12
            local function makeLine(y)
                local holder=Instance.new("Frame"); holder.Parent=frame; holder.Size=UDim2.new(1,-16,0,20); holder.Position=UDim2.new(0,8,0,y); holder.BackgroundTransparency=1
                local dot=Instance.new("Frame"); dot.Parent=holder; dot.Size=UDim2.new(0,12,0,12); dot.Position=UDim2.new(0,0,0,4); dot.BackgroundColor3=Color3.fromRGB(200,0,0)
                local lbl=Instance.new("TextLabel"); lbl.Parent=holder; lbl.Size=UDim2.new(1,-18,1,0); lbl.Position=UDim2.new(0,18,0,0); lbl.BackgroundTransparency=1; lbl.Text=""
                lbl.TextColor3=Color3.fromRGB(230,230,230); lbl.Font=Enum.Font.SourceSans; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
                return {dot=dot, lbl=lbl}
            end
            local lines={}
            lines.runtime = makeLine(52); lines.bf = makeLine(74); lines.car = makeLine(96); lines.last = makeLine(118)
            lines.runtime.lbl.Text = "Runtime: 00h:00m:00s"; lines.bf.lbl.Text="Blox: OFF"; lines.car.lbl.Text="Vehicle: OFF"; lines.last.lbl.Text="Last: Idle"
            STATE.Status = { frame = frame, lines = lines }
            -- draggable
            local dragging, dragInput, startMousePos, startFramePos = false, nil, Vector2.new(0,0), Vector2.new(0,0)
            local function getMouse() return UIS:GetMouseLocation() end
            frame.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    dragging=true; dragInput=input; startMousePos=getMouse(); startFramePos=Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                    input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false; dragInput=nil end end)
                end
            end)
            frame.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end)
            UIS.InputChanged:Connect(function(input)
                if not dragging then return end
                if dragInput and input~=dragInput and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
                local mousePos = getMouse(); local delta = mousePos - startMousePos; local newAbs = startFramePos + delta
                local cam = workspace.CurrentCamera; local vp = (cam and cam.ViewportSize) or Vector2.new(800,600)
                local fw = frame.AbsoluteSize.X; local fh = frame.AbsoluteSize.Y
                newAbs = Vector2.new(math.clamp(newAbs.X, 0, math.max(0, vp.X - fw)), math.clamp(newAbs.Y, 0, math.max(0, vp.Y - fh)))
                frame.Position = UDim2.new(0, newAbs.X, 0, newAbs.Y)
            end)
        end)
    end
    function Status.UpdateRuntime() SAFE_CALL(function() if STATE.Status and STATE.Status.lines and STATE.Status.lines.runtime then STATE.Status.lines.runtime.lbl.Text = "Runtime: "..Utils.FormatTime(os.time()-STATE.StartTime) end end) end
    function Status.SetIndicator(name,on,text) SAFE_CALL(function() if not STATE.Status or not STATE.Status.lines or not STATE.Status.lines[name] then return end local ln = STATE.Status.lines[name]; if on then ln.dot.BackgroundColor3 = Color3.fromRGB(0,200,0) else ln.dot.BackgroundColor3 = Color3.fromRGB(200,0,0) end; if text then ln.lbl.Text = text end end) end
    STATE.Status = STATE.Status or {}; STATE.Status.Create = Status.Create; STATE.Status.UpdateRuntime = Status.UpdateRuntime; STATE.Status.SetIndicator = Status.SetIndicator
end

SAFE_CALL(function() if STATE.Status and STATE.Status.Create then STATE.Status.Create() end end)

-- ===== UI BUILD (Rayfield or fallback) =====
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
            Tabs.TabVehicle = STATE.Window:CreateTab("Vehicle")
            Tabs.Move = STATE.Window:CreateTab("Movement")
            Tabs.Debug = STATE.Window:CreateTab("Debug")
            Tabs.Scripts = STATE.Window:CreateTab("Scripts")
        else
            local function mt() return { CreateLabel=function() end, CreateParagraph=function() end, CreateButton=function() end, CreateToggle=function() end, CreateSlider=function() end, CreateBox=function() end, CreateDropdown=function() end } end
            Tabs.Info = mt(); Tabs.TabBlox = mt(); Tabs.TabVehicle = mt(); Tabs.Move = mt(); Tabs.Debug = mt(); Tabs.Scripts = mt()
        end
        STATE.Tabs = Tabs

        -- Info
        SAFE_CALL(function()
            Tabs.Info:CreateLabel("G-MON Hub - client-only. Use in private/testing places.")
            Tabs.Info:CreateParagraph({ Title="Detected", Content = Utils.ShortLabelForGame(STATE.GAME) })
            Tabs.Info:CreateButton({ Name="Detect Now", Callback=function()
                SAFE_CALL(function()
                    local det = Utils.FlexibleDetectByAliases()
                    if det and det ~= "UNKNOWN" then STATE.GAME = det; if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(det), Duration=3}) end
                    else if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: Unknown", Duration=3}) end end
                    STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
                    STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Vehicle: Available" or "Vehicle: N/A")
                    if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="UI ready — use tabs", Duration=3}) end
                end)
            end})
            Tabs.Info:CreateButton({ Name="Force Blox", Callback=function() STATE.GAME="BLOX_FRUIT"; STATE.Status.SetIndicator("bf", true, "Blox: Forced") end })
            Tabs.Info:CreateButton({ Name="Force Vehicle", Callback=function() STATE.GAME="CAR_TYCOON"; STATE.Status.SetIndicator("car", true, "Vehicle: Forced") end })
            Tabs.Info:CreateParagraph({ Title="Note", Content="Vehicle tab contains Dealer/Race/Delivery features. Do not run conflicting modules simultaneously." })
        end)

        -- Blox tab
        SAFE_CALL(function()
            local t = Tabs.TabBlox
            t:CreateLabel("Blox Fruit Controls")
            t:CreateToggle({ Name="Auto Farm (Blox)", CurrentValue=false, Callback=function(v) if v then SAFE_CALL(STATE.Modules.Blox.start) else SAFE_CALL(STATE.Modules.Blox.stop) end end })
            t:CreateToggle({ Name="Fast Attack", CurrentValue=STATE.Modules.Blox.config.fast_attack, Callback=function(v) STATE.Modules.Blox.config.fast_attack = v end })
            t:CreateToggle({ Name="Long Range Hit", CurrentValue=STATE.Modules.Blox.config.long_range, Callback=function(v) STATE.Modules.Blox.config.long_range = v end })
            t:CreateSlider({ Name="Range Farming (studs)", Range={1,50}, Increment=1, CurrentValue=STATE.Modules.Blox.config.range or 10, Callback=function(v) STATE.Modules.Blox.config.range = v end })
            t:CreateSlider({ Name="Attack Delay (ms)", Range={50,1000}, Increment=25, CurrentValue=math.floor((STATE.Modules.Blox.config.attack_delay or 0.35)*1000), Callback=function(v) STATE.Modules.Blox.config.attack_delay = v/1000 end })
        end)

        -- Vehicle tab (all features from your script converted to safe toggles)
        SAFE_CALL(function()
            local t = Tabs.TabVehicle
            t:CreateLabel("Vehicle / Dealership Controls")
            t:CreateBox({ Name="Drive Speed", Placeholder=tostring(STATE.VehicleSettings.speed), Callback=function(txt) STATE.VehicleSettings.speed = tonumber(txt) or STATE.VehicleSettings.speed end })
            t:CreateToggle({ Name="Auto Farm (Vehicle)", CurrentValue=false, Callback=function(v) if v then SAFE_CALL(STATE.Modules.Vehicle.StartAutoFarm) else SAFE_CALL(STATE.Modules.Vehicle.StopAutoFarm) end end })
            t:CreateToggle({ Name="Auto Collectibles", CurrentValue=false, Callback=function(v) if v then SAFE_CALL(STATE.Modules.Vehicle.StartCollectibles) else SAFE_CALL(STATE.Modules.Vehicle.StopCollectibles) end end })
            t:CreateToggle({ Name="Auto Open Kit", CurrentValue=false, Callback=function(v) if v then SAFE_CALL(STATE.Modules.Vehicle.StartOpenKit) else SAFE_CALL(STATE.Modules.Vehicle.StopOpenKit) end end })
            t:CreateToggle({ Name="Auto Extinguish Fire", CurrentValue=false, Callback=function(v) if v then SAFE_CALL(STATE.Modules.Vehicle.StartExtinguish) else SAFE_CALL(STATE.Modules.Vehicle.StopExtinguish) end end })
            t:CreateToggle({ Name="Auto Sell Cars", CurrentValue=false, Callback=function(v) if v then SAFE_CALL(STATE.Modules.Vehicle.StartAutoSell) else SAFE_CALL(STATE.Modules.Vehicle.StopAutoSell) end end })
            t:CreateToggle({ Name="Auto Delivery", CurrentValue=false, Callback=function(v) if v then SAFE_CALL(STATE.Modules.Vehicle.StartDelivery) else SAFE_CALL(STATE.Modules.Vehicle.StopDelivery) end end })
            t:CreateToggle({ Name="Auto Race (Start/Vote)", CurrentValue=false, Callback=function(v) if v then SAFE_CALL(STATE.Modules.Vehicle.StartRace) else SAFE_CALL(STATE.Modules.Vehicle.StopRace) end end })
            t:CreateButton({ Name="Force Spawn Delivery Job (FireServer)", Callback=function()
                SAFE_CALL(function() if STATE.Remotes.JobRemoteHandler and ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes.DealershipCustomerController and ReplicatedStorage.Remotes.DealershipCustomerController.JobRemoteHandler then
                    ReplicatedStorage.Remotes.DealershipCustomerController.JobRemoteHandler:FireServer(STATE.Remotes.JobRemoteHandler)
                end end)
            end })
        end)

        -- Movement tab (Fly) kept minimal
        SAFE_CALL(function()
            local t = Tabs.Move
            local flyEnabled=false; local flySpeed=60; local flyY=0
            t:CreateLabel("Movement")
            t:CreateToggle({ Name="Fly", Callback=function(v) flyEnabled = v end })
            t:CreateSlider({ Name="Fly Speed", Range={20,150}, Increment=5, CurrentValue=flySpeed, Callback=function(v) flySpeed = v end })
            t:CreateSlider({ Name="Fly Y", Range={-60,60}, Increment=1, CurrentValue=flyY, Callback=function(v) flyY = v end })
            RunService.RenderStepped:Connect(function()
                if not flyEnabled then return end
                SAFE_CALL(function()
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
            t:CreateButton({ Name="Force Start Blox", Callback=function() SAFE_CALL(STATE.Modules.Blox.start) end })
            t:CreateButton({ Name="Stop Blox", Callback=function() SAFE_CALL(STATE.Modules.Blox.stop) end })
            t:CreateButton({ Name="Stop All Vehicle Loops", Callback=function() SAFE_CALL(STATE.Modules.Vehicle.StopAutoFarm); SAFE_CALL(STATE.Modules.Vehicle.StopCollectibles); SAFE_CALL(STATE.Modules.Vehicle.StopOpenKit); SAFE_CALL(STATE.Modules.Vehicle.StopExtinguish); SAFE_CALL(STATE.Modules.Vehicle.StopAutoSell); SAFE_CALL(STATE.Modules.Vehicle.StopDelivery); SAFE_CALL(STATE.Modules.Vehicle.StopRace) end })
        end)

        -- Scripts tab (placeholder to expose Build_A_Boat_For_Treasure)
        SAFE_CALL(function()
            local t = Tabs.Scripts
            t:CreateLabel("Scripts / Extras")
            t:CreateToggle({ Name="Build_A_Boat_For_Treasure (Haruka renamed)", CurrentValue=false, Callback=function(v) if v then SAFE_CALL(STATE.Modules.Build_A_Boat_For_Treasure.start) else SAFE_CALL(STATE.Modules.Build_A_Boat_For_Treasure.stop) end end })
            t:CreateParagraph({ Title="Note", Content="Vehicle features adapted from your Dealership script and made safer. Some UIs/Remotes are game-dependent and may require minor adjustments."})
        end)
    end)
end

-- Apply Game & Status updater
local function ApplyGame(gameKey)
    STATE.GAME = gameKey or Utils.FlexibleDetectByAliases()
    SAFE_CALL(function()
        STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
        STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Vehicle: Available" or "Vehicle: N/A")
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected: "..Utils.ShortLabelForGame(STATE.GAME), Duration=3}) end
    end)
end

-- STATUS updater loop
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
        local det = Utils.FlexibleDetectByAliases(); STATE.GAME = det
        ApplyGame(STATE.GAME)
        -- Anti AFK
        if LP then
            LP.Idled:Connect(function() pcall(function() local cam = workspace.CurrentCamera if cam and cam.CFrame then VirtualUser:Button2Down(Vector2.new(0,0), cam.CFrame); task.wait(1); VirtualUser:Button2Up(Vector2.new(0,0), cam.CFrame) else VirtualUser:Button2Down(); task.wait(1); VirtualUser:Button2Up() end end) end)
        end
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use tabs to control modules", Duration=5}) end
        print("[G-MON] main.lua started. Detected game:", STATE.GAME)
    end)
    return true
end

return Main