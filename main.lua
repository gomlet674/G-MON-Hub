-- main.lua – GMON Hub UI Final (Ultimate)

repeat task.wait() until game:IsLoaded()

-- SERVICES
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Replicated   = game:GetService("ReplicatedStorage")
local UserInput    = game:GetService("UserInputService")

-- GLOBAL CONFIG
_G.Flags  = _G.Flags  or {}
_G.Config = {
    FarmInterval  = 0.5,
    MaxQuestLevel = 2650,
}

-- HELPER: Instance.new + properti
local function New(cls, props, parent)
    local inst = Instance.new(cls)
    for k,v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- DRAGGABLE MAKER
local function makeDraggable(gui)
    local dragging, startPos, startInput
    gui.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging   = true
            startPos   = gui.Position
            startInput = inp.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInput.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - startInput
            gui.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- CONTROL HELPERS
local function AddSwitch(page, label, flag)
    local ctr = New("Frame", {
        Size = UDim2.new(1,0,0,30),
        BackgroundTransparency = 1,
        LayoutOrder = #page:GetChildren()+1,
    }, page)
    New("TextLabel", {
        Text = label,
        Size = UDim2.new(0.7,0,1,0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, ctr)

    local sw = New("TextButton", {
        Text = "",
        Size = UDim2.new(0,40,0,20),
        Position = UDim2.new(1,-50,0,5),
        BackgroundColor3 = Color3.new(1,1,1),
        AutoButtonColor = false,
    }, ctr)
    New("UICorner", { CornerRadius = UDim.new(0,10) }, sw)
    local knob = New("Frame", {
        Size = UDim2.new(0,18,0,18),
        Position = UDim2.new(0,1,0,1),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
    }, sw)
    New("UICorner", { CornerRadius = UDim.new(0,9) }, knob)

    _G.Flags[flag] = _G.Flags[flag] or false
    local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    local function update()
        local goal = { Position = _G.Flags[flag]
            and UDim2.new(1,-19,0,1)
            or UDim2.new(0,1,0,1)
        }
        sw.BackgroundColor3 = _G.Flags[flag]
            and Color3.fromRGB(0,170,0)
            or Color3.new(1,1,1)
        TweenService:Create(knob, ti, goal):Play()
    end
    sw.Activated:Connect(function()
        _G.Flags[flag] = not _G.Flags[flag]
        update()
    end)
    update()
end

local function AddDropdown(page, label, list, flag)
    New("TextLabel", {
        Text = label,
        Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = #page:GetChildren()+1,
    }, page)

    local btn = New("TextButton", {
        Text = list[1] or "Select",
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        TextColor3 = Color3.new(1,1,1),
        LayoutOrder = #page:GetChildren()+1,
    }, page)
    New("UICorner", { CornerRadius = UDim.new(0,6) }, btn)

    btn.Activated:Connect(function()
        if btn:FindFirstChild("Menu") then return end
        local menu = New("Frame", {
            Name = "Menu",
            Size = UDim2.new(0, btn.AbsoluteSize.X, 0, #list*25),
            Position = btn.AbsolutePosition + Vector2.new(0, btn.AbsoluteSize.Y),
            BackgroundColor3 = Color3.fromRGB(30,30,30),
            ZIndex = 10,
        }, btn)
        New("UICorner", { CornerRadius = UDim.new(0,6) }, menu)
        for i,v in ipairs(list) do
            local opt = New("TextButton", {
                Text = v,
                Size = UDim2.new(1,0,0,25),
                BackgroundTransparency = 1,
                TextColor3 = Color3.new(1,1,1),
                LayoutOrder = i,
                Parent = menu,
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

local function AddToggle(page, label, flag)
    local btn = New("TextButton", {
        Text = label,
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(60,60,60),
        TextColor3 = Color3.new(1,1,1),
        LayoutOrder = #page:GetChildren()+1,
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

local function AddText(page, text)
    New("TextLabel", {
        Text = text,
        Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = #page:GetChildren()+1,
    }, page)
end

-- BUILD GUI
local gui = New("ScreenGui", {
    Name = "GMONHub_UI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, Players.LocalPlayer:WaitForChild("PlayerGui"))

-- MAIN FRAME
local frame = New("Frame", {
    Size = UDim2.new(0,600,0,450),
    Position = UDim2.new(0.5,-300,0.5,-225),
    BackgroundColor3 = Color3.new(0,0,0),
    BackgroundTransparency = 0.5,
    ZIndex = 1,
    Visible = false,
}, gui)
New("UICorner", { CornerRadius = UDim.new(0,12) }, frame)
makeDraggable(frame)

-- BACKGROUND IMAGE (sekarang di dalam frame, ZIndex=0 sehingga tidak blok drag)
local bg = New("ImageLabel", {
    Image = "rbxassetid://16790218639",
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    ZIndex = 0,
    Active = false,
    Selectable = false,
}, frame)

-- RGB BORDER ANIM
local stroke = New("UIStroke", {
    Parent = frame,
    Thickness = 4,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
task.spawn(function()
    local hue = 0
    while frame.Parent do
        hue = (hue + 0.005) % 1
        stroke.Color = Color3.fromHSV(hue,1,1)
        task.wait(0.03)
    end
end)

-- TOGGLE BUTTON (GMON)
local toggle = New("TextButton", {
    Text = "GMON",
    Size = UDim2.new(0,70,0,35),
    Position = UDim2.new(0,20,0,20),
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    TextColor3 = Color3.new(1,1,1),
    ZIndex = 2,
}, gui)
New("UICorner", { CornerRadius = UDim.new(0,8) }, toggle)
makeDraggable(toggle)
toggle.Activated:Connect(function()
    frame.Visible = not frame.Visible
end)
UserInput.InputBegan:Connect(function(inp, gp)
    if not gp and inp.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- TABS & PAGES SETUP
local tabNames = {"Info","Main","Item","Sea","Prehistoric","Kitsune","Leviathan","DevilFruit","ESP","Misc","Setting"}
local pages = {}
local tabScroll = New("ScrollingFrame", {
    Size = UDim2.new(1,0,0,40),
    Position = UDim2.new(0,0,0,0),
    BackgroundTransparency = 1,
    ScrollingDirection = Enum.ScrollingDirection.X,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(#tabNames*80,0,0,40),
    ZIndex = 2,
    Parent = frame,
})
New("UIListLayout", {
    Parent = tabScroll,
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0,5),
}, tabScroll)

for i,name in ipairs(tabNames) do
    local tbtn = New("TextButton", {
        Text = name,
        Size = UDim2.new(0,80,1,0),
        BackgroundColor3 = Color3.new(30,30,30),
        TextColor3 = Color3.new(1,1,1),
        LayoutOrder = i,
        ZIndex = 2,
        Parent = tabScroll,
    })
    New("UICorner", { CornerRadius = UDim.new(0,6) }, tbtn)

    local page = New("Frame", {
        Name = name.."Page",
        Size = UDim2.new(1,0,1,-40),
        Position = UDim2.new(0,0,0,40),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Visible = (i==1),
        Parent = frame,
    })
    New("UIListLayout", {
        Parent = page,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,5),
    }, page)
    pages[name] = page

    tbtn.Activated:Connect(function()
        for _,p in pairs(pages) do p.Visible = false end
        pages[name].Visible = true
    end)
end

-- INFO TAB LOGIC (update tiap 5 detik)
task.spawn(function()
    while true do
        local info = pages.Info
        info:ClearAllChildren()
        AddText(info, "Toggle GUI: Press M or click GMON")
        local m = os.date("*t").min % 8
        local phases = {"🌑","🌒","🌓","🌔","🌕","🌖","🌗","🌘"}
        AddText(info, "Moon Phase: "..phases[m+1].." ("..m.."/4)")
        local function chk(name) return workspace:FindFirstChild(name) and "✅" or "❌" end
        AddText(info, "Kitsune Island: "..chk("KitsuneIsland"))
        AddText(info, "Prehistoric Island: "..chk("PrehistoricIsland"))
        AddText(info, "Mirage Island: "..chk("MirageIsland"))
        AddText(info, "Tyrant of the Skies: "..chk("TyrantOfTheSkies"))
        local hasChalice = Players.LocalPlayer.Backpack:FindFirstChild("GodChalice") and "✅" or "❌"
        AddText(info, "God Chalice: "..hasChalice)
        task.wait(5)
    end
end)

-- MAIN LOGIC: AutoQuest, FarmBoss, FarmChest
task.spawn(function()
    while true do
        if _G.Flags.AutoFarm then
            for lvl=1, _G.Config.MaxQuestLevel do
                pcall(function()
                    Replicated.Remotes.Quest:InvokeServer(Players.LocalPlayer.SeaLevel.Value, lvl)
                end)
            end
        end
        if _G.Flags.FarmBossSelected and _G.Flags.SelectedBoss then
            local boss = workspace:FindFirstChild(_G.Flags.SelectedBoss)
            local char = Players.LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if boss and boss.PrimaryPart and hum then
                hum:MoveTo(boss.PrimaryPart.Position + Vector3.new(0,5,0))
            end
        end
        if _G.Flags.FarmChest then
            local char = Players.LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local sea  = Players.LocalPlayer.SeaLevel.Value
            if hum then
                for _,c in ipairs(workspace:GetDescendants()) do
                    if c.Name=="Chest" and c:FindFirstChild("Sea") and c.Sea.Value==sea then
                        local pos = (c.PrimaryPart and c.PrimaryPart.Position) or c.Position
                        hum:MoveTo(pos)
                        hum.MoveToFinished:Wait(1)
                        pcall(function() Replicated.Remotes.OpenChest:InvokeServer(c) end)
                    end
                end
            end
        end
        task.wait(_G.Config.FarmInterval)
    end
end)

-- POPULATE MAIN TAB
do
    local m = pages.Main
    AddSwitch(m, "Auto Farm",           "AutoFarm")
    AddDropdown(m,"Select Boss",        {"Gorilla King","Bobby","Saw","Yeti","Ice Admiral"}, "SelectedBoss")
    AddSwitch(m, "Farm Boss Selected",  "FarmBossSelected")
    AddSwitch(m, "Farm Chest",          "FarmChest")
end

-- OTHER TABS
do local p = pages.Item
    AddToggle(p,"Auto Get Yama",   "AutoYama")
    AddToggle(p,"Auto Tushita",    "AutoTushita")
    AddToggle(p,"Auto Soul Guitar","AutoSoulGuitar")
    AddToggle(p,"Auto CDK",        "AutoCDK")
end
do local p = pages.Sea
    AddSwitch(p,"Kill Sea Beast","KillSeaBeast")
    AddSwitch(p,"Auto Sail",    "AutoSail")
end
do local p = pages.Prehistoric
    AddToggle(p,"Kill Golem",         "KillGolem")
    AddToggle(p,"Defend Volcano",     "DefendVolcano")
    AddToggle(p,"Collect Dragon Egg", "CollectDragonEgg")
    AddToggle(p,"Collect Bones",      "CollectBones")
end
do local p = pages.Kitsune
    AddToggle(p,"Collect Azure Ember","CollectAzure")
    AddToggle(p,"Trade Azure Ember",  "TradeAzure")
end
do local p = pages.Leviathan
    AddToggle(p,"Attack Leviathan","AttackLeviathan")
end
do local p = pages.DevilFruit
    AddToggle(p,"Gacha Fruit","GachaFruit")
    AddText   (p,"Fruit Target:")
    AddDropdown(p,"",{"Bomb","Flame","Quake"},"FruitTarget")
end
do local p = pages.ESP
    AddToggle(p,"ESP Fruit",  "ESPFruit")
    AddToggle(p,"ESP Player", "ESPPlayer")
    AddToggle(p,"ESP Chest",  "ESPChest")
    AddToggle(p,"ESP Flower", "ESPFlower")
end
do local p = pages.Misc
    AddToggle(p,"Server Hop",      "ServerHop")
    AddToggle(p,"Redeem All Codes","RedeemCodes")
    AddToggle(p,"FPS Booster",     "FPSBooster")
    AddToggle(p,"Auto Awaken Fruit","AutoAwaken")
end
do local p = pages.Setting
    AddToggle(p,"Fast Attack","FastAttack")
    AddText   (p,"Version: vFinal")
end

print("GMON Hub UI Loaded (Ultimate)")