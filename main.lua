--===========================================================
-- GMON HUB - FINAL (Blox Fruit + CDT + Build A Boat)
-- Combined single-file rebuild with Save/Load per-game profiles
-- Author: Rebuilt for user (educational)
--===========================================================

--// Libraries
local ok, OrionLib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
end)
if not ok or not OrionLib then
    warn("[GMON] Orion library failed to load. Script will try to continue with a minimal fallback UI.")
end

--// Services & Globals
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

--// Safe helpers
local function safe_pcall(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if not ok then warn("[GMON] safe_pcall:", res) end
    return ok, res
end

local function safe_wait(t)
    t = tonumber(t) or 0.1
    if t < 0.01 then t = 0.01 end
    if t > 5 then t = 5 end
    task.wait(t)
end

--// File helpers (writefile/readfile may not exist in all executors)
local function file_write(path, content)
    local ok, err = pcall(function() writefile(path, content) end)
    if not ok then return false, err end
    return true
end
local function file_read(path)
    local ok, res = pcall(function() return readfile(path) end)
    if not ok then return false, res end
    return true, res
end
local function file_exists(path)
    local ok, res = pcall(function() return isfile and isfile(path) end)
    if not ok then return false end
    return res
end

--// STATE
local GMON = {
    StartTime = os.time(),
    Modules = {},
    Flags = {},
    ProfilesFolder = "GMON_Profiles",
    UI = {}
}

-- ensure profiles folder exists for executors that support writefile/isfile
pcall(function()
    if makefolder and not isfolder(GMON.ProfilesFolder) then makefolder(GMON.ProfilesFolder) end
end)

--// Utilities
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
    safe_pcall(function()
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

-- Game detection helper
function Utils.DetectGame()
    local pid = game.PlaceId
    if pid == 2753915549 then return "BLOX_FRUIT" end
    if pid == 1554960397 then return "CAR_TYCOON" end
    if pid == 537413528 then return "BUILD_A_BOAT" end
    -- heuristic
    for _, obj in ipairs(Workspace:GetChildren()) do
        local n = tostring(obj.Name):lower()
        if string.find(n,"enemy") or string.find(n,"mob") or string.find(n,"monster") then return "BLOX_FRUIT" end
        if string.find(n,"car") or string.find(n,"vehicle") or string.find(n,"dealership") then return "CAR_TYCOON" end
        if string.find(n,"boat") or string.find(n,"stage") or string.find(n,"treasure") or string.find(n,"chest") then return "BUILD_A_BOAT" end
    end
    return "UNKNOWN"
end

-- Save / Load profiles (per-game)
local function profile_path(gameKey, name)
    name = name or "default"
    return GMON.ProfilesFolder .. "/" .. tostring(gameKey) .. "_" .. tostring(name) .. ".json"
end

local function save_profile(gameKey, name, tbl)
    local path = profile_path(gameKey, name)
    local ok, encoded = pcall(function() return HttpService:JSONEncode(tbl) end)
    if not ok then return false, "encode failed" end
    local ok2, err = file_write(path, encoded)
    if not ok2 then return false, err end
    return true
end

local function load_profile(gameKey, name)
    local path = profile_path(gameKey, name)
    local exists = pcall(function() return isfile and isfile(path) end)
    if exists and (isfile and isfile(path)) then
        local ok, txt = file_read(path)
        if not ok then return nil, "read failed" end
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(txt) end)
        if not ok2 then return nil, "decode failed" end
        return decoded
    end
    return nil, "no file"
end

-- ServerHop / Rejoin
local function rejoin()
    pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
end

local function serverhop()
    pcall(function()
        if not HttpService.HttpEnabled then error("HttpService disabled") end
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        local resp = HttpService:GetAsync(url)
        local data = HttpService:JSONDecode(resp)
        if data and data.data then
            for _, srv in ipairs(data.data) do
                if srv.playing and (srv.playing < (srv.maxPlayers or 0)) and srv.id then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                    return
                end
            end
        end
        rejoin()
    end)
end

-- GodMode module
local GodMode = {}
GodMode.Enabled = false
GodMode._task = nil
function GodMode.set(on)
    GodMode.Enabled = on
    if on then
        if GodMode._task then return end
        GodMode._task = task.spawn(function()
            while GodMode.Enabled do
                local char = Utils.SafeChar()
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
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
            GodMode._task = nil
        end)
    else
        GodMode._task = nil
    end
end

-- AntiAFK
Utils.AntiAFK()

--===========================================================
-- MODULE: Blox Fruit
--===========================================================
do
    local M = {}
    M.config = { attack_delay = 0.35, range = 12, long_range = false, fast_attack = false, auto_stats = false, stat_choice = "Melee" }
    M.running = false
    M._task = nil

    local function findEnemyFolder()
        local hints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","EnemiesFolder","NPCs"}
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
                    if ok then
                        local d = (pos - hrp.Position).Magnitude
                        if d < bestDist and d <= (M.config.range or 12) then bestDist, best = d, mob end
                    end
                end
            end
        end
        return best
    end

    local function attackLoop()
        while M.running do
            task.wait(0.12)
            safe_pcall(function()
                if not M.running then return end
                local char = Utils.SafeChar()
                if not char then return end
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
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true
        GMON.Flags.Blox = true
        M._task = task.spawn(attackLoop)
    end

    function M.stop()
        M.running = false
        GMON.Flags.Blox = false
        M._task = nil
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Range", min=2, max=60, current=M.config.range, onChange=function(v) M.config.range = v end },
            { type="toggle", name="Fast Attack", current=M.config.fast_attack, onChange=function(v) M.config.fast_attack = v end },
            { type="toggle", name="Auto Upgrade Stats", current=M.config.auto_stats, onChange=function(v) M.config.auto_stats = v end },
            { type="dropdown", name="Stat to Auto", options={"Melee","Defense","Sword","Demon Fruit","Gun"}, current=M.config.stat_choice, onChange=function(v) M.config.stat_choice = v end }
        }
    end

    GMON.Modules.Blox = M
end

--===========================================================
-- MODULE: Car Dealership Tycoon (CDT)
--===========================================================
do
    local M = {}
    M.running = false
    M.speed = 80
    M.chosen = nil
    M._task = nil
    M.auto_buy_limited = false
    M.auto_drive = false
    M.SelectedCar = nil

    -- guess cars root
    local function guessCarsRoot()
        local hints = {"Cars","Vehicles","Dealership","VehiclesFolder","CarShop","CarsFolder"}
        for _, name in ipairs(hints) do
            local f = Workspace:FindFirstChild(name)
            if f then return f end
        end
        return Workspace
    end

    local function isPlayerOwned(model)
        if not model then return false end
        if tostring(model.Name) == tostring(LP.Name) then return true end
        local ok, owner = pcall(function()
            local o = model:FindFirstChild("Owner") or model:FindFirstChild("OwnerName")
            if o and o.Value then return tostring(o.Value) end
            if model.GetAttribute then return model:GetAttribute("Owner") end
            return nil
        end)
        if ok and owner and tostring(owner) == tostring(LP.Name) then return true end
        local ok2, uid = pcall(function()
            local v = model:FindFirstChild("OwnerUserId") or model:FindFirstChild("UserId")
            if v and v.Value then return tonumber(v.Value) end
            if model.GetAttribute then return model:GetAttribute("OwnerUserId") end
            return nil
        end)
        if ok2 and tonumber(uid) and tonumber(uid) == LP.UserId then return true end
        return false
    end

    local function chooseOwnCar()
        local root = guessCarsRoot()
        local candidates = {}
        for _, m in ipairs(root:GetDescendants()) do
            if m:IsA("Model") and m.PrimaryPart then
                if isPlayerOwned(m) then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then
            for _, m in ipairs(root:GetChildren()) do
                if m:IsA("Model") and m.PrimaryPart and #m:GetDescendants() > 5 then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then return nil end
        table.sort(candidates, function(a,b) return #a:GetDescendants() > #b:GetDescendants() end)
        return candidates[1]
    end

    local function ensureLinearVelocity(part)
        if not part then return nil end
        local att = part:FindFirstChild("_GmonAttach")
        if not att then att = Instance.new("Attachment"); att.Name = "_GmonAttach"; att.Parent = part end
        local lv = part:FindFirstChild("_GmonLV")
        if not lv then
            lv = Instance.new("LinearVelocity")
            lv.Name = "_GmonLV"
            lv.Attachment0 = att
            lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
            lv.MaxForce = math.huge
            lv.Parent = part
        end
        return lv
    end

    local function driveLoop()
        while M.running do
            task.wait(0.2)
            safe_pcall(function()
                if not M.running then return end
                local car = M.chosen
                if (not car) or (not car.PrimaryPart) then
                    car = chooseOwnCar()
                    if not car then GMON.Flags.Car = false; return end
                    M.chosen = car
                    if not car:FindFirstChild("_GmonStartPos") and car.PrimaryPart then
                        local cv = Instance.new("CFrameValue")
                        cv.Name = "_GmonStartPos"
                        cv.Value = car.PrimaryPart.CFrame
                        cv.Parent = car
                    end
                end
                if car and car.PrimaryPart then
                    local lv = ensureLinearVelocity(car.PrimaryPart)
                    if lv then lv.VectorVelocity = car.PrimaryPart.CFrame.LookVector * (M.speed or 80) end
                end
            end)
        end
    end

    -- Auto-buy 'Limited' cars: tries common remote path; you must adapt to private game's remote names
    local function try_auto_buy_limited()
        -- common remote names that games use
        local remotes = {}
        pcall(function() for _,v in ipairs(game:GetDescendants()) do if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then table.insert(remotes, v) end end end)
        -- naive scan: try to find "BuyCar" remote
        for _, r in ipairs(remotes) do
            if tostring(r.Name):lower():find("buy") or tostring(r.Name):lower():find("purchase") then
                -- attempt to call/FireServer for each limited car found in ReplicatedStorage.Cars (if present)
                local repo = game:GetService("ReplicatedStorage"):FindFirstChild("Cars")
                if repo then
                    for _, car in ipairs(repo:GetChildren()) do
                        local isLimited = false
                        pcall(function() isLimited = car:GetAttribute("IsLimited") == true end)
                        if isLimited then
                            pcall(function()
                                if r:IsA("RemoteEvent") then r:FireServer(car.Name) end
                                if r:IsA("RemoteFunction") then r:InvokeServer(car.Name) end
                            end)
                        end
                    end
                end
            end
        end
    end

    function M.start()
        if M.running then return end
        M.running = true
        GMON.Flags.Car = true
        M._task = task.spawn(driveLoop)
    end

    function M.stop()
        M.running = false
        GMON.Flags.Car = false
        if M.chosen and M.chosen.PrimaryPart then
            safe_pcall(function()
                local prim = M.chosen.PrimaryPart
                local lv = prim:FindFirstChild("_GmonLV"); if lv then pcall(function() lv:Destroy() end) end
                local att = prim:FindFirstChild("_GmonAttach"); if att then pcall(function() att:Destroy() end) end
                local tag = M.chosen:FindFirstChild("_GmonStartPos")
                if tag and tag:IsA("CFrameValue") and M.chosen.PrimaryPart then pcall(function() M.chosen:SetPrimaryPartCFrame(tag.Value) end); pcall(function() tag:Destroy() end) end
            end)
        end
        M.chosen = nil
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Car Speed", min=20, max=200, current=M.speed, onChange=function(v) M.speed = v end },
            { type="toggle", name="Auto Buy Limited", current=false, onChange=function(v) M.auto_buy_limited = v end },
            { type="toggle", name="Auto Drive (while seated)", current=false, onChange=function(v) M.auto_drive = v end }
        }
    end

    GMON.Modules.Car = M
end

--===========================================================
-- MODULE: Build A Boat (BABFT)
--===========================================================
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
    M.PlacePartFunction = nil  -- user should provide if they want AutoBuild to work with their game's remote

    local function collectStageParts()
        local out = {}
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = string.lower(v.Name or "")
                if string.find(n,"stage") or string.find(n,"black") or string.find(n,"trigger") or string.find(n,"dark") then
                    table.insert(out, v)
                end
            end
        end
        return out
    end

    local function autoStageLoop()
        while M.running do
            task.wait(0.2)
            safe_pcall(function()
                if not M.running then return end
                local char = Utils.SafeChar()
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local parts = collectStageParts()
                if #parts == 0 then
                    for _,v in ipairs(Workspace:GetDescendants()) do
                        if v:IsA("BasePart") and string.match(string.lower(v.Name or ""),"stage") then table.insert(parts, v) end
                    end
                end
                table.sort(parts, function(a,b) return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude end)
                for _,p in ipairs(parts) do
                    if not M.running then break end
                    if p and p.Parent then pcall(function() hrp.CFrame = p.CFrame * CFrame.new(0,3,0) end) end
                    safe_wait(M.delay)
                end
                -- chest search
                local candidate = nil
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then local ln = string.lower(v.Name or ""); if string.find(ln, "chest") or string.find(ln, "treasure") or string.find(ln, "gold") then candidate = v; break end
                    elseif v:IsA("Model") and v.PrimaryPart then local ln = string.lower(v.Name or ""); if string.find(ln, "chest") or string.find(ln, "treasure") or string.find(ln, "gold") then candidate = v.PrimaryPart; break end
                    end
                end
                if candidate then pcall(function() hrp.CFrame = candidate.CFrame * CFrame.new(0,3,0) end) end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true
        GMON.Flags.Boat = true
        M._task = task.spawn(autoStageLoop)
    end

    function M.stop()
        M.running = false
        GMON.Flags.Boat = false
        M._task = nil
    end

    function M.TeleportToPreset(name)
        local preset = M.teleports[name]
        if not preset then warn("Preset not found:", name) return end
        local char = Utils.SafeChar()
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.CFrame = preset end)
        end
    end

    function M.AutoBuildOnce(partNameList)
        local char = Utils.SafeChar()
        if not char then return false, "No character" end
        if not M.PlacePartFunction or type(M.PlacePartFunction) ~= "function" then
            return false, "No PlacePartFunction hook defined. Set GMON.Modules.Boat.PlacePartFunction to your remote invoker."
        end
        local basePos = (char.PrimaryPart and char.PrimaryPart.CFrame) or CFrame.new(0,5,0)
        for i, pname in ipairs(partNameList or {}) do
            local pos = basePos * CFrame.new(0, 0, 2 * i)
            local ok, err = pcall(function()
                local res = M.PlacePartFunction(pname, pos)
                if res == false then error("Place failed for "..tostring(pname)) end
            end)
            if not ok then
                warn("[GMON AutoBuild] failed placing", pname, err)
            end
            safe_wait(0.15)
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

--===========================================================
-- GOLD TRACKER (Generic)
--===========================================================
do
    local GT = {}
    GT.running = false
    GT.gui = nil

    local function create_gui()
        local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui")
        local sg = Instance.new("ScreenGui")
        sg.Name = "GMON_GoldTracker"
        sg.ResetOnSpawn = false
        sg.Parent = pg

        local frame = Instance.new("Frame", sg)
        frame.Size = UDim2.new(0, 280, 0, 140)
        frame.Position = UDim2.new(0, 10, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
        frame.BorderSizePixel = 0
        local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)

        local rows = { "Start:", "Current:", "Gained:", "Time:" }
        local labels = {}
        for i, txt in ipairs(rows) do
            local r = Instance.new("TextLabel", frame)
            r.Size = UDim2.new(0.9,0,0,24)
            r.Position = UDim2.new(0.05,0,0, 8 + (i-1)*30)
            r.BackgroundTransparency = 1
            r.TextColor3 = Color3.fromRGB(220,220,220)
            r.Font = Enum.Font.SourceSans
            r.Text = txt .. " 0"
            labels[i] = r
        end

        return { Gui = sg, Frame = frame, Labels = labels, StartTime = os.time() }
    end

    local function find_numeric_label(root)
        if not root then return nil end
        if root:IsA("TextLabel") then
            local txt = tostring(root.Text):gsub("%%D",""):gsub("%s","")
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
        local foundLabel = nil
        local startAmt = 0
        local gained = 0
        while GT.running do
            if not foundLabel or not foundLabel.Parent then
                if playerGui:FindFirstChild("GoldGui") and playerGui.GoldGui:FindFirstChild("Frame") then
                    foundLabel = find_numeric_label(playerGui.GoldGui.Frame)
                else
                    foundLabel = find_numeric_label(playerGui)
                end
                if foundLabel then startAmt = tonumber((foundLabel.Text:gsub("[^%d]",""))) or 0 end
            end

            if foundLabel then
                local cur = tonumber((foundLabel.Text:gsub("[^%d]",""))) or 0
                if cur > startAmt then
                    gained = gained + (cur - startAmt)
                    startAmt = cur
                elseif cur < startAmt then
                    startAmt = cur
                end
                guiobj.Labels[2].Text = "Current: " .. tostring(cur)
                guiobj.Labels[3].Text = "Gained: " .. tostring(gained)
            end

            local elapsed = os.time() - guiobj.StartTime
            guiobj.Labels[4].Text = "Time: " .. string.format("%02d:%02d", math.floor(elapsed/60), elapsed%60)
            task.wait(1)
        end
    end

    function GT.start()
        if GT.running then return end
        GT.running = true
        local obj = create_gui()
        GT.gui = obj
        task.spawn(function() loop(obj) end)
    end

    function GT.stop()
        GT.running = false
        if GT.gui and GT.gui.Gui and GT.gui.Gui.Parent then pcall(function() GT.gui.Gui:Destroy() end) end
        GT.gui = nil
    end

    GMON.Modules.GoldTracker = GT
end

--===========================================================
-- UI BUILD (Orion if available, fallback minimal)
--===========================================================
local WindowAPI = nil
if OrionLib and OrionLib.MakeWindow then
    WindowAPI = Window
else
    -- minimal fallback UI using simple ScreenGui controls
    WindowAPI = nil
    warn("[GMON] Orion not available. UI will be minimal and non-interactive for some features.")
end

-- Create Tabs and controls (Orion)
local Tabs = {}
if WindowAPI then
    -- Settings tab (save/load profiles)
    Tabs.Settings = WindowAPI:MakeTab({ Name = "Settings" })
    Tabs.Info = WindowAPI:MakeTab({ Name = "Info" })
    Tabs.Blox = WindowAPI:MakeTab({ Name = "Blox Fruit" })
    Tabs.CDT = WindowAPI:MakeTab({ Name = "Car Tycoon" })
    Tabs.Boat = WindowAPI:MakeTab({ Name = "Build A Boat" })
    Tabs.System = WindowAPI:MakeTab({ Name = "System" })

    -- Save/Load UI - per game
    Tabs.Settings:AddSection({ Name = "Profiles (Save / Load per game)" })
    local selectedGame = Utils.DetectGame()
    local profileName = "default"

    Tabs.Settings:AddDropdown({
        Name = "Select Game",
        Default = selectedGame,
        Options = {"BLOX_FRUIT","CAR_TYCOON","BUILD_A_BOAT"},
        Callback = function(val) selectedGame = val end
    })

    Tabs.Settings:AddTextbox({
        Name = "Profile Name",
        Default = "default",
        TextDisappear = false,
        Callback = function(val) profileName = tostring(val) end
    })

    Tabs.Settings:AddButton({
        Name = "Save Profile",
        Callback = function()
            local pk = selectedGame
            local data = {}
            if pk == "BLOX_FRUIT" then data = GMON.Modules.Blox and GMON.Modules.Blox.config or {} end
            if pk == "CAR_TYCOON" then data = { speed = GMON.Modules.Car and GMON.Modules.Car.speed or 80, auto_buy = GMON.Modules.Car and GMON.Modules.Car.auto_buy_limited or false } end
            if pk == "BUILD_A_BOAT" then data = { delay = GMON.Modules.Boat and GMON.Modules.Boat.delay or 1.2 } end
            local ok, err = save_profile(pk, profileName, data)
            if ok then OrionLib:MakeNotification({Name="GMON",Content="Saved profile: "..profileName,Time=3}) else OrionLib:MakeNotification({Name="GMON",Content="Save failed: "..tostring(err),Time=4}) end
        end
    })

    Tabs.Settings:AddButton({
        Name = "Load Profile",
        Callback = function()
            local pk = selectedGame
            local data, err = load_profile(pk, profileName)
            if not data then OrionLib:MakeNotification({Name="GMON",Content="Load failed: "..tostring(err),Time=4}); return end
            -- apply data to modules
            if pk == "BLOX_FRUIT" and GMON.Modules.Blox then
                for k,v in pairs(data) do GMON.Modules.Blox.config[k] = v end
            elseif pk == "CAR_TYCOON" and GMON.Modules.Car then
                if data.speed then GMON.Modules.Car.speed = data.speed end
                if data.auto_buy ~= nil then GMON.Modules.Car.auto_buy_limited = data.auto_buy end
            elseif pk == "BUILD_A_BOAT" and GMON.Modules.Boat then
                if data.delay then GMON.Modules.Boat.delay = data.delay end
            end
            OrionLib:MakeNotification({Name="GMON",Content="Profile loaded: "..profileName,Time=3})
        end
    })

    -- Info tab
    Tabs.Info:AddParagraph({ Title = "GMON HUB", Content = "Combined hub: Blox Fruit | Car Tycoon | Build A Boat\nUse profiles to save per-game settings."})
    Tabs.Info:AddToggle({ Name = "Gold Tracker (cross-game)", Default = false, Callback = function(v) if v then GMON.Modules.GoldTracker.start() else GMON.Modules.GoldTracker.stop() end end })

    -- Blox tab controls
    Tabs.Blox:AddSection({ Name = "Blox Fruit" })
    Tabs.Blox:AddToggle({ Name = "Auto Farm (Blox)", Default = false, Callback = function(v) if v then GMON.Modules.Blox.start() else GMON.Modules.Blox.stop() end end })
    Tabs.Blox:AddToggle({ Name = "Fast Attack", Default = false, Callback = function(v) GMON.Modules.Blox.config.fast_attack = v end })
    Tabs.Blox:AddSlider({ Name = "Range (studs)", Min = 2, Max = 60, Default = GMON.Modules.Blox.config.range, Increment = 1, Callback = function(v) GMON.Modules.Blox.config.range = v end })
    Tabs.Blox:AddToggle({ Name = "Auto Upgrade Stats", Default = GMON.Modules.Blox.config.auto_stats, Callback = function(v) GMON.Modules.Blox.config.auto_stats = v end })
    Tabs.Blox:AddDropdown({ Name = "Stat to Auto", Default = GMON.Modules.Blox.config.stat_choice or "Melee", Options = {"Melee","Defense","Sword","Demon Fruit","Gun"}, Callback = function(v) GMON.Modules.Blox.config.stat_choice = v end })

    -- CDT tab
    Tabs.CDT:AddSection({ Name = "Car Dealership Tycoon" })
    Tabs.CDT:AddToggle({ Name = "AutoDrive (module)", Default = false, Callback = function(v) if v then GMON.Modules.Car.start() else GMON.Modules.Car.stop() end end })
    Tabs.CDT:AddSlider({ Name = "Car Speed", Min = 20, Max = 200, Default = GMON.Modules.Car and GMON.Modules.Car.speed or 80, Increment = 5, Callback = function(v) if GMON.Modules.Car then GMON.Modules.Car.speed = v end end })
    Tabs.CDT:AddToggle({ Name = "Auto Buy Limited", Default = false, Callback = function(v) if GMON.Modules.Car then GMON.Modules.Car.auto_buy_limited = v; if v then task.spawn(function() while GMON.Modules.Car.auto_buy_limited do safe_pcall(function() -- try buy loop
                -- try_auto_buy_limited is internal; call lightly
                pcall(function() -- best-effort buy
                    -- use simple remote name heuristics
                    local repo = game:GetService("ReplicatedStorage"):FindFirstChild("Cars")
                    if repo then
                        for _, car in ipairs(repo:GetChildren()) do
                            local ok, isLimited = pcall(function() return car:GetAttribute("IsLimited") == true end)
                            if ok and isLimited then
                                pcall(function() -- try Buy remote
                                    local buy = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("BuyCar")
                                    if buy and buy:IsA("RemoteEvent") then buy:FireServer(car.Name) end
                                end)
                            end
                        end
                    end
                end) end) task.wait(3) end end) end end end })
    Tabs.CDT:AddButton({ Name = "Choose Player Car (info)", Callback = function() local chosen = GMON.Modules.Car.choosePlayerFastestCar and GMON.Modules.Car.choosePlayerFastestCar() or GMON.Modules.Car.chosen if chosen then OrionLib:MakeNotification({Name="GMON",Content="Chosen car: "..tostring(chosen.Name),Time=3}) else OrionLib:MakeNotification({Name="GMON",Content="No car found",Time=3}) end end })

    -- Boat tab
    Tabs.Boat:AddSection({ Name = "Build A Boat" })
    Tabs.Boat:AddToggle({ Name = "Auto Stages (module)", Default = false, Callback = function(v) if v then GMON.Modules.Boat.start() else GMON.Modules.Boat.stop() end end })
    Tabs.Boat:AddSlider({ Name = "Stage Delay (s)", Min = 0.2, Max = 6, Default = GMON.Modules.Boat.delay or 1.2, Increment = 0.1, Callback = function(v) if GMON.Modules.Boat then GMON.Modules.Boat.delay = v end end })
    Tabs.Boat:AddButton({ Name = "Teleport: Build Area", Callback = function() GMON.Modules.Boat.TeleportToPreset("build_area") end })
    Tabs.Boat:AddButton({ Name = "Teleport: Spawn", Callback = function() GMON.Modules.Boat.TeleportToPreset("spawn") end })
    Tabs.Boat:AddButton({ Name = "Auto Build Demo (Block, Wheel, Cannon)", Callback = function() local ok, msg = GMON.Modules.Boat.AutoBuildOnce({"Block","Wheel","Cannon"}); OrionLib:MakeNotification({Name="GMON",Content=tostring(ok).." "..tostring(msg),Time=3}) end })

    -- System tab
    Tabs.System:AddSection({ Name = "System" })
    Tabs.System:AddToggle({ Name = "Anti-AFK", Default = true, Callback = function(v) if v then Utils.AntiAFK() end end })
    Tabs.System:AddToggle({ Name = "God Mode", Default = false, Callback = function(v) GodMode.set(v) end })
    Tabs.System:AddButton({ Name = "Rejoin", Callback = function() rejoin() end })
    Tabs.System:AddButton({ Name = "Server Hop", Callback = function() serverhop() end })
    Tabs.System:AddLabel("Runtime:") 
    local runtimeLabel = Tabs.System:AddLabel("00:00:00")
    -- runtime updater
    task.spawn(function()
        while task.wait(1) do
            if runtimeLabel and runtimeLabel.Set then
                -- Orion label doesn't have Set method; instead we will update by creating new label? Simple: use notification or skip
            end
        end
    end)
else
    -- no Orion: minimal notifications & auto start detection
    warn("[GMON] Orion not loaded. UI features limited (profiles may still save if executor supports files).")
end

--===========================================================
-- STATUS GUI (draggable simple overlay) - independent from Orion
--===========================================================
do
    local sg = Instance.new("ScreenGui")
    sg.Name = "GMonStatusGui"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = LP:WaitForChild("PlayerGui") end)

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 320, 0, 120)
    frame.Position = UDim2.new(1,-330,0,10)
    frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,-16,0,24); title.Position = UDim2.new(0,8,0,6)
    title.BackgroundTransparency = 1; title.Font = Enum.Font.SourceSansBold; title.TextSize = 15; title.TextColor3 = Color3.fromRGB(240,240,240)
    title.Text = "G-MON HUB"

    local runtime = Instance.new("TextLabel", frame); runtime.Size=UDim2.new(1,-16,0,18); runtime.Position=UDim2.new(0,8,0,34); runtime.BackgroundTransparency=1; runtime.Font=Enum.Font.SourceSans; runtime.TextSize=12; runtime.TextColor3=Color3.new(0.8,0.8,0.8); runtime.Text="Runtime: 00:00:00"
    local info_blox = Instance.new("TextLabel", frame); info_blox.Size=UDim2.new(1,-16,0,16); info_blox.Position=UDim2.new(0,8,0,54); info_blox.BackgroundTransparency=1; info_blox.Font=Enum.Font.SourceSans; info_blox.TextSize=12; info_blox.TextColor3=Color3.fromRGB(200,200,200)
    info_blox.Text = "Blox: OFF"
    local info_car = Instance.new("TextLabel", frame); info_car.Size=UDim2.new(1,-16,0,16); info_car.Position=UDim2.new(0,8,0,72); info_car.BackgroundTransparency=1; info_car.Font=Enum.Font.SourceSans; info_car.TextSize=12; info_car.TextColor3=Color3.fromRGB(200,200,200); info_car.Text="Car: OFF"
    local info_boat = Instance.new("TextLabel", frame); info_boat.Size=UDim2.new(1,-16,0,16); info_boat.Position=UDim2.new(0,8,0,90); info_boat.BackgroundTransparency=1; info_boat.Font=Enum.Font.SourceSans; info_boat.TextSize=12; info_boat.TextColor3=Color3.fromRGB(200,200,200); info_boat.Text="Boat: OFF"

    -- update loop
    task.spawn(function()
        while true do
            safe_wait(1)
            pcall(function()
                runtime.Text = "Runtime: " .. Utils.FormatTime(os.time() - GMON.StartTime)
                info_blox.Text = "Blox: " .. (GMON.Flags.Blox and "ON" or "OFF")
                info_car.Text = "Car: " .. (GMON.Flags.Car and "ON" or "OFF")
                info_boat.Text = "Boat: " .. (GMON.Flags.Boat and "ON" or "OFF")
            end)
        end
    end)
end

--===========================================================
-- MAIN START
--===========================================================
local Main = {}

function Main.Start()
    -- detect game and notify
    local detected = Utils.DetectGame()
    pcall(function()
        if OrionLib and OrionLib.MakeNotification then
            OrionLib:MakeNotification({Name="GMON", Content="Loaded. Detected: "..tostring(detected), Time=4})
        else
            pcall(function() StarterGui:SetCore("SendNotification", {Title="GMON", Text="Loaded. Detected: "..tostring(detected), Duration=4}) end)
        end
    end)
    return true
end

-- expose modules & save/load helpers
Main.GMON = GMON
Main.Utils = Utils
Main.SaveProfile = save_profile
Main.LoadProfile = load_profile
Main.Rejoin = rejoin
Main.ServerHop = serverhop

-- auto-start minimal useful things
Utils.AntiAFK()
-- Do not auto-start auto-farming modules by default. User toggles via UI.

return Main