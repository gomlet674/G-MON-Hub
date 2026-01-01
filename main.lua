--[[
  G-MON Hub - main_with_vexon_and_gmonextras.lua (Merged & Ready)
  - Core G-MON kept intact (Blox/Car/Boat modules preserved, unchanged)
  - Added VexonHub (key UI + loader helper) integrated into Scripts tab
  - Haruka module renamed to GMONExtras (AutoFarm + Gold Tracker)
  - Integrated VexonHub & GMONExtras into STATE.Modules and UI without altering core G-MON logic
  - NOTE: This script still calls remote loaders (game:HttpGet + loadstring). Remote execution is risky.
    If you want, I can produce a safe version that comments out remote load calls for offline inspection.
--]]

-- BOOTSTRAP
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local TextService = game:GetService("TextService")
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

-- UTILS & DETECTION
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
    if g == "CAR_TYCOON" then return "Car" end
    if g == "BUILD_A_BOAT" then return "Boat" end
    return tostring(g or "Unknown")
end

STATE.Modules.Utils = Utils

-- ===== MODULES (original G-MON kept) =====
-- Blox/Car/Boat modules kept intact (identical behavior). (BEGIN Blox module)
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

-- (BEGIN Car module)
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

    STATE.Modules.Car = M
end
-- (END Car module)

-- (BEGIN Boat module)
do
    local M = {}
    M.running = false
    M.delay = 1.5
    M._task = nil

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
-- (END Boat module)

