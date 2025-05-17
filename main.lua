-- main.lua (G-Mon Hub) repeat task.wait() until game:IsLoaded()

-- Services local Players = game:GetService("Players") local UserInput = game:GetService("UserInputService")

-- Global flags _G.Flags = _G.Flags or {} _G.Config = _G.Config or {FarmInterval = 0.5, BoatSpeed = 100}

-- UI Library local UI = {} UI.__index = UI UI.ToggleKey = Enum.KeyCode.M UI.MainFrame = nil UI.Visible = true

-- Helper to create instances def local function new(class, props, parent) local inst = Instance.new(class) for k, v in pairs(props or {}) do inst[k] = v end if parent then inst.Parent = parent end return inst end

-- Toggle UI UserInput.InputBegan:Connect(function(input, g) if not g and input.KeyCode == UI.ToggleKey and UI.MainFrame then UI.Visible = not UI.Visible UI.MainFrame.Visible = UI.Visible end end)

-- Create main window function UI:CreateWindow() local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") local screenGui = new("ScreenGui", {Name = "GMonHub_UI", ResetOnSpawn = false}, playerGui)

-- Background image
new("ImageLabel", {
    Size = UDim2.new(1,0,1,0),
    Position = UDim2.new(0,0,0,0),
    BackgroundTransparency = 1,
    Image = "rbxassetid://16790218639",
    ScaleType = Enum.ScaleType.Crop
}, screenGui)

-- RGB Border overlay
local overlay = new("Frame", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1}, screenGui)
local stroke = new("UIStroke", {Parent = overlay, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
task.spawn(function()
    local t = 0
    while true do
        t = (t + 0.01) % 1
        stroke.Color = Color3.fromHSV(t, 1, 1)
        task.wait(0.03)
    end
end)

-- Main frame
local main = new("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 480, 0, 360),
    Position = UDim2.new(0.5, -240, 0.5, -180),
    BackgroundColor3 = Color3.fromRGB(25,25,25),
    BackgroundTransparency = 0.5
}, screenGui)
new("UICorner", {CornerRadius = UDim.new(0,12)}, main)
UI.MainFrame = main

-- Tabs
local tabList = new("Frame", {
    Size = UDim2.new(0,120,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1
}, main)
local pageContainer = new("Frame", {
    Size = UDim2.new(1,-120,1,0), Position = UDim2.new(0,120,0,0), BackgroundTransparency = 1
}, main)

local tabs = {}
local activePage
local names = {"Main","Stat","TP","Players","DFruit","Misc","Settings"}
for i, name in ipairs(names) do
    local btn = new("TextButton", {
        Name = name.."Tab",
        Size = UDim2.new(1,0,0,30),
        Position = UDim2.new(0,0,0,(i-1)*30),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.Gotham,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left
    }, tabList)
    local page = new("Frame", {
        Name = name.."Page",
        Size = UDim2.new(1,1,1,0),
        Visible = false,
        BackgroundTransparency = 1
    }, pageContainer)

    btn.MouseButton1Click:Connect(function()
        if activePage then activePage.Visible = false end
        page.Visible = true
        activePage = page
    end)
    if i == 1 then btn:MouseButton1Click() end
    tabs[name] = {Btn = btn, Page = page}
end

-- Toggle helper
local function makeToggle(parent, y, label, flag)
    local frame = new("Frame", {
        Size = UDim2.new(1,-20,0,30), Position = UDim2.new(0,10,0,y), BackgroundTransparency = 1
    }, parent)
    new("TextLabel", {
        Size = UDim2.new(0.7,0,1,0), BackgroundTransparency = 1,
        Text = label, Font = Enum.Font.Gotham, TextColor3 = Color3.new(1,1,1)
    }, frame)
    local btn = new("ImageButton", {
        Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-34,0,3),
        BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(45,45,45),
        Image = "rbxassetid://7033179166"
    }, frame)
    new("UICorner", {CornerRadius = UDim.new(0,4)}, btn)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        _G.Flags[flag] = state
        btn.Image = state and "rbxassetid://7033181995" or "rbxassetid://7033179166"
    end)
end

-- Populate Main toggles
local p = tabs.Main.Page
local y = 10
for _, f in ipairs({"ESP","Wallbang","AutoFarm","AutoChest","AutoSeaEvents","AutoCrewDrop","AutoDragonDojo","AutoKitsune","AutoPrehistoric","AutoBossPrehistoric","AutoRaceV4"}) do
    makeToggle(p, y, f, f)
    y = y + 35
end

return UI

end

-- Build and show UI local lib = UI:CreateWindow()

-- Load source logic task.spawn(function() loadstring(game:HttpGet( "https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua", true ))() end)

