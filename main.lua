-- main.lua
-- G-MON Hub (Rebuild)
-- Single-file, modular, readable.
-- Modules: Blox Fruit, Car Dealership Tycoon, Build A Boat
-- Features: AntiAFK, GodMode (persistent), Rejoin/ServerHop fallback, Build teleport presets, Auto-build (generic), GUI with Rayfield fallback.

-- BOOT
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- SAFE helpers
local function safe_pcall(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[GMON] safe_pcall error:", res)
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
    UI = {},
    Flags = {},
    Config = {
        api_key = "", -- optional
        place_map = { -- default place mapping (override as needed)
            BLOX_FRUIT = { placeids = {2753915549} },
            CAR_TYCOON = { placeids = {1554960397} },
            BUILD_A_BOAT = { placeids = {537413528} }
        }
    }
}

-- UTILITIES
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
                    VirtualUser:Button2Down(); task.wait(1); VirtualUser:Button2Up()
                end
            end)
        end)
    end)
end

-- Game detection
function Utils.DetectGame()
    local pid = game.PlaceId
    for key,info in pairs(GMON.Config.place_map) do
        if info.placeids then
            for _,id in ipairs(info.placeids) do
                if id == pid then return key end
            end
        end
    end
    -- heuristic: search workspace for known folders
    local lower = function(s) if not s then return "" end return string.lower(tostring(s)) end
    for _,obj in ipairs(Workspace:GetChildren()) do
        local n = lower(obj.Name)
        if string.find(n,"enemy") or string.find(n,"mob") or string.find(n,"monster") or string.find(n,"quest") then return "BLOX_FRUIT" end
        if string.find(n,"car") or string.find(n,"vehicle") or string.find(n,"dealership") or string.find(n,"garage") then return "CAR_TYCOON" end
        if string.find(n,"boat") or string.find(n,"stage") or string.find(n,"treasure") or string.find(n,"chest") then return "BUILD_A_BOAT" end
    end
    return "UNKNOWN"
end

