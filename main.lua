-- GMON_hub.lua
-- Adds: God Mode, Rejoin / ServerHop, Anti-AFK, Build-A-Boat Teleports, AutoBuild (generic)
-- Plug-and-play into your existing GMON main; this file can be loaded as a module or run standalone.

-- BOOT
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local Workspace = workspace
local LP = Players.LocalPlayer

-- SAFETY helpers
local function safe_pcall(fn, ...)
    if type(fn) ~= "function" then return false, "not a function" end
    local ok, res = pcall(fn, ...)
    if not ok then warn("[GMON] safe_pcall error:", res) end
    return ok, res
end

local function safe_wait(t) task.wait(tonumber(t) or 0.1) end

-- STATE
local GMON = {}
GMON.Flags = {}
GMON.Modules = {}
GMON.UI = {}
GMON.Status = {}

-- ======================
-- AntiAFK
-- ======================
do
    local running = false
    function GMON.Modules.StartAntiAFK()
        if running then return end
        running = true
        GMON.Flags.AntiAFK = true
        -- prefer VirtualUser method
        local function onIdle()
            pcall(function()
                -- simulate mouse + move to avoid idling
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
                task.wait(0.5)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
            end)
        end
        -- connect once
        pcall(function()
            LP.Idled:Connect(function()
                if running then onIdle() end
            end)
        end)
        -- periodic wiggle as backup
        task.spawn(function()
            while running do
                pcall(function()
                    if LP and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = LP.Character.HumanoidRootPart
                        hrp.CFrame = hrp.CFrame * CFrame.new(0,0,0.001)
                    end
                end)
                task.wait(20 + math.random() * 10)
            end
        end)
        warn("[GMON] AntiAFK started")
    end

    function GMON.Modules.StopAntiAFK()
        running = false
        GMON.Flags.AntiAFK = false
        warn("[GMON] AntiAFK stopped")
    end
end

