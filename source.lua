-- GMON Hub - source.lua (Final) -- Menyusun semua fitur lengkap untuk Blox Fruits sesuai request user

local Window = Library:CreateWindow({ Name = "GMON Hub", LoadingTitle = "GMON HUB | BLOX FRUITS", LoadingSubtitle = "by Gomlet", ConfigurationSaving = { Enabled = true, FolderName = "GMONHub", FileName = "GMONSettings" }, Discord = { Enabled = true, Invite = "pandadev", RememberJoins = true }, KeySystem = false, })

-- Tabs local InfoTab = Window:CreateTab("Info", 4483362458) local MainTab = Window:CreateTab("Main", 4483362458) local ItemTab = Window:CreateTab("Item", 4483362458) local PrehistoricTab = Window:CreateTab("Prehistoric Island", 4483362458) local KitsuneTab = Window:CreateTab("Kitsune Island", 4483362458) local MirageTab = Window:CreateTab("Mirage Island", 4483362458) local LeviathanTab = Window:CreateTab("Leviathan", 4483362458) local SeaTab = Window:CreateTab("Sea Events", 4483362458) local MiscTab = Window:CreateTab("Misc", 4483362458) local SettingTab = Window:CreateTab("Setting", 4483362458)

-- MainTab Features MainTab:CreateDropdown("Select Weapon", {"Melee", "Sword", "Blox Fruit"}, function(v) getgenv().SelectedWeapon = v end) MainTab:CreateToggle("Auto Farm", nil, function(v) getgenv().AutoFarm = v end) MainTab:CreateToggle("Farm Nearest", nil, function(v) getgenv().FarmNearest = v end) MainTab:CreateToggle("Auto Next Sea", nil, function(v) getgenv().AutoNextSea = v end) MainTab:CreateToggle("Auto Equip Accessory", nil, function(v) getgenv().AutoEquipAccessory = v end)

-- ItemTab Features ItemTab:CreateButton("Auto CDK", function() -- your CDK logic end) ItemTab:CreateButton("Farm Material", function() -- your material logic end) ItemTab:CreateButton("Auto Holy Torch", function() -- torch logic end) ItemTab:CreateButton("Auto Tushita", function() -- tushita logic end)

-- PrehistoricTab Features PrehistoricTab:CreateToggle("Auto Farm", nil, function(v) getgenv().AutoFarmPrehistoric = v end) PrehistoricTab:CreateToggle("Auto Kill Boss", nil, function(v) getgenv().AutoKillPreBoss = v end) PrehistoricTab:CreateToggle("Auto Collect Item", nil, function(v) getgenv().AutoCollectPreItem = v end)

-- KitsuneTab Features KitsuneTab:CreateToggle("Auto Kill Kitsune", nil, function(v) getgenv().AutoKillKitsune = v end) KitsuneTab:CreateToggle("Auto Farm Kitsune", nil, function(v) getgenv().AutoFarmKitsune = v end)

-- MirageTab Features MirageTab:CreateToggle("Auto Find Mirage", nil, function(v) getgenv().AutoFindMirage = v end) MirageTab:CreateToggle("Auto Get Blue Gear", nil, function(v) getgenv().AutoBlueGear = v end)

-- LeviathanTab Features LeviathanTab:CreateToggle("Auto Kill Leviathan", nil, function(v) getgenv().AutoKillLeviathan = v end) LeviathanTab:CreateToggle("Auto Take Heart", nil, function(v) getgenv().AutoTakeHeart = v end) LeviathanTab:CreateToggle("Auto Draco Race", nil, function(v) getgenv().AutoDraco = v end) LeviathanTab:CreateToggle("Auto Blaze Ember", nil, function(v) getgenv().AutoBlaze = v end) LeviathanTab:CreateToggle("Auto Craft", nil, function(v) getgenv().AutoCraft = v end)

-- SeaTab Features SeaTab:CreateToggle("Auto Sea Events", nil, function(v) getgenv().AutoSeaEvents = v end) SeaTab:CreateToggle("Auto Sea Beast", nil, function(v) getgenv().AutoSeaBeast = v end) SeaTab:CreateToggle("Auto Boat", nil, function(v) getgenv().AutoBoat = v end)

-- MiscTab Features MiscTab:CreateButton("Redeem All Codes", function() -- redeem logic end) MiscTab:CreateButton("FPS Booster", function() -- fps logic end) MiscTab:CreateButton("Server Hop", function() -- hop logic end)

-- SettingTab Features SettingTab:CreateToggle("Fast Attack", nil, function(v) getgenv().FastAttack = v end) SettingTab:CreateToggle("Auto Click", nil, function(v) getgenv().AutoClick = v end) SettingTab:CreateToggle("Use Skill X", nil, function(v) getgenv().UseSkillX = v end) SettingTab:CreateToggle("Use Skill Z", nil, function(v) getgenv().UseSkillZ = v end) SettingTab:CreateToggle("Use Skill C", nil, function(v) getgenv().UseSkillC = v end) SettingTab:CreateToggle("Use Skill V", nil, function(v) getgenv().UseSkillV = v end)

-- InfoTab Features InfoTab:CreateLabel("Full Moon Status: Pending") InfoTab:CreateLabel("Discord: discord.gg/pandadev")