-- Attempt to load Rayfield (non-fatal)
local Rayfield = nil
do
    local ok, res = pcall(function()
        -- try common rayfield path used previously (if executor allows)
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and res then Rayfield = res end
end

-- SIMPLE FALLBACK UI (if Rayfield not present)
local function makeFallbackWindow(title)
    local W = {}
    W._root = Instance.new("ScreenGui")
    W._root.Name = "GMonFallbackGUI"
    W._root.ResetOnSpawn = false
    safe_pcall(function() W._root.Parent = LP:WaitForChild("PlayerGui") end)
    local frame = Instance.new("Frame", W._root)
    frame.Size = UDim2.new(0, 420, 0, 520)
    frame.Position = UDim2.new(0, 10, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.ClipsDescendants = true
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0,8)
    local titleL = Instance.new("TextLabel", frame)
    titleL.Size = UDim2.new(1, -8, 0, 30)
    titleL.Position = UDim2.new(0,4,0,4)
    titleL.Text = title
    titleL.Font = Enum.Font.SourceSansBold
    titleL.TextSize = 18
    titleL.TextColor3 = Color3.fromRGB(220,220,220)
    titleL.BackgroundTransparency = 1

    local content = Instance.new("Frame", frame)
    content.Position = UDim2.new(0,4,0,40)
    content.Size = UDim2.new(1, -8, 1, -44)
    content.BackgroundTransparency = 1

    function W:CreateTab(name)
        local Tab = {}
        local y = #content:GetChildren() * 36
        local label = Instance.new("TextLabel", content)
        label.Position = UDim2.new(0,2,0,y)
        label.Size = UDim2.new(1,-4,0,32)
        label.Text = "[ "..name.." ]"
        label.Font = Enum.Font.SourceSans
        label.TextSize = 14
        label.TextColor3 = Color3.fromRGB(200,200,200)
        label.BackgroundTransparency = 1

        function Tab:CreateLabel(txt) local L=Instance.new("TextLabel", content); L.Position=UDim2.new(0,6,0,y+36); L.Size=UDim2.new(1,-12,0,20); L.Text=txt; L.BackgroundTransparency=1; L.TextColor3=Color3.fromRGB(200,200,200); L.Font=Enum.Font.SourceSans; L.TextSize=13; y=y+26; return L end
        function Tab:CreateButton(tbl) local b = Instance.new("TextButton", content); b.Position = UDim2.new(0,6,0,y+36); b.Size = UDim2.new(1,-12,0,26); b.Text = tbl.Name or "Button"; b.Font=Enum.Font.SourceSansBold; b.TextSize=14; b.BackgroundColor3=Color3.fromRGB(40,40,40); b.TextColor3=Color3.fromRGB(230,230,230); b.MouseButton1Click:Connect(function() safe_pcall(tbl.Callback) end); y=y+32; return b end
        function Tab:CreateToggle(tbl) local frame = Instance.new("Frame", content); frame.Position = UDim2.new(0,6,0,y+36); frame.Size=UDim2.new(1,-12,0,26); frame.BackgroundTransparency=1; local label = Instance.new("TextLabel", frame); label.Size = UDim2.new(0.8,0,1,0); label.Text = tbl.Name; label.BackgroundTransparency=1; label.TextColor3=Color3.fromRGB(220,220,220); label.Font=Enum.Font.SourceSans; label.TextSize=14; local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0.18,0,1,0); btn.Position = UDim2.new(0.82,0,0,0); btn.Text = tbl.CurrentValue and "ON" or "OFF"; btn.Font=Enum.Font.SourceSansBold; btn.TextSize=14; btn.BackgroundColor3 = tbl.CurrentValue and Color3.fromRGB(30,140,40) or Color3.fromRGB(100,100,100); btn.MouseButton1Click:Connect(function() local nv = not tbl.CurrentValue; tbl.CurrentValue = nv; btn.Text = nv and "ON" or "OFF"; btn.BackgroundColor3 = nv and Color3.fromRGB(30,140,40) or Color3.fromRGB(100,100,100); safe_pcall(tbl.Callback, nv) end); y=y+32; return frame end
        function Tab:CreateSlider(tbl) -- simple slider (not interactive), assume Callback called with number
            local label = Instance.new("TextLabel", content); label.Position = UDim2.new(0,6,0,y+36); label.Size = UDim2.new(1,-12,0,22); label.Text = string.format("%s: %s", tbl.Name, tostring(tbl.CurrentValue)); label.TextColor3=Color3.fromRGB(220,220,220); label.BackgroundTransparency=1; y=y+26
            local btn = Instance.new("TextButton", content); btn.Position = UDim2.new(0,6,0,y+36); btn.Size = UDim2.new(1,-12,0,26); btn.Text = "Set Value"; btn.Font=Enum.Font.SourceSans; btn.TextSize=14; btn.MouseButton1Click:Connect(function()
                local val = tonumber(game:GetService("StarterGui"):GetCore("SendNotification") and "0") -- placeholder (can't prompt)
                -- fallback: just call callback with current value
                safe_pcall(tbl.Callback, tbl.CurrentValue)
            end)
            y=y+32; return {label=label, button=btn}
        end
        return Tab
    end

    function W:Notify(params)
        -- simple print + in-game notification via StarterGui (best-effort)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = params.Title or "G-MON",
                Text = params.Content or "",
                Duration = params.Duration or 3
            })
        end)
        print("[G-MON Notify]", params.Title, params.Content)
    end

    return W
end

-- Build UI (Rayfield if available)
local Window = nil
if Rayfield and type(Rayfield.CreateWindow) == "function" then
    Window = Rayfield:CreateWindow({
        Name = "G-MON Hub",
        LoadingTitle = "G-MON Hub",
        LoadingSubtitle = "Ready",
        ConfigurationSaving = { Enabled = false }
    })
else
    Window = makeFallbackWindow("G-MON Hub")
end
GMON.UI.Window = Window

