-- GMON - Unified: Blox Fruit, CDT (Buy Limited), Build A Boat (Haruka)
-- Paste into executor (LocalScript). Uses Rayfield if available; fallback safe UI.

-- ===== BOOTSTRAP =====
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = workspace
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
    if sec > 5 then sec = 5 end
    task.wait(sec)
end

-- ===== STATE =====
local STATE = {
    StartTime = os.time(),
    Rayfield = nil,
    Window = nil,
    Tabs = {},
    Status = nil,
    Modules = {},
    Flags = {},
    LastAction = "Idle",
    Settings = {}
}

-- ===== UTILS =====
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

-- Heuristic detect money: tries leaderstats or PlayerGui labels that contain currency
function Utils.GetPlayerMoney()
    local pl = Players.LocalPlayer
    if not pl then return nil end
    -- 1) leaderstats common keys
    local ls = pl:FindFirstChild("leaderstats") or pl:FindFirstChild("Leaderstats")
    if ls and ls:IsA("Folder") then
        for _,v in ipairs(ls:GetChildren()) do
            local name = string.lower(v.Name or "")
            if (name:find("cash") or name:find("money") or name:find("coins") or name:find("gold") or name:find("balance") or name:find("bank")) and typeof(v.Value) == "number" then
                return tonumber(v.Value)
            elseif typeof(v.Value) == "string" then
                local num = tonumber((v.Value:gsub("[^%d]","")))
                if num then return num end
            end
        end
    end
    -- 2) PlayerGui search: find label with $ and digits
    local pg = pl:FindFirstChild("PlayerGui")
    if pg then
        for _,obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local txt = tostring(obj.Text or "")
                if txt:find("%$") or txt:find("%d%d%d") then
                    local num = tonumber((txt:gsub("[^%d]","")))
                    if num and num > 0 then return num end
                end
            end
        end
    end
    return nil -- unknown
end

-- Try to click a Gui button robustly
function Utils.TriggerGuiButton(btn)
    if not btn then return false end
    local success = false
    SAFE_CALL(function()
        -- prefer Activate if available
        if pcall(function() return btn.Activate end) then
            pcall(function() btn:Activate() end); success = true; return
        end
    end)
    if success then return true end
    -- firesignal fallback
    if typeof(firesignal) == "function" then
        SAFE_CALL(function() firesignal(btn.MouseButton1Click) end); return true
    end
    -- fire MouseButton1Click event
    SAFE_CALL(function() btn.MouseButton1Click:Fire() end)
    return true
end

-- Attempt to find car-buy button by keywords in PlayerGui
function Utils.FindCarButtonByKeyword(keyword)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    keyword = (tostring(keyword) or ""):lower()
    for _,v in ipairs(pg:GetDescendants()) do
        if v:IsA("TextButton") or v:IsA("ImageButton") then
            local n = tostring(v.Name or ""):lower()
            local t = tostring(v.Text or ""):lower()
            if n:find(keyword) or t:find(keyword) then
                return v
            end
            -- sometimes parent/frame contains name
            local pn = tostring(v.Parent and v.Parent.Name or ""):lower()
            if pn:find(keyword) then return v end
        end
    end
    return nil
end

-- Default notify (Rayfield or warn)
function Utils.Notify(title, content, duration)
    duration = duration or 3
    if STATE.Rayfield and STATE.Rayfield.Notify then
        pcall(function() STATE.Rayfield:Notify({Title = title, Content = content, Duration = duration}) end)
    else
        warn("NOTIFY:", title, content)
    end
end

STATE.Utils = Utils

-- ===== RAYFIELD LOAD (safe fallback) =====
do
    local ok, Ray = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Ray then
        STATE.Rayfield = Ray
    else
        warn("[G-MON] Rayfield load failed; using minimal fallback UI.")
        -- minimal fallback: table with CreateWindow stub that returns tab objects with methods that do nothing but store state
        local Fallback = {}
        function Fallback:CreateWindow(opts)
            local win = {tabs = {}}
            function win:CreateTab(name)
                local tab = {
                    CreateLabel = function(_) end,
                    CreateParagraph = function(_) end,
                    CreateButton = function(_) end,
                    CreateToggle = function(_) end,
                    CreateSlider = function(_) end,
                    CreateDropdown = function(_) end,
                    CreateInput = function(_) end
                }
                win.tabs[name] = tab
                return tab
            end
            function win:CreateNotification(...) end
            return win
        end
        function Fallback:Notify(...) end
        STATE.Rayfield = Fallback
    end
