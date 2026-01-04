-- GMON HUB - main.lua (FIXED)
-- Single-file: Blox Fruit + Car Tycoon + Build A Boat
-- Notes: Safe wrappers, improved fallback UI, verbose SAFE_CALL with traceback.

-- BOOTSTRAP
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

-- SAFE HELPERS (verbose)
local function SAFE_CALL(fn, ...)
    if type(fn) ~= "function" then
        warn("[GMON SAFE_CALL] not a function:", fn)
        return false
    end
    local args = {...}
    local ok, res = xpcall(function() return fn(unpack(args)) end, function(err)
        local tb = debug.traceback(err, 2)
        print("[GMON SAFE_CALL ERROR] " .. tostring(err))
        print(tb)
        return err
    end)
    if not ok then
        -- res holds the error value returned by our error handler
        return false, res
    end
    return true, res
end

local function SAFE_WAIT(t)
    t = tonumber(t) or 0.1
    if t < 0.01 then t = 0.01 end
    if t > 5 then t = 5 end
    task.wait(t)
end

-- CORE
local GMON = {
    StartTime = os.time(),
    Modules = {},
    Flags = {},
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    Status = nil,
    LastAction = "Idle"
}

-- UTILITIES
local Utils = {}
function Utils.SafeChar()
    local ok, c = pcall(function() return LP and LP.Character end)
    if not ok or not c then return nil end
    if c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then return c end
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

function Utils.FlexibleDetectGame()
    local pid = game.PlaceId
    if pid == 2753915549 or pid == 4442272183 or pid == 7449423635 then return "BLOX_FRUIT" end
    if pid == 1554960397 or pid == 654732683 then return "CAR_TYCOON" end
    if pid == 537413528 or pid == 142823291 then return "BUILD_A_BOAT" end
    local map = {
        BLOX_FRUIT = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","Quests"},
        CAR_TYCOON = {"Cars","VehicleFolder","Dealership","Garage","CarShop"},
        BUILD_A_BOAT = {"BoatStages","Stages","NormalStages","StageFolder","BoatStage","Chest","Treasure"}
    }
    for k, names in pairs(map) do
        for _,n in ipairs(names) do
            if Workspace:FindFirstChild(n) then return k end
        end
    end
    for _,obj in ipairs(Workspace:GetChildren()) do
        local n = string.lower(obj.Name or "")
        if string.find(n,"enemy") or string.find(n,"mob") or string.find(n,"monster") then return "BLOX_FRUIT" end
        if string.find(n,"car") or string.find(n,"vehicle") or string.find(n,"garage") then return "CAR_TYCOON" end
        if string.find(n,"boat") or string.find(n,"stage") or string.find(n,"treasure") or string.find(n,"chest") then return "BUILD_A_BOAT" end
    end
    return "UNKNOWN"
end

function Utils.ShortLabel(g)
    if g=="BLOX_FRUIT" then return "Blox" end
    if g=="CAR_TYCOON" then return "Car" end
    if g=="BUILD_A_BOAT" then return "Boat" end
    return tostring(g or "Unknown")
end

GMON.Utils = Utils

-- TRY LOAD RAYFIELD (non-fatal)
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        GMON.Rayfield = Ray
        print("[GMON] Rayfield loaded.")
    else
        GMON.Rayfield = nil
        print("[GMON] Rayfield not available; using fallback UI.")
    end
end