-- STATUS WIDGET
do
    local status = {}
    status.Gui = Instance.new("ScreenGui")
    status.Gui.Name = "GMonStatus"
    status.Gui.ResetOnSpawn = false
    pcall(function() status.Gui.Parent = LP:WaitForChild("PlayerGui") end)
    local frame = Instance.new("Frame", status.Gui)
    frame.Size = UDim2.new(0,300,0,120)
    frame.Position = UDim2.new(1,-310,0,20)
    frame.BackgroundColor3 = Color3.fromRGB(24,24,24); frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,-12,0,26); title.Position = UDim2.new(0,6,0,6)
    title.BackgroundTransparency = 1; title.Font = Enum.Font.SourceSansBold; title.TextSize = 15; title.TextColor3 = Color3.fromRGB(240,240,240)
    title.Text = "G-MON Status"
    local runtime = Instance.new("TextLabel", frame); runtime.Size=UDim2.new(1,-12,0,18); runtime.Position=UDim2.new(0,6,0,34); runtime.BackgroundTransparency=1; runtime.Font=Enum.Font.SourceSans; runtime.TextSize=13; runtime.TextColor3=Color3.new(0.8,0.8,0.8); runtime.Text="Runtime: 00:00"
    local info_blox = Instance.new("TextLabel", frame); info_blox.Size=UDim2.new(1,-12,0,16); info_blox.Position=UDim2.new(0,6,0,54); info_blox.BackgroundTransparency=1; info_blox.Font=Enum.Font.SourceSans; info_blox.TextSize=13; info_blox.TextColor3=Color3.fromRGB(200,200,200)
    info_blox.Text = "Blox: OFF"
    local info_car = Instance.new("TextLabel", frame); info_car.Size=UDim2.new(1,-12,0,16); info_car.Position=UDim2.new(0,6,0,72); info_car.BackgroundTransparency=1; info_car.Font=Enum.Font.SourceSans; info_car.TextSize=13; info_car.TextColor3=Color3.fromRGB(200,200,200); info_car.Text="Car: OFF"
    local info_boat = Instance.new("TextLabel", frame); info_boat.Size=UDim2.new(1,-12,0,16); info_boat.Position=UDim2.new(0,6,0,90); info_boat.BackgroundTransparency=1; info_boat.Font=Enum.Font.SourceSans; info_boat.TextSize=13; info_boat.TextColor3=Color3.fromRGB(200,200,200); info_boat.Text="Boat: OFF"

    GMON.UI.Status = { Gui = status.Gui, Runtime = runtime, Blox = info_blox, Car = info_car, Boat = info_boat }
    -- update loop
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                GMON.UI.Status.Runtime.Text = "Runtime: " .. Utils.FormatTime(os.time() - GMON.StartTime)
                GMON.UI.Status.Blox.Text = "Blox: " .. (GMON.Flags.Blox and "ON" or "OFF")
                GMON.UI.Status.Car.Text = "Car: " .. (GMON.Flags.Car and "ON" or "OFF")
                GMON.UI.Status.Boat.Text = "Boat: " .. (GMON.Flags.Boat and "ON" or "OFF")
            end)
        end
    end)
end

