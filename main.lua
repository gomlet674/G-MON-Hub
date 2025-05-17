-- main.lua - GMON Hub UI Script (Tab: Main)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))() local Window = Library.CreateLib("GMON Hub | Main", "Midnight")

-- Main Tab local Main = Window:NewTab("Main") local MainSection = Main:NewSection("Auto Farm Settings")

-- Dropdown: Select Weapon MainSection:NewDropdown("Select Weapon", "Choose weapon type", {"Melee", "Fruit", "Sword", "Gun"}, function(currentOption) getgenv().SelectedWeapon = currentOption end)

-- Toggle: Fruit Mastery MainSection:NewToggle("Fruit Mastery", "Auto level up Fruit mastery", function(state) getgenv().FruitMastery = state end)

-- Toggle: Auto Farm MainSection:NewToggle("Auto Farm", "Automatically farms enemies", function(state) getgenv().AutoFarm = state end)

-- Toggle: Fast Attack MainSection:NewToggle("Fast Attack", "Faster combat attacks", function(state) getgenv().FastAttack = state end)

-- Toggle: Auto Click MainSection:NewToggle("Auto Click", "Auto click ability/attack", function(state) getgenv().AutoClick = state end)

-- Toggle: Auto Equip Accessory MainSection:NewToggle("Auto Equip Accessory", "Equip best accessory automatically", function(state) getgenv().AutoEquipAccessory = state end)

-- Toggle: Aimbot MainSection:NewToggle("Aimbot", "Aim at enemy automatically", function(state) getgenv().AimbotEnabled = state end)

-- Save current config to shared/global environment shared.GMON_Settings = getgenv()

