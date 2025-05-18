-- main.lua – GMON Hub UI Final (Fallback Tangguh)
repeat task.wait() until game:IsLoaded()

-- SERVICES
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local UserInput   = game:GetService("UserInputService")

-- GLOBAL CONFIG
_G.Flags  = _G.Flags  or {}
_G.Config = _G.Config or { FarmInterval = 0.5 }

-- FUNSI MEMUAT SOURCE
local function tryLoadRemote()
    if not HttpService.HttpEnabled then
        -- Di Studio, aktifkan dulu jika perlu
        pcall(function() HttpService.HttpEnabled = true end)
    end
    local ok, result = pcall(function()
        return HttpService:GetAsync("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua")
    end)
    if ok and type(result) == "string" and #result > 50 then
        local f, err = loadstring(result)
        if f then
            pcall(f)
            return true
        else
            warn("GMON: loadstring gagal—", err)
        end
    else
        warn("GMON: Gagal HttpGet atau result invalid:", result)
    end
    return false
end

-- Coba muat remote, tapi jangan fatal error
local loadedRemote = tryLoadRemote()
if not loadedRemote then
    warn("GMON: Source remote tidak dimuat, lanjut UI saja.")
end

-- HELPER: Buat Instance
local function New(class, props, parent)
    local inst = Instance.new(class)
    for k,v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- AddSwitch, AddToggle, AddText, AddInput (seperti sebelumnya)...
local function AddSwitch(page, text, flag)
    local ctr = New("Frame", { Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, LayoutOrder=#page:GetChildren() }, page)
    New("TextLabel", { Text=text, Size=UDim2.new(0.7,0,1,0), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), TextXAlignment=Enum.TextXAlignment.Left, Parent=ctr })
    local sw = New("Frame", { Size=UDim2.new(0,40,0,20), Position=UDim2.new(1,-50,0,5), BackgroundColor3=Color3.new(1,1,1), Parent=ctr })
    New("UICorner",{ CornerRadius=UDim.new(0,10) }, sw)
    local knob = New("Frame",{ Size=UDim2.new(0,18,0,18), Position=UDim2.new(0,1,0,1), BackgroundColor3=Color3.new(0.2,0.2,0.2), Parent=sw })
    New("UICorner",{ CornerRadius=UDim.new(0,9) }, knob)
    _G.Flags[flag] = _G.Flags[flag] or false
    local function update()
        if _G.Flags[flag] then sw.BackgroundColor3 = Color3.fromRGB(0,170,0); knob.Position = UDim2.new(1,-19,0,1)
        else sw.BackgroundColor3 = Color3.new(1,1,1); knob.Position = UDim2.new(0,1,0,1) end
    end
    update()
    sw.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _G.Flags[flag]=not _G.Flags[flag]; update() end end)
end

local function AddToggle(page, text, flag)
    local btn = New("TextButton",{ Text=text, Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(60,60,60), TextColor3=Color3.new(1,1,1), LayoutOrder=#page:GetChildren() }, page)
    New("UICorner",{},btn)
    _G.Flags[flag] = _G.Flags[flag] or false
    btn.MouseButton1Click:Connect(function() _G.Flags[flag]=not _G.Flags[flag]; btn.BackgroundColor3 = _G.Flags[flag] and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60) end)
end

local function AddText(page, txt)
    New("TextLabel",{ Text=txt, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=#page:GetChildren() }, page)
end

local function AddInput(page, placeholder, callback)
    local box = New("TextBox",{ PlaceholderText=placeholder, Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(50,50,50), TextColor3=Color3.new(1,1,1), LayoutOrder=#page:GetChildren() }, page)
    New("UICorner",{},box)
    box.FocusLost:Connect(function(enter) if enter and box.Text~="" then callback(box.Text) end end)
end

-- BUILD GUI
local gui = New("ScreenGui",{ Name="GMONHub_UI", ResetOnSpawn=false }, Players.LocalPlayer:WaitForChild("PlayerGui"))
New("ImageLabel",{ Image="rbxassetid://16790218639", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ZIndex=0 }, gui)

-- Main Frame + Dragging
local frame = New("Frame",{ Size=UDim2.new(0,580,0,420), Position=UDim2.new(0.5,-290,0.5,-210), BackgroundColor3=Color3.new(25,25,25), BackgroundTransparency=0.2 }, gui)
New("UICorner",{ CornerRadius=UDim.new(0,12) }, frame)
do
    local dragging, startPos, startInput
    frame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; startPos=frame.Position; startInput=i.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
    UserInput.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local delta=i.Position - startInput; frame.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y) end end)
end

-- RGB Stroke
local stroke=New("UIStroke",{ Thickness=3, ApplyStrokeMode=Enum.ApplyStrokeMode.Border },frame)
spawn(function() local hue=0 while frame.Parent do hue=(hue+0.005)%1; stroke.Color=Color3.fromHSV(hue,1,1); wait(0.03) end end)

-- Toggle Button & Keybind
local toggle=New("TextButton",{ Text="GMON", Size=UDim2.new(0,60,0,30), Position=UDim2.new(0,20,0.5,-15), BackgroundColor3=Color3.new(40,40,40), TextColor3=Color3.new(1,1,1) },gui)
New("UICorner",{},toggle)
toggle.MouseButton1Click:Connect(function() frame.Visible=not frame.Visible end)
UserInput.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.M then frame.Visible=not frame.Visible end end)

-- Tabs (horizontal) & Pages (vertical)
local tabNames={"Info","Main","Item","Sea"}
local pages={}
local tabScroll=New("ScrollingFrame",{ Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, ScrollingDirection=Enum.ScrollingDirection.X, ScrollBarThickness=4, CanvasSize=UDim2.new(0,#tabNames*105,0,30), Parent=frame})
New("UIListLayout",{ Parent=tabScroll, FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5) },tabScroll)
for i,name in ipairs(tabNames) do
    local btn=New("TextButton",{ Text=name, Size=UDim2.new(0,100,0,30), BackgroundTransparency=0.5, BackgroundColor3=Color3.new(40,40,40), TextColor3=Color3.new(1,1,1), Parent=tabScroll })
    New("UICorner",{},btn)
    local page=New("ScrollingFrame",{ Size=UDim2.new(1,-20,1,-50), Position=UDim2.new(0,10,0,40), BackgroundTransparency=1, Visible=false, ScrollBarThickness=4, Parent=frame })
    New("UIListLayout",{ Parent=page, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5) },page)
    btn.MouseButton1Click:Connect(function() for _,p in ipairs(pages) do p.Visible=false end page.Visible=true end)
    pages[i]=page
    if i==1 then page.Visible=true end
end

-- EXAMPLE CONTROLS
AddText(pages[1],"Toggle GUI: Press M or click GMON")
AddSwitch(pages[2],"Auto Farm","AutoFarm")
AddSwitch(pages[2],"Farm All Boss","FarmAllBoss")
AddToggle(pages[3],"Auto CDK","AutoCDK")

print("GMON Hub UI Loaded")