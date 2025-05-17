repeat wait() until game:IsLoaded()

-- Load source logic
loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

-- UI Library (Contoh pakai Rayfield, bisa diganti sesuai preferensi)
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
   Name = "GMON Hub | Blox Fruits",
   LoadingTitle = "GMON Hub Loading...",
   LoadingSubtitle = "By Gomlet",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "GMONHub", 
      FileName = "GMONConfig"
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateToggle({
   Name = "Auto Farm",
   CurrentValue = false,
   Flag = "AutoFarm",
   Callback = function(Value)
       shared.AutoFarm = Value
   end,
})

MainTab:CreateToggle({
   Name = "Aimbot (Player)",
   CurrentValue = false,
   Flag = "Aimbot",
   Callback = function(Value)
       shared.Aimbot = Value
   end,
})

MainTab:CreateButton({
   Name = "Refresh Weapon",
   Callback = function()
       RefreshWeaponList()
   end,
})

MainTab:CreateDropdown({
   Name = "Select Weapon",
   Options = {"Melee", "Sword", "Blox Fruit"},
   CurrentOption = "Melee",
   Flag = "SelectedWeapon",
   Callback = function(Value)
       shared.SelectedWeapon = Value
   end,
})

MainTab:CreateToggle({
   Name = "Auto Equip Accessory",
   CurrentValue = false,
   Flag = "AutoEquipAccessory",
   Callback = function(Value)
       shared.AutoEquipAccessory = Value
   end,
})

-- Settings Tab
local SettingTab = Window:CreateTab("Setting", 4483345998)

SettingTab:CreateToggle({
   Name = "Fast Attack",
   CurrentValue = false,
   Flag = "FastAttack",
   Callback = function(Value)
       shared.FastAttack = Value
   end,
})

SettingTab:CreateToggle({
   Name = "Auto Click",
   CurrentValue = false,
   Flag = "AutoClick",
   Callback = function(Value)
       shared.AutoClick = Value
   end,
})

-- Add more tabs like Stats, Teleport, Players, DevilFruit, ESP-Raid, Buy Item as needed

Rayfield:Notify({
   Title = "GMON Hub Loaded",
   Content = "Main UI Loaded Successfully",
   Duration = 5
})