-- FALLBACK UI (Rayfield-like) - fully compatible to used calls
local function createCustomWindow(title)
    local API = {}
    local sg = Instance.new("ScreenGui")
    sg.Name = "GMON_CustomUI"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = LP:WaitForChild("PlayerGui") end)

    local winFrame = Instance.new("Frame", sg)
    winFrame.Name = "GMON_Window"
    winFrame.Size = UDim2.new(0, 820, 0, 520)
    winFrame.Position = UDim2.new(0, 20, 0, 60)
    winFrame.BackgroundColor3 = Color3.fromRGB(18,18,20)
    winFrame.BorderSizePixel = 0
    winFrame.Active = true
    winFrame.Draggable = true
    local winCorner = Instance.new("UICorner", winFrame); winCorner.CornerRadius = UDim.new(0,10)

    -- Title
    local titleBar = Instance.new("Frame", winFrame)
    titleBar.Size = UDim2.new(1,0,0,36); titleBar.Position = UDim2.new(0,0,0,0); titleBar.BackgroundTransparency = 1
    local titleLbl = Instance.new("TextLabel", titleBar)
    titleLbl.Size = UDim2.new(1,-120,1,0); titleLbl.Position = UDim2.new(0,12,0,0)
    titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.SourceSansBold; titleLbl.TextSize = 18; titleLbl.TextColor3 = Color3.fromRGB(230,230,230)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Text = title or "GMON Hub"

    -- Close & toggle (goggle)
    local goggleBtn = Instance.new("TextButton", titleBar)
    goggleBtn.Size = UDim2.new(0, 28, 0, 28); goggleBtn.Position = UDim2.new(1, -44, 0, 4)
    goggleBtn.Text = "👁"; goggleBtn.Font = Enum.Font.SourceSans; goggleBtn.TextSize = 18; goggleBtn.BackgroundColor3 = Color3.fromRGB(38,38,40); goggleBtn.TextColor3 = Color3.fromRGB(240,240,240)
    local goggleCorner = Instance.new("UICorner", goggleBtn); goggleCorner.CornerRadius = UDim.new(0,6)
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 28, 0, 28); closeBtn.Position = UDim2.new(1, -8, 0, 4); closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.SourceSans; closeBtn.TextSize = 14; closeBtn.BackgroundColor3 = Color3.fromRGB(45,45,47); closeBtn.TextColor3 = Color3.fromRGB(240,240,240)
    local closeCorner = Instance.new("UICorner", closeBtn); closeCorner.CornerRadius = UDim.new(0,6)
    closeBtn.MouseButton1Click:Connect(function() pcall(function() sg:Destroy() end) end)

    -- Sidebar & Tabs
    local sidebar = Instance.new("Frame", winFrame); sidebar.Size = UDim2.new(0,200,1,-36); sidebar.Position=UDim2.new(0,0,0,36); sidebar.BackgroundColor3 = Color3.fromRGB(28,28,30)
    local sideTitle = Instance.new("TextLabel", sidebar); sideTitle.Size=UDim2.new(1,-12,0,28); sideTitle.Position=UDim2.new(0,6,0,8); sideTitle.BackgroundTransparency=1; sideTitle.Font=Enum.Font.SourceSansSemibold; sideTitle.TextSize=14; sideTitle.TextColor3=Color3.fromRGB(210,210,210); sideTitle.Text="Tabs"
    local tabsList = Instance.new("ScrollingFrame", sidebar); tabsList.Name="TabsList"; tabsList.Position=UDim2.new(0,6,0,40); tabsList.Size=UDim2.new(1,-12,1,-48); tabsList.BackgroundTransparency=1; tabsList.ScrollBarThickness=6
    local uiGrid = Instance.new("UIListLayout", tabsList); uiGrid.SortOrder = Enum.SortOrder.LayoutOrder; uiGrid.Padding = UDim.new(0,6)

    -- Content area
    local content = Instance.new("Frame", winFrame); content.Size = UDim2.new(1,-212,1,-46); content.Position=UDim2.new(0,208,0,36); content.BackgroundTransparency=1
    local contentScroll = Instance.new("ScrollingFrame", content); contentScroll.Name="ContentScroll"; contentScroll.Size=UDim2.new(1,-12,1,-12); contentScroll.Position=UDim2.new(0,6,0,6); contentScroll.BackgroundTransparency=1; contentScroll.ScrollBarThickness=8
    local contentLayout = Instance.new("UIListLayout", contentScroll); contentLayout.SortOrder = Enum.SortOrder.LayoutOrder; contentLayout.Padding = UDim.new(0,8)

    local function recalcCanvas(scroll)
        SAFE_CALL(function()
            local layout = scroll:FindFirstChildWhichIsA("UIListLayout", true)
            if not layout then return end
            local total = layout.AbsoluteContentSize.Y
            scroll.CanvasSize = UDim2.new(0,0,0, total + 12)
        end)
    end

    local tabs = {}
    local function makeTab(name)
        local tabObj = {}
        local btn = Instance.new("TextButton", tabsList)
        btn.Size = UDim2.new(1,-12,0,34); btn.BackgroundColor3 = Color3.fromRGB(40,40,42); btn.TextColor3 = Color3.fromRGB(220,220,220); btn.Font = Enum.Font.SourceSans; btn.TextSize = 14; btn.Text = name
        local bcorner = Instance.new("UICorner", btn); bcorner.CornerRadius = UDim.new(0,6)
        local items = {}

        function tabObj:CreateLabel(txt)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1,-8,0,24)
            f.BackgroundTransparency = 1
            local lbl = Instance.new("TextLabel", f)
            lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.Text = txt or ""
            table.insert(items, f); return f
        end

        function tabObj:CreateParagraph(tbl)
            local f = Instance.new("Frame"); f.Size = UDim2.new(1,-8,0,48); f.BackgroundTransparency = 1
            local title = Instance.new("TextLabel", f); title.Size = UDim2.new(1,0,0,18); title.BackgroundTransparency = 1; title.Font=Enum.Font.SourceSansSemibold; title.TextSize=14; title.TextColor3=Color3.fromRGB(210,210,210); title.Text = tbl.Title or ""
            local cont = Instance.new("TextLabel", f); cont.Position = UDim2.new(0,0,0,18); cont.Size = UDim2.new(1,0,1,-18); cont.BackgroundTransparency = 1; cont.Font=Enum.Font.SourceSans; cont.TextSize=13; cont.TextColor3=Color3.fromRGB(200,200,200); cont.Text = tbl.Content or ""; cont.TextWrapped = true
            table.insert(items, f); return f
        end

        function tabObj:CreateButton(tbl)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -8, 0, 34)
            b.AutoButtonColor = true
            b.Text = tbl.Name or "Button"
            b.Font = Enum.Font.SourceSansBold
            b.TextSize = 14
            b.BackgroundColor3 = Color3.fromRGB(48,48,50)
            b.TextColor3 = Color3.fromRGB(240,240,240)
            local bc = Instance.new("UICorner", b); bc.CornerRadius = UDim.new(0,6)
            b.MouseButton1Click:Connect(function() SAFE_CALL(tbl.Callback) end)
            table.insert(items, b); return b
        end

        function tabObj:CreateToggle(tbl)
            local fr = Instance.new("Frame"); fr.Size = UDim2.new(1,-8,0,34); fr.BackgroundTransparency = 1
            local lbl = Instance.new("TextLabel", fr); lbl.Size = UDim2.new(0.74,0,1,0); lbl.Position = UDim2.new(0,6,0,0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.Text = tbl.Name or "Toggle"
            local btn = Instance.new("TextButton", fr); btn.Size = UDim2.new(0.24, -12, 0.8, 0); btn.Position = UDim2.new(0.76, 6, 0.1, 0); btn.Font = Enum.Font.SourceSansBold; btn.TextSize = 13; btn.Text = tbl.CurrentValue and "ON" or "OFF"; btn.BackgroundColor3 = tbl.CurrentValue and Color3.fromRGB(30,160,50) or Color3.fromRGB(100,100,100); btn.TextColor3 = Color3.fromRGB(240,240,240)
            local bc = Instance.new("UICorner", btn); bc.CornerRadius = UDim.new(0,6)
            btn.MouseButton1Click:Connect(function()
                local nv = not (tbl.CurrentValue)
                tbl.CurrentValue = nv
                btn.Text = nv and "ON" or "OFF"
                btn.BackgroundColor3 = nv and Color3.fromRGB(30,160,50) or Color3.fromRGB(100,100,100)
                SAFE_CALL(tbl.Callback, nv)
            end)
            table.insert(items, fr); return fr
        end

        function tabObj:CreateSlider(tbl)
            -- Accepts: Name, Range={min,max}, Increment, CurrentValue, Callback
            local fr = Instance.new("Frame"); fr.Size = UDim2.new(1,-8,0,72); fr.BackgroundTransparency = 1
            local title = Instance.new("TextLabel", fr); title.Size = UDim2.new(1,0,0,18); title.BackgroundTransparency = 1; title.Font = Enum.Font.SourceSans; title.TextSize = 13; title.TextColor3 = Color3.fromRGB(210,210,210)
            title.Text = tbl.Name .. " : " .. tostring(tbl.CurrentValue)
            -- numeric entry + apply
            local numBox = Instance.new("TextBox", fr)
            numBox.Size = UDim2.new(0.6, -8, 0, 30); numBox.Position = UDim2.new(0,6,0,22); numBox.Text = tostring(tbl.CurrentValue); numBox.Font = Enum.Font.SourceSans; numBox.TextSize = 14
            local applyBtn = Instance.new("TextButton", fr)
            applyBtn.Size = UDim2.new(0.38, -8, 0, 30); applyBtn.Position = UDim2.new(0.62, 6, 0, 22); applyBtn.Text = "Apply"; applyBtn.Font = Enum.Font.SourceSans; applyBtn.TextSize = 13; applyBtn.BackgroundColor3 = Color3.fromRGB(45,45,47); applyBtn.TextColor3 = Color3.fromRGB(240,240,240)
            local bc = Instance.new("UICorner", applyBtn); bc.CornerRadius = UDim.new(0,6)
            applyBtn.MouseButton1Click:Connect(function()
                local val = tonumber(numBox.Text) or tbl.CurrentValue
                -- clamp based on Range
                if tbl.Range and type(tbl.Range)=="table" then
                    local minv, maxv = tbl.Range[1], tbl.Range[2]
                    val = math.clamp(val, minv, maxv)
                end
                tbl.CurrentValue = val
                title.Text = tbl.Name .. " : " .. tostring(tbl.CurrentValue)
                SAFE_CALL(tbl.Callback, tbl.CurrentValue)
            end)
            table.insert(items, fr)
            return {label=title, number=numBox, button=applyBtn}
        end

        function tabObj:CreateDropdown(tbl)
            local fr = Instance.new("Frame"); fr.Size = UDim2.new(1,-8,0,46); fr.BackgroundTransparency = 1
            local title = Instance.new("TextLabel", fr); title.Size = UDim2.new(1,0,0,18); title.BackgroundTransparency = 1; title.Font = Enum.Font.SourceSans; title.TextSize = 13; title.TextColor3 = Color3.fromRGB(210,210,210); title.Text = tbl.Name or "Dropdown"
            local drop = Instance.new("TextButton", fr); drop.Position = UDim2.new(0,0,0,20); drop.Size = UDim2.new(1,-8,0,24); drop.Text = tbl.Default or "Select"; drop.BackgroundColor3 = Color3.fromRGB(45,45,47); drop.Font = Enum.Font.SourceSans; drop.TextSize = 13; drop.TextColor3 = Color3.fromRGB(240,240,240)
            local bc = Instance.new("UICorner", drop); bc.CornerRadius = UDim.new(0,6)
            local optionsFrame = Instance.new("Frame", fr); optionsFrame.Size = UDim2.new(1,-8,0,0); optionsFrame.Position = UDim2.new(0,0,0,46); optionsFrame.BackgroundTransparency = 1; optionsFrame.ClipsDescendants = true
            local opened = false
            local optionsList = Instance.new("UIListLayout", optionsFrame)
            optionsFrame.Visible = false
            drop.MouseButton1Click:Connect(function()
                opened = not opened
                optionsFrame.Visible = opened
                if opened then
                    -- populate
                    for _,opt in ipairs(tbl.Options or {}) do
                        if not optionsFrame:FindFirstChild(opt) then
                            local ob = Instance.new("TextButton", optionsFrame)
                            ob.Name = opt; ob.Size = UDim2.new(1,0,0,28); ob.BackgroundColor3 = Color3.fromRGB(38,38,40); ob.TextColor3 = Color3.fromRGB(230,230,230); ob.Text = opt; ob.Font = Enum.Font.SourceSans; ob.TextSize = 13
                            ob.MouseButton1Click:Connect(function() drop.Text = opt; SAFE_CALL(tbl.Callback, opt); optionsFrame.Visible = false; opened = false end)
                        end
                    end
                    recalcCanvas(optionsFrame)
                else
                    -- hide
                end
            end)
            table.insert(items, fr)
            return {frame=fr, button=drop}
        end

        function tabObj._render(parent)
            for _,v in ipairs(items) do
                v.Parent = parent
            end
            recalcCanvas(parent)
        end

        btn.MouseButton1Click:Connect(function()
            -- highlight
            for _,t in ipairs(tabs) do if t._btn then pcall(function() t._btn.BackgroundColor3 = Color3.fromRGB(40,40,42) end) end end
            btn.BackgroundColor3 = Color3.fromRGB(64,64,66)
            -- clear content
            for _,c in ipairs(contentScroll:GetChildren()) do if not c:IsA("UIListLayout") then pcall(function() c:Destroy() end) end end
            -- render items
            SAFE_CALL(tabObj._render, contentScroll)
        end)

        tabObj._btn = btn
        table.insert(tabs, tabObj)
        -- update canvas of tabsList
        task.defer(function() pcall(function() tabsList.CanvasSize = UDim2.new(0,0,0, uiGrid.AbsoluteContentSize.Y + 12) end) end)
        return tabObj
    end

    function API:CreateTab(name) return makeTab(name) end
    function API:Notify(tbl)
        pcall(function()
            StarterGui:SetCore("SendNotification", {Title = tbl.Title or "GMON", Text = tbl.Content or "", Duration = tbl.Duration or 3})
        end)
    end
    function API:CreateNotification() end

    return API
end

-- Create window (Rayfield if present)
local function createWindow(title)
    if GMON.Rayfield and type(GMON.Rayfield.CreateWindow) == "function" then
        local ok, w = pcall(function()
            return GMON.Rayfield:CreateWindow({
                Name = title,
                LoadingTitle = title,
                LoadingSubtitle = "Ready",
                ConfigurationSaving = { Enabled = true, FolderName = "GMON_Settings" }
            })
        end)
        if ok and w then return w end
    end
    return createCustomWindow(title)
end

GMON.Window = createWindow("G-MON Hub")
local win = GMON.Window -- convenience

-- STATUS GUI (draggable + update)
do
    local sg = Instance.new("ScreenGui")
    sg.Name = "GMonStatusGui"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = LP:WaitForChild("PlayerGui") end)

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 340, 0, 140)
    frame.Position = UDim2.new(1, -350, 0, 16)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -16, 0, 26)
    title.Position = UDim2.new(0, 8, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "G-MON Status"
    title.TextColor3 = Color3.fromRGB(240,240,240)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left

    local runtime = Instance.new("TextLabel", frame)
    runtime.Size = UDim2.new(1, -16, 0, 18)
    runtime.Position = UDim2.new(0, 8, 0, 36)
    runtime.BackgroundTransparency = 1
    runtime.Font = Enum.Font.SourceSans
    runtime.TextSize = 13
    runtime.TextColor3 = Color3.fromRGB(200,200,200)
    runtime.Text = "Runtime: 00:00"

    local info_blox = Instance.new("TextLabel", frame)
    info_blox.Size = UDim2.new(1, -16, 0, 16)
    info_blox.Position = UDim2.new(0,8,0,58)
    info_blox.BackgroundTransparency = 1
    info_blox.Font = Enum.Font.SourceSans
    info_blox.TextSize = 13
    info_blox.TextColor3 = Color3.fromRGB(200,200,200)
    info_blox.Text = "Blox: OFF"

    local info_car = info_blox:Clone(); info_car.Parent = frame
    info_car.Position = UDim2.new(0,8,0,76); info_car.Text = "Car: OFF"

    local info_boat = info_blox:Clone(); info_boat.Parent = frame
    info_boat.Position = UDim2.new(0,8,0,94); info_boat.Text = "Boat: OFF"

    local last = info_blox:Clone(); last.Parent = frame
    last.Position = UDim2.new(0,8,0,112); last.Text = "Last: Idle"

    GMON.Status = {
        Gui = sg,
        Frame = frame,
        Runtime = runtime,
        Blox = info_blox,
        Car = info_car,
        Boat = info_boat,
        Last = last
    }

    -- draggable
    do
        local dragging, startPos, startMouse = false, nil, nil
        local function getMouse() return UIS:GetMouseLocation() end
        frame.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true; startMouse = getMouse(); startPos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                local delta = getMouse() - startMouse
                local newPos = startPos + delta
                local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800,600)
                frame.Position = UDim2.new(0, math.clamp(newPos.X, 0, vp.X - frame.AbsoluteSize.X), 0, math.clamp(newPos.Y, 0, vp.Y - frame.AbsoluteSize.Y))
            end
        end)
    end

    -- update loop
    task.spawn(function()
        while task.wait(1) do
            local elapsed = os.time() - GMON.StartTime
            pcall(function()
                GMON.Status.Runtime.Text = "Runtime: " .. Utils.FormatTime(elapsed)
                GMON.Status.Blox.Text = "Blox: " .. (GMON.Flags.Blox and "ON" or "OFF")
                GMON.Status.Car.Text = "Car: " .. (GMON.Flags.Car and "ON" or "OFF")
                GMON.Status.Boat.Text = "Boat: " .. (GMON.Flags.Boat and "ON" or "OFF")
                GMON.Status.Last.Text = "Last: "..(GMON.LastAction or "Idle")
            end)
        end
    end)
