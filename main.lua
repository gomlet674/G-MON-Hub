-- GMON HUB - MAIN LOADER
-- UI by Rayfield | Background anime | Load source.lua

local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "GMON HUB | Blox Fruits",
	LoadingTitle = "Loading GMON HUB...",
	LoadingSubtitle = "by gomlet674",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "GMONHub",
		FileName = "GMONConfig"
	},
	KeySystem = false,
	Discord = {
		Enabled = false
	}
})

-- Toggle Button UI (kanan atas)
local ToggleUI = Instance.new("ScreenGui")
ToggleUI.Name = "GMON_Toggle"
ToggleUI.ResetOnSpawn = false

-- Protect GUI jika syn
if syn and syn.protect_gui then
    syn.protect_gui(ToggleUI)
end
ToggleUI.Parent = game:GetService("CoreGui")

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0, 110, 0, 30)
Button.Position = UDim2.new(1, -120, 0, 100)
Button.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
Button.Text = "Toggle GMON"
Button.TextSize = 14
Button.Parent = ToggleUI

local gmonVisible = true
Button.MouseButton1Click:Connect(function()
	gmonVisible = not gmonVisible
	for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
		if gui.Name == "Rayfield" then
			gui.Enabled = gmonVisible
		end
	end
end)

-- Load Source Logic
local GMON = loadstring(game:HttpGet("https://raw.githubusercontent.com/gomlet674/G-MON-Hub/main/source.lua"))()

-- Buat Tab & Section
local Tab = Window:CreateTab("Main", 4483362458)
local Section = Tab:CreateSection("Chest & Chalice")

Tab:CreateToggle({
	Name = "ESP God Chalice",
	CurrentValue = false,
	Callback = function(state)
		if state then
			GMON.ESPGodChalice()
		end
	end,
})

Tab:CreateButton({
	Name = "Start Farm Chest",
	Callback = function()
		GMON.FarmChest()
	end,
})

Tab:CreateButton({
	Name = "Stop Farm Chest",
	Callback = function()
		GMON.StopFarmChest()
	end,
})