repeat task.wait() until game:IsLoaded()

-- Services
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")

-- Global Flags and Configs
_G.Flags = {
    TrackEliteSpawn = false, TrackFullMoon = false, TrackGodChalice = false,
    AutoFarm = false, FarmBossSelected = false, FarmAllBoss = false, MasteryFruit = false,
    AutoCDK = false, AutoYama = false, AutoTushita = false, AutoSoulGuitar = false,
    KillSeaBeast = false, AutoSail = false,
    KillGolem = false, DefendVolcano = false, CollectDragonEgg = false, CollectBones = false,
    CollectAzure = false, TradeAzure = false,
    AttackLeviathan = false,
    GachaFruit = false, FruitTarget = "",
    ESPFruit = false, ESPPlayer = false, ESPChest = false, ESPFlower = false,
    ServerHop = false, RedeemCodes = false, FastAttack = false
}
_G.Config = { FarmInterval = 0.5 }

-- UI Library
local UI = {}; UI.__index = UI
UI.ToggleKey = Enum.KeyCode.M
UI.Visible = true
UI.MainFrame = nil

local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

function UI:Create()
    local gui = new("ScreenGui", { Name = "GMonHub_UI", ResetOnSpawn = false }, Players.LocalPlayer:WaitForChild("PlayerGui"))

-- UI Toggle Kiri & Draggable
local toggleBtn = new("TextButton", {
    Text = "G",
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(0, 10, 0.5, -15),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.3,
    Parent = gui
})
new("UICorner", {CornerRadius = UDim.new(0, 6)}, toggleBtn)
local dragging, dragInput, startPos, startInputPos
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        startPos = toggleBtn.Position
        startInputPos = input.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
toggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInput.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - startInputPos
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
toggleBtn.MouseButton1Click:Connect(function()
    UI.Visible = not UI.Visible
    UI.MainFrame.Visible = UI.Visible
end)

    -- RGB Background
    local bg = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Parent = gui })
    local bgStroke = new("UIStroke", { Thickness = 4, Transparency = 0.2, Parent = bg })
    task.spawn(function()
        local t = 0
        while true do
            t = (t + 0.005) % 1
            bgStroke.Color = Color3.fromHSV(t, 1, 1)
            task.wait(0.05)
        end
    end)

    -- Main Frame
    local frame = new("Frame", {
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BackgroundTransparency = 0.3,
        Active = true, Draggable = true,
        Visible = true, Parent = gui
    })
    new("UICorner", { CornerRadius = UDim.new(0, 10) }, frame)
    local stroke = new("UIStroke", { Thickness = 3, Parent = frame })
    task.spawn(function()
        local t = 0
        while true do
            t = (t + 0.01) % 1
            stroke.Color = Color3.fromHSV(t, 1, 1)
            task.wait(0.03)
        end
    end)
    UI.MainFrame = frame

    -- Tab setup
    local tabs, pages = {}, {}
    local tabNames = { "Info", "Main", "Item", "Sea", "Prehistoric", "Kitsune", "Leviathan", "DevilFruit", "ESP", "Misc", "Setting" }
    for i, name in ipairs(tabNames) do
        local btn = new("TextButton", {
            Text = name, Size = UDim2.new(0, 100, 0, 30),
            Position = UDim2.new(0, (i - 1) * 100, 0, 0),
            BackgroundTransparency = 0.7, TextColor3 = Color3.new(1, 1, 1),
            Parent = frame
        })
        local page = new("Frame", {
            Size = UDim2.new(1, 0, 1, -30), Position = UDim2.new(0, 0, 0, 30),
            Visible = false, BackgroundTransparency = 1, Parent = frame
        })
        new("UIListLayout", { Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })
        btn.MouseButton1Click:Connect(function()
            for _, p in ipairs(pages) do p.Visible = false end
            page.Visible = true
        end)
        if i == 1 then btn:MouseButton1Click() end
        table.insert(tabs, btn); table.insert(pages, page)
    end

    -- Add Toggle/Text helper
    local function addToggle(page, text, flag)
        local cb = new("TextButton", { Text = text, Size = UDim2.new(1, -20, 0, 30), BackgroundTransparency = 0.5, TextColor3 = Color3.new(1, 1, 1), Parent = page })
        cb.MouseButton1Click:Connect(function()
            _G.Flags[flag] = not _G.Flags[flag]
            cb.BackgroundColor3 = _G.Flags[flag] and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
        end)
    end
    local function addText(page, text)
        new("TextLabel", { Text = text, Size = UDim2.new(1, -20, 0, 20), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), Parent = page })
    end

    -- Populate Tabs
    local pg = pages[1]; addToggle(pg, "Track Elite Spawn", "TrackEliteSpawn"); addToggle(pg, "Track Full Moon", "TrackFullMoon"); addToggle(pg, "Track God Chalice", "TrackGodChalice")
    pg = pages[2]; addToggle(pg, "Auto Farm", "AutoFarm"); addToggle(pg, "Farm Boss Selected", "FarmBossSelected"); addToggle(pg, "Farm All Boss", "FarmAllBoss"); addToggle(pg, "Mastery Fruit", "MasteryFruit")
    pg = pages[3]; addToggle(pg, "Auto CDK", "AutoCDK"); addToggle(pg, "Auto Yama", "AutoYama"); addToggle(pg, "Auto Tushita", "AutoTushita"); addToggle(pg, "Auto Soul Guitar", "AutoSoulGuitar")
    pg = pages[4]; addToggle(pg, "Kill Sea Beast", "KillSeaBeast"); addToggle(pg, "Auto Sail", "AutoSail")
    pg = pages[5]; addToggle(pg, "Kill Golem", "KillGolem"); addToggle(pg, "Defend Volcano", "DefendVolcano"); addToggle(pg, "Collect Dragon Egg", "CollectDragonEgg"); addToggle(pg, "Collect Bones", "CollectBones")
    pg = pages[6]; addToggle(pg, "Collect Azure Ember", "CollectAzure"); addToggle(pg, "Trade Azure Ember", "TradeAzure")
    pg = pages[7]; addToggle(pg, "Attack Leviathan", "AttackLeviathan")
    pg = pages[8]; addToggle(pg, "Gacha Fruit", "GachaFruit")
    local fruitBox = new("TextBox", { PlaceholderText = "Fruit Target", Size = UDim2.new(1, -20, 0, 30), Parent = pg })
    fruitBox.FocusLost:Connect(function(enter) if enter then _G.Flags.FruitTarget = fruitBox.Text end end)
    pg = pages[9]; addToggle(pg, "ESP Fruit", "ESPFruit"); addToggle(pg, "ESP Player", "ESPPlayer"); addToggle(pg, "ESP Chest", "ESPChest"); addToggle(pg, "ESP Flower", "ESPFlower")
    pg = pages[10]; addToggle(pg, "Server Hop", "ServerHop"); addToggle(pg, "Redeem All Codes", "RedeemCodes")
    pg = pages[11]; addText(pg, "Toggle UI Key: press M"); addToggle(pg, "Fast Attack", "FastAttack")

    -- Toggle UI button (left side)
    local toggleBtn = new("TextButton", {
        Text = "G", Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 10, 0.5, -20), BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        TextColor3 = Color3.new(1, 1, 1), Parent = gui, Draggable = true, Active = true
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, toggleBtn)
    toggleBtn.MouseButton1Click:Connect(function()
        UI.Visible = not UI.Visible
        UI.MainFrame.Visible = UI.Visible
    end)

    -- Keybind M fallback
    UserInput.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == UI.ToggleKey and UI.MainFrame then
            UI.Visible = not UI.Visible
            UI.MainFrame.Visible = UI.Visible
        end
    end)
end

-- Init
UI:Create()