end

-- MODULE: BLOX FRUIT (fixed / same design)
do
    local M = {}
    M.config = { attack_delay = 0.35, range = 12, long_range = false, fast_attack = false, auto_stats = false, stat_to = "Melee" }
    M.running = false
    M._task = nil

    local function findEnemies()
        local hints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","NPCs"}
        for _,h in ipairs(hints) do local f = Workspace:FindFirstChild(h); if f then return f end end
        -- fallback: return nil so caller doesn't scan whole workspace uncontrolled
        return nil
    end

    local function nearestEnemy(hrp)
        local folder = findEnemies()
        if not folder then return nil end
        local best, bestDist = nil, math.huge
        for _,mob in ipairs(folder:GetDescendants()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") then
                local hum = mob:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < bestDist and d <= (M.config.range or 12) then bestDist, best = d, mob end
                end
            end
        end
        return best
    end

    local function attackLoop()
        while M.running do
            SAFE_WAIT( M.config.attack_delay or 0.35 )
            SAFE_CALL(function()
                if not M.running then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local target = nearestEnemy(hrp)
                if not target then return end
                if M.config.long_range then
                    local dmg = M.config.fast_attack and 35 or 20
                    local hits = M.config.fast_attack and 3 or 1
                    for i=1,hits do pcall(function() if target and target:FindFirstChildOfClass("Humanoid") then target:FindFirstChildOfClass("Humanoid"):TakeDamage(dmg) end end) end
                    GMON.LastAction = "Blox LongHit -> "..tostring(target.Name or "mob")
                else
                    pcall(function() hrp.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
                    if M.config.fast_attack then
                        for i=1,3 do pcall(function() if target and target:FindFirstChildOfClass("Humanoid") then target:FindFirstChildOfClass("Humanoid"):TakeDamage(30) end end) end
                        GMON.LastAction = "Blox FastMelee -> "..tostring(target.Name or "mob")
                    else
                        pcall(function() if target and target:FindFirstChildOfClass("Humanoid") then target:FindFirstChildOfClass("Humanoid"):TakeDamage(18) end end)
                        GMON.LastAction = "Blox Melee -> "..tostring(target.Name or "mob")
                    end
                end
                if M.config.auto_stats then
                    pcall(function()
                        local rem = game:GetService("ReplicatedStorage"):FindFirstChild("CommF_") or (game:GetService("ReplicatedStorage").Remotes and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_"))
                        if rem and rem.InvokeServer then rem:InvokeServer("AddPoint", M.config.stat_to) end
                    end)
                end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true; GMON.Flags.Blox = true
        M._task = task.spawn(attackLoop)
    end
    function M.stop()
        M.running = false; GMON.Flags.Blox = false; M._task = nil
    end
    function M.ExposeConfig()
        return {
            { type="slider", name="Range (studs)", min=2, max=60, current=M.config.range, onChange=function(v) M.config.range = v end },
            { type="slider", name="Attack Delay (ms)", min=50, max=1000, current=math.floor(M.config.attack_delay*1000), onChange=function(v) M.config.attack_delay = v/1000 end },
            { type="toggle", name="Fast Attack", current=M.config.fast_attack, onChange=function(v) M.config.fast_attack = v end },
            { type="toggle", name="Long Range Hit", current=M.config.long_range, onChange=function(v) M.config.long_range = v end },
            { type="toggle", name="Auto Upgrade Stats", current=M.config.auto_stats, onChange=function(v) M.config.auto_stats = v end }
        }
    end

    GMON.Modules.Blox = M
end

-- MODULE: CAR DEALERSHIP TYCOON
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
            if o and o.Value then return tostring(o.Value) end
            if m.GetAttribute then return m:GetAttribute("Owner") end
            return nil
        end)
        if ok and ownerVal and tostring(ownerVal) == tostring(LP.Name) then return true end
        local ok2, idVal = pcall(function()
            local v = m:FindFirstChild("OwnerUserId") or m:FindFirstChild("UserId")
            if v and v.Value then return tonumber(v.Value) end
            if m.GetAttribute then return m:GetAttribute("OwnerUserId") end
            return nil
        end)
        if ok2 and tonumber(idVal) and tonumber(idVal) == LP.UserId then return true end
        return false
    end

    local function choosePlayerCar()
        local root = Workspace:FindFirstChild("Cars") or Workspace
        local candidates = {}
        for _,m in ipairs(root:GetDescendants()) do
            if m:IsA("Model") and m.PrimaryPart then
                if isOwnedByPlayer(m) then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then
            for _,m in ipairs(root:GetDescendants()) do
                if m:IsA("Model") and m.PrimaryPart and #m:GetDescendants() > 5 then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then return nil end
        table.sort(candidates, function(a,b) return #a:GetDescendants() > #b:GetDescendants() end)
        return candidates[1]
    end

    -- expose alias expected by UI
    M.choosePlayerFastestCar = choosePlayerCar
    M.choosePlayerCar = choosePlayerCar

    local function ensureLV(part)
        if not part then return nil end
        local att = part:FindFirstChild("_GmonAttach")
        if not att then
            att = Instance.new("Attachment")
            att.Name = "_GmonAttach"
            att.Parent = part
        end
        local lv = part:FindFirstChild("_GmonLV")
        if not lv then
            lv = Instance.new("LinearVelocity")
            lv.Name = "_GmonLV"
            lv.Attachment0 = att
            lv.MaxForce = math.huge
            lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
            lv.Parent = part
        end
        return lv
    end

    local function driveLoop()
        while M.running do
            task.wait(0.12)
            SAFE_CALL(function()
                if not M.running then return end
                if not M.chosen or not M.chosen.PrimaryPart then
                    local car = choosePlayerCar()
                    if not car or not car.PrimaryPart then GMON.Flags.Car = false; return end
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
                    local lv = ensureLV(prim)
                    if lv then lv.VectorVelocity = prim.CFrame.LookVector * (M.speed or 60) end
                end
            end)
        end
    end

    function M.start()
        if M.running then return end
        M.running = true; GMON.Flags.Car = true
        M._task = task.spawn(driveLoop)
    end
    function M.stop()
        M.running = false; GMON.Flags.Car = false
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
            end)
        end
        M.chosen = nil
    end

    function M.TryBuy(modelName)
        local rem = Workspace:FindFirstChild("BuyCar") or (game:GetService("ReplicatedStorage").Remotes and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("BuyCar"))
        if rem and rem:IsA("RemoteEvent") then SAFE_CALL(function() rem:FireServer(modelName) end); return true end
        warn("[GMON] Car buy remote not found.")
        return false
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Car Speed", min=20, max=200, current=M.speed, onChange=function(v) M.speed = v end }
        }
    end

    GMON.Modules.Car = M
end

-- MODULE: BUILD A BOAT
do
    local M = {}
    M.running = false; M.delay = 1.5; M._task = nil
    M.teleports = { spawn = CFrame.new(0,5,0), shop = CFrame.new(10,5,0), build_area = CFrame.new(0,5,50) }
    M.PlacePartFunction = nil

    local function collectStages(root)
        local out = {}
        if not root then return out end
        for _,obj in ipairs(root:GetDescendants()) do
            if obj:IsA("BasePart") then
                local lname = string.lower(obj.Name or "")
                local ok,col = pcall(function() return obj.Color end)
                local isDark = false
                if ok and col then if (col.R + col.G + col.B) / 3 < 0.2 then isDark = true end end
                if isDark or string.find(lname,"stage") or string.find(lname,"black") or string.find(lname,"trigger") or string.find(lname,"dark") then
                    table.insert(out, obj)
                end
            end
        end
        return out
    end

    local function autoLoop()
        while M.running do
            task.wait(0.2)
            SAFE_CALL(function()
                if not M.running then return end
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

                local roots = {}
                for _,n in ipairs({"BoatStages","Stages","NormalStages","StageFolder","BoatStage"}) do local r = Workspace:FindFirstChild(n); if r then table.insert(roots, r) end end
                if #roots == 0 then table.insert(roots, Workspace) end

                local stages = {}
                for _,r in ipairs(roots) do
                    local s = collectStages(r)
                    for _,p in ipairs(s) do table.insert(stages, p) end
                end
                if #stages == 0 then
                    for _,obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") and string.find(string.lower(obj.Name or ""), "stage") then table.insert(stages,obj) end end
                end
                if #stages == 0 then GMON.Flags.Boat = false; M.running = false; return end

                local seen, uniq = {}, {}
                for _,p in ipairs(stages) do
                    if p and p.Position then
                        local key = string.format("%.2f_%.2f_%.2f", p.Position.X, p.Position.Y, p.Position.Z)
                        if not seen[key] then seen[key] = true; table.insert(uniq, p) end
                    end
                end
                stages = uniq
                table.sort(stages, function(a,b) return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude end)

                for _,part in ipairs(stages) do
                    if not M.running then break end
                    if part and part.Parent then pcall(function() hrp.CFrame = part.CFrame * CFrame.new(0,3,0) end) end
                    SAFE_WAIT(M.delay or 1.2)
                end

                local candidate = nil
                for _,v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then local ln = string.lower(v.Name or ""); if string.find(ln,"chest") or string.find(ln,"treasure") or string.find(ln,"golden") then candidate = v; break end
                    elseif v:IsA("Model") and v.PrimaryPart then local ln = string.lower(v.Name or ""); if string.find(ln,"chest") or string.find(ln,"treasure") or string.find(ln,"golden") then candidate = v.PrimaryPart; break end
                    end
                end
                if candidate then pcall(function() hrp.CFrame = candidate.CFrame * CFrame.new(0,3,0) end) end
            end)
        end
    end

    function M.start() if M.running then return end M.running=true; GMON.Flags.Boat=true; M._task = task.spawn(autoLoop) end
    function M.stop() M.running=false; GMON.Flags.Boat=false; M._task=nil end
    function M.TeleportTo(name) local preset = M.teleports[name]; if not preset then warn("Preset not found:", name); return end; local char = Utils.SafeChar(); if not char then return end; local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp then pcall(function() hrp.CFrame = preset end) end end
    function M.AutoBuildOnce(list) if not list or #list==0 then return false,"No parts" end if type(M.PlacePartFunction)~="function" then return false,"Set PlacePartFunction" end local char = Utils.SafeChar(); if not char then return false,"No char" end local base=(char.PrimaryPart and char.PrimaryPart.CFrame) or CFrame.new(0,5,0); for i,name in ipairs(list) do local pos = base * CFrame.new(0,0,2*i); local ok,res = pcall(function() return M.PlacePartFunction(name,pos) end); if not ok or res==false then warn("[GMON AutoBuild] failed", name, tostring(res)) end SAFE_WAIT(0.15) end return true end
    function M.ExposeConfig() return { { type="slider", name="Stage Delay (s)", min=0.2, max=6, current=M.delay, onChange=function(v) M.delay=v end } } end

    GMON.Modules.Boat = M
end

-- GOLD TRACKER (safe)
do
    local Gold = {}
    Gold.running = false; Gold.guiobj = nil
    local function create()
        local player = LP
        if not player then return nil end
        local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        local scr = Instance.new("ScreenGui"); scr.Name="GMonGoldGui"; scr.ResetOnSpawn=false; scr.Parent=pg
        local f = Instance.new("Frame", scr); f.Size = UDim2.new(0, 280, 0, 160); f.Position = UDim2.new(0,10,0,10); f.BackgroundColor3=Color3.fromRGB(0,0,0); f.BackgroundTransparency=0.12; f.BorderSizePixel=0
        local corner = Instance.new("UICorner", f); corner.CornerRadius=UDim.new(0,10)
        local stroke = Instance.new("UIStroke", f); stroke.Color = Color3.fromRGB(50,50,50); stroke.Thickness = 2
        local labels = {}
        local rows = {"Start:","Current:","Gained:","Time:"}
        for i,t in ipairs(rows) do
            local r = Instance.new("Frame", f); r.Size = UDim2.new(1,-20,0,30); r.Position = UDim2.new(0,10,0,15 + (i-1)*35); r.BackgroundTransparency = 1
            local left = Instance.new("TextLabel", r); left.Size = UDim2.new(0.6,0,1,0); left.BackgroundTransparency=1; left.Font=Enum.Font.Gotham; left.TextSize=14; left.TextColor3=Color3.fromRGB(180,180,180); left.Text = t
            local right = Instance.new("TextLabel", r); right.Size = UDim2.new(0.4,0,1,0); right.Position = UDim2.new(0.6,0,0,0); right.BackgroundTransparency=1; right.Font=Enum.Font.GothamBold; right.TextSize=14; right.TextColor3=Color3.fromRGB(255,255,255); right.Text="0"
            labels[i]=right
        end
        return {Gui=scr, Frame=f, Labels=labels, StartTime=os.time()}
    end
    local function findNumeric(root)
        if not root then return nil end
        if root:IsA("TextLabel") then local txt = tostring(root.Text or ""):gsub("%s",""); if txt~="" then local num = txt:match("(%d+)"); if num then return root end end end
        for _,c in ipairs(root:GetChildren()) do local f = findNumeric(c); if f then return f end end
        return nil
    end
    local function loop(gui)
        if not gui then return end
        local playerGui = LP:WaitForChild("PlayerGui")
        local goldLabel = nil
        local startAmount = 0 local gained = 0
        gui.Labels[1].Text="0"; gui.Labels[2].Text="0"; gui.Labels[3].Text="0"; gui.Labels[4].Text="00:00"
        while Gold.running do
            if not goldLabel or not goldLabel.Parent then
                if playerGui:FindFirstChild("GoldGui") and playerGui.GoldGui:FindFirstChild("Frame") then goldLabel = findNumeric(playerGui.GoldGui.Frame) else goldLabel = findNumeric(playerGui) end
                if goldLabel then startAmount = tonumber((goldLabel.Text or ""):gsub("[^%d]","")) or 0 end
                gui.Labels[1].Text = tostring(startAmount)
            end
            if goldLabel and goldLabel.Parent then
                local cur = tonumber((goldLabel.Text or ""):gsub("[^%d]","")) or 0
                gui.Labels[2].Text = tostring(cur)
                if cur > startAmount then gained = gained + (cur - startAmount); gui.Labels[3].Text = tostring(gained); startAmount = cur
                elseif cur < startAmount then startAmount = cur end
            end
            local elapsed = os.time() - gui.StartTime
            gui.Labels[4].Text = string.format("%02d:%02d", math.floor(elapsed/60), elapsed%60)
            task.wait(1)
        end
    end
    function Gold.start() if Gold.running then return end Gold.running=true; Gold.guiobj = create(); if Gold.guiobj then task.spawn(function() loop(Gold.guiobj) end) end GMON.Flags.Gold = true end
    function Gold.stop() Gold.running=false; GMON.Flags.Gold=false; if Gold.guiobj and Gold.guiobj.Gui and Gold.guiobj.Gui.Parent then pcall(function() Gold.guiobj.Gui:Destroy() end) end Gold.guiobj=nil end
    GMON.Modules.GoldTracker = Gold
end

-- SYSTEM: God Mode, Rejoin, ServerHop
do
    local S = {}
    S.God = false; S._loop = nil
    function S.EnableGod(v)
        S.God = not not v
        if S._loop then S._loop = nil end
        if S.God then
            S._loop = task.spawn(function()
                while S.God do
                    local c = Utils.SafeChar()
                    if c then local hum = c:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.MaxHealth = 1e8; hum.Health = hum.MaxHealth end) end end
                    task.wait(1)
                end
            end)
        end
    end
    function S.Rejoin() pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) end
    function S.ServerHop()
        SAFE_CALL(function()
            if not HttpService.HttpEnabled then S.Rejoin(); return end
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            local resp = game:HttpGet(url)
            local data = HttpService:JSONDecode(resp)
            if data and data.data then
                for _,srv in ipairs(data.data) do
                    if srv.playing and srv.playing < (srv.maxPlayers or 0) and srv.id then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                        return
                    end
                end
            end
            S.Rejoin()
        end)
    end
    GMON.System = S
