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

-- source.lua - G-Mon Hub Final Logic --

local Players = game:GetService("Players") local Replicated = game:GetService("ReplicatedStorage") local Workspace = game:GetService("Workspace")

local function getHRP() local char = Players.LocalPlayer.Character return char and char:FindFirstChild("HumanoidRootPart") end

-- Utility 
local function serverHop() -- Dummy server hop logic 
print("[GMON] Server hop...")
 end

local function redeemAllCodes() -- Dummy redeem logic print("[GMON] Redeeming all codes...") end

local function fastAttack() -- Dummy fast attack logic print("[GMON] Fast Attack enabled") end

local function autoFarm() -- Dummy farm logic print("[GMON] Farming mobs...") end

local function autoChest() -- Dummy chest farm logic print("[GMON] Farming chests...") end

local function autoCDK() -- Dummy CDK logic print("[GMON] Collecting CDK...") end

local function autoGolem() -- Dummy golem farm print("[GMON] Killing Golem...") end

local function autoLeviathan() print("[GMON] Attacking Leviathan...") end

local function autoEnchant() print("[GMON] Auto Enchanting...") end

local function autoAwaken() print("[GMON] Auto Awakening Fruit...") end

local function autoBoat() print("[GMON] Auto Sailing...") end

local function autoSeaEvent() print("[GMON] Auto Sea Events...") end

local function bountyFarm() print("[GMON] Bounty Hunting...") end

-- Main Loop spawn(function() while task.wait(0.5) do local hrp = getHRP()

-- Info
    if _G.Flags.TrackEliteSpawn then print("[GMON] Tracking Elite Spawn") end
    if _G.Flags.TrackFullMoon then print("[GMON] Tracking Full Moon") end
    if _G.Flags.TrackGodChalice then print("[GMON] Tracking God Chalice") end

    -- Main
    if _G.Flags.AutoFarm then autoFarm() end
    if _G.Flags.FarmAllBoss then print("[GMON] Farming All Boss") end
    if _G.Flags.MasteryFruit then print("[GMON] Mastering Fruit") end

    -- Item
    if _G.Flags.AutoCDK then autoCDK() end
    if _G.Flags.AutoYama then print("[GMON] Getting Yama") end
    if _G.Flags.AutoTushita then print("[GMON] Getting Tushita") end
    if _G.Flags.AutoSoulGuitar then print("[GMON] Getting Soul Guitar") end

    -- Sea Events
    if _G.Flags.KillSeaBeast then print("[GMON] Killing Sea Beast") end
    if _G.Flags.AutoSail then autoBoat() end

    -- Prehistoric
    if _G.Flags.KillGolem then autoGolem() end
    if _G.Flags.DefendVolcano then print("[GMON] Defending Volcano") end
    if _G.Flags.CollectDragonEgg then print("[GMON] Collecting Dragon Egg") end
    if _G.Flags.CollectBones then print("[GMON] Collecting Bones") end

    -- Kitsune
    if _G.Flags.CollectAzure then print("[GMON] Collecting Azure Ember") end
    if _G.Flags.TradeAzure then print("[GMON] Trading Azure") end

    -- Leviathan
    if _G.Flags.AttackLeviathan then autoLeviathan() end

    -- DevilFruit
    if _G.Flags.GachaFruit then print("[GMON] Gacha Fruit...") end
    if _G.Flags.FruitTarget ~= "" then print("[GMON] Targeting Fruit: " .. _G.Flags.FruitTarget) end

    -- ESP (stub)
    if _G.Flags.ESPFruit then print("[GMON] ESP: Fruit") end
    if _G.Flags.ESPPlayer then print("[GMON] ESP: Player") end
    if _G.Flags.ESPChest then print("[GMON] ESP: Chest") end
    if _G.Flags.ESPFlower then print("[GMON] ESP: Flower") end

    -- Misc
    if _G.Flags.ServerHop then serverHop() end
    if _G.Flags.RedeemCodes then redeemAllCodes() end

    -- Setting
    if _G.Flags.FastAttack then fastAttack() end
end

end)

print("[GMON] source.lua initialized")


