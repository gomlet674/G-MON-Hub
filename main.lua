--[[
  G-MON Hub - main.lua (Single-file, Full, Fixed)
  - Single-file heavy script (lazy staged load)
  - Rayfield GUI (with fallback)
  - Status GUI (draggable)
  - AntiAFK
  - Modules: Blox, Car, Boat
  - Auto-start per game (safe)
  - LinearVelocity for car simulation
  - SAFE_CALL wrapper to avoid nil-call errors
--]]

-- ===== BOOTSTRAP =====
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
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
    if sec > 2 then sec = 2 end
    task.wait(sec)
end

-- ===== STATE =====
local STATE = {
    Modules = {},   -- modules table: Blox, Car, Boat
    Active = {},    -- handles for loops
    StartTime = os.time(),
    GAME = "UNKNOWN",
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    Status = nil,
}

-- ===== GAME DETECTION =====
do
    local pid = game.PlaceId
    if pid == 2753915549 then
        STATE.GAME = "BLOX_FRUIT"
    elseif pid == 1554960397 then
        STATE.GAME = "CAR_TYCOON"
    elseif pid == 537413528 then
        STATE.GAME = "BUILD_A_BOAT"
    else
        STATE.GAME = "UNKNOWN"
    end
end

-- ===== UTILS (module-like helpers) =====
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
                    -- fallback (some executors accept)
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

STATE.Modules.Utils = Utils

-- ===== RAYFIELD LOAD (safe) =====
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        STATE.Rayfield = Ray
    else
        warn("[G-MON] Rayfield load failed. Using fallback UI object.")
        STATE.Rayfield = {
            CreateWindow = function(opts)
                return {
                    CreateTab = function(name)
                        return {
                            CreateLabel = function() end,
                            CreateParagraph = function() end,
                            CreateButton = function() end,
                            CreateToggle = function() end,
                            CreateSlider = function() end
                        }
                    end,
                    CreateNotification = function() end
                }
            end,
            Notify = function() end,
            CreateNotification = function() end
        }
    end
end

-- ===== CREATE WINDOW & TABS (safe) =====
do
    SAFE_CALL(function()
        STATE.Window = STATE.Rayfield:CreateWindow({
            Name = "G-MON Hub",
            LoadingTitle = "G-MON Hub",
            LoadingSubtitle = STATE.GAME,
            ConfigurationSaving = { Enabled = false }
        })
        STATE.Tabs.Info = STATE.Window:CreateTab("Info")
        STATE.Tabs.Fitur = STATE.Window:CreateTab("Fitur")
        STATE.Tabs.Move = STATE.Window:CreateTab("Movement")
        STATE.Tabs.Debug = STATE.Window:CreateTab("Debug")
    end)
end

