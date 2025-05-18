-- main.lua – GMON Hub UI Final
repeat task.wait() until game:IsLoaded()

-- Source utama
local success, sourceScript = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-Mon-Hub/main/source.lua")
end)
if success then
    loadstring(sourceScript)()
else
    warn("GMON Hub: Gagal memuat source.lua!")
end

-- Services
local Players     = game:GetService("Players")
local UserInput   = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")

-- Config Global
_G.Flags  = _G.Flags  or {}
_G.Config = _G.Config or { FarmInterval = 0.5 }

-- Helper: create instance with properties
local function New(class, props, parent)
    local inst = Instance.new(class)
    for k,v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

-- AddSwitch: toggle styled like a switch
local function AddSwitch(page, text, flag)
    local container = New("Frame", {
        Size = UDim2.new(1,0,0,30),
        BackgroundTransparency = 1,
        LayoutOrder = #page:GetChildren(),
    }, page)

    New("TextLabel", {
        Text = text,
        Size = UDim2.new(0.7,0,1,0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    local sw = New("Frame", {
        Size = UDim2.new(0,40,0,20),
        Position = UDim2.new(1,-50,0,5),
        BackgroundColor3 = Color3.new(1,1,1),
        Parent = container,
    })
    New("UICorner", { CornerRadius = UDim.new(0,10) }, sw)

    local knob = New("Frame", {
        Size = UDim2.new(0,18,0,18),
        Position = UDim2.new(0,1,0,1),
        BackgroundColor3 = Color3.new(0.2,0.2,0.2),
        Parent = sw,
    })
    New("UICorner", { CornerRadius = UDim.new(0,9) }, knob)

    -- init
    _G.Flags[flag] = _G.Flags[flag] or false
    local function update()
        if _G.Flags[flag] then
            sw.BackgroundColor3 = Color3.fromRGB(0,170,0)
            knob.Position = UDim2.new(1,-19,0,1)
        else
            sw.BackgroundColor3 = Color3.new(1,1,1)
            knob.Position = UDim2.new(0,1,0,1)
        end
    end
    update()

    -- click
    sw.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            _G.Flags[flag] = not _G.Flags[flag]
            update()
        end
    end)
end

-- AddToggle: simple on/off button
local function AddToggle(page, text, flag)
    local btn = New("TextButton", {
        Text = text,
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(60,60,60),
        TextColor3 = Color3.new(1,1,1),
        LayoutOrder = #page:GetChildren(),
    }, page)
    New("UICorner", {}, btn)

    _G.Flags[flag] = _G.Flags[flag] or false
    btn.MouseButton1Click:Connect(function()
        _G.Flags[flag] = not _G.Flags[flag]
        btn.BackgroundColor3 = _G.Flags[flag] and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
    end)
end

-- AddText: plain label
local function AddText(page, text)
    New("TextLabel", {
        Text = text,
        Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = #page:GetChildren(),
    }, page)
end

-- AddInput: textbox with callback
local function AddInput(page, placeholder, callback)
    local box = New("TextBox", {
        PlaceholderText = placeholder,
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        TextColor3 = Color3.new(1,1,1),
        LayoutOrder = #page:GetChildren(),
    }, page)
    New("UICorner", {}, box)

    box.FocusLost:Connect(function(enter)
        if enter and box.Text ~= "" then
            callback(box.Text)
        end
    end)
end

-- AddDropdown: simple dropdown menu
local function AddDropdown(page, title, list, callback)
    AddText(page, title)
    local dropdown = New("TextButton", {
        Text = list[1] or "Select",
        Size = UDim2.new(1,0,0,30),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        TextColor3 = Color3.new(1,1,1),
        LayoutOrder = #page:GetChildren(),
    }, page)
    New("UICorner", {}, dropdown)

    dropdown.MouseButton1Click:Connect(function()
        local menu = New("Frame", {
            Size = UDim2.new(0, dropdown.AbsoluteSize.X, 0, #list*25),
            Position = UDim2.new(0, dropdown.AbsolutePosition.X, 0, dropdown.AbsolutePosition.Y + dropdown.AbsoluteSize.Y),
            BackgroundColor3 = Color3.fromRGB(35,35,35),
            ZIndex = dropdown.ZIndex + 1,
        }, dropdown)
        New("UICorner", {}, menu)

        for i, item in ipairs(list) do
            local btn = New("TextButton", {
                Text = item,
                Size = UDim2.new(1,0,0,25),
                BackgroundTransparency = 1,
                TextColor3 = Color3.new(1,1,1),
                LayoutOrder = i,
                Parent = menu,
            })
            btn.Position = UDim2.new(0,0,0,(i-1)*25)
            btn.MouseButton1Click:Connect(function()
                dropdown.Text = item
                callback(item)
                menu:Destroy()
            end)
        end
    end)
end

-- Create main GUI
local gui = New("ScreenGui", {
    Name = "GMONHub_UI",
    ResetOnSpawn = false,
}, Players.LocalPlayer:WaitForChild("PlayerGui"))

-- Background animation
New("ImageLabel", {
    Image = "rbxassetid://16790218639",
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    ZIndex = 0,
}, gui)

-- Main frame + RGB stroke
local frame = New("Frame", {
    Size = UDim2.new(0,580,0,420),
    Position = UDim2.new(0.5,-290,0.5,-210),
    BackgroundColor3 = Color3.fromRGB(25,25,25),
    BackgroundTransparency = 0.2,
    Name = "MainFrame",
}, gui)
New("UICorner", { CornerRadius = UDim.new(0,12) }, frame)
local stroke = New("UIStroke", {
    Thickness = 3,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, frame)
task.spawn(function()
    local hue = 0
    while frame.Parent do
        hue = (hue + 0.005) % 1
        stroke.Color = Color3.fromHSV(hue,1,1)
        task.wait(0.03)
    end
end)

-- Toggle button
local toggleBtn = New("TextButton", {
    Text = "GMON",
    Size = UDim2.new(0,60,0,30),
    Position = UDim2.new(0,20,0.5,-15),
    BackgroundColor3 = Color3.fromRGB(40,40,40),
    TextColor3 = Color3.new(1,1,1),
    Active = true,
    Name = "ToggleBtn",
}, gui)
New("UICorner", {}, toggleBtn)
toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)
-- Keybind M
UserInput.InputBegan:Connect(function(inp, gp)
    if not gp and inp.KeyCode == Enum.KeyCode.M then
        frame.Visible = not frame.Visible
    end
end)

-- Tabs setup
local tabNames = {"Info","Main","Item","Sea","Prehistoric","Kitsune","Leviathan","DevilFruit","ESP","Misc","Setting"}
local tabs, pages = {}, {}
local tabScroll = New("ScrollingFrame", {
    Size = UDim2.new(1,0,0,30),
    Position = UDim2.new(0,0,0,0),
    BackgroundTransparency = 1,
    ScrollBarThickness = 4,
    ScrollingDirection = Enum.ScrollingDirection.X,
    CanvasSize = UDim2.new(0,#tabNames*105,0,30),
    Parent = frame,
})
New("UIListLayout", {
    Parent = tabScroll,
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0,5),
}, tabScroll)

for i,name in ipairs(tabNames) do
    local btn = New("TextButton", {
        Text = name,
        Size = UDim2.new(0,100,0,30),
        BackgroundTransparency = 0.5,
        BackgroundColor3 = Color3.fromRGB(40,40,40),
        TextColor3 = Color3.new(1,1,1),
        Parent = tabScroll,
    })
    New("UICorner", {}, btn)

    local page = New("ScrollingFrame", {
        Size = UDim2.new(1,-20,1,-50),
        Position = UDim2.new(0,10,0,40),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 4,
        Parent = frame,
    })
    New("UIListLayout", {
        Parent = page,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,5),
    }, page)

    btn.MouseButton1Click:Connect(function()
        for _,p in ipairs(pages) do p.Visible = false end
        page.Visible = true
    end)

    table.insert(tabs, btn)
    table.insert(pages, page)
    if i == 1 then
        page.Visible = true
    end
end

-- Populate Info tab
AddText(pages[1], "Toggle GUI: Press M or click GMON")
-- … you can add dynamic labels here like moonLabel, mirageLabel, etc.

-- Example switches & toggles
AddSwitch(pages[2], "Auto Farm", "AutoFarm")
AddSwitch(pages[2], "Farm Boss Selected", "FarmBossSelected")
AddSwitch(pages[2], "Farm All Boss", "FarmAllBoss")
AddSwitch(pages[2], "Mastery Fruit", "MasteryFruit")
AddSwitch(pages[2], "Aimbot", "Aimbot")

AddToggle(pages[3],"Auto CDK","AutoCDK")
AddToggle(pages[3],"Auto Yama","AutoYama")
AddToggle(pages[3],"Auto Tushita","AutoTushita")
AddToggle(pages[3],"Auto Soul Guitar","AutoSoulGuitar")

-- … lanjutkan sesuai kebutuhan…

print("GMON Hub UI Loaded")