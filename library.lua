-- library.lua
-- G-Mon Hub UI Library (IsnaHamzah + Redz style)
-- Usage: local UI = loadstring(game:HttpGet(URL))()

local UI = {}
UI.__index = UI

-- Services
local TweenService   = game:GetService("TweenService")
local UserInput      = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local CoreGui        = game:GetService("CoreGui")

-- Default settings
UI.ToggleKey        = Enum.KeyCode.M
UI.MainFrame        = nil
UI.WindowVisible    = true

-- utility: create instances
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k] = v end
    inst.Parent = parent or props.Parent
    return inst
end

-- Toggle main UI visibility
UserInput.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == UI.ToggleKey and UI.MainFrame then
        UI.WindowVisible = not UI.WindowVisible
        UI.MainFrame.Visible = UI.WindowVisible
    end
end)

-- Create the main window and container for tabs
function UI:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "Hub"
    local rounded = opts.Rounded and 8 or 0
    local drag = opts.Drag

    -- ScreenGui
    local SGui = new("ScreenGui", {Name="GMonHub_UI"}, CoreGui)
    SGui.ResetOnSpawn = false

    -- Main Frame
    local Main = new("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 450, 0, 350),
        Position = UDim2.new(0.5, -225, 0.5, -175),
        BackgroundColor3 = Color3.fromRGB(25,25,25),
        BorderSizePixel = 0
    }, SGui)
    new("UICorner", {CornerRadius = UDim.new(0, rounded)}, Main)

    UI.MainFrame = Main

    -- Top bar
    local Top = new("Frame", {
        Size = UDim2.new(1,0,0,40),
        BackgroundTransparency = 1,
        Parent = Main
    })
    new("TextLabel", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = title, Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(255,255,255)
    }, Top)

    -- Tabs container
    local TabList = new("Frame", {
        Name = "TabList",
        Size = UDim2.new(0,120,1,-40),
        Position = UDim2.new(0,0,0,40),
        BackgroundTransparency = 1
    }, Main)
    local PageContainer = new("Frame", {
        Name = "PageContainer",
        Size = UDim2.new(1,-120,1,-40),
        Position = UDim2.new(0,120,0,40),
        BackgroundTransparency = 1
    }, Main)

    -- Dragging
    if drag then
        local dragging, start, pos
        Top.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=true
                start=i.Position
                pos=Main.Position
            end
        end)
        Top.InputChanged:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseMovement then
                UserInput.InputChanged:Connect(function(inp)
                    if inp==i and dragging then
                        local delta=inp.Position-start
                        Main.Position=UDim2.new(pos.X.Scale, pos.X.Offset+delta.X, pos.Y.Scale, pos.Y.Offset+delta.Y)
                    end
                end)
            end
        end)
        UserInput.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)
    end

    -- Internal state
    local tabs = {}
    local activePage

    -- Create a new tab
    function WindowMethods:CreateTab(name)
        local Button = new("TextButton", {
            Name = name.."Tab",
            Size = UDim2.new(1,0,0,30),
            BackgroundTransparency = 1,
            Text = "  "..name,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(200,200,200),
            LayoutOrder = #tabs+1
        }, TabList)

        local Page = new("ScrollingFrame", {
            Name = name.."Page",
            Size = UDim2.new(1,0,1,0),
            CanvasSize = UDim2.new(0,0,2,0),
            ScrollBarThickness = 6,
            BackgroundTransparency = 1,
            Visible = false
        }, PageContainer)
        local UIList = new("UIListLayout", {Padding = UDim.new(0,5)}, Page)

        local function select()
            if activePage then activePage.Visible=false end
            Page.Visible=true
            activePage=Page
            -- highlight button
            for _,btn in pairs(TabList:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.TextColor3 = (btn==Button) and Color3.new(1,1,1) or Color3.fromRGB(200,200,200)
                end
            end
        end
        Button.MouseButton1Click:Connect(select)

        -- select first tab by default
        if #tabs==0 then select() end
        tabs[#tabs+1] = {Button=Button, Page=Page}

        -- Tab API
        local TabAPI = {}

        function TabAPI:Button(opts)
            opts = opts or {}
            local btn = new("TextButton", {
                Size = UDim2.new(1,-10,0,30),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                Text = opts.Text or "Button",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.new(1,1,1)
            }, Page)
            new("UICorner", {CornerRadius=UDim.new(0,4)}, btn)
            btn.MouseButton1Click:Connect(function() pcall(opts.Callback) end)
        end

        function TabAPI:Toggle(opts)
            opts = opts or {}
            local container = new("Frame", {
                Size = UDim2.new(1,-10,0,30),
                BackgroundTransparency = 1
            }, Page)
            local lbl = new("TextLabel", {
                Size = UDim2.new(0.8,0,1,0),
                BackgroundTransparency=1,
                Text = opts.Text or "Toggle",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.new(1,1,1)
            }, container)
            local tk = Instance.new("ImageButton", container)
            tk.Size = UDim2.new(0,24,0,24)
            tk.Position = UDim2.new(1,-28,0,3)
            tk.BackgroundTransparency = 1
            tk.Image = "rbxassetid://7033179166" -- off icon
            local state = false
            tk.MouseButton1Click:Connect(function()
                state = not state
                tk.Image = state and "rbxassetid://7033181995" or "rbxassetid://7033179166"
                pcall(opts.Callback, state)
            end)
        end

        function TabAPI:Slider(opts)
            opts = opts or {}
            local frame = new("Frame", {
                Size = UDim2.new(1,-10,0,30),
                BackgroundTransparency = 1
            }, Page)
            local lbl = new("TextLabel", {
                Size = UDim2.new(0.4,0,1,0),
                BackgroundTransparency=1,
                Text = opts.Text or "Slider",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.new(1,1,1)
            }, frame)
            local sliderBg = new("Frame", {
                Size = UDim2.new(0.5,0,0,8),
                Position = UDim2.new(0.45,0,0.5,-4),
                BackgroundColor3 = Color3.fromRGB(60,60,60)
            }, frame)
            new("UICorner", {CornerRadius=UDim.new(0,4)}, sliderBg)
            local fill = new("Frame", {Size=UDim2.new(0,0,1,0), BackgroundColor3=Color3.fromRGB(0,170,127)}, sliderBg)
            new("UICorner", {CornerRadius=UDim.new(0,4)}, fill)

            local dragging
            local min, max = opts.min or 0, opts.max or 1
            local function update(input)
                local x = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X, 0,1)
                fill.Size = UDim2.new(x,0,1,0)
                local val = min + (max-min)*x
                pcall(opts.Callback, math.floor((val)*(10^(opts.precision or 2)))/(10^(opts.precision or 2)))
            end
            sliderBg.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=true; update(i)
                end
            end)
            sliderBg.InputChanged:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseMovement then
                    UserInput.InputChanged:Connect(function(inp)
                        if inp==i and dragging then update(inp) end
                    end)
                end
            end)
            UserInput.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
            end)
        end

        function TabAPI:Dropdown(opts)
            opts = opts or {}
            local frame = new("Frame", {
                Size = UDim2.new(1,-10,0,30),
                BackgroundTransparency = 1
            }, Page)
            local lbl = new("TextLabel", {
                Size = UDim2.new(0.4,0,1,0),
                BackgroundTransparency=1,
                Text = opts.Text or "Dropdown",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.new(1,1,1)
            }, frame)
            local btn = new("TextButton", {
                Size = UDim2.new(0.55,0,1,0),
                Position = UDim2.new(0.45,0,0,0),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                Text = opts.List[1] or "",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.new(1,1,1)
            }, frame)
            new("UICorner", {CornerRadius=UDim.new(0,4)}, btn)

            local open = false
            local menu = new("Frame", {
                Size = UDim2.new(0,btn.AbsoluteSize.X,0,0),
                Position = UDim2.new(0.45,0,1,2),
                BackgroundColor3 = Color3.fromRGB(45,45,45),
                Visible = false,
                ClipsDescendants = true
            }, frame)
            new("UICorner", {CornerRadius=UDim.new(0,4)}, menu)
            local layout = new("UIListLayout", {Padding=UDim.new(0,2)}, menu)

            btn.MouseButton1Click:Connect(function()
                open = not open
                menu.Visible = open
                menu:TweenSize(UDim2.new(0,btn.AbsoluteSize.X,0, open and (#opts.List*25) or 0), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.2)
            end)
            for _,v in ipairs(opts.List or {}) do
                local it = new("TextButton", {
                    Size = UDim2.new(1,0,0,25),
                    BackgroundTransparency = 1,
                    Text = v,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Color3.new(1,1,1)
                }, menu)
                it.MouseButton1Click:Connect(function()
                    btn.Text = v
                    pcall(opts.Callback, v)
                    open = false
                    menu:TweenSize(UDim2.new(0,menu.AbsoluteSize.X,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.2)
                end)
            end
        end

        function TabAPI:Label(opts)
            new("TextLabel", {
                Size = UDim2.new(1,-10,0,20),
                BackgroundTransparency = 1,
                Text = opts.Text or "",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(170,170,170)
            }, Page)
        end

        function TabAPI:TextBox(opts)
            local tb = new("TextBox", {
                Size = UDim2.new(1,-10,0,30),
                BackgroundColor3 = Color3.fromRGB(40,40,40),
                Text = "",
                PlaceholderText = opts.Placeholder or "",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.new(1,1,1)
            }, Page)
            new("UICorner", {CornerRadius=UDim.new(0,4)}, tb)
            tb.FocusLost:Connect(function(enter)
                if enter and opts.Callback then pcall(opts.Callback, tb.Text) end
            end)
        end

        function TabAPI:Bullet(opts)
            local lbl = new("TextLabel", {
                Size = UDim2.new(1,-10,0,20),
                BackgroundTransparency = 1,
                Text = "• "..(opts.Text or ""),
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(200,200,200)
            }, Page)
        end

        return TabAPI
    end

    -- expose Window methods
    local WindowMethods = {}
    setmetatable(WindowMethods, UI)
    return WindowMethods
end

-- Initialize (no-op, kept for API consistency)
function UI:Init() end

return UI