-- ===== VEXON HUB module (integrated) =====
do
    local V = {}
    V.Name = "VexonHub"
    V.TrialFile = "VexonHubTrail.txt"
    V.MaxAttempts = 5
    V.KeyFile = "VexonHub_Key.txt"
    V.RemoteKeyURL1 = "https://raw.githubusercontent.com/TheVex0n/vexonhub-key/refs/heads/main/key.txt"
    V.RemoteKeyURL2 = "https://raw.githubusercontent.com/DiosDi/VexonHub/refs/heads/main/Key-VexonHub"
    V.LoaderURL = "https://raw.githubusercontent.com/DiosDi/VexonHub/main/Loader-VexonHub"

    -- UI refs
    V._gui = nil

    -- increment usage trail
    local function incrementTrail()
        local a = V.TrialFile
        local b = V.MaxAttempts
        local c = 0
        if isfile and readfile and isfile(a) then
            local d = readfile(a)
            c = tonumber(d) or 0
        end
        c = c + 1
        if writefile then pcall(function() writefile(a, tostring(c)) end) end
        return c
    end

    local function fetchRemoteKey(url)
        local ok, res = pcall(function() return game:HttpGet(url, true) end)
        if ok and res and res ~= "" then
            local s = res:gsub("^\239\187\191",""):gsub("^%s*(.-)%s*$","%1")
            return s
        end
        return nil
    end

    function V.CheckRemoteKeys()
        local k1 = fetchRemoteKey(V.RemoteKeyURL1)
        local k2 = fetchRemoteKey(V.RemoteKeyURL2)
        return k1, k2
    end

    function V.LoadLoaderSafe()
        -- loads remote loader; kept as original (remote execution risk)
        pcall(function()
            local body = game:HttpGet(V.LoaderURL)
            if body and body ~= "" then
                loadstring(body)()
            end
        end)
    end

    function V.ShowKeyUI()
        SAFE_CALL(function()
            -- Build UI only once
            if V._gui and V._gui.Parent then return end

            local c = incrementTrail()
            if c <= V.MaxAttempts then
                -- auto-load loader if under trial
                V.LoadLoaderSafe()
                return
            end

            local playerGui = LP:WaitForChild("PlayerGui")
            -- Black fade GUI
            local blackGui = Instance.new("ScreenGui")
            blackGui.Name = "VexonHub_BlackFadeGui"
            blackGui.IgnoreGuiInset = true
            blackGui.ResetOnSpawn = false
            blackGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
            blackGui.Parent = playerGui

            local frame = Instance.new("Frame")
            frame.BackgroundColor3 = Color3.new(0,0,0)
            frame.Size = UDim2.new(1,0,1,0)
            frame.Position = UDim2.new(0,0,0,0)
            frame.BackgroundTransparency = 0.0
            frame.BorderSizePixel = 0
            frame.ZIndex = 999999
            frame.Parent = blackGui

            local logo = Instance.new("ImageLabel")
            logo.Size = UDim2.new(0,100,0,100)
            logo.Position = UDim2.new(0.5,-50,0.5,-110)
            logo.BackgroundTransparency = 1
            logo.Image = "rbxassetid://84519376661277"
            logo.ImageTransparency = 0
            logo.ZIndex = 1000001
            logo.Parent = blackGui

            -- Key textbox GUI
            local keyGui = Instance.new("ScreenGui")
            keyGui.Name = "VexonHub_GlowingTextbox"
            keyGui.ResetOnSpawn = false
            keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
            keyGui.Parent = playerGui

            local function styleGuiText(x)
                x.BackgroundColor3 = Color3.fromRGB(0,0,0)
                x.TextColor3 = Color3.fromRGB(255,255,255)
                x.Font = Enum.Font.Gotham
                x.TextSize = 18
                x.ZIndex = 1000002
                x.TextTransparency = 0
                local y = Instance.new("UICorner", x)
                y.CornerRadius = UDim.new(0,12)
                local z = Instance.new("UIStroke", x)
                z.Thickness = 1
                z.Color = Color3.fromRGB(170,0,255)
                z.Transparency = 0.2
            end

            local txtBox = Instance.new("TextBox")
            txtBox.Name = "Vexon_KeyBox"
            txtBox.Parent = keyGui
            txtBox.Size = UDim2.new(0,210,0,30)
            txtBox.Position = UDim2.new(0.5, -105, 0.5, -25)
            txtBox.ClearTextOnFocus = true
            txtBox.Text = "Key In Discord for free"
            styleGuiText(txtBox)

            local btnGet = Instance.new("TextButton"); btnGet.Parent = keyGui; btnGet.Size = UDim2.new(0,100,0,30); btnGet.Position = UDim2.new(0.5, -105, 0.5, 20); btnGet.Text = "Get Key"; styleGuiText(btnGet)
            local btnCheck = Instance.new("TextButton"); btnCheck.Parent = keyGui; btnCheck.Size = UDim2.new(0,100,0,30); btnCheck.Position = UDim2.new(0.5, 5, 0.5, 20); btnCheck.Text = "Check Key"; styleGuiText(btnCheck)
            local btnClose = Instance.new("TextButton"); btnClose.Parent = keyGui; btnClose.Size = UDim2.new(0,15,0,15); btnClose.Position = UDim2.new(1, -275, 0, 145); btnClose.Text = "×"; styleGuiText(btnClose)
            local btnHelp = Instance.new("TextButton"); btnHelp.Parent = keyGui; btnHelp.Size = UDim2.new(0,15,0,15); btnHelp.Position = UDim2.new(1, -519, 0, 145); btnHelp.Text = "?"; styleGuiText(btnHelp)

            local gameList = Instance.new("TextLabel")
            gameList.Parent = keyGui
            gameList.Text = "VexonHub Supported Games..."
            gameList.TextColor3 = Color3.fromRGB(255,255,255)
            gameList.BackgroundTransparency = 1
            gameList.Font = Enum.Font.GothamBold
            gameList.TextSize = 18
            gameList.TextXAlignment = Enum.TextXAlignment.Left
            gameList.Size = UDim2.new(0,1000,0,30)
            gameList.Position = UDim2.new(1,0,0.85,0)
            gameList.ZIndex = 1000003

            -- copy invite
            btnGet.MouseButton1Click:Connect(function()
                local invite = "https://discord.gg/mdJKdwbKjE"
                pcall(function() setclipboard(invite) end)
                btnGet.Text = "Copied"
                task.wait(1.5)
                btnGet.Text = "Get Key"
            end)

            -- check key
            btnCheck.MouseButton1Click:Connect(function()
                local entered = txtBox.Text:gsub("^%s*(.-)%s*$","%1")
                local k1, k2 = V.CheckRemoteKeys()
                local ok = (k1 and entered == k1) or (k2 and entered == k2)
                if ok then
                    pcall(function() if writefile then writefile(V.KeyFile, entered) end end)
                    -- attempt to load loader (kept behavior)
                    pcall(function() V.LoadLoaderSafe() end)
                    -- cleanup GUIs
                    pcall(function()
                        if keyGui then keyGui:Destroy() end
                        if blackGui then blackGui:Destroy() end
                    end)
                else
                    btnCheck.Text = "Wrong"
                    task.wait(1.2)
                    btnCheck.Text = "Check Key"
                end
            end)

            btnClose.MouseButton1Click:Connect(function()
                pcall(function() if keyGui then keyGui:Destroy() end if blackGui then blackGui:Destroy() end end)
            end)

            V._gui = keyGui
        end)
    end

    function V.TryAutoLoadIfKeyPresent()
        SAFE_CALL(function()
            local hasFile = isfile and readfile and isfile(V.KeyFile)
            if hasFile then
                local q = readfile(V.KeyFile):gsub("^%s*(.-)%s*$","%1")
                local k1,k2 = V.CheckRemoteKeys()
                if q == k1 or q == k2 then
                    pcall(function() V.LoadLoaderSafe() end)
                    return true
                end
            end
            return false
        end)
    end

    function V.ExposeConfig()
        return {
            { type="button", name="Open Vexon Key UI", callback = function() V.ShowKeyUI() end },
            { type="button", name="Try Autoload (local key)", callback = function() V.TryAutoLoadIfKeyPresent() end }
        }
    end

    STATE.Modules.VexonHub = V