-- SYSTEM MODULE: AntiAFK, GodMode, Rejoin/ServerHop
do
    local M = {}
    M.GodModeEnabled = false
    M._godLoop = nil

    function M.EnableAntiAFK()
        Utils.AntiAFK()
    end

    function M.SetGodMode(enabled)
        M.GodModeEnabled = enabled
        if enabled then
            if M._godLoop and task.cancel then task.cancel(M._godLoop) end
            M._godLoop = task.spawn(function()
                while M.GodModeEnabled do
                    local character = Utils.SafeChar()
                    if character then
                        local hum = character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            pcall(function()
                                hum.MaxHealth = 1e8
                                hum.Health = hum.MaxHealth
                                -- disable ragdoll/knockback in a safe way
                                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                                hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                            end)
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            M._godLoop = nil
        end
    end

    function M.Rejoin()
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end

    function M.ServerHop()
        -- Best-effort: attempt to query public servers (requires HttpService & allowlist)
        -- If HttpService is not enabled, fallback to Rejoin()
        local success, err = pcall(function()
            if not HttpService.HttpEnabled then error("Http not enabled") end
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            local resp = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(resp)
            if data and data.data then
                local me = LP
                for _,srv in ipairs(data.data) do
                    if srv.playing and (srv.playing < (srv.maxPlayers or 0)) and srv.id then
                        -- try teleport to this server
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                        return
                    end
                end
            end
            -- fallback
            M.Rejoin()
        end)
        if not success then
            warn("[GMON] ServerHop failed:", err)
            pcall(function() M.Rejoin() end)
        end
    end

    GMON.System = M
end

-- MODULE: Blox Fruit (generic auto-farm)
do
    local M = {}
    M.running = false
    M.config = {
        range = 12,
        fast_attack = false,
        long_range = false
    }
    M._task = nil

    local function findEnemyFolder()
        local hints = {"Enemies","Sea1Enemies","Sea2Enemies","Monsters","Mobs","NPCs"}
        for _, name in ipairs(hints) do
            local f = Workspace:FindFirstChild(name)
            if f then return f end
        end
        -- fallback: return first folder with models and humanoids
        for _, c in ipairs(Workspace:GetDescendants()) do
            if c:IsA("Model") and c:FindFirstChildOfClass("Humanoid") then
                return Workspace
            end
        end
        return nil
    end

    local function nearestEnemy(hrp)
        local folder = findEnemyFolder()
        if not folder then return nil end
        local best, bestDist = nil, math.huge
        for _, mob in ipairs(folder:GetDescendants()) do
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
            task.wait(0.12)
            safe_pcall(function()
                if not M.running then return end
                local char = Utils.SafeChar()
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local target = nearestEnemy(hrp)
                if not target then
                    -- optionally go to sea spawn / quest NPC etc.
                    return
                end
                -- generic attack: teleport near and trigger damage attempt
                pcall(function()
                    hrp.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end)
                if M.config.fast_attack then
                    -- multiple hits
                    for i=1,3 do
                        pcall(function()
                            if target and target:FindFirstChildOfClass("Humanoid") then
                                target:FindFirstChildOfClass("Humanoid"):TakeDamage(20)
                            end
                        end)
                        task.wait(0.06)
                    end
                else
                    pcall(function()
                        if target and target:FindFirstChildOfClass("Humanoid") then
                            target:FindFirstChildOfClass("Humanoid"):TakeDamage(12)
                        end
                    end)
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
            { type="toggle", name="Long Range", current=M.config.long_range, onChange=function(v) M.config.long_range = v end }
        }
    end

    GMON.Modules.Blox = M
end

-- MODULE: Car Dealership Tycoon (auto drive & buy utility)
do
    local M = {}
    M.running = false
    M.speed = 80
    M.chosen = nil
    M._task = nil

    local function isPlayerOwned(model)
        if not model then return false end
        if tostring(model.Name) == tostring(LP.Name) then return true end
        -- try common owner attributes
        local ok, owner = pcall(function()
            local o = model:FindFirstChild("Owner") or model:FindFirstChild("OwnerName")
            if o and o.Value then return tostring(o.Value) end
            if model.GetAttribute then return model:GetAttribute("Owner") end
            return nil
        end)
        if ok and owner and tostring(owner) == tostring(LP.Name) then return true end
        -- user id
        local ok2, uid = pcall(function()
            local v = model:FindFirstChild("OwnerUserId") or model:FindFirstChild("UserId")
            if v and v.Value then return tonumber(v.Value) end
            if model.GetAttribute then return model:GetAttribute("OwnerUserId") end
            return nil
        end)
        if ok2 and tonumber(uid) and tonumber(uid) == LP.UserId then return true end
        return false
    end

    local function guessCarsRoot()
        local hints = {"Cars", "Vehicles", "Dealership", "VehiclesFolder", "CarShop"}
        for _,name in ipairs(hints) do
            local f = Workspace:FindFirstChild(name)
            if f then return f end
        end
        return Workspace
    end

    local function chooseOwnCar()
        local root = guessCarsRoot()
        local candidates = {}
        for _,m in ipairs(root:GetDescendants()) do
            if m:IsA("Model") and m.PrimaryPart then
                if isPlayerOwned(m) then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then
            -- fallback pick any model with multiple parts
            for _,m in ipairs(root:GetDescendants()) do
                if m:IsA("Model") and m.PrimaryPart and #m:GetDescendants() > 5 then table.insert(candidates, m) end
            end
        end
        if #candidates == 0 then return nil end
        table.sort(candidates, function(a,b) return #a:GetDescendants() > #b:GetDescendants() end)
        return candidates[1]
    end

    local function ensureLinearVelocityPart(part)
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
                    -- store starting pos
                    if not car:FindFirstChild("_GmonStartPos") then
                        local cv = Instance.new("CFrameValue")
                        cv.Name = "_GmonStartPos"
                        cv.Value = car.PrimaryPart.CFrame
                        cv.Parent = car
                    end
                end
                if car and car.PrimaryPart then
                    local lv = ensureLinearVelocityPart(car.PrimaryPart)
                    if lv then
                        lv.VectorVelocity = car.PrimaryPart.CFrame.LookVector * (M.speed or 80)
                    end
                end
            end)
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
            local prim = M.chosen.PrimaryPart
            pcall(function()
                local lv = prim:FindFirstChild("_GmonLV")
                if lv then lv:Destroy() end
                local att = prim:FindFirstChild("_GmonAttach")
                if att then att:Destroy() end
                local tag = M.chosen:FindFirstChild("_GmonStartPos")
                if tag and tag:IsA("CFrameValue") then
                    pcall(function() M.chosen:SetPrimaryPartCFrame(tag.Value) end)
                    pcall(function() tag:Destroy() end)
                end
            end)
        end
        M.chosen = nil
    end

    -- Generic Buy function (game-specific remote required)
    function M.TryBuySelectedCar(selectedModel)
        -- Example: trigger remote "BuyCar" with args (modelName)
        -- You MUST adapt this based on your private game's remote names/payloads.
        local success, err = pcall(function()
            if not selectedModel then error("No car selected") end
            -- Example: try to find remote
            local rr = Workspace:FindFirstChild("BuyCar") or Workspace:FindFirstChild("RemoteBuyCar")
            if rr and rr:IsA("RemoteEvent") then
                rr:FireServer(selectedModel.Name)
                return true
            end
            -- fallback: try to simulate click on part
            if selectedModel.PrimaryPart then
                local click = selectedModel.PrimaryPart:FindFirstChildOfClass("ClickDetector")
                if click then
                    -- nothing we can do locally to trigger click other than Signal (game may not accept)
                    return true
                end
            end
            error("No buy remote found. Please set correct remote name in script.")
        end)
        if not success then warn("[GMON Car Buy] error:", err) end
        return success
    end

    function M.ExposeConfig()
        return {
            { type="slider", name="Car Speed", min=20, max=200, current=M.speed, onChange=function(v) M.speed = v end }
        }
    end

    GMON.Modules.Car = M
end

-- MODULE: Build A Boat (Auto stages, Teleport presets, Auto build hook)
do
    local M = {}
    M.running = false
    M.delay = 1.2 -- delay between stage visits
    M._task = nil
    M.teleports = { -- default teleport presets (can be edited)
        spawn = CFrame.new(0,5,0),
        shop = CFrame.new(10,5,0),
        build_area = CFrame.new(0,5,50)
    }

    -- Automatic stage collector: tries to walk through parts named 'Stage'/'Black' etc.
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
                    -- fallback search for parts containing "stage"
                    for _,v in ipairs(Workspace:GetDescendants()) do
                        if v:IsA("BasePart") and string.match(string.lower(v.Name or ""),"stage") then table.insert(parts, v) end
                    end
                end
                -- order by distance
                table.sort(parts, function(a,b)
                    return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
                end)
                for _,p in ipairs(parts) do
                    if not M.running then break end
                    if p and p.Parent then
                        pcall(function() hrp.CFrame = p.CFrame * CFrame.new(0,3,0) end)
                        safe_wait(M.delay)
                    end
                end

                -- search for treasure/chest
                local candidate = nil
                for _,v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        local ln = string.lower(v.Name or "")
                        if string.find(ln,"chest") or string.find(ln,"treasure") or string.find(ln,"gold") then candidate = v; break end
                    elseif v:IsA("Model") and v.PrimaryPart then
                        local ln = string.lower(v.Name or "")
                        if string.find(ln,"chest") or string.find(ln,"treasure") or string.find(ln,"gold") then candidate = v.PrimaryPart; break end
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

    -- teleport to preset
    function M.TeleportToPreset(name)
        local preset = M.teleports[name]
        if not preset then warn("Preset not found:", name) return end
        local char = Utils.SafeChar()
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function() hrp.CFrame = preset end)
        end
    end

    -- auto-build generic: This is game-specific. We provide a hook and a naive automator that tries to place items
    -- You should set M.PlacePartFunction = function(partName, positionCFrame) ... end  -> returns true/false
    M.PlacePartFunction = nil -- user-provided hook (adapt to your private game's remote)
    function M.AutoBuildOnce(partNameList)
        -- naive: iterate part names and call PlacePartFunction for relative positions
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
                -- continue to next
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

-- BUILD UI TABS (Rayfield or fallback)
local Tabs = {}
do
    local win = Window
    if win.CreateTab then
        Tabs.Info = win:CreateTab("Info")
        Tabs.TabBlox = win:CreateTab("Blox Fruit")
        Tabs.TabCar = win:CreateTab("Car Tycoon")
        Tabs.TabBoat = win:CreateTab("Build A Boat")
        Tabs.System = win:CreateTab("System")
    else
        Tabs.Info = win:CreateTab("Info")
        Tabs.TabBlox = win:CreateTab("Blox Fruit")
        Tabs.TabCar = win:CreateTab("Car Tycoon")
        Tabs.TabBoat = win:CreateTab("Build A Boat")
        Tabs.System = win:CreateTab("System")
    end

    -- Info
    safe_pcall(function()
        if Tabs.Info.CreateLabel then Tabs.Info:CreateLabel("G-MON Hub - Rebuild (single-file). Use modules per-tab.") end
        if Tabs.Info.CreateParagraph then Tabs.Info:CreateParagraph({Title="Detected", Content = Utils.DetectGame()}) end
        if Tabs.Info.CreateButton then Tabs.Info:CreateButton({Name="Detect Now", Callback=function()
            local g = Utils.DetectGame()
            (Window.Notify and Window.Notify or makeFallbackWindow("G-MON").Notify)({Title="G-MON", Content="Detected: "..tostring(g), Duration=3})
        end}) end
    end)

    -- BLOX
    safe_pcall(function()
        local t = Tabs.TabBlox
        if t.CreateLabel then t:CreateLabel("Blox Fruit Controls") end
        if t.CreateToggle then t:CreateToggle({Name="Auto Farm (Blox)", CurrentValue=false, Callback=function(v) if v then GMON.Modules.Blox.start() else GMON.Modules.Blox.stop() end end}) end
        if t.CreateToggle then t:CreateToggle({Name="Fast Attack", CurrentValue = GMON.Modules.Blox.config.fast_attack, Callback=function(v) GMON.Modules.Blox.config.fast_attack = v end}) end
        if t.CreateSlider then t:CreateSlider({Name="Range", CurrentValue = GMON.Modules.Blox.config.range, Callback=function(v) GMON.Modules.Blox.config.range = v end}) end
    end)

    -- CAR
    safe_pcall(function()
        local t = Tabs.TabCar
        if t.CreateLabel then t:CreateLabel("Car Tycoon Controls") end
        if t.CreateToggle then t:CreateToggle({Name="Car AutoDrive", CurrentValue=false, Callback=function(v) if v then GMON.Modules.Car.start() else GMON.Modules.Car.stop() end end}) end
        if t.CreateSlider then t:CreateSlider({Name="Car Speed", CurrentValue=GMON.Modules.Car.speed, Callback=function(v) GMON.Modules.Car.speed = v end}) end
        if t.CreateButton then t:CreateButton({Name="Choose Player Car", Callback=function()
            local chosen = GMON.Modules.Car.choosePlayerFastestCar and GMON.Modules.Car.choosePlayerFastestCar() or GMON.Modules.Car.chosen
            if chosen then
                (Window.Notify and Window.Notify or makeFallbackWindow("G-MON").Notify)({Title="G-MON", Content="Chosen car: "..tostring(chosen.Name), Duration=3})
            else
                (Window.Notify and Window.Notify or makeFallbackWindow("G-MON").Notify)({Title="G-MON", Content="No car found", Duration=3})
            end
        end}) end
    end)

    -- BOAT
    safe_pcall(function()
        local t = Tabs.TabBoat
        if t.CreateLabel then t:CreateLabel("Build A Boat Controls") end
        if t.CreateToggle then t:CreateToggle({Name="Auto Stages", CurrentValue=false, Callback=function(v) if v then GMON.Modules.Boat.start() else GMON.Modules.Boat.stop() end end}) end
        if t.CreateSlider then t:CreateSlider({Name="Stage Delay (s)", CurrentValue=GMON.Modules.Boat.delay, Callback=function(v) GMON.Modules.Boat.delay = v end}) end
        if t.CreateButton then t:CreateButton({Name="Teleport: Build Area", Callback=function() GMON.Modules.Boat.TeleportToPreset("build_area") end}) end
        if t.CreateButton then t:CreateButton({Name="Teleport: Spawn", Callback=function() GMON.Modules.Boat.TeleportToPreset("spawn") end}) end
        if t.CreateButton then t:CreateButton({Name="Auto Build - Demo", Callback=function()
            -- sample usage: override M.PlacePartFunction in code to match your game's remote.
            local success, msg = GMON.Modules.Boat.AutoBuildOnce({"Block","Wheel","Cannon"})
            (Window.Notify and Window.Notify or makeFallbackWindow("G-MON").Notify)({Title="G-MON", Content=tostring(success) .. " " .. tostring(msg), Duration=3})
        end}) end
    end)

    -- SYSTEM
    safe_pcall(function()
        local t = Tabs.System
        if t.CreateLabel then t:CreateLabel("System") end
        if t.CreateToggle then t:CreateToggle({Name="Anti AFK", CurrentValue=true, Callback=function(v) if v then GMON.System.EnableAntiAFK() end end}) end
        if t.CreateToggle then t:CreateToggle({Name="God Mode", CurrentValue=false, Callback=function(v) GMON.System.SetGodMode(v) end}) end
        if t.CreateButton then t:CreateButton({Name="Rejoin", Callback=function() GMON.System.Rejoin() end}) end
        if t.CreateButton then t:CreateButton({Name="ServerHop", Callback=function() GMON.System.ServerHop() end}) end
    end)
end

-- INIT: detect and show a startup notify
task.spawn(function()
    local detected = Utils.DetectGame()
    (Window.Notify and Window.Notify or makeFallbackWindow("G-MON").Notify)({Title="G-MON Hub", Content="Loaded. Detected: "..tostring(detected), Duration=4})
    print("[G-MON] Loaded. Detected:", detected)
end)

-- Exports & helper for moderator editing
local Main = {}
function Main.StartAll()
    safe_pcall(function()
        GMON.Modules.Blox.start()
        GMON.Modules.Car.start()
        GMON.Modules.Boat.start()
    end)
end
function Main.StopAll()
    safe_pcall(function()
        GMON.Modules.Blox.stop()
        GMON.Modules.Car.stop()
        GMON.Modules.Boat.stop()
    end)
end

Main.GMON = GMON
Main.Utils = Utils
Main.Window = Window

-- RETURN API for loader compatibility
return Main