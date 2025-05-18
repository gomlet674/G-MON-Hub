-- main.lua – GMON Hub UI Final (Ultimate)
repeat task.wait() until game:IsLoaded()

-- SERVICES
local HttpService   = game:GetService("HttpService")
local Players       = game:GetService("Players")
local UserInput     = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")

-- GLOBAL CONFIG
_G.Flags  = _G.Flags  or {}
_G.Config = _G.Config or { FarmInterval = 0.5 }

-- TRY LOAD REMOTE SOURCE (NON-FATAL) & SIMPAN MODUL
local function tryLoadRemote()
    if not HttpService.HttpEnabled then
        pcall(function() HttpService.HttpEnabled = true end)
    end
    local ok, result = pcall(function()
        return HttpService:GetAsync("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua")
    end)
    if ok and type(result) == "string" and #result > 50 then
        local fn, err = loadstring(result)
        if not fn then
            warn("GMON: loadstring error:", err)
            return nil
        end
        local success, module = pcall(fn)
        if success and type(module) == "table" then
            return module
        end
    end
    warn("GMON: Gagal memuat source.lua, pakai fallback ModuleScript if ada")
    if script:FindFirstChild("source") then
        return require(script.source)
    end
    return nil
end

local source = tryLoadRemote()
if not source then
    error("GMON: source.lua tidak berhasil di-load, logic akan gagal.")
end

-- HELPER: Instance.new + properti
local function New(cls, props, parent)
    local inst = Instance.new(cls)
    for k,v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- DRAGGABLE MAKER
local function makeDraggable(guiObject)
    local dragging, startPos, startInput
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos   = guiObject.Position
            startInput = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            guiObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- CONTROL HELPERS
local function AddSwitch(page, text, flag)
    local ctr = New("Frame", {
        Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1,
        LayoutOrder = #page:GetChildren(),
    }, page)
    New("TextLabel", {
        Text = text, Size = UDim2.new(0.7,0,1,0),
        BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, ctr)
    local sw = New("TextButton", {
        Text = "", Size = UDim2.new(0,40,0,20),
        Position = UDim2.new(1,-50,0,5),
        BackgroundColor3 = Color3.new(1,1,1), AutoButtonColor = false,
    }, ctr)
    New("UICorner", { CornerRadius = UDim.new(0,10) }, sw)

    local knob = New("Frame", {
        Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,1,0,1),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
    }, sw)
    New("UICorner", { CornerRadius = UDim.new(0,9) }, knob)

    _G.Flags[flag] = _G.Flags[flag] or false
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    local function toggle()
        _G.Flags[flag] = not _G.Flags[flag]
        sw.BackgroundColor3 = _G.Flags[flag]
            and Color3.fromRGB(0,170,0)
            or Color3.new(1,1,1)
        local goal = { Position = _G.Flags[flag]
            and UDim2.new(1,-19,0,1)
            or UDim2.new(0,1,0,1) }
        TweenService:Create(knob, tweenInfo, goal):Play()
    end
    sw.Activated:Connect(toggle)
    -- init state
    toggle()
end

local function AddDropdown(page, label, list, flag)
    New("TextLabel", {
        Text = label, Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = #page:GetChildren(),
    }, page)
    local btn = New("TextButton", {
        Text = list[1] or "Select",
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        TextColor3 = Color3.new(1,1,1),
        LayoutOrder = #page:GetChildren(),
    }, page)
    New("UICorner", { CornerRadius = UDim.new(0,6) }, btn)

    btn.Activated:Connect(function()
        if btn:FindFirstChild("Menu") then return end
        local menu = New("Frame", {
            Name = "Menu",
            Size = UDim2.new(0, btn.AbsoluteSize.X, 0, #list*25),
            Position = UDim2.new(0, btn.AbsolutePosition.X, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y),
            BackgroundColor3 = Color3.fromRGB(30,30,30),
            ZIndex = 10,
        }, btn)
        New("UICorner", { CornerRadius = UDim.new(0,6) }, menu)

        for i,v in ipairs(list) do
            local opt = New("TextButton", {
                Text = v, Size = UDim2.new(1,0,0,25),
                BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1),
                LayoutOrder = i, Parent = menu,
            })
            opt.Position = UDim2.new(0,0,0,(i-1)*25)
            opt.Activated:Connect(function()
                btn.Text = v
                _G.Flags[flag] = v
                menu:Destroy()
            end)
        end
    end)
