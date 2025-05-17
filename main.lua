-- main.lua - GMON Hub UI Final
repeat task.wait() until game:IsLoaded()

-- Services
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")

-- Config Global
_G.Flags = _G.Flags or {}
_G.Config = _G.Config or {FarmInterval = 0.5}

-- UI Setup
local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- Main GUI
local gui = New("ScreenGui", {Name = "GMONHub_UI", ResetOnSpawn = false}, Players.LocalPlayer:WaitForChild("PlayerGui"))

-- Background Anime
New("ImageLabel", {
    Image = "rbxassetid://16790218639",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 0
}, gui)

-- Main Frame + RGB Stroke
local frame = New("Frame", {
    Size = UDim2.new(0, 580, 0, 420),
    -- Sebelumnya:
-- Position = UDim2.new(0.5, -290, 0.5, -210),

-- Ganti jadi:
Position = UDim2.new(0.5, -290, 0.5, -160),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.2,
    Draggable = true,
    Active = true,
    Visible = true,
    Name = "MainFrame"
}, gui)

-- Logo di atas tengah
local logo = New("ImageLabel", {
    Image = "rbxassetid://16790218639", -- ganti jika punya logo khusus G-MON
    Size = UDim2.new(0, 100, 0, 100),
    Position = UDim2.new(0.5, -50, 0, -60),
    BackgroundTransparency = 1,
    Parent = gui,
    ZIndex = 5
})

New("UICorner", {CornerRadius = UDim.new(0, 12)}, frame)

local stroke = New("UIStroke", {Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, frame)
task.spawn(function()
    local hue = 0
    while true do
        hue = (hue + 0.01) % 1
        stroke.Color = Color3.fromHSV(hue, 1, 1)
        task.wait(0.03)
    end
end)

-- Toggle UI Button (Left Side)
local toggleBtn = New("TextButton", {
    Text = "GMON",
    Size = UDim2.new(0, 60, 0, 30),
    Position = UDim2.new(0, 20, 0.5, -15),
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    ZIndex = 100,
    Active = true,
    Draggable = true,
    Parent = gui
})
New("UICorner", {}, toggleBtn)

toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Tabs & Pages
local tabNames = {
    "Info", "Main", "Item", "Sea", "Prehistoric",
    "Kitsune", "Leviathan", "DevilFruit", "ESP", "Misc", "Setting"
}
local tabs = {}
local pages = {}

-- Tab buttons with horizontal scrolling
local tabScroll = New("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    ScrollBarThickness = 4,
    ScrollingDirection = Enum.ScrollingDirection.X,
    CanvasSize = UDim2.new(0, #tabNames * 105, 0, 30),
    Parent = frame
})
New("UIListLayout", {
    Parent = tabScroll,
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5)
})

for i, name in ipairs(tabNames) do
    local btn = New("TextButton", {
        Text = name,
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(0, (i - 1) * 100, 0, 0),
        BackgroundTransparency = 0.5,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        TextColor3 = Color3.new(1,1,1),
        Parent = tabScroll -- FIXED: from tabBar to tabScroll
    })
    New("UICorner", {}, btn)

    local page = New("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -50),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 4,
        Parent = frame
    })
    New("UIListLayout", {
        Parent = page,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })

    table.insert(tabs, btn)
    table.insert(pages, page)

    btn.MouseButton1Click:Connect(function()
        for _, p in ipairs(pages) do p.Visible = false end
        page.Visible = true
    end)

    if i == 1 then
        page.Visible = true
    end
end

-- Add toggle helper
local function AddToggle(page, text, flag)
    local toggle = New("TextButton", {
        Text = text,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        TextColor3 = Color3.new(1,1,1),
        Parent = page
    })
    New("UICorner", {}, toggle)

    toggle.MouseButton1Click:Connect(function()
        _G.Flags[flag] = not _G.Flags[flag]
        toggle.BackgroundColor3 = _G.Flags[flag] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
    end)
end

-- Add text label
local function AddText(page, text)
    New("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = page
    })
end

-- Add text box
local function AddInput(page, placeholder, onInput)
    local box = New("TextBox", {
        PlaceholderText = placeholder,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        TextColor3 = Color3.new(1,1,1),
        Parent = page
    })
    New("UICorner", {}, box)
    box.FocusLost:Connect(function(enter)
        if enter and box.Text ~= "" then
            onInput(box.Text)
        end
    end)
end

-- Populate Tabs
-- Info
local pg = pages[1]
AddToggle(pg, "Track Elite Spawn", "TrackEliteSpawn")
AddToggle(pg, "Track Full Moon", "TrackFullMoon")
AddToggle(pg, "Track God Chalice", "TrackGodChalice")

-- Main
pg = pages[2]
AddToggle(pg, "Auto Farm", "AutoFarm")
AddToggle(pg, "Farm Boss Selected", "FarmBossSelected")
AddToggle(pg, "Farm All Boss", "FarmAllBoss")
AddToggle(pg, "Mastery Fruit", "MasteryFruit")

-- Item
pg = pages[3]
AddToggle(pg, "Auto CDK", "AutoCDK")
AddToggle(pg, "Auto Yama", "AutoYama")
AddToggle(pg, "Auto Tushita", "AutoTushita")
AddToggle(pg, "Auto Soul Guitar", "AutoSoulGuitar")

-- Sea
pg = pages[4]
AddToggle(pg, "Kill Sea Beast", "KillSeaBeast")
AddToggle(pg, "Auto Sail", "AutoSail")

-- Prehistoric
pg = pages[5]
AddToggle(pg, "Kill Golem", "KillGolem")
AddToggle(pg, "Defend Volcano", "DefendVolcano")
AddToggle(pg, "Collect Dragon Egg", "CollectDragonEgg")
AddToggle(pg, "Collect Bones", "CollectBones")

-- Kitsune
pg = pages[6]
AddToggle(pg, "Collect Azure Ember", "CollectAzure")
AddToggle(pg, "Trade Azure Ember", "TradeAzure")

-- Leviathan
pg = pages[7]
AddToggle(pg, "Attack Leviathan", "AttackLeviathan")

-- DevilFruit
pg = pages[8]
AddToggle(pg, "Gacha Fruit", "GachaFruit")
AddInput(pg, "Fruit Target", function(text)
    _G.Flags.FruitTarget = text
end)

-- ESP
pg = pages[9]
AddToggle(pg, "ESP Fruit", "ESPFruit")
AddToggle(pg, "ESP Player", "ESPPlayer")
AddToggle(pg, "ESP Chest", "ESPChest")
AddToggle(pg, "ESP Flower", "ESPFlower")

-- Misc
pg = pages[10]
AddToggle(pg, "Server Hop", "ServerHop")
AddToggle(pg, "Redeem All Codes", "RedeemCodes")
AddToggle(pg, "FPS Booster", "FPSBooster")
AddToggle(pg, "Auto Awaken Fruit", "AutoAwaken")

-- Settings
pg = pages[11]
AddToggle(pg, "Fast Attack", "FastAttack")
AddText(pg, "Toggle GUI: Press M or click left button")

-- M Key toggle
UserInput.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- Memuat semua fitur dari source.lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

print("GMON Hub UI Loaded")