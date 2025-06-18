-- GMON Hub UI - Auto Hatch Anti Bee Egg

repeat task.wait() until game:IsLoaded()

local HttpService  = game:GetService("HttpService")
local Players      = game:GetService("Players")
local UserInput    = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

_G.Flags = _G.Flags or {}

local function New(cls, props, parent)
    local inst = Instance.new(cls)
    for k,v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- Draggable frame
local function makeDraggable(gui)
    local dragging, startPos, startInput
    gui.Active = true
    gui.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = gui.Position
            startInput = inp.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInput.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - startInput
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                     startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- GUI
local gui = New("ScreenGui", {
    Name = "GMONHub_UI", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, Players.LocalPlayer:WaitForChild("PlayerGui"))

local frame = New("Frame", {
    Size = UDim2.new(0,600,0,450),
    Position = UDim2.new(0.5,-300,0.5,-225),
    BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.5,
    Visible = false,
}, gui)
New("UICorner", { CornerRadius = UDim.new(0,12) }, frame)
makeDraggable(frame)

New("ImageLabel", {
    Image = "rbxassetid://16790218639",
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    ZIndex = 0,
}, frame)

local stroke = New("UIStroke", {
    Parent = frame, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
task.spawn(function()
    local hue = 0
    while frame.Parent do
        hue = (hue + 0.005) % 1
        stroke.Color = Color3.fromHSV(hue,1,1)
        task.wait(0.03)
    end
end)

-- TOGGLE BUTTON
local toggle = New("TextButton", {
    Text = "GMON", Size = UDim2.new(0,70,0,35),
    Position = UDim2.new(0,20,0,20),
    BackgroundColor3 = Color3.fromRGB(40,40,40), TextColor3 = Color3.new(1,1,1),
    ZIndex = 2,
}, gui)
New("UICorner", { CornerRadius = UDim.new(0,8) }, toggle)
makeDraggable(toggle)
toggle.Activated:Connect(function() frame.Visible = not frame.Visible end)
UserInput.InputBegan:Connect(function(inp, gp)
    if not gp and inp.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- TAB (Auto Hatch Only)
local tabScroll = New("ScrollingFrame", {
    Size = UDim2.new(1,0,0,40), Position = UDim2.new(0,0,0,0),
    BackgroundTransparency = 1, ScrollingDirection = Enum.ScrollingDirection.X,
    ScrollBarThickness = 0, CanvasSize = UDim2.new(0,120,0,40),
    Parent = frame,
})
New("UIListLayout", {
    Parent = tabScroll,
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0,5),
}, tabScroll)

local btn = New("TextButton", {
    Text = "Auto Hatch", Size = UDim2.new(0,120,1,0),
    BackgroundColor3 = Color3.fromRGB(30,30,30), TextColor3 = Color3.new(1,1,1),
    Parent = tabScroll,
})
New("UICorner", { CornerRadius = UDim.new(0,6) }, btn)

local page = New("ScrollingFrame", {
    Name = "HatchPage",
    Size = UDim2.new(1,0,1,-40), Position = UDim2.new(0,0,0,40),
    BackgroundTransparency = 1, ScrollBarThickness = 6,
    CanvasSize = UDim2.new(0,0,0,1000), Visible = true,
    Parent = frame,
})
New("UIListLayout", {
    Parent = page,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0,6),
})

btn.Activated:Connect(function()
    page.Visible = true
end)

-- TOGGLE FUNCTION
local function AddToggle(page, text, flag)
    local btn = New("TextButton", {
        Text = text, Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = Color3.new(1,1,1),
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

-- Add Toggle: Auto Hatch Anti Bee Egg
AddToggle(page, "Auto Hatch if selected pet (Anti Bee Egg)", "auto_hatch_antibee")
