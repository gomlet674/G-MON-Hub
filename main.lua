-- main.lua – GMON Hub UI Final

repeat task.wait() until game:IsLoaded()

-- SERVICES 
local HttpService   = game:GetService("HttpService") 
local Players       = game:GetService("Players")
 local UserInput     = game:GetService("UserInputService") 
local TweenService  = game:GetService("TweenService")

-- GLOBAL CONFIG 
_G.Flags  = _G.Flags  or {} _G.Config = _G.Config or { FarmInterval = 0.5 }

-- TRY LOAD REMOTE SOURCE (NON-FATAL) 
local function tryLoadRemote()
 if not HttpService.HttpEnabled then pcall(function() HttpService.HttpEnabled = true end) end local ok, result = pcall(function() return HttpService:GetAsync("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua") end) if ok and type(result)=="string" and #result>50 then local fn, err = loadstring(result) if fn then pcall(fn) end end end tryLoadRemote()

-- HELPER: Instance.new + properti
 local function New(cls, props, parent) local inst = Instance.new(cls) for k,v in pairs(props) do inst[k] = v end if parent then inst.Parent = parent end return inst end

-- DRAGGABLE MAKER
 global function makeDraggable(guiObject) 
local dragging, startPos, startInput guiObject.InputBegan:Connect(function(input) 
if input.UserInputType == 
Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true startPos   = guiObject.Position startInput = input.Position input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end) UserInput.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - startInput guiObject.Position = UDim2.new( startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y ) end end) end

-- SWITCH CONTROL
 local function AddSwitch(page, text, flag) local ctr = New("Frame", { Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, LayoutOrder=#page:GetChildren() }, page) New("TextLabel", { Text=text, Size=UDim2.new(0.7,0,1,0), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), TextXAlignment=Enum.TextXAlignment.Left }, ctr) local sw = New("TextButton", { Size=UDim2.new(0,40,0,20), Position=UDim2.new(1,-50,0,5), BackgroundColor3=Color3.new(1,1,1), AutoButtonColor=false }, ctr) New("UICorner", { CornerRadius=UDim.new(0,10) }, sw) local knob = New("Frame", { Size=UDim2.new(0,18,0,18), Position=UDim2.new(0,1,0,1), BackgroundColor3=Color3.fromRGB(50,50,50) }, sw) New("UICorner", { CornerRadius=UDim.new(0,9) }, knob)

_G.Flags[flag] = _G.Flags[flag] or false
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
local function update()
    local goal = {}
    if _G.Flags[flag] then
        sw.BackgroundColor3 = Color3.fromRGB(0,170,0)
        goal.Position = UDim2.new(1,-19,0,1)
    else
        sw.BackgroundColor3 = Color3.new(1,1,1)
        goal.Position = UDim2.new(0,1,0,1)
    end
    TweenService:Create(knob, tweenInfo, goal):Play()
end
sw.Activated:Connect(function()
    _G.Flags[flag] = not _G.Flags[flag]
    update()
end)
update()

end

-- ... Tambahkan AddDropdown, AddToggle, AddText sesuai file sebelumnya ...

-- BUILD GUI -- [Sisipkan kode pembuatan gui, frame, toggle, tabs] ...

-- MAIN.LOGIC: INFO & AUTO FARM -- Info Logic: update moon phase dll di loop setiap 10 detik 
spawn(function() while task.wait(10) do -- contoh moon_phase local m = os.date("*t").min % 8 local phases = {[0]="🌑 0/4",[1]="🌒 -1/4",[2]="🌓 -2/4",[3]="🌔 -3/4", [4]="🌕 4/4",[5]="🌖 3/4",[6]="🌗 2/4",[7]="🌘 1/4"} _G.Flags.MoonPhase = phases[m]
 -- Kitsune, Prehistoric, Mirage: cek workspace 
_G.Flags.Kitsune = workspace:FindFirstChild("KitsuneIsland")=nil _G.Flags.Mirage = workspace:FindFirstChild("MirageIsland")~=nil end end)

-- Main logic: Auto Farm & Chest 
spawn(function() while task.wait(_G.Config.FarmInterval) do 
if _G.Flags.AutoFarm then local plr = Players.LocalPlayer local sea = plr:FindFirstChild("SeaLevel") and plr.SeaLevel.Value or 1 
-- ambil quest list sesuai sea
 for lvl=1,2650 do 
-- lakukan pengambilan quest sesuai sea dan lvl -- contoh: 
game.ReplicatedStorage.Remotes.Quest:InvokeServer(sea, lvl) end end if _G.Flags.FarmChest then -- cari chest di workspace sesuai sea 
for _, chest in ipairs(workspace:GetDescendants()) do if chest.Name == "Chest" and chest:FindFirstChild("Sea") then -- misal chest.Sea.Value == plr.SeaLevel -- game.ReplicatedStorage.Remotes.OpenChest:InvokeServer(chest) end end end end end)

print("GMON Hub UI Loaded and Logic Active")

-- source.lua (Placeholder untuk logic kickstart) -- Sumber utama telah di-load via tryLoadRemote()