end

local function AddToggle(page, text, flag)
    local btn = New("TextButton", {
        Text = text, Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(60,60,60),
        TextColor3 = Color3.new(1,1,1),
        LayoutOrder = #page:GetChildren(),
    }, page)
    New("UICorner", { CornerRadius = UDim.new(0,6) }, btn)

    _G.Flags[flag] = _G.Flags[flag] or false
    btn.Activated:Connect(function()
        _G.Flags[flag] = not _G.Flags[flag]
        btn.BackgroundColor3 = _G.Flags[flag]
            and Color3.fromRGB(0,170,0)
            or Color3.fromRGB(60,60,60)
    end)
end

local function AddText(page, txt)
    New("TextLabel", {
        Text = txt, Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = #page:GetChildren(),
    }, page)
end

-- BUILD GUI
local gui = New("ScreenGui", {
    Name = "GMONHub_UI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, Players.LocalPlayer:WaitForChild("PlayerGui"))

New("ImageLabel", {
    Image = "rbxassetid://16790218639",
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    ZIndex = 0,
}, gui)

local frame = New("Frame", {
    Size = UDim2.new(0,600,0,450),
    Position = UDim2.new(0.5,-300,0.5,-225),
    BackgroundColor3 = Color3.new(0,0,0),
    BackgroundTransparency = 0.5,
    Visible = false,
}, gui)
New("UICorner", { CornerRadius = UDim.new(0,12) }, frame)
makeDraggable(frame)

local stroke = New("UIStroke", {
    Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame,
})
task.spawn(function()
    local hue = 0
    while frame.Parent do
        hue = (hue + 0.005) % 1
        stroke.Color = Color3.fromHSV(hue,1,1)
        task.wait(0.03)
    end
end)

local toggle = New("TextButton", {
    Text = "GMON", Size = UDim2.new(0,70,0,35),
    Position = UDim2.new(0,20,0,20),
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    TextColor3 = Color3.new(1,1,1), ZIndex = 10,
}, gui)
New("UICorner", { CornerRadius = UDim.new(0,8) }, toggle)
makeDraggable(toggle)
toggle.Activated:Connect(function() frame.Visible = not frame.Visible end)
UserInput.InputBegan:Connect(function(inp,gp)
    if not gp and inp.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- Tabs & Pages
local tabNames = {"Info","Main","Item","Sea","Prehistoric","Kitsune","Leviathan","DevilFruit","ESP","Misc","Setting"}
local pages = {}
local tabScroll = New("ScrollingFrame", {
    Size = UDim2.new(1,0,0,40), Position = UDim2.new(0,0,0,0),
    BackgroundTransparency = 1, ScrollingDirection = Enum.ScrollingDirection.X,
    ScrollBarThickness = 6, CanvasSize = UDim2.new(0,#tabNames*110,0,40),
    Parent = frame,
})
New("UIListLayout", { Parent = tabScroll, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,5) }, tabScroll)

for i,name in ipairs(tabNames) do
    local btn = New("TextButton", {
        Text = name, Size = UDim2.new(0,100,0,35),
        BackgroundTransparency = 0.7, BackgroundColor3 = Color3.new(30,30,30),
        TextColor3 = Color3.new(1,1,1), ZIndex = 5,
    }, tabScroll)
    New("UICorner", { CornerRadius = UDim.new(0,8) }, btn)

    local page = New("ScrollingFrame", {
        Size = UDim2.new(1,-20,1,-80), Position = UDim2.new(0,10,0,50),
        BackgroundTransparency = 1, Visible = (i==1), ScrollBarThickness = 6,
        Parent = frame,
    })
    New("UIListLayout", { Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,5) }, page)

    btn.Activated:Connect(function()
        for _,p in ipairs(pages) do p.Visible = false end
        page.Visible = true
        for _,sib in ipairs(tabScroll:GetChildren()) do
            if sib:IsA("TextButton") then sib.BackgroundColor3 = Color3.new(30,30,30) end
        end
        btn.BackgroundColor3 = Color3.fromRGB(0,170,0)
    end)

    table.insert(pages, page)
end

-- POPULATE TABS
-- Info
AddText(pages[1],"Toggle GUI: Press M or click GMON")
AddText(pages[1],"Moon Phase: Loading…")
AddText(pages[1],"Kitsune Island: Loading…")
AddText(pages[1],"Prehistoric Island: Loading…")
AddText(pages[1],"Mirage Island: Loading…")
AddText(pages[1],"Tyrant of the Skies: Loading…")
AddText(pages[1],"God Chalice: Loading…")

-- Dynamic Info
spawn(function()
    while task.wait(10) do
        local phase      = source.getMoonPhase()
        local kitsune    = source.islandSpawned("KitsuneIsland")     and "✅" or "❌"
        local prehistoric= source.islandSpawned("PrehistoricIsland") and "✅" or "❌"
        local mirage     = source.islandSpawned("MirageIsland")      and "✅" or "❌"
        local tyrant     = source.islandSpawned("TyrantOfTheSkies")  and "✅" or "❌"
        local chalice    = source.hasGodChalice()                    and "✅" or "❌"
        local labels = pages[1]:GetChildren()
        labels[1].Text = "Moon Phase: "..phase
        labels[2].Text = "Kitsune Island: "..kitsune
        labels[3].Text = "Prehistoric Island: "..prehistoric
        labels[4].Text = "Mirage Island: "..mirage
        labels[5].Text = "Tyrant of the Skies: "..tyrant
        labels[6].Text = "God Chalice: "..chalice
    end
end)

-- Main
AddSwitch(pages[2],"Auto Farm","AutoFarm")
AddDropdown(pages[2],"Select Boss", source.allBosses(), "SelectedBoss")
AddSwitch(pages[2],"Farm Boss Selected","FarmBossSelected")
AddSwitch(pages[2],"Farm Chest","FarmChest")

spawn(function()
    local plr = Players.LocalPlayer
    while task.wait(_G.Config.FarmInterval) do
        if _G.Flags.AutoFarm then
            source.autoFarm(plr, 2650)
        end
        if _G.Flags.FarmBossSelected and _G.Flags.SelectedBoss then
            source.farmBoss(plr, _G.Flags.SelectedBoss)
        end
        if _G.Flags.FarmChest then
            source.farmChest(plr)
        end
    end
end)

-- Item
AddToggle(pages[3],"Auto Get Yama","AutoYama")
AddToggle(pages[3],"Auto Tushita","AutoTushita")
AddToggle(pages[3],"Auto Soul Guitar","AutoSoulGuitar")
AddToggle(pages[3],"Auto CDK","AutoCDK")

-- Sea
AddSwitch(pages[4],"Kill Sea Beast","KillSeaBeast")
AddSwitch(pages[4],"Auto Sail","AutoSail")

-- Prehistoric
AddToggle(pages[5],"Kill Golem","KillGolem")
AddToggle(pages[5],"Defend Volcano","DefendVolcano")
AddToggle(pages[5],"Collect Dragon Egg","CollectDragonEgg")
AddToggle(pages[5],"Collect Bones","CollectBones")

-- Kitsune
AddToggle(pages[6],"Collect Azure Ember","CollectAzure")
AddToggle(pages[6],"Trade Azure Ember","TradeAzure")

-- Leviathan
AddToggle(pages[7],"Attack Leviathan","AttackLeviathan")

-- DevilFruit
AddToggle(pages[8],"Gacha Fruit","GachaFruit")
AddText(pages[8],"Fruit Target:")
AddDropdown(pages[8],"Select Fruit",{"Bomb","Flame","Quake"},"FruitTarget")

-- ESP
AddToggle(pages[9],"ESP Fruit","ESPFruit")
AddToggle(pages[9],"ESP Player","ESPPlayer")
AddToggle(pages[9],"ESP Chest","ESPChest")
AddToggle(pages[9],"ESP Flower","ESPFlower")

-- Misc
AddToggle(pages[10],"Server Hop","ServerHop")
AddToggle(pages[10],"Redeem All Codes","RedeemCodes")
AddToggle(pages[10],"FPS Booster","FPSBooster")
AddToggle(pages[10],"Auto Awaken Fruit","AutoAwaken")

-- Setting
AddToggle(pages[11],"Fast Attack","FastAttack")
AddText(pages[11],"Version: vFinal")

print("GMON Hub UI Loaded")