end

-- ===== GMONExtras module (formerly Haruka) =====
do
    local M = {}
    M.autoRunning = false
    M.goldRunning = false
    M._autoTask = nil
    M._goldGui = nil

    -- AutoFarm loop (copied/adapted)
    local function haruka_auto_loop(character)
        ::haruka_top::
        while M.autoRunning do
            if not character or not character.Parent then
                task.wait(1)
                character = game.Players.LocalPlayer and game.Players.LocalPlayer.Character or nil
                if not character then goto haruka_continue end
            end

            task.wait(1.24)
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1) goto haruka_continue end

            local velObj = Instance.new("BodyVelocity")
            velObj.Name = "_HarukaVel"
            velObj.Parent = hrp
            velObj.MaxForce = Vector3.new(0,0,0)
            pcall(function() velObj.Velocity = Vector3.new(0, -0.1, 0) end)

            pcall(function() hrp.CFrame = CFrame.new(-135.900,72,623.750) end)

            while hrp and hrp.CFrame and (hrp.CFrame.Z < 8600.75) and M.autoRunning do
                for i=1,50 do
                    if not M.autoRunning then break end
                    if hrp then pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0,0,0.3) end) end
                    task.wait()
                end
                task.wait()
            end

            if velObj and velObj.Parent then pcall(function() velObj:Destroy() end) end

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

            ::haruka_continue::
            task.wait(0.1)
        end
    end

    function M.startAutoFarm()
        if M.autoRunning then return end
        M.autoRunning = true
        STATE.Flags.GMONAuto = true
        local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character or nil
        if char then
            M._autoTask = task.spawn(function() haruka_auto_loop(char) end)
        else
            game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(2)
                if M.autoRunning then task.spawn(function() haruka_auto_loop(char) end) end
            end)
        end
    end

    function M.stopAutoFarm()
        M.autoRunning = false
        STATE.Flags.GMONAuto = false
        M._autoTask = nil
    end

    -- Gold Tracker (UI)
    local function create_gold_gui()
        local player = game.Players.LocalPlayer
        if not player then return nil end
        local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        local GoldGui = Instance.new("ScreenGui")
        GoldGui.Name = "GMON_GoldTracker"
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
        local texts = {"Start balance:", "Current balance:", "Earned:", "Runtime:"}
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
            local s = lbl.Text or ""
            local num = s:gsub("%s",""):gsub(",","")
            if num ~= "" and tonumber((num:gsub("[^0-9]",""))) then return lbl end
            local digits = num:match("(%d+)")
            if digits and tonumber(digits) then return lbl end
        end
        return nil
    end

    local function gold_loop(stateObj)
        if not stateObj then return end
        local player = game.Players.LocalPlayer
        local startLabel = nil
        local baseAmount = 0
        stateObj.Labels[1].Text = "0"
        stateObj.Labels[2].Text = "0"
        stateObj.Labels[3].Text = "0"
        stateObj.Labels[4].Text = "00:00"
        while M.goldRunning do
            local root = player and player:FindFirstChild("PlayerGui")
            if root then
                local found = nil
                -- game-specific path attempt
                if root:FindFirstChild("GoldGui") and root.GoldGui:FindFirstChild("Frame") then
                    local ok, frame = pcall(function() return root.GoldGui.Frame end)
                    if ok and frame then found = try_find_amount_label(frame) end
                end
                if not found then
                    for _, child in ipairs(root:GetDescendants()) do
                        if child:IsA("TextLabel") then
                            local txt = child.Text or ""
                            local num = (txt:gsub("%s",""):gsub("[^%d]",""))
                            if num ~= "" and tonumber(num) then found = child; break end
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
            task.wait(1)
        end
    end

    function M.startGoldTracker()
        if M.goldRunning then return end
        M.goldRunning = true
        STATE.Flags.GMONGold = true
        local obj = create_gold_gui()
        if obj then
            M._goldGui = obj
            task.spawn(function() gold_loop(obj) end)
        end
    end

    function M.stopGoldTracker()
        M.goldRunning = false
        STATE.Flags.GMONGold = false
        if M._goldGui and M._goldGui.Gui and M._goldGui.Gui.Parent then
            pcall(function() M._goldGui.Gui:Destroy() end)
        end
        M._goldGui = nil
    end

    function M.ExposeConfig()
        return {
            { type="toggle", name="GMON Auto Farm", current=false, onChange=function(v) if v then M.startAutoFarm() else M.stopAutoFarm() end end },
            { type="toggle", name="GMON Gold Tracker", current=false, onChange=function(v) if v then M.startGoldTracker() else M.stopGoldTracker() end end }
        }
    end

    STATE.Modules.GMONExtras = M
