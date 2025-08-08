-- main.lua – Complete NatHub-Style ESP & Join Player UI
-- Fluxus / Synapse compatible

-- Ensure game is loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players          = game:GetService("Players")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local lp = Players.LocalPlayer

-- ==== 1. Global Flags (via getgenv) ====
getgenv().EggESPFlags = getgenv().EggESPFlags or {
    ESP_Common      = false,
    ESP_Uncommon    = false,
    ESP_Rare        = false,
    ESP_Legendary   = false,
    ESP_Mythical    = false,
    ESP_Bug         = false,
    ESP_Bee         = false,
    ESP_AntiBee     = false,
}
local Flags = getgenv().EggESPFlags

-- Prediction map
local predictionMap = {
    CommonEgg      = { "Golden Lab", "Dog", "Bunny" },
    UncommonEgg    = { "Black Bunny", "Chicken", "Cat", "Deer" },
    RareEgg        = { "Orange Tabby", "Spotted Deer", "Pig", "Rooster", "Monkey" },
    LegendaryEgg   = { "Cow", "Silver Monkey", "Sea Otter", "Turtle", "Polar Bear" },
    MythicalEgg    = { "Grey Mouse", "Brown Mouse", "Squirrel", "Red Giant Ant", "Red Fox" },
    BugEgg         = { "Snail", "Giant Ant", "Caterpillar", "Praying Mantis", "Dragonfly" },
    BeeEgg         = { "Bee", "Honey Bee", "Bear Bee", "Petal Bee", "Queen Bee" },
    AntiBeeEgg     = { "Wasp", "Tarantula Hawk", "Moth", "Butterfly", "Disco Bee" },
}

-- Helper to create Instance
local function New(cls, props, parent)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- Make frame draggable
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos  = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragInput = inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging then
            local delta = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==== 2. Build GUI ====
-- Parent ScreenGui
local screenGui = New("ScreenGui", {
    Name = "NatHubUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = lp:WaitForChild("PlayerGui"),
})

-- Toggle Button (GMON)
local toggleBtn = New("TextButton", {
    Name = "GMONToggle",
    Text = "GMON",
    Size = UDim2.new(0, 60, 0, 32),
    Position = UDim2.new(0, 12, 0, 12),
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    TextColor3 = Color3.fromRGB(230, 230, 230),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    AutoButtonColor = false,
}, screenGui)
New("UICorner", { CornerRadius = UDim.new(0,6) }, toggleBtn)
makeDraggable(toggleBtn)

-- Main Frame
local frame = New("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 350, 0, 500),
    Position = UDim2.new(0, 12, 0, 52),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    Visible = false,
}, screenGui)
New("UICorner", { CornerRadius = UDim.new(0,8) }, frame)
makeDraggable(frame)

-- RGB Animated Border
local stroke = New("UIStroke", {
    Thickness = 2,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, frame)
task.spawn(function()
    local hue = 0
    while true do
        hue = (hue + 1) % 360
        stroke.Color = Color3.fromHSV(hue/360, 1, 1)
        task.wait(0.03)
    end
end)

-- Title
New("TextLabel", {
    Parent = frame,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "NatHub – ESP & Join UI",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.new(1,1,1),
    TextXAlignment = Enum.TextXAlignment.Center,
}, frame)

-- Close Button
local closeBtn = New("TextButton", {
    Parent = frame,
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -30, 0, 5),
    Text = "✕",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(200,200,200),
    AutoButtonColor = false,
}, frame)
closeBtn.MouseButton1Click:Connect(function() frame.Visible = false end)

-- ==== 3. Join Player Section ====
-- Username Input
local usernameBox = New("TextBox", {
    Parent = frame,
    Name = "UsernameBox",
    Size = UDim2.new(1, -40, 0, 30),
    Position = UDim2.new(0, 20, 0, 45),
    PlaceholderText = "Masukkan Username...",
    BackgroundTransparency = 0.6,
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.Gotham,
    TextSize = 16,
}, frame)
New("UICorner", { CornerRadius = UDim.new(0,4) }, usernameBox)

-- Status Label
local statusLabel = New("TextLabel", {
    Parent = frame,
    Name = "StatusLabel",
    Size = UDim2.new(1, -40, 0, 20),
    Position = UDim2.new(0, 20, 0, 80),
    BackgroundTransparency = 1,
    Text = "Status: -",
    Font = Enum.Font.Gotham,
    TextSize = 14,
    TextColor3 = Color3.new(1,1,1),
    TextXAlignment = Enum.TextXAlignment.Left,
}, frame)

-- Join Button
local joinBtn = New("TextButton", {
    Parent = frame,
    Name = "JoinButton",
    Size = UDim2.new(1, -40, 0, 36),
    Position = UDim2.new(0, 20, 0, 110),
    Text = "Join Friend / Dev",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.new(1,1,1),
    BackgroundColor3 = Color3.fromRGB(30,130,255),
    AutoButtonColor = false,
}, frame)
New("UICorner", { CornerRadius = UDim.new(0,6) }, joinBtn)