end

-- ===== STATUS GUI (simple, draggable) =====
do
    local Status = {}
    function Status.Create()
        SAFE_CALL(function()
            local pg = LP:WaitForChild("PlayerGui")
            if pg:FindFirstChild("GMonStatusGui") then return end
            local sg = Instance.new("ScreenGui")
            sg.Name = "GMonStatusGui"
            sg.ResetOnSpawn = false
            sg.Parent = pg

            local frame = Instance.new("Frame")
            frame.Name = "StatusFrame"
            frame.Size = UDim2.new(0, 320, 0, 160)
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

            local function makeLine(y)
                local holder = Instance.new("Frame"); holder.Parent = frame
                holder.Size = UDim2.new(1, -16, 0, 20); holder.Position = UDim2.new(0,8,0,y)
                holder.BackgroundTransparency = 1
                local dot = Instance.new("Frame"); dot.Parent = holder
                dot.Size = UDim2.new(0, 12, 0, 12); dot.Position = UDim2.new(0, 0, 0, 4)
                dot.BackgroundColor3 = Color3.fromRGB(200,0,0)
                local lbl = Instance.new("TextLabel"); lbl.Parent = holder
                lbl.Size = UDim2.new(1, -18, 1, 0); lbl.Position = UDim2.new(0, 18, 0, 0)
                lbl.BackgroundTransparency = 1; lbl.Text = ""; lbl.TextColor3 = Color3.fromRGB(230,230,230)
                lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
                return {dot = dot, lbl = lbl}
            end

            local lines = {}
            lines.runtime = makeLine(40)
            lines.blox = makeLine(64)
            lines.cdt = makeLine(88)
            lines.bab = makeLine(112)
            lines.last = makeLine(136)

            lines.runtime.lbl.Text = "Runtime: 00h:00m:00s"
            lines.blox.lbl.Text = "Blox: OFF"
            lines.cdt.lbl.Text = "CDT: OFF"
            lines.bab.lbl.Text = "BuildA: OFF"
            lines.last.lbl.Text = "Last: Idle"

            STATE.Status = { frame = frame, lines = lines }

            -- draggable
            local dragging = false; local dragInput = nil; local startMousePos = Vector2.new(0,0); local startFramePos = Vector2.new(0,0)
            local function getMousePos() return UIS:GetMouseLocation() end
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; dragInput = input; startMousePos = getMousePos(); startFramePos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                    input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false; dragInput = nil end end)
                end
            end)
            frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
            UIS.InputChanged:Connect(function(input)
                if not dragging then return end
                if dragInput and input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local mousePos = getMousePos(); local delta = mousePos - startMousePos; local newAbs = startFramePos + delta
                local cam = workspace.CurrentCamera; local vp = (cam and cam.ViewportSize) or Vector2.new(800,600); local fw = frame.AbsoluteSize.X; local fh = frame.AbsoluteSize.Y
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

-- create status gui
SAFE_CALL(function() if STATE.Status and STATE.Status.Create then STATE.Status.Create() end end)

-- ===== MODULE: BLOX FRUIT (AUTO FARM simple) =====
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
                local char = Utils.SafeChar(); if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local folder = findEnemyFolder(); if not folder then return end

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
                    STATE.LastAction = "Blox LongHit"
                else
                    pcall(function() hrp.CFrame = nearest.HumanoidRootPart.CFrame * CFrame.new(0,0,3) end)
                    if M.config.fast_attack then
                        for i=1,3 do pcall(function() if nearest and nearest:FindFirstChild("Humanoid") then nearest.Humanoid:TakeDamage(30) end end) end
                        STATE.LastAction = "Blox FastMelee"
                    else
                        pcall(function() if nearest and nearest:FindFirstChild("Humanoid") then nearest.Humanoid:TakeDamage(18) end end)
                        STATE.LastAction = "Blox Melee"
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
            { type="toggle", name="Auto Farm (Blox)", current=M.running, onChange=function(v) if v then M.start() else M.stop() end end },
            { type="toggle", name="Fast Attack", current=M.config.fast_attack, onChange=function(v) M.config.fast_attack = v end },
            { type="toggle", name="Long Range Hit", current=M.config.long_range, onChange=function(v) M.config.long_range = v end },
            { type="slider", name="Range (studs)", min=1, max=50, current=M.config.range, onChange=function(v) M.config.range = v end },
            { type="slider", name="Attack Delay (ms)", min=50, max=1000, current=math.floor(M.config.attack_delay*1000), onChange=function(v) M.config.attack_delay = v/1000 end }
        }
    end

    STATE.Modules.Blox = M