-- ===== STATUS GUI (draggable) =====
do
    local Status = {}
    Status.frame = nil
    Status.lines = {}

    function Status.Create()
        SAFE_CALL(function()
            local pg = LP:FindFirstChild("PlayerGui")
            local tries = 0
            while not pg and tries < 40 do task.wait(0.1); tries = tries + 1; pg = LP:FindFirstChild("PlayerGui") end
            if not pg then error("PlayerGui not found") end

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

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0,8)
            corner.Parent = frame

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
            sub.Text = STATE.GAME
            sub.TextColor3 = Color3.fromRGB(200,200,200)
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.Font = Enum.Font.SourceSans
            sub.TextSize = 12

            local function makeLine(y)
                local holder = Instance.new("Frame")
                holder.Parent = frame
                holder.Size = UDim2.new(1, -16, 0, 20)
                holder.Position = UDim2.new(0,8,0,y)
                holder.BackgroundTransparency = 1

                local dot = Instance.new("Frame")
                dot.Parent = holder
                dot.Size = UDim2.new(0, 12, 0, 12)
                dot.Position = UDim2.new(0, 0, 0, 4)
                dot.BackgroundColor3 = Color3.fromRGB(200, 0, 0)

                local lbl = Instance.new("TextLabel")
                lbl.Parent = holder
                lbl.Size = UDim2.new(1, -18, 1, 0)
                lbl.Position = UDim2.new(0, 18, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = ""
                lbl.TextColor3 = Color3.fromRGB(230,230,230)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Font = Enum.Font.SourceSans
                lbl.TextSize = 12

                return {holder = holder, dot = dot, lbl = lbl}
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

            Status.frame = frame
            Status.lines = lines

            -- draggable
            local dragging = false
            local dragInput = nil
            local startMousePos = Vector2.new(0,0)
            local startFramePos = Vector2.new(0,0)

            local function getMousePos()
                return UIS:GetMouseLocation()
            end

            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragInput = input
                    startMousePos = getMousePos()
                    startFramePos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                            dragInput = nil
                        end
                    end)
                end
            end)

            frame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    dragInput = input
                end
            end)

            UIS.InputChanged:Connect(function(input)
                if not dragging then return end
                if dragInput and input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local mousePos = getMousePos()
                local delta = mousePos - startMousePos
                local newAbs = startFramePos + delta
                local cam = workspace.CurrentCamera
                local vp = (cam and cam.ViewportSize) or Vector2.new(800,600)
                local fw = frame.AbsoluteSize.X
                local fh = frame.AbsoluteSize.Y
                newAbs = Vector2.new(
                    math.clamp(newAbs.X, 0, math.max(0, vp.X - fw)),
                    math.clamp(newAbs.Y, 0, math.max(0, vp.Y - fh))
                )
                frame.Position = UDim2.new(0, newAbs.X, 0, newAbs.Y)
            end)
        end)
    end

    function Status.Set(name, on, text)
        SAFE_CALL(function()
            local ln = Status.lines[name]
            if not ln then return end
            if on then
                ln.dot.BackgroundColor3 = Color3.fromRGB(0,200,0)
            else
                ln.dot.BackgroundColor3 = Color3.fromRGB(200,0,0)
            end
            if text then ln.lbl.Text = text end
        end)
    end

    function Status.UpdateRuntime()
        SAFE_CALL(function()
            if not Status.lines or not Status.lines.runtime then return end
            Status.lines.runtime.lbl.Text = "Runtime: "..Utils.FormatTime(os.time() - STATE.StartTime)
        end)
    end

    STATE.Status = Status
end

-- try create status GUI (non-fatal)
SAFE_CALL(function() STATE.Status.Create() end)

