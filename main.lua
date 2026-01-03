-- GMON HUB - FINAL (Draggable Status + Cross-executor Fallback UI)
-- Paste this single file into your executor.
-- If Orion / Rayfield fails, fallback UI will be created and fully draggable.
-- Author: Rebuilt for user (educational)

-- BOOT
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

-- SAFE helpers
local function safe_pcall(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[GMON] safe_pcall:", res)
    end
    return ok, res
end
local function safe_wait(t)
    t = tonumber(t) or 0.1
    if t < 0.01 then t = 0.01 end
    if t > 5 then t = 5 end
    task.wait(t)
end

-- STATE
local GMON = {
    StartTime = os.time(),
    Modules = {},
    Flags = {},
    UI = {}
}

-- Utilities
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

-- Try to load Orion (non-fatal)
local OrionLib, WindowAPI
local okOrion, orionRes = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
end)
if okOrion and type(orionRes) == "table" then
    OrionLib = orionRes
    WindowAPI = OrionLib:MakeWindow({ Name = "G-MON Hub", LoadingTitle = "G-MON Hub", LoadingSubtitle = "Ready", ConfigurationSaving = { Enabled = false } })
else
    warn("[GMON] Orion failed to load; using fallback UI.")
    OrionLib = nil
    WindowAPI = nil
end

