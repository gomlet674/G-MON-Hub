
-- GMON Hub Main Script (main.lua)
repeat wait() until game:IsLoaded()

local uis = game:GetService("UserInputService")
local plr = game.Players.LocalPlayer

-- UI Library
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

-- Create Window
local win = library:CreateWindow("GMON HUB", "Mukuro Styled UI", Color3.fromRGB(255,0,0), "rbxassetid://15275852420")

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
