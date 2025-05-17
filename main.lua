-- main.lua (All-in-One G-Mon Hub) -- Menggabungkan library.lua dan setup main UI + source loader

repeat task.wait() until game:IsLoaded()

-- Services local TweenService    = game:GetService("TweenService") local UserInput       = game:GetService("UserInputService") local Players         = game:GetService("Players") local ReplicatedStore = game:GetService("ReplicatedStorage") local CoreGui         = game:GetService("CoreGui")

--===[ UI Library ]===-- local UI = {} UI.__index = UI UI.ToggleKey     = Enum.KeyCode.M UI.MainFrame     = nil UI.WindowVisible = true

local function new(class, props, parent) local inst = Instance.new(class) for k,v in pairs(props or {}) do inst[k] = v end if parent then inst.Parent = parent end return inst end

-- Toggle visibility UserInput.InputBegan:Connect(function(inp, g) if not g and inp.KeyCode == UI.ToggleKey and UI.MainFrame then UI.WindowVisible = not UI.WindowVisible UI.MainFrame.Visible = UI.WindowVisible end end)

function UI:CreateWindow(opts) opts = opts or {} local title  = opts.Title or "Hub" local radius = opts.Rounded and 8 or 0 local drag   = opts.Drag

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
    while true do
        t = (t + 0.01) % 1
        local r = math.sin(t*2*math.pi)*0.5 + 0.5
        local g = math.sin(t*2*math.pi + 2)*0.5 + 0.5
        local b = math.sin(t*2*math.pi + 4)*0.5 + 0.5
        stroke.Color = Color3.new(r,g,b)
        task.wait(0.03)
    end
end)
-- Title bar
local Top = new("Frame", {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1}, Main)
new("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text=title, Font=Enum.Font.GothamBold, TextSize=18, TextColor3=Color3.new(1,1,1)
}, Top)
-- Containers
local TabList = new("Frame", {Size=UDim2.new(0,120,1,-40), Position=UDim2.new(0,0,0,40), BackgroundTransparency=1}, Main)
local PageContainer = new("Frame", {Size=UDim2.new(1,-120,1,-40), Position=UDim2.new(0,120,0,40), BackgroundTransparency=1}, Main)
-- Drag
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