end

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

-- STATUS GUI (draggable)
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

-- UI BUILDING: create separate tabs per game (only once), plus Scripts (VexonHub & GMONExtras)
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
            Tabs.TabCar = STATE.Window:CreateTab("Car Tycoon")
            Tabs.TabBoat = STATE.Window:CreateTab("Build A Boat")
            Tabs.Move = STATE.Window:CreateTab("Movement")
            Tabs.Debug = STATE.Window:CreateTab("Debug")
            Tabs.Scripts = STATE.Window:CreateTab("Scripts") -- VexonHub & GMONExtras
        else
            local function makeTab()
                return { CreateLabel = function() end, CreateParagraph = function() end, CreateButton = function() end, CreateToggle = function() end, CreateSlider = function() end }
            end
            Tabs.Info = makeTab(); Tabs.TabBlox = makeTab(); Tabs.TabCar = makeTab(); Tabs.TabBoat = makeTab(); Tabs.Move = makeTab(); Tabs.Debug = makeTab(); Tabs.Scripts = makeTab()
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
            Tabs.Info:CreateButton({ Name = "Force Blox", Callback = function() STATE.GAME = "BLOX_FRUIT"; STATE.Status.SetIndicator("bf", true, "Blox: Forced"); if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Forced: Blox", Duration=2}) end end })
            Tabs.Info:CreateButton({ Name = "Force Car", Callback = function() STATE.GAME = "CAR_TYCOON"; STATE.Status.SetIndicator("car", true, "Car: Forced"); if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Forced: Car", Duration=2}) end end })
            Tabs.Info:CreateButton({ Name = "Force Boat", Callback = function() STATE.GAME = "BUILD_A_BOAT"; STATE.Status.SetIndicator("boat", true, "Boat: Forced"); if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Forced: Boat", Duration=2}) end end })
            Tabs.Info:CreateParagraph({ Title = "Note", Content = "Each game has its own tab. Use Force/Detect to update status. Features are separated to avoid duplicates." })
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

        -- CAR tab
        SAFE_CALL(function()
            local t = Tabs.TabCar
            t:CreateLabel("Car Tycoon Controls")
            t:CreateToggle({ Name = "Car AutoDrive", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Car.start) else SAFE_CALL(STATE.Modules.Car.stop) end end })
            t:CreateSlider({ Name = "Car Speed", Range = {20,200}, Increment = 5, CurrentValue = STATE.Modules.Car.speed or 60, Callback = function(v) STATE.Modules.Car.speed = v end })
        end)

        -- BOAT tab
        SAFE_CALL(function()
            local t = Tabs.TabBoat
            t:CreateLabel("Build A Boat Controls")
            t:CreateToggle({ Name = "Boat Auto Stages", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.Boat.start) else SAFE_CALL(STATE.Modules.Boat.stop) end end })
            t:CreateSlider({ Name = "Stage Delay (s)", Range = {0.5,6}, Increment = 0.5, CurrentValue = STATE.Modules.Boat.delay or 1.5, Callback = function(v) STATE.Modules.Boat.delay = v end })
        end)

        -- Movement tab
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
            t:CreateButton({ Name = "Force Start All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.start); SAFE_CALL(STATE.Modules.Car.start); SAFE_CALL(STATE.Modules.Boat.start) end })
            t:CreateButton({ Name = "Stop All Modules", Callback = function() SAFE_CALL(STATE.Modules.Blox.stop); SAFE_CALL(STATE.Modules.Car.stop); SAFE_CALL(STATE.Modules.Boat.stop) end })
        end)

        -- Scripts tab (VexonHub & GMONExtras)
        SAFE_CALL(function()
            local t = Tabs.Scripts
            t:CreateLabel("Script Picker / Extensions")
            t:CreateParagraph({ Title = "VexonHub", Content = "Key entry & loader for VexonHub." })
            t:CreateButton({ Name = "Open Vexon Key UI", Callback = function() SAFE_CALL(function() if STATE.Modules.VexonHub then STATE.Modules.VexonHub.ShowKeyUI() end end) end })
            t:CreateButton({ Name = "Try Vexon Autoload (local key)", Callback = function() SAFE_CALL(function() if STATE.Modules.VexonHub then STATE.Modules.VexonHub.TryAutoLoadIfKeyPresent() end end) end })
            t:CreateParagraph({ Title = "GMON Extras (formerly Haruka)", Content = "AutoFarm & Gold tracker integrated into GMON." })
            t:CreateToggle({ Name = "GMON Auto Farm", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.GMONExtras.startAutoFarm) else SAFE_CALL(STATE.Modules.GMONExtras.stopAutoFarm) end end })
            t:CreateToggle({ Name = "GMON Gold Tracker", CurrentValue = false, Callback = function(v) if v then SAFE_CALL(STATE.Modules.GMONExtras.startGoldTracker) else SAFE_CALL(STATE.Modules.GMONExtras.stopGoldTracker) end end })
            t:CreateButton({ Name = "Stop GMON Extras", Callback = function() SAFE_CALL(STATE.Modules.GMONExtras.stopAutoFarm); SAFE_CALL(STATE.Modules.GMONExtras.stopGoldTracker) end })
            t:CreateParagraph({ Title = "Note", Content = "VexonHub uses remote loader; GMON Extras moves your character. Use in private/testing environments." })
        end)
    end)
end

-- Apply Game (set status indicators and notify)
local function ApplyGame(gameKey)
    STATE.GAME = gameKey or Utils.FlexibleDetectByAliases()
    SAFE_CALL(function()
        STATE.Status.SetIndicator("bf", STATE.GAME=="BLOX_FRUIT", (STATE.GAME=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
        STATE.Status.SetIndicator("car", STATE.GAME=="CAR_TYCOON", (STATE.GAME=="CAR_TYCOON") and "Car: Available" or "Car: N/A")
        STATE.Status.SetIndicator("boat", STATE.GAME=="BUILD_A_BOAT", (STATE.GAME=="BUILD_A_BOAT") and "Boat: Available" or "Boat: N/A")
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

-- INITIALIZATION (lazy) - build UI & integrate modules
local Main = {}

function Main.Start()
    SAFE_CALL(function()
        buildUI()
        local det = Utils.FlexibleDetectByAliases()
        STATE.GAME = det
        ApplyGame(STATE.GAME)
        Utils.AntiAFK()
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use tabs to control modules (Scripts tab contains VexonHub & GMON Extras)", Duration=5}) end
        print("[G-MON] main_with_vexon_and_gmonextras started. Detected game:", STATE.GAME)
    end)
    return true
end

-- Auto-start (can be removed if you prefer manual start)
pcall(function() Main.Start() end)

-- Return Main for loader compatibility
return Main