-- ===== MODULE: Blox (AutoFarm etc) =====
do
    local M = {}
    M.config = {
        attack_delay = 0.35,
        range = 10,
        long_range = false,
        fast_attack = false
    }
    M.running = false
    M._task = nil

    function M.start()
        if M.running then return end
        M.running = true
        STATE.Status.Set("bf", true, "Blox: ON")
        M._task = task.spawn(function()
            while M.running do
                task.wait(0.12)
                SAFE_CALL(function()
                    if STATE.GAME ~= "BLOX_FRUIT" then return end
                    local char = Utils.SafeChar()
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    -- find quest if any (simple)
                    local qfolder = Workspace:FindFirstChild("Quests") or Workspace:FindFirstChild("QuestGiver") or Workspace:FindFirstChild("NPCQuests")
                    if qfolder and qfolder.Parent then
                        local qtarget = nil
                        for _, obj in ipairs(qfolder:GetDescendants()) do
                            if obj:IsA("BasePart") then qtarget = obj; break end
                        end
                        if qtarget then
                            pcall(function() hrp.CFrame = qtarget.CFrame * CFrame.new(0,3,0) end)
                            STATE.Status.Set("last", false, "Goto Quest")
                            task.wait(1)
                            return
                        end
                    end

                    -- find enemy folder heuristics
                    local folderHints = {"Enemies","Sea1Enemies","Monsters","Mobs"}
                    local folder = nil
                    for _, name in ipairs(folderHints) do
                        local f = Workspace:FindFirstChild(name)
                        if f then folder = f; break end
                    end
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
                        for i=1,hits do
                            pcall(function()
                                if nearest and nearest:FindFirstChild("Humanoid") then
                                    nearest.Humanoid:TakeDamage(dmg)
                                end
                            end)
                        end
                        STATE.Status.Set("last", false, "LongHit -> "..tostring(nearest.Name or "mob"))
                    else
                        pcall(function() hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
                        if M.config.fast_attack then
                            for i=1,3 do
                                pcall(function()
                                    if nearest and nearest:FindFirstChild("Humanoid") then
                                        nearest.Humanoid:TakeDamage(30)
                                    end
                                end)
                            end
                            STATE.Status.Set("last", false, "FastMelee -> "..tostring(nearest.Name or "mob"))
                        else
                            pcall(function()
                                if nearest and nearest:FindFirstChild("Humanoid") then
                                    nearest.Humanoid:TakeDamage(18)
                                end
                            end)
                            STATE.Status.Set("last", false, "Melee -> "..tostring(nearest.Name or "mob"))
                        end
                    end
                end)
            end
        end)
    end

    function M.stop()
        M.running = false
        STATE.Status.Set("bf", false, "Blox: OFF")
        if M._task then M._task = nil end
    end

    STATE.Modules.Blox = M
end

-- ===== MODULE: Car (LinearVelocity simulation + restore) =====
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
                if m:IsA("Model") and m.PrimaryPart and #m:GetDescendants() > 5 then
                    table.insert(candidates, m)
                end
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

    local function attachFloor(car, origCF)
        SAFE_CALL(function()
            if not car or not origCF then return end
            if car:FindFirstChild("_GmonFloorRef") then return end
            local floor = Instance.new("Part")
            floor.Name = "_GmonFloor_GMON"
            floor.Size = Vector3.new(300, 2, 300)
            floor.Position = Vector3.new(origCF.Position.X, origCF.Position.Y - 500, origCF.Position.Z)
            floor.Anchored = true
            floor.CanCollide = true
            floor.Transparency = 0.15
            floor.Parent = Workspace
            local fv = Instance.new("ObjectValue"); fv.Name = "_GmonFloorRef"; fv.Value = floor; fv.Parent = car
            if pcall(function() return car.SetAttribute end) then
                pcall(function() car:SetAttribute("GmonFloor", true) end)
            end
        end)
    end

    local function ensureLinearVelocity(prim)
        if not prim then return nil end
        local att = prim:FindFirstChild("_GmonAttach")
        if not att then
            att = Instance.new("Attachment")
            att.Name = "_GmonAttach"
            att.Parent = prim
        end
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

    function M.start()
        if M.running then return end
        M.running = true
        STATE.Status.Set("car", true, "Car: ON")
        M._task = task.spawn(function()
            while M.running do
                task.wait(0.2)
                SAFE_CALL(function()
                    if STATE.GAME ~= "CAR_TYCOON" then return end
                    if not M.chosen or not M.chosen.PrimaryPart then
                        local car = M.choosePlayerFastestCar()
                        if not car or not car.PrimaryPart then
                            STATE.Status.Set("last", false, "No car found")
                            return
                        end
                        M.chosen = car
                        if not car:FindFirstChild("_GmonStartPos") then
                            local cv = Instance.new("CFrameValue"); cv.Name = "_GmonStartPos"; cv.Value = car.PrimaryPart.CFrame; cv.Parent = car
                        end
                        local ok, orig = pcall(function() return car.PrimaryPart.CFrame end)
                        if ok and orig then attachFloor(car, orig) end
                        if ok and orig then
                            pcall(function() car:SetPrimaryPartCFrame(CFrame.new(orig.Position.X, orig.Position.Y - 500, orig.Position.Z)) end)
                        end
                    end

                    if M.chosen and M.chosen.PrimaryPart then
                        local prim = M.chosen.PrimaryPart
                        local lv = ensureLinearVelocity(prim)
                        if lv then
                            lv.VectorVelocity = prim.CFrame.LookVector * (M.speed or 60)
                        end
                    end
                end)
            end
        end)
    end

    function M.stop()
        M.running = false
        STATE.Status.Set("car", false, "Car: OFF")
        if M.chosen then
            SAFE_CALL(function()
                if M.chosen.PrimaryPart then
                    local prim = M.chosen.PrimaryPart
                    local lv = prim:FindFirstChild("_GmonLV")
                    if lv then pcall(function() lv:Destroy() end) end
                    local att = prim:FindFirstChild("_GmonAttach")
                    if att then pcall(function() att:Destroy() end) end
                end
                local tag = M.chosen:FindFirstChild("_GmonStartPos")
                if tag and tag:IsA("CFrameValue") and M.chosen.PrimaryPart then
                    pcall(function() M.chosen:SetPrimaryPartCFrame(tag.Value) end)
                    pcall(function() tag:Destroy() end)
                end
                local fv = M.chosen:FindFirstChild("_GmonFloorRef")
                if fv and fv.Value and fv.Value.Parent then pcall(function() fv.Value:Destroy() end) end
                if M.chosen.GetAttribute and M.chosen:GetAttribute("GmonFloor") then pcall(function() M.chosen:SetAttribute("GmonFloor", nil) end) end
            end)
        end
        M.chosen = nil
    end

    STATE.Modules.Car = M
end

-- ===== MODULE: Boat (Auto Gold) =====
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
                if ok and col then
                    if (col.R + col.G + col.B) / 3 < 0.2 then isDark = true end
                end
                if isDark or string.find(lname, "stage") or string.find(lname, "black") or string.find(lname, "dark") or string.find(lname, "trigger") then
                    table.insert(out, obj)
                end
            end
        end
        return out
    end

    function M.start()
        if M.running then return end
        M.running = true
        STATE.Status.Set("boat", true, "Boat: ON")
        M._task = task.spawn(function()
            while M.running do
                task.wait(0.2)
                SAFE_CALL(function()
                    if STATE.GAME ~= "BUILD_A_BOAT" then return end
                    local char = Utils.SafeChar()
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end

                    local roots = {}
                    for _, n in ipairs({"BoatStages","Stages","NormalStages","StageFolder","BoatStage"}) do
                        local r = Workspace:FindFirstChild(n)
                        if r then table.insert(roots, r) end
                    end
                    if #roots == 0 then table.insert(roots, Workspace) end

                    local stages = {}
                    for _, r in ipairs(roots) do
                        local s = collectStages(r)
                        for _, p in ipairs(s) do table.insert(stages, p) end
                    end

                    if #stages == 0 then
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("BasePart") and string.find(string.lower(obj.Name or ""), "stage") then table.insert(stages, obj) end
                        end
                    end

                    if #stages == 0 then
                        STATE.Status.Set("last", false, "No stages")
                        M.running = false
                        STATE.Status.Set("boat", false, "Boat: OFF")
                        return
                    end

                    -- dedupe & sort by nearest to player
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
                        if part and part.Parent then
                            pcall(function() hrp.CFrame = part.CFrame * CFrame.new(0,3,0) end)
                            STATE.Status.Set("last", false, "Boat Stage -> "..tostring(part.Name))
                        end
                        SAFE_WAIT(M.delay or 1.5)
                    end

                    -- find nearest chest
                    local candidate = nil
                    for _, v in ipairs(Workspace:GetDescendants()) do
                        if v:IsA("BasePart") then
                            local ln = string.lower(v.Name or "")
                            if string.find(ln, "chest") or string.find(ln, "treasure") or string.find(ln, "golden") then
                                candidate = v; break
                            end
                        elseif v:IsA("Model") and v.PrimaryPart then
                            local ln = string.lower(v.Name or "")
                            if string.find(ln, "chest") or string.find(ln, "treasure") or string.find(ln, "golden") then
                                candidate = v.PrimaryPart; break
                            end
                        end
                    end
                    if candidate then
                        pcall(function() hrp.CFrame = candidate.CFrame * CFrame.new(0,3,0) end)
                        STATE.Status.Set("last", false, "Reached chest")
                    else
                        STATE.Status.Set("last", false, "No chest found")
                    end
                end)
            end
        end)
    end

    function M.stop()
        M.running = false
        STATE.Status.Set("boat", false, "Boat: OFF")
        if M._task then M._task = nil end
    end

    STATE.Modules.Boat = M
end

-- ===== UI wiring (Rayfield) - add toggles & sliders =====
SAFE_CALL(function()
    local Tabs = STATE.Tabs
    Tabs.Info:CreateLabel("G-MON Hub - client-only. Use in private/testing places.")
    Tabs.Info:CreateButton({
        Name = "Show Quick Help",
        Callback = function()
            SAFE_CALL(function()
                if STATE.GAME == "BLOX_FRUIT" then
                    STATE.Rayfield:Notify({Title="Help - Blox", Content="Auto Farm: teleport to mobs & melee. Use toggles to control.", Duration=5})
                elseif STATE.GAME == "CAR_TYCOON" then
                    STATE.Rayfield:Notify({Title="Help - Car", Content="Auto Drive: chooses your car and simulates drive.", Duration=5})
                elseif STATE.GAME == "BUILD_A_BOAT" then
                    STATE.Rayfield:Notify({Title="Help - Boat", Content="Auto Gold: teleport stage-to-stage & chest.", Duration=5})
                else
                    STATE.Rayfield:Notify({Title="Help", Content="PlaceId not recognized.", Duration=4})
                end
            end)
        end
    })

    -- BLOX controls
    Tabs.Fitur:CreateToggle({
        Name = "Auto Farm (Blox)",
        CurrentValue = false,
        Callback = function(v)
            if v then SAFE_CALL(STATE.Modules.Blox.start) else SAFE_CALL(STATE.Modules.Blox.stop) end
        end
    })
    Tabs.Fitur:CreateToggle({
        Name = "Long Range Hit",
        CurrentValue = false,
        Callback = function(v) STATE.Modules.Blox.config.long_range = v end
    })
    Tabs.Fitur:CreateToggle({
        Name = "Fast Attack (client)",
        CurrentValue = false,
        Callback = function(v) STATE.Modules.Blox.config.fast_attack = v end
    })
    Tabs.Fitur:CreateSlider({
        Name = "Attack Delay (ms)",
        Range = {50,1000},
        Increment = 25,
        CurrentValue = 350,
        Callback = function(v) STATE.Modules.Blox.config.attack_delay = v/1000 end
    })
    Tabs.Fitur:CreateSlider({
        Name = "Range Farming (studs)",
        Range = {1,50},
        Increment = 1,
        CurrentValue = 10,
        Callback = function(v) STATE.Modules.Blox.config.range = v end
    })

    -- CAR controls
    Tabs.Fitur:CreateToggle({
        Name = "Car AutoDrive",
        CurrentValue = false,
        Callback = function(v)
            if v then SAFE_CALL(STATE.Modules.Car.start) else SAFE_CALL(STATE.Modules.Car.stop) end
        end
    })
    Tabs.Fitur:CreateSlider({
        Name = "Car Speed",
        Range = {20,200},
        Increment = 5,
        CurrentValue = 60,
        Callback = function(v) STATE.Modules.Car.speed = v end
    })

    -- BOAT controls
    Tabs.Fitur:CreateToggle({
        Name = "Boat Auto Stages",
        CurrentValue = false,
        Callback = function(v)
            if v then SAFE_CALL(STATE.Modules.Boat.start) else SAFE_CALL(STATE.Modules.Boat.stop) end
        end
    })
    Tabs.Fitur:CreateSlider({
        Name = "Stage Delay (s)",
        Range = {0.5,6},
        Increment = 0.5,
        CurrentValue = 1.5,
        Callback = function(v) STATE.Modules.Boat.delay = v end
    })

    -- Movement tab (Fly)
    local flyEnabled = false
    local flySpeed = 60
    local flyY = 0
    Tabs.Move:CreateToggle({ Name = "Fly", Callback = function(v) flyEnabled = v end })
    Tabs.Move:CreateSlider({ Name = "Fly Speed", Range = {20,150}, Increment = 5, CurrentValue = 60, Callback = function(v) flySpeed = v end })
    Tabs.Move:CreateSlider({ Name = "Fly Y", Range = {-60,60}, Increment = 1, CurrentValue = 0, Callback = function(v) flyY = v end })

    -- Debug tab
    Tabs.Debug:CreateButton({ Name = "Force Start All", Callback = function()
        SAFE_CALL(function() STATE.Modules.Blox.start() end)
        SAFE_CALL(function() STATE.Modules.Car.start() end)
        SAFE_CALL(function() STATE.Modules.Boat.start() end)
    end })
    Tabs.Debug:CreateButton({ Name = "Stop All", Callback = function()
        SAFE_CALL(function() STATE.Modules.Blox.stop() end)
        SAFE_CALL(function() STATE.Modules.Car.stop() end)
        SAFE_CALL(function() STATE.Modules.Boat.stop() end)
    end })
end)

-- ===== Lightweight Fly (RenderStepped) =====
do
    local flyEnabled = false
    local flySpeed = 60
    local flyY = 0
    -- Bind slider changes from UI (if Rayfield available)
    SAFE_CALL(function()
        -- Try to set initial values (the UI callbacks above are separate)
        -- We'll map values by checking toggles are created, but fallback if not.
    end)

    RunService.RenderStepped:Connect(function()
        if not flyEnabled then return end
        pcall(function()
            local c = Utils.SafeChar()
            if not c then return end
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
end

-- ===== STATUS UPDATER LOOP =====
task.spawn(function()
    while true do
        SAFE_WAIT(1)
        SAFE_CALL(function()
            if STATE.Status then STATE.Status.UpdateRuntime() end
        end)
    end
end)

-- ===== Anti AFK =====
SAFE_CALL(function() Utils.AntiAFK() end)

-- ===== STAGED LAZY BOOT (AUTO START SAFE) =====
task.spawn(function()
    -- small initial wait
    SAFE_WAIT(1)

    -- create status gui (if not already)
    SAFE_CALL(function() if STATE.Status and STATE.Status.Create then STATE.Status.Create() end end)

    -- wait more to spread load
    SAFE_WAIT(6)

    -- notify
    SAFE_CALL(function() if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Initializing modules...", Duration=4}) end end)

    -- final delay then auto-start relevant module safely
    SAFE_WAIT(10)
    SAFE_CALL(function()
        local g = STATE.GAME or "UNKNOWN"
        if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Detected game: "..g.." (auto-starting module)", Duration=5}) end
        task.delay(3, function()
            SAFE_CALL(function()
                if g == "BLOX_FRUIT" and STATE.Modules.Blox and STATE.Modules.Blox.start then
                    STATE.Modules.Blox.start()
                elseif g == "CAR_TYCOON" and STATE.Modules.Car and STATE.Modules.Car.start then
                    STATE.Modules.Car.start()
                elseif g == "BUILD_A_BOAT" and STATE.Modules.Boat and STATE.Modules.Boat.start then
                    STATE.Modules.Boat.start()
                else
                    -- no auto-start; user can toggle in UI
                    if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="No auto-started module; use toggles.", Duration=5}) end
                end
            end)
        end)
    end)

    SAFE_WAIT(12)
    SAFE_CALL(function() if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Initialization complete (lazy)", Duration=4}) end end)
end)

-- ===== Final notify & print =====
SAFE_CALL(function()
    if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON Hub", Content="Loaded — use toggles to control modules", Duration=5}) end
end)
print("[G-MON] main.lua loaded. Detected game:", STATE.GAME)