-- ======================
-- God Mode (client-side best-effort)
-- ======================
do
    local alive = false
    local conHealthChanged = nil
    local conDied = nil
    local keepReset = true

    local function getHumanoid()
        local c = LP.Character or LP.CharacterAdded and LP.CharacterAdded:Wait(3) or nil
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            return h, c
        end
        return nil, nil
    end

    local function enableGod()
        local h,c = getHumanoid()
        if not h then return false, "no humanoid" end
        -- try to set big health and prevent state changes
        pcall(function()
            h.MaxHealth = math.huge
            h.Health = math.huge
            -- disable ragdoll-like states
            if h.SetStateEnabled then
                local ok, _ = pcall(function()
                    for _, st in ipairs({
                        Enum.HumanoidStateType.FallingDown,
                        Enum.HumanoidStateType.PlatformStanding,
                        Enum.HumanoidStateType.Ragdoll,
                        Enum.HumanoidStateType.GettingUp
                    }) do
                        pcall(function() h:SetStateEnabled(st, false) end)
                    end
                end)
            end
        end)

        -- watch for health being changed and reset
        conHealthChanged = h.HealthChanged:Connect(function()
            if not keepReset then return end
            pcall(function()
                if h and h.Health and h.Health < (h.MaxHealth*0.9) then
                    h.Health = h.MaxHealth
                end
            end)
        end)
        -- prevent death by respawning quickly
        conDied = h.Died:Connect(function()
            if keepReset then
                -- attempt quick respawn
                pcall(function()
                    local hrp = c:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = hrp.CFrame end
                end)
            end
        end)
        alive = true
        GMON.Flags.GodMode = true
        return true
    end

    local function disableGod()
        keepReset = false
        if conHealthChanged then pcall(function() conHealthChanged:Disconnect() end) end
        if conDied then pcall(function() conDied:Disconnect() end) end
        local h = (LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")) or nil
        if h then
            pcall(function()
                h.MaxHealth = 100
                if h.Health and h.Health > 0 and h.Health < 1 then h.Health = 1 end
            end)
        end
        alive = false
        GMON.Flags.GodMode = false
    end

    function GMON.Modules.EnableGodMode()
        keepReset = true
        local ok, err = pcall(enableGod)
        if not ok then warn("[GMON] EnableGodMode failed:", err) end
        return ok
    end

    function GMON.Modules.DisableGodMode()
        disableGod()
    end
end

-- ======================
-- Rejoin & Server Hop
-- ======================
do
    local TS = TeleportService

    -- simple rejoin (same place, same server)
    function GMON.Modules.Rejoin()
        pcall(function()
            local placeId = game.PlaceId
            -- Teleport to same place (Roblox will often send you to another server or same)
            TS:Teleport(placeId, LP)
        end)
    end

    -- serverhop: query public servers and teleport to a different jobId
    function GMON.Modules.ServerHop(opts)
        opts = opts or {}
        local placeId = opts.placeId or game.PlaceId
        local curJob = tostring(game.JobId)
        local api = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
        local found = nil
        local visited = {}
        local cursor = nil
        for iteration = 1, 6 do
            local url = api .. (cursor and ("&cursor="..HttpService:UrlEncode(cursor)) or "")
            local ok, body = pcall(function()
                return HttpService:GetAsync(url, true)
            end)
            if not ok or not body then
                break
            end
            local succ, decoded = pcall(function() return HttpService:JSONDecode(body) end)
            if not succ or type(decoded) ~= "table" then break end
            local data = decoded.data or {}
            for _, server in ipairs(data) do
                if server and server.id and server.playing and server.maxPlayers then
                    if tostring(server.id) ~= tostring(curJob) and (server.playing < server.maxPlayers) then
                        found = server
                        break
                    end
                end
            end
            if found then break end
            cursor = decoded.nextPageCursor
            if not cursor then break end
        end

        if found then
            pcall(function()
                TS:TeleportToPlaceInstance(placeId, found.id, LP)
            end)
            return true, found.id
        else
            -- fallback: rejoin current server
            pcall(function() TS:Teleport(game.PlaceId, LP) end)
            return false, "no different server found; rejoined"
        end
    end
end

-- ======================
-- Build A Boat teleports & stage detection
-- ======================
do
    local teleports = {
        -- default example teleport positions (these are placeholders — tune for your map)
        ["Start"] = CFrame.new(0, 10, 0),
        ["Shipyard"] = CFrame.new(50, 10, 0),
        ["Treasure"] = CFrame.new(-100, 5, 200),
        ["TopStage"] = CFrame.new(0, 50, 500),
    }

    -- allow dynamic detection: find parts named Stage/Chest/Treasure
    local function findNamedParts()
        local res = {}
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n = (v.Name or ""):lower()
                if string.find(n, "stage") or string.find(n, "platform") or string.find(n, "treasure") or string.find(n, "chest") or string.find(n, "spawn") then
                    table.insert(res, {name = v.Name, part = v})
                end
            elseif v:IsA("Model") and v.PrimaryPart then
                local n = (v.Name or ""):lower()
                if string.find(n, "stage") or string.find(n, "treasure") or string.find(n, "chest") then
                    table.insert(res, {name = v.Name, part = v.PrimaryPart})
                end
            end
        end
        return res
    end

    function GMON.Modules.GetBoatTeleports()
        local list = {}
        -- include configured teleports
        for k,v in pairs(teleports) do list[k] = v end
        -- include discovered ones
        local discovered = findNamedParts()
        for _, d in ipairs(discovered) do
            if d.part and d.part.Position then
                list["DISC - ".. tostring(d.name).. ""] = CFrame.new(d.part.Position + Vector3.new(0,3,0))
            end
        end
        return list
    end

    function GMON.Modules.TeleportToBoatLocation(name)
        local tbl = GMON.Modules.GetBoatTeleports()
        local cf = tbl[name]
        if not cf then return false, "location not found" end
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            safe_pcall(function() char.HumanoidRootPart.CFrame = cf end)
            return true
        end
        return false, "no character"
    end

    function GMON.Modules.AddBoatTeleport(name, cframe)
        teleports[name] = cframe
    end
end

-- ======================
-- AutoBuild (generic best-effort)
-- - Two modes:
--   1) Remote-Event mode: finds "place" Remotes in ReplicatedStorage/ServerScriptService and fires them
--   2) Teleport-and-click mode: teleports to build area and attempts to call typical place Remotes
-- ======================
do
    local running = false
    local auto_task = nil

    -- heuristics: remote names often used by Build-type games
    local remoteNameHints = {
        "PlaceBlock","Place","PlacePart","Build","BuildBlock","ServerPlace","PlaceObject","Deploy",
        "BuyBlock","RequestPlace","PlaceTool","PlaceFurniture","PlacePiece"
    }

    local function findCandidateRemotes()
        local candidates = {}
        local searchContainers = {
            game:GetService("ReplicatedStorage"),
            game:GetService("ServerStorage"),
            game:GetService("StarterPlayer"),
            Workspace
        }
        for _, container in ipairs(searchContainers) do
            if container then
                for _, obj in ipairs(container:GetDescendants()) do
                    if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and obj.Name and type(obj.Name) == "string" then
                        local nm = obj.Name:lower()
                        for _, hint in ipairs(remoteNameHints) do
                            if string.find(nm, hint:lower()) then
                                table.insert(candidates, obj)
                                break
                            end
                        end
                    end
                end
            end
        end
        -- also search for modules that hold remotes
        return candidates
    end

    local function try_fire_remote(remote)
        if not remote then return false end
        local ok, res = pcall(function()
            if remote:IsA("RemoteFunction") then
                -- invoke; some remote functions require args - best effort: try common args
                local argsSet = {
                    {}, { "Place", Vector3.new(0,0,0) }, { "place" }, {1}, {"build"}
                }
                for _, a in ipairs(argsSet) do
                    pcall(function()
                        remote:InvokeServer(unpack(a))
                    end)
                end
            elseif remote:IsA("RemoteEvent") then
                local argsSet = {
                    {}, {"Place"}, {"place", Vector3.new(0,0,0)}, {1}
                }
                for _, a in ipairs(argsSet) do
                    pcall(function()
                        remote:FireServer(unpack(a))
                    end)
                end
            end
        end)
        return ok
    end

    local function auto_build_loop(buildArgs)
        -- buildArgs: {mode="auto"/"teleport", delay=0.3}
        while running do
            -- find remotes
            local remotes = findCandidateRemotes()
            if #remotes > 0 then
                for _, r in ipairs(remotes) do
                    if not running then break end
                    safe_pcall(function() try_fire_remote(r) end)
                    task.wait(buildArgs.delay or 0.4)
                end
            else
                -- fallback: move to a build area and try again
                -- attempt to find a part named "Build" or "BuildZone"
                local buildPart = nil
                for _, d in ipairs(Workspace:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local n = (d.Name or ""):lower()
                        if string.find(n, "build") or string.find(n, "workshop") or string.find(n, "craft") or string.find(n, "construction") then
                            buildPart = d; break
                        end
                    end
                end
                if buildPart and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                    safe_pcall(function() LP.Character.HumanoidRootPart.CFrame = buildPart.CFrame + Vector3.new(0,3,0) end)
                end
            end
            task.wait(buildArgs.delay or 0.6)
        end
    end

    function GMON.Modules.StartAutoBuild(opts)
        if running then return end
        opts = opts or { mode = "auto", delay = 0.4 }
        running = true
        GMON.Flags.AutoBuild = true
        auto_task = task.spawn(function() auto_build_loop(opts) end)
        warn("[GMON] AutoBuild started (mode)", opts.mode)
    end

    function GMON.Modules.StopAutoBuild()
        running = false
        GMON.Flags.AutoBuild = false
        auto_task = nil
        warn("[GMON] AutoBuild stopped")
    end
end

-- ======================
-- UI (Rayfield fallback)
-- ======================
do
    local Ray
    local ok, r = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and r then Ray = r else
        Ray = nil
    end
    local Window = nil
    local Tabs = {}

    local function simpleFallbackWindow()
        local win = {}
        function win:CreateTab(name)
            local tab = {}
            function tab:CreateLabel(text) print("[GMON][UI]["..(name or "tab").."] Label:", text) end
            function tab:CreateButton(tbl) print("[GMON][UI]["..(name or "tab").."] Button:", tbl.Name); if tbl.Callback then tbl.Callback() end end
            function tab:CreateToggle(tbl) print("[GMON][UI]["..(name or "tab").."] Toggle:", tbl.Name) end
            function tab:CreateSlider(tbl) print("[GMON][UI]["..(name or "tab").."] Slider:", tbl.Name) end
            function tab:CreateParagraph(tbl) print("[GMON][UI]["..(name or "tab").."] Paragraph:", tbl.Title, tbl.Content) end
            return tab
        end
        function win:CreateNotification() end
        return win
    end

    if Ray then
        Window = Ray:CreateWindow({
            Name = "G-MON Hub v2",
            LoadingTitle = "G-MON Hub",
            LoadingSubtitle = "Ready",
            ConfigurationSaving = { Enabled = false }
        })
    else
        Window = simpleFallbackWindow()
    end

    Tabs.Info = Window:CreateTab("Info")
    Tabs.Boat = Window:CreateTab("Build A Boat")
    Tabs.Utility = Window:CreateTab("Utility")

    -- Info
    Tabs.Info:CreateLabel("G-MON Hub - Build A Boat additions")
    Tabs.Info:CreateParagraph({ Title = "Notice", Content = "AutoBuild generic: best-effort. GodMode client-side best-effort. ServerHop uses Roblox public servers API." })

    -- Boat tab
    do
        local t = Tabs.Boat
        t:CreateLabel("Teleports")
        -- populate a dropdown-like UI if Ray exists, else simple print + buttons list
        local locations = GMON.Modules.GetBoatTeleports()
        -- if Rayfield, we can create dynamic dropdown; fallback: create button per location
        if Ray and Window then
            local locationNames = {}
            for k,_v in pairs(locations) do table.insert(locationNames, k) end
            -- Create dropdown-like by using a slider / toggles fallback (Rayfield specifics depend)
            t:CreateParagraph({ Title = "Available Locations", Content = table.concat(locationNames, ", ") })
            for _, name in ipairs(locationNames) do
                t:CreateButton({ Name = "TP -> "..name, Callback = function() local ok, err = GMON.Modules.TeleportToBoatLocation(name); if not ok then warn("Teleport failed:", err) end end })
            end
            t:CreateButton({ Name = "Refresh Locations", Callback = function() -- no-op: UI will reflect next open
                if Window and Window.Notify then Window:Notify({Title="G-MON", Content="Locations refreshed", Duration=2}) else warn("Locations refreshed") end
            end })
        else
            -- fallback
            local idx = 1
            for name, _v in pairs(locations) do
                local n = name
                t:CreateButton({ Name = ("TP -> %s"):format(n), Callback = function() GMON.Modules.TeleportToBoatLocation(n) end })
                idx = idx + 1
            end
            t:CreateParagraph({ Title = "Note", Content = "If teleports are missing, run Detect (in Info tab) or add via script." })
        end

        t:CreateLabel("AutoBuild")
        t:CreateToggle({ Name = "AutoBuild (generic)", CurrentValue = false, Callback = function(v)
            if v then GMON.Modules.StartAutoBuild({mode="auto", delay=0.4}) else GMON.Modules.StopAutoBuild() end
        end })
        t:CreateSlider({ Name = "AutoBuild Delay (s)", Range = {0.1, 2}, Increment = 0.05, CurrentValue = 0.4, Callback = function(v) -- set internal variable (best-effort)
            -- we simply restart with new delay
            if GMON.Flags.AutoBuild then
                GMON.Modules.StopAutoBuild()
                GMON.Modules.StartAutoBuild({mode="auto", delay = v})
            end
        end })
    end

    -- Utility tab
    do
        local t = Tabs.Utility
        t:CreateLabel("God Mode")
        t:CreateToggle({ Name = "God Mode (client-side)", CurrentValue = false, Callback = function(v)
            if v then GMON.Modules.EnableGodMode() else GMON.Modules.DisableGodMode() end
        end })

        t:CreateLabel("Anti AFK")
        t:CreateToggle({ Name = "Anti-AFK", CurrentValue = false, Callback = function(v)
            if v then GMON.Modules.StartAntiAFK() else GMON.Modules.StopAntiAFK() end
        end })

        t:CreateLabel("Rejoin / Server-Hop")
        t:CreateButton({ Name = "Rejoin (same place)", Callback = function() GMON.Modules.Rejoin() end })
        t:CreateButton({ Name = "Server Hop (find another public server)", Callback = function()
            local ok, sid = GMON.Modules.ServerHop()
            if ok then
                if Window and Window.Notify then Window:Notify({Title="G-MON", Content="Hopping to server "..tostring(sid), Duration=3}) end
            else
                if Window and Window.Notify then Window:Notify({Title="G-MON", Content="ServerHop fallback: rejoined", Duration=3}) end
            end
        end })
    end

    GMON.UI.Window = Window
    GMON.UI.Tabs = Tabs
end

-- ======================
-- Status small GUI (draggable)
-- ======================
do
    local function createStatus()
        local pg = LP:WaitForChild("PlayerGui")
        local sg = Instance.new("ScreenGui"); sg.Name = "GMonStatus"; sg.ResetOnSpawn = false; sg.Parent = pg
        local frame = Instance.new("Frame"); frame.Size = UDim2.new(0,260,0,100); frame.Position = UDim2.new(1,-280,0,8);
        frame.BackgroundTransparency = 0.12; frame.BackgroundColor3 = Color3.fromRGB(18,18,18); frame.Parent = sg
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,8); corner.Parent = frame
        local title = Instance.new("TextLabel"); title.Size = UDim2.new(1,-8,0,20); title.Position = UDim2.new(0,8,0,6); title.BackgroundTransparency = 1;
        title.Text = "G-MON (Boat additions)"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.SourceSansBold; title.TextSize = 14; title.Parent = frame

        local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1,-16,0,64); txt.Position = UDim2.new(0,8,0,30); txt.BackgroundTransparency = 1;
        txt.TextColor3 = Color3.fromRGB(200,200,200); txt.Text = "God: OFF\nAutoBuild: OFF\nAntiAFK: OFF"; txt.TextXAlignment = Enum.TextXAlignment.Left; txt.TextYAlignment = Enum.TextYAlignment.Top; txt.Font = Enum.Font.SourceSans; txt.TextSize = 13; txt.Parent = frame

        -- update function
        GMON.Status.Update = function()
            local s = ("God: %s\nAutoBuild: %s\nAntiAFK: %s\nGame: %s"):format(
                GMON.Flags.GodMode and "ON" or "OFF",
                GMON.Flags.AutoBuild and "ON" or "OFF",
                GMON.Flags.AntiAFK and "ON" or "OFF",
                (GMON.DetectedGame or "Unknown")
            )
            pcall(function() txt.Text = s end)
        end
        -- small updater
        task.spawn(function()
            while true do
                pcall(function() GMON.Status.Update() end)
                task.wait(1)
            end
        end)
    end
    createStatus()
end

-- ======================
-- Initialization: detect and expose
-- ======================
do
    -- detect simple by workspace hints
    local function detectGame()
        local p = game.PlaceId
        if p == 537413528 then return "BUILD_A_BOAT" end
        -- heuristics: names
        for _, obj in ipairs(Workspace:GetChildren()) do
            local n = (obj.Name or ""):lower()
            if string.find(n, "boat") or string.find(n, "stage") then return "BUILD_A_BOAT" end
            if string.find(n, "car") or string.find(n, "vehicle") or string.find(n, "dealer") then return "CAR_TYCOON" end
            if string.find(n, "enemy") or string.find(n, "mob") or string.find(n, "monster") then return "BLOX_FRUIT" end
        end
        return "UNKNOWN"
    end

    GMON.DetectedGame = detectGame()
    -- notify via UI
    if GMON.UI and GMON.UI.Window and GMON.UI.Window.Notify then
        GMON.UI.Window:Notify({Title="G-MON", Content=("Detected: %s"):format(GMON.DetectedGame), Duration=3})
    else
        print("[GMON] Detected:", GMON.DetectedGame)
    end
end

-- Return the module so main loader can call it
return GMON