end

-- PROFILE save/load (safe)
do
    local folder = "GMON_Profiles"
    local filename = folder .. "/" .. tostring(Utils.FlexibleDetectGame() or "UNKNOWN") .. ".json"

    local function ensureFolder()
        local ok = pcall(function() if isfolder and not isfolder(folder) then makefolder(folder) end end)
        return ok
    end

    function GMON.SaveProfile()
        SAFE_CALL(function()
            ensureFolder()
            local data = {
                Blox = GMON.Modules.Blox and GMON.Modules.Blox.config or nil,
                Car = GMON.Modules.Car and { speed = GMON.Modules.Car.speed } or nil,
                Boat = GMON.Modules.Boat and { delay = GMON.Modules.Boat.delay } or nil
            }
            if writefile then
                local ok, err = pcall(function() writefile(filename, HttpService:JSONEncode(data)) end)
                if not ok then warn("[GMON] writefile failed:", err) end
            else
                print("[GMON] writefile unsupported in this executor.")
            end
        end)
    end

    function GMON.LoadProfile()
        SAFE_CALL(function()
            if isfile and isfile(filename) then
                local raw = readfile(filename)
                local data = HttpService:JSONDecode(raw)
                if data and data.Blox and GMON.Modules.Blox then for k,v in pairs(data.Blox) do GMON.Modules.Blox.config[k] = v end end
                if data and data.Car and GMON.Modules.Car then GMON.Modules.Car.speed = data.Car.speed or GMON.Modules.Car.speed end
                if data and data.Boat and GMON.Modules.Boat then GMON.Modules.Boat.delay = data.Boat.delay or GMON.Modules.Boat.delay end
            else
                print("[GMON] No profile file found or filesystem unsupported.")
            end
        end)
    end

    pcall(function() GMON.LoadProfile() end)