end

-- ===== MODULE: CAR DEALERSHIP TYCOON (CDT) including Buy Limited =====
do
    local CDT = {}
    CDT.Auto = false
    CDT.open = false
    CDT.Customer = false
    CDT.deliver = false
    CDT.buyer = false
    CDT.speed = 300
    CDT._tasks = {}
    CDT.SettingsFile = "gmon_cdt_settings.txt"

    -- Car price & mapping
    local CarList = {
        -- DisplayName = { key, priceNumber, priceDisplay, modelNames = {possible model names to check}}
        ["Hyperluxe Balle"] = { key = "hyperluxe", priceNum = 37500000, price = "$37,500,000", models = {"Bugatti5","Balle","HyperluxeBalle"} },
        ["Hyperluxe 300+/SS+"] = { key = "ss", priceNum = 35000000, price = "$35,000,000", models = {"SS+","HyperluxeSS","Hyperluxe300"} },
        ["Hyperluxe Vision GT"] = { key = "vision", priceNum = 30000000, price = "$30,000,000", models = {"VisionGT","Vision","HyperluxeVision"} }
    }

    -- Persistence: save/load
    local function saveSettings(tbl)
        pcall(function()
            if writefile and type(tbl) == "table" then
                local s = game:GetService("HttpService"):JSONEncode(tbl)
                writefile(CDT.SettingsFile, s)
            end
        end)
    end
    local function loadSettings()
        pcall(function()
            if isfile and isfile(CDT.SettingsFile) then
                local s = readfile(CDT.SettingsFile)
                local ok, t = pcall(function() return game:GetService("HttpService"):JSONDecode(s) end)
                if ok and type(t) == "table" then
                    CDT.UIState = t
                end
            end
        end)
    end
    loadSettings()

    -- Helper: find player's tycoon plot (best-effort)
    local function findPlayerPlot()
        if not Workspace:FindFirstChild("Tycoons") then return nil end
        for _,v in ipairs(Workspace.Tycoons:GetDescendants()) do
            if v.Name == "Owner" and v:IsA("StringValue") and (string.find(v.Parent.Name,"Plot") or string.find(v.Parent.Name,"Slot")) and v.Value == LP.Name then
                return v.Parent
            end
        end
        return nil
    end

    -- Basic auto functions kept minimal (not altering user's original heavy logic)
    function CDT.startAutoFarm()
        if CDT.Auto then return end
        CDT.Auto = true
        CDT._tasks.auto = task.spawn(function()
            while CDT.Auto do
                task.wait(0.5)
                -- attempt to keep moving if in seat (simple)
                local char = Utils.SafeChar()
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                    if char.Humanoid.SeatPart and char.Humanoid.SeatPart.Parent then
                        local car = char.Humanoid.SeatPart.Parent
                        pcall(function()
                            if car.PrimaryPart then
                                car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.CFrame.LookVector * (CDT.speed or 300)
                            end
                        end)
                    end
                end
            end
        end)
    end
    function CDT.stopAutoFarm()
        CDT.Auto = false
        if CDT._tasks.auto then pcall(function() task.cancel(CDT._tasks.auto) end); CDT._tasks.auto = nil end
    end

    -- BUY LIMITED CAR: UI + action
    function CDT.CreateBuyLimitedUI(Tab)
        local t = Tab
        local label = t:CreateLabel("Buy Car Limited")
        local currentSelection = nil
        local priceLabel = t:CreateLabel("Price: -")

        -- Dropdown options list
        local options = {}
        for name,_ in pairs(CarList) do table.insert(options, name) end
        table.sort(options)

        -- Use CreateDropdown if present; otherwise fallback to text buttons
        if t.CreateDropdown then
            t:CreateDropdown({
                Name = "Select Limited Car",
                Options = options,
                CurrentOption = nil,
                Callback = function(value)
                    currentSelection = value
                    local info = CarList[value]
                    priceLabel:Set("Price: "..(info and info.price or "-"))
                end
            })
        else
            -- fallback: create buttons
            for _,name in ipairs(options) do
                t:CreateButton({ Name = "Select: "..name, Callback = function()
                    currentSelection = name
                    local info = CarList[name]
                    priceLabel:Set("Price: "..(info and info.price or "-"))
                end})
            end
        end

        -- Quick select buttons too (small)
        for displayName,info in pairs(CarList) do
            t:CreateButton({ Name = "Quick Buy: "..displayName, Callback = function()
                currentSelection = displayName
                priceLabel:Set("Price: "..info.price)
            end})
        end

        -- Buy button
        t:CreateButton({ Name = "Buy Selected Car (Attempt)", Callback = function()
            if not currentSelection then
                Utils.Notify("GMON CDT", "Pilih mobil dulu.", 3); return
            end
            local info = CarList[currentSelection]
            if not info then Utils.Notify("GMON CDT", "Data mobil tidak ditemukan.", 3); return end

            -- check money heuristic
            local beforeMoney = Utils.GetPlayerMoney()
            if beforeMoney then
                if beforeMoney < info.priceNum then
                    Utils.Notify("GMON CDT", "Not enough money ("..tostring(beforeMoney)..") for "..info.price, 4)
                    return
                end
            end

            -- Try to locate buy button by keyword (key or model names)
            local foundBtn = nil
            -- first try keywords (like "hyperluxe" or "ss" or "vision")
            foundBtn = Utils.FindCarButtonByKeyword(info.key) or foundBtn
            -- then try display name fragments
            foundBtn = foundBtn or Utils.FindCarButtonByKeyword(displayName)
            -- last-resort: search for price string in buttons
            if not foundBtn then
                local pg = LP:FindFirstChild("PlayerGui")
                if pg then
                    for _,v in ipairs(pg:GetDescendants()) do
                        if v:IsA("TextButton") or v:IsA("ImageButton") then
                            local text = tostring(v.Text or ""):lower()
                            if (info.price and text:find(tostring(info.price):lower():gsub(",",""):gsub("%$",""))) or (text:find(tostring(info.price):lower())) then
                                foundBtn = v; break
                            end
                        end
                    end
                end
            end

            if not foundBtn then
                Utils.Notify("GMON CDT", "Buy button not found in PlayerGui. Attempting fallback remote...", 4)
                -- fallback attempt: look for expected remote patterns (best-effort, not guaranteed)
                -- Some CDT servers might expect a Remote: FireServer("BuyCar", modelName) - but we can't assume API.
                -- we simply return here.
                return
            end

            -- click it
            local okClick = pcall(function() Utils.TriggerGuiButton(foundBtn) end)
            if not okClick then Utils.Notify("GMON CDT", "Failed to click buy button (executor limitation).", 4); return end

            -- wait and check money delta
            SAFE_WAIT(1.2)
            local afterMoney = Utils.GetPlayerMoney()
            if beforeMoney and afterMoney then
                if afterMoney < beforeMoney then
                    Utils.Notify("GMON CDT", "Buy success: "..(currentSelection).." ("..(info.price)..")", 4)
                else
                    Utils.Notify("GMON CDT", "Buy attempt made but no money change detected. Maybe pending or server-side failed.", 4)
                end
            else
                Utils.Notify("GMON CDT", "Buy attempted. Could not verify money (unknown money).", 4)
            end
        end})

        -- Show static price info paragraph
        local infoText = "Price list:\n"
        for name,info in pairs(CarList) do
            infoText = infoText .. name .. " : " .. info.price .. "\n"
        end
        t:CreateParagraph({ Title = "Price List", Content = infoText })
    end

    -- Expose options for UI
    function CDT.ExposeUI(Tab)
        local t = Tab
        t:CreateLabel("Car Dealership Tycoon (CDT)")
        -- load controls from earlier (auto farm etc.)
        local conf = {
            { type="toggle", name="Auto Drive Farm", current=CDT.Auto, onChange=function(v) if v then CDT.startAutoFarm() else CDT.stopAutoFarm() end end },
            { type="slider", name="AutoDrive Speed", min=50, max=1000, current=CDT.speed, onChange=function(v) CDT.speed = v end }
        }
        for _,opt in ipairs(conf) do
            if opt.type == "toggle" then t:CreateToggle({ Name = opt.name, CurrentValue = opt.current, Callback = opt.onChange }) end
            if opt.type == "slider" then t:CreateSlider({ Name = opt.name, Range = {opt.min, opt.max}, Increment = 10, CurrentValue = opt.current, Callback = opt.onChange }) end
        end

        -- Buy limited UI
        CDT.CreateBuyLimitedUI(t)
    end

    STATE.Modules.CarDeal = CDT
end

-- ===== MODULE: BUILD A BOAT (Haruka style autofarm kept simple) =====
do
    local M = {}
    M.autoRunning = false
    M._task = nil

    local function haruka_auto_loop(character)
        while M.autoRunning do
            if not character or not character.Parent then
                wait(1)
                character = game.Players.LocalPlayer.Character
                if not character then continue end
            end

            wait(1.24)
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then wait(1) continue end

            pcall(function() hrp.CFrame = CFrame.new(-135.900,72,623.750) end)
            -- simple forward motion simulation for AFK farming; precise coordinates from your Haruka script can be used here
            for i=1,175 do
                if not M.autoRunning then break end
                pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0,0,40) end)
                task.wait(0.12)
            end
            task.wait(1)
        end
    end

    function M.startAutoFarm()
        if M.autoRunning then return end
        M.autoRunning = true
        STATE.Flags.HarukaAuto = true
        if game.Players.LocalPlayer.Character then
            M._task = task.spawn(function() haruka_auto_loop(game.Players.LocalPlayer.Character) end)
        end
        game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
            wait(2)
            if M.autoRunning then task.spawn(function() haruka_auto_loop(char) end) end
        end)
    end

    function M.stopAutoFarm()
        M.autoRunning = false
        STATE.Flags.HarukaAuto = false
        M._task = nil
    end

    function M.ExposeConfig()
        return {
            { type="toggle", name="Haruka AutoFarm", current=false, onChange=function(v) if v then M.startAutoFarm() else M.stopAutoFarm() end end }
        }
    end

    STATE.Modules.Haruka = M
