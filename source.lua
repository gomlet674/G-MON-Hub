-->> FILE: source.lua (FINAL FUNCTIONALITY)

return function(env) local UI = env.UI local Player = env.Player local Mouse = env.Mouse

-- Tab System
local Tabs = {
    "Info", "Main", "Item", "Prehistoric", "Kitsune", "Mirage", "Leviathan", "Misc", "Setting"
}

local SelectedTab = nil
local TabButtons = {}

local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(0, 150, 1, 0)
TabHolder.Position = UDim2.new(0, 0, 0, 0)
TabHolder.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TabHolder.Parent = UI
Instance.new("UICorner", TabHolder).CornerRadius = UDim.new(0, 6)

local ContentHolder = Instance.new("Frame")
ContentHolder.Size = UDim2.new(1, -150, 1, 0)
ContentHolder.Position = UDim2.new(0, 150, 0, 0)
ContentHolder.BackgroundTransparency = 1
ContentHolder.Parent = UI

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, (#TabButtons) * 35 + 10)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = TabHolder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, 0, 1, -10)
    content.Position = UDim2.new(0, 0, 0, 5)
    content.CanvasSize = UDim2.new(0, 0, 0, 500)
    content.ScrollBarThickness = 4
    content.Visible = false
    content.Parent = ContentHolder

    TabButtons[#TabButtons+1] = {Button = btn, Content = content}

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(TabButtons) do
            t.Content.Visible = false
        end
        content.Visible = true
        SelectedTab = name
    end)

    return content
end

-- Create Tabs
local TabFrames = {}
for _, tab in ipairs(Tabs) do
    TabFrames[tab] = CreateTab(tab)
end
TabButtons[1].Button:Invoke()

-- Feature Functionality
local function AddToggle(parent, text, callback)
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 200, 0, 30)
    toggle.Text = "[ OFF ] " .. text
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Parent = parent

    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.Text = (state and "[ ON  ] " or "[ OFF ] ") .. text
        pcall(function()
            callback(state)
        end)
    end)
end

-- EXAMPLE IMPLEMENTATION
AddToggle(TabFrames["Main"], "Auto Farm", function(bool)
    _G.AutoFarm = bool
    while _G.AutoFarm and wait(0.5) do
        -- Farming logic here
    end
end)

AddToggle(TabFrames["Main"], "Auto Chest", function(bool)
    _G.AutoChest = bool
    while _G.AutoChest and wait(1) do
        -- Chest collecting logic here
    end
end)

AddToggle(TabFrames["Item"], "Auto CDK", function(bool)
    _G.AutoCDK = bool
    while _G.AutoCDK and wait(1) do
        -- CDK farming logic
    end
end)

AddToggle(TabFrames["Prehistoric"], "Auto Boss", function(bool)
    _G.AutoPreBoss = bool
    while _G.AutoPreBoss and wait(1) do
        -- Auto boss kill logic
    end
end)

AddToggle(TabFrames["Leviathan"], "Auto Kill Leviathan", function(bool)
    _G.AutoLeviathan = bool
    while _G.AutoLeviathan and wait(2) do
        -- Auto Leviathan logic
    end
end)

AddToggle(TabFrames["Setting"], "Fast Attack", function(bool)
    _G.FastAttack = bool
    -- Configure Fast Attack System
end)

-- More toggles can be added per tab...

end