end

-- UI BUILD
do
    local win = GMON.Window
    local function createTabSafe(name)
        if not win then error("No window API present") end
        if type(win.CreateTab) == "function" then return win:CreateTab(name) end
        -- Rayfield different naming maybe: try colon call
        if type(win.CreateWindow) == "function" and type(win.CreateWindow.CreateTab) == "function" then
            return win.CreateWindow.CreateTab(name)
        end
        error("Window API doesn't support CreateTab")
    end

    local Tabs = {}
    Tabs.Settings = createTabSafe("Settings")
    Tabs.Info = createTabSafe("Info")
    Tabs.Main = createTabSafe("Main")
    Tabs.TabBlox = createTabSafe("Blox Fruit")
    Tabs.TabCar = createTabSafe("Car Tycoon")
    Tabs.TabBoat = createTabSafe("Build A Boat")
    GMON.Tabs = Tabs

    -- SETTINGS
    SAFE_CALL(function()
        local t = Tabs.Settings
        if t.CreateLabel then t:CreateLabel("Settings & Profiles") end
        if t.CreateButton then
            t:CreateButton({ Name = "Save Profile (now)", Callback = function() SAFE_CALL(GMON.SaveProfile); (win.Notify and win:Notify or function() end)({Title="GMON", Content="Profile saved", Duration=2}) end })
        end
        if t.CreateButton then
            t:CreateButton({ Name = "Load Profile (now)", Callback = function() SAFE_CALL(GMON.LoadProfile); (win.Notify and win:Notify or function() end)({Title="GMON", Content="Profile loaded", Duration=2}) end })
        end
        if t.CreateToggle then t:CreateToggle({ Name = "Auto Save Every 10s", CurrentValue = true, Callback = function(v) GMON.Flags.AutoSave = v end }) end
        if t.CreateToggle then t:CreateToggle({ Name = "Enable God Mode", CurrentValue = false, Callback = function(v) GMON.System.EnableGod(v) end }) end
    end)

    -- INFO
    SAFE_CALL(function()
        local t = Tabs.Info
        if t.CreateLabel then t:CreateLabel("Information") end
        if t.CreateParagraph then t:CreateParagraph({ Title = "Detected", Content = Utils.ShortLabel(Utils.FlexibleDetectGame()) }) end
        if t.CreateToggle then t:CreateToggle({ Name = "Gold Tracker (cross-game)", CurrentValue = false, Callback = function(v) if v then GMON.Modules.GoldTracker.start() else GMON.Modules.GoldTracker.stop() end end }) end
        if t.CreateButton then t:CreateButton({ Name = "Open Profiles Folder", Callback = function()
            if isfolder then
                if isfolder("GMON_Profiles") then (win.Notify and win:Notify or function() end)({Title="GMON", Content="Profiles folder exists", Duration=2}) else (win.Notify and win:Notify or function() end)({Title="GMON", Content="Profiles folder missing", Duration=2}) end
            else
                (win.Notify and win:Notify or function() end)({Title="GMON", Content="Filesystem unsupported", Duration=3})
            end
        end }) end
    end)

    -- MAIN
    SAFE_CALL(function()
        local t = Tabs.Main
        if t.CreateLabel then t:CreateLabel("Main Controls") end
        if t.CreateButton then t:CreateButton({ Name = "Force Detect", Callback = function() local d = Utils.FlexibleDetectGame(); GMON.Flags.Detected = d; (win.Notify and win:Notify or function() end)({Title="GMON", Content="Detected: "..tostring(d), Duration=3}) end }) end
        if t.CreateButton then t:CreateButton({ Name = "Stop All Modules", Callback = function() SAFE_CALL(GMON.Modules.Blox.stop); SAFE_CALL(GMON.Modules.Car.stop); SAFE_CALL(GMON.Modules.Boat.stop); SAFE_CALL(GMON.Modules.GoldTracker.stop) end }) end
        if t.CreateButton then t:CreateButton({ Name = "Start All Modules (if applicable)", Callback = function() SAFE_CALL(function() local g = Utils.FlexibleDetectGame(); if g=="BLOX_FRUIT" then GMON.Modules.Blox.start() end if g=="CAR_TYCOON" then GMON.Modules.Car.start() end if g=="BUILD_A_BOAT" then GMON.Modules.Boat.start() end end) end }) end
        if t.CreateButton then t:CreateButton({ Name = "Rejoin", Callback = function() GMON.System.Rejoin() end }) end
        if t.CreateButton then t:CreateButton({ Name = "ServerHop", Callback = function() GMON.System.ServerHop() end }) end
    end)

    -- BLOX TAB
    SAFE_CALL(function()
        local t = Tabs.TabBlox
        if t.CreateLabel then t:CreateLabel("Blox Fruit Controls") end
        if t.CreateToggle then t:CreateToggle({ Name = "Blox Auto (module)", CurrentValue = false, Callback = function(v) if v then GMON.Modules.Blox.start() else GMON.Modules.Blox.stop() end end }) end
        if t.CreateToggle then t:CreateToggle({ Name = "Fast Attack", CurrentValue = GMON.Modules.Blox.config.fast_attack, Callback = function(v) GMON.Modules.Blox.config.fast_attack = v end }) end
        if t.CreateToggle then t:CreateToggle({ Name = "Long Range Hit", CurrentValue = GMON.Modules.Blox.config.long_range, Callback = function(v) GMON.Modules.Blox.config.long_range = v end }) end
        if t.CreateSlider then t:CreateSlider({ Name = "Range Farming (studs)", Range = {1,50}, Increment = 1, CurrentValue = GMON.Modules.Blox.config.range or 12, Callback = function(v) GMON.Modules.Blox.config.range = v end }) end
        if t.CreateSlider then t:CreateSlider({ Name = "Attack Delay (ms)", Range = {50,1000}, Increment = 25, CurrentValue = math.floor((GMON.Modules.Blox.config.attack_delay or 0.35)*1000), Callback = function(v) GMON.Modules.Blox.attack_delay = v/1000; GMON.Modules.Blox.config.attack_delay = v/1000 end }) end
    end)

    -- CAR TAB
    SAFE_CALL(function()
        local t = Tabs.TabCar
        if t.CreateLabel then t:CreateLabel("Car Dealership Controls") end
        if t.CreateToggle then t:CreateToggle({ Name = "Car AutoDrive", CurrentValue = false, Callback = function(v) if v then GMON.Modules.Car.start() else GMON.Modules.Car.stop() end end }) end
        if t.CreateSlider then t:CreateSlider({ Name = "Car Speed", Range = {20,200}, Increment = 5, CurrentValue = GMON.Modules.Car.speed or 60, Callback = function(v) GMON.Modules.Car.speed = v end }) end
        if t.CreateButton then t:CreateButton({ Name = "Choose Player Car", Callback = function()
            local chosen = GMON.Modules.Car.choosePlayerFastestCar and GMON.Modules.Car.choosePlayerFastestCar() or GMON.Modules.Car.chosen
            if chosen then (win.Notify and win:Notify or function() end)({Title="GMON", Content="Chosen car: "..tostring(chosen.Name), Duration=3}) else (win.Notify and win:Notify or function() end)({Title="GMON", Content="No car found", Duration=3}) end
        end }) end
    end)

    -- BOAT TAB
    SAFE_CALL(function()
        local t = Tabs.TabBoat
        if t.CreateLabel then t:CreateLabel("Build A Boat Controls") end
        if t.CreateToggle then t:CreateToggle({ Name = "Boat Auto Stages", CurrentValue = false, Callback = function(v) if v then GMON.Modules.Boat.start() else GMON.Modules.Boat.stop() end end }) end
        if t.CreateSlider then t:CreateSlider({ Name = "Stage Delay (s)", Range = {0.2,6}, Increment = 0.1, CurrentValue = GMON.Modules.Boat.delay or 1.5, Callback = function(v) GMON.Modules.Boat.delay = v end }) end
        if t.CreateButton then t:CreateButton({ Name = "Teleport: Build Area", Callback = function() GMON.Modules.Boat.TeleportTo("build_area") end }) end
        if t.CreateButton then t:CreateButton({ Name = "Teleport: Spawn", Callback = function() GMON.Modules.Boat.TeleportTo("spawn") end }) end
        if t.CreateButton then t:CreateButton({ Name = "Auto Build - Demo", Callback = function()
            local ok,msg = GMON.Modules.Boat.AutoBuildOnce({"Block","Wheel","Cannon"})
            (win.Notify and win:Notify or function() end)({Title="GMON", Content=tostring(ok).." "..tostring(msg), Duration=3})
        end }) end
    end)
end

-- STARTUP & RUNTIME
GMON.Flags.AutoSave = true
task.spawn(function()
    while task.wait(10) do
        if GMON.Flags.AutoSave then SAFE_CALL(GMON.SaveProfile) end
    end
end)

Utils.AntiAFK()

task.spawn(function()
    local det = Utils.FlexibleDetectGame()
    if GMON.Window and GMON.Window.Notify then GMON.Window:Notify({Title="GMON Hub", Content="Loaded. Detected: "..tostring(det), Duration=4}) end
    print("[GMON] Loaded. Detected:", det)
end)

-- Export
local Main = {}
function Main.StartAll() SAFE_CALL(function() GMON.Modules.Blox.start(); GMON.Modules.Car.start(); GMON.Modules.Boat.start() end) end
function Main.StopAll() SAFE_CALL(function() GMON.Modules.Blox.stop(); GMON.Modules.Car.stop(); GMON.Modules.Boat.stop() end) end
Main.GMON = GMON; Main.Utils = Utils; Main.Window = GMON.Window
return Main