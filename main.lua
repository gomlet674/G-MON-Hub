-- main.lua (All-in-One G-Mon Hub) -- Menggabungkan UI Library, Main UI, dan Source Logic untuk fitur penuh seperti IsnaHamzah & Redz Hub

repeat task.wait() until game:IsLoaded()

-- Services local TweenService    = game:GetService("TweenService") local UserInput       = game:GetService("UserInputService") local Players         = game:GetService("Players") local ReplicatedStore = game:GetService("ReplicatedStorage") local CoreGui         = game:GetService("CoreGui")

-- Global flags for features _G.Flags = { AutoFarm              = false, AutoChest             = false, WeaponMode            = "Auto", ESP                   = false, Wallbang              = false, AutoSeaEvents         = false, AutoCrewDrop          = false, AutoDragonDojo        = false, AutoKitsune           = false, AutoPrehistoric       = false, AutoBossPrehistoric   = false, AutoRaceV4            = false, AutoRaid              = false, AutoBountyFarm        = false, FastAttack            = false, } _G.Config = { FarmInterval = 0.5, BoatSpeed = 100 }

--===[ UI Library ]===-- local UI = {} UI.__index = UI UI.ToggleKey     = Enum.KeyCode.M UI.MainFrame     = nil UI.WindowVisible = true

local function new(class, props, parent) local inst = Instance.new(class) for k,v in pairs(props or {}) do inst[k] = v end if parent then inst.Parent = parent end return inst end

-- Toggle UI Visibility UserInput.InputBegan:Connect(function(inp, g) if not g and inp.KeyCode == UI.ToggleKey and UI.MainFrame then UI.WindowVisible = not UI.WindowVisible UI.MainFrame.Visible = UI.WindowVisible end end)

function UI:CreateWindow(opts) opts = opts or {} local title  = opts.Title or "Hub" local radius = opts.Rounded and 8 or 0 local drag   = opts.Drag

-- ScreenGui and Main frame
local SGui = new("ScreenGui", {Name="GMonHub_UI", ResetOnSpawn=false}, CoreGui)
local Main = new("Frame", {
    Name = "MainFrame", Size = UDim2.new(0,460,0,360),
    Position = UDim2.new(0.5,-230,0.5,-180),
    BackgroundColor3 = Color3.fromRGB(25,25,25), BorderSizePixel=0
}, SGui)
new("UICorner", {CornerRadius=UDim.new(0,radius)}, Main)
UI.MainFrame = Main

-- RGB Border
local stroke = new("UIStroke", {Parent=Main, Thickness=2})
task.spawn(function()
    local t=0
    while task.wait(0.03) do
        t = (t + 0.01) % 1
        stroke.Color = Color3.fromHSV(t, 1, 1)
    end
end)

-- Title bar
local Top = new("Frame", {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1}, Main)
new("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text=title, Font=Enum.Font.GothamBold, TextSize=18, TextColor3=Color3.new(1,1,1)
}, Top)

-- Tab containers
local TabList = new("Frame", {Size=UDim2.new(0,120,1,-40), Position=UDim2.new(0,0,0,40), BackgroundTransparency=1}, Main)
local PageContainer = new("Frame", {Size=UDim2.new(1,-120,1,-40), Position=UDim2.new(0,120,0,40), BackgroundTransparency=1}, Main)

-- Drag functionality
if drag then
    local dragging, startMouse, startPos
    Top.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; startMouse=i.Position; startPos=Main.Position
        end
    end)
    Top.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then
            UserInput.InputChanged:Connect(function(inp)
                if inp==i and dragging then
                    local delta = inp.Position - startMouse
                    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X,
                                              startPos.Y.Scale, startPos.Y.Offset+delta.Y)
                end
            end)
        end
    end)
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputState==Enum.UserInputState.End then dragging=false end
    end)
end