-- ===== Fallback UI (draggable, works in all executors) =====
local function makeFallbackWindow(title)
    local W = {}
    -- Root ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "GMonFallback"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = LP:WaitForChild("PlayerGui") end)

    -- Main window frame (draggable)
    local frame = Instance.new("Frame", sg)
    frame.Name = "WindowFrame"
    frame.Size = UDim2.new(0, 420, 0, 520)
    frame.Position = UDim2.new(0, 10, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0

    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
    -- Title bar
    local titleBar = Instance.new("Frame", frame)
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundTransparency = 1
    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(1, -8, 1, 0)
    titleLabel.Position = UDim2.new(0, 4, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(230,230,230)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.Text = title or "G-MON Hub (Fallback)"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Content frame (scrollable list of controls)
    local content = Instance.new("Frame", frame)
    content.Size = UDim2.new(1, -8, 1, -40)
    content.Position = UDim2.new(0, 4, 0, 36)
    content.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", content) layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,8)

    -- Simple Tab implementation: we'll create sections sequentially
    function W:CreateTab(name)
        local Tab = {}
        local header = Instance.new("TextLabel", content)
        header.Size = UDim2.new(1, 0, 0, 24)
        header.BackgroundTransparency = 1
        header.Text = "[ "..tostring(name).." ]"
        header.Font = Enum.Font.SourceSans
        header.TextSize = 14
        header.TextColor3 = Color3.fromRGB(200,200,200)

        function Tab:CreateLabel(text)
            local lbl = Instance.new("TextLabel", content)
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(210,210,210)
            lbl.Font = Enum.Font.SourceSans
            lbl.TextSize = 13
            lbl.Text = tostring(text or "")
            return lbl
        end

        function Tab:CreateParagraph(tbl)
            local title = Instance.new("TextLabel", content); title.Size = UDim2.new(1,0,0,18); title.BackgroundTransparency = 1; title.Font = Enum.Font.SourceSansBold; title.TextSize = 13; title.TextColor3 = Color3.fromRGB(220,220,220); title.Text = tostring(tbl.Title or "")
            local body = Instance.new("TextLabel", content); body.Size = UDim2.new(1,0,0,36); body.BackgroundTransparency = 1; body.Font = Enum.Font.SourceSans; body.TextSize = 12; body.TextColor3 = Color3.fromRGB(180,180,180); body.Text = tostring(tbl.Content or ""); body.TextWrapped = true
            return {title = title, body = body}
        end

        function Tab:CreateButton(tbl)
            local btn = Instance.new("TextButton", content)
            btn.Size = UDim2.new(1, -8, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
            btn.TextColor3 = Color3.fromRGB(230,230,230)
            btn.Font = Enum.Font.SourceSansBold
            btn.TextSize = 14
            btn.Text = tostring(tbl.Name or "Button")
            btn.MouseButton1Click:Connect(function() safe_pcall(tbl.Callback) end)
            return btn
        end

        function Tab:CreateToggle(tbl)
            local holder = Instance.new("Frame", content)
            holder.Size = UDim2.new(1, -8, 0, 28)
            holder.BackgroundTransparency = 1
            local label = Instance.new("TextLabel", holder)
            label.Size = UDim2.new(0.75, 0, 1, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.SourceSans; label.TextSize = 14; label.TextColor3 = Color3.fromRGB(220,220,220); label.Text = tostring(tbl.Name or "Toggle"); label.TextXAlignment = Enum.TextXAlignment.Left
            local btn = Instance.new("TextButton", holder)
            btn.Size = UDim2.new(0.23, 0, 0.9, 0); btn.Position = UDim2.new(0.76, 0, 0.05, 0); btn.Text = tbl.CurrentValue and "ON" or "OFF"; btn.Font = Enum.Font.SourceSansBold; btn.TextSize = 13
            btn.BackgroundColor3 = tbl.CurrentValue and Color3.fromRGB(30,160,40) or Color3.fromRGB(100,100,100)
            btn.MouseButton1Click:Connect(function()
                local nv = not tbl.CurrentValue
                tbl.CurrentValue = nv
                btn.Text = nv and "ON" or "OFF"
                btn.BackgroundColor3 = nv and Color3.fromRGB(30,160,40) or Color3.fromRGB(100,100,100)
                safe_pcall(tbl.Callback, nv)
            end)
            return holder
        end

        function Tab:CreateSlider(tbl)
            local holder = Instance.new("Frame", content)
            holder.Size = UDim2.new(1, -8, 0, 56)
            holder.BackgroundTransparency = 1
            local label = Instance.new("TextLabel", holder)
            label.Size = UDim2.new(1, 0, 0, 20); label.Position = UDim2.new(0,0,0,0); label.BackgroundTransparency = 1; label.Font = Enum.Font.SourceSans; label.TextSize = 13; label.TextColor3 = Color3.fromRGB(220,220,220); label.Text = tostring(tbl.Name or "Slider") .. ": " .. tostring(tbl.CurrentValue or "")
            local btn = Instance.new("TextButton", holder)
            btn.Size = UDim2.new(1, 0, 0, 28); btn.Position = UDim2.new(0,0,0,24)
            btn.BackgroundColor3 = Color3.fromRGB(50,50,50); btn.Font = Enum.Font.SourceSans; btn.TextSize = 13; btn.Text = "Set ("..tostring(tbl.CurrentValue)..")"
            btn.MouseButton1Click:Connect(function()
                -- no prompt across all executors reliably; just call callback with current value
                safe_pcall(tbl.Callback, tbl.CurrentValue)
            end)
            return holder
        end

        function Tab:CreateDropdown(tbl)
            -- extremely simple: create label and call callback with first option when clicked
            local holder = Instance.new("Frame", content); holder.Size = UDim2.new(1,-8,0,36); holder.BackgroundTransparency = 1
            local label = Instance.new("TextLabel", holder); label.Size = UDim2.new(0.6,0,1,0); label.BackgroundTransparency = 1; label.Font = Enum.Font.SourceSans; label.TextSize = 13; label.Text = tostring(tbl.Name or "Dropdown"); label.TextColor3 = Color3.fromRGB(220,220,220)
            local btn = Instance.new("TextButton", holder); btn.Size = UDim2.new(0.38,0,1,0); btn.Position = UDim2.new(0.62,0,0,0); btn.Text = tostring(tbl.Default or (tbl.Options and tbl.Options[1]) or "Select"); btn.Font = Enum.Font.SourceSans; btn.TextSize = 13; btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            btn.MouseButton1Click:Connect(function()
                local opt = (tbl.Options and tbl.Options[1]) or btn.Text
                safe_pcall(tbl.Callback, opt)
                btn.Text = tostring(opt)
            end)
            return holder
        end

        return Tab
    end

    function W:Notify(params)
        pcall(function()
            if StarterGui and StarterGui.SetCore then
                StarterGui:SetCore("SendNotification", {Title = params.Title or "G-MON", Text = params.Content or "", Duration = params.Duration or 3})
            end
        end)
        print("[G-MON Notify]", params.Title, params.Content)
    end

    -- Make the window draggable (title bar)
    do
        local dragging, dragInput, startMousePos, startPos = false, nil, Vector2.new(0,0), Vector2.new(0,0)
        local function getMousePosition()
            if UIS.TouchEnabled and UIS:GetLastInputType() == Enum.UserInputType.Touch then
                return UIS:GetLastInputPositions and (select(1, UIS:GetLastInputPositions()) or Vector2.new(0,0)) or UIS:GetMouseLocation()
            else
                return UIS:GetMouseLocation()
            end
        end
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragInput = input
                startMousePos = getMousePosition()
                startPos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local mp = getMousePosition()
                local delta = mp - startMousePos
                local newPos = startPos + delta
                local cam = workspace.CurrentCamera
                local vp = (cam and cam.ViewportSize) or Vector2.new(800,600)
                local fw = frame.AbsoluteSize.X; local fh = frame.AbsoluteSize.Y
                newPos = Vector2.new(math.clamp(newPos.X, 0, math.max(0, vp.X - fw)), math.clamp(newPos.Y, 0, math.max(0, vp.Y - fh)))
                frame.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
            end
        end)
    end

    W._root = sg
    W._frame = frame
    W._content = content
    return W
end

-- Decide UI to use: Orion or fallback
local UIWindow = WindowAPI or makeFallbackWindow("G-MON Hub")
GMON.UI.Window = UIWindow

-- ===== Draggable GMON STATUS (works on all executors) =====
do
    local Status = {}
    Status.Gui = Instance.new("ScreenGui")
    Status.Gui.Name = "GMonStatus"
    Status.Gui.ResetOnSpawn = false
    pcall(function() Status.Gui.Parent = LP:WaitForChild("PlayerGui") end)

    local frame = Instance.new("Frame", Status.Gui)
    frame.Name = "StatusFrame"
    frame.Size = UDim2.new(0, 320, 0, 150)
    frame.Position = UDim2.new(1, -330, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -12, 0, 26)
    title.Position = UDim2.new(0, 6, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(240,240,240)
    title.Text = "G-MON Status"

    local subtitle = Instance.new("TextLabel", frame)
    subtitle.Size = UDim2.new(1, -12, 0, 18)
    subtitle.Position = UDim2.new(0, 6, 0, 34)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.SourceSans
    subtitle.TextSize = 12
    subtitle.TextColor3 = Color3.fromRGB(200,200,200)
    subtitle.Text = "Status Overlay (drag me)"

    -- data lines
    local function makeLine(y)
        local holder = Instance.new("Frame", frame); holder.Size = UDim2.new(1, -12, 0, 18); holder.Position = UDim2.new(0, 6, 0, y); holder.BackgroundTransparency = 1
        local dot = Instance.new("Frame", holder); dot.Size = UDim2.new(0, 10, 0, 10); dot.Position = UDim2.new(0, 0, 0, 4); dot.BackgroundColor3 = Color3.fromRGB(200,0,0); local dc = Instance.new("UICorner", dot); dc.CornerRadius = UDim.new(0,4)
        local lbl = Instance.new("TextLabel", holder); lbl.Size = UDim2.new(1, -18, 1, 0); lbl.Position = UDim2.new(0, 18, 0, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 12; lbl.TextColor3 = Color3.fromRGB(230,230,230); lbl.TextXAlignment = Enum.TextXAlignment.Left
        return {dot = dot, lbl = lbl}
    end

    local lines = {}
    lines.runtime = makeLine(56)
    lines.blox = makeLine(78)
    lines.car = makeLine(100)
    lines.boat = makeLine(122)
    lines.last = makeLine(144)

    lines.runtime.lbl.Text = "Runtime: 00:00"
    lines.blox.lbl.Text = "Blox: OFF"
    lines.car.lbl.Text = "Car: OFF"
    lines.boat.lbl.Text = "Boat: OFF"
    lines.last.lbl.Text = "Last: Idle"

    -- make draggable (frame)
    do
        local dragging, dragInput, startMousePos, startFramePos = false, nil, Vector2.new(0,0), Vector2.new(0,0)
        local function getMousePos()
            return UIS:GetMouseLocation()
        end
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragInput = input; startMousePos = getMousePos(); startFramePos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false; dragInput = nil end
                end)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                local mousePos = getMousePos(); local delta = mousePos - startMousePos; local newAbs = startFramePos + delta
                local cam = workspace.CurrentCamera; local vp = (cam and cam.ViewportSize) or Vector2.new(800,600)
                local fw = frame.AbsoluteSize.X; local fh = frame.AbsoluteSize.Y
                newAbs = Vector2.new(math.clamp(newAbs.X, 0, math.max(0, vp.X - fw)), math.clamp(newAbs.Y, 0, math.max(0, vp.Y - fh)))
                frame.Position = UDim2.new(0, newAbs.X, 0, newAbs.Y)
            end
        end)
    end

    -- Public API to update lines
    function Status.UpdateRuntimeText(txt) lines.runtime.lbl.Text = "Runtime: "..tostring(txt) end
    function Status.SetIndicator(name, on, text)
        local ln = lines[name]
        if not ln then return end
        ln.dot.BackgroundColor3 = on and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
        if text then ln.lbl.Text = text end
    end

    GMON.UI.Status = Status
end

-- STATUS updater loop
task.spawn(function()
    while true do
        safe_wait(1)
        pcall(function()
            GMON.UI.Status.UpdateRuntimeText(Utils.FormatTime(os.time() - GMON.StartTime))
            GMON.UI.Status.SetIndicator("last", false, "Last: "..(GMON.LastAction or "Idle"))
            GMON.UI.Status.SetIndicator("blox", GMON.Flags.Blox==true, (GMON.Flags.Blox and "Blox: ON" or "Blox: OFF"))
            GMON.UI.Status.SetIndicator("car", GMON.Flags.Car==true, (GMON.Flags.Car and "Car: ON" or "Car: OFF"))
            GMON.UI.Status.SetIndicator("boat", GMON.Flags.Boat==true, (GMON.Flags.Boat and "Boat: ON" or "Boat: OFF"))
        end)
    end
end)

-- ===========================================================
-- (Modules: Blox, Car, Boat, GoldTracker)
-- For brevity these are similar to earlier versions and kept minimal.
-- Toggle with UI buttons.
-- ===========================================================
-- (BLOX)
do
    local M = {}
    M.config = { range = 12, fast_attack = false }
    M.running = false
    M._task = nil
    local function findEnemies()
        local hints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs"}
        for _, name in ipairs(hints) do local f = Workspace:FindFirstChild(name); if f then return f end end
        return Workspace
    end
    local function loop()
        while M.running do
            safe_wait(0.12)
            pcall(function()
                if not M.running then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local folder = findEnemies()
                local nearest, bestDist = nil, math.huge
                for _, mob in ipairs(folder:GetDescendants()) do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") then
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local ok, pos = pcall(function() return mob.HumanoidRootPart.Position end)
                            if ok then local d = (pos - hrp.Position).Magnitude; if d < bestDist and d <= (M.config.range or 12) then bestDist, nearest = d, mob end end
                        end
                    end
                end
                if nearest then
                    pcall(function() hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
                    if M.config.fast_attack then for i=1,3 do pcall(function() if nearest and nearest:FindFirstChildOfClass("Humanoid") then nearest:FindFirstChildOfClass("Humanoid"):TakeDamage(25) end end); safe_wait(0.06) end
                end
            end)
        end
    end
    function M.start() if M.running then return end; M.running = true; GMON.Flags.Blox = true; M._task = task.spawn(loop) end
    function M.stop() M.running = false; GMON.Flags.Blox = false; M._task = nil end
    GMON.Modules.Blox = M
end

-- (CAR)
do
    local M = {}
    M.running = false; M.speed = 80; M.chosen = nil; M._task = nil
    local function guessRoot() for _,n in ipairs({"Cars","Vehicles","Dealership","CarShop"}) do local f = Workspace:FindFirstChild(n); if f then return f end end return Workspace end
    local function isOwned(m)
        if not m then return false end
        if tostring(m.Name) == tostring(LP.Name) then return true end
        local ok, o = pcall(function() local v = m:FindFirstChild("Owner") or m:FindFirstChild("OwnerName"); if v and v.Value then return tostring(v.Value) end end)
        if ok and o and tostring(o) == tostring(LP.Name) then return true end
        return false
    end
    local function pickCar()
        local root = guessRoot()
        for _,c in ipairs(root:GetDescendants()) do if c:IsA("Model") and c.PrimaryPart and isOwned(c) then return c end end
        for _,c in ipairs(root:GetChildren()) do if c:IsA("Model") and c.PrimaryPart and #c:GetDescendants()>5 then return c end end
        return nil
    end
    local function ensureLV(part)
        if not part then return nil end
        if not part:FindFirstChild("_GmonLV") then
            local att = part:FindFirstChild("_GmonAttach") or Instance.new("Attachment", part); if not att.Name then att.Name = "_GmonAttach" end
            local lv = Instance.new("LinearVelocity", part); lv.Name = "_GmonLV"; lv.Attachment0 = att; lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0; lv.MaxForce = math.huge
            return lv
        else return part:FindFirstChild("_GmonLV") end
    end
    local function loop()
        while M.running do
            safe_wait(0.2)
            pcall(function()
                if not M.running then return end
                if not M.chosen or not M.chosen.PrimaryPart then
                    M.chosen = pickCar()
                    if M.chosen and M.chosen.PrimaryPart and not M.chosen:FindFirstChild("_GmonStartPos") then local cv = Instance.new("CFrameValue", M.chosen); cv.Name = "_GmonStartPos"; cv.Value = M.chosen.PrimaryPart.CFrame end
                end
                if M.chosen and M.chosen.PrimaryPart then local lv = ensureLV(M.chosen.PrimaryPart); if lv then lv.VectorVelocity = M.chosen.PrimaryPart.CFrame.LookVector * (M.speed or 80) end end
            end)
        end
    end
    function M.start() if M.running then return end; M.running = true; GMON.Flags.Car = true; M._task = task.spawn(loop) end
    function M.stop() M.running = false; GMON.Flags.Car = false; if M.chosen and M.chosen.PrimaryPart then pcall(function() local lv = M.chosen.PrimaryPart:FindFirstChild("_GmonLV"); if lv then lv:Destroy() end local att = M.chosen.PrimaryPart:FindFirstChild("_GmonAttach"); if att then att:Destroy() end local tag = M.chosen:FindFirstChild("_GmonStartPos"); if tag and tag:IsA("CFrameValue") then pcall(function() M.chosen:SetPrimaryPartCFrame(tag.Value) end); pcall(function() tag:Destroy() end) end end) end; M.chosen = nil end
    GMON.Modules.Car = M
end

-- (BOAT)
do
    local M = {}
    M.running = false; M.delay = 1.2; M._task = nil
    local function collectStages()
        local out = {}
        for _,v in ipairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and (string.find(string.lower(v.Name or ""),"stage") or string.find(string.lower(v.Name or ""),"black")) then table.insert(out, v) end end
        return out
    end
    local function loop()
        while M.running do
            safe_wait(0.2)
            pcall(function()
                if not M.running then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local parts = collectStages()
                table.sort(parts, function(a,b) return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude end)
                for _,p in ipairs(parts) do if not M.running then break end; pcall(function() hrp.CFrame = p.CFrame * CFrame.new(0,3,0) end); safe_wait(M.delay) end
                -- chest search
                for _,v in ipairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and (string.find(string.lower(v.Name or ""),"chest") or string.find(string.lower(v.Name or ""),"treasure")) then pcall(function() hrp.CFrame = v.CFrame * CFrame.new(0,3,0) end); break end end
            end)
        end
    end
    function M.start() if M.running then return end; M.running = true; GMON.Flags.Boat = true; M._task = task.spawn(loop) end
    function M.stop() M.running = false; GMON.Flags.Boat = false; M._task = nil end
    GMON.Modules.Boat = M
end

-- (GoldTracker) - simple wrapper (kept minimal)
do
    local GT = {}
    GT.running = false; GT.gui = nil
    local function create_gui()
        local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui")
        local sg = Instance.new("ScreenGui"); sg.Name = "GMON_GoldTracker"; sg.ResetOnSpawn = false; sg.Parent = pg
        local frame = Instance.new("Frame", sg); frame.Size = UDim2.new(0, 260, 0, 120); frame.Position = UDim2.new(0, 6, 0, 6); frame.BackgroundColor3 = Color3.fromRGB(18,18,18); local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
        local labels = {}
        for i=1,4 do local l = Instance.new("TextLabel", frame); l.Size = UDim2.new(1, -12, 0, 20); l.Position = UDim2.new(0, 6, 0, 6 + (i-1)*26); l.BackgroundTransparency = 1; l.Font = Enum.Font.SourceSans; l.TextSize = 13; l.TextColor3 = Color3.fromRGB(220,220,220); l.Text = "..." labels[i] = l end
        return { Gui = sg, Frame = frame, Labels = labels, StartTime = os.time() }
    end
    local function find_numeric_label(root)
        if not root then return nil end
        if root:IsA("TextLabel") then local txt = tostring(root.Text):gsub("%s",""); if txt ~= "" and tonumber(txt) then return root end end
        for _,c in ipairs(root:GetChildren()) do local f = find_numeric_label(c) if f then return f end end
        return nil
    end
    local function loop(guiobj)
        if not guiobj then return end
        local playerGui = LP:WaitForChild("PlayerGui")
        local found = nil; local startAmt = 0; local gained = 0
        while GT.running do
            if not found or not found.Parent then
                if playerGui:FindFirstChild("GoldGui") and playerGui.GoldGui:FindFirstChild("Frame") then found = find_numeric_label(playerGui.GoldGui.Frame) else found = find_numeric_label(playerGui) end
                if found then startAmt = tonumber((found.Text:gsub("[^%d]",""))) or 0 end
            end
            if found then
                local cur = tonumber((found.Text:gsub("[^%d]",""))) or 0
                if cur > startAmt then gained = gained + (cur - startAmt); startAmt = cur elseif cur < startAmt then startAmt = cur end
                guiobj.Labels[1].Text = "Start: "..tostring(startAmt)
                guiobj.Labels[2].Text = "Current: "..tostring(cur)
                guiobj.Labels[3].Text = "Gained: "..tostring(gained)
            end
            guiobj.Labels[4].Text = "Time: "..string.format("%02d:%02d", math.floor((os.time()-guiobj.StartTime)/60), (os.time()-guiobj.StartTime)%60)
            safe_wait(1)
        end
    end
    function GT.start() if GT.running then return end; GT.running = true; GT.gui = create_gui(); task.spawn(function() loop(GT.gui) end) end
    function GT.stop() GT.running = false; if GT.gui and GT.gui.Gui and GT.gui.Gui.Parent then pcall(function() GT.gui.Gui:Destroy() end) end; GT.gui = nil end
    GMON.Modules.GoldTracker = GT
end

-- ============================================================
-- Build UI controls into Orion or fallback
-- If Orion is available we already created WindowAPI earlier.
-- Otherwise use fallback window API (makeFallbackWindow) which we stored as UIWindow.
-- ============================================================
do
    local win = UIWindow
    if win.CreateTab then
        local tInfo = win:CreateTab("Info")
        tInfo:CreateLabel("G-MON Hub - Fallback/Orion aware UI")
        tInfo:CreateParagraph({ Title = "Detected", Content = "Use this UI if Orion failed." })
        tInfo:CreateToggle({ Name = "Gold Tracker", CurrentValue = false, Callback = function(v) if v then GMON.Modules.GoldTracker.start() else GMON.Modules.GoldTracker.stop() end end })

        local tBlox = win:CreateTab("Blox Fruit")
        tBlox:CreateLabel("Blox controls")
        tBlox:CreateToggle({ Name = "Auto Farm (module)", CurrentValue = false, Callback = function(v) if v then GMON.Modules.Blox.start() else GMON.Modules.Blox.stop() end end })
        tBlox:CreateToggle({ Name = "Fast Attack", CurrentValue = false, Callback = function(v) GMON.Modules.Blox.config.fast_attack = v end })

        local tCar = win:CreateTab("Car Tycoon")
        tCar:CreateLabel("Car controls")
        tCar:CreateToggle({ Name = "Auto Drive", CurrentValue = false, Callback = function(v) if v then GMON.Modules.Car.start() else GMON.Modules.Car.stop() end end })
        tCar:CreateSlider({ Name = "Car Speed", CurrentValue = GMON.Modules.Car and GMON.Modules.Car.speed or 80, onChange = function(v) if GMON.Modules.Car then GMON.Modules.Car.speed = v end end })

        local tBoat = win:CreateTab("Build A Boat")
        tBoat:CreateLabel("Boat controls")
        tBoat:CreateToggle({ Name = "Auto Stages", CurrentValue = false, Callback = function(v) if v then GMON.Modules.Boat.start() else GMON.Modules.Boat.stop() end end })
        tBoat:CreateSlider({ Name = "Stage Delay", CurrentValue = GMON.Modules.Boat.delay or 1.2, onChange = function(v) if GMON.Modules.Boat then GMON.Modules.Boat.delay = v end end })
        tBoat:CreateButton({ Name = "Teleport Build Area", Callback = function() GMON.Modules.Boat.TeleportToPreset("build_area") end })
    else
        -- If win doesn't have CreateTab, it's the fallback object returned earlier
        local tInfo = win:CreateTab("Info")
        tInfo:CreateLabel("G-MON Hub - Fallback UI")
        tInfo:CreateParagraph({ Title = "Detected", Content = "Fallback UI ready." })
    end
end

-- ============================================================
-- Start / notify
-- ============================================================
task.spawn(function()
    safe_pcall(function()
        if OrionLib and OrionLib.MakeNotification then OrionLib:MakeNotification({ Name = "GMON", Content = "Loaded. Status UI draggable.", Time = 4 }) end
        pcall(function() StarterGui:SetCore("SendNotification", {Title="GMON", Text="Loaded. Status UI draggable.", Duration=4}) end)
    end)
end)

-- Export main table
local Main = {}
Main.GMON = GMON
Main.Utils = Utils
return Main