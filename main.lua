repeat wait() until game:IsLoaded()

-- Pastikan UserInputService terpasang
local uis = game:GetService("UserInputService")
local plr = game.Players.LocalPlayer

-- Memuat library UI
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

-- Membuat window untuk UI
local win = library:CreateWindow("GMON HUB", "Mukuro Styled UI", Color3.fromRGB(255,0,0), "rbxassetid://88817335071002")

-- Membuat tab pertama (Main Tab)
local Main = win:CreateTab("Main")
Main:CreateDropdown("Select Weapon", _G.WeaponList or {"Refresh Weapon"}, function(val) _G.Weapon = val end)
Main:CreateButton("Refresh Weapon", function() RefreshWeaponList() end)
Main:CreateToggle("Auto Farm", nil, function(v) _G.AutoFarm = v end)

-- Tambahkan tab lain jika diperlukan seperti Stats, Teleport, dll.

-- Main Tab
local Main = win:CreateTab("Main")
Main:CreateDropdown("Select Weapon", _G.WeaponList or {"Refresh Weapon"}, function(val) _G.Weapon = val end)
Main:CreateButton("Refresh Weapon", function() RefreshWeaponList() end)
Main:CreateToggle("Auto Farm", nil, function(v) _G.AutoFarm = v end)
Main:CreateToggle("Auto Next Sea", nil, function(v) _G.AutoNextSea = v end)
Main:CreateToggle("Auto Equip Accessory", nil, function(v) _G.AutoEquipAccessory = v end)

-- Stats Tab
local Stats = win:CreateTab("Stats")
Stats:CreateToggle("Auto Melee", nil, function(v) _G.AutoMelee = v end)
Stats:CreateToggle("Auto Defense", nil, function(v) _G.AutoDefense = v end)
Stats:CreateToggle("Auto Sword", nil, function(v) _G.AutoSword = v end)
Stats:CreateToggle("Auto Gun", nil, function(v) _G.AutoGun = v end)
Stats:CreateToggle("Auto Blox Fruit", nil, function(v) _G.AutoBloxFruit = v end)

-- Teleport Tab
local Teleport = win:CreateTab("Teleport")
Teleport:CreateDropdown("Teleport to Island", _G.IslandList or {"Select"}, function(v) TeleportToIsland(v) end)
Teleport:CreateButton("Teleport to Sea 1", function() TeleportToSea(1) end)
Teleport:CreateButton("Teleport to Sea 2", function() TeleportToSea(2) end)
Teleport:CreateButton("Teleport to Sea 3", function() TeleportToSea(3) end)

-- Players Tab
local Players = win:CreateTab("Players")
Players:CreateButton("Kill Player", function() KillSelectedPlayer() end)
Players:CreateButton("Spectate Player", function() SpectateSelectedPlayer() end)

-- Devil Fruit Tab
local Fruit = win:CreateTab("DevilFruit")
Fruit:CreateToggle("Auto Store Fruit", nil, function(v) _G.AutoStoreFruit = v end)
Fruit:CreateToggle("Auto Random Fruit", nil, function(v) _G.AutoRandomFruit = v end)
Fruit:CreateToggle("Auto Eat Fruit", nil, function(v) _G.AutoEatFruit = v end)
Fruit:CreateButton("Bring All Fruit", function() BringAllFruit() end)
Fruit:CreateToggle("Fruit Sniper", nil, function(v) _G.FruitSniper = v end)

-- ESP-Raid Tab
local ESPRaid = win:CreateTab("ESP-Raid")
ESPRaid:CreateToggle("Enable ESP", nil, function(v) _G.ESP = v end)
ESPRaid:CreateToggle("Auto Join Raid", nil, function(v) _G.AutoRaid = v end)
ESPRaid:CreateToggle("Auto Kill Raid Boss", nil, function(v) _G.AutoRaidBoss = v end)

-- Buy Item Tab
local Buy = win:CreateTab("Buy Item")
Buy:CreateButton("Buy Legendary Sword", function() BuyLegendarySword() end)
Buy:CreateToggle("Auto Buy Potion", nil, function(v) _G.AutoBuyPotion = v end)
Buy:CreateToggle("Auto Buy Enhancement", nil, function(v) _G.AutoBuyEnhance = v end)

-- Setting Tab
local Setting = win:CreateTab("Setting")
Setting:CreateToggle("Fast Attack", nil, function(v) _G.FastAttack = v end)
Setting:CreateToggle("Auto Click", nil, function(v) _G.AutoClick = v end)
Setting:CreateToggle("Skill Z", nil, function(v) _G.SkillZ = v end)
Setting:CreateToggle("Skill X", nil, function(v) _G.SkillX = v end)
Setting:CreateToggle("Skill C", nil, function(v) _G.SkillC = v end)
Setting:CreateToggle("Skill V", nil, function(v) _G.SkillV = v end)

-- Info Tab
local Info = win:CreateTab("Info")
Info:CreateLabel("Full Moon: " .. tostring(game:GetService("Lighting").ClockTime))
Info:CreateButton("Copy Discord", function() setclipboard("https://discord.gg/gmonhub") end)

-- Background Anime Transparency (20%)
win.MainFrame.BackgroundTransparency = 0.8
local bg = Instance.new("ImageLabel", win.MainFrame)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundTransparency = 1
bg.Image = "rbxassetid://88817335071002"
bg.ZIndex = -1

-- RGB/Glow Effect for the Entire UI (Window + Background)
local tweenService = game:GetService("TweenService")
local function applyRGBGlowEffect(frame)
    while true do
        -- Create RGB animation for the entire UI background (Glow effect)
        for i = 0, 360, 20 do
            local color = Color3.fromHSV(i / 360, 1, 1)
            tweenService:Create(frame, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {BackgroundColor3 = color}):Play()
            wait(1)
        end
    end
end

-- Start the RGB/Glow animation for the entire window
coroutine.wrap(applyRGBGlowEffect)(win.MainFrame)

-- RGB Effect for Toggle Button (Glow Effect)
local toggleButton = Instance.new("TextButton", win.MainFrame)
toggleButton.Size = UDim2.new(0, 120, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Toggle"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
toggleButton.Font = Enum.Font.SourceSans
toggleButton.TextSize = 18
toggleButton.BorderSizePixel = 0
toggleButton.MouseButton1Click:Connect(function()
    -- Toggle Action (For example, show or hide the GUI)
    win.MainFrame.Visible = not win.MainFrame.Visible
end)

-- Start the RGB/Glow animation for the toggle button
coroutine.wrap(applyRGBEffect)(toggleButton)

-- Draggable functionality for the whole window
local dragToggle = nil
local dragInput = nil
local dragStart = nil
local startPos = nil

-- Enable dragging for main window
win.MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = true
        dragStart = input.Position
        startPos = win.MainFrame.Position
    end
end)

win.MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
        local delta = input.Position - dragStart
        win.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

win.MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = false
    end
end)