-- Tabs state
local tabs, active = {}, nil
function UI:CreateTab(name)
    -- Tab button
    local btn = new("TextButton", {
        Name            = name.."Tab",
        Size            = UDim2.new(1,0,0,30),
        BackgroundTransp=1,
        Text            = "  "..name,
        Font            = Enum.Font.Gotham,
        TextSize        = 14,
        TextColor3      = Color3.fromRGB(180,180,180),
        Parent          = TabList
    })
    -- Page
    local page = new("ScrollingFrame", {
        Name             = name.."Page",
        Size             = UDim2.new(1,0,1,0),
        CanvasSize       = UDim2.new(0,0,2,0),
        ScrollBarThick   = 6,
        BackgroundTransp = 1,
        Visible          = false,
        Parent           = PageContainer
    })
    new("UIListLayout", {Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, page)

    -- Select logic
    local function selectTab()
        if active then active.Visible=false end
        page.Visible=true; active=page
        for _,c in ipairs(TabList:GetChildren()) do
            if c:IsA("TextButton") then
                c.TextColor3=(c==btn and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,180))
            end
        end
    end
    btn.MouseButton1Click:Connect(selectTab)
    if #tabs==0 then selectTab() end
    tabs[#tabs+1] = {Button=btn, Page=page}

    -- Tab API
    local API = {}
    function API:Button(opts)
        local b = new("TextButton", {
            Size            = UDim2.new(1,-10,0,30),
            BackgroundColor3= Color3.fromRGB(45,45,45),
            Text            = opts.Text or "Button",
            Font            = Enum.Font.Gotham,
            TextSize        = 14,
            TextColor3      = Color3.new(1,1,1),
            LayoutOrder     = #page:GetChildren()+1,
            Parent          = page
        })
        new("UICorner", {CornerRadius=UDim.new(0,4)}, b)
        b.MouseButton1Click:Connect(function() pcall(opts.Callback) end)
    end
    function API:Toggle(opts)
        local cont = new("Frame", {Size=UDim2.new(1,-10,0,30),BackgroundTransparency=1,LayoutOrder=#page:GetChildren()+1,Parent=page})
        local lbl = new("TextLabel", {Size=UDim2.new(0.75,0,1,0),BackgroundTransparency=1,Text=opts.Text or"Toggle",
            Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=cont})
        local tk = new("ImageButton", {Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-28,0,3),BackgroundTransparency=1,
            Image="rbxassetid://7033179166",Parent=cont})
        new("UICorner", {CornerRadius=UDim.new(0,4)}, tk)
        local state=false
        tk.MouseButton1Click:Connect(function()
            state = not state
            _G.Flags[opts.Flag] = state
            tk.Image = state and "rbxassetid://7033181995" or "rbxassetid://7033179166"
            if opts.Callback then pcall(opts.Callback, state) end
        end)
    end
    function API:Slider(opts)
        local cont = new("Frame", {Size=UDim2.new(1,-10,0,30),BackgroundTransparency=1,LayoutOrder=#page:GetChildren()+1,Parent=page})
        new("TextLabel", {Size=UDim2.new(0.4,0,1,0),BackgroundTransparency=1,Text=opts.Text or"Slider",
            Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=cont})
        local bg = new("Frame", {Size=UDim2.new(0.5,0,0,8),Position=UDim2.new(0.45,0,0.5,-4),BackgroundColor3=Color3.fromRGB(60,60,60),Parent=cont})
        new("UICorner", {CornerRadius=UDim.new(0,4)}, bg)
        local fill = new("Frame", {Size=UDim2.new((opts.Default-opts.min)/(opts.max-opts.min),0,1,0),BackgroundColor3=Color3.fromRGB(0,170,127),Parent=bg})
        new("UICorner", {CornerRadius=UDim.new(0,4)}, fill)
        local dragging
        local function update(i)
            local x = math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
            fill.Size = UDim2.new(x,0,1,0)
            local val = opts.min + (opts.max-opts.min)*x
            _G.Config[opts.ConfigKey] = val
            if opts.Callback then pcall(opts.Callback, val) end
        end
        bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i) end end)
        bg.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then UserInput.InputChanged:Connect(function(inp) if inp==i and dragging then update(inp) end end) end end)
        UserInput.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    end
    function API:Dropdown(opts)
        local cont = new("Frame",{Size=UDim2.new(1,-10,0,30),BackgroundTransparency=1,LayoutOrder=#page:GetChildren()+1,Parent=page})
        new("TextLabel",{Size=UDim2.new(0.4,0,1,0),BackgroundTransparency=1,Text=opts.Text or"Dropdown",
            Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=cont})
        local btn = new("TextButton",{Size=UDim2.new(0.55,0,1,0),Position=UDim2.new(0.45,0,0,0),BackgroundColor3=Color3.fromRGB(45,45,45),
            Text=opts.List[1] or"",Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=cont})
        new("UICorner",{CornerRadius=UDim.new(0,4)},btn)
        local menu=new("Frame",{Size=UDim2.new(0,btn.AbsoluteSize.X,0,0),Position=UDim2.new(0.45,0,1,2),BackgroundColor3=Color3.fromRGB(45,45,45),ClipsDescendants=true,Visible=false,Parent=cont})
        new("UICorner",{CornerRadius=UDim.new(0,4)},menu)
        new("UIListLayout",{Padding=UDim.new(0,2)},menu)
        local open=false
        btn.MouseButton1Click:Connect(function() open = not open; menu.Visible = open; menu:TweenSize(UDim2.new(0,btn.AbsoluteSize.X,0, open and (#opts.List*25) or 0), Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.2) end)
        for _,v in ipairs(opts.List or {}) do
            local it = new("TextButton",{Size=UDim2.new(1,0,0,25),BackgroundTransparency=1,Text=v,Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=menu})
            it.MouseButton1Click:Connect(function()
                btn.Text = v
                _G.Flags[opts.Flag] = v
                pcall(opts.Callback, v)
                open = false;
                menu:TweenSize(UDim2.new(0,menu.AbsoluteSize.X,0,0), Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.2)
            end)
        end
    end
    function API:Label(opts) new("TextLabel",{Size=UDim2.new(1,-10,0,20),BackgroundTransparency=1,Text=opts.Text or"",Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.fromRGB(200,200,200),LayoutOrder=#page:GetChildren()+1,Parent=page}) end
    function API:TextBox(opts)
        local tb = new("TextBox",{Size=UDim2.new(1,-10,0,30),BackgroundColor3=Color3.fromRGB(40,40,40),Text="",PlaceholderText=opts.Placeholder or"",Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),LayoutOrder=#page:GetChildren()+1,Parent=page})
        new("UICorner",{CornerRadius=UDim.new(0,4)}, tb)
        tb.FocusLost:Connect(function(enter) if enter and opts.Callback then pcall(opts.Callback, tb.Text) end end)
    end
    function API:Bullet(opts) new("TextLabel",{Size=UDim2.new(1,-10,0,20),BackgroundTransparency=1,Text="• "..(opts.Text or""),Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),LayoutOrder=#page:GetChildren()+1,Parent=page}) end
    return API
end
return UI

end

--===[ Main UI Setup ]===-- local Library = UI:CreateWindow({Title="G-Mon Hub | Blox Fruits", Rounded=true, Drag=true}) local Main      = Library:CreateTab("Main") local Stats     = Library:CreateTab("Stats") local Teleport  = Library:CreateTab("Teleport") local PlayersTb = Library:CreateTab("Players") local DFruit    = Library:CreateTab("DevilFruit") local EPSRaid   = Library:CreateTab("EPS-Raid") local BuyItem   = Library:CreateTab("Buy Item") local Misc      = Library:CreateTab("Misc") local Settings  = Library:CreateTab("Settings")

-- Main Tab (IsnaHamzah + Redz) Main:Toggle({Text="ESP", Flag="ESP"}) Main:Toggle({Text="Wallbang", Flag="Wallbang"}) Main:Toggle({Text="Auto Farm", Flag="AutoFarm"}) Main:Toggle({Text="Auto Chest", Flag="AutoChest"}) Main:Toggle({Text="Auto Sea Events", Flag="AutoSeaEvents"}) Main:Toggle({Text="Auto Crew Drop", Flag="AutoCrewDrop"}) Main:Toggle({Text="Auto Dragon Dojo", Flag="AutoDragonDojo"}) Main:Toggle({Text="Auto Kitsune", Flag="AutoKitsune"}) Main:Toggle({Text="Auto Prehistoric", Flag="AutoPrehistoric"}) Main:Toggle({Text="Auto Boss Prehistoric", Flag="AutoBossPrehistoric"}) Main:Toggle({Text="Auto Race V4", Flag="AutoRaceV4"}) Main:Toggle({Text="Auto EPS Raid", Flag="AutoRaid"}) Main:Button({Text="Server Hop", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/serverhop.lua", true))() end})

-- Stats Tab Stats:Button({Text="Refresh Stats", Callback=function() local d = Players.LocalPlayer:FindFirstChild("Data") if d then Stats:Bullet({Text="Level: "..d.Level.Value}) Stats:Bullet({Text="XP: "..d.XP.Value}) Stats:Bullet({Text="Money: "..d.Money.Value}) end end})

-- Teleport Tab Teleport:Dropdown({Text="Teleport To", List={"Starter Island","Pirate Village","Marine Fortress","Colosseum"}, Flag="TeleportLoc", Callback=function(loc) local coords = {['Starter Island']=Vector3.new(0,10,0), ['Pirate Village']=Vector3.new(500,20,300), ['Marine Fortress']=Vector3.new(-200,15,800), ['Colosseum']=Vector3.new(1000,30,100)} local char = Players.LocalPlayer.Character if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = CFrame.new(coords[loc]) end end})

-- Players Tab PlayersTb:TextBox({Placeholder="Player Name", Callback=function(n) _G.Target=n end}) PlayersTb:Button({Text="Bring Player", Callback=function() local p = Players:FindFirstChild(_G.Target) if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then Players.LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame end end}) PlayersTb:Button({Text="Kill Player", Callback=function() for _,v in pairs(workspace:GetDescendants()) do if v.Name==_G.Target and v:IsA("Humanoid") then v.Health = 0 end end end})

-- DevilFruit Tab DFruit:Toggle({Text="Auto Buy Fruit", Flag="AutoBuyFruit", Callback=function(v) if v then spawn(function() while _G.Flags.AutoBuyFruit do ReplicatedStore.RF:InvokeServer("BuyRandomFruit") task.wait(60) end end) end end}) DFruit:Button({Text="Equip Best Fruit", Callback=function() local bp = Players.LocalPlayer.Backpack:GetChildren() table.sort(bp, function(a,b) return a.Name < b.Name end) if bp[1] then bp[1]:Activate() end end})

-- EPS-Raid Tab EPSRaid:Button({Text="Teleport to EPS Raid", Callback=function() local pt = workspace:FindFirstChild("EPS_RaidPoint") if pt then Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pt.Position) end end}) EPSRaid:Toggle({Text="Auto Enter Raid", Flag="AutoRaid"})

-- Buy Item Tab BuyItem:TextBox({Placeholder="Item ID", Callback=function(id) _G.BuyID=id end}) BuyItem:Button({Text="Buy Item", Callback=function() ReplicatedStore.RF:InvokeServer("BuyItem", tonumber(_G.BuyID)) end})

-- Misc Tab Misc:Toggle({Text="Auto Bounty Farm", Flag="AutoBountyFarm"}) Misc:Button({Text="Redeem All Codes", Callback=function() for _,c in ipairs({"Sub2OfficialNoob","ILoveBloxFruit","EpicAttack"}) do ReplicatedStore.RF:InvokeServer("RedeemCode",c) task.wait(1) end end}) Misc:Button({Text="FPS Booster", Callback=function() setfpscap(60) workspace.Terrain.WaterWaveSize = 0 end})

-- Settings Tab Settings:Toggle({Text="Fast Attack", Flag="FastAttack"}) Settings:Slider({Text="Farm Interval", min=0.1, max=1, Default=_G.Config.FarmInterval, ConfigKey="FarmInterval"}) Settings:Slider({Text="Boat Speed", min=10, max=200, Default=_G.Config.BoatSpeed, ConfigKey="BoatSpeed"}) Settings:Dropdown({Text="Toggle UI Key", List={"M","K","L"}, Flag="ToggleKey", Callback=function(k) UI.ToggleKey = Enum.KeyCode[k] end}) Settings:Slider({Text="UI Transparency", min=0, max=1, Default=0, Callback=function(v) UI.MainFrame.BackgroundTransparency = v end})

-- Init UI -- note: library Init no-op

--===[ Source Logic Loader ]===-- spawn(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua",true))() end)

print("G-Mon Hub All-in-One loaded with full features!")