-- Function cek online
local function checkOnline(username)
    if username == "" then
        statusLabel.Text = "Status: Masukkan username!"
        statusLabel.TextColor3 = Color3.fromRGB(255,50,50)
        return nil
    end
    local ok, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    if not ok then
        statusLabel.Text = "Status: Username tidak ditemukan"
        statusLabel.TextColor3 = Color3.fromRGB(255,50,50)
        return nil
    end
    -- Cek online via API
    local suc, resp = pcall(function()
        return HttpService:GetAsync("https://api.roblox.com/users/"..userId.."/onlinestatus/")
    end)
    if not suc then
        statusLabel.Text = "Status: Gagal koneksi"
        statusLabel.TextColor3 = Color3.fromRGB(255,50,50)
        return nil
    end
    local data = HttpService:JSONDecode(resp)
    if data.IsOnline then
        statusLabel.Text = "Status: ONLINE"
        statusLabel.TextColor3 = Color3.fromRGB(0,255,0)
        return userId
    else
        statusLabel.Text = "Status: OFFLINE"
        statusLabel.TextColor3 = Color3.fromRGB(255,50,50)
        return nil
    end
end

usernameBox.FocusLost:Connect(function()
    checkOnline(usernameBox.Text)
end)

joinBtn.MouseButton1Click:Connect(function()
    local uid = checkOnline(usernameBox.Text)
    if uid then
        -- Ambil jobId (bila developer server, owner bisa taruh sendiri)
        -- Contoh: gunakan jobId pemain target
        local jobId = workspace:FindFirstChild("PlaceJobId_"..uid) and workspace["PlaceJobId_"..uid].Value
        if typeof(jobId) == "string" then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, lp)
        else
            -- fallback: teleport ke game (jika public)
            TeleportService:Teleport(game.PlaceId, lp)
        end
    end
end)

-- ==== 4. ESP Egg Prediction Section ====
-- Scrolling Frame
local scroll = New("ScrollingFrame", {
    Parent = frame,
    Name = "ESPScroll",
    Size = UDim2.new(1, -40, 0, 230),
    Position = UDim2.new(0, 20, 0, 160),
    CanvasSize = UDim2.new(0,0,0,0),
    ScrollBarThickness = 6,
    BackgroundTransparency = 1,
}, frame)
local layout = New("UIListLayout", {
    Parent = scroll,
    Padding = UDim.new(0,8),
}, scroll)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 10)
end)

-- Create switch for each egg category
for eggName,_ in pairs(predictionMap) do
    local labelText = eggName:gsub("Egg","")
    local holder = New("Frame", {
        Parent = scroll,
        Size = UDim2.new(1,0,0, thirty),
        BackgroundTransparency = 1,
    }, scroll)
    local lbl = New("TextLabel", {
        Parent = holder,
        Size = UDim2.new(0.7,0,1,0),
        Position = UDim2.new(0,0,0,0),
        BackgroundTransparency = 1,
        Text = labelText,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)
    -- Switch
    local sw = New("Frame", {
        Parent = holder,
        Size = UDim2.new(0,40,0,20),
        Position = UDim2.new(1,-45,0.5,-10),
        BackgroundColor3 = Color3.fromRGB(60,60,60),
        Name = "Switch"..eggName,
    }, holder)
    New("UICorner", { CornerRadius = UDim.new(0,10) }, sw)
    local knob = New("Frame", {
        Parent = sw,
        Size = UDim2.new(0,18,0,18),
        Position = UDim2.new(0,2,0,2),
        BackgroundColor3 = Color3.fromRGB(200,200,200),
    }, sw)
    New("UICorner", { CornerRadius = UDim.new(0,9) }, knob)
    -- click
    sw.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            Flags["ESP_"..labelText] = not Flags["ESP_"..labelText]
            -- animate knob
            if Flags["ESP_"..labelText] then
                knob:TweenPosition(UDim2.new(1,-20,0,2),"InOut","Quad",0.15,true)
                sw.BackgroundColor3 = Color3.fromRGB(0,170,0)
            else
                knob:TweenPosition(UDim2.new(0,2,0,2),"InOut","Quad",0.15,true)
                sw.BackgroundColor3 = Color3.fromRGB(60,60,60)
            end
        end
    end)
end

-- ESP Rendering Loop
task.spawn(function()
    while task.wait(1.5) do
        -- bersihkan ESP lama
        for _, gui in ipairs(Workspace:GetDescendants()) do
            if gui.Name == "EggESP" and gui:IsA("BillboardGui") then
                gui:Destroy()
            end
        end
        -- buat ESP baru
        for eggName,pets in pairs(predictionMap) do
            local flagKey = "ESP_"..eggName:gsub("Egg","")
            if Flags[flagKey] then
                for _, mdl in ipairs(Workspace:GetDescendants()) do
                    if mdl:IsA("Model") and mdl.Name == eggName then
                        local part = mdl:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local bb = New("BillboardGui", {
                                Name = "EggESP",
                                Parent = mdl,
                                Adornee = part,
                                Size = UDim2.new(0,140,0,30),
                                StudsOffset = Vector3.new(0,3,0),
                                AlwaysOnTop = true,
                            }, mdl)
                            New("UICorner", { CornerRadius = UDim.new(0,4) }, bb)
                            New("TextLabel", {
                                Parent = bb,
                                Size = UDim2.new(1,0,1,0),
                                BackgroundTransparency = 0.6,
                                BackgroundColor3 = Color3.fromRGB(0,0,0),
                                TextColor3 = Color3.fromRGB(255,255,0),
                                Font = Enum.Font.Gotham,
                                TextSize = 14,
                                Text = "→ "..table.concat(pets, ", "),
                                TextWrapped = true,
                            }, bb)
                        end
                    end
                end
            end
        end
    end
end)

-- Hotkey M untuk toggle GUI
UserInputService.InputBegan:Connect(function(input,gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- Toggle juga via tombol GMON
toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)