end

-- ===== UI BUILDING =====
local function buildUI()
    SAFE_CALL(function()
        local Ray = STATE.Rayfield
        STATE.Window = (Ray and Ray.CreateWindow) and Ray:CreateWindow({
            Name = "G-MON Hub",
            LoadingTitle = "G-MON Hub",
            LoadingSubtitle = "Universal",
            ConfigurationSaving = { Enabled = false }
        }) or nil

        local Tabs = {}
        if STATE.Window then
            Tabs.Info = STATE.Window:CreateTab("Info")
            Tabs.Blox = STATE.Window:CreateTab("Blox Fruit")
            Tabs.CDT = STATE.Window:CreateTab("Car Dealership")
            Tabs.Boat = STATE.Window:CreateTab("Build A Boat")
            Tabs.Debug = STATE.Window:CreateTab("Debug")
        else
            local function makeTab() return { CreateLabel = function() end, CreateParagraph = function() end, CreateButton = function() end, CreateToggle = function() end, CreateSlider = function() end, CreateDropdown = function() end } end
            Tabs.Info = makeTab(); Tabs.Blox = makeTab(); Tabs.CDT = makeTab(); Tabs.Boat = makeTab(); Tabs.Debug = makeTab()
        end
        STATE.Tabs = Tabs

        -- Info
        SAFE_CALL(function()
            local t = Tabs.Info
            t:CreateLabel("G-MON Hub - merged features")
            t:CreateParagraph({ Title = "Note", Content = "Use tabs to control modules. Buy limited cars appear under Car Dealership tab." })
            t:CreateButton({ Name = "Detect Game (refresh status)", Callback = function()
                local det = "ALL"
                -- quick best-effort detection (kept simple)
                local pid = game.PlaceId
                if pid == 2753915549 then det = "BLOX_FRUIT" elseif pid == 1554960397 then det = "CAR_TYCOON" elseif pid == 537413528 then det = "BUILD_A_BOAT" else det = "ALL" end
                STATE.Status.SetIndicator("blox", det=="BLOX_FRUIT", (det=="BLOX_FRUIT") and "Blox: Available" or "Blox: N/A")
                STATE.Status.SetIndicator("cdt", det=="CAR_TYCOON", (det=="CAR_TYCOON") and "CDT: Available" or "CDT: N/A")
                STATE.Status.SetIndicator("bab", det=="BUILD_A_BOAT", (det=="BUILD_A_BOAT") and "BuildA: Available" or "BuildA: N/A")
                Utils.Notify("G-MON", "Detected: "..det, 3)
            end})
            t:CreateParagraph({ Title = "Money Detection", Content = "This script attempts to read your money via leaderstats or PlayerGui. If money cannot be detected, buy attempt will still occur but success may not be verifiable." })
        end)

        -- BLOX UI
        SAFE_CALL(function()
            local t = Tabs.Blox
            t:CreateLabel("Blox Fruit Controls")
            local conf = STATE.Modules.Blox.ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then t:CreateToggle({ Name = opt.name, CurrentValue = opt.current, Callback = opt.onChange }) end
                if opt.type == "slider" then t:CreateSlider({ Name = opt.name, Range = {opt.min or opt.Range[1], opt.max or opt.Range[2]}, Increment = opt.Increment or 1, CurrentValue = opt.current, Callback = opt.onChange }) end
            end
        end)

        -- CDT UI
        SAFE_CALL(function()
            local t = Tabs.CDT
            STATE.Modules.CarDeal.ExposeUI(t)
        end)

        -- Build A Boat UI
        SAFE_CALL(function()
            local t = Tabs.Boat
            t:CreateLabel("Build A Boat (Haruka) Features")
            local conf = STATE.Modules.Haruka.ExposeConfig()
            for _,opt in ipairs(conf) do
                if opt.type == "toggle" then t:CreateToggle({ Name = opt.name, CurrentValue = opt.current, Callback = opt.onChange }) end
            end
            t:CreateParagraph({ Title = "Note", Content = "Haruka auto farm kept simple. Use only in compatible places." })
        end)

        -- Debug
        SAFE_CALL(function()
            local t = Tabs.Debug
            t:CreateLabel("Debug / Utilities")
            t:CreateButton({ Name = "Stop All Modules", Callback = function()
                pcall(function() STATE.Modules.Blox.stop() end)
                pcall(function() STATE.Modules.CarDeal.stopAutoFarm() end)
                pcall(function() STATE.Modules.Haruka.stopAutoFarm() end)
                STATE.Status.SetIndicator("blox", false, "Blox: OFF")
                STATE.Status.SetIndicator("cdt", false, "CDT: OFF")
                STATE.Status.SetIndicator("bab", false, "BuildA: OFF")
                Utils.Notify("G-MON", "Stopped all modules", 3)
            end})
        end)
    end)
end

-- ===== STATUS UPDATER =====
task.spawn(function()
    while true do
        SAFE_WAIT(1)
        SAFE_CALL(function()
            if STATE.Status and STATE.Status.UpdateRuntime then STATE.Status.UpdateRuntime() end
            if STATE.Status and STATE.Status.SetIndicator then STATE.Status.SetIndicator("last", false, "Last: "..(STATE.LastAction or "Idle")) end
        end)
    end
end)

-- ===== ANTI AFK =====
SAFE_CALL(function() Utils.AntiAFK() end)

-- ===== START UI =====
SAFE_CALL(function()
    buildUI()
    if STATE.Rayfield and STATE.Rayfield.Notify then STATE.Rayfield:Notify({Title="G-MON", Content="Loaded modules: Blox, CDT, Build A Boat (Haruka)", Duration=4}) end
end)

print("[G-MON] Unified script loaded.")