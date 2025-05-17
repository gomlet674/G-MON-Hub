-- main.lua -- G-Mon Hub: UI + Loader repeat task.wait() until game:IsLoaded()

-- Services game:GetService("RunService"):BindToRenderStep("LoadUI",Enum.RenderPriority.First, function() game:GetService("RunService"):UnbindFromRenderStep("LoadUI")

local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")

-- UI Library embedded
local UI = {}
UI.__index = UI
UI.ToggleKey = Enum.KeyCode.M
UI.MainFrame = nil
UI.Visible = true
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end
UserInput.InputBegan:Connect(function(i,g)
    if not g and i.KeyCode==UI.ToggleKey and UI.MainFrame then
        UI.Visible = not UI.Visible
        UI.MainFrame.Visible = UI.Visible
    end
end)
function UI:CreateWindow()
    local SGui = new("ScreenGui",{Name="GMonHub"},CoreGui)
    local bg = new("ImageLabel",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=0,
        Image="rbxassetid://16790218639",ScaleType=Enum.ScaleType.Crop,
        ZIndex=0,Parent=SGui
    })
    -- RGB Overlay
    local overlay = new("Frame",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=SGui
    })
    local stroke = new("UIStroke",{Parent=overlay,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},nil)
    task.spawn(function()
        local t=0
        while true do
            t=(t+0.01)%1
            stroke.Color = Color3.fromHSV(t,1,1)
            task.wait(0.03)
        end
    end)
    -- Main Frame
    local Main = new("Frame",{
        Name="MainFrame",Size=UDim2.new(0,480,0,360),Position=UDim2.new(0.5,-240,0.5,-180),
        BackgroundColor3=Color3.fromRGB(25,25,25),BackgroundTransparency=0.5,ClipsDescendants=true
    },SGui)
    UI.MainFrame = Main
    new("UICorner",{CornerRadius=UDim.new(0,12)},Main)
    -- Tabs
    local tablist = new("Frame",{Size=UDim2.new(0,120,1,0),Position=UDim2.new(0,0,0,0),BackgroundTransparency=1},Main)
    local pages = new("Frame",{Size=UDim2.new(1,-120,1,0),Position=UDim2.new(0,120,0,0),BackgroundTransparency=1},Main)
    local tabs,active
    local names={"Main","Stat","TP","Players","DFruit","Misc","Settings"}
    for i,name in ipairs(names) do
        local btn=new("TextButton",{
            Name=name.."Tab",Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,0,(i-1)*30),
            BackgroundTransparency=1,Text=name,Font=Enum.Font.Gotham,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left
        },tablist)
        local page=new("Frame",{Name=name.."Page",Size=UDim2.new(1,1,1,0),Visible=false,BackgroundTransparency=1},pages)
        btn.MouseButton1Click:Connect(function()
            if active then active.Visible=false end
            page.Visible=true;active=page
        end)
        if i==1 then btn:MouseButton1Click() end
        tabs[name]={Btn=btn,Page=page}
    end
    -- Example Toggle creation for Main tab
    local function MakeToggle(parent,y,text,flag)
        local cb = new("Frame",{Size=UDim2.new(1,-20,0,30),Position=UDim2.new(0,10,0,y),BackgroundTransparency=1},parent)
        local lbl=new("TextLabel",{Size=UDim2.new(0.7,0,1,0),BackgroundTransparency=1,Text=text,Font=Enum.Font.Gotham,TextColor3=Color3.new(1,1,1)},cb)
        local btn=new("ImageButton",{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-34,0,3),BackgroundTransparency=0.5,BackgroundColor3=Color3.fromRGB(45,45,45)},cb)
        new("UICorner",{CornerRadius=UDim.new(0,4)},btn)
        btn.Image = "rbxassetid://7033179166"
        local state=false
        btn.MouseButton1Click:Connect(function()
            state=not state; _G.Flags[flag]=state
            btn.Image = state and "rbxassetid://7033181995" or "rbxassetid://7033179166"
        end)
        return btn
    end
    -- Populate Main features
    local p = tabs.Main.Page
    local y=10
    for _,f in ipairs({"ESP","Wallbang","AutoFarm","AutoChest","AutoSeaEvents","AutoCrewDrop","AutoDragonDojo","AutoKitsune","AutoPrehistoric","AutoBossPrehistoric","AutoRaceV4"}) do
        MakeToggle(p,y,f,f)
        y=y+35
    end

    return UI
end

-- Build UI
local Library = UI:CreateWindow()
-- Load source logic

task.spawn(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua",true))() 
end
) 
end
)