local tabs, active = {}, nil
function UI:CreateTab(name)
    local btn = new("TextButton", {Name=name.."Tab", Size=UDim2.new(1,0,0,30), BackgroundTransparency=1,
        Text="  "..name, Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(180,180,180), Parent=TabList}, nil)
    local page = new("ScrollingFrame", {Name=name.."Page", Size=UDim2.new(1,0,1,0), CanvasSize=UDim2.new(0,0,2,0),
        ScrollBarThickness=6, BackgroundTransparency=1, Visible=false, Parent=PageContainer}, nil)
    new("UIListLayout", {Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, page)
    local function select()
        if active then active.Visible=false end; page.Visible=true; active=page
        for _,c in ipairs(TabList:GetChildren()) do
            if c:IsA("TextButton") then c.TextColor3=(c==btn and Color3.new(1,1,1) or Color3.fromRGB(180,180,180)) end
        end
    end
    btn.MouseButton1Click:Connect(select)
    if #tabs==0 then select() end
    tabs[#tabs+1]={Button=btn,Page=page}
    -- Tab API
    local API={}
    function API:Button(opts)
        local b=new("TextButton",{Size=UDim2.new(1,-10,0,30), BackgroundColor3=Color3.fromRGB(45,45,45),
            Text=opts.Text or"Btn",Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=page},nil)
        new("UICorner",{CornerRadius=UDim.new(0,4)},b)
        b.MouseButton1Click:Connect(function() pcall(opts.Callback) end)
    end
    function API:Toggle(opts)
        local cont=new("Frame",{Size=UDim2.new(1,-10,0,30),BackgroundTransparency=1,Parent=page},nil)
        local lbl=new("TextLabel",{Size=UDim2.new(0.75,0,1,0),BackgroundTransparency=1,Text=opts.Text or"Toggle",
            Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=cont},nil)
        local tk=new("ImageButton",{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-28,0,3),BackgroundTransparency=1,
            Image="rbxassetid://7033179166",Parent=cont},nil)
        new("UICorner",{CornerRadius=UDim.new(0,4)},tk)
        local st=false;tk.MouseButton1Click:Connect(function()st=not st;tk.Image=st and "rbxassetid://7033181995" or "rbxassetid://7033179166";pcall(opts.Callback,st)end)
    end
    function API:Slider(opts)
        local cont=new("Frame",{Size=UDim2.new(1,-10,0,30),BackgroundTransparency=1,Parent=page},nil)
        new("TextLabel",{Size=UDim2.new(0.4,0,1,0),BackgroundTransparency=1,Text=opts.Text or"Slider",
            Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=cont},nil)
        local bg=new("Frame",{Size=UDim2.new(0.5,0,0,8),Position=UDim2.new(0.45,0,0.5,-4),BackgroundColor3=Color3.fromRGB(60,60,60),Parent=cont},nil)
        new("UICorner",{CornerRadius=UDim.new(0,4)},bg)
        local fill=new("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=Color3.fromRGB(0,170,127),Parent=bg},nil)
        new("UICorner",{CornerRadius=UDim.new(0,4)},fill)
        local dragging
        local function upd(i)
            local x=math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
            fill.Size=UDim2.new(x,0,1,0)
            local val=(opts.min or 0)+(opts.max-(opts.min or 0))*x
            pcall(opts.Callback,val)
        end
        bg.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;upd(i)end end)
        bg.InputChanged:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseMovement then UserInput.InputChanged:Connect(function(inp)if inp==i and dragging then upd(inp)end end)end end)
        UserInput.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    end
    function API:Dropdown(opts)
        local cont=new("Frame",{Size=UDim2.new(1,-10,0,30),BackgroundTransparency=1,Parent=page},nil)
        new("TextLabel",{Size=UDim2.new(0.4,0,1,0),BackgroundTransparency=1,Text=opts.Text or"Drop",
            Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=cont},nil)
        local btn=new("TextButton",{Size=UDim2.new(0.55,0,1,0),Position=UDim2.new(0.45,0,0,0),
            BackgroundColor3=Color3.fromRGB(45,45,45),Text=opts.List[1] or"",Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=cont},nil)
        new("UICorner",{CornerRadius=UDim.new(0,4)},btn)
        local menu=new("Frame",{Size=UDim2.new(0,btn.AbsoluteSize.X,0,0),Position=UDim2.new(0.45,0,1,2),
            BackgroundColor3=Color3.fromRGB(45,45,45),ClipsDescendants=true,Visible=false,Parent=cont},nil)
        new("UICorner",{CornerRadius=UDim.new(0,4)},menu)
        new("UIListLayout",{Padding=UDim.new(0,2)},menu)
        local open=false
        btn.MouseButton1Click:Connect(function()open=not open;menu.Visible=open;menu:TweenSize(UDim2.new(0,btn.AbsoluteSize.X,0,open and(#opts.List*25)or 0),Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0.2)end)
        for _,v in ipairs(opts.List or {})do local it=new("TextButton",{Size=UDim2.new(1,0,0,25),BackgroundTransparency=1,Text=v,Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=menu},nil)
            it.MouseButton1Click:Connect(function()btn.Text=v;pcall(opts.Callback,v);open=false;menu:TweenSize(UDim2.new(0,menu.AbsoluteSize.X,0,0),Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0.2)end)
        end
    end
    function API:Label(opts) new("TextLabel",{Size=UDim2.new(1,-10,0,20),BackgroundTransparency=1,Text=opts.Text or"",Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.fromRGB(200,200,200),Parent=page},nil) end
    function API:TextBox(opts)
        local tb=new("TextBox",{Size=UDim2.new(1,-10,0,30),BackgroundColor3=Color3.fromRGB(40,40,40),Text="",PlaceholderText=opts.Placeholder or"",Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=page},nil)
        new("UICorner",{CornerRadius=UDim.new(0,4)},tb)
        tb.FocusLost:Connect(function(enter)if enter then pcall(opts.Callback,tb.Text)end end)
    end
    function API:Bullet(opts) new("TextLabel",{Size=UDim2.new(1,-10,0,20),BackgroundTransparency=1,Text="• "..(opts.Text or""),Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.new(1,1,1),Parent=page},nil) end
    return API
end
return UI

end

--===[ Main UI Setup ]===-- local UI        = UI:CreateWindow({Title="G-Mon Hub | Blox Fruits", Rounded=true, Drag=true}) local Tabs      = {Main=UI:CreateTab("Main"), Fruit=UI:CreateTab("DevilFruit"), Farm=UI:CreateTab("Auto Farm"), Boss=UI:CreateTab("Auto Boss"), TP=UI:CreateTab("Teleport"), Misc=UI:CreateTab("Misc"), Settings=UI:CreateTab("Settings")} -- Contoh fitur di Main tabs.Main.Toggle({Text="Auto Farm", Flag="AF", Callback=function(v) _G.AutoFarm=v end}) -- (Tambah elemen lain sesuai source.lua)

UI:Init()

--===[ Source Logic Loader ]===-- spawn(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua",true))() end)

print("G-Mon Hub All-in-One loaded!")

